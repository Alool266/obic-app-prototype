// Made by Dr Ali
// WeChat Moments–style feed — likes, comments, tap-to-view media + download.
// Bottom-tab only (not on Home). Guests browse; actions require auth.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

import '../../core/api_errors.dart';
import '../../core/app_foreground.dart';
import '../../core/badge_store.dart';
import '../../core/connectivity_service.dart';
import '../../core/media_pick.dart';
import '../../core/media_url.dart';
import '../../core/offline_cache_store.dart';
import '../../core/upload_filename.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/obic_cached_image.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/wechat_media_actions.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_api.dart';
import '../auth/auth_models.dart';
import '../auth/require_auth.dart';
import '../ai/ai_api.dart';
import '../channels/channel_nav.dart';
import '../messages/chat_favorites_store.dart';
import '../social/social_api.dart';
import 'media_download.dart';
import 'moment_avatar.dart';
import 'moment_comment_composer.dart';
import 'moment_engagement.dart';
import 'moment_compose_screen.dart';
import 'moment_media_viewer.dart';
import 'moments_cover_adjust_screen.dart';
import 'moments_profile_screen.dart';
import 'moment_pin_store.dart';
import 'moments_header_chrome.dart';
import 'moments_notify_prefs.dart';

const _kWeChatName = Color(0xFF576B95);
const _kWeChatBg = Color(0xFFF7F7F7);
const _kWeChatGreen = Color(0xFF07C160);

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({
    super.key,
    required this.authController,
    this.embedded = false,
    this.lastSeenMomentsAt,
    this.isActive = false,
    this.focusMomentId,
  });

  final AuthController authController;
  final bool embedded;
  /// Posts after this timestamp render as unseen (WeChat bold).
  final DateTime? lastSeenMomentsAt;
  final bool isActive;
  /// When set (e.g. from Favorites), scroll this moment into view after load.
  final String? focusMomentId;

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  final _api = SocialApi();
  final _scroll = ScrollController();
  final Map<String, GlobalKey> _momentKeys = {};
  List<Map<String, dynamic>> _feed = [];
  bool _loading = true;
  String? _error;
  String? _cacheUserKey;
  Future<void>? _loadInFlight;
  /// 0 = cover expanded, 1 = pinned toolbar (WeChat Moments chrome).
  double _collapseT = 0;
  bool _didFocusMoment = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    widget.authController.addListener(_onAuth);
    AppForeground.instance.addListener(_onForegroundChanged);
    _cacheUserKey = widget.authController.user?.id ?? 'guest';
    // First open / cold start — always fetch latest (WeChat Moments).
    unawaited(_load());
  }

  void _onScroll() {
    if (!mounted || !_scroll.hasClients) return;
    final next = momentsHeaderCollapseT(
      scrollOffset: _scroll.offset,
      topPadding: MediaQuery.paddingOf(context).top,
      expandedHeight: kMomentsCoverExpandedHeight,
    );
    if ((next - _collapseT).abs() < 0.015) return;
    setState(() => _collapseT = next);
  }

  @override
  void didUpdateWidget(MomentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      // Entering Moments tab — refresh without requiring pull.
      unawaited(_load(silent: _feed.isNotEmpty));
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    AppForeground.instance.removeListener(_onForegroundChanged);
    widget.authController.removeListener(_onAuth);
    super.dispose();
  }

  void _onAuth() {
    final nextKey = widget.authController.user?.id ?? 'guest';
    if (nextKey != _cacheUserKey) {
      _cacheUserKey = nextKey;
      // Account switch / login — drop stale feed immediately.
      if (mounted) {
    setState(() {
          _feed = [];
      _loading = true;
      _error = null;
    });
      }
      unawaited(_load());
      return;
    }
    if (widget.authController.isAuthenticated) {
      unawaited(_load(silent: _feed.isNotEmpty));
    }
  }

  void _onForegroundChanged() {
    if (AppForeground.instance.isActive && widget.isActive) {
      unawaited(_load(silent: _feed.isNotEmpty));
    }
  }

  Future<void> _load({bool silent = false}) async {
    final existing = _loadInFlight;
    if (existing != null) return existing;
    final done = _loadInner(silent: silent);
    _loadInFlight = done;
    return done.whenComplete(() {
      if (identical(_loadInFlight, done)) _loadInFlight = null;
    });
  }

  Future<List<Map<String, dynamic>>> _presentMoments(
    List<Map<String, dynamic>> rows,
  ) async {
    final muted = (await MomentsNotifyPrefs.mutedFriendIds()).toSet();
    final meId = widget.authController.user?.id;
    final visible = rows.where((m) {
      final author = m['authorId'] as String?;
      if (author == null || author == meId) return true;
      return !muted.contains(author);
    }).toList();
    return visible.length > 100 ? visible.sublist(0, 100) : visible;
  }

  Future<void> _loadInner({bool silent = false}) async {
    final cacheKey = widget.authController.user?.id ?? 'guest';
    _cacheUserKey = cacheKey;
    if (_feed.isEmpty) {
      final cached = await OfflineCacheStore.instance.loadMoments(cacheKey);
      if (!mounted || cacheKey != (widget.authController.user?.id ?? 'guest')) {
        return;
      }
      if (cached != null && cached.isNotEmpty) {
        final visible = await _presentMoments(cached);
        if (!mounted) return;
        setState(() {
          _feed = visible;
          _loading = false;
          _error = null;
        });
        _scheduleFocusMoment();
      }
    }
    if (!silent && _feed.isEmpty && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final token = await widget.authController.accessToken();
      final rows = await _api.listMoments(accessToken: token);
      if (!mounted || cacheKey != (widget.authController.user?.id ?? 'guest')) {
        return;
      }
      await OfflineCacheStore.instance.saveMoments(cacheKey, rows);
      final capped = await _presentMoments(rows);
      if (!mounted) return;
      setState(() {
        _feed = capped;
        _loading = false;
        _error = null;
      });
      _scheduleFocusMoment();
    } catch (e) {
      if (!mounted) return;
      if (_feed.isNotEmpty) {
      setState(() {
        _loading = false;
          _error = null;
        });
        return;
      }
      final cached = await OfflineCacheStore.instance.loadMoments(cacheKey);
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        final visible = await _presentMoments(cached);
        if (!mounted) return;
        setState(() {
          _feed = visible;
          _loading = false;
          _error = null;
        });
        _scheduleFocusMoment();
        return;
      }
      setState(() {
        _loading = false;
        final l10n = AppLocalizations.of(context);
        _error = ConnectivityService.instance.isOffline
            ? l10n.offlineNeedsNetwork
            : friendlyApiError(
                classifyTransportError(e),
                l10n: l10n,
                langCode: Localizations.localeOf(context).languageCode,
              );
      });
    }
  }

  void _scheduleFocusMoment() {
    final focusId = widget.focusMomentId?.trim();
    if (focusId == null || focusId.isEmpty || _didFocusMoment) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didFocusMoment) return;
      final key = _momentKeys[focusId];
      final ctx = key?.currentContext;
      if (ctx == null) {
        // Moment may be off the first build pass — try once more next frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _didFocusMoment) return;
          final retryCtx = _momentKeys[focusId]?.currentContext;
          if (retryCtx == null) return;
          _didFocusMoment = true;
          Scrollable.ensureVisible(
            retryCtx,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            alignment: 0.12,
          );
        });
        return;
      }
      _didFocusMoment = true;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      );
    });
  }

  Future<void> _openCompose() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    if (ConnectivityService.instance.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            offlineNeedsNetworkMessage(AppLocalizations.of(context)),
          ),
        ),
      );
      return;
    }

    final choice = await showMomentsCreateSheet(context);
    if (!mounted || choice == null) return;

    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    List<({String path, String filename, String kind})> initial = [];

    void toastPick(Object e) {
      final token = classifyMediaPickError(e);
      final msg = switch (token) {
        'camera_denied' => l10n.mediaCameraPermissionDenied,
        'photos_denied' => l10n.mediaPhotosPermissionDenied,
        'mic_denied' => l10n.chatMicPermissionDenied,
        'cancelled' => '',
        _ => l10n.mediaPickFailed,
      };
      if (msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }

    try {
      switch (choice) {
        case 'album':
          final shots = await pickAlbumImages(picker, imageQuality: 85, limit: 9);
          if (shots.isEmpty || !mounted) return;
          initial = [
            for (final s in shots)
              (path: s.path, filename: s.filename, kind: s.kind),
          ];
        case 'camera':
          final shot = await takeCameraPhoto(picker, imageQuality: 85);
          if (shot == null || !mounted) return;
          initial = [
            (path: shot.path, filename: shot.filename, kind: shot.kind),
          ];
        case 'video':
          final source = await showWechatVideoSourceSheet(context);
          if (source == null || !mounted) return;
          final v = await pickOrRecordVideo(
            picker,
            source: source,
            maxDuration: kMomentsVideoMaxDuration,
          );
          if (v == null || !mounted) return;
          final len = await localFileLength(v.path);
          if (!mounted) return;
          final sizeToken = classifyVideoSize(len);
          if (sizeToken == 'too_large') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.chatVideoTooLarge)),
            );
            return;
          }
          if (sizeToken == 'unreadable') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.chatVideoPickFailed)),
            );
            return;
          }
          if (sizeToken == 'large_warning') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.chatVideoLargeWarning)),
            );
          }
          initial = [
            (path: v.path, filename: v.filename, kind: v.kind),
          ];
        case 'text':
          break;
        default:
          return;
      }
    } catch (e) {
      if (!mounted) return;
      toastPick(e);
      return;
    }

    if (!mounted) return;
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MomentComposeScreen(
          authController: widget.authController,
          initialMedia: initial,
        ),
      ),
    );
    if (posted == true) {
      // Own post must not leave a Moments tab badge (WeChat-like).
      await writeLastSeenMomentsAt(DateTime.now());
      if (!mounted) return;
      await _load();
    }
  }

  void _toastCoverError(Object e) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final msg = friendlyApiError(
      classifyTransportError(e),
      l10n: l10n,
      langCode: lang,
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _changeCover() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final shot = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (shot == null || !mounted) return;

    final initialFocus =
        widget.authController.user?.momentsCoverFocusY ?? 0.0;
    final adjusted = await Navigator.of(context).push<MomentsCoverAdjustResult>(
      MaterialPageRoute(
        builder: (_) => MomentsCoverAdjustScreen(
          imagePath: shot.path,
          initialFocusY: initialFocus,
        ),
      ),
    );
    if (adjusted == null || !mounted) return;

    try {
      final token = await widget.authController.accessToken();
      if (token == null) {
        throw AuthApiException('Not signed in');
      }
      final items = await _api.uploadFiles(
        accessToken: token,
        files: [
          (
            path: adjusted.imagePath,
            filename: uploadFilenameForImage(XFile(adjusted.imagePath)),
          ),
        ],
      );
      if (items.isEmpty) {
        throw AuthApiException('Upload failed');
      }
      final url = items.first['url'] as String?;
      if (url == null || url.isEmpty) {
        throw AuthApiException('Upload failed');
      }
      final updated = await AuthApi().updateMomentsCover(
        accessToken: token,
        coverUrl: url,
        focusY: adjusted.focusY,
      );
      await widget.authController.applyUser(updated);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      _toastCoverError(e);
    }
  }

  void _openMomentsProfile({
    required String userId,
    String? name,
    String? avatarUrl,
  }) {
    if (userId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MomentsProfileScreen(
          authController: widget.authController,
          userId: userId,
          initialName: name,
          initialAvatarUrl: avatarUrl,
        ),
      ),
    );
  }

  void _openOwnMomentsProfile() {
    final me = widget.authController.user;
    if (me == null) {
      unawaited(requireAuth(context, widget.authController));
      return;
    }
    _openMomentsProfile(
      userId: me.id,
      name: me.name,
      avatarUrl: me.avatarUrl,
    );
  }

  void _openChannel() {
    openObicOfficialChannel(context, widget.authController);
  }

  Future<void> _changeCoverAvatar() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final shot = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (shot == null || !mounted) return;
    try {
      final token = await widget.authController.accessToken();
      if (token == null) {
        throw AuthApiException('Not signed in');
      }
      final items = await _api.uploadFiles(
        accessToken: token,
        files: [
          (path: shot.path, filename: uploadFilenameForImage(shot)),
        ],
      );
      if (items.isEmpty) {
        throw AuthApiException('Upload failed');
      }
      final url = items.first['url'] as String?;
      if (url == null || url.isEmpty) {
        throw AuthApiException('Upload failed');
      }
      final json = await _api.updateAvatar(
        accessToken: token,
        avatarUrl: url,
      );
      await widget.authController.applyUser(ObicUser.fromJson(json));
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      _toastCoverError(e);
    }
  }

  String _relativeTime(AppLocalizations l10n, dynamic raw) {
    final dt = raw is String ? DateTime.tryParse(raw) : null;
    if (dt == null) return '';
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 1) return l10n.momentsJustNow;
    if (diff.inHours < 1) return l10n.momentsMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.momentsHoursAgo(diff.inHours);
    return l10n.momentsDaysAgo(diff.inDays.clamp(1, 999));
  }

  List<Map<String, dynamic>> _mediaOf(Map<String, dynamic> m) {
    final raw = m['media'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    final imageUrl = m['imageUrl'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return [
        {'kind': 'image', 'url': imageUrl, 'name': 'photo.jpg'},
      ];
    }
    return [];
  }

  void _replaceMoment(String id, Map<String, dynamic> next) {
    final i = _feed.indexWhere((m) => m['id'] == id);
    if (i < 0) return;
    setState(() => _feed[i] = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = widget.authController.user;
    final myName = me?.name ?? 'OBIC';
    final coverUrl = me?.momentsCoverUrl;
    final coverFocus = me?.momentsCoverFocusY ?? 0.0;
    final t = _collapseT;
    final barBg = momentsHeaderBarColor(context, t);
    final fg = momentsHeaderFgColor(context, t);
    // Title fades in as the cover collapses (WeChat Moments).
    final titleOpacity = Curves.easeOut.transform(((t - 0.35) / 0.45).clamp(0.0, 1.0));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: momentsHeaderSystemUi(context, t),
      child: Scaffold(
        backgroundColor: ObicColors.isDark(context)
            ? ObicColors.darkCanvas
            : _kWeChatBg,
        body: RefreshIndicator(
          color: _kWeChatGreen,
          onRefresh: _load,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: kMomentsCoverExpandedHeight,
                backgroundColor: barBg,
                foregroundColor: fg,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                iconTheme: IconThemeData(color: fg),
                actionsIconTheme: IconThemeData(color: fg),
        automaticallyImplyLeading: !widget.embedded,
                title: Opacity(
                  opacity: titleOpacity,
                  child: Text(
                    l10n.momentsTitle,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                ),
        actions: [
                  IconButton(
                    tooltip: l10n.channelTitle,
                    onPressed: _openChannel,
                    icon: Icon(Icons.smart_display_outlined, color: fg),
                  ),
          IconButton(
            tooltip: l10n.momentsCreate,
                    onPressed: _openCompose,
                    icon: Icon(Icons.camera_alt_outlined, color: fg),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        onTap: _changeCover,
                        child: coverUrl != null && coverUrl.isNotEmpty
                            ? ObicCachedImage(
                                resolveMediaUrl(coverUrl),
                                fit: BoxFit.cover,
                                alignment: Alignment(0, coverFocus),
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      ObicColors.navyDeep,
                                      ObicColors.navySoft,
                                      ObicColors.navy,
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      momentsCoverBottomFade(),
                      PositionedDirectional(
                        end: 16,
                        bottom: 16,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _openOwnMomentsProfile,
                              child: Text(
                                myName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _openOwnMomentsProfile,
                              onLongPress: _changeCoverAvatar,
                              child: MomentAvatar(
                                name: myName,
                                avatarUrl: me?.avatarUrl,
                                size: 72,
                                borderRadius: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loading && _feed.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _feed.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                ),
              )
            else if (_feed.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 48,
                            color: ObicColors.blue.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.momentsEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ObicColors.mutedOf(context)),
                          ),
                        ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                          final m = _feed[i];
                    final id = (m['id'] as String?) ?? 'm-$i';
                    final key = _momentKeys.putIfAbsent(id, GlobalKey.new);
                    return KeyedSubtree(
                      key: key,
                      child: _MomentPost(
                      moment: m,
                      media: _mediaOf(m),
                      timeLabel: _relativeTime(l10n, m['createdAt']),
                      unseen: isMomentUnseen(
                        m,
                        lastSeen: widget.lastSeenMomentsAt,
                      ),
                      authController: widget.authController,
                      api: _api,
                      onChanged: (next) =>
                          _replaceMoment(m['id'] as String, next),
                      onReload: _load,
                      onOpenProfile: _openMomentsProfile,
                    ),
                    );
                  },
                  childCount: _feed.length,
                ),
              ),
              const SoftSliverSpacer(height: 88),
            ],
          ),
        ),
      ),
    );
  }
}

