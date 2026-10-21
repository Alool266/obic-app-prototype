// Made by Dr Ali
// Public catalog + authenticated order create — AuthZ on the API.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';
import 'service_catalog.dart';
import 'service_sub_catalog.dart';

class ServicesApi {
  ServicesApi({http.Client? client, String? baseUrl})
      : _client = client ?? obicHttpClient(),
        _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  /// Public — guests may browse.
  Future<List<ObicService>> fetchCatalog({
    String? country,
    String? city,
  }) async {
    final params = <String, String>{};
    if (country != null && country.trim().isNotEmpty) {
      params['country'] = country.trim().toUpperCase();
    }
    if (city != null && city.trim().isNotEmpty) {
      params['city'] = city.trim();
    }
    final uri = _uri('/v1/services').replace(
      queryParameters: params.isEmpty ? null : params,
    );
    final res = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        'Catalog failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw AuthApiException('Malformed catalog response');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ObicService.fromJson)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<List<ObicSubService>> fetchSubServices(
    String parentSlug, {
    String? country,
    String? city,
  }) async {
    final params = <String, String>{};
    if (country != null && country.trim().isNotEmpty) {
      params['country'] = country.trim().toUpperCase();
    }
    if (city != null && city.trim().isNotEmpty) {
      params['city'] = city.trim();
    }
    final uri = _uri('/v1/services/$parentSlug/sub-services').replace(
      queryParameters: params.isEmpty ? null : params,
    );
    final res = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        'Sub-services failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw AuthApiException('Malformed sub-services response');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ObicSubService.fromJson)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Requires JWT — userId is derived from the token on the server.
  Future<Map<String, dynamic>> createOrder({
    required String accessToken,
    required String serviceId,
    String? preferredBranch,
    String? notes,
    String? offerId,
    String? subServiceId,
    String? subServiceNameEn,
    String? subServiceNameAr,
    Map<String, String>? formData,
  }) async {
    final res = await _client.post(
      _uri('/v1/orders'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'serviceId': serviceId,
        if (preferredBranch != null && preferredBranch.isNotEmpty)
          'preferredBranch': preferredBranch,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (offerId != null && offerId.isNotEmpty) 'offerId': offerId,
        if (subServiceId != null && subServiceId.isNotEmpty)
          'subServiceId': subServiceId,
        if (subServiceNameEn != null && subServiceNameEn.isNotEmpty)
          'subServiceNameEn': subServiceNameEn,
        if (subServiceNameAr != null && subServiceNameAr.isNotEmpty)
          'subServiceNameAr': subServiceNameAr,
        if (formData != null && formData.isNotEmpty) 'formData': formData,
      }),
    );
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
              : 'Order failed (${res.statusCode})';
      throw AuthApiException(text, statusCode: res.statusCode);
    }
    return json;
  }

  Future<List<Map<String, dynamic>>> listMyOrders(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/orders'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        'Orders failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> openOrderChat({
    required String accessToken,
    required String orderId,
  }) async {
    final res = await _client.get(
      _uri('/v1/orders/$orderId/chat'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        'Order chat failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw AuthApiException('Malformed order chat response');
    }
    return decoded;
  }
}

/// Loads catalog from API with local seed fallback for offline / guest demos.
class CatalogRepository {
  CatalogRepository({ServicesApi? api}) : _api = api ?? ServicesApi();

  final ServicesApi _api;
  List<ObicService>? _cache;
  String? _cacheKey;
  String? _countryCode;
  String? _cityName;

  void setRegion({String? countryCode, String? cityName}) {
    final nextKey = '${countryCode ?? ''}:${cityName ?? ''}';
    if (_cacheKey == nextKey) return;
    _countryCode = countryCode;
    _cityName = cityName;
    invalidate();
  }

  Future<List<ObicService>> load() async {
    final key = '${_countryCode ?? ''}:${_cityName ?? ''}';
    if (_cache != null && _cacheKey == key) return _cache!;
    try {
      // Trial API cold-start can be slow; never hang Home forever.
      var rows = await _api
          .fetchCatalog(
            country: _countryCode,
            city: _cityName,
          )
          .timeout(const Duration(seconds: 12));
      if (rows.isEmpty &&
          (_countryCode != null && _countryCode!.isNotEmpty)) {
        rows = await _api
            .fetchCatalog()
            .timeout(const Duration(seconds: 8));
      }
      _cache = rows.isNotEmpty
          ? rows
          : localCatalogSeed(countryCode: _countryCode);
    } catch (_) {
      _cache = localCatalogSeed(countryCode: _countryCode);
    }
    _cacheKey = key;
    return _cache!;
  }

  void invalidate() {
    _cache = null;
    _cacheKey = null;
  }
}

/// Loads inner services from API with local seed fallback.
class SubCatalogRepository {
  SubCatalogRepository({ServicesApi? api}) : _api = api ?? ServicesApi();

  final ServicesApi _api;
  final Map<String, List<ObicSubService>> _cache = {};
  String? _countryCode;
  String? _cityName;

  void setRegion({String? countryCode, String? cityName}) {
    _countryCode = countryCode;
    _cityName = cityName;
    invalidate();
  }

  Future<List<ObicSubService>> loadForParent(String parentSlug) async {
    final cacheKey =
        '$parentSlug:${_countryCode ?? ''}:${_cityName ?? ''}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    try {
      var rows = await _api.fetchSubServices(
        parentSlug,
        country: _countryCode,
        city: _cityName,
      );
      // Simulator / wrong region often empties China catalog — retry worldwide.
      if (rows.isEmpty &&
          (_countryCode != null && _countryCode!.isNotEmpty)) {
        rows = await _api.fetchSubServices(parentSlug);
      }
      if (rows.isNotEmpty) {
        _cache[cacheKey] = rows;
        return rows;
      }
    } catch (_) {
      // fall through to local
    }
    final local = subServicesForParent(parentSlug);
    _cache[cacheKey] = local;
    return local;
  }

  void invalidate([String? parentSlug]) {
    if (parentSlug != null) {
      _cache.removeWhere((k, _) => k.startsWith('$parentSlug:'));
    } else {
      _cache.clear();
    }
  }
}
