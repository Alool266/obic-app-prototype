// Made by Dr Ali
// Non-VIP Company Registration (boss W1) — /v1/registration client.
// userId always comes from the JWT on the server; never sent from here.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';

class RegistrationDoc {
  const RegistrationDoc({
    required this.id,
    required this.docType,
    required this.label,
    required this.required,
    required this.status,
    required this.color,
    required this.fileUrl,
    required this.version,
    required this.reviewNote,
  });

  factory RegistrationDoc.fromJson(Map<String, dynamic> j) => RegistrationDoc(
    id: j['id'] as String,
    docType: j['docType'] as String,
    label: j['label'] as String? ?? j['docType'] as String,
    required: j['required'] as bool? ?? false,
    status: j['status'] as String? ?? 'missing',
    color: j['color'] as String? ?? 'Yellow',
    fileUrl: j['fileUrl'] as String?,
    version: (j['version'] as num?)?.toInt() ?? 0,
    reviewNote: j['reviewNote'] as String?,
  );

  final String id;
  final String docType;
  final String label;
  final bool required;
  final String status;
  final String color;
  final String? fileUrl;
  final int version;
  final String? reviewNote;
}

class RegistrationApplication {
  const RegistrationApplication({
    required this.id,
    required this.trackingId,
    required this.contractId,
    required this.city,
    required this.activity,
    required this.nationality,
    required this.insideChina,
    required this.eligibilityOutcome,
    required this.status,
    required this.accountantTier,
    required this.includeWorkResidence,
    required this.priceSnapshot,
    required this.formData,
    required this.documents,
    required this.extractions,
    required this.events,
  });

  factory RegistrationApplication.fromJson(Map<String, dynamic> j) {
    final docs = j['documents'];
    final exts = j['extractions'];
    final evts = j['events'];
    return RegistrationApplication(
      id: j['id'] as String,
      trackingId: j['trackingId'] as String? ?? '',
      contractId: j['contractId'] as String?,
      city: j['city'] as String? ?? '',
      activity: j['activity'] as String? ?? '',
      nationality: j['nationality'] as String?,
      insideChina: j['insideChina'] as bool? ?? false,
      eligibilityOutcome:
          j['eligibilityOutcome'] as String? ?? 'to_be_verified',
      status: j['status'] as String? ?? 'DRAFT',
      accountantTier: j['accountantTier'] as String?,
      includeWorkResidence: j['includeWorkResidence'] as bool? ?? false,
      priceSnapshot: j['priceSnapshot'] is Map<String, dynamic>
          ? j['priceSnapshot'] as Map<String, dynamic>
          : null,
      formData: j['formData'] is Map<String, dynamic>
          ? j['formData'] as Map<String, dynamic>
          : null,
      documents: docs is List
          ? docs
                .whereType<Map<String, dynamic>>()
                .map(RegistrationDoc.fromJson)
                .toList()
          : const [],
      extractions: exts is List
          ? exts.whereType<Map<String, dynamic>>().toList()
          : const [],
      events: evts is List
          ? evts.whereType<Map<String, dynamic>>().toList()
          : const [],
    );
  }

  final String id;
  final String trackingId;
  final String? contractId;
  final String city;
  final String activity;
  final String? nationality;
  final bool insideChina;
  final String eligibilityOutcome;
  final String status;
  final String? accountantTier;
  final bool includeWorkResidence;
  final Map<String, dynamic>? priceSnapshot;
  final Map<String, dynamic>? formData;
  final List<RegistrationDoc> documents;
  final List<Map<String, dynamic>> extractions;
  final List<Map<String, dynamic>> events;
}

class RegistrationApi {
  RegistrationApi({http.Client? client, String? baseUrl})
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

  Future<Map<String, dynamic>> checkEligibility({
    required String accessToken,
    required String city,
    required String activity,
    String? nationality,
    required bool insideChina,
  }) async {
    final res = await _client.post(
      _uri('/v1/registration/eligibility/check'),
      headers: _headers(accessToken),
      body: jsonEncode({
        'city': city,
        'activity': activity,
        if (nationality != null && nationality.isNotEmpty)
          'nationality': nationality,
        'insideChina': insideChina,
      }),
    );
    return _decode(res);
  }

