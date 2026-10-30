// Made by Dr Ali
// Stable Home mega-icon IDs for regional «بين يديك» hubs (favoritable / reorderable).

import 'package:flutter/material.dart';

import '../africa_in_hand/africa_in_hand_page.dart';
import '../africa_in_hand/africa_media.dart';
import '../auth/auth_controller.dart';
import '../china_in_hand/china_in_hand_page.dart';
import '../china_in_hand/china_media.dart';
import '../mideast_in_hand/mideast_in_hand_page.dart';
import '../mideast_in_hand/mideast_media.dart';
import '../services/service_catalog.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/obic_cached_image.dart';

/// Stable slugs — Nest home-layout favorites/order/hide and SharedPreferences.
const kChinaInHandHomeSlug = 'china-in-hand';
const kMideastInHandHomeSlug = 'mideast-in-hand';
const kAfricaInHandHomeSlug = 'africa-in-hand';

const kRegionalHomeIconSlugs = <String>{
  kChinaInHandHomeSlug,
  kMideastInHandHomeSlug,
  kAfricaInHandHomeSlug,
};

bool isRegionalHomeIconSlug(String slug) =>
    kRegionalHomeIconSlugs.contains(slug);

/// Bundled cover photos for Home tiles (not generic 4-square icons).
String? regionalHomeCoverAsset(String slug) {
  switch (slug) {
    case kChinaInHandHomeSlug:
      return ChinaMedia.discoverChinaInHand;
    case kMideastInHandHomeSlug:
      return MideastMedia.discoverMideastInHand;
    case kAfricaInHandHomeSlug:
      return AfricaMedia.discoverAfricaInHand;
    default:
      return null;
  }
}

/// Virtual catalog rows — not API mega-categories; Home-only + arrange screen.
List<ObicService> kRegionalHomeIconServices() => const [
      ObicService(
        id: kChinaInHandHomeSlug,
        slug: kChinaInHandHomeSlug,
        icon: 'public',
        colorKey: 'travel',
        sortOrder: -30,
        nameAr: 'الصين بين يديك',
        nameEn: 'China in your hand',
        nameZh: '中国尽在掌握',
        descAr: 'أعمال، تأشيرات، مدن، لوجستيات في الصين.',
        descEn: 'Business, visas, cities, logistics in China.',
        descZh: '中国商务、签证、城市与物流。',
        priceAr: 'مجاني للاستكشاف',
        priceEn: 'Free to explore',
        priceZh: '免费浏览',
      ),
      ObicService(
        id: kMideastInHandHomeSlug,
        slug: kMideastInHandHomeSlug,
        icon: 'mosque',
        colorKey: 'business',
        sortOrder: -20,
        nameAr: 'الشرق الأوسط بين يديك',
        nameEn: 'Middle East in your hand',
        nameZh: '中东尽在掌握',
        descAr: 'أعمال، تأشيرات، تجارة ودول المنطقة.',
        descEn: 'Business, visas, trade across the region.',
        descZh: '区域内商务、签证与贸易。',
        priceAr: 'مجاني للاستكشاف',
        priceEn: 'Free to explore',
        priceZh: '免费浏览',
      ),
      ObicService(
        id: kAfricaInHandHomeSlug,
        slug: kAfricaInHandHomeSlug,
        icon: 'travel_explore',
        colorKey: 'logistics',
        sortOrder: -10,
        nameAr: 'أفريقيا بين يديك',
        nameEn: 'Africa in your hand',
        nameZh: '非洲尽在掌握',
        descAr: 'أعمال، تأشيرات، توريد ولوجستيات أفريقيا.',
        descEn: 'Business, visas, sourcing & logistics in Africa.',
        descZh: '非洲商务、签证、采购与物流。',
        priceAr: 'مجاني للاستكشاف',
        priceEn: 'Free to explore',
        priceZh: '免费浏览',
      ),
    ];

/// Regional hubs first (default), then API/seed catalog — layout reorder still wins.
/// Same slug appears once (API/seed dupes collapse).
List<ObicService> mergeHomeServicesWithRegional(List<ObicService> catalog) {
  final bySlug = <String, ObicService>{};
  for (final s in catalog) {
    bySlug.putIfAbsent(s.slug, () => s);
  }
  final out = <ObicService>[];
  for (final r in kRegionalHomeIconServices()) {
    out.add(bySlug.remove(r.slug) ?? r);
  }
  final rest = bySlug.values.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  out.addAll(rest);
  return out;
}

Future<void> openRegionalHomeIcon({
  required BuildContext context,
  required AuthController authController,
  required String langCode,
  required String slug,
}) async {
  final Widget page;
  switch (slug) {
    case kChinaInHandHomeSlug:
      page = ChinaInHandPage(
        authController: authController,
        langCode: langCode,
      );
    case kMideastInHandHomeSlug:
      page = MideastInHandPage(
        authController: authController,
        langCode: langCode,
      );
    case kAfricaInHandHomeSlug:
      page = AfricaInHandPage(
        authController: authController,
        langCode: langCode,
      );
    default:
      return;
  }
  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      pageBuilder: (_, animation, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 320),
    ),
  );
}

/// Rounded photo glyph for regional Home tiles.
class RegionalHomeCoverGlyph extends StatelessWidget {
  const RegionalHomeCoverGlyph({
    super.key,
    required this.slug,
    this.size = 44,
  });

  final String slug;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = regionalHomeCoverAsset(slug);
    if (asset == null) {
      return SizedBox(width: size, height: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ObicColors.navy.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ObicCachedImage(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Image.asset(asset, fit: BoxFit.cover),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x33071628),
                  Color(0x99071628),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
