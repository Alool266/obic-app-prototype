// Made by Dr Ali
// Ctrip-style travel hub — Obic navy/blue, photo-rich, premium, RTL.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_back_button.dart';
import '../../widgets/obic_cached_image.dart';
import '../../widgets/obic_soft_motion.dart';
import '../auth/auth_controller.dart';
import '../marketplace/marketplace_hub_search_card.dart';
import '../marketplace/marketplace_models.dart';
import '../marketplace/open_marketplace_category.dart';
import 'travel_hub_catalog.dart';
import 'travel_hub_strings.dart';
import 'travel_media.dart';
import 'travel_tabs.dart';
import '../hub_chrome/hub_app_bar_actions.dart';
import '../hub_chrome/hub_content_api.dart';
import '../hub_chrome/hub_id.dart';
import '../hub_chrome/hub_onboarding.dart';
import '../hub_chrome/hub_prefs.dart';
import '../hub_chrome/hub_profile_strip.dart';
import '../hub_chrome/hub_strings.dart';

class TravelHubPage extends StatefulWidget {
  const TravelHubPage({
    super.key,
    required this.authController,
    required this.langCode,
  });

  final AuthController authController;
  final String langCode;

  @override
  State<TravelHubPage> createState() => _TravelHubPageState();
}

class _TravelHubPageState extends State<TravelHubPage> {
  late final TravelHubStrings s = TravelHubStrings(widget.langCode);
  late final HubChromeStrings hs = HubChromeStrings(widget.langCode, ObicHubId.travel);
  late final HubPrefs _hubPrefs = HubPrefs(ObicHubId.travel);
  final _hubApi = HubContentApi();
  final _search = TextEditingController();
  final _bannerPage = PageController(viewportFraction: 0.92);
  int _bannerIndex = 0;
  int _tab = 0;
  Timer? _autoBanner;
  List<HubDealDto> _deals = const [];

  bool get _ar => widget.langCode.startsWith('ar');

