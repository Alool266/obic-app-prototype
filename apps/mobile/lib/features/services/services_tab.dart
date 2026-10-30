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
import '../africa_in_hand/africa_in_hand_page.dart';
import '../africa_in_hand/africa_in_hand_strings.dart';
import '../africa_in_hand/africa_media.dart';
import '../china_in_hand/china_in_hand_page.dart';
import '../china_in_hand/china_in_hand_strings.dart';
import '../china_in_hand/china_media.dart';
import '../daily_life/daily_life_page.dart';
import '../daily_life/daily_life_strings.dart';
import '../daily_life/daily_media.dart';
import '../logistics/logistics_hub_page.dart';
import '../mideast_in_hand/mideast_in_hand_page.dart';
import '../mideast_in_hand/mideast_in_hand_strings.dart';
import '../mideast_in_hand/mideast_media.dart';
import '../travel_hub/travel_hub_page.dart';
import '../travel_hub/travel_hub_strings.dart';
import '../travel_hub/travel_media.dart';
import '../../widgets/obic_cached_image.dart';
import '../../widgets/obic_soft_motion.dart';
import 'recent_services_store.dart';
import 'service_catalog.dart';
import 'service_hub_page.dart';
import 'services_api.dart';
import 'widgets/services_hero.dart';
import 'widgets/services_highlights.dart';
import 'widgets/soft_service_icon.dart';

/// Covered by يومي / سفر وسياحة hubs — hide from the messy home grid.
const _kHomeGridHiddenSlugs = <String>{
  'food',
  'healthcare',
  'travel',
  'transport',
};

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
    final lang = widget.localeController.langCode;
    // Hub-covered parents → dedicated pages (correct destination, no empty hub).
    switch (service.slug) {
      case 'food':
      case 'healthcare':
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => DailyLifePage(
              authController: widget.authController,
              langCode: lang,
            ),
          ),
        );
        return;
      case 'travel':
      case 'transport':
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => TravelHubPage(
              authController: widget.authController,
              langCode: lang,
            ),
          ),
        );
        return;
      case 'logistics':
        await openLogisticsTools(
          context: context,
          authController: widget.authController,
          langCode: lang,
        );
        return;
      default:
        break;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceHubPage(
          service: service,
          authController: widget.authController,
          langCode: lang,
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
        final allServices = snap.data ?? localCatalogSeed();
        final services = allServices
            .where((s) => !_kHomeGridHiddenSlugs.contains(s.slug))
            .toList();
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Builder(
                  builder: (context) {
                    final daily = DailyLifeStrings(langCode);
                    final travel = TravelHubStrings(langCode);
                    final china = ChinaInHandStrings(langCode);
                    final mideast = MideastInHandStrings(langCode);
                    final africa = AfricaInHandStrings(langCode);
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _PhotoHubCard(
                                title: daily.title,
                                subtitle: daily.subtitle,
                                photo: DailyMedia.hero,
                                accent: const Color(0xFF1A6DFF),
                                onTap: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute(
                                      builder: (_) => DailyLifePage(
                                        authController: widget.authController,
                                        langCode: langCode,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PhotoHubCard(
                                title: travel.title,
                                subtitle: travel.subtitle,
                                photo: TravelMedia.hero,
                                accent: const Color(0xFF0B4FD6),
                                onTap: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute(
                                      builder: (_) => TravelHubPage(
                                        authController: widget.authController,
                                        langCode: langCode,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _RegionPhotoHubCard(
                          title: china.title,
                          subtitle: china.subtitle,
                          photo: ChinaMedia.discoverChinaInHand,
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => ChinaInHandPage(
                                  authController: widget.authController,
                                  langCode: langCode,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _RegionPhotoHubCard(
                          title: mideast.title,
                          subtitle: mideast.subtitle,
                          photo: MideastMedia.discoverMideastInHand,
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => MideastInHandPage(
                                  authController: widget.authController,
                                  langCode: langCode,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _RegionPhotoHubCard(
                          title: africa.title,
                          subtitle: africa.subtitle,
                          photo: AfricaMedia.discoverAfricaInHand,
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => AfricaInHandPage(
                                  authController: widget.authController,
                                  langCode: langCode,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
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

class _PhotoHubCard extends StatelessWidget {
  const _PhotoHubCard({
    required this.title,
    required this.subtitle,
    required this.photo,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String photo;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ObicBounce(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 128,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ObicCachedImage(photo, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.15),
                      const Color(0xEE071628),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF8F5EE),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF93C5FD).withValues(alpha: 0.95),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionPhotoHubCard extends StatelessWidget {
  const _RegionPhotoHubCard({
    required this.title,
    required this.subtitle,
    required this.photo,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ObicBounce(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 112,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ObicCachedImage(photo, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      Color(0xEE071628),
                      Color(0x88071628),
                      Color(0x44071628),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF8F5EE),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFE8D48B).withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

