// Made by Dr Ali
// API base URL only — no JWT secrets or DB credentials in the binary.

import 'package:flutter/foundation.dart';

/// Production API on the OBIC Aliyun ECS — default for all builds
/// (live since 22 Oct 2026).
/// Local Mac `:3001` is opt-in only via `--dart-define=API_BASE_URL=...`
/// so release APKs never bake a LAN IP.
const String kObicProdApi = 'https://api.obicgp.com';

/// Former Render trial API — reachable only via an explicit
/// `--dart-define=API_BASE_URL=https://obic-trial-api.onrender.com`.
const String kObicTrialApi = 'https://obic-trial-api.onrender.com';

const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

bool _isDevLanOrLoopback(String url) {
  final u = url.toLowerCase();
  return u.contains('192.168.') ||
      u.contains('10.0.2.2') ||
      u.contains('127.0.0.1') ||
      u.contains('localhost') ||
      RegExp(r':3001(/|$)').hasMatch(u);
}

/// Resolved API base URL (no trailing slash).
///
/// Override at build/run time when needed:
/// - Default (debug/profile/release): [kObicProdApi]
/// - Android emulator: `--dart-define=API_BASE_URL=http://10.0.2.2:3001`
/// - iOS simulator: `--dart-define=API_BASE_URL=http://127.0.0.1:3001`
/// - Physical phone → Mac LAN: `--dart-define=API_BASE_URL=http://<mac-lan-ip>:3001`
/// - Release/profile: LAN/loopback dart-defines are ignored (always trial)
String get kApiBaseUrl {
  // Host only — never include /v1 (clients append /v1/... themselves).
  String normalize(String raw) {
    var u = raw.trim().replaceAll(RegExp(r'/$'), '');
    u = u.replaceFirst(RegExp(r'/v1$'), '');
    return u;
  }

  if (_envApiBaseUrl.isNotEmpty) {
    final fromEnv = normalize(_envApiBaseUrl);
    // Never ship a release/profile APK that still talks to LAN :3001,
    // even if a debug dart-define was accidentally left on the build command.
    if (!kDebugMode && _isDevLanOrLoopback(fromEnv)) {
      return kObicProdApi;
    }
    return fromEnv;
  }
  return kObicProdApi;
}
