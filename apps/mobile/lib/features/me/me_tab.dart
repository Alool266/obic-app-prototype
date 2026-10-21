// Made by Dr Ali
// Me tab — WeChat-style header (Status + friends pills) + dense list groups.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;

import '../admin/admin_home_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../auth/require_auth.dart';
import '../channels/channel_nav.dart';
import '../friends/add_friend_screen.dart';
import '../friends/contact_profile_screen.dart';
import '../friends/friends_screen.dart';
import '../messages/chat_favorites_sheet.dart';
import 'addresses_screen.dart';
import 'language_settings_screen.dart';
import 'pay_services_demo_screen.dart';
import 'profile_settings_screen.dart';
import 'settings_screen.dart';
import 'settings_widgets.dart';
import '../moments/moment_avatar.dart';
import '../moments/moments_profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../ops/ops_hub_screen.dart';
import '../orders/orders_tab.dart';
import '../social/social_api.dart';
import '../shell/tab_badge.dart';
import '../../core/china_phone_gate.dart';
import '../../core/obic_bidi.dart';
import '../../core/legal_links.dart';
import '../../core/offline_cache_store.dart';
import '../../core/region_controller.dart';
import '../../l10n/locale_controller.dart';
import '../../l10n/theme_mode_controller.dart';
import '../../widgets/language_switcher.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/obic_logo.dart';

class MeTab extends StatefulWidget {
  const MeTab({
    super.key,
    required this.localeController,
    required this.themeModeController,
    required this.authController,
    this.regionController,
    this.pendingFriendRequests = 0,
    this.unreadNotifications = 0,
    this.onBadgeRefresh,
    this.onOpenServices,
  });

  final LocaleController localeController;
  final ThemeModeController themeModeController;
  final AuthController authController;
  final RegionController? regionController;
  final int pendingFriendRequests;
  final int unreadNotifications;
  final Future<void> Function()? onBadgeRefresh;

  /// Switch shell to Services tab (from Pay & Services demo hub).
  final VoidCallback? onOpenServices;

