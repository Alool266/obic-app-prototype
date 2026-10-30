// Made by Dr Ali
// OBIC AI avatar — same brand asset as floating bubble / app icon (not a person).

import 'package:flutter/material.dart';

import '../../widgets/obic_logo.dart';
import 'obic_ai_floating_bubble.dart';

/// Chat / list avatar for OBIC AI auto-reply and the AI assistant identity.
class ObicAiAvatar extends StatelessWidget {
  const ObicAiAvatar({
    super.key,
    this.size = 36,
    this.borderRadius,
    this.useGlassMark = false,
  });

  final double size;
  final double? borderRadius;

  /// When true, uses the Home floating glass mark; otherwise the OBIC app icon.
  final bool useGlassMark;

  @override
  Widget build(BuildContext context) {
    if (useGlassMark) {
      return SizedBox(
        width: size,
        height: size,
        child: ObicAiGlassMark(size: size),
      );
    }
    final r = borderRadius ?? (size * 0.18).clamp(4.0, 10.0);
    return ObicLogo(size: size, borderRadius: r);
  }
}
