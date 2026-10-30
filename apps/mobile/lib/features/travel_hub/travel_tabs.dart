// Made by Dr Ali
// Ctrip-style travel mini-app tabs (inside Obic).

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/media_url.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/obic_soft_motion.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../marketplace/delivery_address_bar.dart';
import '../marketplace/marketplace_models.dart';
import '../marketplace/open_marketplace_category.dart';
import '../me/addresses_screen.dart';
import '../me/profile_settings_screen.dart';
import '../moments/moment_avatar.dart';
import '../services/services_api.dart';

class TravelMessagesTab extends StatelessWidget {
  const TravelMessagesTab({
    super.key,
    required this.authController,
    required this.langCode,
  });

  final AuthController authController;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final ar = langCode.startsWith('ar');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text(
          ar ? 'رسائل السفر' : 'Travel messages',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ObicColors.titleOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ar
              ? 'تأكيدات الحجز والعروض من أوبك تظهر هنا.'
              : 'Booking confirms and OBIC travel offers appear here.',
          style: TextStyle(color: ObicColors.mutedOf(context)),
        ),
        const SizedBox(height: 20),
        _emptyCard(
          context,
          icon: Icons.mail_outline_rounded,
          title: ar ? 'لا رسائل بعد' : 'No messages yet',
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => openMarketplaceCategory(
            context: context,
            authController: authController,
            langCode: langCode,
            vertical: MarketplaceVertical.hotel,
          ),
          style: FilledButton.styleFrom(backgroundColor: ObicColors.blue),
          child: Text(ar ? 'تصفح الفنادق' : 'Browse hotels'),
        ),
      ],
    );
  }
}

class TravelCommunityTab extends StatelessWidget {
  const TravelCommunityTab({
    super.key,
    required this.authController,
    required this.langCode,
  });

  final AuthController authController;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final ar = langCode.startsWith('ar');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text(
          ar ? 'مجتمع المسافرين' : 'Travel community',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ObicColors.titleOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ar
              ? 'نصائح ييوو وشنغهاي — اضغط لفتح القسم المناسب.'
              : 'Yiwu & Shanghai tips — tap to open the right section.',
          style: TextStyle(color: ObicColors.mutedOf(context)),
        ),
        const SizedBox(height: 16),
        _communityTile(
          context,
          title: ar ? 'أفضل فنادق قرب السوق' : 'Best hotels near the market',
          onTap: () => openMarketplaceCategory(
            context: context,
            authController: authController,
            langCode: langCode,
            vertical: MarketplaceVertical.hotel,
            city: 'Yiwu',
          ),
        ),
        _communityTile(
          context,
          title: ar ? 'قطار هانغتشو في ساعة' : 'Hangzhou train in 1 hour',
          onTap: () => openMarketplaceCategory(
            context: context,
            authController: authController,
            langCode: langCode,
            vertical: MarketplaceVertical.train,
          ),
        ),
        _communityTile(
          context,
          title: ar ? 'تأشيرة سريعة' : 'Fast visa tips',
          onTap: () => openTravelServiceRequest(
            context: context,
            authController: authController,
            langCode: langCode,
            catId: 'visa',
          ),
        ),
      ],
    );
  }
}

