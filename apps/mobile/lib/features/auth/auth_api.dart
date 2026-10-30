// Made by Dr Ali
// Thin HTTP client for /v1/auth and /v1/users/me — AuthZ stays on the server.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../../core/api_config.dart';
import '../../core/phone_activation_lock.dart';
import 'auth_models.dart';

/// Whole auth call, including a Render free-tier cold start (~30–90s).
/// Always finite so the login spinner cannot wait on a stalled socket.
const Duration _kAuthRequestTimeout = Duration(seconds: 120);

/// TCP connect only. A cold API still accepts the socket quickly and holds
/// the HTTP response; this stops a blackholed route from waiting forever.
const Duration _kAuthConnectTimeout = Duration(seconds: 30);

http.Client _defaultAuthClient() {
  final io = HttpClient()..connectionTimeout = _kAuthConnectTimeout;
  return IOClient(io);
}

class AuthApiException implements Exception {
  AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Login password OK — SuperAdmin must enter TOTP before tokens issue.
class AuthTotpRequiredException implements Exception {
  AuthTotpRequiredException(this.totpSession);

  final String totpSession;
}

/// Login/register password OK — must enter email/phone OTP before tokens issue.
class AuthVerifyRequiredException implements Exception {
  AuthVerifyRequiredException({
    required this.verifySession,
    required this.channel,
    required this.destinationMasked,
    this.phoneMasked,
    this.debugCode,
    this.delivery,
  });

  final String verifySession;
  final String channel;
  final String destinationMasked;
  final String? phoneMasked;
  final String? debugCode;
  final String? delivery;
}

class AuthApi {
  AuthApi({http.Client? client, String? baseUrl})
      : _client = client ?? _defaultAuthClient(),
        _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<http.Response> _send(Future<http.Response> request) {
    return request.timeout(_kAuthRequestTimeout);
  }

  Future<({AuthTokens tokens, ObicUser user})> register({
    String? email,
    String? phone,
    required String password,
    required String name,
    String? locale,
    String? regionCountry,
  }) async {
    final body = <String, dynamic>{
      'password': password,
      'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (locale != null && locale.isNotEmpty) 'locale': locale,
      if (regionCountry != null && regionCountry.isNotEmpty)
        'regionCountry': regionCountry,
    };
    final json = await _postJson('/v1/auth/register', body);
    _throwIfVerifyRequired(json);
    return _parseAuthResult(json);
  }

  Future<({AuthTokens tokens, ObicUser user})> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    final body = <String, dynamic>{
      'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };
    final json = await _postJson('/v1/auth/login', body);
    if (json['requiresTotp'] == true) {
      throw AuthTotpRequiredException(
        json['totpSession'] as String? ?? '',
      );
    }
    _throwIfVerifyRequired(json);
    return _parseAuthResult(json);
  }

  Future<({AuthTokens tokens, ObicUser user})> socialSignIn({
    required String provider,
    required String idToken,
    String? name,
    String? regionCountry,
  }) async {
    final body = <String, dynamic>{
      'provider': provider,
      'idToken': idToken,
      if (name != null && name.isNotEmpty) 'name': name,
      if (regionCountry != null && regionCountry.isNotEmpty)
        'regionCountry': regionCountry,
    };
    final json = await _postJson('/v1/auth/social', body);
    _throwIfVerifyRequired(json);
    return _parseAuthResult(json);
  }

  Future<({AuthTokens tokens, ObicUser user})> verifyOtp({
    required String verifySession,
    required String code,
  }) async {
    final json = await _postJson('/v1/auth/verify-otp', {
      'verifySession': verifySession,
      'code': code,
    });
    return _parseAuthResult(json);
  }

