// Made by Dr Ali
// Theme mode — system / light / dark; persisted on device.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefKey = 'obic_theme_mode_v1';

/// Holds [ThemeMode] and persists user choice (WeChat-style appearance).
class ThemeModeController extends ChangeNotifier {
  ThemeModeController({ThemeMode? initial}) : _mode = initial ?? ThemeMode.system;

  ThemeMode _mode;
  bool _loaded = false;

  ThemeMode get mode => _mode;

  bool get isLoaded => _loaded;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefKey);
    _mode = _parse(raw) ?? ThemeMode.system;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode next) async {
    if (_mode == next) return;
    _mode = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, _encode(next));
  }

  static ThemeMode? _parse(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => null,
    };
  }

  static String _encode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}