Widget _communityTile(
  BuildContext context, {
  required String title,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ObicBounce(
      onTap: onTap,
      child: Material(
        color: ObicColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: const Icon(Icons.forum_rounded, color: ObicColors.blue),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    ),
  );
}

class TravelTripsTab extends StatefulWidget {
  const TravelTripsTab({
    super.key,
    required this.authController,
    required this.langCode,
  });

  final AuthController authController;
  final String langCode;

  @override
  State<TravelTripsTab> createState() => _TravelTripsTabState();
}

class _TravelTripsTabState extends State<TravelTripsTab>
    with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _future;
  late final TabController _seg;

  static const _done = {'Completed', 'Cancelled', 'closed', 'done'};

  @override
  void initState() {
    super.initState();
    _seg = TabController(length: 2, vsync: this);
    _future = _load();
  }

  @override
  void dispose() {
    _seg.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final token = await widget.authController.accessToken();
    if (token == null) return const [];
    try {
      final rows = await ServicesApi().listMyOrders(token);
      return rows.where((o) {
        final slug =
            '${o['serviceSlug'] ?? o['parentSlug'] ?? o['service']?['slug'] ?? ''}'
                .toLowerCase();
        return slug == 'travel' ||
            slug == 'transport' ||
            slug.contains('hotel') ||
            slug.contains('flight') ||
            slug.contains('train') ||
            slug.contains('tour') ||
            slug.contains('transfer');
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  bool _isPast(Map<String, dynamic> o) {
    final st = '${o['status'] ?? ''}';
    return _done.contains(st);
  }

  Widget _tripTile(Map<String, dynamic> o) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ObicColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: const Icon(
            Icons.confirmation_number_rounded,
            color: ObicColors.blue,
          ),
          title: Text(
            '${o['serviceName'] ?? o['title'] ?? o['id'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('${o['status'] ?? ''}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.langCode.startsWith('ar');
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        final items = snap.data ?? const [];
        final upcoming = items.where((o) => !_isPast(o)).toList();
        final past = items.where(_isPast).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                ar ? 'رحلاتي' : 'My trips',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: ObicColors.titleOf(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                ar
                    ? 'طلبات الفنادق والطيران من خادم أوبك.'
                    : 'Hotel & flight orders from the OBIC server.',
                style: TextStyle(color: ObicColors.mutedOf(context)),
              ),
            ),
            TabBar(
              controller: _seg,
              labelColor: ObicColors.blue,
              tabs: [
                Tab(text: ar ? 'قادمة (${upcoming.length})' : 'Upcoming (${upcoming.length})'),
                Tab(text: ar ? 'سابقة (${past.length})' : 'Past (${past.length})'),
              ],
            ),
            Expanded(
              child: snap.connectionState == ConnectionState.waiting &&
                      items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _seg,
                      children: [
                        ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            if (upcoming.isEmpty)
                              _emptyCard(
                                context,
                                icon: Icons.luggage_rounded,
                                title: ar ? 'لا رحلات قادمة' : 'No upcoming trips',
                              )
                            else
                              for (final o in upcoming) _tripTile(o),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => openMarketplaceCategory(
                                context: context,
                                authController: widget.authController,
                                langCode: widget.langCode,
                                vertical: MarketplaceVertical.hotel,
                              ),
                              child: Text(ar ? 'احجز فندقاً' : 'Book a hotel'),
                            ),
                          ],
                        ),
                        ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            if (past.isEmpty)
                              _emptyCard(
                                context,
                                icon: Icons.history_rounded,
                                title: ar ? 'لا رحلات سابقة' : 'No past trips',
                              )
                            else
                              for (final o in past) _tripTile(o),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class TravelAccountTab extends StatefulWidget {
  const TravelAccountTab({
    super.key,
    required this.authController,
    required this.langCode,
  });

  final AuthController authController;
  final String langCode;

  @override
  State<TravelAccountTab> createState() => _TravelAccountTabState();
}

class _TravelAccountTabState extends State<TravelAccountTab> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshMe());
  }

  Future<void> _refreshMe() async {
    final token = await widget.authController.accessToken();
    if (token == null) return;
    setState(() => _refreshing = true);
    try {
      final user = await AuthApi().fetchMe(token);
      await widget.authController.applyUser(user);
    } catch (_) {
      // keep cached user
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.langCode.startsWith('ar');
    final user = widget.authController.user;
    final name = user?.name ?? (ar ? 'ضيف' : 'Guest');
    // Force resolve against OUR API host (rewrites trial /uploads).
    final avatar = resolveMediaUrl(user?.avatarUrl);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Row(
          children: [
            MomentAvatar(
              name: name,
              avatarUrl: avatar.isEmpty ? null : avatar,
              size: 72,
              borderRadius: 16,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: ObicColors.titleOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ar ? 'حساب السفر · أوبك' : 'Travel account · OBIC',
                    style: TextStyle(color: ObicColors.mutedOf(context)),
                  ),
                  if (_refreshing)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (avatar.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            ar
                ? 'أضف صورة من الملف الشخصي — تُحفظ على خادم أوبك.'
                : 'Add a photo in Profile — stored on the OBIC server.',
            style: TextStyle(
              color: ObicColors.mutedOf(context),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 20),
        DeliveryAddressBar(
          authController: widget.authController,
          langCode: widget.langCode,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 16),
        _accountTile(
          context,
          icon: Icons.person_rounded,
          title: ar ? 'الملف الشخصي' : 'Profile',
          onTap: () async {
            final ok = await requireAuth(context, widget.authController);
            if (!context.mounted || !ok) return;
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => ProfileSettingsScreen(
                  authController: widget.authController,
                ),
              ),
            );
            await _refreshMe();
          },
        ),
        _accountTile(
          context,
          icon: Icons.location_on_rounded,
          title: ar ? 'عناويني' : 'My addresses',
          onTap: () async {
            final ok = await requireAuth(context, widget.authController);
            if (!context.mounted || !ok) return;
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) =>
                    AddressesScreen(authController: widget.authController),
              ),
            );
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _accountTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ObicBounce(
        onTap: onTap,
        child: Material(
          color: ObicColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            leading: Icon(icon, color: ObicColors.blue),
            title:
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      ),
    );
  }
}

Widget _emptyCard(
  BuildContext context, {
  required IconData icon,
  required String title,
}) {
  return Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: ObicColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ObicColors.lineOf(context)),
    ),
    child: Column(
      children: [
        Icon(icon, size: 40, color: ObicColors.mutedOf(context)),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ObicColors.mutedOf(context),
          ),
        ),
      ],
    ),
  );
}
