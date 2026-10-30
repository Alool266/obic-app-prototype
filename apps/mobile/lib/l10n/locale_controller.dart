// Made by Dr Ali
// Locale controller — Arabic default; English + Chinese first-class; persisted.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefKey = 'obic_locale_v1';

/// Holds the active [Locale]. Arabic (RTL) is the product default when unset.
/// User choice (ar / en / zh / fr) is stored in SharedPreferences and restored on
/// cold start — same pattern as [ThemeModeController].
class LocaleController extends ChangeNotifier {
  LocaleController({Locale? initial}) : _locale = initial ?? const Locale('ar');

  Locale _locale;
  bool _loaded = false;

  Locale get locale => _locale;

  String get langCode => _locale.languageCode;

  bool get isArabic => _locale.languageCode == 'ar';

  bool get isChinese => _locale.languageCode == 'zh';

  bool get isFrench => _locale.languageCode == 'fr';

  bool get isLoaded => _loaded;

  /// Read saved locale before [runApp] so the first frame is already correct.
  static Future<Locale> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return _parse(prefs.getString(_kPrefKey)) ?? const Locale('ar');
  }

  /// Optional late reload (tests / prefs cleared elsewhere). Safe no-op if
  /// [loadSavedLocale] already seeded the controller.
  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final parsed = _parse(prefs.getString(_kPrefKey));
    if (parsed != null && parsed != _locale) {
      _locale = parsed;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Cycles ar → en → zh → fr → ar.
  Future<void> toggle() {
    final next = switch (_locale.languageCode) {
      'ar' => const Locale('en'),
      'en' => const Locale('zh'),
      'zh' => const Locale('fr'),
      'fr' => const Locale('ar'),
      _ => const Locale('ar'),
    };
    return setLocale(next);
  }

  Future<void> setLocale(Locale next) async {
    final normalized = _normalize(next);
    if (normalized == _locale) return;
    _locale = normalized;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, normalized.languageCode);
  }

  String languageLabel({bool arabicUi = true}) {
    switch (_locale.languageCode) {
      case 'ar':
        return arabicUi ? 'العربية' : 'Arabic';
      case 'zh':
        return arabicUi ? '中文' : 'Chinese';
      case 'fr':
        return 'Français';
      case 'en':
      default:
        return 'English';
    }
  }

  static Locale? _parse(String? raw) {
    return switch (raw) {
      'ar' => const Locale('ar'),
      'en' => const Locale('en'),
      'zh' => const Locale('zh'),
      'fr' => const Locale('fr'),
      _ => null,
    };
  }

  /// Only persist supported language codes; strip unexpected country tags.
  static Locale _normalize(Locale locale) {
    return switch (locale.languageCode) {
      'ar' => const Locale('ar'),
      'en' => const Locale('en'),
      'zh' => const Locale('zh'),
      'fr' => const Locale('fr'),
      _ => const Locale('ar'),
    };
  }
}
