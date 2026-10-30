// Made by Dr Ali
// WeChat Moments pinned header — transparent over cover → light/frosted when collapsed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/obic_colors.dart';

const kMomentsCoverExpandedHeight = 220.0;
const kMomentsProfileCoverExpandedHeight = 240.0;

/// Collapse progress: 0 = cover fully visible, 1 = pinned toolbar only.
double momentsHeaderCollapseT({
  required double scrollOffset,
  required double topPadding,
  double expandedHeight = kMomentsCoverExpandedHeight,
}) {
  final collapsed = topPadding + kToolbarHeight;
  final range = (expandedHeight - collapsed).clamp(1.0, 400.0);
  return (scrollOffset / range).clamp(0.0, 1.0);
}

/// Pinned bar fill: clear over cover, frosted white / dark surface when collapsed.
Color momentsHeaderBarColor(BuildContext context, double t) {
  final dark = ObicColors.isDark(context);
  final solid = dark
      ? ObicColors.darkSurface.withValues(alpha: 0.96)
      : const Color(0xFFF7F7F7).withValues(alpha: 0.96);
  final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
  return Color.lerp(Colors.transparent, solid, eased)!;
}

/// Title + action ink: white over cover → dark ink (light) / near-white (dark).
Color momentsHeaderFgColor(BuildContext context, double t) {
  final dark = ObicColors.isDark(context);
  final collapsed = dark ? ObicColors.darkInk : ObicColors.ink;
  final eased = Curves.easeIn.transform(t.clamp(0.0, 1.0));
  return Color.lerp(Colors.white, collapsed, eased)!;
}

SystemUiOverlayStyle momentsHeaderSystemUi(BuildContext context, double t) {
  final dark = ObicColors.isDark(context);
  if (t < 0.55) {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );
  }
  if (dark) {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );
  }
  return const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );
}

/// Soft bottom wash so cover meets the feed without a heavy black crush.
Widget momentsCoverBottomFade({double height = 56}) {
  return Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    height: height,
    child: const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00000000),
            Color(0x33000000), // ~0.20 — name/avatar legibility only
          ],
        ),
      ),
    ),
  );
}
