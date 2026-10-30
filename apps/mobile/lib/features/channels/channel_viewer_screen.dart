// Made by Dr Ali
// WeChat Channels viewer — Follow / Nearby / Friends / Hot + vertical shorts.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

import '../../core/api_errors.dart';
import '../../core/badge_store.dart';
import '../../core/media_url.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../hub_chrome/hub_gps.dart';
import '../moments/moment_avatar.dart';
import '../moments/moment_compose_screen.dart';
import '../social/social_api.dart';

enum ChannelFeedTab { follow, nearby, friends, hot }

extension on ChannelFeedTab {
  String get api => name;
}

class ChannelViewerScreen extends StatefulWidget {
  const ChannelViewerScreen({
    super.key,
    required this.authController,
    this.initialTab = ChannelFeedTab.hot,
    this.openMyChannelOnStart = false,
  });

  final AuthController authController;
  final ChannelFeedTab initialTab;
  final bool openMyChannelOnStart;

  @override
  State<ChannelViewerScreen> createState() => _ChannelViewerScreenState();
}

class _ChannelViewerScreenState extends State<ChannelViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = ChannelFeedTab.values;
  final _api = SocialApi();
  late final TabController _tabCtrl;
  final Map<ChannelFeedTab, List<Map<String, dynamic>>> _feeds = {};
  final Map<ChannelFeedTab, bool> _loading = {};
  String? _error;
  bool _canPostOfficial = false;
  bool _canPostMine = false;
  String? _myChannelSlug;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _tabs.indexOf(widget.initialTab),
    );
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        unawaited(_ensureTab(_tabs[_tabCtrl.index]));
      }
    });
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _ensureTab(_tabs[_tabCtrl.index]);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      final discover = await _api.getChannelsDiscover(accessToken: token);
      final mine = await _api.getMyChannel(token);
      if (!mounted) return;
      setState(() {
        _canPostOfficial = discover['canPostOfficial'] == true;
        _canPostMine = mine['canPost'] == true;
        _myChannelSlug = mine['slug'] as String?;
      });
      // Opening the viewer counts as watching — clear Discover Channels tip.
      final channels = discover['channels'] as Map<String, dynamic>?;
      await writeLastSeenChannelsAt(
        newestChannelPreviewTime([
          channels?['officialPreview'] as Map<String, dynamic>?,
          channels?['friendsPreview'] as Map<String, dynamic>?,
        ]),
      );
      if (widget.openMyChannelOnStart) {
        // Stay on friends/hot — upload fab handles mine.
      }
    } catch (_) {}
  }

  Future<void> _ensureTab(ChannelFeedTab tab, {bool force = false}) async {
    if (!force && _feeds.containsKey(tab) && !(_loading[tab] ?? false)) {
      return;
    }
    setState(() {
      _loading[tab] = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      String? city;
      double? lat;
      double? lng;
      if (tab == ChannelFeedTab.nearby) {
        final gps = await readHubGps(forcePrompt: false);
        if (gps != null) {
          city = gps.city;
          lat = gps.lat;
          lng = gps.lng;
        }
      }
      final rows = await _api.listChannelFeed(
        tab: tab.api,
        accessToken: token,
        city: city,
        lat: lat,
        lng: lng,
      );
      if (!mounted) return;
      setState(() {
        _feeds[tab] = rows;
        _loading[tab] = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final lang = Localizations.localeOf(context).languageCode;
      setState(() {
        _loading[tab] = false;
        _error = friendlyApiError(
          classifyTransportError(e),
          l10n: l10n,
          langCode: lang,
        );
      });
    }
  }

  Future<void> _upload() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final l10n = AppLocalizations.of(context);

    String? targetSlug;
    if (_canPostOfficial && _canPostMine) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: Text(l10n.channelOfficialShort),
                onTap: () => Navigator.pop(ctx, 'obic'),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.channelMyChannel),
                onTap: () => Navigator.pop(ctx, _myChannelSlug ?? 'me'),
              ),
            ],
          ),
        ),
      );
      targetSlug = choice;
    } else if (_canPostOfficial) {
      targetSlug = 'obic';
    } else if (_canPostMine) {
      targetSlug = _myChannelSlug;
      if (targetSlug == null) {
        final mine = await _api.getMyChannel(
          (await widget.authController.accessToken())!,
        );
        targetSlug = mine['slug'] as String?;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.channelPostDenied)),
      );
      return;
    }
    if (targetSlug == null || !mounted) return;

    final shot = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (shot == null || !mounted) return;
    final file = File(shot.path);
    final bytes = await file.length();
    if (bytes > 40 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.channelVideoTooLarge)),
      );
      return;
    }

    final captionCtrl = TextEditingController();
    final caption = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.channelUploadTitle),
        content: TextField(
          controller: captionCtrl,
          maxLength: 500,
          maxLines: 3,
          decoration: InputDecoration(hintText: l10n.channelCaptionHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.chatHandoffCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, captionCtrl.text.trim()),
            child: Text(l10n.channelUpload),
          ),
        ],
      ),
    );
    captionCtrl.dispose();
    if (caption == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw Exception('Not signed in');
      final items = await _api.uploadFiles(
        accessToken: token,
        files: [(path: shot.path, filename: p.basename(shot.path))],
      );
      final url = items.first['url'] as String?;
      if (url == null || url.isEmpty) throw Exception('Upload failed');

      int? durationSec;
      try {
        final ctrl = VideoPlayerController.file(file);
        await ctrl.initialize();
        durationSec = ctrl.value.duration.inSeconds.clamp(1, 60);
        await ctrl.dispose();
      } catch (_) {}

      final slug = targetSlug == 'me' ? (_myChannelSlug ?? 'me') : targetSlug;
      if (slug == 'obic') {
        await _api.createObicChannelVideo(
          accessToken: token,
          videoUrl: url,
          caption: caption,
          durationSec: durationSec,
          byteSize: bytes,
        );
      } else {
        await _api.createChannelVideo(
          accessToken: token,
          idOrSlug: slug,
          videoUrl: url,
          caption: caption,
          durationSec: durationSec,
          byteSize: bytes,
        );
      }
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      await _ensureTab(_tabs[_tabCtrl.index], force: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.channelUploadDone)),
      );
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;
      final lang = Localizations.localeOf(context).languageCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyApiError(
              classifyTransportError(e),
              l10n: l10n,
              langCode: lang,
            ),
          ),
        ),
      );
    }
  }

  String _tabLabel(AppLocalizations l10n, ChannelFeedTab t) {
    switch (t) {
      case ChannelFeedTab.follow:
        return l10n.channelTabFollow;
      case ChannelFeedTab.nearby:
        return l10n.channelTabNearby;
      case ChannelFeedTab.friends:
        return l10n.channelTabFriends;
      case ChannelFeedTab.hot:
        return l10n.channelTabHot;
    }
  }

  /// Keep like/share counts in sync across tabs when user engages.
  void _patchVideoInFeeds(String videoId, Map<String, dynamic> patch) {
    var changed = false;
    for (final list in _feeds.values) {
      for (final v in list) {
        if (v['id'] == videoId) {
          v.addAll(patch);
          changed = true;
        }
      }
    }
    if (changed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showUpload = _canPostOfficial || _canPostMine;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: TabBar(
                        controller: _tabCtrl,
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        indicatorColor: Colors.white,
                        indicatorWeight: 2.5,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: [
                          for (final t in _tabs) Tab(text: _tabLabel(l10n, t)),
                        ],
                      ),
                    ),
                    if (showUpload)
                      IconButton(
                        tooltip: l10n.channelUpload,
                        onPressed: () => unawaited(_upload()),
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    for (final t in _tabs)
                      _FeedPage(
                        authController: widget.authController,
                        videos: _feeds[t] ?? const [],
                        loading: _loading[t] == true && !_feeds.containsKey(t),
                        error: _error,
                        onRefresh: () => _ensureTab(t, force: true),
                        emptyLabel: l10n.channelEmpty,
                        onVideoPatch: _patchVideoInFeeds,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedPage extends StatelessWidget {
  const _FeedPage({
    required this.authController,
    required this.videos,
    required this.loading,
    required this.onRefresh,
    required this.emptyLabel,
    required this.onVideoPatch,
    this.error,
  });

  final AuthController authController;
  final List<Map<String, dynamic>> videos;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final String emptyLabel;
  final void Function(String videoId, Map<String, dynamic> patch) onVideoPatch;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (error != null && videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    if (videos.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.35),
            Text(
              emptyLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        itemBuilder: (context, i) {
          final video = videos[i];
          final id = video['id'] as String? ?? '$i';
          return _VerticalVideoPage(
            key: ValueKey<String>(id),
            authController: authController,
            video: video,
            onVideoPatch: onVideoPatch,
          );
        },
      ),
    );
  }
}

class _VerticalVideoPage extends StatefulWidget {
  const _VerticalVideoPage({
    super.key,
    required this.authController,
    required this.video,
    required this.onVideoPatch,
  });

  final AuthController authController;
  final Map<String, dynamic> video;
  final void Function(String videoId, Map<String, dynamic> patch) onVideoPatch;

  @override
  State<_VerticalVideoPage> createState() => _VerticalVideoPageState();
}

class _VerticalVideoPageState extends State<_VerticalVideoPage> {
  final _api = SocialApi();
  VideoPlayerController? _ctrl;
  bool _ready = false;
  late int _likes;
  late int _comments;
  late int _shares;
  late bool _liked;
  bool _busy = false;

  static int _asInt(Object? raw, [int fallback = 0]) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? fallback;
    return fallback;
  }

  static bool _asBool(Object? raw) {
    if (raw == true) return true;
    if (raw == false || raw == null) return false;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final s = raw.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  void _hydrateFromVideo(Map<String, dynamic> video) {
    _likes = _asInt(video['likeCount']);
    _comments = _asInt(video['commentCount']);
    _shares = _asInt(video['shareCount']);
    _liked = _asBool(video['likedByMe']);
  }

  @override
  void initState() {
    super.initState();
    _hydrateFromVideo(widget.video);
    final url = widget.video['videoUrl'] as String?;
    if (url != null && url.isNotEmpty) {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(resolveMediaUrl(url)))
        ..setLooping(true)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          _ctrl?.play();
        });
    }
  }

  @override
  void didUpdateWidget(covariant _VerticalVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.video['id'];
    final nextId = widget.video['id'];
    if (oldId != nextId) {
      // PageView recycled this State onto another video — full rehydrate.
      _ctrl?.dispose();
      _ctrl = null;
      _ready = false;
      _hydrateFromVideo(widget.video);
      final url = widget.video['videoUrl'] as String?;
      if (url != null && url.isNotEmpty) {
        _ctrl = VideoPlayerController.networkUrl(Uri.parse(resolveMediaUrl(url)))
          ..setLooping(true)
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() => _ready = true);
            _ctrl?.play();
          });
      }
      setState(() {});
      return;
    }
    // Parent feed patched likedByMe / counts — stay in sync with server map.
    final nextLiked = _asBool(widget.video['likedByMe']);
    final nextLikes = _asInt(widget.video['likeCount'], _likes);
    final nextShares = _asInt(widget.video['shareCount'], _shares);
    final nextComments = _asInt(widget.video['commentCount'], _comments);
    if (nextLiked != _liked ||
        nextLikes != _likes ||
        nextShares != _shares ||
        nextComments != _comments) {
      setState(() {
        _liked = nextLiked;
        _likes = nextLikes;
        _shares = nextShares;
        _comments = nextComments;
      });
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok || _busy) return;
    final videoId = widget.video['id'] as String;
    final prevLiked = _liked;
    final prevLikes = _likes;
    // Optimistic — revert on failure.
    setState(() {
      _busy = true;
      _liked = !_liked;
      _likes = (_likes + (_liked ? 1 : -1)).clamp(0, 1 << 30);
    });
    widget.onVideoPatch(videoId, {
      'likedByMe': _liked,
      'likeCount': _likes,
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw Exception('auth');
      final res = await _api.likeChannelVideo(
        accessToken: token,
        videoId: videoId,
      );
      if (!mounted) return;
      final liked = _asBool(res['liked']) || res['liked'] == true;
      final count = _asInt(res['likeCount'], _likes);
      setState(() {
        _liked = liked;
        _likes = count;
      });
      widget.onVideoPatch(videoId, {
        'likedByMe': liked,
        'likeCount': count,
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked = prevLiked;
        _likes = prevLikes;
      });
      widget.onVideoPatch(videoId, {
        'likedByMe': prevLiked,
        'likeCount': prevLikes,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorGenericRetry)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Caption-only share text — never dump the raw video URL into Moments/chat.
  String _shareCaption() {
    final caption = (widget.video['caption'] as String?)?.trim() ?? '';
    final name = (widget.video['authorName'] as String?)?.trim() ?? 'OBIC';
    return caption.isNotEmpty ? '$name: $caption' : name;
  }

  Future<void> _bumpShareCount() async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      final res = await _api.shareChannelVideo(
        accessToken: token,
        videoId: widget.video['id'] as String,
      );
      if (!mounted) return;
      final count = _asInt(res['shareCount'], _shares + 1);
      setState(() => _shares = count);
      widget.onVideoPatch(widget.video['id'] as String, {
        'shareCount': count,
      });
    } catch (_) {}
  }

  Future<void> _share() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  l10n.channelShareTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: ObicColors.titleOf(ctx),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.channelShareToMoments),
                onTap: () => Navigator.pop(ctx, 'moments'),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(l10n.channelShareToChat),
                onTap: () => Navigator.pop(ctx, 'chat'),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(l10n.channelShareCopyLink),
                onTap: () => Navigator.pop(ctx, 'copy'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    // Cancel / dismiss → do NOT increment shareCount.
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'moments':
        await _shareToMoments();
      case 'chat':
        await _shareToChat();
      case 'copy':
        await _shareCopyLink();
      default:
        break;
    }
  }

  Future<void> _shareCopyLink() async {
    final l10n = AppLocalizations.of(context);
    final url = widget.video['videoUrl'] as String? ?? '';
    final text = url.isNotEmpty ? resolveMediaUrl(url) : _shareCaption();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.channelShareCopied)),
    );
    // Copying a link is not a completed Moments/Chat share — no count bump.
  }

  Future<void> _shareToMoments() async {
    final l10n = AppLocalizations.of(context);
    final url = widget.video['videoUrl'] as String?;
    final thumb = widget.video['thumbUrl'] as String?;
    final media = <Map<String, dynamic>>[];
    if (url != null && url.isNotEmpty) {
      media.add({
        'kind': 'video',
        'url': resolveMediaUrl(url),
        'name': 'channel.mp4',
        if (thumb != null && thumb.isNotEmpty)
          'thumbUrl': resolveMediaUrl(thumb),
      });
    } else if (thumb != null && thumb.isNotEmpty) {
      media.add({
        'kind': 'image',
        'url': resolveMediaUrl(thumb),
        'name': 'channel.jpg',
      });
    }
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MomentComposeScreen(
          authController: widget.authController,
          // Caption only — video rides in initialRemoteMedia, not the text field.
          initialBody: _shareCaption(),
          initialRemoteMedia: media,
        ),
      ),
    );
    // Only after a successful Moments post.
    if (posted == true) {
      await _bumpShareCount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.channelShareMomentsDone)),
      );
    }
  }

  Future<void> _shareToChat() async {
    final l10n = AppLocalizations.of(context);
    final token = await widget.authController.accessToken();
    if (token == null || !mounted) return;
    List<Map<String, dynamic>> friends;
    try {
      friends = await _api.listFriends(token);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGenericRetry)),
      );
      return;
    }
    if (!mounted) return;
    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.channelShareNoFriends)),
      );
      return;
    }
    final peer = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.5,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    l10n.channelSharePickFriend,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (_, i) {
                      final f = friends[i];
                      final name = (f['name'] as String?) ?? l10n.momentsAnon;
                      return ListTile(
                        title: Text(name),
                        onTap: () => Navigator.pop(ctx, f),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    // Friend picker cancelled — no share count.
    if (peer == null || !mounted) return;
    final peerId = peer['id'] as String?;
    if (peerId == null) return;
    try {
      final thread = await _api.openDirectThread(
        accessToken: token,
        peerUserId: peerId,
      );
      final threadId = thread['id'] as String?;
      if (threadId == null) throw Exception('thread');
      final videoUrl = widget.video['videoUrl'] as String?;
      final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
      await _api.sendMessage(
        accessToken: token,
        threadId: threadId,
        // Video is the attachment; caption is optional text — no URL dump.
        body: _shareCaption(),
        attachmentKind: hasVideo ? 'video' : 'none',
        attachmentName: hasVideo ? 'channel.mp4' : null,
        attachmentUrl: hasVideo ? resolveMediaUrl(videoUrl) : null,
      );
      await _bumpShareCount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.channelShareChatDone)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGenericRetry)),
      );
    }
  }

  Future<void> _openComments() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final l10n = AppLocalizations.of(context);
    final videoId = widget.video['id'] as String;
    final token = await widget.authController.accessToken();
    List<Map<String, dynamic>> comments = [];
    try {
      comments = await _api.listChannelVideoComments(
        videoId: videoId,
        accessToken: token,
      );
    } catch (_) {}
    if (!mounted) return;
    final ctrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ObicColors.surfaceOf(context),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.55,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.channelCommentsTitle(_comments),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: comments.isEmpty
                      ? Center(child: Text(l10n.channelCommentsEmpty))
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (_, i) {
                            final c = comments[i];
                            return ListTile(
                              title: Text(
                                c['authorName'] as String? ?? l10n.momentsAnon,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(c['body'] as String? ?? ''),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          decoration: InputDecoration(
                            hintText: l10n.channelCommentHint,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final body = ctrl.text.trim();
                          if (body.isEmpty) return;
                          final t =
                              await widget.authController.accessToken();
                          if (t == null) return;
                          try {
                            final created = await _api.commentChannelVideo(
                              accessToken: t,
                              videoId: videoId,
                              body: body,
                            );
                            comments = [...comments, created];
                            ctrl.clear();
                            if (ctx.mounted) {
                              (ctx as Element).markNeedsBuild();
                            }
                            if (mounted) {
                              setState(() => _comments += 1);
                            }
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.send, color: Color(0xFF07C160)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    ctrl.dispose();
  }

  String _fmt(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final caption = (widget.video['caption'] as String?) ?? '';
    final name = (widget.video['authorName'] as String?) ?? '';
    final verified = widget.video['authorVerified'] == true;
    final avatar = widget.video['authorAvatarUrl'] as String?;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            final c = _ctrl;
            if (c == null || !_ready) return;
            if (c.value.isPlaying) {
              c.pause();
            } else {
              c.play();
            }
            setState(() {});
          },
          child: ColoredBox(
            color: Colors.black,
            child: !_ready || _ctrl == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _ctrl!.value.size.width,
                      height: _ctrl!.value.size.height,
                      child: VideoPlayer(_ctrl!),
                    ),
                  ),
          ),
        ),
        // Bottom gradient + meta
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 48, 72, 16 + bottom),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    MomentAvatar(
                      name: name.isNotEmpty ? name : '?',
                      avatarUrl: avatar,
                      size: 32,
                      borderRadius: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: Color(0xFFFFC107),
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        // Right engagement column — WeChat Channels: one Like (heart) + share + comments
        Positioned(
          right: 10,
          bottom: 100 + bottom,
          child: Column(
            children: [
              _EngagementButton(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                color: _liked ? const Color(0xFFFA5151) : Colors.white,
                label: _fmt(_likes),
                onTap: () => unawaited(_toggleLike()),
              ),
              const SizedBox(height: 18),
              _EngagementButton(
                icon: Icons.ios_share_outlined,
                label: _fmt(_shares),
                onTap: () => unawaited(_share()),
              ),
              const SizedBox(height: 18),
              _EngagementButton(
                icon: Icons.chat_bubble_outline,
                label: _fmt(_comments),
                onTap: () => unawaited(_openComments()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EngagementButton extends StatelessWidget {
  const _EngagementButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
