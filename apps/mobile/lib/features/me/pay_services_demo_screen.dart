// Made by Dr Ali
// Example Pay & Services hub — WeChat-style grid for trial UI only (no payments).

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';

/// Demo hub opened from Me → Pay and Services. Not wired to real payments.
class PayServicesDemoScreen extends StatelessWidget {
  const PayServicesDemoScreen({
    super.key,
    this.onOpenRealServices,
  });

  /// Optional: jump to the real Services tab and pop this screen.
  final VoidCallback? onOpenRealServices;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = ObicColors.surfaceOf(context);
    final ink = ObicColors.inkOf(context);
    final muted = ObicColors.mutedOf(context);

    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(l10n.mePayServices),
        backgroundColor: surface,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
        children: [
          _DemoBanner(
            title: l10n.payDemoBannerTitle,
            body: l10n.payDemoBannerBody,
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.payDemoSectionMoney,
            children: [
              _TileGrid(
                items: [
                  _DemoTileData(
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF07C160),
                    label: l10n.payDemoWallet,
                  ),
                  _DemoTileData(
                    icon: Icons.swap_horiz_rounded,
                    color: const Color(0xFF07C160),
                    label: l10n.payDemoTransfer,
                  ),
                  _DemoTileData(
                    icon: Icons.qr_code_2_rounded,
                    color: const Color(0xFF07C160),
                    label: l10n.payDemoReceive,
                  ),
                  _DemoTileData(
                    icon: Icons.credit_card_rounded,
                    color: const Color(0xFF1485EE),
                    label: l10n.payDemoCards,
                  ),
                ],
                onTap: (label) => _showDemoSnack(context, label),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.payDemoSectionShortcuts,
            children: [
              _TileGrid(
                items: [
                  _DemoTileData(
                    icon: Icons.miscellaneous_services_outlined,
                    color: ObicColors.blue,
                    label: l10n.payDemoDailyServices,
                  ),
                  _DemoTileData(
                    icon: Icons.flight_takeoff_rounded,
                    color: const Color(0xFF576B95),
                    label: l10n.payDemoVisa,
                  ),
                  _DemoTileData(
                    icon: Icons.account_balance_outlined,
                    color: const Color(0xFFFA9D3B),
                    label: l10n.payDemoBanking,
                  ),
                  _DemoTileData(
                    icon: Icons.luggage_outlined,
                    color: const Color(0xFF10B981),
                    label: l10n.payDemoTravel,
                  ),
                ],
                onTap: (label) => _showDemoSnack(context, label),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.payDemoSectionOffers,
            children: [
              _TileGrid(
                items: [
                  _DemoTileData(
                    icon: Icons.local_offer_outlined,
                    color: const Color(0xFFE53935),
                    label: l10n.payDemoOfferVip,
                  ),
                  _DemoTileData(
                    icon: Icons.card_giftcard_outlined,
                    color: const Color(0xFF9C27B0),
                    label: l10n.payDemoOfferPartner,
                  ),
                  _DemoTileData(
                    icon: Icons.percent_rounded,
                    color: const Color(0xFF00897B),
                    label: l10n.payDemoOfferSeasonal,
                  ),
                  _DemoTileData(
                    icon: Icons.new_releases_outlined,
                    color: ObicColors.blueDeep,
                    label: l10n.payDemoOfferComing,
                  ),
                ],
                onTap: (label) => _showDemoSnack(context, label),
              ),
            ],
          ),
          if (onOpenRealServices != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onOpenRealServices!();
                },
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: Text(l10n.payDemoOpenRealServices),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ObicColors.blue,
                  side: BorderSide(color: ObicColors.blue.withValues(alpha: 0.45)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l10n.payDemoFooter,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.35, color: muted),
            ),
          ),
        ],
      ),
    );
  }

  void _showDemoSnack(BuildContext context, String label) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.payDemoTileSnack(label)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ObicColors.surfaceOf(context),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF07C160).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: Color(0xFF07C160),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ObicColors.inkOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: ObicColors.mutedOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ObicColors.surfaceOf(context),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ObicColors.mutedOf(context),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _DemoTileData {
  const _DemoTileData({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.items, required this.onTap});

  final List<_DemoTileData> items;
  final void Function(String label) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return InkWell(
          onTap: () => onTap(item.label),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 28, color: item.color),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.15,
                    color: ObicColors.inkOf(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