class SoftSliverSpacer extends StatelessWidget {
  const SoftSliverSpacer({super.key, required this.height, this.child});
  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: height,
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _MomentPost extends StatefulWidget {
  const _MomentPost({
    required this.moment,
    required this.media,
    required this.timeLabel,
    required this.unseen,
    required this.authController,
    required this.api,
    required this.onChanged,
    required this.onReload,
    required this.onOpenProfile,
  });

  final Map<String, dynamic> moment;
  final List<Map<String, dynamic>> media;
  final String timeLabel;
  final bool unseen;
  final AuthController authController;
  final SocialApi api;
  final void Function(Map<String, dynamic> next) onChanged;
  final Future<void> Function() onReload;
  final void Function({
    required String userId,
    String? name,
    String? avatarUrl,
  }) onOpenProfile;

  @override
  State<_MomentPost> createState() => _MomentPostState();
}

class _MomentPostState extends State<_MomentPost> {
  final GlobalKey _actionKey = GlobalKey();
  final _aiApi = AiApi();
  bool _busy = false;
  String? _translation;
  bool _showTranslation = false;
  bool _translating = false;

  Map<String, dynamic> get m => widget.moment;

  Future<void> _toggleLike() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    if (ConnectivityService.instance.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            offlineNeedsNetworkMessage(AppLocalizations.of(context)),
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      final res = await widget.api.toggleMomentLike(
        accessToken: token,
        momentId: m['id'] as String,
      );
      final liked = res['liked'] == true;
      final me = widget.authController.user;
      final likes = momentMaps(m['likes']);
      if (liked && me != null) {
        likes.removeWhere((l) => l['userId'] == me.id);
        likes.add({'userId': me.id, 'name': me.name});
      } else if (me != null) {
        likes.removeWhere((l) => l['userId'] == me.id);
      }
      widget.onChanged({
        ...m,
        'likedByMe': liked,
        'likeCount': likes.length,
        'likes': likes,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _comment({Map<String, dynamic>? replyTo}) async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    if (ConnectivityService.instance.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            offlineNeedsNetworkMessage(AppLocalizations.of(context)),
          ),
        ),
      );
      return;
    }
    final l10n = AppLocalizations.of(context);
    final replyName = (replyTo?['authorName'] as String?)?.trim();
    final draft = await showMomentCommentComposer(
      context,
      replyToName: (replyName != null && replyName.isNotEmpty)
          ? replyName
          : null,
    );
    if (draft == null || !mounted) return;
    if (draft.body.isEmpty && draft.images.isEmpty) return;
    setState(() => _busy = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      List<Map<String, dynamic>> media = [];
      if (draft.images.isNotEmpty) {
        final uploaded = await widget.api.uploadFiles(
          accessToken: token,
          files: draft.images,
        );
        media = uploaded
            .where((u) => (u['kind'] as String?) == 'image')
            .map(
              (u) => {
                'kind': 'image',
                'url': u['url'],
                if (u['name'] != null) 'name': u['name'],
                if (u['mime'] != null) 'mime': u['mime'],
                if (u['size'] != null) 'size': u['size'],
              },
            )
            .toList();
      }
      final created = await widget.api.addMomentComment(
        accessToken: token,
        momentId: m['id'] as String,
        body: draft.body,
        replyToCommentId: replyTo?['id'] as String?,
        media: media.isEmpty ? null : media,
      );
      final comments = momentMaps(m['comments'])..add(created);
      widget.onChanged({...m, 'comments': comments});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.momentsCommentSendFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final l10n = AppLocalizations.of(context);
    final commentId = comment['id'] as String?;
    if (commentId == null || commentId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.momentsCommentDelete),
        content: Text(l10n.momentsCommentDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.authClose),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.momentsCommentDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (ConnectivityService.instance.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(offlineNeedsNetworkMessage(l10n))),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await widget.api.deleteMomentComment(
        accessToken: token,
        momentId: m['id'] as String,
        commentId: commentId,
      );
      final comments = momentMaps(m['comments'])
        ..removeWhere((c) => c['id'] == commentId);
      widget.onChanged({...m, 'comments': comments});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.momentsCommentDeleted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _favoriteMoment() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final l10n = AppLocalizations.of(context);
    final name = (m['authorName'] as String?) ?? l10n.momentsAnon;
    final body = (m['body'] as String?) ?? '';
    String? thumb;
    for (final item in widget.media) {
      final url = item['url'] as String?;
      if (url != null && url.isNotEmpty) {
        thumb = url;
        break;
      }
    }
    thumb ??= m['imageUrl'] as String?;
    await ChatFavoritesStore.instance.add(
      kind: 'moment',
      momentId: m['id'] as String?,
      name: name,
      body: body.isNotEmpty
          ? body
          : (widget.media.isNotEmpty ? '[Media]' : ''),
      pathOrUrl: thumb,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.momentsFavorited)),
    );
  }

  Future<void> _reportMoment() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final l10n = AppLocalizations.of(context);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await widget.api.reportContent(
        accessToken: token,
        targetType: 'moment',
        targetId: m['id'] as String,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.momentsReported)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _copyBody() async {
    final body = (m['body'] as String?)?.trim() ?? '';
    if (body.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: body));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).momentsTextCopied)),
    );
  }

  Future<void> _translateBody() async {
    final body = (m['body'] as String?)?.trim() ?? '';
    if (body.isEmpty || _translating) return;
    if (_translation != null && _translation!.isNotEmpty) {
      setState(() => _showTranslation = true);
      return;
    }
    if (ConnectivityService.instance.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            offlineNeedsNetworkMessage(AppLocalizations.of(context)),
          ),
        ),
      );
      return;
    }
    setState(() => _translating = true);
    final code = Localizations.localeOf(context).languageCode;
    final target = code == 'ar' || code == 'zh' ? code : 'en';
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null || !mounted) return;
      final res = await _aiApi.translate(
        accessToken: token,
        text: body,
        targetLocale: target,
        messageId: m['id'] as String?,
      );
      final t = (res['translation'] as String?)?.trim() ?? '';
      if (!mounted) return;
      if (t.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).msgTranslateFailed)),
        );
        return;
      }
      setState(() {
        _translation = t;
        _showTranslation = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).msgTranslateFailed)),
      );
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  Future<void> _showMediaActions() async {
    final l10n = AppLocalizations.of(context);
    final urls = widget.media
        .map((e) => e['url'] as String?)
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.download_rounded, color: ObicColors.isDark(ctx) ? const Color(0xFF8FA3D9) : _kWeChatName),
              title: Text(l10n.momentsDownload),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await saveImageToGallery(urls.first);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.momentsSaved)),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.momentsSaveFailed}: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded, color: _kWeChatName),
              title: Text(l10n.momentsCopyLink),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: urls.first));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.momentsCopied)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_border_rounded, color: _kWeChatName),
              title: Text(l10n.momentsFavorite),
              onTap: () {
                Navigator.pop(ctx);
                _favoriteMoment();
              },
            ),
            ListTile(
              title: Text(l10n.authClose, textAlign: TextAlign.center),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBodyActions() async {
    final l10n = AppLocalizations.of(context);
    final body = (m['body'] as String?)?.trim() ?? '';
    final meId = widget.authController.user?.id;
    final authorId = m['authorId'] as String?;
    final momentId = m['id'] as String? ?? '';
    final isMine = meId != null && meId == authorId;
    await MomentPinStore.instance.ensureLoaded();
    final pinned = MomentPinStore.instance.isPinned(momentId);
    final muted = !isMine && authorId != null
        ? await MomentsNotifyPrefs.isFriendMuted(authorId)
        : false;
    final hiddenFrom = !isMine && authorId != null
        ? (await MomentsNotifyPrefs.hiddenFromFriendIds()).contains(authorId)
        : false;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (body.isNotEmpty)
              ListTile(
                leading: Icon(
                  Icons.copy_rounded,
                  color: ObicColors.isDark(ctx)
                      ? const Color(0xFF8FA3D9)
                      : _kWeChatName,
                ),
                title: Text(l10n.momentsCopyText),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyBody();
                },
              ),
            if (body.isNotEmpty)
              ListTile(
                leading: Icon(
                  Icons.translate_rounded,
                  color: ObicColors.isDark(ctx)
                      ? const Color(0xFF8FA3D9)
                      : _kWeChatName,
                ),
                title: Text(l10n.momentsTranslate),
                onTap: () {
                  Navigator.pop(ctx);
                  _translateBody();
                },
              ),
            ListTile(
              leading: Icon(
                Icons.star_border_rounded,
                color: ObicColors.isDark(ctx)
                    ? const Color(0xFF8FA3D9)
                    : _kWeChatName,
              ),
              title: Text(l10n.momentsFavorite),
              onTap: () {
                Navigator.pop(ctx);
                _favoriteMoment();
              },
            ),
            if (isMine)
              ListTile(
                leading: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: ObicColors.isDark(ctx)
                      ? const Color(0xFF8FA3D9)
                      : _kWeChatName,
                ),
                title: Text(pinned ? l10n.momentsUnpin : l10n.momentsPin),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (pinned) {
                    await MomentPinStore.instance.unpin(momentId);
                  } else {
                    await MomentPinStore.instance.pin(momentId);
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        pinned
                            ? l10n.momentsUnpinnedToast
                            : l10n.momentsPinnedToast,
                      ),
                    ),
                  );
                },
              ),
            if (!isMine && authorId != null) ...[
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: Text(
                  muted ? l10n.momentsShowTheirs : l10n.momentsHideTheirs,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _setHideTheirs(authorId, hide: !muted);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(
                  hiddenFrom ? l10n.momentsShowMine : l10n.momentsHideMine,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _setHideMine(authorId, hide: !hiddenFrom);
                },
              ),
            ],
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  l10n.momentsDelete,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete();
                },
              ),
            ListTile(
              title: Text(l10n.authClose, textAlign: TextAlign.center),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setHideTheirs(String friendId, {required bool hide}) async {
    final l10n = AppLocalizations.of(context);
    final token = await widget.authController.ensureAccessToken();
    if (token == null || !mounted) return;
    try {
      if (hide) {
        await MomentsNotifyPrefs.muteFriend(
          accessToken: token,
          friendId: friendId,
        );
      } else {
        await MomentsNotifyPrefs.unmuteFriend(
          accessToken: token,
          friendId: friendId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.momentsPrefsSaved)),
      );
      await widget.onReload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _setHideMine(String friendId, {required bool hide}) async {
    final l10n = AppLocalizations.of(context);
    final token = await widget.authController.ensureAccessToken();
    if (token == null || !mounted) return;
    try {
      if (hide) {
        await MomentsNotifyPrefs.hideFromFriend(
          accessToken: token,
          friendId: friendId,
        );
      } else {
        await MomentsNotifyPrefs.unhideFromFriend(
          accessToken: token,
          friendId: friendId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.momentsPrefsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.momentsDelete),
        content: Text(l10n.momentsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.authClose),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.momentsDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _deleteMoment();
  }

  Future<void> _deleteMoment() async {
    final l10n = AppLocalizations.of(context);
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    if (ConnectivityService.instance.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(offlineNeedsNetworkMessage(l10n))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await widget.api.deleteMoment(
        accessToken: token,
        momentId: m['id'] as String,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.momentsDeleted)),
      );
      await widget.onReload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showActionBubble() async {
    final l10n = AppLocalizations.of(context);
    final box = _actionKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final liked = m['likedByMe'] == true;
    final meId = widget.authController.user?.id;
    final isMine = meId != null && meId == (m['authorId'] as String?);

    final choice = await showMenu<String>(
      context: context,
      color: const Color(0xFF4C4C4C),
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'like',
          child: Row(
            children: [
              Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                liked ? l10n.momentsUnlike : l10n.momentsLike,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'comment',
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.momentsComment,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'favorite',
          child: Row(
            children: [
              const Icon(Icons.star_border_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.momentsFavorite,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        if (isMine)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.momentsDelete,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                const Icon(Icons.flag_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.momentsReport,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
      ],
    );
    if (choice == 'like') await _toggleLike();
    if (choice == 'comment') await _comment();
    if (choice == 'favorite') await _favoriteMoment();
    if (choice == 'report') await _reportMoment();
    if (choice == 'delete') await _confirmDelete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = (m['authorName'] as String?) ?? l10n.momentsAnon;
    final authorId = m['authorId'] as String? ?? '';
    final meId = widget.authController.user?.id;
                          final role = m['authorRole'] as String?;
                          final notify = m['notifyAll'] == true;
    final body = (m['body'] as String?) ?? '';
    final avatar = m['authorAvatarUrl'] as String?;
    final isStaff = role == 'Employee' || role == 'SuperAdmin';
    final likes = momentMaps(m['likes']);
    final likeCount = momentInt(m['likeCount']);
    final comments = momentMaps(m['comments']);
    final liked = m['likedByMe'] == true;

                          return Container(
      color: widget.unseen
          ? (ObicColors.isDark(context)
              ? const Color(0xFF2A2224)
              : const Color(0xFFFFF8F8))
          : ObicColors.surfaceOf(context),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Column(
                              children: [
                                Row(
            crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
              // Unseen = WeChat-style bold name (+ faint row tint), not a
              // chat online/unread corner dot on the Moments avatar.
              GestureDetector(
                onTap: authorId.isEmpty
                    ? null
                    : () => widget.onOpenProfile(
                          userId: authorId,
                          name: name,
                          avatarUrl: avatar,
                        ),
                child: MomentAvatar(name: name, avatarUrl: avatar, size: 44),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                Row(
                                  children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: authorId.isEmpty
                                ? null
                                : () => widget.onOpenProfile(
                                      userId: authorId,
                                      name: name,
                                      avatarUrl: avatar,
                                    ),
                            child: Text(
                                            name,
                              style: TextStyle(
                                color: ObicColors.isDark(context)
                                    ? const Color(0xFF8FA3D9)
                                    : _kWeChatName,
                                fontWeight: widget.unseen
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        if (notify || isStaff) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: notify
                                  ? const Color(0xFFE8F8EF)
                                  : const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notify
                                  ? l10n.momentsOfficial
                                  : l10n.momentsStaff,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: notify ? _kWeChatGreen : _kWeChatName,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onLongPress: _busy ? null : _showBodyActions,
                        child: Text(
                          body,
                          style: TextStyle(
                            color: ObicColors.isDark(context)
                                ? ObicColors.darkInk
                                : const Color(0xFF191919),
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ),
                      if (_translating)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            '…',
                            style: TextStyle(color: _kWeChatName, fontSize: 13),
                          ),
                        )
                      else if (_showTranslation &&
                          _translation != null &&
                          _translation!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _translation!,
                                            style: const TextStyle(
                            color: Color(0xFF576B95),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showTranslation = false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(l10n.msgShowOriginal),
                        ),
                      ],
                    ],
                    if (widget.media.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onLongPress: _busy ? null : _showMediaActions,
                        child: _MediaBlock(media: widget.media),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                                        children: [
                                            Text(
                          widget.timeLabel,
                                              style: TextStyle(
                            color: ObicColors.isDark(context)
                                ? ObicColors.darkInk
                                : const Color(0xFFB2B2B2),
                                                fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: liked
                              ? l10n.momentsUnlike
                              : l10n.momentsLike,
                          onPressed: _busy ? null : _toggleLike,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 28,
                          ),
                          icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: ObicColors.isDark(context)
                                ? ObicColors.darkInk
                                : _kWeChatName,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.momentsComment,
                          onPressed: _busy ? null : () => _comment(),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 28,
                          ),
                          icon: Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: ObicColors.isDark(context)
                                ? ObicColors.darkInk
                                : _kWeChatName,
                          ),
                        ),
                        InkWell(
                          key: _actionKey,
                          onTap: _busy ? null : _showActionBubble,
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                              vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(
                              Icons.more_horiz,
                              size: 18,
                              color: _kWeChatName,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                    if (likes.isNotEmpty ||
                        comments.isNotEmpty ||
                        likeCount > 0) ...[
                      const SizedBox(height: 6),
                      MomentEngagementBox(
                        likes: likes,
                        likeCount: likeCount > likes.length
                            ? likeCount
                            : likes.length,
                        comments: comments,
                        emptyLikes: l10n.momentsNoLikes,
                        repliedToLabel: l10n.momentsRepliedTo,
                        viewerId: meId,
                        momentAuthorId: authorId,
                        onReply: (c) => _comment(replyTo: c),
                        onDeleteComment: (c) => _deleteComment(c),
                        onOpenProfile: widget.onOpenProfile,
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                                              ),
                                            ),
                                        ],
                                      ),
          Divider(height: 1, color: ObicColors.lineOf(context)),
        ],
      ),
    );
  }
}

class _MediaBlock extends StatelessWidget {
  const _MediaBlock({required this.media});

  final List<Map<String, dynamic>> media;

  @override
  Widget build(BuildContext context) {
    final images = media.where((m) => m['kind'] == 'image').toList();
    final videos = media.where((m) => m['kind'] == 'video').toList();
    final files = media.where((m) => m['kind'] == 'file').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) _ImageGrid(items: images),
        if (videos.isNotEmpty) ...[
          if (images.isNotEmpty) const SizedBox(height: 6),
          for (final v in videos) ...[
            _VideoTile(url: resolveMediaUrl(v['url'] as String?)),
            const SizedBox(height: 6),
          ],
        ],
        if (files.isNotEmpty) ...[
          for (final f in files)
            _FileChip(
              name: (f['name'] as String?) ?? 'file',
              url: resolveMediaUrl(f['url'] as String?),
            ),
        ],
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final count = items.length.clamp(1, 9);
    final cols = count == 1 ? 1 : (count == 4 ? 2 : 3);
    const gap = 4.0;

    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth;
        final cell = count == 1
            ? maxW * 0.72
            : (maxW - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < count; i++)
              GestureDetector(
                onTap: () {
                  final urls = items
                      .map((e) => resolveMediaUrl(e['url'] as String?))
                      .where((u) => u.isNotEmpty)
                      .toList();
                  openMomentPhotoViewer(
                    context,
                    urls: urls,
                    initialIndex: i,
                  );
                },
                child: SizedBox(
                  width: cell,
                  height: count == 1 ? cell * 1.15 : cell,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: ObicCachedImage(
                      resolveMediaUrl(items[i]['url'] as String?),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFE8E8E8),
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _VideoTile extends StatefulWidget {
  const _VideoTile({required this.url});

  final String url;

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.url.isEmpty) return;
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      }).catchError((_) {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.url.isEmpty) return;
        openMomentVideoViewer(context, url: widget.url);
      },
      child: AspectRatio(
        aspectRatio: _ready && _controller != null
            ? _controller!.value.aspectRatio
            : 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: _ready && _controller != null
                  ? VideoPlayer(_controller!)
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white70,
                size: 56,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.name, required this.url});

  final String name;
  final String url;

  Future<void> _download(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final path = await saveFileToDocuments(url, filename: name);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.momentsFileSaved}: $path')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.momentsSaveFailed}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _download(context),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, color: _kWeChatName, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF191919)),
              ),
            ),
            const Icon(
              Icons.download_outlined,
              size: 18,
              color: Color(0xFFB2B2B2),
            ),
          ],
                      ),
      ),
    );
  }
}
