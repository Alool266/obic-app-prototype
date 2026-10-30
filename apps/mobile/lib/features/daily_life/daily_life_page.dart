// Made by Dr Ali
// Meituan-style daily hub — Obic navy/blue, photo-rich, RTL.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_back_button.dart';
import '../../widgets/obic_cached_image.dart';
import '../../widgets/obic_soft_motion.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../marketplace/marketplace_hub_search_card.dart';
import '../marketplace/marketplace_models.dart';
import '../marketplace/open_marketplace_category.dart';
import '../marketplace/pages/merchant_shop_page.dart';
import 'daily_life_catalog.dart';
import 'daily_life_strings.dart';
import 'daily_media.dart';
import '../hub_chrome/hub_app_bar_actions.dart';
import '../hub_chrome/hub_content_api.dart';
import '../hub_chrome/hub_gps.dart';
import '../hub_chrome/hub_id.dart';
import '../hub_chrome/hub_onboarding.dart';
import '../hub_chrome/hub_prefs.dart';
import '../hub_chrome/hub_profile_strip.dart';
import '../hub_chrome/hub_states.dart';
import '../hub_chrome/hub_strings.dart';
import '../marketplace/marketplace_api.dart';

class DailyLifePage extends StatefulWidget {
  const DailyLifePage({
    super.key,
    required this.authController,
    required this.langCode,
  });

  final AuthController authController;
  final String langCode;

  @override
  State<DailyLifePage> createState() => _DailyLifePageState();
}

class _DailyLifePageState extends State<DailyLifePage> {
  late final DailyLifeStrings s = DailyLifeStrings(widget.langCode);
  late final HubChromeStrings hs = HubChromeStrings(widget.langCode, ObicHubId.daily);
  late final HubPrefs _hubPrefs = HubPrefs(ObicHubId.daily);
  final _search = TextEditingController();
  final _hubApi = HubContentApi();
  List<HubDealDto> _deals = const [];
  List<DailyMerchant> _merchants = kDailyMerchants;
  bool _loading = true;
  bool _offline = false;
  bool _gpsBusy = false;
  String? _error;