  Future<RegistrationApplication> createApplication({
    required String accessToken,
    required String city,
    required String activity,
    String? nationality,
    required bool insideChina,
    String? qualification,
    String? accountantTier,
    bool includeWorkResidence = false,
  }) async {
    final res = await _client.post(
      _uri('/v1/registration/applications'),
      headers: _headers(accessToken),
      body: jsonEncode({
        'city': city,
        'activity': activity,
        if (nationality != null && nationality.isNotEmpty)
          'nationality': nationality,
        'insideChina': insideChina,
        if (qualification != null && qualification.isNotEmpty)
          'qualification': qualification,
        if (accountantTier != null) 'accountantTier': accountantTier,
        'includeWorkResidence': includeWorkResidence,
      }),
    );
    return RegistrationApplication.fromJson(_decode(res));
  }

  Future<List<RegistrationApplication>> myApplications(
    String accessToken,
  ) async {
    final res = await _client.get(
      _uri('/v1/registration/applications'),
      headers: _headers(accessToken),
    );
    final rows = _decode(res)['rows'];
    if (rows is! List) return [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(RegistrationApplication.fromJson)
        .toList();
  }

  Future<RegistrationApplication> getApplication(
    String accessToken,
    String id,
  ) async {
    final res = await _client.get(
      _uri('/v1/registration/applications/$id'),
      headers: _headers(accessToken),
    );
    return RegistrationApplication.fromJson(_decode(res));
  }

  Future<RegistrationApplication> updateApplication({
    required String accessToken,
    required String id,
    String? accountantTier,
    bool? includeWorkResidence,
    Map<String, dynamic>? formData,
  }) async {
    final res = await _client.patch(
      _uri('/v1/registration/applications/$id'),
      headers: _headers(accessToken),
      body: jsonEncode({
        if (accountantTier != null) 'accountantTier': accountantTier,
        if (includeWorkResidence != null)
          'includeWorkResidence': includeWorkResidence,
        if (formData != null) 'formData': formData,
      }),
    );
    return RegistrationApplication.fromJson(_decode(res));
  }

  /// Upload one file to /v1/uploads and return its public URL.
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
    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    final map = _decode(res);
    final items = map['items'];
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map<String, dynamic> && first['url'] is String) {
        return first['url'] as String;
      }
    }
    throw AuthApiException('Upload returned no file URL');
  }

  Future<RegistrationDoc> uploadDocument({
    required String accessToken,
    required String applicationId,
    required String docType,
    required String fileUrl,
    String? fileName,
  }) async {
    final res = await _client.post(
      _uri('/v1/registration/applications/$applicationId/documents'),
      headers: _headers(accessToken),
      body: jsonEncode({
        'docType': docType,
        'fileUrl': fileUrl,
        if (fileName != null) 'fileName': fileName,
      }),
    );
    return RegistrationDoc.fromJson(_decode(res));
  }

  Future<RegistrationApplication> submit(String accessToken, String id) async {
    final res = await _client.post(
      _uri('/v1/registration/applications/$id/submit'),
      headers: _headers(accessToken),
    );
    return RegistrationApplication.fromJson(_decode(res));
  }

  Future<RegistrationApplication> cancel(String accessToken, String id) async {
    final res = await _client.post(
      _uri('/v1/registration/applications/$id/cancel'),
      headers: _headers(accessToken),
      body: jsonEncode({}),
    );
    return RegistrationApplication.fromJson(_decode(res));
  }

  /// Ask OBIC AI to read the passport photo. Throws 503 when OCR is off.
  Future<Map<String, dynamic>> extractPassport({
    required String accessToken,
    required String applicationId,
    required String documentId,
    required File file,
    required Map<String, String> typedValues,
  }) async {
    final bytes = await file.readAsBytes();
    final res = await _client.post(
      _uri(
        '/v1/registration/applications/$applicationId/documents/$documentId/extract',
      ),
      headers: _headers(accessToken),
      body: jsonEncode({
        'dataBase64': base64Encode(bytes),
        'mime': 'image/jpeg',
        'typedValues': typedValues,
      }),
    );
    return _decode(res);
  }
}
