// Made by Dr Ali
// Layered depth tokens — soft elevation, no neon/glow spam.

import 'package:flutter/material.dart';

import 'obic_colors.dart';

/// Elevation ladder used across shell, cards, sheets, and CTAs.
abstract final class ObicElevation {
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  /// Flat inset chip / tile resting on scaffold.
  static List<BoxShadow> get level0 => const [];

  /// Soft card lift (lists, menu rows).
  static List<BoxShadow> get level1 => [
        BoxShadow(
          color: Color(0x140B1F3A),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color(0x081A6DFF),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ];

  /// Raised surface (auth card, featured panels).
  static List<BoxShadow> get level2 => [
        BoxShadow(
          color: Color(0x1A0B1F3A),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
        BoxShadow(
          color: Color(0x0C1A6DFF),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ];

  /// Floating chrome (bottom nav, FAB-like bars).
  static List<BoxShadow> get level3 => [
        BoxShadow(
          color: Color(0x240B1F3A),
          blurRadius: 28,
          offset: Offset(0, -6),
        ),
        BoxShadow(
          color: Color(0x0A1A6DFF),
          blurRadius: 10,
          offset: Offset(0, -2),
        ),
      ];

  /// Primary CTA pressable shadow (restrained blue depth).
  static List<BoxShadow> cta({bool pressed = false}) => [
        BoxShadow(
          color: ObicColors.blue.withValues(alpha: pressed ? 0.16 : 0.32),
          blurRadius: pressed ? 8 : 16,
          offset: Offset(0, pressed ? 3 : 8),
        ),
      ];

  static BorderSide get hairline => BorderSide(
        color: ObicColors.line.withValues(alpha: 0.85),
      );

  static BorderSide get hairlineSoft => BorderSide(
        color: ObicColors.line.withValues(alpha: 0.55),
      );
}
