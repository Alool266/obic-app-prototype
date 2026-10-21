// Made by Dr Ali
// Admin API client — never trusts client role; server returns 403 for Customers.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';

class AdminApi {
  AdminApi({http.Client? client, String? baseUrl})
    : _client = client ?? obicHttpClient(),
      _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    final u = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) return u;
    return u.replace(queryParameters: query);
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> me(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/admin/me'),
      headers: _headers(accessToken),
    );
    return _decodeMap(res, 'Admin me');
  }

  Future<Map<String, dynamic>> dashboard(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/admin/dashboard'),
      headers: _headers(accessToken),
    );
    return _decodeMap(res, 'Admin dashboard');
  }

  Future<List<Map<String, dynamic>>> listOrders(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/admin/orders'),
      headers: _headers(accessToken),
    );
    return _decodeList(res, 'Admin orders');
  }

  Future<Map<String, dynamic>> updateOrder({
    required String accessToken,
    required String orderId,
    String? status,
    String? assignedEmployeeId,
    bool clearAssignee = false,
  }) async {
    final body = <String, dynamic>{
      if (status != null) 'status': status,
      if (clearAssignee) 'assignedEmployeeId': null,
      if (!clearAssignee && assignedEmployeeId != null)
        'assignedEmployeeId': assignedEmployeeId,
    };
    final res = await _client.patch(
      _uri('/v1/admin/orders/$orderId'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    return _decodeMap(res, 'Admin update order');
  }

  Future<Map<String, dynamic>> openOrderChat({
    required String accessToken,
    required String orderId,
  }) async {
    final res = await _client.get(
      _uri('/v1/admin/orders/$orderId/chat'),
      headers: _headers(accessToken),
    );
    return _decodeMap(res, 'Admin order chat');
  }

  Future<List<Map<String, dynamic>>> listStaff(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/admin/staff'),
      headers: _headers(accessToken),
    );
    return _decodeList(res, 'Admin staff');
  }

  /// Form2 rule 5 — SuperAdmin creates Employee; production phones/emails later.
  Future<Map<String, dynamic>> createStaff({
    required String accessToken,
    required String name,
    required String password,
    String? email,
    String? phone,
    String? staffTitle,
    String? branchLabel,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (staffTitle != null && staffTitle.isNotEmpty) 'staffTitle': staffTitle,
      if (branchLabel != null && branchLabel.isNotEmpty)
        'branchLabel': branchLabel,
    };
    final res = await _client.post(
      _uri('/v1/admin/staff'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    return _decodeMap(res, 'Admin create staff');
  }

  Future<Map<String, dynamic>> updateStaffRole({
    required String accessToken,
    required String userId,
    required String role,
  }) async {
    final res = await _client.patch(
      _uri('/v1/admin/staff/$userId/role'),
      headers: _headers(accessToken),
      body: jsonEncode({'role': role}),
    );
    return _decodeMap(res, 'Admin staff role');
  }

  /// SuperAdmin: name, phone, desk title, branch, avatar, opsAccess,
  /// offersAccess, optional password.
  Future<Map<String, dynamic>> updateStaffProfile({
    required String accessToken,
    required String userId,
    String? name,
    String? phone,
    String? staffTitle,
    String? branchLabel,
    String? avatarUrl,
    bool? opsAccess,
    bool? offersAccess,
    String? newPassword,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (staffTitle != null) 'staffTitle': staffTitle,
      if (branchLabel != null) 'branchLabel': branchLabel,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (opsAccess != null) 'opsAccess': opsAccess,
      if (offersAccess != null) 'offersAccess': offersAccess,
      if (newPassword != null && newPassword.isNotEmpty)
        'newPassword': newPassword,
    };
    final res = await _client.patch(
      _uri('/v1/admin/staff/$userId'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    return _decodeMap(res, 'Admin staff profile');
  }

  Future<String> uploadFile({
    required String accessToken,
    required String path,
    required String filename,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/v1/uploads'));
    req.headers['Authorization'] = 'Bearer $accessToken';
    req.headers['Accept'] = 'application/json';
    req.files.add(
      await http.MultipartFile.fromPath('files', path, filename: filename),
    );
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final map = _decodeMap(res, 'Upload');
    final items = map['items'];
    if (items is! List || items.isEmpty) {
      throw AuthApiException('Upload returned no URL');
    }
    final first = items.first;
    if (first is! Map || first['url'] is! String) {
      throw AuthApiException('Upload returned no URL');
    }
    return first['url'] as String;
  }

  Future<List<Map<String, dynamic>>> listOversightChats(
    String accessToken, {
    String? kind,
    String? q,
    bool includeFriends = false,
  }) async {
    final res = await _client.get(
      _uri('/v1/admin/oversight/chats', {
        if (kind != null && kind.isNotEmpty) 'kind': kind,
        if (q != null && q.isNotEmpty) 'q': q,
        if (includeFriends) 'includeFriends': '1',
      }),
      headers: _headers(accessToken),
    );
    return _decodeList(res, 'Admin oversight');
  }

  Future<Map<String, dynamic>> oversightTranscript({
    required String accessToken,
    required String conversationId,
  }) async {
    final res = await _client.get(
      _uri('/v1/admin/oversight/chats/$conversationId/messages'),
      headers: _headers(accessToken),
    );
    return _decodeMap(res, 'Admin transcript');
  }

  /// SuperAdmin joins Support / order / group (audited). Friend DMs refuse.
  Future<Map<String, dynamic>> setThreadAiAutoReply({
    required String accessToken,
    required String conversationId,
    required bool enabled,
  }) async {
    final res = await _client.patch(
      _uri('/v1/chat/threads/$conversationId/ai-auto-reply'),
      headers: _headers(accessToken),
      body: jsonEncode({'enabled': enabled}),
    );
    return _decodeMap(res, 'Thread AI auto-reply');
  }

  Future<Map<String, dynamic>> joinOversightChat({
    required String accessToken,
    required String conversationId,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/oversight/chats/$conversationId/join'),
      headers: _headers(accessToken),
      body: '{}',
    );
    return _decodeMap(res, 'Admin join chat');
  }

  Future<List<Map<String, dynamic>>> listAudit(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/admin/audit'),
      headers: _headers(accessToken),
    );
    return _decodeList(res, 'Admin audit');
  }

  /// Staff hotel/flight offers (own rows; SuperAdmin sees all).
  Future<List<Map<String, dynamic>>> listOffers(
    String accessToken, {
    String? kind,
    String? type,
    String? q,
    String? city,
  }) async {
    final res = await _client.get(
      _uri('/v1/admin/offers', {
        if (kind != null && kind.isNotEmpty) 'kind': kind,
        if (type != null && type.isNotEmpty) 'type': type,
        if (q != null && q.isNotEmpty) 'q': q,
        if (city != null && city.isNotEmpty) 'city': city,
      }),
      headers: _headers(accessToken),
    );
    final map = _decodeMap(res, 'Admin offers');
    final items = map['items'];
    if (items is! List) return [];
    return items.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createOffer({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/offers'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    return _decodeMap(res, 'Create offer');
  }

  Future<Map<String, dynamic>> updateOffer({
    required String accessToken,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    final res = await _client.patch(
      _uri('/v1/admin/offers/$id'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    return _decodeMap(res, 'Update offer');
  }

  Future<void> deleteOffer({
    required String accessToken,
    required String id,
  }) async {
    final res = await _client.delete(
      _uri('/v1/admin/offers/$id'),
      headers: _headers(accessToken),
    );
    _decodeMap(res, 'Delete offer');
  }

  Future<List<Map<String, dynamic>>> listModerationReports(
    String accessToken,
  ) async {
    final res = await _client.get(
      _uri('/v1/admin/moderation/reports'),
      headers: _headers(accessToken),
    );
    return _decodeList(res, 'Moderation reports');
  }

  Future<void> reviewModerationReport({
    required String accessToken,
    required String reportId,
    required String status,
  }) async {
    final res = await _client.patch(
      _uri('/v1/admin/moderation/reports/$reportId'),
      headers: _headers(accessToken),
      body: jsonEncode({'status': status}),
    );
    _decodeMap(res, 'Review report');
  }

  Future<List<Map<String, dynamic>>> listBannedWords(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/admin/moderation/words'),
      headers: _headers(accessToken),
    );
    return _decodeList(res, 'Banned words');
  }

  Future<List<Map<String, dynamic>>> listServices(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/admin/services'),
      headers: _headers(accessToken),
    );
    return _decodeList(res, 'Admin services');
  }

  Future<Map<String, dynamic>> createService({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/services'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    return _decodeMap(res, 'Create service');
  }

  Future<Map<String, dynamic>> updateService({
    required String accessToken,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    final res = await _client.patch(
      _uri('/v1/admin/services/$id'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    return _decodeMap(res, 'Update service');
  }

  Future<List<Map<String, dynamic>>> listSubServices(
    String accessToken,
    String serviceId,
  ) async {
    final res = await _client.get(
      _uri('/v1/admin/service-subs?serviceId=$serviceId'),
      headers: _headers(accessToken),
    );
    return _decodeList(res, 'Admin sub-services');
  }

  Future<Map<String, dynamic>> createSubService({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/service-subs'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    return _decodeMap(res, 'Create sub-service');
  }

  Future<Map<String, dynamic>> updateSubService({
    required String accessToken,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    final res = await _client.patch(
      _uri('/v1/admin/service-subs/$id'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    return _decodeMap(res, 'Update sub-service');
  }

  Future<List<Map<String, dynamic>>> listBugReports(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/admin/bug-reports'),
      headers: _headers(accessToken),
    );
    return _decodeList(res, 'Bug reports');
  }

  Future<List<Map<String, dynamic>>> listMiniApps(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/admin/mini-apps'),
      headers: _headers(accessToken),
    );
    return _decodeList(res, 'Mini apps');
  }

  Future<List<Map<String, dynamic>>> listDeactivatedUsers({
    required String accessToken,
    String? q,
  }) async {
    final res = await _client.get(
      _uri(
        '/v1/admin/users/deactivated',
        q != null && q.isNotEmpty ? {'q': q} : null,
      ),
      headers: _headers(accessToken),
    );
    return _decodeList(res, 'Deactivated users');
  }

  Future<Map<String, dynamic>> restoreUser({
    required String accessToken,
    required String userId,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/users/$userId/restore'),
      headers: _headers(accessToken),
      body: '{}',
    );
    return _decodeMap(res, 'Restore user');
  }

  Future<Map<String, dynamic>> updateBugReportStatus({
    required String accessToken,
    required String reportId,
    required String status,
  }) async {
    final res = await _client.patch(
      _uri('/v1/admin/bug-reports/$reportId'),
      headers: _headers(accessToken),
      body: jsonEncode({'status': status}),
    );
    return _decodeMap(res, 'Update bug report');
  }

  Future<Map<String, dynamic>> addBannedWord({
    required String accessToken,
    required String phrase,
    String? category,
  }) async {
    final res = await _client.post(
      _uri('/v1/admin/moderation/words'),
      headers: _headers(accessToken),
      body: jsonEncode({
        'phrase': phrase,
        if (category != null && category.isNotEmpty) 'category': category,
      }),
    );
    return _decodeMap(res, 'Add banned word');
  }

  List<Map<String, dynamic>> _decodeList(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(_err(res, label), statusCode: res.statusCode);
    }
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Map<String, dynamic> _decodeMap(http.Response res, String label) {
    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        _err(res, label, json),
        statusCode: res.statusCode,
      );
    }
    return json;
  }

  String _err(http.Response res, String label, [Map<String, dynamic>? json]) {
    final msg = json?['message'];
    if (msg is String) return msg;
    if (msg is List) return msg.join(', ');
    return '$label failed (${res.statusCode})';
  }
}
