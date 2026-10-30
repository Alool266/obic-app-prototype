// Made by Dr Ali
// Home — search, tiles, banners, promos, lists.

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mesh/mesh.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/obic_phrases.dart';
import '../../core/region_controller.dart';
import '../../l10n/locale_controller.dart';
import '../../core/obic_branches.dart';
import '../../theme/obic_colors.dart';
import '../../theme/obic_elevation.dart';
import '../../widgets/obic_logo.dart';
import '../../widgets/script_text_field.dart';
import '../auth/auth_controller.dart';
import '../scan/obic_scan_screen.dart';
import '../mini_apps/mini_apps_pull_panel.dart';
import 'branch_office_screen.dart';
import '../services/service_catalog.dart';
import '../services/service_hub_page.dart';
import '../services/services_api.dart';
import '../services/widgets/banner_slider.dart';
import '../services/widgets/service_tiles.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.authController,
    required this.localeController,
    required this.regionController,
    required this.catalogRepository,
    this.subCatalogRepository,
    this.onSeeAllServices,
  });

  final AuthController authController;
  final LocaleController localeController;
  final RegionController regionController;
  final CatalogRepository catalogRepository;
  final SubCatalogRepository? subCatalogRepository;
  final VoidCallback? onSeeAllServices;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<List<ObicService>> _future;
  String _query = '';
  final _miniAppsPull = MiniAppsPullController();

  @override
  void initState() {
    super.initState();
    widget.regionController.addListener(_onRegionChanged);
    _syncRegionAndLoad();
  }

  @override
  void dispose() {
    widget.regionController.removeListener(_onRegionChanged);
    super.dispose();
  }

  void _onRegionChanged() => _syncRegionAndLoad();

  void _syncRegionAndLoad() {
    widget.catalogRepository.setRegion(
      countryCode: widget.regionController.countryCode,
      cityName: widget.regionController.cityName,
    );
    setState(() {
      _future = widget.catalogRepository.load();
    });
  }

  void _openHub(ObicService service) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceHubPage(
          service: service,
          authController: widget.authController,
          langCode: widget.localeController.langCode,
          subCatalog: widget.subCatalogRepository,
        ),
      ),
    );
  }

  ObicService? _bySlug(List<ObicService> all, String slug) {
    for (final s in all) {
      if (s.slug == slug) return s;
    }
    return null;
  }

  void _openBySlug(List<ObicService> all, String slug) {
    final s = _bySlug(all, slug) ?? (all.isNotEmpty ? all.first : null);
    if (s != null) _openHub(s);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = widget.localeController.langCode;

    return FutureBuilder<List<ObicService>>(
      future: _future,
      builder: (context, snap) {
        final all =
            snap.data ??
            localCatalogSeed(countryCode: widget.regionController.countryCode);
        final filtered = _query.trim().isEmpty
            ? all
            : all.where((s) {
                final q = _query.toLowerCase();
                return s.nameAr.contains(_query) ||
                    s.nameEn.toLowerCase().contains(q) ||
                    s.nameZh.contains(_query) ||
                    s.descEn.toLowerCase().contains(q) ||
                    s.descAr.contains(_query) ||
                    s.descZh.contains(_query);
              }).toList();

        final mega = filtered.isEmpty ? all : filtered;
        final ranked = [
          for (final slug in ['travel', 'transport', 'property', 'government'])
            ...all.where((s) => s.slug == slug),
        ];
        final recommended = all.take(3).toList();

        return MiniAppsPullDownHost(
          displayName: () => widget.authController.user?.name,
          userId: widget.authController.user?.id,
          controller: _miniAppsPull,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HomeTopBar(
                      l10n: l10n,
                      authController: widget.authController,
                      localeController: widget.localeController,
                      regionController: widget.regionController,
                      onSearchChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MiniAppsPullCue(onTap: _miniAppsPull.open),
                  ),
                  SliverToBoxAdapter(child: _HomeLifestyleStrip(l10n: l10n)),
                  if (snap.connectionState == ConnectionState.waiting &&
                      snap.data == null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          borderRadius: BorderRadius.circular(2),
                          color: ObicColors.blue,
                          backgroundColor: ObicColors.blue.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                    ),
                  // Always show seed/cached catalog — never a blank forever-spinner.
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: MegaCategoryGrid(
                        services: mega,
                        langCode: langCode,
                        onTap: _openHub,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: HomeBannerSlider(
                        slides: [
                          BannerSlide(
                            asset: 'assets/banners/vip-china.jpg',
                            serviceSlug: 'travel',
                            eyebrow: l10n.featured,
                            title: l10n.vipTrip,
                            subtitle: l10n.vipTripDesc,
                            cta: l10n.bookPkg,
                          ),
                          BannerSlide(
                            asset: 'assets/banners/fast-visa.jpg',
                            serviceSlug: 'government',
                            eyebrow: l10n.fastTrack,
                            title: l10n.visaExpress,
                            subtitle: l10n.visaExpressDesc,
                            cta: l10n.from120,
                          ),
                          BannerSlide(
                            asset: 'assets/banners/open-bank.jpg',
                            serviceSlug: 'business',
                            eyebrow: l10n.setup,
                            title: l10n.openBank,
                            subtitle: l10n.openBankDesc,
                            cta: l10n.startReq,
                          ),
                        ],
                        onTap: (slug) => _openBySlug(all, slug),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: PromoRow(
                        visa: _bySlug(all, 'government'),
                        bank: _bySlug(all, 'business'),
                        langCode: langCode,
                        visaTitle: l10n.visaExpress,
                        bankTitle: l10n.openBank,
                        bankSubtitle: langCode.startsWith('ar')
                            ? 'إيوو · قوانغتشو · شنغهاي'
                            : langCode.startsWith('zh')
                            ? '义乌 · 广州 · 上海'
                            : 'Yiwu · Guangzhou · Shanghai',
                        onTap: _openHub,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: l10n.topServices,
                        action: l10n.seeAll,
                        onAction: widget.onSeeAllServices,
                      ),
                    ),
                  ),
                  if (ranked.isNotEmpty)
                    ...ranked.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      final theme = ServiceTheme.of(s.colorKey);
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _RankRow(
                            rank: i + 1,
                            service: s,
                            langCode: langCode,
                            soft: theme.soft,
                            ink: theme.ink,
                            onTap: () => _openHub(s),
                          ),
                        ),
                      );
                    }),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(title: l10n.recommended),
                    ),
                  ),
                  ...recommended.map((s) {
                    final theme = ServiceTheme.of(s.colorKey);
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _ListServiceCard(
                          service: s,
                          langCode: langCode,
                          soft: theme.soft,
                          ink: theme.ink,
                          onTap: () => _openHub(s),
                        ),
                      ),
                    );
                  }),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _NearMeBranches(
                        l10n: l10n,
                        langCode: langCode,
                        regionController: widget.regionController,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact first-viewport positioning — social + daily life, no marketing card.
class _HomeLifestyleStrip extends StatelessWidget {
  const _HomeLifestyleStrip({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeGreeting,
            style: TextStyle(
              color: ObicColors.titleOf(context),
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.25,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.homeHint,
            style: TextStyle(
              color: ObicColors.mutedOf(context),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.l10n,
    required this.authController,
    required this.localeController,
    required this.regionController,
    required this.onSearchChanged,
  });

  final AppLocalizations l10n;
  final AuthController authController;
  final LocaleController localeController;
  final RegionController regionController;
  final ValueChanged<String> onSearchChanged;

  String _regionLabel() {
    final langCode = localeController.langCode;
    final code = regionController.countryCode;
    if (code == null || code.isEmpty) return l10n.regionDetecting;
    final city = regionController.cityName;
    final nearest = nearestBranch(
      regionController.latitude,
      regionController.longitude,
      countryCode: code,
    );
    final base = city != null && city.isNotEmpty ? '$city · $code' : code;
    if (nearest == null || !regionController.hasCoordinates) return base;
    return '$base · ${nearest.distanceLabel(regionController.latitude, regionController.longitude, langCode: langCode)}';
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldEnd = ObicColors.scaffoldOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ObicColors.navy,
            ObicColors.isDark(context)
                ? ObicColors.darkSurface
                : ObicColors.navySoft,
            scaffoldEnd,
          ],
          stops: const [0, 0.72, 1],
        ),
      ),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: reduceMotion
              ? fallback
              : OMeshGradient(
                  mesh: OMeshRect(
                    width: 3,
                    height: 3,
                    vertices: [
                      (0.0, 0.0).v,
                      (0.5, 0.0).v,
                      (1.0, 0.0).v,
                      (0.0, 0.5).v,
                      (0.5, 0.45).v,
                      (1.0, 0.5).v,
                      (0.0, 1.0).v,
                      (0.5, 1.0).v,
                      (1.0, 1.0).v,
                    ],
                    colors: [
                      ObicColors.navy,
                      const Color(0xFF1D4ED8),
                      ObicColors.navy,
                      const Color(0xFF0F766E),
                      ObicColors.navySoft,
                      ObicColors.navy,
                      scaffoldEnd,
                      scaffoldEnd,
                      scaffoldEnd,
                    ],
                  ),
                ),
        ),
        Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const ObicLogo(size: 40, borderRadius: 12, metal: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      l10n.brandTag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: obicPhrase(context, ar: 'مسح', en: 'Scan', zh: '扫一扫'),
                  onPressed: () => openObicScanner(context, authController),
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.place_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _regionLabel(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (regionController.locating)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                )
              else
                TextButton(
                  onPressed: () => regionController.detectLocation(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.regionRefresh,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GlassContainer(
            useOwnLayer: true,
            quality: GlassQuality.standard,
            shape: const LiquidRoundedSuperellipse(borderRadius: 14),
            child: ObicScriptTextField(
              onChanged: onSearchChanged,
              style: TextStyle(color: ObicColors.inkOf(context)),
              decoration: InputDecoration(
                hintText: l10n.searchPlaceholder,
                hintStyle: TextStyle(
                  color: ObicColors.mutedOf(context),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: ObicColors.mutedOf(context),
                ),
                suffixIcon: IconButton(
                  tooltip: obicPhrase(context, ar: 'مسح', en: 'Scan', zh: '扫一扫'),
                  onPressed: () => openObicScanner(context, authController),
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: ObicColors.blue,
                    size: 22,
                  ),
                ),
                filled: true,
                fillColor: ObicColors.surfaceOf(context),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: ObicColors.blue,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
        ),
      ],
    );
  }
}

class _NearMeBranches extends StatelessWidget {
  const _NearMeBranches({
    required this.l10n,
    required this.langCode,
    required this.regionController,
  });

  final AppLocalizations l10n;
  final String langCode;
  final RegionController regionController;

  @override
  Widget build(BuildContext context) {
    final branches = branchesSortedByDistance(
      regionController.latitude,
      regionController.longitude,
      countryCode: regionController.countryCode,
    ).take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BranchDirectoryScreen(
                  langCode: langCode,
                  userLat: regionController.latitude,
                  userLng: regionController.longitude,
                ),
              ),
            );
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.nearMeTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ObicColors.inkOf(context),
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                langCode.startsWith('ar')
                    ? 'الكل'
                    : langCode.startsWith('zh')
                    ? '全部'
                    : 'All',
                style: const TextStyle(
                  color: ObicColors.blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ObicColors.mutedOf(context),
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.nearMeHint,
          style: TextStyle(color: ObicColors.mutedOf(context), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final b in branches)
              Material(
                color: ObicColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                elevation: ObicColors.isDark(context) ? 0 : 1,
                shadowColor: const Color(0x140B1F3A),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BranchOfficeScreen(
                          branch: b,
                          langCode: langCode,
                          userLat: regionController.latitude,
                          userLng: regionController.longitude,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ObicColors.lineOf(
                          context,
                        ).withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: ObicColors.blue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          b.distanceLabel(
                            regionController.latitude,
                            regionController.longitude,
                            langCode: langCode,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: ObicColors.inkOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ObicColors.inkOf(context),
              fontSize: 15,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                color: ObicColors.blue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.service,
    required this.langCode,
    required this.soft,
    required this.ink,
    required this.onTap,
  });

  final int rank;
  final ObicService service;
  final String langCode;
  final Color soft;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final desc = service.desc(langCode);
    final short = desc.length > 36 ? '${desc.substring(0, 36)}…' : desc;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: ObicColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ObicColors.lineOf(context).withValues(alpha: 0.6),
            ),
            boxShadow: ObicColors.isDark(context)
                ? ObicElevation.level0
                : ObicElevation.level1,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  '$rank',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: ObicColors.blue,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ink.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(serviceIconData(service.icon), color: ink),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name(langCode),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ObicColors.inkOf(context),
                        ),
                      ),
                      Text(
                        short,
                        style: TextStyle(
                          color: ObicColors.mutedOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  service
                      .price(langCode)
                      .replaceFirst(RegExp(r'^(From |من )'), ''),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ObicColors.blue,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListServiceCard extends StatelessWidget {
  const _ListServiceCard({
    required this.service,
    required this.langCode,
    required this.soft,
    required this.ink,
    required this.onTap,
  });

  final ObicService service;
  final String langCode;
  final Color soft;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final desc = service.desc(langCode);
    final short = desc.length > 40 ? '${desc.substring(0, 40)}…' : desc;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: ObicColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ObicColors.lineOf(context).withValues(alpha: 0.6),
            ),
            boxShadow: ObicColors.isDark(context)
                ? ObicElevation.level0
                : ObicElevation.level1,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: ServiceTheme.of(service.colorKey).gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: ObicColors.navy.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    serviceIconData(service.icon),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name(langCode),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ObicColors.inkOf(context),
                        ),
                      ),
                      Text(
                        short,
                        style: TextStyle(
                          color: ObicColors.mutedOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  service.price(langCode),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ObicColors.blue,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
