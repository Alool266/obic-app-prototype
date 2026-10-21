// Made by Dr Ali
// WeChat-style Discover hub — Moments + Channels + OBIC Apps entry.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/api_errors.dart';
import '../../core/badge_store.dart';
import '../../core/media_url.dart';
import '../../core/offline_cache_store.dart';
import '../../widgets/obic_cached_image.dart';
import '../../widgets/obic_lottie_empty.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../mini_apps/mini_apps_pull_panel.dart';
import '../moments/moments_screen.dart';
import '../social/social_api.dart';
import 'channel_nav.dart';
import 'channel_viewer_screen.dart';
import 'discover_extras.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.authController,
    this.lastSeenMomentsAt,
    this.isActive = true,
    this.onMomentsOpened,
  });

  final AuthController authController;
  final DateTime? lastSeenMomentsAt;
  final bool isActive;
  final VoidCallback? onMomentsOpened;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _api = SocialApi();
  Map<String, dynamic>? _preview;
  bool _loading = true;
  String? _error;
  bool _channelsUnreadDot = false;
  bool _channelsBaselined = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.authController.user?.id != oldWidget.authController.user?.id) {
      _preview = null;
      unawaited(_load());
      return;
    }
    if (widget.isActive && !oldWidget.isActive) {
      unawaited(_load(silent: true));
    }
  }

  List<Map<String, dynamic>?> _channelPreviews(Map<String, dynamic>? preview) {
    final channels = preview?['channels'] as Map<String, dynamic>?;
    final me = widget.authController.user?.id;
    Map<String, dynamic>? stripMine(Map<String, dynamic>? v) {
      if (v == null) return null;
      if (v['mine'] == true) return null;
      if (me != null && v['authorId'] == me) return null;
      return v;
    }

    return [
      stripMine(channels?['officialPreview'] as Map<String, dynamic>?),
      stripMine(channels?['friendsPreview'] as Map<String, dynamic>?),
    ];
  }

  /// Prefer official tip, else friends — never own posts (server + client).
  Map<String, dynamic>? _tipPreview(
    Map<String, dynamic>? official,
    Map<String, dynamic>? friends,
  ) {
    final me = widget.authController.user?.id;
    bool usable(Map<String, dynamic>? v) {
      if (v == null) return false;
      if (v['mine'] == true) return false;
      if (me != null && v['authorId'] == me) return false;
      return true;
    }

    if (usable(official)) return official;
    if (usable(friends)) return friends;
    return null;
  }

  Future<void> _refreshChannelsDot() async {
    final previews = _channelPreviews(_preview);
    final hasContent = previews.any((p) => p != null);
    var lastSeen = await readLastSeenChannelsAt();
    // Moments-style baseline: first visit with content marks current as seen
    // so the tip only appears for *new* posts after that.
    if (lastSeen == null && hasContent && !_channelsBaselined) {
      await writeLastSeenChannelsAt(newestChannelPreviewTime(previews));
      _channelsBaselined = true;
      lastSeen = await readLastSeenChannelsAt();
    }
    final show = hasUnseenChannelPreview(previews, lastSeen: lastSeen);
    if (!mounted) return;
    setState(() => _channelsUnreadDot = show);
  }

  Future<void> _markChannelsSeen() async {
    final previews = _channelPreviews(_preview);
    final stamp = newestChannelPreviewTime(previews);
    await writeLastSeenChannelsAt(stamp);
    _channelsBaselined = true;
    if (mounted) setState(() => _channelsUnreadDot = false);
  }

  String get _cacheUserId => widget.authController.user?.id ?? 'guest';

  Future<void> _load({bool silent = false}) async {
    final uid = _cacheUserId;
    if (_preview == null) {
      final cached = await OfflineCacheStore.instance.loadDiscover(uid);
      if (!mounted || uid != _cacheUserId) return;
      if (cached != null) {
        setState(() {
          _preview = cached;
          _loading = false;
          _error = null;
        });
        await _refreshChannelsDot();
      }
    }
    if (!silent && _preview == null && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final token = await widget.authController.accessToken();
      final preview = await _api.getChannelsDiscover(accessToken: token);
      if (!mounted || uid != _cacheUserId) return;
      await OfflineCacheStore.instance.saveDiscover(uid, preview);
      if (!mounted || uid != _cacheUserId) return;
      setState(() {
        _preview = preview;
        _loading = false;
        _error = null;
      });
      await _refreshChannelsDot();
    } catch (e) {
      if (!mounted) return;
      if (_preview != null) {
        setState(() {
          _loading = false;
          _error = null;
        });
        return;
      }
      final l10n = AppLocalizations.of(context);
      final lang = Localizations.localeOf(context).languageCode;
      setState(() {
        _loading = false;
        _error = friendlyApiError(
          classifyTransportError(e),
          l10n: l10n,
          langCode: lang,
        );
      });
    }
  }

  void _openMoments() {
    widget.onMomentsOpened?.call();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MomentsScreen(
          authController: widget.authController,
          embedded: false,
          lastSeenMomentsAt: widget.lastSeenMomentsAt,
          isActive: true,
        ),
      ),
    );
  }

  Future<void> _openChannels() async {
    await _markChannelsSeen();
    if (!mounted) return;
    await openChannelsDiscover(context, widget.authController);
    if (mounted) await _load(silent: true);
  }

  void _openMiniApps() {
    unawaited(
      openMiniAppsPanel(
        context,
        displayName: () => widget.authController.user?.name,
        userId: widget.authController.user?.id,
      ),
    );
  }

  Future<void> _openMyChannel() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChannelViewerScreen(
          authController: widget.authController,
          initialTab: ChannelFeedTab.friends,
          openMyChannelOnStart: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = ObicColors.isDark(context);
    final canvas = dark ? ObicColors.darkCanvas : const Color(0xFFEDEDED);
    final channels = _preview?['channels'] as Map<String, dynamic>?;
    final officialPreview =
        channels?['officialPreview'] as Map<String, dynamic>?;
    final friendsPreview = channels?['friendsPreview'] as Map<String, dynamic>?;
    // WeChat: tip thumb + red only while unread; clear completely after watch.
    final tip = _channelsUnreadDot
        ? _tipPreview(officialPreview, friendsPreview)
        : null;

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        title: Text(l10n.discoverTitle),
        centerTitle: true,
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: l10n.channelMyChannel,
            onPressed: () => unawaited(_openMyChannel()),
            icon: const Icon(Icons.smart_display_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF07C160),
        onRefresh: _load,
        child: DiscoverScroll(
          authController: widget.authController,
          isActive: widget.isActive,
          onMoments: _openMoments,
          onChannels: () => unawaited(_openChannels()),
          onMiniApps: _openMiniApps,
          header: Column(
            children: [
              if (_loading && _preview == null)
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 4),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_error != null && _preview == null)
                ObicLottieEmpty(message: _error!, size: 84),
              const SizedBox(height: 12),
              _DiscoverSection(
                children: [
                  _DiscoverRow(
                    icon: Icons.photo_camera_outlined,
                    iconColor: const Color(0xFFE75D5C),
                    label: l10n.momentsTitle,
                    onTap: _openMoments,
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFB2B2B2),
                    ),
                  ),
                  _DiscoverRow(
                    icon: Icons.play_circle_outline,
                    iconColor: const Color(0xFFF5A623),
                    label: l10n.channelTitle,
                    showDot: _channelsUnreadDot,
                    previewThumb: _thumbUrl(tip),
                    previewText: _previewCaption(tip, l10n),
                    onTap: () => unawaited(_openChannels()),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFB2B2B2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DiscoverSection(
                children: [
                  _DiscoverRow(
                    icon: Icons.apps_outlined,
                    iconColor: const Color(0xFF576B95),
                    label: l10n.miniAppsTitle,
                    subtitle: l10n.discoverMiniAppsHint,
                    onTap: _openMiniApps,
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFB2B2B2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _thumbUrl(Map<String, dynamic>? v) {
    final t = v?['thumbUrl'] as String?;
    if (t != null && t.isNotEmpty) return t;
    final avatar = v?['authorAvatarUrl'] as String?;
    if (avatar != null && avatar.isNotEmpty) return avatar;
    return null;
  }

  String? _previewCaption(Map<String, dynamic>? v, AppLocalizations l10n) {
    if (v == null) return null;
    final cap = (v['caption'] as String?)?.trim();
    if (cap != null && cap.isNotEmpty) return cap;
    final name = (v['authorName'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    return l10n.channelNoCaption;
  }
}

class _DiscoverSection extends StatelessWidget {
  const _DiscoverSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ObicColors.surfaceOf(context),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 56,
                color: ObicColors.lineOf(context).withValues(alpha: 0.7),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _DiscoverRow extends StatelessWidget {
  const _DiscoverRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.previewThumb,
    this.previewText,
    this.showDot = false,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final String? previewThumb;
  final String? previewText;
  final bool showDot;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ObicColors.inkOf(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: ObicColors.mutedOf(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (previewText != null && previewThumb == null)
              Flexible(
                child: Text(
                  previewText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    color: ObicColors.mutedOf(context),
                  ),
                ),
              ),
            if (previewThumb != null) ...[
              if (previewText != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    previewText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: ObicColors.mutedOf(context),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: ObicCachedImage(
                      resolveMediaUrl(previewThumb!),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 40,
                        height: 40,
                        color: const Color(0xFFE8E8E8),
                        child: const Icon(Icons.videocam, size: 18),
                      ),
                    ),
                  ),
                  if (showDot)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFA5151),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ] else if (showDot)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFA5151),
                  shape: BoxShape.circle,
                ),
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
