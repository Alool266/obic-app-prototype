// Made by Dr Ali
// الصين بين يديك — big category cards; services open inside each category.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_back_button.dart';
import '../../widgets/obic_cached_image.dart';
import '../../widgets/obic_soft_motion.dart';
import '../auth/auth_controller.dart';
import 'china_category_page.dart';
import 'china_in_hand_catalog.dart';
import 'china_in_hand_icons.dart';
import 'china_in_hand_strings.dart';
import 'china_media.dart';
import 'china_tile_nav.dart';
import 'china_visit_banner.dart';
import '../hub_chrome/hub_app_bar_actions.dart';
import '../hub_chrome/hub_id.dart';
import '../hub_chrome/hub_onboarding.dart';
import '../hub_chrome/hub_prefs.dart';
import '../hub_chrome/hub_profile_strip.dart';

class ChinaInHandPage extends StatefulWidget {
  const ChinaInHandPage({
    super.key,
    required this.authController,
    required this.langCode,
  });

  final AuthController authController;
  final String langCode;

  @override
  State<ChinaInHandPage> createState() => _ChinaInHandPageState();
}

class _ChinaInHandPageState extends State<ChinaInHandPage> {
  final _search = TextEditingController();
  late ChinaInHandStrings s;
  int _bannerIndex = 0;
  double _pageOffset = 0;
  final _bannerPage = PageController();
  Timer? _autoBanner;

  bool get _rtl => widget.langCode.startsWith('ar');

  static const _banners = ChinaMedia.hubCarousel;

  late final HubPrefs _hubPrefs = HubPrefs(ObicHubId.china);

