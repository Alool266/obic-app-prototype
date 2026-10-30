// Made by Dr Ali
// Thin client for /v1/user-office (Notes / Docs / Sheets / PDF).

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';

class UserOfficeApi {
  UserOfficeApi({http.Client? client, String? baseUrl})
      : _client = client ?? obicHttpClient(),
        _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;
  static const Duration _timeout = Duration(seconds: 30);

  Uri _uri(String path, [Map<String, String>? q]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: q);

  Future<List<Map<String, dynamic>>> list({
    required String accessToken,
    required String kind,
  }) async {
    final res = await _client
        .get(
          _uri('/v1/user-office', {'kind': kind}),
          headers: _headers(accessToken),
        )
        .timeout(_timeout);
    final map = _decodeMap(res, 'Office list');
    final rows = map['rows'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> get({
    required String accessToken,
    required String id,
  }) async {
    final res = await _client
        .get(_uri('/v1/user-office/$id'), headers: _headers(accessToken))
        .timeout(_timeout);
    return _decodeMap(res, 'Office item');
  }

  Future<Map<String, dynamic>> create({
    required String accessToken,
    required String kind,
    String? title,
    String? body,
    List<List<String>>? grid,
    String? fileUrl,
  }) async {
    final res = await _client
        .post(
          _uri('/v1/user-office'),
          headers: _headers(accessToken),
          body: jsonEncode({
            'kind': kind,
            if (title != null) 'title': title,
            if (body != null) 'body': body,
            if (grid != null) 'grid': grid,
            if (fileUrl != null) 'fileUrl': fileUrl,
          }),
        )
        .timeout(_timeout);
    return _decodeMap(res, 'Create office');
  }

  Future<Map<String, dynamic>> update({
    required String accessToken,
    required String id,
    String? title,
    String? body,
    List<List<String>>? grid,
    String? fileUrl,
  }) async {
    final res = await _client
        .patch(
          _uri('/v1/user-office/$id'),
          headers: _headers(accessToken),
          body: jsonEncode({
            if (title != null) 'title': title,
            if (body != null) 'body': body,
            if (grid != null) 'grid': grid,
            if (fileUrl != null) 'fileUrl': fileUrl,
          }),
        )
        .timeout(_timeout);
    return _decodeMap(res, 'Save office');
  }

  Future<Map<String, dynamic>> share({
    required String accessToken,
    required String id,
    required List<String> shareUserIds,
  }) async {
    final res = await _client
        .put(
          _uri('/v1/user-office/$id/share'),
          headers: _headers(accessToken),
          body: jsonEncode({'shareUserIds': shareUserIds}),
        )
        .timeout(_timeout);
    return _decodeMap(res, 'Share office');
  }

  Future<void> remove({
    required String accessToken,
    required String id,
  }) async {
    final res = await _client
        .delete(_uri('/v1/user-office/$id'), headers: _headers(accessToken))
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException('Delete failed', statusCode: res.statusCode);
    }
  }

  Map<String, String> _headers(String accessToken) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

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
    if (res.body.isEmpty) return {};
    final body = jsonDecode(res.body);
    if (body is! Map) {
      throw AuthApiException('Invalid $label response', statusCode: res.statusCode);
    }
    return Map<String, dynamic>.from(body);
  }
}
