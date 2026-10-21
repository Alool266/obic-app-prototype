// Made by Dr Ali
// Featured and recent service cards under the catalog grid.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../../theme/obic_colors.dart';
import '../../../widgets/obic_lottie_empty.dart';
import '../../../widgets/obic_soft_motion.dart';
import '../service_catalog.dart';
import 'soft_service_icon.dart';

const _featuredSlugs = ['travel', 'food', 'healthcare', 'shopping'];

List<ObicService> featuredServices(List<ObicService> all) {
  final picked = <ObicService>[];
  for (final slug in _featuredSlugs) {
    for (final service in all) {
      if (service.slug == slug) {
        picked.add(service);
        break;
      }
    }
  }
  if (picked.length >= 3) return picked;
  return all.take(4).toList();
}

List<ObicService> recentServicesOf(List<ObicService> all, List<String> slugs) {
  final picked = <ObicService>[];
  for (final slug in slugs) {
    for (final service in all) {
      if (service.slug == slug) {
        picked.add(service);
        break;
      }
    }
  }
  return picked;
}

class ServicesSpotlight extends StatelessWidget {
  const ServicesSpotlight({
    super.key,
    required this.services,
    required this.recent,
    required this.langCode,
    required this.onTap,
  });

  final List<ObicService> services;
  final List<ObicService> recent;
  final String langCode;
  final ValueChanged<ObicService> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final featured = featuredServices(services);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(title: l10n.featured),
        if (featured.isEmpty)
          ObicLottieEmpty(message: l10n.discoverEmpty)
        else
          _CardStrip(services: featured, langCode: langCode, onTap: onTap),
        _Heading(title: l10n.servicesRecent),
        if (recent.isEmpty)
          ObicLottieEmpty(message: l10n.servicesRecentEmpty, size: 88)
        else
          _CardStrip(services: recent, langCode: langCode, onTap: onTap),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: ObicColors.titleOf(context),
        ),
      ),
    );
  }
}

class _CardStrip extends StatelessWidget {
  const _CardStrip({
    required this.services,
    required this.langCode,
    required this.onTap,
  });

  final List<ObicService> services;
  final String langCode;
  final ValueChanged<ObicService> onTap;

  @override
  Widget build(BuildContext context) {
    final dark = ObicColors.isDark(context);
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
        itemCount: services.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final service = services[index];
          return ObicSlideIn(
            index: index,
            child: ObicBounce(
              onTap: () => onTap(service),
              child: Container(
                width: 206,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ObicColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: ObicColors.lineOf(context).withValues(alpha: 0.8),
                  ),
                  boxShadow: dark
                      ? null
                      : [
                          BoxShadow(
                            color: ObicColors.navy.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Soft3dServiceMark(service: service, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      service.name(langCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ObicColors.titleOf(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(
                        service.desc(langCode),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ObicColors.mutedOf(context),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ),
                    Text(
                      service.price(langCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ObicColors.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
