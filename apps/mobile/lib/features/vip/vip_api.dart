// Made by Dr Ali
// VIP client — timed consultations (USD) + trip builder (CNY coordination).
// Two separate products; prices always come from server Active versions.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';

class VipApi {
  VipApi({http.Client? client, String? baseUrl})
    : _client = client ?? obicHttpClient(),
      _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = json['message'];
      final text = msg is String
          ? msg
          : msg is List
          ? msg.join(', ')
          : 'Request failed (${res.statusCode})';
      throw AuthApiException(text, statusCode: res.statusCode);
    }
    return json;
  }

  Future<Map<String, dynamic>> createConsultation(
    String token,
    int minutes,
  ) async {
    final res = await _client.post(
      _uri('/v1/vip/consultations'),
      headers: _headers(token),
      body: jsonEncode({'minutes': minutes}),
    );
    return _decode(res);
  }

  Future<List<Map<String, dynamic>>> myConsultations(String token) async {
    final res = await _client.get(
      _uri('/v1/vip/consultations'),
      headers: _headers(token),
    );
    final rows = _decode(res)['rows'];
    return rows is List ? rows.whereType<Map<String, dynamic>>().toList() : [];
  }

  Future<Map<String, dynamic>> startConsultation(
    String token,
    String id,
  ) async {
    final res = await _client.post(
      _uri('/v1/vip/consultations/$id/start'),
      headers: _headers(token),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> endConsultation(String token, String id) async {
    final res = await _client.post(
      _uri('/v1/vip/consultations/$id/end'),
      headers: _headers(token),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> createTrip({
    required String token,
    required String purpose,
    required List<String> cities,
    required int days,
    required int people,
    String? notes,
  }) async {
    final res = await _client.post(
      _uri('/v1/vip/trips'),
      headers: _headers(token),
      body: jsonEncode({
        'purpose': purpose,
        'cities': cities,
        'days': days,
        'people': people,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    return _decode(res);
  }

  Future<List<Map<String, dynamic>>> myTrips(String token) async {
    final res = await _client.get(
      _uri('/v1/vip/trips'),
      headers: _headers(token),
    );
    final rows = _decode(res)['rows'];
    return rows is List ? rows.whereType<Map<String, dynamic>>().toList() : [];
  }

  Future<Map<String, dynamic>> getTrip(String token, String id) async {
    final res = await _client.get(
      _uri('/v1/vip/trips/$id'),
      headers: _headers(token),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> quoteTrip(String token, String id) async {
    final res = await _client.post(
      _uri('/v1/vip/trips/$id/quote'),
      headers: _headers(token),
      body: jsonEncode({}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> acceptTrip(String token, String id) async {
    final res = await _client.post(
      _uri('/v1/vip/trips/$id/accept'),
      headers: _headers(token),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> cancelTrip(String token, String id) async {
    final res = await _client.post(
      _uri('/v1/vip/trips/$id/cancel'),
      headers: _headers(token),
    );
    return _decode(res);
  }
}
