// Made by Dr Ali
// WeChat / iOS-style red count badges for tab bar and list rows.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';

/// Compact circular (or short pill for 10+) unread count.
///
/// **Must** stay content-sized. [ListTile] trailing/leading often pass a
/// *tight* height equal to the whole row; a decorated [Container] then
/// stretches into a tall red bar. [UnconstrainedBox] drops those constraints
/// so this never expands to the tile height.
class ObicCountBadge extends StatelessWidget {
  const ObicCountBadge({
    super.key,
    required this.count,
    this.compact = false,
  });

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final label = count > 99 ? '99+' : '$count';
    final min = compact ? 16.0 : 18.0;
    final fontSize = compact ? 10.0 : 11.0;
    final multi = label.length > 1;
    final hPad = multi ? (compact ? 5.0 : 6.0) : 0.0;

    return UnconstrainedBox(
      child: Container(
        width: multi ? null : min,
        height: min,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        decoration: BoxDecoration(
          color: ObicColors.badgeRed,
          borderRadius: BorderRadius.circular(min / 2),
          border: Border.all(color: ObicColors.card, width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}

/// Icon / avatar with a compact count on the **top-end** corner (RTL-safe).
///
/// Use for Me menu rows, chat avatars, etc. Never put [ObicCountBadge] alone
/// in [ListTile.trailing] next to a chevron — that reintroduces stretch / dupes.
class ObicMenuBadgeIcon extends StatelessWidget {
  const ObicMenuBadgeIcon({
    super.key,
    required this.icon,
    required this.unread,
    this.size = 40,
  });

  final Widget icon;
  final int unread;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          icon,
          if (unread > 0)
            PositionedDirectional(
              top: -4,
              end: -6,
              child: ObicCountBadge(count: unread, compact: true),
            ),
        ],
      ),
    );
  }
}

/// Navigation tab icon with optional WeChat-style red badge overlay.
/// Material [Badge] is kept here — [NavigationBar] clips raw [Stack]s.
class ObicNavBadgeIcon extends StatelessWidget {
  const ObicNavBadgeIcon({
    super.key,
    required this.icon,
    required this.unread,
  });

  final Widget icon;
  final int unread;

  @override
  Widget build(BuildContext context) {
    if (unread <= 0) return icon;
    final label = unread > 99 ? '99+' : '$unread';
    return Badge(
      backgroundColor: ObicColors.badgeRed,
      // Small fixed padding → circle for 1 digit, short pill for 10+/99+.
      padding: EdgeInsets.symmetric(
        horizontal: label.length > 1 ? 5 : 4,
        vertical: 2,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      child: icon,
    );
  }
}

/// Small red dot when there are unread items but no numeric label needed.
class ObicRedDot extends StatelessWidget {
  const ObicRedDot({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return UnconstrainedBox(
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: ObicColors.badgeRed,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
