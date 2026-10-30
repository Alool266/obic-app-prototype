// Made by Dr Ali
// Public offers API — published hotels / flights entered by staff.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';

class OffersApi {
  OffersApi({http.Client? client, String? baseUrl})
      : _client = client ?? obicHttpClient(),
        _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    final u = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) return u;
    return u.replace(queryParameters: query);
  }

  Future<List<Map<String, dynamic>>> listPublished({
    String? kind,
    String? type,
    String? q,
    String? city,
  }) async {
    final res = await _client.get(
      _uri('/v1/offers', {
        if (kind != null && kind.isNotEmpty) 'kind': kind,
        if (type != null && type.isNotEmpty) 'type': type,
        if (q != null && q.isNotEmpty) 'q': q,
        if (city != null && city.isNotEmpty) 'city': city,
      }),
      headers: {'Accept': 'application/json'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        'Offers failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) return [];
    final items = decoded['items'];
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<Map<String, dynamic>> getOne(String id) async {
    final res = await _client.get(
      _uri('/v1/offers/$id'),
      headers: {'Accept': 'application/json'},
    );
    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = json['message'];
      throw AuthApiException(
        msg is String ? msg : 'Offer failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return json;
  }
}
