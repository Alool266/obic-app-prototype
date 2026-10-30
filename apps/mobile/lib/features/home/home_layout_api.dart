// Made by Dr Ali
// Thin client for GET/PUT /v1/users/me/home-layout.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';
import 'home_service_layout.dart';

class HomeLayoutApi {
  HomeLayoutApi({http.Client? client, String? baseUrl})
      : _client = client ?? obicHttpClient(),
        _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 20);

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<HomeServiceLayout> fetch(String accessToken) async {
    final res = await _client
        .get(
          _uri('/v1/users/me/home-layout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        )
        .timeout(_timeout);
    final json = _decodeMap(res, 'Home layout');
    return HomeServiceLayout.fromJson(json);
  }

  Future<HomeServiceLayout> put({
    required String accessToken,
    required HomeServiceLayout layout,
  }) async {
    final res = await _client
        .put(
          _uri('/v1/users/me/home-layout'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(layout.toJson()),
        )
        .timeout(_timeout);
    final json = _decodeMap(res, 'Home layout');
    return HomeServiceLayout.fromJson(json);
  }

  Map<String, dynamic> _decodeMap(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message = label;
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) {
          message = body['message'].toString();
        }
      } catch (_) {}
      throw AuthApiException(message, statusCode: res.statusCode);
    }
    if (res.body.isEmpty) {
      return const {'order': [], 'favorites': [], 'hidden': []};
    }
    final body = jsonDecode(res.body);
    if (body is! Map) {
      throw AuthApiException('Invalid $label response', statusCode: res.statusCode);
    }
    return Map<String, dynamic>.from(body);
  }
}
