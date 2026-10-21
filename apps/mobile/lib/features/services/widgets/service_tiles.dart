// Made by Dr Ali
// Ctrip-style primary colored tiles + secondary soft tiles (same size as primary).

import 'package:flutter/material.dart';

import '../../../theme/obic_colors.dart';
import '../service_catalog.dart';

/// WeChat-style 10 mega icons — two rows of five colored tiles.
class MegaCategoryGrid extends StatelessWidget {
  const MegaCategoryGrid({
    super.key,
    required this.services,
    required this.langCode,
    required this.onTap,
  });

  final List<ObicService> services;
  final String langCode;
  final ValueChanged<ObicService> onTap;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();
    final row1 = services.take(5).toList();
    final row2 = services.skip(5).take(5).toList();
    return Column(
      children: [
        PrimaryServiceTiles(
          services: row1,
          langCode: langCode,
          onTap: onTap,
        ),
        if (row2.isNotEmpty) ...[
          const SizedBox(height: 8),
          PrimaryServiceTiles(
            services: row2,
            langCode: langCode,
            onTap: onTap,
          ),
        ],
      ],
    );
  }
}

class PrimaryServiceTiles extends StatelessWidget {
  const PrimaryServiceTiles({
    super.key,
    required this.services,
    required this.langCode,
    required this.onTap,
  });

  final List<ObicService> services;
  final String langCode;
  final ValueChanged<ObicService> onTap;

  @override
  Widget build(BuildContext context) {
    return _ServiceTileRow(
      services: services,
      langCode: langCode,
      onTap: onTap,
      primary: true,
    );
  }
}

class SecondaryServiceGrid extends StatelessWidget {
  const SecondaryServiceGrid({
    super.key,
    required this.services,
    required this.langCode,
    required this.onTap,
    this.columns = 5,
  });

  final List<ObicService> services;
  final String langCode;
  final ValueChanged<ObicService> onTap;
  /// Same column count as primary row so white tiles match Hotels tile size.
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < services.length; i += columns) {
      final end = (i + columns).clamp(0, services.length);
      final chunk = services.sublist(i, end);
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(
        _ServiceTileRow(
          services: chunk,
          langCode: langCode,
          onTap: onTap,
          primary: false,
          columns: columns,
        ),
      );
    }
    return Column(children: rows);
  }
}

class _ServiceTileRow extends StatelessWidget {
  const _ServiceTileRow({
    required this.services,
    required this.langCode,
    required this.onTap,
    required this.primary,
    this.columns = 5,
  });

  final List<ObicService> services;
  final String langCode;
  final ValueChanged<ObicService> onTap;
  final bool primary;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final slots = List<ObicService?>.from(services);
    while (slots.length < columns) {
      slots.add(null);
    }

    return Row(
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: slots[i] == null
                ? const SizedBox.shrink()
                : _ServiceTile(
                    service: slots[i]!,
                    langCode: langCode,
                    onTap: () => onTap(slots[i]!),
                    primary: primary,
                  ),
          ),
        ],
      ],
    );
  }
}

/// Prefer wrapping price segments (e.g. "من 2000¥ · تسجيل 8000¥") on separate
/// lines so money info is not clipped by ellipsis in narrow 4-col cells.
String catalogPriceDisplay(String price) {
  return price
      .replaceAll(' · ', '\n')
      .replaceAll(' • ', '\n')
      .replaceAll(' ·', '\n')
      .replaceAll(' •', '\n');
}

/// Shared circular logo chip — consistent padding so icons sit professionally.
class CatalogLogoCircle extends StatelessWidget {
  const CatalogLogoCircle({
    super.key,
    required this.icon,
    required this.ink,
    this.fill,
    this.gradient,
    this.size = 56,
    this.iconSize = 28,
    this.shadow,
  });

  final IconData icon;
  final Color ink;
  final Color? fill;
  final Gradient? gradient;
  final double size;
  final double iconSize;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient == null ? (fill ?? Colors.white) : null,
        gradient: gradient,
        boxShadow: shadow,
      ),
      child: Icon(icon, color: ink, size: iconSize),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.langCode,
    required this.onTap,
    required this.primary,
  });

  final ObicService service;
  final String langCode;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = ServiceTheme.of(service.colorKey);
    // Alipay / WeChat style: circular icon chip + label under (not a filled card).
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CatalogLogoCircle(
                icon: serviceIconData(service.icon),
                ink: primary ? Colors.white : theme.ink,
                fill: primary ? null : theme.soft,
                gradient: primary ? theme.gradient : null,
                size: 44,
                iconSize: 22,
                shadow: [
                  BoxShadow(
                    color: (primary ? theme.ink : ObicColors.navy)
                        .withValues(alpha: primary ? 0.18 : 0.08),
                    blurRadius: primary ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                service.name(langCode),
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  color: ObicColors.titleOf(context),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
