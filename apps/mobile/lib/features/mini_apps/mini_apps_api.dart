// Made by Dr Ali
// Mini-app HTTP client. Public list is approved-only. Own list needs a JWT.
// This client never sends the token to a mini-app page.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';
import 'mini_apps_catalog.dart';

class MiniAppSubmission {
  const MiniAppSubmission({
    required this.id,
    required this.name,
    required this.description,
    required this.startUrl,
    required this.status,
    this.iconUrl,
    this.reviewNote,
  });

  final String id;
  final String name;
  final String description;
  final String startUrl;
  final String? iconUrl;
  final String status;
  final String? reviewNote;

  bool get canOpenInCatalog => status == 'approved';
}

class MiniAppsApi {
  MiniAppsApi({http.Client? client, String? baseUrl})
    : _client = client ?? obicHttpClient(),
      _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 90);

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> _headers(String? accessToken) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };

  Future<List<MiniAppEntry>> listApproved() async {
    final res = await _client
        .get(_uri('/v1/mini-apps'), headers: _headers(null))
        .timeout(_timeout);
    final rows = _decodeList(res, 'Mini apps');
    final out = <MiniAppEntry>[];
    for (final row in rows) {
      final entry = miniAppFromPublicJson(row);
      if (entry != null) out.add(entry);
    }
    return out;
  }

  Future<List<MiniAppSubmission>> listMine(String accessToken) async {
    final res = await _client
        .get(_uri('/v1/mini-apps/mine'), headers: _headers(accessToken))
        .timeout(_timeout);
    return _decodeList(res, 'My mini apps').map(_submission).toList();
  }

  Future<MiniAppSubmission> create({
    required String accessToken,
    required String name,
    required String description,
    required String packagePath,
    required String packageFilename,
    String? iconUrl,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/v1/mini-apps'));
    req.headers['Authorization'] = 'Bearer $accessToken';
    req.headers['Accept'] = 'application/json';
    req.fields['name'] = name;
    req.fields['description'] = description;
    final icon = iconUrl?.trim() ?? '';
    if (icon.isNotEmpty) req.fields['iconUrl'] = icon;
    req.files.add(
      await http.MultipartFile.fromPath(
        'package',
        packagePath,
        filename: packageFilename,
      ),
    );
    final streamed = await _client.send(req).timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    return _submission(_decodeMap(res, 'Submit mini app'));
  }

  MiniAppSubmission _submission(Map<String, dynamic> json) {
    return MiniAppSubmission(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startUrl: json['startUrl'] as String? ?? '',
      iconUrl: json['iconUrl'] as String?,
      status: json['status'] as String? ?? 'pending',
      reviewNote: json['reviewNote'] as String?,
    );
  }

  List<Map<String, dynamic>> _decodeList(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(_errorText(res, label), statusCode: res.statusCode);
    }
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Map<String, dynamic> _decodeMap(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(_errorText(res, label), statusCode: res.statusCode);
    }
    if (res.body.isEmpty) return {};
    final decoded = jsonDecode(res.body);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  String _errorText(http.Response res, String label) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
      if (decoded is Map && decoded['message'] is List) {
        return (decoded['message'] as List).join('\n');
      }
    } catch (_) {}
    return '$label failed (${res.statusCode})';
  }
}
