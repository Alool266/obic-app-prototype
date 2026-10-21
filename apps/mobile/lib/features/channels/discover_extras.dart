// Made by Dr Ali
// Discover fill under Moments / Channels / Obic Apps:
// offers carousel, shortcuts, trending services, mini-app preview.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/media_url.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/obic_cached_image.dart';
import '../../widgets/obic_lottie_empty.dart';
import '../../widgets/obic_soft_motion.dart';
import '../auth/auth_controller.dart';
import '../mini_apps/mini_apps_api.dart';
import '../mini_apps/mini_apps_catalog.dart';
import '../mini_apps/mini_apps_pull_panel.dart';
import '../music/music_screen.dart';
import '../offers/offers_api.dart';
import '../offers/offers_browse.dart';
import '../services/service_catalog.dart';
import '../services/service_detail_page.dart';
import '../services/service_hub_page.dart';
import '../services/service_sub_catalog.dart';

class DiscoverScroll extends StatefulWidget {
  const DiscoverScroll({
    super.key,
    required this.authController,
    required this.isActive,
    required this.header,
    required this.onMoments,
    required this.onChannels,
    required this.onMiniApps,
  });

  final AuthController authController;
  final bool isActive;
  final Widget header;
  final VoidCallback onMoments;
  final VoidCallback onChannels;
  final VoidCallback onMiniApps;

  @override
  State<DiscoverScroll> createState() => _DiscoverScrollState();
}

class _Slide {
  const _Slide({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.imageUrl,
    this.asset,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  final String? imageUrl;
  final String? asset;
}

class _DiscoverScrollState extends State<DiscoverScroll> {
  final _page = PageController();
  Timer? _timer;
  int _index = 0;
  List<Map<String, dynamic>> _offers = const [];
  List<MiniAppEntry> _remote = const [];
  List<_Slide> _slides = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadOffers());
    unawaited(_loadMiniApps());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _armTimer();
  }