  bool get _ar => widget.langCode.startsWith('ar');

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() {});
      final q = _search.text.trim();
      if (q.length >= 2) _hubPrefs.pushRecentSearch(q);
    });
    _boot();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowHubOnboarding(
        context: context,
        hub: ObicHubId.daily,
        langCode: widget.langCode,
      );
    });
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });
    try {
      final dealsFut = _hubApi.fetchDeals('daily');
      final merchFut = marketplaceRepo.listMerchants(MarketplaceVertical.food);
      final deals = await dealsFut;
      final merch = await merchFut;
      if (!mounted) return;
      setState(() {
        _deals = deals;
        if (merch.isNotEmpty) {
          _merchants = [
            for (final m in merch)
              DailyMerchant(
                nameAr: m.nameAr,
                nameEn: m.nameEn,
                photo: m.photo,
                rating: m.rating,
                distanceKm: m.distanceKm,
                etaMin: m.etaMin,
                feeYuan: m.feeYuan,
                tags: m.tags,
                parentSlug: m.category == MarketplaceVertical.pharmacy
                    ? 'healthcare'
                    : m.category == MarketplaceVertical.market
                        ? 'shopping'
                        : m.category == MarketplaceVertical.errand
                            ? 'logistics'
                            : 'food',
              ),
          ];
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'err';
        _offline = true;
      });
    }
  }

  Future<void> _useGps() async {
    if (_gpsBusy) return;
    setState(() => _gpsBusy = true);
    try {
      final ok = await requireAuth(context, widget.authController);
      if (!mounted || !ok) return;
      final gps = await applyGpsAsDefaultAddress(widget.authController);
      if (!mounted) return;
      if (gps == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hs.offlineHint)),
        );
      } else {
        await _hubPrefs.setDefaultCity(gps.city);
        setState(() {});
      }
    } finally {
      if (mounted) setState(() => _gpsBusy = false);
    }
  }

  List<DailyGridItem> get _filteredGrid {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return kDailyGrid;
    return kDailyGrid
        .where((i) => i.label(widget.langCode).toLowerCase().contains(q) ||
            i.labelAr.contains(q) ||
            i.labelEn.toLowerCase().contains(q) ||
            i.id.contains(q))
        .toList();
  }

  List<DailyMerchant> get _filteredMerchants {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _merchants;
    return _merchants
        .where((m) =>
            m.nameAr.contains(q) ||
            m.nameEn.toLowerCase().contains(q) ||
            m.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openGrid(DailyGridItem item) async {
    final vertical = dailyVerticalForId(item.id) ?? MarketplaceVertical.food;
    await openMarketplaceCategory(
      context: context,
      authController: widget.authController,
      langCode: widget.langCode,
      vertical: vertical,
      titleOverride: item.label(widget.langCode),
      foodFilter: item.id,
    );
  }

  Future<void> _openMerchant(DailyMerchant m) async {
    final vertical = switch (m.parentSlug) {
      'healthcare' => MarketplaceVertical.pharmacy,
      'shopping' => MarketplaceVertical.market,
      'logistics' => MarketplaceVertical.errand,
      _ => MarketplaceVertical.food,
    };
    // Build a lightweight listing so we open the shop, not the category list.
    final listing = MerchantListing(
      id: 'hub-${m.nameEn.hashCode}',
      nameAr: m.nameAr,
      nameEn: m.nameEn,
      photo: m.photo,
      rating: m.rating,
      distanceKm: m.distanceKm,
      etaMin: m.etaMin,
      feeYuan: m.feeYuan,
      tags: m.tags,
      category: vertical,
    );
    await openMerchantShop(
      context: context,
      auth: widget.authController,
      langCode: widget.langCode,
      merchant: listing,
      vertical: vertical,
    );
  }

  Future<void> _onHubSearch(String raw) async {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return;
    if (q.contains('pharm') || q.contains('صيدل') || q.contains('药')) {
      await openMarketplaceCategory(
        context: context,
        authController: widget.authController,
        langCode: widget.langCode,
        vertical: MarketplaceVertical.pharmacy,
      );
      return;
    }
    if (q.contains('errand') || q.contains('مشوار') || q.contains('跑腿')) {
      await openMarketplaceCategory(
        context: context,
        authController: widget.authController,
        langCode: widget.langCode,
        vertical: MarketplaceVertical.errand,
      );
      return;
    }
    if (q.contains('market') ||
        q.contains('سوبر') ||
        q.contains('خضار') ||
        q.contains('超市')) {
      await openMarketplaceCategory(
        context: context,
        authController: widget.authController,
        langCode: widget.langCode,
        vertical: MarketplaceVertical.market,
      );
      return;
    }
    await openMarketplaceCategory(
      context: context,
      authController: widget.authController,
      langCode: widget.langCode,
      vertical: MarketplaceVertical.food,
      foodFilter: raw.trim(),
    );
  }

  Future<void> _openPromo(int i) async {
    final vertical = switch (i) {
      1 => MarketplaceVertical.pharmacy,
      2 => MarketplaceVertical.market,
      _ => MarketplaceVertical.food,
    };
    await openMarketplaceCategory(
      context: context,
      authController: widget.authController,
      langCode: widget.langCode,
      vertical: vertical,
      foodFilter: i == 0 ? 'delivery' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              // Hero only — title stays above the search card (no overlap).
              height: top + 156,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ObicCachedImage(
                    DailyMedia.hero,
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
                          hub: ObicHubId.daily,
                          langCode: widget.langCode,
                          authController: widget.authController,
                          cityChoices: const [
                            'Yiwu',
                            'Shanghai',
                            'Hangzhou',
                            'Guangzhou',
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
                              color: const Color(0xFF93C5FD)
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          child: Text(
                            _ar
                                ? 'تطبيق يومي · داخل أوبك'
                                : 'Daily mini-app · inside OBIC',
                            style: const TextStyle(
                              color: Color(0xFFE0F2FE),
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
          // Opaque Meituan card — sits BELOW hero (no Transform overlap).
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: MarketplaceHubSearchCard(
                authController: widget.authController,
                langCode: widget.langCode,
                searchController: _search,
                searchHint: s.searchHint,
                eyebrow: _ar ? 'التوصيل إلى' : 'Deliver to',
                fallbackCity: s.location,
                onAddressChanged: () {
                  if (mounted) setState(() {});
                },
                onSearchSubmitted: _onHubSearch,
                onUseGps: _useGps,
                gpsBusy: _gpsBusy,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: HubProfileStrip(
                authController: widget.authController,
                langCode: widget.langCode,
                hub: ObicHubId.daily,
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
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredGrid.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (context, i) {
                  final item = _filteredGrid[i];
                  return ObicSlideIn(
                    index: i,
                    child: ObicBounce(
                      onTap: () => _openGrid(item),
                      child: Column(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.color.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Icon(item.icon, color: item.color, size: 26),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.label(widget.langCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ObicColors.inkOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: HubIllustratedState(
                strings: hs,
                kind: _offline ? HubStateKind.offline : HubStateKind.error,
                onRetry: _boot,
              ),
            ),
          if (_deals.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Text(
                s.flash,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: ObicColors.titleOf(context),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _deals.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final p = _deals[i];
                  final photo = DailyMedia.food;
                  return ObicBounce(
                    onTap: () => _openPromo(i % 3),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 228,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ObicCachedImage(photo, fit: BoxFit.cover),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: AlignmentDirectional.centerStart,
                                  end: AlignmentDirectional.centerEnd,
                                  colors: [
                                    ObicColors.navy.withValues(alpha: 0.9),
                                    ObicColors.blue.withValues(alpha: 0.28),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  p.title(widget.langCode),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    height: 1.25,
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
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                s.nearby,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: ObicColors.titleOf(context),
                ),
              ),
            ),
          ),
          SliverList.separated(
            itemCount: _filteredMerchants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = _filteredMerchants[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ObicBounce(
                  onTap: () => _openMerchant(m),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ObicColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ObicColors.lineOf(context)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: ObicCachedImage(m.photo, fit: BoxFit.cover),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name(widget.langCode),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: ObicColors.titleOf(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    Text(
                                      ' ${m.rating}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      ' · ${m.distanceKm} km · ${m.etaMin} ${s.eta}',
                                      style: TextStyle(
                                        color: ObicColors.mutedOf(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${s.fee} ¥${m.feeYuan}',
                                  style: const TextStyle(
                                    color: ObicColors.blue,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    for (final t in m.tags)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ObicColors.blueSoftOf(context),
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                        child: Text(
                                          t,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: ObicColors.blueDeep,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
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
          const SliverToBoxAdapter(child: SizedBox(height: 36)),
        ],
      ),
    );
  }
}
