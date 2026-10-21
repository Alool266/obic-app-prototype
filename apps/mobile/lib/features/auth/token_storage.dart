// Made by Dr Ali
// Secure token vault — tokens never go in SharedPreferences or logs.

import 'dart:async';

import '../../core/china_push.dart';
import 'secure_store.dart';

class TokenStorage {
  TokenStorage({ObicSecureStore? store}) : _store = store ?? ObicSecureStore();

  static const _accessKey = 'obic_access_token';
  static const _refreshKey = 'obic_refresh_token';
  static const _userKey = 'obic_user_json';

  final ObicSecureStore _store;

  /// iOS Keychain reads are a platform-channel round trip. Caching the
  /// session in memory keeps later API calls from paying that before they
  /// even open a socket. [_generation] stops a slow read from overwriting a
  /// newer save or sign-out.
  int _generation = 0;
  String? _accessMem;
  String? _refreshMem;
  String? _userMem;

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userJson,
  }) async {
    _generation++;
    _accessMem = accessToken;
    _refreshMem = refreshToken;
    _userMem = userJson;
    // One key at a time so an iOS duplicate-item retry cannot overlap
    // another SecItemAdd for the same session.
    await _store.write(_accessKey, accessToken);
    await _store.write(_refreshKey, refreshToken);
    await _store.write(_userKey, userJson);
    unawaited(
      ChinaPush.sync(accessToken: accessToken, refreshToken: refreshToken),
    );
  }

  /// Retry briefly — Keystore can return null once on cold start without
  /// meaning the session was cleared.
  Future<String?> _readWithRetry(String key) async {
    try {
      final v = await _store.read(key);
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {
      // Fall through to retry.
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
      return await _store.read(key);
    } catch (_) {
      return null;
    }
  }

  Future<String?> readAccessToken() =>
      _readCached(_accessKey, () => _accessMem, (v) => _accessMem = v);

  Future<String?> readRefreshToken() =>
      _readCached(_refreshKey, () => _refreshMem, (v) => _refreshMem = v);

  Future<String?> readUserJson() =>
      _readCached(_userKey, () => _userMem, (v) => _userMem = v);

  Future<String?> _readCached(
    String key,
    String? Function() readMem,
    void Function(String? value) writeMem,
  ) async {
    final mem = readMem();
    if (mem != null && mem.isNotEmpty) return mem;
    final generation = _generation;
    final v = await _readWithRetry(key);
    if (generation != _generation) return readMem();
    if (v != null && v.isNotEmpty) writeMem(v);
    return readMem() ?? v;
  }

  Future<void> clear() async {
    _generation++;
    _accessMem = null;
    _refreshMem = null;
    _userMem = null;
    await _store.delete(_accessKey);
    await _store.delete(_refreshKey);
    await _store.delete(_userKey);
    unawaited(ChinaPush.clear());
  }
}
