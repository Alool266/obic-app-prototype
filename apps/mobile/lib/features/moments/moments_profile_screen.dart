// Made by Dr Ali
// Friend / own Moments album — cover, overlapping avatar, Pin row, date+media timeline.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/api_errors.dart';
import '../../core/connectivity_service.dart';
import '../../core/media_url.dart';
import '../../core/offline_cache_store.dart';
import '../../widgets/obic_cached_image.dart';
import '../../core/upload_filename.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/offline_banner.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../channels/channel_nav.dart';
import '../social/social_api.dart';
import 'moment_avatar.dart';
import 'moment_comment_composer.dart';
import 'moment_engagement.dart';
import 'moment_friend_picker.dart';
import 'moment_media_viewer.dart';
import 'moment_pin_store.dart';
import 'moments_cover_adjust_screen.dart';
import 'moments_notify_prefs.dart';
import 'moments_header_chrome.dart';

const _kWeChatGreen = Color(0xFF07C160);
const _kProfileAvatarSize = 68.0;
const _kProfileAvatarBorder = 2.0;
const _kProfileAvatarOuter = _kProfileAvatarSize + _kProfileAvatarBorder * 2;
const _kProfileAvatarHang = _kProfileAvatarOuter / 2;
String? _momentLocation(Map<String, dynamic> moment) {
  for (final key in const ['location', 'locationName', 'place', 'placeName']) {
    final value = moment[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

const _kMonthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class MomentsProfileScreen extends StatefulWidget {
  const MomentsProfileScreen({
    super.key,
    required this.authController,
    required this.userId,
    this.initialName,
    this.initialAvatarUrl,
  });

  final AuthController authController;
  final String userId;
  final String? initialName;
  final String? initialAvatarUrl;

  @override
  State<MomentsProfileScreen> createState() => _MomentsProfileScreenState();
}

class _MomentsProfileScreenState extends State<MomentsProfileScreen> {
  final _api = SocialApi();
  final _scroll = ScrollController();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _moments = [];
  String? _channelName;
  String? _channelThumb;
  bool _loading = true;
  bool _acting = false;
  String? _error;
  double _collapseT = 0;

  bool get _isMine => widget.authController.user?.id == widget.userId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    MomentPinStore.instance.addListener(_onPins);
    _load();
  }

  @override
  void dispose() {
    MomentPinStore.instance.removeListener(_onPins);
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scroll.hasClients) return;
    final next = momentsHeaderCollapseT(
      scrollOffset: _scroll.offset,
      topPadding: MediaQuery.paddingOf(context).top,
      expandedHeight: kMomentsProfileCoverExpandedHeight,
    );
    if ((next - _collapseT).abs() < 0.015) return;
    setState(() => _collapseT = next);
  }

  void _onPins() {
    if (mounted) setState(() {});
  }

  String get _albumKey => 'album_${widget.userId}';

  Future<void> _showCachedAlbum() async {
    final cached = await OfflineCacheStore.instance.loadMoments(_albumKey);
    final profile = await OfflineCacheStore.instance.loadAlbumProfile(
      widget.userId,
    );
    if (!mounted) return;
    if ((cached == null || cached.isEmpty) && profile == null) return;
    await MomentPinStore.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      if (profile != null) _profile = profile;
      if (cached != null && cached.isNotEmpty) _moments = cached;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _load() async {
    if (_moments.isEmpty && _profile == null) {
      await _showCachedAlbum();
    }
    if (_moments.isEmpty && _profile == null && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final token = await widget.authController.accessToken();
      final profile = await _api.getMomentsProfile(
        userId: widget.userId,
        accessToken: token,
      );
      final rows = await _api.listMomentsForUser(
        userId: widget.userId,
        accessToken: token,
      );
      await MomentPinStore.instance.ensureLoaded();
      await OfflineCacheStore.instance.saveMoments(_albumKey, rows);
      await OfflineCacheStore.instance.saveAlbumProfile(widget.userId, profile);
      final channel = await _lookupChannel(token);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _moments = rows;
        _channelName = channel?.name;
        _channelThumb = channel?.thumbUrl;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (_moments.isNotEmpty || _profile != null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = null;
          });
        }
        return;
      }
      await _showCachedAlbum();
      if (!mounted) return;
      if (_moments.isNotEmpty || _profile != null) return;
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

  Future<ObicPersonalChannel?> _lookupChannel(String? token) async {
    try {
      return await lookupPersonalChannel(
        api: _api,
        userId: widget.userId,
        accessToken: token,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _openChannel() async {
    await openUserChannel(
      context,
      widget.authController,
      userId: widget.userId,
    );
  }

  Widget _channelRow(AppLocalizations l10n, Color surface) {
    final name = _channelName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    final thumb = _channelThumb;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final ink = ObicColors.inkOf(context);
    final muted = ObicColors.mutedOf(context);
    return Material(
      color: surface,
      child: InkWell(
        onTap: _openChannel,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
          child: Row(
            children: [
              Text(
                l10n.channelTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 15, color: ink),
                ),
              ),
              if (thumb != null && thumb.isNotEmpty) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: ObicCachedImage(
                    resolveMediaUrl(thumb),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              Icon(
                rtl ? Icons.chevron_left : Icons.chevron_right,
                color: muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _mediaOf(Map<String, dynamic> moment) {
    final raw = moment['media'];
    final media = raw is List
        ? raw.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    if (media.isEmpty) {
      final imageUrl = moment['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        media.add({'kind': 'image', 'url': imageUrl, 'name': 'photo.jpg'});
      }
    }
    return media;
  }

  void _replaceMoment(String id, Map<String, dynamic> next) {
    final i = _moments.indexWhere((m) => m['id'] == id);
    if (i < 0) return;
    setState(() => _moments[i] = next);
    unawaited(OfflineCacheStore.instance.saveMoments(_albumKey, _moments));
  }

  void _openLikersProfile({
    required String userId,
    String? name,
    String? avatarUrl,
  }) {
    if (userId.isEmpty || userId == widget.userId) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MomentsProfileScreen(
          authController: widget.authController,
          userId: userId,
          initialName: name,
          initialAvatarUrl: avatarUrl,
        ),
      ),
    );
  }

  Future<void> _toggleLike(Map<String, dynamic> moment) async {
    if (_acting) return;
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final l10n = AppLocalizations.of(context);
    if (ConnectivityService.instance.isOffline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(offlineNeedsNetworkMessage(l10n))));
      return;
    }
    final id = moment['id'] as String?;
    if (id == null || id.isEmpty) return;
    setState(() => _acting = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || !mounted) return;
      final res = await _api.toggleMomentLike(accessToken: token, momentId: id);
      if (!mounted) return;
      final liked = res['liked'] == true;
      final me = widget.authController.user;
      final likes = momentMaps(moment['likes']);
      if (liked && me != null) {
        likes.removeWhere((l) => l['userId'] == me.id);
        likes.add({'userId': me.id, 'name': me.name});
      } else if (me != null) {
        likes.removeWhere((l) => l['userId'] == me.id);
      }
      _replaceMoment(id, {
        ...moment,
        'likedByMe': liked,
        'likeCount': likes.length,
        'likes': likes,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _comment(
    Map<String, dynamic> moment, {
    Map<String, dynamic>? replyTo,
  }) async {
    if (_acting) return;
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final l10n = AppLocalizations.of(context);
    if (ConnectivityService.instance.isOffline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(offlineNeedsNetworkMessage(l10n))));
      return;
    }
    final id = moment['id'] as String?;
    if (id == null || id.isEmpty) return;
    final replyName = (replyTo?['authorName'] as String?)?.trim();
    final draft = await showMomentCommentComposer(
      context,
      replyToName: (replyName != null && replyName.isNotEmpty)
          ? replyName
          : null,
    );
    if (draft == null || !mounted) return;
    if (draft.body.isEmpty && draft.images.isEmpty) return;
    setState(() => _acting = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      List<Map<String, dynamic>> media = [];
      if (draft.images.isNotEmpty) {
        final uploaded = await _api.uploadFiles(
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
      final created = await _api.addMomentComment(
        accessToken: token,
        momentId: id,
        body: draft.body,
        replyToCommentId: replyTo?['id'] as String?,
        media: media.isEmpty ? null : media,
      );
      if (!mounted) return;
      final comments = momentMaps(moment['comments'])..add(created);
      _replaceMoment(id, {...moment, 'comments': comments});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.momentsCommentSendFailed)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _deleteComment(
    Map<String, dynamic> moment,
    Map<String, dynamic> comment,
  ) async {
    if (_acting) return;
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final l10n = AppLocalizations.of(context);
    final momentId = moment['id'] as String?;
    final commentId = comment['id'] as String?;
    if (momentId == null ||
        momentId.isEmpty ||
        commentId == null ||
        commentId.isEmpty) {
      return;
    }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(offlineNeedsNetworkMessage(l10n))));
      return;
    }
    setState(() => _acting = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await _api.deleteMomentComment(
        accessToken: token,
        momentId: momentId,
        commentId: commentId,
      );
      if (!mounted) return;
      final comments = momentMaps(moment['comments'])
        ..removeWhere((c) => c['id'] == commentId);
      _replaceMoment(momentId, {...moment, 'comments': comments});
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.momentsCommentDeleted)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  List<Map<String, dynamic>> get _pinCandidates =>
      MomentPinStore.instance.pinnedFrom(_moments);

  Future<void> _onAlbumLongPress(Map<String, dynamic> moment) async {
    final l10n = AppLocalizations.of(context);
    final id = moment['id'] as String? ?? '';
    final authorId = moment['authorId'] as String?;
    final isMine = _isMine;
    await MomentPinStore.instance.ensureLoaded();
    final pinned = MomentPinStore.instance.isPinned(id);
    final muted = !isMine && authorId != null
        ? await MomentsNotifyPrefs.isFriendMuted(authorId)
        : false;
    final hidden = !isMine && authorId != null
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
            if (isMine)
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: Text(pinned ? l10n.momentsUnpin : l10n.momentsPin),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (pinned) {
                    await MomentPinStore.instance.unpin(id);
                  } else {
                    await MomentPinStore.instance.pin(id);
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
            if (isMine)
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: Text(l10n.friendsHideMyMoments),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _openPrivacyPicker(hideMine: true);
                },
              ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.do_not_disturb_on_outlined),
                title: Text(l10n.friendsMuteMoments),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _openPrivacyPicker(hideMine: false);
                },
              ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  l10n.momentsDelete,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _deleteAlbumMoment(id);
                },
              ),
            if (!isMine && authorId != null) ...[
              ListTile(
                title: Text(
                  muted ? l10n.momentsShowTheirs : l10n.momentsHideTheirs,
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _toggleFriendMoments(authorId, mute: !muted);
                },
              ),
              ListTile(
                title: Text(
                  hidden ? l10n.momentsShowMine : l10n.momentsHideMine,
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _toggleHideMine(authorId, hide: !hidden);
                },
              ),
            ],
            ListTile(
              title: Text(l10n.authClose, textAlign: TextAlign.center),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAlbumMoment(String id) async {
    if (id.isEmpty) return;
    final token = await widget.authController.accessToken();
    if (token == null) return;
    try {
      await _api.deleteMoment(accessToken: token, momentId: id);
      await MomentPinStore.instance.unpin(id);
      if (mounted) await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openPrivacyPicker({required bool hideMine}) async {
    final l10n = AppLocalizations.of(context);
    final ids = hideMine
        ? await MomentsNotifyPrefs.hiddenFromFriendIds()
        : await MomentsNotifyPrefs.mutedFriendIds();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MomentFriendPickerScreen(
          authController: widget.authController,
          title: hideMine ? l10n.friendsHideMyMoments : l10n.friendsMuteMoments,
          selectedIds: ids.toSet(),
          onToggle: (friendId, next) => hideMine
              ? _toggleHideMine(friendId, hide: next)
              : _toggleFriendMoments(friendId, mute: next),
        ),
      ),
    );
  }

  Future<bool> _toggleFriendMoments(
    String friendId, {
    required bool mute,
  }) async {
    final token = await widget.authController.accessToken();
    if (token == null) return false;
    try {
      if (mute) {
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
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      return false;
    }
  }

  Future<bool> _toggleHideMine(String friendId, {required bool hide}) async {
    final token = await widget.authController.accessToken();
    if (token == null) return false;
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
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      return false;
    }
  }

  Future<void> _changeCover() async {
    if (!_isMine) return;
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final shot = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (shot == null || !mounted) return;

    final focusY =
        (_profile?['momentsCoverFocusY'] as num?)?.toDouble() ??
        widget.authController.user?.momentsCoverFocusY ??
        0.0;
    final adjusted = await Navigator.of(context).push<MomentsCoverAdjustResult>(
      MaterialPageRoute(
        builder: (_) => MomentsCoverAdjustScreen(
          imagePath: shot.path,
          initialFocusY: focusY,
        ),
      ),
    );
    if (adjusted == null || !mounted) return;

    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw AuthApiException('Not signed in');
      final items = await _api.uploadFiles(
        accessToken: token,
        files: [
          (
            path: adjusted.imagePath,
            filename: uploadFilenameForImage(XFile(adjusted.imagePath)),
          ),
        ],
      );
      if (items.isEmpty) throw AuthApiException('Upload failed');
      final url = items.first['url'] as String?;
      if (url == null || url.isEmpty) throw AuthApiException('Upload failed');
      final updated = await AuthApi().updateMomentsCover(
        accessToken: token,
        coverUrl: url,
        focusY: adjusted.focusY,
      );
      await widget.authController.applyUser(updated);
      if (!mounted) return;
      setState(() {
        _profile = {
          ...?_profile,
          'momentsCoverUrl': updated.momentsCoverUrl,
          'momentsCoverFocusY': updated.momentsCoverFocusY,
        };
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorMomentsCoverFailed)));
    }
  }

  void _openMedia(Map<String, dynamic> moment, {int initialIndex = 0}) {
    final media = _mediaOf(moment);
    if (media.isEmpty) return;
    final first = media[initialIndex.clamp(0, media.length - 1)];
    final kind = first['kind'] as String? ?? 'image';
    final url = first['url'] as String?;
    if (url == null || url.isEmpty) return;
    if (kind == 'video') {
      openMomentVideoViewer(context, url: resolveMediaUrl(url));
      return;
    }
    final imageUrls = media
        .where((m) => (m['kind'] as String? ?? 'image') != 'video')
        .map((m) => resolveMediaUrl(m['url'] as String? ?? ''))
        .where((u) => u.isNotEmpty)
        .toList();
    if (imageUrls.isEmpty) return;
    final imageIndex = media
        .take(initialIndex + 1)
        .where((m) => (m['kind'] as String? ?? 'image') != 'video')
        .length;
    openMomentPhotoViewer(
      context,
      urls: imageUrls,
      initialIndex: (imageIndex - 1).clamp(0, imageUrls.length - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = ObicColors.isDark(context);
    final name =
        (_profile?['name'] as String?) ??
        widget.initialName ??
        l10n.momentsAnon;
    final avatar =
        (_profile?['avatarUrl'] as String?) ?? widget.initialAvatarUrl;
    final whatsUp =
        (_profile?['whatsUp'] as String?)?.trim() ??
        (_isMine ? (widget.authController.user?.whatsUp?.trim() ?? '') : '');
    final coverUrl = _profile?['momentsCoverUrl'] as String?;
    final focusY = (_profile?['momentsCoverFocusY'] as num?)?.toDouble() ?? 0.0;
    final meCover = widget.authController.user?.momentsCoverUrl;
    final displayCover = _isMine && (coverUrl == null || coverUrl.isEmpty)
        ? meCover
        : coverUrl;
    final displayFocus = _isMine
        ? (widget.authController.user?.momentsCoverFocusY ?? focusY)
        : focusY;

    final t = _collapseT;
    final barBg = momentsHeaderBarColor(context, t);
    final fg = momentsHeaderFgColor(context, t);
    final titleOpacity = Curves.easeOut.transform(
      ((t - 0.35) / 0.45).clamp(0.0, 1.0),
    );
    final pins = _pinCandidates;
    final surface = dark ? ObicColors.darkCanvas : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: momentsHeaderSystemUi(context, t),
      child: Scaffold(
        backgroundColor: surface,
        body: RefreshIndicator(
          color: _kWeChatGreen,
          onRefresh: _load,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: kMomentsProfileCoverExpandedHeight,
                backgroundColor: barBg,
                foregroundColor: fg,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                iconTheme: IconThemeData(color: fg),
                actionsIconTheme: IconThemeData(color: fg),
                title: Opacity(
                  opacity: titleOpacity,
                  child: Text(
                    _isMine
                        ? l10n.momentsMyAlbum
                        : l10n.momentsFriendAlbum(name),
                    style: TextStyle(
                      color: fg,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                GestureDetector(
                                  onTap: _isMine ? _changeCover : null,
                                  child:
                                      displayCover != null &&
                                          displayCover.isNotEmpty
                                      ? ObicCachedImage(
                                          resolveMediaUrl(displayCover),
                                          fit: BoxFit.cover,
                                          alignment: Alignment(0, displayFocus),
                                        )
                                      : const DecoratedBox(
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
                                momentsCoverBottomFade(height: 64),
                              ],
                            ),
                          ),
                          ColoredBox(
                            color: surface,
                            child: const SizedBox(height: _kProfileAvatarHang),
                          ),
                        ],
                      ),
                      Positioned(
                        left: 16,
                        right: 16 + _kProfileAvatarOuter + 8,
                        bottom: _kProfileAvatarHang + 6,
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: surface,
                              width: _kProfileAvatarBorder,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              final raw = avatar;
                              if (raw == null || raw.isEmpty) return;
                              final url = resolveMediaUrl(raw);
                              if (url.isEmpty) return;
                              openMomentPhotoViewer(
                                context,
                                urls: [url],
                                initialIndex: 0,
                              );
                            },
                            child: MomentAvatar(
                              name: name,
                              avatarUrl: avatar,
                              size: _kProfileAvatarSize,
                              borderRadius: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (whatsUp.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    color: surface,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    alignment: AlignmentDirectional.centerEnd,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Text(
                        whatsUp,
                        textAlign: TextAlign.end,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: ObicColors.inkOf(context),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_channelName != null)
                SliverToBoxAdapter(child: _channelRow(l10n, surface)),
              if (pins.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    color: surface,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 56,
                              child: Text(
                                l10n.momentsPin,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: ObicColors.inkOf(context),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final m in pins)
                                    _PinThumb(
                                      moment: m,
                                      media: _mediaOf(m),
                                      onTap: () => _openMedia(m),
                                      onLongPress: () => _onAlbumLongPress(m),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: ObicColors.lineOf(context)),
                      ],
                    ),
                  ),
                ),
              if (_loading && _moments.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _moments.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  ),
                )
              else if (_moments.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      16,
                      16,
                      24,
                    ),
                    child: Text(
                      _isMine
                          ? l10n.contactMomentsNoneSelf
                          : l10n.contactMomentsNone(name),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: ObicColors.mutedOf(context),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final m = _moments[index];
                      final prev = index > 0 ? _moments[index - 1] : null;
                      return _AlbumTimelineRow(
                        moment: m,
                        previous: prev,
                        media: _mediaOf(m),
                        onOpenMedia: (i) => _openMedia(m, initialIndex: i),
                        onLongPress: () => _onAlbumLongPress(m),
                        likes: momentMaps(m['likes']),
                        likeCount: momentInt(m['likeCount']),
                        comments: momentMaps(m['comments']),
                        liked: m['likedByMe'] == true,
                        emptyLikes: l10n.momentsNoLikes,
                        repliedToLabel: l10n.momentsRepliedTo,
                        likeLabel: m['likedByMe'] == true
                            ? l10n.momentsUnlike
                            : l10n.momentsLike,
                        commentLabel: l10n.momentsComment,
                        viewerId: widget.authController.user?.id,
                        onLike: _acting ? null : () => _toggleLike(m),
                        onComment: _acting ? null : () => _comment(m),
                        onReply: (c) => _comment(m, replyTo: c),
                        onDeleteComment: (c) => _deleteComment(m, c),
                        onOpenProfile: _openLikersProfile,
                      );
                    }, childCount: _moments.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinThumb extends StatelessWidget {
  const _PinThumb({
    required this.moment,
    required this.media,
    required this.onTap,
    this.onLongPress,
  });

  final Map<String, dynamic> moment;
  final List<Map<String, dynamic>> media;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final dark = ObicColors.isDark(context);
    final first = media.isNotEmpty ? media.first : null;
    final url = first?['url'] as String?;
    final kind = first?['kind'] as String? ?? 'image';
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url != null && url.isNotEmpty)
                ObicCachedImage(
                  resolveMediaUrl(url),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: dark
                        ? ObicColors.darkSurfaceRaised
                        : const Color(0xFFEDEDED),
                  ),
                )
              else
                ColoredBox(
                  color: dark
                      ? ObicColors.darkSurfaceRaised
                      : const Color(0xFFEDEDED),
                  child: const Icon(Icons.photo_outlined, size: 28),
                ),
              if (kind == 'video')
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumTimelineRow extends StatelessWidget {
  const _AlbumTimelineRow({
    required this.moment,
    required this.previous,
    required this.media,
    required this.onOpenMedia,
    required this.likes,
    required this.likeCount,
    required this.comments,
    required this.liked,
    required this.emptyLikes,
    required this.repliedToLabel,
    required this.likeLabel,
    required this.commentLabel,
    required this.onReply,
    required this.onDeleteComment,
    required this.onOpenProfile,
    this.onLongPress,
    this.onLike,
    this.onComment,
    this.viewerId,
  });

  final Map<String, dynamic> moment;
  final Map<String, dynamic>? previous;
  final List<Map<String, dynamic>> media;
  final void Function(int index) onOpenMedia;
  final VoidCallback? onLongPress;
  final List<Map<String, dynamic>> likes;
  final int likeCount;
  final List<Map<String, dynamic>> comments;
  final bool liked;
  final String emptyLikes;
  final String repliedToLabel;
  final String likeLabel;
  final String commentLabel;
  final String? viewerId;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final void Function(Map<String, dynamic> comment) onReply;
  final void Function(Map<String, dynamic> comment) onDeleteComment;
  final void Function({required String userId, String? name, String? avatarUrl})
  onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final dark = ObicColors.isDark(context);
    final body = (moment['body'] as String?) ?? '';
    final created = moment['createdAt'] as String?;
    final dt = created != null ? DateTime.tryParse(created)?.toLocal() : null;
    final prevCreated = previous?['createdAt'] as String?;
    final prevDt = prevCreated != null
        ? DateTime.tryParse(prevCreated)?.toLocal()
        : null;
    final sameDay =
        dt != null &&
        prevDt != null &&
        dt.year == prevDt.year &&
        dt.month == prevDt.month &&
        dt.day == prevDt.day;

    final month = dt == null ? '' : _kMonthNames[dt.month - 1];
    final day = dt == null ? '' : '${dt.day}';
    final location = _momentLocation(moment);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: sameDay
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: rtl
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          month,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ObicColors.mutedOf(context),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          day,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: ObicColors.inkOf(context),
                            height: 1.05,
                          ),
                        ),
                        if (location != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            location,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              color: ObicColors.mutedOf(context),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        body,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: dark
                              ? ObicColors.darkInk
                              : const Color(0xFF191919),
                        ),
                      ),
                    ),
                  if (media.isNotEmpty)
                    _MediaGrid(media: media, onOpen: onOpenMedia),
                  if (body.isEmpty && media.isEmpty)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: dark
                            ? ObicColors.darkSurfaceRaised
                            : const Color(0xFFEDEDED),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        color: ObicColors.mutedOf(context),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _AlbumTextAction(
                        icon: liked ? Icons.favorite : Icons.favorite_border,
                        label: likeLabel,
                        onTap: onLike,
                      ),
                      const SizedBox(width: 8),
                      _AlbumTextAction(
                        icon: Icons.chat_bubble_outline,
                        label: commentLabel,
                        onTap: onComment,
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
                      emptyLikes: emptyLikes,
                      repliedToLabel: repliedToLabel,
                      viewerId: viewerId,
                      momentAuthorId: moment['authorId'] as String? ?? '',
                      onReply: onReply,
                      onDeleteComment: onDeleteComment,
                      onOpenProfile: onOpenProfile,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumTextAction extends StatelessWidget {
  const _AlbumTextAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = ObicColors.isDark(context)
        ? ObicColors.darkInk
        : const Color(0xFF576B95);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.media, required this.onOpen});

  final List<Map<String, dynamic>> media;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final dark = ObicColors.isDark(context);
    final n = media.length;
    if (n == 1) {
      return _thumb(context, 0, 120, 120, dark);
    }
    final size = n <= 4 ? 88.0 : 72.0;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < n && i < 9; i++)
          _thumb(context, i, size, size, dark),
      ],
    );
  }

  Widget _thumb(
    BuildContext context,
    int index,
    double w,
    double h,
    bool dark,
  ) {
    final item = media[index];
    final url = item['url'] as String?;
    final kind = item['kind'] as String? ?? 'image';
    return GestureDetector(
      onTap: () => onOpen(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url != null && url.isNotEmpty)
                ObicCachedImage(
                  resolveMediaUrl(url),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: dark
                        ? ObicColors.darkSurfaceRaised
                        : const Color(0xFFEDEDED),
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                )
              else
                ColoredBox(
                  color: dark
                      ? ObicColors.darkSurfaceRaised
                      : const Color(0xFFEDEDED),
                ),
              if (kind == 'video')
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
