// Made by Dr Ali
// Boss-module admin API (Steps 1–4) for the in-app staff desk — same
// endpoints and server-side role checks as the Admin Web. Price/rule
// transitions accept the TOTP step-up header when the server requires it.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';

class AdminBossApi {
  AdminBossApi({http.Client? client, String? baseUrl})
    : _client = client ?? obicHttpClient(),
      _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> _headers(String token, {String? totpCode}) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (totpCode != null && totpCode.isNotEmpty) 'x-obic-totp': totpCode,
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

  Future<List<Map<String, dynamic>>> _rows(String token, String path) async {
    final res = await _client.get(_uri(path), headers: _headers(token));
    final rows = _decode(res)['rows'];
    return rows is List ? rows.whereType<Map<String, dynamic>>().toList() : [];
  }

  // Prices (SuperAdmin)
  Future<List<Map<String, dynamic>>> prices(String token) =>
      _rows(token, '/v1/admin/prices');

  Future<Map<String, dynamic>> transitionPrice({
    required String token,
    required String id,
    required String status,
    String? effectiveFrom,
    String? totpCode,
  }) async {
    final res = await _client.patch(
      _uri('/v1/admin/prices/$id/transition'),
      headers: _headers(token, totpCode: totpCode),
      body: jsonEncode({
        'status': status,
        if (effectiveFrom != null) 'effectiveFrom': effectiveFrom,
      }),
    );
    return _decode(res);
  }

  // Eligibility rules (SuperAdmin)
  Future<List<Map<String, dynamic>>> eligibilityRules(String token) =>
      _rows(token, '/v1/admin/eligibility-rules');

  Future<Map<String, dynamic>> transitionRule({
    required String token,
    required String id,
    required String status,
    String? effectiveFrom,
    String? totpCode,
  }) async {
    final res = await _client.patch(
      _uri('/v1/admin/eligibility-rules/$id/transition'),
      headers: _headers(token, totpCode: totpCode),
      body: jsonEncode({
        'status': status,
        if (effectiveFrom != null) 'effectiveFrom': effectiveFrom,
      }),
    );
    return _decode(res);
  }

  // Registration queue (staff)
  Future<List<Map<String, dynamic>>> registrationApps(String token) =>
      _rows(token, '/v1/admin/registration/applications');

  Future<Map<String, dynamic>> registrationDetail(
    String token,
    String id,
  ) async {
    final res = await _client.get(
      _uri('/v1/admin/registration/applications/$id'),
      headers: _headers(token),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> reviewDocument({
    required String token,
    required String appId,
    required String docId,
    required String decision,
    String? note,
  }) async {
    final res = await _client.post(
      _uri(
        '/v1/admin/registration/applications/$appId/documents/$docId/review',
      ),
      headers: _headers(token),
      body: jsonEncode({'decision': decision, if (note != null) 'note': note}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> transitionRegistration({
    required String token,
    required String appId,
    required String status,
  }) async {
    final res = await _client.patch(
      _uri('/v1/admin/registration/applications/$appId/transition'),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> assignRegistration({
    required String token,
    required String appId,
    required String employeeId,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/registration/applications/$appId/assign'),
      headers: _headers(token),
      body: jsonEncode({'employeeId': employeeId}),
    );
    return _decode(res);
  }

  // OCR queue (staff)
  Future<List<Map<String, dynamic>>> ocrQueue(String token) =>
      _rows(token, '/v1/admin/registration/ocr-queue');

  Future<Map<String, dynamic>> reviewExtraction({
    required String token,
    required String extractionId,
    required String decision,
    String? note,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/registration/extractions/$extractionId/review'),
      headers: _headers(token),
      body: jsonEncode({'decision': decision, if (note != null) 'note': note}),
    );
    return _decode(res);
  }

  // VIP desk (staff)
  Future<List<Map<String, dynamic>>> vipTrips(String token) =>
      _rows(token, '/v1/admin/vip/trips');

  Future<List<Map<String, dynamic>>> vipConsultations(String token) =>
      _rows(token, '/v1/admin/vip/consultations');

  Future<Map<String, dynamic>> vipMarkTripPaid({
    required String token,
    required String tripId,
    required String reference,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/vip/trips/$tripId/mark-paid'),
      headers: _headers(token),
      body: jsonEncode({'reference': reference}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> vipMarkConsultationPaid({
    required String token,
    required String sessionId,
    required String reference,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/vip/consultations/$sessionId/mark-paid'),
      headers: _headers(token),
      body: jsonEncode({'reference': reference}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> vipAssignTrip({
    required String token,
    required String tripId,
    required String employeeId,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/vip/trips/$tripId/assign'),
      headers: _headers(token),
      body: jsonEncode({'employeeId': employeeId}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> vipCreateGroup({
    required String token,
    required String tripId,
    required List<String> memberUserIds,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/vip/trips/$tripId/create-group'),
      headers: _headers(token),
      body: jsonEncode({'memberUserIds': memberUserIds}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> vipTransitionTrip({
    required String token,
    required String tripId,
    required String status,
  }) async {
    final res = await _client.patch(
      _uri('/v1/admin/vip/trips/$tripId/transition'),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );
    return _decode(res);
  }
}