  @override
  void didUpdateWidget(covariant DiscoverScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) _armTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  void _armTimer() {
    final covered = ModalRoute.of(context)?.isCurrent == false;
    final run = widget.isActive && !covered && !obicReduceMotion(context);
    if (!run) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 4), (_) => _advance());
  }

  void _advance() {
    if (!mounted || _slides.length < 2 || !_page.hasClients) return;
    if (obicReduceMotion(context)) return;
    final next = (_index + 1) % _slides.length;
    _page.animateToPage(
      next,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _loadOffers() async {
    try {
      final items = await OffersApi().listPublished();
      if (!mounted) return;
      final usable = items
          .where((offer) {
            final id = offer['id'];
            return id is String &&
                id.isNotEmpty &&
                _offerTitle(offer, 'zh').isNotEmpty;
          })
          .take(3)
          .toList();
      if (usable.isEmpty) return;
      if (_page.hasClients) _page.jumpToPage(0);
      if (!mounted) return;
      setState(() {
        _offers = usable;
        _index = 0;
      });
    } catch (_) {
      // Keep the local featured slides. The offers route stays available.
    }
  }

  Future<void> _loadMiniApps() async {
    try {
      final remote = await MiniAppsApi().listApproved();
      if (!mounted) return;
      setState(() => _remote = remote);
    } catch (_) {
      // Website and Music tiles still open without the public list.
    }
  }

  ObicService? _service(String slug) {
    for (final service in localCatalogSeed()) {
      if (service.slug == slug) return service;
    }
    return null;
  }

  void _openSub(String parentSlug, String subId) {
    final service = _service(parentSlug);
    if (service == null || !mounted) return;
    ObicSubService? sub;
    for (final item in subServicesForParent(parentSlug)) {
      if (item.id == subId) {
        sub = item;
        break;
      }
    }
    if (sub == null) {
      _openService(parentSlug);
      return;
    }
    final lang = Localizations.localeOf(context).languageCode;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceDetailPage(
          service: service,
          authController: widget.authController,
          langCode: lang,
          subService: sub,
        ),
      ),
    );
  }

  void _openOffers() {
    final lang = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final offers = List<Map<String, dynamic>>.from(_offers);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: ObicColors.scaffoldOf(context),
          appBar: AppBar(title: Text(l10n.discoverOffers)),
          body: offers.isEmpty
              ? Center(
                  child: Text(
                    l10n.discoverEmpty,
                    style: TextStyle(color: ObicColors.mutedOf(context)),
                  ),
                )
              : ListView.separated(
                  itemCount: offers.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: ObicColors.lineOf(context),
                  ),
                  itemBuilder: (context, i) {
                    final offer = offers[i];
                    final cover = _offerCover(offer);
                    return ListTile(
                      leading: cover == null
                          ? null
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ObicCachedImage(
                                cover,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                      title: Text(_offerTitle(offer, lang)),
                      subtitle: Text(_offerSubtitle(offer, lang)),
                      onTap: () => _openOffer(offer),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _openService(String slug) {
    final service = _service(slug);
    if (service == null || !mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceHubPage(
          service: service,
          authController: widget.authController,
          langCode: lang,
        ),
      ),
    );
  }

  void _openOffer(Map<String, dynamic> offer) {
    final id = offer['id'];
    if (id is! String || id.isEmpty) return;
    final service = _service(_slugForOffer(offer));
    if (service == null || !mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OfferDetailPage(
          offerId: id,
          arabic: lang == 'ar',
          authController: widget.authController,
          service: service,
          preview: offer,
        ),
      ),
    );
  }

  void _openMusic() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MusicScreen()));
  }

  List<_Slide> _buildSlides(AppLocalizations l10n) {
    final lang = Localizations.localeOf(context).languageCode;
    final slides = <_Slide>[];
    if (_offers.isEmpty) {
      slides.add(
        _Slide(
          eyebrow: l10n.discoverOffers,
          title: l10n.vipTrip,
          subtitle: l10n.vipTripDesc,
          colors: const [Color(0xFFFB7185), Color(0xFFE11D48)],
          asset: 'assets/banners/vip-china.jpg',
          onTap: () => _openSub('travel', 'hotels'),
        ),
      );
      slides.add(
        _Slide(
          eyebrow: l10n.fastTrack,
          title: l10n.visaExpress,
          subtitle: l10n.visaExpressDesc,
          colors: const [Color(0xFF2DD4BF), Color(0xFF0D9488)],
          asset: 'assets/banners/fast-visa.jpg',
          onTap: () => _openSub('travel', 'visa'),
        ),
      );
      slides.add(
        _Slide(
          eyebrow: l10n.setup,
          title: l10n.openBank,
          subtitle: l10n.openBankDesc,
          colors: const [ObicColors.blue, ObicColors.navy],
          asset: 'assets/banners/open-bank.jpg',
          onTap: () => _openSub('business', 'company-yiwu'),
        ),
      );
    } else {
      for (final offer in _offers) {
        final title = _offerTitle(offer, lang);
        if (title.isEmpty) continue;
        slides.add(
          _Slide(
            eyebrow: l10n.discoverOffers,
            title: title,
            subtitle: _offerSubtitle(offer, lang),
            colors: _colorsForOffer(offer),
            imageUrl: _offerCover(offer),
            onTap: () => _openOffer(offer),
          ),
        );
      }
    }
    slides.add(
      _Slide(
        eyebrow: l10n.discoverMusic,
        title: obicMusicMiniApp(lang).name,
        subtitle: '',
        colors: const [Color(0xFF6366F1), Color(0xFF4338CA)],
        onTap: _openMusic,
      ),
    );
    slides.add(
      _Slide(
        eyebrow: l10n.discoverNew,
        title: l10n.miniAppsTitle,
        subtitle: l10n.discoverNewHint,
        colors: const [ObicColors.blue, ObicColors.blueDeep],
        onTap: widget.onMiniApps,
      ),
    );
    return slides;
  }

  List<MiniAppEntry> _miniApps(AppLocalizations l10n) {
    final lang = Localizations.localeOf(context).languageCode;
    final site = obicWebsiteMiniApp(l10n.miniAppWebsiteName);
    final merged = mergeApprovedMiniApps(site, _remote);
    if (merged.isEmpty) return [obicMusicMiniApp(lang)];
    return [merged.first, obicMusicMiniApp(lang), ...merged.skip(1)];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _slides = _buildSlides(l10n);
    final apps = _miniApps(l10n);
    final trending = localCatalogSeed().take(4).toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        widget.header,
        ObicFadeIn(
          child: _Carousel(
            slides: _slides,
            controller: _page,
            index: _index,
            onChanged: (value) {
              setState(() => _index = value);
              _timer?.cancel();
              _timer = null;
              _armTimer();
            },
          ),
        ),
        ObicFadeIn(
          delay: const Duration(milliseconds: 40),
          child: _Shortcuts(
            l10n: l10n,
            onMoments: widget.onMoments,
            onChannels: widget.onChannels,
            onMusic: _openMusic,
            onMiniApps: widget.onMiniApps,
            onOffers: _openOffers,
          ),
        ),
        ObicFadeIn(
          delay: const Duration(milliseconds: 80),
          child: _Trending(
            title: l10n.discoverTrending,
            empty: l10n.discoverEmpty,
            services: trending,
            onTap: (service) => _openService(service.slug),
          ),
        ),
        ObicFadeIn(
          delay: const Duration(milliseconds: 120),
          child: _MiniPreview(
            title: l10n.miniAppsTitle,
            seeAll: l10n.seeAll,
            empty: l10n.discoverEmpty,
            apps: apps.take(8).toList(),
            displayName: widget.authController.user?.name,
            onSeeAll: widget.onMiniApps,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _Carousel extends StatelessWidget {
  const _Carousel({
    required this.slides,
    required this.controller,
    required this.index,
    required this.onChanged,
  });

  final List<_Slide> slides;
  final PageController controller;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (slides.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          SizedBox(
            height: 148,
            child: PageView.builder(
              controller: controller,
              itemCount: slides.length,
              onPageChanged: onChanged,
              itemBuilder: (context, i) {
                final slide = slides[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ObicBounce(
                    onTap: slide.onTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: AlignmentDirectional.centerStart,
                                end: AlignmentDirectional.centerEnd,
                                colors: slide.colors,
                              ),
                            ),
                          ),
                          if (slide.asset != null)
                            Image.asset(
                              slide.asset!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            )
                          else if (slide.imageUrl != null)
                            ObicCachedImage(
                              slide.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  slide.colors.last.withValues(alpha: 0.88),
                                  slide.colors.first.withValues(
                                    alpha: slide.imageUrl == null &&
                                            slide.asset == null
                                        ? 0.05
                                        : 0.2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              14,
                              16,
                              12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slide.eyebrow,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  slide.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                                if (slide.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    slide.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 12,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ],
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == index
                        ? ObicColors.blue
                        : ObicColors.mutedOf(context).withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({
    required this.l10n,
    required this.onMoments,
    required this.onChannels,
    required this.onMusic,
    required this.onMiniApps,
    required this.onOffers,
  });

  final AppLocalizations l10n;
  final VoidCallback onMoments;
  final VoidCallback onChannels;
  final VoidCallback onMusic;
  final VoidCallback onMiniApps;
  final VoidCallback onOffers;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        l10n.momentsTitle,
        Icons.photo_camera_outlined,
        const Color(0xFFE75D5C),
        onMoments,
      ),
      (
        l10n.channelTitle,
        Icons.play_circle_outline,
        const Color(0xFFF5A623),
        onChannels,
      ),
      (
        l10n.discoverMusic,
        Icons.music_note_rounded,
        const Color(0xFF6366F1),
        onMusic,
      ),
      (
        l10n.miniAppsTitle,
        Icons.apps_rounded,
        const Color(0xFF576B95),
        onMiniApps,
      ),
      (
        l10n.discoverOffers,
        Icons.local_offer_outlined,
        const Color(0xFFE11D48),
        onOffers,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: l10n.discoverShortcuts),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            primary: false,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              return ObicBounce(
                onTap: item.$4,
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ObicColors.surfaceOf(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ObicColors.lineOf(
                              context,
                            ).withValues(alpha: 0.8),
                          ),
                        ),
                        child: Icon(item.$2, color: item.$3, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
      ],
    );
  }
}

class _Trending extends StatelessWidget {
  const _Trending({
    required this.title,
    required this.empty,
    required this.services,
    required this.onTap,
  });

  final String title;
  final String empty;
  final List<ObicService> services;
  final ValueChanged<ObicService> onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final dark = ObicColors.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: title),
        if (services.isEmpty)
          ObicLottieEmpty(message: empty)
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              primary: false,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
              itemCount: services.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final service = services[i];
                final theme = ServiceTheme.of(service.colorKey);
                return ObicBounce(
                  onTap: () => onTap(service),
                  child: Container(
                    width: 196,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ObicColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ObicColors.lineOf(
                          context,
                        ).withValues(alpha: 0.8),
                      ),
                      boxShadow: dark
                          ? null
                          : [
                              BoxShadow(
                                color: ObicColors.navy.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          serviceIconData(service.icon),
                          color: theme.ink,
                          size: 22,
                        ),
                        const Spacer(),
                        Text(
                          service.name(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ObicColors.titleOf(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          service.desc(lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ObicColors.mutedOf(context),
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MiniPreview extends StatelessWidget {
  const _MiniPreview({
    required this.title,
    required this.seeAll,
    required this.empty,
    required this.apps,
    required this.onSeeAll,
    this.displayName,
  });

  final String title;
  final String seeAll;
  final String empty;
  final List<MiniAppEntry> apps;
  final VoidCallback onSeeAll;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 8, 8),
          child: Row(
            children: [
              Expanded(child: _SectionTitle(title: title, padded: false)),
              TextButton(onPressed: onSeeAll, child: Text(seeAll)),
            ],
          ),
        ),
        if (apps.isEmpty)
          ObicLottieEmpty(message: empty)
        else
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: apps.length,
            itemBuilder: (context, i) {
              final app = apps[i];
              return ObicBounce(
                onTap: () {
                  unawaited(
                    openMiniAppEntry(context, app, displayName: displayName),
                  );
                },
                child: Column(
                  children: [
                    _MiniIcon(app: app),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        app.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                          color: ObicColors.inkOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({required this.app});

  final MiniAppEntry app;

  @override
  Widget build(BuildContext context) {
    final url = app.iconUrl;
    final resolved = url == null || url.isEmpty ? '' : resolveMediaUrl(url);
    return ClipOval(
      child: Container(
        width: 48,
        height: 48,
        color: ObicColors.blue,
        alignment: Alignment.center,
        child: resolved.isNotEmpty
            ? ObicCachedImage(
                resolved,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    if (app.native || app.id == kObicMusicMiniAppId) {
      return const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 24,
      );
    }
    if (app.firstParty) {
      return const Icon(Icons.language_rounded, color: Colors.white, size: 24);
    }
    final trimmed = app.name.trim();
    final letter = trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first);
    return Text(
      letter,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.padded = true});

  final String title;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: ObicColors.titleOf(context),
      ),
    );
    if (!padded) return text;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: text,
    );
  }
}

String _offerTitle(Map<String, dynamic> offer, String lang) {
  String pick(String key) {
    final value = offer[key];
    return value is String ? value.trim() : '';
  }

  if (lang == 'ar') {
    final arabic = pick('titleAr');
    if (arabic.isNotEmpty) return arabic;
  }
  if (lang == 'zh') {
    final chinese = pick('titleZh');
    if (chinese.isNotEmpty) return chinese;
  }
  final english = pick('titleEn');
  if (english.isNotEmpty) return english;
  return pick('titleAr');
}

String _offerSubtitle(Map<String, dynamic> offer, String lang) {
  final price = lang == 'ar' ? offer['priceLabelAr'] : offer['priceLabelEn'];
  final location = offer['locationLabel'];
  final parts = <String>[];
  if (location is String && location.trim().isNotEmpty) {
    parts.add(location.trim());
  }
  if (price is String && price.trim().isNotEmpty) parts.add(price.trim());
  return parts.join(' · ');
}

String? _offerCover(Map<String, dynamic> offer) {
  final media = offer['media'];
  if (media is! List) return null;
  for (final item in media) {
    if (item is! Map) continue;
    final url = item['url'];
    final kind = '${item['kind'] ?? item['type'] ?? 'image'}'.toLowerCase();
    if (url is String && url.isNotEmpty && kind != 'video') {
      final resolved = resolveMediaUrl(url);
      if (resolved.isNotEmpty) return resolved;
    }
  }
  return null;
}

String _slugForOffer(Map<String, dynamic> offer) {
  switch ('${offer['kind'] ?? ''}'.toLowerCase()) {
    case 'flights':
      return 'transport';
    case 'restaurants':
      return 'food';
    case 'hotels':
      return 'travel';
    default:
      return 'travel';
  }
}

List<Color> _colorsForOffer(Map<String, dynamic> offer) {
  switch ('${offer['kind'] ?? ''}'.toLowerCase()) {
    case 'flights':
      return const [Color(0xFF60A5FA), Color(0xFF1A6DFF)];
    case 'restaurants':
      return const [Color(0xFFFB923C), Color(0xFFEA580C)];
    case 'hotels':
      return const [Color(0xFFFB7185), Color(0xFFE11D48)];
    default:
      return const [ObicColors.blue, ObicColors.navy];
  }
}