  AuthVerifyRequiredException _parseVerifyRequired(
    Map<String, dynamic> json, {
    String? fallbackSession,
  }) {
    return AuthVerifyRequiredException(
      verifySession:
          json['verifySession'] as String? ?? fallbackSession ?? '',
      channel: json['channel'] as String? ?? 'email',
      destinationMasked: json['destinationMasked'] as String? ?? '',
      phoneMasked: json['phoneMasked'] as String?,
      debugCode: json['debugCode'] as String?,
      delivery: json['delivery'] as String?,
    );
  }

  Future<AuthVerifyRequiredException?> resendOtp(String verifySession) async {
    final json = await _postJson('/v1/auth/resend-otp', {
      'verifySession': verifySession,
    });
    if (json['requiresVerification'] == true) {
      return _parseVerifyRequired(json, fallbackSession: verifySession);
    }
    throw AuthApiException('Unexpected resend response');
  }

  void _throwIfVerifyRequired(Map<String, dynamic> json) {
    if (json['requiresVerification'] == true) {
      throw _parseVerifyRequired(json);
    }
  }

  Future<({AuthTokens tokens, ObicUser user})> verifyTotpLogin({
    required String totpSession,
    required String code,
  }) async {
    final json = await _postJson('/v1/auth/totp/verify', {
      'totpSession': totpSession,
      'code': code,
    });
    return _parseAuthResult(json);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final json = await _postJson('/v1/auth/refresh', {
      'refreshToken': refreshToken,
    });
    return AuthTokens.fromJson(json);
  }

  Future<void> logout(String refreshToken) async {
    await _postJson('/v1/auth/logout', {'refreshToken': refreshToken});
  }

  Future<ObicUser> fetchMe(String accessToken) async {
    final res = await _send(
      _client.get(
        _uri('/v1/users/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      ),
    );
    final json = _decode(res);
    return ObicUser.fromJson(json);
  }

  Future<AuthVerifyRequiredException> startEmailVerify({
    required String accessToken,
    String? email,
    String? locale,
  }) async {
    await _wakeTrialIfNeeded();
    final res = await _send(
      _client.post(
        _uri('/v1/auth/email/start'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (email != null && email.isNotEmpty) 'email': email.trim(),
          if (locale != null && locale.isNotEmpty) 'locale': locale,
        }),
      ),
    );
    final json = _decode(res);
    if (json['requiresVerification'] == true) {
      return _parseVerifyRequired(json);
    }
    throw AuthApiException('Unexpected email verify response');
  }

  Future<AuthVerifyRequiredException> startPhoneVerify({
    required String accessToken,
    required String phone,
    String? email,
    String? locale,
  }) async {
    await _wakeTrialIfNeeded();
    final res = await _send(
      _client.post(
        _uri('/v1/auth/phone/start'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone.trim(),
          if (email != null && email.isNotEmpty) 'email': email.trim(),
          if (locale != null && locale.isNotEmpty) 'locale': locale,
        }),
      ),
    );
    final json = _decode(res);
    if (json['requiresVerification'] == true) {
      return _parseVerifyRequired(json);
    }
    throw AuthApiException('Unexpected phone verify response');
  }

  /// WeChat-style phone sign-in: sends an SMS code to [phone]. New numbers
  /// are registered by the same call; completing verifyOtp signs in.
  Future<AuthVerifyRequiredException> startPhoneLogin({
    required String phone,
    String? locale,
    String? regionCountry,
  }) async {
    final json = await _postJson('/v1/auth/phone-login/start', {
      'phone': phone.trim(),
      if (locale != null && locale.isNotEmpty) 'locale': locale,
      if (regionCountry != null && regionCountry.isNotEmpty)
        'regionCountry': regionCountry,
    });
    if (json['requiresVerification'] == true) {
      return _parseVerifyRequired(json);
    }
    throw AuthApiException('Unexpected phone login response');
  }

  /// Best-effort Render wake so phone/email OTP is not the cold-start victim.
  Future<void> _wakeTrialIfNeeded() async {
    final host = _baseUrl.toLowerCase();
    if (!host.contains('onrender.com')) return;
    try {
      await _send(
        _client.get(
          _uri('/v1/health'),
          headers: {'Accept': 'application/json'},
        ),
      );
    } catch (_) {
      // Real OTP call surfaces the error with a clearer mapped message.
    }
  }