  @override
  State<MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<MeTab> {
  final _api = SocialApi();
  bool _uploadingAvatar = false;
  int _friendsCount = 0;
  String? _friendsPreviewAvatar;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.authController.refreshProfile();
      await _loadFriendsMeta();
    });
  }

  @override
  void didUpdateWidget(covariant MeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authController.user?.id != widget.authController.user?.id) {
      unawaited(_loadFriendsMeta());
    }
  }

  void _applyFriends(List<Map<String, dynamic>> friends) {
    String? preview;
    for (final row in friends) {
      final user = row['user'];
      if (user is Map) {
        final url = user['avatarUrl'] as String?;
        if (url != null && url.isNotEmpty) {
          preview = url;
          break;
        }
      }
    }
    setState(() {
      _friendsCount = friends.length;
      _friendsPreviewAvatar = preview;
    });
  }

  Future<void> _loadFriendsMeta() async {
    if (!widget.authController.isAuthenticated) {
      if (mounted) {
        setState(() {
          _friendsCount = 0;
          _friendsPreviewAvatar = null;
        });
      }
      return;
    }
    final uid = widget.authController.user?.id ?? '';
    if (uid.isNotEmpty) {
      final cached = await OfflineCacheStore.instance.loadFriends(uid);
      if (cached != null && mounted) _applyFriends(cached);
    }
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      final friends = await _api.listFriends(token);
      if (uid.isNotEmpty) {
        await OfflineCacheStore.instance.saveFriends(uid, friends);
      }
      if (!mounted) return;
      _applyFriends(friends);
    } catch (_) {
      // Cached count stays. A cold start with no snapshot keeps 0.
    }
  }

  Future<void> _openProtected(
    BuildContext context,
    Widget Function() builder,
  ) async {
    final ok = await requireAuth(context, widget.authController);
    if (!context.mounted || !ok) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => builder()));
  }

  Future<void> _openOrders(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final region = widget.regionController;
    final needsEmail =
        region != null &&
        clientNeedsEmailVerification(
          user: widget.authController.user,
          region: region,
        );
    if (needsEmail) {
      await openChinaVerificationGates(
        context: context,
        auth: widget.authController,
        localeController: widget.localeController,
        themeModeController: widget.themeModeController,
        region: region,
      );
      if (!context.mounted) return;
      if (clientNeedsEmailVerification(
        user: widget.authController.user,
        region: region,
      )) {
        return;
      }
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: ObicColors.scaffoldOf(context),
          appBar: AppBar(title: Text(l10n.ordersTitle)),
          body: OrdersTab(authController: widget.authController),
        ),
      ),
    );
  }

  Future<void> _openFavorites(BuildContext context) async {
    final ok = await requireAuth(context, widget.authController);
    if (!context.mounted || !ok) return;
    await showChatFavoritesPicker(
      context,
      pickMode: false,
      authController: widget.authController,
    );
  }

  Future<void> _openProfile({String? focusField}) async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSettingsScreen(
          authController: widget.authController,
          focusField: focusField,
        ),
      ),
    );
    if (mounted) await widget.authController.refreshProfile();
  }

  Future<void> _openMyPosts() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final me = widget.authController.user;
    if (me == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MomentsProfileScreen(
          authController: widget.authController,
          userId: me.id,
          initialName: me.name,
          initialAvatarUrl: me.avatarUrl,
        ),
      ),
    );
  }

  Future<void> _openChannel() async {
    await openMyChannel(context, widget.authController);
  }

  Future<void> _openFriends() async {
    await _openProtected(
      context,
      () => FriendsScreen(
        authController: widget.authController,
        openNewFriends: widget.pendingFriendRequests > 0,
      ),
    );
    await widget.onBadgeRefresh?.call();
    await _loadFriendsMeta();
  }

  Future<void> _openMyQr() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddFriendScreen(
          authController: widget.authController,
          demoInitialTab: 1,
        ),
      ),
    );
  }

  Future<void> _copyObicId(String id) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.profileObicIdCopied),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  Future<void> _changeAvatar() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final shot = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (shot == null || !mounted) return;
    setState(() => _uploadingAvatar = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      final items = await _api.uploadFiles(
        accessToken: token,
        files: [(path: shot.path, filename: p.basename(shot.path))],
      );
      if (items.isEmpty) return;
      final url = items.first['url'] as String?;
      if (url == null || url.isEmpty) return;
      final json = await _api.updateAvatar(accessToken: token, avatarUrl: url);
      await widget.authController.applyUser(ObicUser.fromJson(json));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.authController,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final authController = widget.authController;
        final localeController = widget.localeController;
        final themeModeController = widget.themeModeController;
        final user = authController.user;
        final signedIn = authController.isAuthenticated && user != null;
        final ar = Directionality.of(context) == TextDirection.rtl;

        final canvas = ObicColors.canvasOf(context);
        final surface = ObicColors.surfaceOf(context);
        final muted = ObicColors.mutedOf(context);

        return ColoredBox(
          color: canvas,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              if (signedIn)
                _MeProfileHeader(
                  user: user,
                  uploadingAvatar: _uploadingAvatar,
                  friendsCount: _friendsCount,
                  friendsPreviewAvatar: _friendsPreviewAvatar,
                  pendingFriendRequests: widget.pendingFriendRequests,
                  onTapAvatar: () {
                    final me = authController.user;
                    if (me == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ContactProfileScreen(
                          authController: authController,
                          userId: me.id,
                          allowCall: false,
                        ),
                      ),
                    );
                  },
                  onLongPressAvatar: _changeAvatar,
                  onTapBody: () => _openProfile(),
                  onTapObicId: () {
                    final id = user.obicId?.trim() ?? '';
                    if (id.isNotEmpty) {
                      _copyObicId(id);
                    } else {
                      _openProfile(focusField: 'obicId');
                    }
                  },
                  onTapQr: _openMyQr,
                  onTapStatus: () => _openProfile(focusField: 'whatsUp'),
                  onTapFriends: _openFriends,
                )
              else
                _MeGuestHeader(
                  onLogin: () => openLoginScreen(context, authController),
                  onRegister: () => openRegisterScreen(context, authController),
                ),
              const SizedBox(height: 12),
              // WeChat primary group: Pay/Services · Favorites · My Posts · Works
              SettingsGroup(
                dividerIndent: 56,
                children: [
                  _MeMenuRow(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF07C160),
                    title: l10n.mePayServices,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PayServicesDemoScreen(
                            onOpenRealServices: widget.onOpenServices,
                          ),
                        ),
                      );
                    },
                  ),
                  _MeMenuRow(
                    icon: Icons.star_border_rounded,
                    iconColor: const Color(0xFFFA9D3B),
                    title: l10n.meFavorites,
                    onTap: () => _openFavorites(context),
                  ),
                  if (signedIn)
                    _MeMenuRow(
                      icon: Icons.photo_camera_outlined,
                      iconColor: const Color(0xFF576B95),
                      title: l10n.meMyPosts,
                      onTap: _openMyPosts,
                    ),
                  if (signedIn)
                    _MeMenuRow(
                      icon: Icons.smart_display_outlined,
                      iconColor: const Color(0xFF1485EE),
                      title: l10n.meWorks,
                      subtitle: l10n.meChannelHint,
                      onTap: _openChannel,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SettingsGroup(
                dividerIndent: 56,
                children: [
                  if (signedIn)
                    _MeMenuRow(
                      icon: Icons.location_on_outlined,
                      title: l10n.addressesTitle,
                      onTap: () => _openProtected(
                        context,
                        () => AddressesScreen(authController: authController),
                      ),
                    ),
                  _MeMenuRow(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.ordersTitle,
                    onTap: () => _openOrders(context),
                  ),
                  _MeMenuRow(
                    icon: Icons.notifications_none_rounded,
                    title: l10n.notificationsTitle,
                    badge: signedIn ? widget.unreadNotifications : 0,
                    onTap: () async {
                      await _openProtected(
                        context,
                        () => NotificationsScreen(
                          authController: authController,
                          onUnreadChanged: widget.onBadgeRefresh,
                        ),
                      );
                      await widget.onBadgeRefresh?.call();
                    },
                  ),
                  if (signedIn && authController.canOpenOps)
                    _MeMenuRow(
                      icon: Icons.apartment_rounded,
                      title: ar ? 'النظام الإداري الداخلي' : 'Internal Ops',
                      onTap: () =>
                          _openProtected(context, () => const OpsHubScreen()),
                    ),
                  if (signedIn && authController.isStaffRole)
                    _MeMenuRow(
                      icon: Icons.admin_panel_settings_outlined,
                      title: ar
                          ? 'عمليات الخدمة (الحالية)'
                          : 'Service desk (current)',
                      onTap: () => _openProtected(
                        context,
                        () => AdminHomeScreen(authController: authController),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SettingsGroup(
                dividerIndent: 56,
                children: [
                  _MeMenuRow(
                    icon: Icons.settings_outlined,
                    iconColor: const Color(0xFF1485EE),
                    title: l10n.settingsTitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SettingsScreen(
                            authController: authController,
                            localeController: localeController,
                            themeModeController: themeModeController,
                            onBadgeRefresh: widget.onBadgeRefresh,
                          ),
                        ),
                      );
                    },
                  ),
                  _MeMenuRow(
                    icon: Icons.language,
                    title: languageMenuTitle(localeController.langCode),
                    trailingText: languageNativeName(localeController.langCode),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LanguageSettingsScreen(
                            localeController: localeController,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SettingsGroup(
                dividerIndent: 56,
                children: [
                  _MeMenuRow(
                    icon: Icons.description_outlined,
                    title: l10n.legalTerms,
                    onTap: () => ObicLegal.open(ObicLegal.terms),
                  ),
                  _MeMenuRow(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.legalPrivacy,
                    onTap: () => ObicLegal.open(ObicLegal.privacy),
                  ),
                ],
              ),
              if (signedIn) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: authController.busy
                        ? null
                        : () => authController.logout(),
                    style: TextButton.styleFrom(
                      foregroundColor: ObicColors.badgeRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      l10n.authLogout,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  l10n.aboutObicBlurb,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.aboutCredit,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// WeChat-style identity: avatar · name · OBIC ID · QR · Status + friends pills.
class _MeProfileHeader extends StatelessWidget {
  const _MeProfileHeader({
    required this.user,
    required this.uploadingAvatar,
    required this.friendsCount,
    required this.friendsPreviewAvatar,
    required this.pendingFriendRequests,
    required this.onTapAvatar,
    required this.onLongPressAvatar,
    required this.onTapBody,
    required this.onTapObicId,
    required this.onTapQr,
    required this.onTapStatus,
    required this.onTapFriends,
  });

  final ObicUser user;
  final bool uploadingAvatar;
  final int friendsCount;
  final String? friendsPreviewAvatar;
  final int pendingFriendRequests;
  final VoidCallback onTapAvatar;
  final VoidCallback onLongPressAvatar;
  final VoidCallback onTapBody;
  final VoidCallback onTapObicId;
  final VoidCallback onTapQr;
  final VoidCallback onTapStatus;
  final VoidCallback onTapFriends;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = user.obicId?.trim() ?? '';
    final hasId = id.isNotEmpty;

    final surface = ObicColors.surfaceOf(context);
    final ink = ObicColors.inkOf(context);
    final muted = ObicColors.mutedOf(context);
    final idAccent = ObicColors.isDark(context)
        ? ObicColors.darkInk
        : ObicColors.navy;

    return Material(
      color: surface,
      child: InkWell(
        onTap: onTapBody,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onTapAvatar,
                    onLongPress: onLongPressAvatar,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        MomentAvatar(
                          name: user.name,
                          avatarUrl: user.avatarUrl,
                          size: 64,
                          borderRadius: 10,
                        ),
                        if (uploadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: ink,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: onTapObicId,
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    Text(
                                      '${l10n.meObicId}: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: muted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Flexible(
                                      child: hasId
                                          ? ObicIdentifierText(
                                              id,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: idAccent,
                                              ),
                                            )
                                          : Text(
                                              l10n.profileSetObicId,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: ObicColors.blue,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.meMyQr,
                              onPressed: onTapQr,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              icon: Icon(
                                Icons.qr_code_2_rounded,
                                color: muted,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MePill(
                              onTap: onTapStatus,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 14, color: muted),
                                  const SizedBox(width: 2),
                                  Text(
                                    l10n.meStatus,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _MePill(
                              onTap: onTapFriends,
                              showDot: pendingFriendRequests > 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (friendsPreviewAvatar != null &&
                                      friendsPreviewAvatar!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        end: 6,
                                      ),
                                      child: MomentAvatar(
                                        name: 'f',
                                        avatarUrl: friendsPreviewAvatar,
                                        size: 18,
                                        borderRadius: 9,
                                      ),
                                    ),
                                  Text(
                                    l10n.meFriendsCount(friendsCount),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: muted.withValues(alpha: 0.7),
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MePill extends StatelessWidget {
  const _MePill({
    required this.child,
    required this.onTap,
    this.showDot = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final raised = ObicColors.surfaceRaisedOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: raised,
              borderRadius: BorderRadius.circular(20),
            ),
            child: child,
          ),
          if (showDot)
            PositionedDirectional(
              end: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ObicColors.badgeRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeGuestHeader extends StatelessWidget {
  const _MeGuestHeader({required this.onLogin, required this.onRegister});

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = ObicColors.surfaceOf(context);
    final ink = ObicColors.inkOf(context);
    final muted = ObicColors.mutedOf(context);
    const compactBtn = Size(0, 40);

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ObicLogo(size: 64, borderRadius: 10),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.meTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.meGuestHint,
                      style: TextStyle(fontSize: 13, color: muted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: ObicColors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: compactBtn,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(l10n.authLogin),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRegister,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ObicColors.blue,
                    side: const BorderSide(color: ObicColors.blue),
                    minimumSize: compactBtn,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(l10n.authRegister),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeMenuRow extends StatelessWidget {
  const _MeMenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge = 0,
    this.trailingText,
    this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int badge;
  final String? trailingText;
  final String? subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ink = ObicColors.inkOf(context);
    final muted = ObicColors.mutedOf(context);
    final color = iconColor ?? ObicColors.blue;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minVerticalPadding: 10,
      leading: ObicMenuBadgeIcon(
        unread: badge,
        size: 28,
        icon: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ink,
          height: 1.2,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: muted),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null && trailingText!.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                trailingText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ),
          Icon(
            Icons.chevron_right_rounded,
            color: muted.withValues(alpha: 0.7),
            size: 20,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
