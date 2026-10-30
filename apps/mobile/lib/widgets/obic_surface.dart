// Made by Dr Ali
// Elevated surfaces + empty states — one visual language for the app.

import 'package:flutter/material.dart';

import '../theme/obic_colors.dart';
import '../theme/obic_elevation.dart';

enum ObicSurfaceLevel { flat, card, raised }

/// Layered white/navy surface with restrained shadow.
class ObicSurface extends StatelessWidget {
  const ObicSurface({
    super.key,
    required this.child,
    this.level = ObicSurfaceLevel.card,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.color,
  });

  final Widget child;
  final ObicSurfaceLevel level;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ??
        (level == ObicSurfaceLevel.raised
            ? ObicElevation.radiusLg
            : ObicElevation.radiusMd);
    final dark = ObicColors.isDark(context);
    final shadows = dark
        ? ObicElevation.level0
        : switch (level) {
            ObicSurfaceLevel.flat => ObicElevation.level0,
            ObicSurfaceLevel.card => ObicElevation.level1,
            ObicSurfaceLevel.raised => ObicElevation.level2,
          };
    final radius = BorderRadius.circular(r);
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? ObicColors.surfaceOf(context),
        borderRadius: radius,
        border: Border.all(
          color: ObicColors.lineOf(context).withValues(
            alpha: level == ObicSurfaceLevel.flat ? 0.9 : 0.55,
          ),
        ),
        boxShadow: shadows,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: box,
      ),
    );
  }
}

/// Consistent empty / guest placeholder with soft depth.
class ObicEmptyState extends StatelessWidget {
  const ObicEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ObicColors.blueSoftOf(context),
                    ObicColors.surfaceOf(context),
                  ],
                ),
                border: Border.all(
                  color: ObicColors.lineOf(context).withValues(alpha: 0.7),
                ),
                boxShadow: ObicColors.isDark(context)
                    ? ObicElevation.level0
                    : ObicElevation.level1,
              ),
              child: Icon(icon, color: ObicColors.blue, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ObicColors.inkOf(context),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ObicColors.mutedOf(context),
                    height: 1.45,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
