// Made by Dr Ali
// Hands the Android keep-alive the session it needs on phones with no Google push.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'api_config.dart';

class ChinaPush {
  ChinaPush._();

  static const _channel = MethodChannel('obic/push');

  static Future<void> sync({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (accessToken.isEmpty || refreshToken.isEmpty) return;
    try {
      await _channel.invokeMethod<bool>('syncChinaPush', {
        'access': accessToken,
        'refresh': refreshToken,
        'api': kApiBaseUrl,
      });
    } catch (_) {}
  }

  static Future<void> clear() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('clearChinaPush');
    } catch (_) {}
  }
}
