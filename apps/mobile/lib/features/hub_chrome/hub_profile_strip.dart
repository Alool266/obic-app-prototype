// Made by Dr Ali
// Profile strip: addresses · favorites · recent · order history.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_soft_motion.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../me/addresses_screen.dart';
import '../orders/orders_tab.dart';
import 'hub_id.dart';
import 'hub_prefs.dart';
import 'hub_strings.dart';

class HubProfileStrip extends StatelessWidget {
  const HubProfileStrip({
    super.key,
    required this.authController,
    required this.langCode,
    required this.hub,
    this.onRecentTap,
    this.onFavoritesTap,
  });

  final AuthController authController;
  final String langCode;
  final ObicHubId hub;
  final ValueChanged<String>? onRecentTap;
  final VoidCallback? onFavoritesTap;

  HubChromeStrings get s => HubChromeStrings(langCode, hub);

  Future<void> _openAddresses(BuildContext context) async {
    final ok = await requireAuth(context, authController);
    if (!context.mounted || !ok) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddressesScreen(authController: authController),
      ),
    );
  }

  Future<void> _openOrders(BuildContext context) async {
    final ok = await requireAuth(context, authController);
    if (!context.mounted || !ok) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: ObicColors.scaffoldOf(context),
          appBar: AppBar(
            title: Text(s.profileOrders),
            backgroundColor: ObicColors.surfaceOf(context),
          ),
          body: OrdersTab(authController: authController),
        ),
      ),
    );
  }

  Future<void> _openRecent(BuildContext context) async {
    final prefs = HubPrefs(hub);
    final recent = await prefs.recentSearches();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.profileRecent,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: ObicColors.titleOf(ctx),
                  ),
                ),
                const SizedBox(height: 10),
                if (recent.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      s.emptyRecent,
                      style: TextStyle(color: ObicColors.mutedOf(ctx)),
                    ),
                  )
                else
                  for (final q in recent)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.history_rounded),
                      title: Text(q),
                      onTap: () {
                        Navigator.pop(ctx);
                        onRecentTap?.call(q);
                      },
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openFavorites(BuildContext context) async {
    if (onFavoritesTap != null) {
      onFavoritesTap!();
      return;
    }
    final prefs = HubPrefs(hub);
    final favs = await prefs.favorites();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.profileFavorites,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: ObicColors.titleOf(ctx),
                  ),
                ),
                const SizedBox(height: 10),
                if (favs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      s.emptyFavorites,
                      style: TextStyle(color: ObicColors.mutedOf(ctx)),
                    ),
                  )
                else
                  for (final id in favs)
                    ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFE11D48),
                      ),
                      title: Text(id),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, VoidCallback onTap})>[
      (
        icon: Icons.location_on_outlined,
        label: s.profileAddresses,
        onTap: () => _openAddresses(context),
      ),
      (
        icon: Icons.favorite_border_rounded,
        label: s.profileFavorites,
        onTap: () => _openFavorites(context),
      ),
      (
        icon: Icons.history_rounded,
        label: s.profileRecent,
        onTap: () => _openRecent(context),
      ),
      (
        icon: Icons.receipt_long_outlined,
        label: s.profileOrders,
        onTap: () => _openOrders(context),
      ),
    ];

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final it = items[i];
          return ObicBounce(
            onTap: it.onTap,
            child: Container(
              width: 92,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: ObicColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ObicColors.lineOf(context).withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(it.icon, color: ObicColors.blue, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    it.label,
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
    );
  }
}