  List<TravelPromo> get _promos {
    if (_deals.isEmpty) return const [];
    return [
      for (final d in _deals)
        TravelPromo(
          ar: d.titleAr,
          en: d.titleEn,
          photo: TravelMedia.hotel,
          tint: const Color(0xFF0B1F3A),
          parentSlug: 'travel',
          subServiceId: d.target,
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim();
      if (q.length >= 2) _hubPrefs.pushRecentSearch(q);
    });
    _hubApi.fetchDeals('travel').then((d) {
      if (mounted) setState(() => _deals = d);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowHubOnboarding(
        context: context,
        hub: ObicHubId.travel,
        langCode: widget.langCode,
      );
    });
    _autoBanner = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerPage.hasClients) return;
      if (obicReduceMotion(context)) return;
      // Loop عروض السفر (must match PageView itemCount).
      final list = _promos;
      if (list.isEmpty) return;
      final next = (_bannerIndex + 1) % list.length;
      _bannerPage.animateToPage(
        next,
        duration: const Duration(milliseconds: 680),
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

  Future<void> _openCat(TravelCat cat) async {
    if (isTravelServiceRequestId(cat.id) ||
        isTravelServiceRequestId(cat.subServiceId ?? '')) {
      await openTravelServiceRequest(
        context: context,
        authController: widget.authController,
        langCode: widget.langCode,
        catId: cat.id,
      );
      return;
    }
    final vertical =
        travelVerticalForId(cat.id) ?? MarketplaceVertical.hotel;
    await openMarketplaceCategory(
      context: context,
      authController: widget.authController,
      langCode: widget.langCode,
      vertical: vertical,
      titleOverride: cat.label(widget.langCode),
    );
  }

  Future<void> _openPromo(TravelPromo p) async {
    final id = p.subServiceId ?? 'hotels';
    if (isTravelServiceRequestId(id)) {
      await openTravelServiceRequest(
        context: context,
        authController: widget.authController,
        langCode: widget.langCode,
        catId: id,
      );
      return;
    }
    final vertical = travelVerticalForId(id) ??
        (p.parentSlug == 'transport'
            ? MarketplaceVertical.flight
            : MarketplaceVertical.hotel);
    await openMarketplaceCategory(
      context: context,
      authController: widget.authController,
      langCode: widget.langCode,
      vertical: vertical,
    );
  }

  Future<void> _onHubSearch(String raw) async {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return;
    if (q.contains('visa') || q.contains('تأشير') || q.contains('فيزا')) {
      await openTravelServiceRequest(
        context: context,
        authController: widget.authController,
        langCode: widget.langCode,
        catId: 'visa',
      );
      return;
    }
    if (q.contains('flight') || q.contains('طيران') || q.contains('航班')) {
      await openMarketplaceCategory(
        context: context,
        authController: widget.authController,
        langCode: widget.langCode,
        vertical: MarketplaceVertical.flight,
      );
      return;
    }
    if (q.contains('train') || q.contains('قطار') || q.contains('高铁')) {
      await openMarketplaceCategory(
        context: context,
        authController: widget.authController,
        langCode: widget.langCode,
        vertical: MarketplaceVertical.train,
      );
      return;
    }
    // City / hotel query → hotels filtered by city text.
    await openMarketplaceCategory(
      context: context,
      authController: widget.authController,
      langCode: widget.langCode,
      vertical: MarketplaceVertical.hotel,
      city: raw.trim(),
    );
  }

  Future<void> _showMore() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ObicColors.lineOf(ctx),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  s.more,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: ObicColors.titleOf(ctx),
                  ),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kTravelMore.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (_, i) {
                    final c = kTravelMore[i];
                    return ObicBounce(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openCat(c);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: ObicColors.blueSoftOf(ctx),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              c.icon,
                              color: ObicColors.blue,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.label(widget.langCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ObicColors.inkOf(ctx),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _cityLabel(({String ar, String en, String zh}) c) {
    if (_ar) return c.ar;
    if (widget.langCode.startsWith('zh')) return c.zh;
    return c.en;
  }

  Widget _tabPane(Widget child) {
    final top = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12, top + 6, 12, 8),
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: ObicBackButton(),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _homeBody(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: top + 156,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ObicCachedImage(
                    TravelMedia.hero,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: ObicColors.navy),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x99071628),
                          Color(0xBB0B1F3A),
                          Color(0xF2071628),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: top + 6,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        const ObicBackButton(),
                        const Spacer(),
                        HubHeroActions(
                          hub: ObicHubId.travel,
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
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: const Color(0xFFE8D48B)
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          child: Text(
                            _ar
                                ? 'تطبيق سفر · داخل أوبك'
                                : 'Travel mini-app · inside OBIC',
                            style: const TextStyle(
                              color: Color(0xFFE8D48B),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.title,
                          style: const TextStyle(
                            color: Color(0xFFF8F5EE),
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color: Color(0x88000000),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.subtitle,
                          style: const TextStyle(
                            color: Color(0xFFE0F2FE),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.2,
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
              child: MarketplaceHubSearchCard(
                authController: widget.authController,
                langCode: widget.langCode,
                searchController: _search,
                searchHint: s.searchHint,
                eyebrow: _ar ? 'الوجهة' : 'Destination',
                fallbackCity: _ar ? 'ييوو · الصين' : 'Yiwu · China',
                onAddressChanged: () {
                  if (mounted) setState(() {});
                },
                onSearchSubmitted: _onHubSearch,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: HubProfileStrip(
                authController: widget.authController,
                langCode: widget.langCode,
                hub: ObicHubId.travel,
                onRecentTap: (q) {
                  _search.text = q;
                  setState(() {});
                  _onHubSearch(q);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                s.topCats,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: ObicColors.titleOf(context),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: kTravelTop.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final c = kTravelTop[i];
                  return ObicSlideIn(
                    index: i,
                    child: ObicBounce(
                      onTap: () => _openCat(c),
                      child: SizedBox(
                        width: 92,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox(
                                width: 76,
                                height: 76,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ObicCachedImage(c.photo, fit: BoxFit.cover),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            c.accent.withValues(alpha: 0.72),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Icon(
                                        c.icon,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c.label(widget.langCode),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: ObicColors.inkOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Row(
                children: [
                  for (final c in kTravelSecond)
                    Expanded(
                      child: ObicBounce(
                        onTap: () => _openCat(c),
                        child: Column(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: ObicColors.blueSoftOf(context),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                c.icon,
                                color: ObicColors.blueDeep,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              c.label(widget.langCode),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: ObicColors.inkOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: ObicBounce(
                      onTap: _showMore,
                      child: Column(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: ObicColors.navy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: ObicColors.lineOf(context),
                              ),
                            ),
                            child: const Icon(
                              Icons.more_horiz_rounded,
                              color: ObicColors.navy,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.more,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: ObicColors.inkOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                s.cities,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: ObicColors.titleOf(context),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: kTravelCities.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = kTravelCities[i];
                  return ObicBounce(
                    onTap: () => openMarketplaceCategory(
                      context: context,
                      authController: widget.authController,
                      langCode: widget.langCode,
                      vertical: MarketplaceVertical.hotel,
                      city: c.en,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: ObicColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: ObicColors.lineOf(context)),
                      ),
                      child: Text(
                        _cityLabel(c),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: ObicColors.titleOf(context),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Text(
                s.promos,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: ObicColors.titleOf(context),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 132,
              child: PageView.builder(
                controller: _bannerPage,
                itemCount: _promos.length,
                onPageChanged: (i) => setState(() => _bannerIndex = i),
                itemBuilder: (context, i) {
                  final p = _promos[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ObicBounce(
                      onTap: () => _openPromo(p),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ObicCachedImage(p.photo, fit: BoxFit.cover),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: AlignmentDirectional.centerStart,
                                  end: AlignmentDirectional.centerEnd,
                                  colors: [
                                    p.tint.withValues(alpha: 0.88),
                                    p.tint.withValues(alpha: 0.25),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  _ar ? p.ar : p.en,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: ObicBounce(
                onTap: () => openMarketplaceCategory(context: context, authController: widget.authController, langCode: widget.langCode, vertical: MarketplaceVertical.tour),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [
                        Color(0xFF071628),
                        Color(0xFF0B1F3A),
                        Color(0xFF163A5F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFC9A227).withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A227).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFE8D48B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.aiTrip,
                              style: const TextStyle(
                                color: Color(0xFFF8F5EE),
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.aiTripBody,
                              style: TextStyle(
                                color: const Color(0xFFE8D48B)
                                    .withValues(alpha: 0.9),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: ObicColors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          s.aiCta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <({IconData icon, String label})>[
      (
        icon: Icons.home_rounded,
        label: _ar ? 'الرئيسية' : 'Home',
      ),
      (
        icon: Icons.mail_outline_rounded,
        label: _ar ? 'رسائل' : 'Inbox',
      ),
      (
        icon: Icons.groups_rounded,
        label: _ar ? 'مجتمع' : 'Community',
      ),
      (
        icon: Icons.luggage_rounded,
        label: _ar ? 'رحلاتي' : 'Trips',
      ),
      (
        icon: Icons.person_rounded,
        label: _ar ? 'حسابي' : 'Me',
      ),
    ];

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      body: IndexedStack(
        index: _tab,
        children: [
          _homeBody(context),
          _tabPane(TravelMessagesTab(
            authController: widget.authController,
            langCode: widget.langCode,
          )),
          _tabPane(TravelCommunityTab(
            authController: widget.authController,
            langCode: widget.langCode,
          )),
          _tabPane(
            TravelTripsTab(
              authController: widget.authController,
              langCode: widget.langCode,
            ),
          ),
          _tabPane(
            TravelAccountTab(
              authController: widget.authController,
              langCode: widget.langCode,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        height: 64,
        backgroundColor: ObicColors.surfaceOf(context),
        indicatorColor: ObicColors.blueSoftOf(context),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.icon, color: ObicColors.blue),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
