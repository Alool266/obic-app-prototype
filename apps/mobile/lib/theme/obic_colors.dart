// Made by Dr Ali
// Brand palette aligned with the interactive prototype (navy / OBIC blue).

import 'package:flutter/material.dart';

/// OBIC brand colors — keep client styling only; never embed secrets here.
abstract final class ObicColors {
  static const Color navy = Color(0xFF0B1F3A);
  static const Color navySoft = Color(0xFF122A4A);
  static const Color navyDeep = Color(0xFF071628);
  static const Color blue = Color(0xFF1A6DFF);
  static const Color blueDeep = Color(0xFF0B4FD6);
  static const Color blueSoft = Color(0xFFE8F1FF);
  /// Cool layered canvas (not cream / purple).
  static const Color background = Color(0xFFE6EDF6);
  static const Color backgroundDeep = Color(0xFFD9E3F0);
  /// WeChat-style list chrome (Me / Settings groups).
  static const Color listCanvas = Color(0xFFEDEDED);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color line = Color(0xFFD5DEEB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardRaised = Color(0xFFFBFCFE);
  /// WeChat / iOS-style unread badge red (#E53935).
  static const Color badgeRed = Color(0xFFE53935);

  // —— Dark (WeChat-like charcoal + OBIC blue; WCAG-friendly text) ——
  static const Color darkCanvas = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceRaised = Color(0xFF2C2C2E);
  /// Near-white primary text (~15:1 on canvas).
  static const Color darkInk = Color(0xFFF5F5F7);
  /// Secondary text ≥4.5:1 on #111 / #1C1C1E.
  static const Color darkMuted = Color(0xFFB0B0B8);
  static const Color darkLine = Color(0xFF3A3A3C);
  static const Color darkBlueSoft = Color(0xFF1A2744);
  static const Color darkChatCanvas = Color(0xFF0D0D0D);
  /// Unselected nav / chrome — brighter than darkMuted for legibility.
  static const Color darkNavIdle = Color(0xFFC8C8D0);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Page / list background behind grouped rows.
  static Color canvasOf(BuildContext context) =>
      isDark(context) ? darkCanvas : listCanvas;

  /// Scaffold / home canvas (slightly cooler in light).
  static Color scaffoldOf(BuildContext context) =>
      isDark(context) ? darkCanvas : background;

  /// Grouped list / card surface.
  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : card;

  static Color surfaceRaisedOf(BuildContext context) =>
      isDark(context) ? darkSurfaceRaised : cardRaised;

  /// Body / list primary text (light: ink, dark: near-white).
  static Color inkOf(BuildContext context) =>
      isDark(context) ? darkInk : ink;

  /// Headlines that used navy in light — never navy-on-black.
  static Color titleOf(BuildContext context) =>
      isDark(context) ? darkInk : navy;

  static Color mutedOf(BuildContext context) =>
      isDark(context) ? darkMuted : muted;

  static Color lineOf(BuildContext context) =>
      isDark(context) ? darkLine : line;

  static Color blueSoftOf(BuildContext context) =>
      isDark(context) ? darkBlueSoft : blueSoft;

  static Color navIdleOf(BuildContext context) =>
      isDark(context) ? darkNavIdle : muted;

  /// Chat thread background.
  static Color chatCanvasOf(BuildContext context) =>
      isDark(context) ? darkChatCanvas : background;

  /// Prefer Theme colorScheme when available (same contrast rules).
  static Color onSurfaceOf(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (isDark(context)) return cs.onSurface;
    return ink;
  }

  static Color onSurfaceVariantOf(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (isDark(context)) {
      return cs.onSurfaceVariant.withValues(alpha: 1);
    }
    return muted;
  }
}
