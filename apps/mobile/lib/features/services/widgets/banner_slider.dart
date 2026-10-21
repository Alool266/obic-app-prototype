// Made by Dr Ali
// Home banner slider — real promo photos from assets/banners.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/obic_colors.dart';
import '../../../theme/obic_elevation.dart';
import '../service_catalog.dart';
import 'service_tiles.dart';

class BannerSlide {
  const BannerSlide({
    required this.asset,
    required this.serviceSlug,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.cta,
  });

  final String asset;
  final String serviceSlug;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;
}

class HomeBannerSlider extends StatefulWidget {
  const HomeBannerSlider({
    super.key,
    required this.slides,
    required this.onTap,
  });

  final List<BannerSlide> slides;
  final ValueChanged<String> onTap;

  @override
  State<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends State<HomeBannerSlider> {
  final _controller = PageController();
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.slides.isEmpty) return;
      final next = (_index + 1) % widget.slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final slide = widget.slides[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () => widget.onTap(slide.serviceSlug),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          slide.asset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: ObicColors.titleOf(context),
                          ),
                        ),
                        // Scrim so text stays readable over photos.
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: AlignmentDirectional.centerStart,
                              end: AlignmentDirectional.centerEnd,
                              colors: [
                                ObicColors.navy.withValues(alpha: 0.78),
                                ObicColors.navy.withValues(alpha: 0.25),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slide.eyebrow.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                slide.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                slide.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  slide.cta,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
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
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.slides.length, (i) {
            final on = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: on ? 14 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: on ? ObicColors.blue : ObicColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class PromoRow extends StatelessWidget {
  const PromoRow({
    super.key,
    required this.visa,
    required this.bank,
    required this.langCode,
    required this.visaTitle,
    required this.bankTitle,
    required this.bankSubtitle,
    required this.onTap,
  });

  final ObicService? visa;
  final ObicService? bank;
  final String langCode;
  final String visaTitle;
  final String bankTitle;
  final String bankSubtitle;
  final ValueChanged<ObicService> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 12,
          child: _PromoCard(
            onTap: visa == null ? null : () => onTap(visa!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: ServiceTheme.visa.gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        end: 10,
                        top: 10,
                        child: Icon(
                          serviceIconData('visa'),
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 28,
                        ),
                      ),
                      PositionedDirectional(
                        start: 10,
                        bottom: 8,
                        child: Text(
                          visa?.name(langCode) ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  visaTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ObicColors.titleOf(context),
                    fontSize: 13,
                  ),
                ),
                Text(
                  visa?.price(langCode) ?? '',
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 10,
          child: _PromoCard(
            onTap: bank == null ? null : () => onTap(bank!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CatalogLogoCircle(
                  icon: serviceIconData('bank'),
                  ink: ServiceTheme.bank.ink,
                  fill: ServiceTheme.bank.soft,
                  size: 40,
                  iconSize: 22,
                ),
                const SizedBox(height: 10),
                Text(
                  bankTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ObicColors.titleOf(context),
                    fontSize: 13,
                  ),
                ),
                Text(
                  bankSubtitle,
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ObicColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ObicColors.lineOf(context).withValues(alpha: 0.65)),
            boxShadow: ObicColors.isDark(context)
                ? ObicElevation.level0
                : ObicElevation.level1,
          ),
          child: child,
        ),
      ),
    );
  }
}
