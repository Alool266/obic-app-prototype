// Made by Dr Ali
// Phase 5 — OBIC AI client. Calls API only; no OpenAI keys in the binary.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';

class AiApi {
  AiApi({http.Client? client, String? baseUrl})
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
      _uri('/v1/ai/status'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    return _decodeMap(res, 'AI status');
  }

  Future<List<Map<String, dynamic>>> listThreads(String accessToken) async {
    final res = await _client.get(
      _uri('/v1/ai/assistant/threads'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    final decoded = _decodeJson(res, 'AI threads');
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getThread({
    required String accessToken,
    required String threadId,
  }) async {
    final res = await _client.get(
      _uri('/v1/ai/assistant/threads/$threadId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    return _decodeMap(res, 'AI thread');
  }

  Future<void> deleteThread({
    required String accessToken,
    required String threadId,
  }) async {
    final res = await _client.delete(
      _uri('/v1/ai/assistant/threads/$threadId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _decodeMap(res, 'Delete AI thread');
    }
  }

  /// [abortTrigger] cancels the in-flight POST when it completes.
  /// The shared client supports this via [http.AbortableRequest].
  Future<Map<String, dynamic>> ask({
    required String accessToken,
    required String message,
    required String locale,
    List<Map<String, String>>? history,
    String? threadId,
    Map<String, String>? attachment,
    Future<void>? abortTrigger,
  }) async {
    final request = http.AbortableRequest(
      'POST',
      _uri('/v1/ai/assistant'),
      abortTrigger: abortTrigger,
    );
    request.headers.addAll(_authHeaders(accessToken));
    request.body = jsonEncode({
      'message': message,
      'locale': locale,
      if (history != null && history.isNotEmpty) 'history': history,
      if (threadId != null && threadId.isNotEmpty) 'threadId': threadId,
      'attachment': ?attachment,
    });
    try {
      final streamed = await _client.send(request);
      final res = await http.Response.fromStream(streamed);
      return _decodeMap(res, 'OBIC AI');
    } on http.RequestAbortedException {
      throw const AiAskCancelled();
    }
  }

  /// Streaming variant of [ask] — yields SSE events ({delta}… then
  /// {done, threadId, locale}) so the UI can render the reply as it is
  /// written instead of waiting for the full completion.
  Stream<Map<String, dynamic>> askStream({
    required String accessToken,
    required String message,
    required String locale,
    List<Map<String, String>>? history,
    String? threadId,
    Map<String, String>? attachment,
  }) async* {
    final request = http.Request('POST', _uri('/v1/ai/assistant/stream'));
    request.headers.addAll(_authHeaders(accessToken));
    request.headers['Accept'] = 'text/event-stream';
    request.body = jsonEncode({
      'message': message,
      'locale': locale,
      if (history != null && history.isNotEmpty) 'history': history,
      if (threadId != null && threadId.isNotEmpty) 'threadId': threadId,
      'attachment': ?attachment,
    });
    final streamed = await _client.send(request);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final res = await http.Response.fromStream(streamed);
      _decodeMap(res, 'OBIC AI');
      return;
    }
    await for (final line in streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) yield Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Ignore malformed keep-alive lines.
      }
    }
  }

  /// WeChat-style translate (AR / EN / ZH). Cached server-side by messageId.
  Future<Map<String, dynamic>> translate({
    required String accessToken,
    required String text,
    required String targetLocale,
    String? messageId,
  }) async {
    final res = await _client.post(
      _uri('/v1/ai/translate'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({
        'text': text,
        'targetLocale': targetLocale,
        if (messageId != null && messageId.isNotEmpty) 'messageId': messageId,
      }),
    );
    return _decodeMap(res, 'Translate');
  }

  Future<Map<String, dynamic>> seeText({
    required String accessToken,
    required String dataBase64,
    required String mime,
  }) async {
    final res = await _client.post(
      _uri('/v1/ai/see-text'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'dataBase64': dataBase64, 'mime': mime}),
    );
    return _decodeMap(res, 'See text');
  }

  Future<Map<String, dynamic>> transcribe({
    required String accessToken,
    required String dataBase64,
    required String mime,
  }) async {
    final res = await _client.post(
      _uri('/v1/ai/transcribe'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'dataBase64': dataBase64, 'mime': mime}),
    );
    return _decodeMap(res, 'Transcribe');
  }

  dynamic _decodeJson(http.Response res, String label) {
    dynamic decoded;
    if (res.body.isNotEmpty) {
      decoded = jsonDecode(res.body);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      final msg = json['message'];
      final text = msg is String
          ? msg
          : msg is List
              ? msg.join(', ')
              : '$label failed (${res.statusCode})';
      throw AuthApiException(text, statusCode: res.statusCode);
    }
    return decoded;
  }

  Map<String, dynamic> _decodeMap(http.Response res, String label) {
    final decoded = _decodeJson(res, label);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }
}

/// The user stopped an assistant request before a reply arrived.
class AiAskCancelled implements Exception {
  const AiAskCancelled();
}
