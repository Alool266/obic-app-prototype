// Made by Dr Ali
// Services tab — catalog grid, globe hero, featured and recent cards.
// Detail still opens the existing service hub.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../l10n/locale_controller.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/obic_lottie_empty.dart';
import '../auth/auth_controller.dart';
import 'recent_services_store.dart';
import 'service_catalog.dart';
import 'service_hub_page.dart';
import 'services_api.dart';
import 'widgets/services_hero.dart';
import 'widgets/services_highlights.dart';
import 'widgets/soft_service_icon.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({
    super.key,
    required this.authController,
    required this.localeController,
    required this.catalogRepository,
  });

  final AuthController authController;
  final LocaleController localeController;
  final CatalogRepository catalogRepository;

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  final _recentStore = RecentServicesStore();
  late Future<List<ObicService>> _future;
  List<String> _recentSlugs = const [];

  @override
  void initState() {
    super.initState();
    _future = widget.catalogRepository.load();
    unawaited(_loadRecent());
  }

  Future<void> _loadRecent() async {
    final slugs = await _recentStore.load();
    if (!mounted) return;
    setState(() => _recentSlugs = slugs);
  }

  Future<void> _openHub(ObicService service) async {
    final next = await _recentStore.remember(service.slug);
    if (!mounted) return;
    setState(() => _recentSlugs = next);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceHubPage(
          service: service,
          authController: widget.authController,
          langCode: widget.localeController.langCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = widget.localeController.langCode;

    return FutureBuilder<List<ObicService>>(
      future: _future,
      builder: (context, snap) {
        final services = snap.data ?? localCatalogSeed();
        final waiting =
            snap.connectionState == ConnectionState.waiting &&
            snap.data == null;
        final recent = recentServicesOf(services, _recentSlugs);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 12,
                  16,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.allServices,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: ObicColors.titleOf(context),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ObicColors.blueSoftOf(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${services.length}',
                        style: const TextStyle(
                          color: ObicColors.blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (waiting)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: ObicColors.blue,
                    backgroundColor: ObicColors.blue.withValues(alpha: 0.12),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: ServicesGlobeHero(title: l10n.servicesHeroTitle),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              sliver: SliverToBoxAdapter(
                child: services.isEmpty
                    ? ObicLottieEmpty(message: l10n.discoverEmpty)
                    : Soft3dServiceGrid(
                        services: services,
                        langCode: langCode,
                        onTap: (service) => unawaited(_openHub(service)),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: ServicesSpotlight(
                services: services,
                recent: recent,
                langCode: langCode,
                onTap: (service) => unawaited(_openHub(service)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        );
      },
    );
  }
}