  @override
  void initState() {
    super.initState();
    s = ChinaInHandStrings(widget.langCode);
    _search.addListener(() {
      setState(() {});
      final q = _search.text.trim();
      if (q.length >= 2) {
        _hubPrefs.pushRecentSearch(q);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowHubOnboarding(
        context: context,
        hub: ObicHubId.china,
        langCode: widget.langCode,
      );
    });
    _bannerPage.addListener(() {
      if (!mounted || !_bannerPage.hasClients) return;
      setState(() => _pageOffset = _bannerPage.page ?? 0);
    });
    _autoBanner = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_bannerPage.hasClients) return;
      if (obicReduceMotion(context)) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _bannerPage.animateToPage(
        next,
        duration: const Duration(milliseconds: 720),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoBanner?.cancel();
    _search.dispose();
    _bannerPage.dispose();
    super.dispose();
  }

  bool _isExcluded(ChinaHubTile t) {
    if (kChinaHubExcludedIds.contains(t.id)) return true;
    if (kChinaHubExcludedIds.contains(t.parentSlug)) return true;
    if (t.subServiceId != null &&
        kChinaHubExcludedIds.contains(t.subServiceId)) {
      return true;
    }
    return false;
  }

  List<ChinaHubSection> get _landingCategories {
    final out = <ChinaHubSection>[];
    for (final section in kChinaInHandLandingCategories()) {
      final tiles = section.tiles.where((t) => !_isExcluded(t)).toList();
      if (tiles.isEmpty) continue;
      out.add(
        ChinaHubSection(
          id: section.id,
          titleAr: section.titleAr,
          titleEn: section.titleEn,
          titleZh: section.titleZh,
          tiles: tiles,
        ),
      );
    }
    return out;
  }

  List<ChinaHubTile> get _searchHits {
    final q = _search.text;
    final hits = <ChinaHubTile>[];
    final seen = <String>{};
    for (final section in kChinaInHandLandingCategories()) {
      for (final t in section.tiles) {
        if (_isExcluded(t)) continue;
        if (!t.matchesQuery(q, widget.langCode)) continue;
        if (!seen.add(t.id)) continue;
        hits.add(t);
      }
    }
    return hits;
  }

  Future<void> _openCategory(ChinaHubSection section) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChinaCategoryPage(
          authController: widget.authController,
          langCode: widget.langCode,
          section: section,
        ),
      ),
    );
  }

  String _bannerTagline(int i) {
    switch (i % 4) {
      case 1:
        return s.bannerTagline2;
      case 2:
        return s.bannerTagline3;
      case 3:
        return s.bannerTagline1;
      default:
        return s.bannerTagline1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final searching = query.isNotEmpty;
    final categories = _landingCategories;
    final hits = searching ? _searchHits : const <ChinaHubTile>[];

    final topPad = MediaQuery.paddingOf(context).top;
    final heroHeight = topPad + 248;

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: heroHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _bannerPage,
                    itemCount: _banners.length,
                    onPageChanged: (i) => setState(() => _bannerIndex = i),
                    itemBuilder: (context, i) {
                      final delta = (_pageOffset - i).clamp(-1.0, 1.0);
                      final parallax = delta * 36;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Transform.translate(
                            offset: Offset(parallax, 0),
                            child: Transform.scale(
                              scale: 1.08,
                              child: ObicCachedImage(
                                _banners[i],
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (_, _, _) => Image.asset(
                                  ChinaMedia.fallbackCover,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x66071628),
                                  Color(0x220B1F3A),
                                  Color(0xE6071628),
                                ],
                                stops: [0, 0.42, 1],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Positioned(
                    top: topPad + 6,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        const ObicBackButton(),
                        const Spacer(),
                        HubHeroActions(
                          hub: ObicHubId.china,
                          langCode: widget.langCode,
                          authController: widget.authController,
                          cityChoices: const [
                            'Yiwu',
                            'Shanghai',
                            'Beijing',
                            'Guangzhou',
                            'Hangzhou',
                            'Shenzhen',
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style: const TextStyle(
                            color: Color(0xFFF8F5EE),
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            letterSpacing: 0.2,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.subtitle,
                          style: TextStyle(
                            color:
                                const Color(0xFFE8D48B).withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bannerTagline(_bannerIndex),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                const Color(0xFFF8F5EE).withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _banners.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: i == _bannerIndex ? 18 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i == _bannerIndex
                                  ? const Color(0xFFC9A227)
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _LocaleSearchField(
                controller: _search,
                hint: s.searchHint,
                isRtl: _rtl,
                onClear: () {
                  _search.clear();
                  setState(() {});
                },
              ),
            ),
          ),
          if (!searching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: HubProfileStrip(
                  authController: widget.authController,
                  langCode: widget.langCode,
                  hub: ObicHubId.china,
                  onRecentTap: (q) {
                    _search.text = q;
                    setState(() {});
                  },
                ),
              ),
            ),
          if (searching && hits.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 40,
                      color: ObicColors.mutedOf(context),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.noResults,
                      style: TextStyle(
                        color: ObicColors.titleOf(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (searching)
            ContainedSliver(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  children: [
                    for (var i = 0; i < hits.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      ObicSlideIn(
                        index: i,
                        child: _SearchHitTile(
                          tile: hits[i],
                          langCode: widget.langCode,
                          onTap: () => openChinaHubTile(
                            context: context,
                            authController: widget.authController,
                            langCode: widget.langCode,
                            tile: hits[i],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            ContainedSliver(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ChinaVisitBanner(
                  authController: widget.authController,
                  langCode: widget.langCode,
                ),
              ),
            ),
            ContainedSliver(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                child: Column(
                  children: [
                    for (var i = 0; i < categories.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      ObicSlideIn(
                        index: i,
                        child: _BigCategoryCard(
                          section: categories[i],
                          langCode: widget.langCode,
                          servicesLabel: s.categoryServicesCount(
                            categories[i].tiles.length,
                          ),
                          onTap: () => _openCategory(categories[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ContainedSliver extends StatelessWidget {
  const ContainedSliver({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: child);
  }
}

class _BigCategoryCard extends StatelessWidget {
  const _BigCategoryCard({
    required this.section,
    required this.langCode,
    required this.servicesLabel,
    required this.onTap,
  });

  final ChinaHubSection section;
  final String langCode;
  final String servicesLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = chinaCategoryVisual(section.id);
    final hero = ChinaMedia.categoryHero(section.id);
    return ObicBounce(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 124,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFC9A227).withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: ObicColors.navy.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ObicCachedImage(hero, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    ObicColors.navy.withValues(alpha: 0.92),
                    Color.lerp(ObicColors.navy, visual.soft, 0.4)!
                        .withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: visual.ink.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(visual.icon, color: visual.ink, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          section.title(langCode),
                          style: const TextStyle(
                            color: Color(0xFFF8F5EE),
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          servicesLabel,
                          style: TextStyle(
                            color:
                                const Color(0xFFE8D48B).withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: const Color(0xFFC9A227).withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHitTile extends StatelessWidget {
  const _SearchHitTile({
    required this.tile,
    required this.langCode,
    required this.onTap,
  });

  final ChinaHubTile tile;
  final String langCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = chinaHubVisual(tile.id);
    final dark = ObicColors.isDark(context);
    return Material(
      color: ObicColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      visual.soft,
                      visual.soft.withValues(alpha: dark ? 0.5 : 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(visual.icon, color: visual.ink, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tile.label(langCode),
                  style: TextStyle(
                    color: ObicColors.inkOf(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ObicColors.mutedOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocaleSearchField extends StatelessWidget {
  const _LocaleSearchField({
    required this.controller,
    required this.hint,
    required this.isRtl,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final bool isRtl;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: ObicColors.surfaceOf(context).withValues(alpha: 0.92),
            elevation: ObicColors.isDark(context) ? 0 : 2,
            shadowColor: ObicColors.navy.withValues(alpha: 0.1),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.none,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: ObicColors.inkOf(context),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: ObicColors.mutedOf(context)),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: ObicColors.blue,
                ),
                suffixIcon: hasText
                    ? IconButton(
                        onPressed: onClear,
                        icon: Icon(
                          Icons.close_rounded,
                          color: ObicColors.mutedOf(context),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
