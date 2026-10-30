// Made by Dr Ali
// Inner services grid — loads from API with local fallback.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../offers/offers_browse.dart';
import 'service_catalog.dart';
import 'service_detail_page.dart';
import 'service_icons.dart';
import 'service_sub_catalog.dart';
import 'services_api.dart';
import 'widgets/service_tiles.dart';

String _hubSubtitle(String langCode) {
  switch (langCode) {
    case 'ar':
      return 'اختر الخدمة التي تحتاجها';
    case 'zh':
      return '选择您需要的服务';
    default:
      return 'Choose the service you need';
  }
}

String _sectionTitle(String langCode) {
  switch (langCode) {
    case 'ar':
      return 'الخدمات داخل هذا القسم';
    case 'zh':
      return '本分类下的服务';
    default:
      return 'Services in this section';
  }
}

class ServiceHubPage extends StatefulWidget {
  const ServiceHubPage({
    super.key,
    required this.service,
    required this.authController,
    required this.langCode,
    this.subCatalog,
  });

  final ObicService service;
  final AuthController authController;
  final String langCode;
  final SubCatalogRepository? subCatalog;

  @override
  State<ServiceHubPage> createState() => _ServiceHubPageState();
}

class _ServiceHubPageState extends State<ServiceHubPage> {
  late final SubCatalogRepository _subs =
      widget.subCatalog ?? SubCatalogRepository();
  late Future<List<ObicSubService>> _future;

  @override
  void initState() {
    super.initState();
    _future = _subs.loadForParent(widget.service.slug);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ServiceTheme.of(widget.service.colorKey);

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(widget.service.name(widget.langCode)),
      ),
      body: FutureBuilder<List<ObicSubService>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? subServicesForParent(widget.service.slug);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                decoration: BoxDecoration(
                  gradient: theme.gradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Solid white chip + ink logo (avoids washed double-circle
                    // that looked like a stray play overlay on the suitcase).
                    CatalogLogoCircle(
                      icon: serviceIconData(widget.service.icon),
                      ink: theme.ink,
                      fill: Colors.white,
                      size: 52,
                      iconSize: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.service.name(widget.langCode),
                            softWrap: true,
                            maxLines: 2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hubSubtitle(widget.langCode),
                            softWrap: true,
                            maxLines: 2,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (widget.service.slug == 'food') ...[
                OffersSection(
                  kind: 'restaurants',
                  arabic: widget.langCode == 'ar',
                  authController: widget.authController,
                  service: widget.service,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.langCode == 'ar'
                      ? 'تصفح حسب نوع المطبخ'
                      : widget.langCode == 'zh'
                          ? '按菜系浏览'
                          : 'Browse by cuisine',
                  style: TextStyle(
                    color: ObicColors.titleOf(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
              Text(
                _sectionTitle(widget.langCode),
                style: TextStyle(
                  color: ObicColors.titleOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ],
              if (snap.connectionState == ConnectionState.waiting &&
                  snap.data == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ObicColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    AppLocalizations.of(context).regionUnavailable,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ObicColors.mutedOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                _SubServiceIconGrid(
                  items: items,
                  langCode: widget.langCode,
                  onTap: (sub) {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailPage(
                          service: widget.service,
                          authController: widget.authController,
                          langCode: widget.langCode,
                          subService: sub,
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Layer 2 — dense WeChat-style circular sub-icons.
class _SubServiceIconGrid extends StatelessWidget {
  const _SubServiceIconGrid({
    required this.items,
    required this.langCode,
    required this.onTap,
  });

  final List<ObicSubService> items;
  final String langCode;
  final ValueChanged<ObicSubService> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        // Tighter cells — smaller icons, less empty vertical space.
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, i) {
        final sub = items[i];
        final colors = subServiceIconColors(sub.icon);
        return InkWell(
          onTap: () => onTap(sub),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CatalogLogoCircle(
                  icon: subServiceIcon(sub.icon),
                  ink: colors.ink,
                  fill: colors.soft,
                  size: 40,
                  iconSize: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  sub.name(langCode),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ObicColors.titleOf(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  catalogPriceDisplay(sub.price(langCode)),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