  void _guardProfileWrite(String method, Uri url) {
    if (PhoneActivationLock.block(method, url)) {
      throw const PhoneActivationRequired();
    }
  }

  Future<ObicUser> updateMe({
    required String accessToken,
    String? name,
    String? phone,
    String? city,
    String? country,
    String? gender,
    String? whatsUp,
    String? obicId,
  }) async {
    final uri = _uri('/v1/users/me');
    _guardProfileWrite('PATCH', uri);
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (gender != null) 'gender': gender,
      if (whatsUp != null) 'whatsUp': whatsUp,
      if (obicId != null) 'obicId': obicId,
    };
    final res = await _send(
      _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );
    final json = _decode(res);
    return ObicUser.fromJson(json);
  }

  /// Change email — requires current password. Old email can no longer sign in.
  Future<ObicUser> changeEmail({
    required String accessToken,
    required String email,
    required String currentPassword,
  }) async {
    final uri = _uri('/v1/users/me/email');
    _guardProfileWrite('PATCH', uri);
    final res = await _send(
      _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'currentPassword': currentPassword,
        }),
      ),
    );
    final json = _decode(res);
    return ObicUser.fromJson(json);
  }

  Future<ObicUser> updateMomentsCover({
    required String accessToken,
    required String coverUrl,
    double? focusY,
  }) async {
    final uri = _uri('/v1/users/me/moments-cover');
    _guardProfileWrite('PATCH', uri);
    final res = await _send(
      _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'coverUrl': coverUrl,
          if (focusY != null) 'focusY': focusY,
        }),
      ),
    );
    final json = _decode(res);
    return ObicUser.fromJson(json);
  }

  Future<void> deleteMe({
    required String accessToken,
    required String currentPassword,
  }) async {
    final uri = _uri('/v1/users/me');
    _guardProfileWrite('DELETE', uri);
    final res = await _send(
      _client.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'currentPassword': currentPassword}),
      ),
    );
    _decode(res);
  }

  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = _uri('/v1/users/me/password');
    _guardProfileWrite('PATCH', uri);
    final res = await _send(
      _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ),
    );
    _decode(res);
  }

  Future<ObicUser> updateAddresses({
    required String accessToken,
    required List<ObicAddress> addresses,
  }) async {
    final uri = _uri('/v1/users/me/addresses');
    _guardProfileWrite('PUT', uri);
    final res = await _send(
      _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'addresses': addresses.map((a) => a.toJson()).toList(),
        }),
      ),
    );
    final json = _decode(res);
    return ObicUser.fromJson(json);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _send(
      _client.post(
        _uri(path),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        }
      } on FormatException {
        // Render/proxy HTML 502s must not become a generic "network" catch.
        throw AuthApiException(
          _statusFallback(res.statusCode),
          statusCode: res.statusCode,
        );
      }
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg =
          _messageFromBody(json) ?? _statusFallback(res.statusCode);
      throw AuthApiException(msg, statusCode: res.statusCode);
    }
    return json;
  }

  String _statusFallback(int statusCode) {
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return 'SERVER_WAKING';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Unauthorized';
    }
    return 'Request failed ($statusCode)';
  }

  String? _messageFromBody(Map<String, dynamic> json) {
    final message = json['message'];
    if (message is String) return message;
    if (message is List && message.isNotEmpty) {
      return message.map((e) => e.toString()).join(', ');
    }
    return null;
  }

  ({AuthTokens tokens, ObicUser user}) _parseAuthResult(
    Map<String, dynamic> json,
  ) {
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      throw AuthApiException('Malformed auth response');
    }
    return (
      tokens: AuthTokens.fromJson(json),
      user: ObicUser.fromJson(userJson),
    );
  }
}
