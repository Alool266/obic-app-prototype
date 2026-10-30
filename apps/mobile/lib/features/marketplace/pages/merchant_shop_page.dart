// Made by Dr Ali
// Merchant shop — real book/request CTA (not category dump).

import 'package:flutter/material.dart';

import '../../../theme/obic_colors.dart';
import '../../../widgets/obic_cached_image.dart';
import '../../auth/auth_controller.dart';
import '../marketplace_models.dart';
import 'marketplace_chrome.dart';

class MerchantShopPage extends StatelessWidget {
  const MerchantShopPage({
    super.key,
    required this.authController,
    required this.langCode,
    required this.merchant,
    required this.vertical,
  });

  final AuthController authController;
  final String langCode;
  final MerchantListing merchant;
  final MarketplaceVertical vertical;

  @override
  Widget build(BuildContext context) {
    final lang = langCode;
    final m = merchant;
    return MarketplaceScaffold(
      title: m.name(lang),
      accent: ObicColors.blue,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: ObicCachedImage(m.photo, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            m.name(lang),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: ObicColors.titleOf(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '★ ${m.rating} · ${m.distanceKm} km · ${m.etaMin} '
            '${mp(lang, 'د', 'min', '分钟')}',
            style: TextStyle(color: ObicColors.mutedOf(context)),
          ),
          const SizedBox(height: 8),
          Text(
            '${mp(lang, 'رسوم', 'Fee', '配送费')} ¥${m.feeYuan}'
            '${m.minOrderYuan != null ? ' · ${mp(lang, 'حد أدنى', 'min', '起送')} ¥${m.minOrderYuan}' : ''}',
            style: const TextStyle(
              color: ObicColors.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in m.tags)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ObicColors.blueSoftOf(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ObicColors.blueDeep,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            mp(lang, 'طلب من هذا المتجر', 'Order from this shop', '向该商家下单'),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ObicColors.titleOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mp(
              lang,
              'سيُرسل طلبك إلى فريق أوبك مع اسم المتجر — نفس مسار الطلبات.',
              'Your request goes to the OBIC team with this shop name — same order pipeline.',
              '请求会带上商家名发给 OBIC 团队，走同一订单流程。',
            ),
            style: TextStyle(
              color: ObicColors.mutedOf(context),
              height: 1.35,
            ),
          ),
        ],
      ),
      // MarketplaceScaffold has no bottomBar — use overlay via Stack? Keep CTA in body end via Scaffold.
    );
  }
}

Future<void> openMerchantShop({
  required BuildContext context,
  required AuthController auth,
  required String langCode,
  required MerchantListing merchant,
  required MarketplaceVertical vertical,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => _MerchantShopScaffold(
        authController: auth,
        langCode: langCode,
        merchant: merchant,
        vertical: vertical,
      ),
    ),
  );
}

class _MerchantShopScaffold extends StatelessWidget {
  const _MerchantShopScaffold({
    required this.authController,
    required this.langCode,
    required this.merchant,
    required this.vertical,
  });

  final AuthController authController;
  final String langCode;
  final MerchantListing merchant;
  final MarketplaceVertical vertical;

  @override
  Widget build(BuildContext context) {
    final lang = langCode;
    final m = merchant;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      body: Column(
        children: [
          Expanded(
            child: MerchantShopPage(
              authController: authController,
              langCode: langCode,
              merchant: merchant,
              vertical: vertical,
            ),
          ),
          MarketplaceCtaBar(
            label: mp(lang, 'اطلب الآن', 'Request now', '立即下单'),
            onPressed: () => showMarketplaceHoldDialog(
              context,
              auth: authController,
              langCode: lang,
              title: m.name(lang),
              vertical: vertical,
              formData: {
                'merchantId': m.id,
                'merchant': m.nameEn,
              },
              notes: 'Merchant: ${m.nameEn} (${m.id})',
            ),
          ),
        ],
      ),
    );
  }
}
