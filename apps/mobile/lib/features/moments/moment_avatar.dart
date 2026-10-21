// Made by Dr Ali
// WeChat Moments–style avatar (network or initials).

import 'package:flutter/material.dart';

import '../../core/media_url.dart';
import '../../widgets/obic_cached_image.dart';

class MomentAvatar extends StatelessWidget {
  const MomentAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 44,
    this.borderRadius,
  });

  final String name;
  final String? avatarUrl;
  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(avatarUrl);
    final r = borderRadius ?? 6;
    final trimmed = name.trim();
    final letter = trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first);

    Widget child;
    if (url.isNotEmpty) {
      child = ObicCachedImage(
        url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        // Avoid blank-frame flash when AppBar/list rebuilds (chat poll, nav).
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _Initials(letter: letter, size: size),
      );
    } else {
      child = _Initials(letter: letter, size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.letter, required this.size});

  final String letter;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hue = (letter.codeUnitAt(0) * 37) % 360;
    return ColoredBox(
      color: HSLColor.fromAHSL(1, hue.toDouble(), 0.42, 0.55).toColor(),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }
}
