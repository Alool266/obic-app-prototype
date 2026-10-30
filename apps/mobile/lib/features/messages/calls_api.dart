// Made by Dr Ali
// Phase 5 — Agora call client. Tokens from API only; certificate never in the app.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';

class CallsApi {
  CallsApi({http.Client? client, String? baseUrl})
      : _client = client ?? obicHttpClient(),
        _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> _authHeaders(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> status(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/calls/status'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    return _decodeMap(res, 'Calls status');
  }

  /// Create/ring a call; returns Agora join payload for the caller.
  Future<Map<String, dynamic>> createCall({
    required String accessToken,
    required String conversationId,
    required String mode, // voice | video
    List<String>? inviteUserIds,
  }) async {
    final res = await _client.post(
      _uri('/v1/calls'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({
        'conversationId': conversationId,
        'mode': mode,
        if (inviteUserIds != null && inviteUserIds.isNotEmpty)
          'inviteUserIds': inviteUserIds,
      }),
    );
    return _decodeMap(res, 'Create call');
  }

  Future<Map<String, dynamic>?> activeCall({
    required String accessToken,
    required String conversationId,
  }) async {
    final res = await _client.get(
      _uri('/v1/calls/active?conversationId=$conversationId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode == 404) return null;
    final json = _decodeMap(res, 'Active call');
    final call = json['call'];
    if (call is Map) return Map<String, dynamic>.from(call);
    return null;
  }

  Future<void> inviteCall({
    required String accessToken,
    required String callId,
    required List<String> userIds,
  }) async {
    final res = await _client.post(
      _uri('/v1/calls/$callId/invite'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'userIds': userIds}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _decodeMap(res, 'Invite');
    }
  }

  Future<void> leaveCall({
    required String accessToken,
    required String callId,
  }) async {
    final res = await _client.post(
      _uri('/v1/calls/$callId/leave'),
      headers: _authHeaders(accessToken),
      body: '{}',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _decodeMap(res, 'Leave call');
    }
  }

  /// Active incoming rings (HTTP backup when realtime push was missed).
  Future<List<Map<String, dynamic>>> listIncoming(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/calls/incoming'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _decodeMap(res, 'Incoming calls');
      return const [];
    }
    if (res.body.isEmpty) return const [];
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> mintToken({
    required String accessToken,
    required String callId,
  }) async {
    final res = await _client.post(
      _uri('/v1/calls/$callId/token'),
      headers: _authHeaders(accessToken),
      body: '{}',
    );
    return _decodeMap(res, 'Call token');
  }

  Future<void> endCall({
    required String accessToken,
    required String callId,
  }) async {
    final res = await _client.post(
      _uri('/v1/calls/$callId/end'),
      headers: _authHeaders(accessToken),
      body: '{}',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _decodeMap(res, 'End call');
    }
  }

  Map<String, dynamic> _decodeMap(http.Response res, String label) {
    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = json['message'];
      String text;
      if (msg is String) {
        text = msg;
      } else if (msg is List) {
        text = msg.join(', ');
      } else {
        text = '$label failed (${res.statusCode})';
      }
      throw AuthApiException(text, statusCode: res.statusCode);
    }
    return json;
  }
}
