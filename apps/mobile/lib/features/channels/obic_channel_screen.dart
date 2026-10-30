// Made by Dr Ali
// OBIC Channel — WeChat 视频号–style short video feed + upload.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

import '../../core/api_errors.dart';
import '../../core/media_url.dart';
import '../../widgets/obic_cached_image.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../social/social_api.dart';

const _kGreen = Color(0xFF07C160);
const _kChannelMaxBytes = 40 * 1024 * 1024;
const _kChannelMaxSec = 60;

class ObicChannelScreen extends StatefulWidget {
  const ObicChannelScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ObicChannelScreen> createState() => _ObicChannelScreenState();
}

class _ObicChannelScreenState extends State<ObicChannelScreen> {
  final _api = SocialApi();
  Map<String, dynamic>? _channel;
  List<Map<String, dynamic>> _videos = [];
  bool _loading = true;
  String? _error;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final token = await widget.authController.accessToken();
      final channel = await _api.getObicChannel(accessToken: token);
      final videos = await _api.listObicChannelVideos(accessToken: token);
      if (!mounted) return;
      setState(() {
        _channel = channel;
        _videos = videos;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _toggleFollow() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok || _followBusy) return;
    setState(() => _followBusy = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      final followed = _channel?['followedByMe'] == true;
      final next = followed
          ? await _api.unfollowObicChannel(token)
          : await _api.followObicChannel(token);
      if (!mounted) return;
      setState(() => _channel = next);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGenericRetry)),
      );
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _upload() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    final l10n = AppLocalizations.of(context);
    final shot = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: _kChannelMaxSec),
    );
    if (shot == null || !mounted) return;

    final file = File(shot.path);
    final bytes = await file.length();
    if (bytes > _kChannelMaxBytes) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.channelUploadLimits,
              style: TextStyle(
                fontSize: 13,
                color: ObicColors.mutedOf(ctx),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: captionCtrl,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.channelCaptionHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.chatHandoffCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kGreen),
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
        files: [
          (path: shot.path, filename: p.basename(shot.path)),
        ],
      );
      if (items.isEmpty) throw Exception('Upload failed');
      final url = items.first['url'] as String?;
      if (url == null || url.isEmpty) throw Exception('Upload failed');

      int? durationSec;
      try {
        final ctrl = VideoPlayerController.file(file);
        await ctrl.initialize();
        durationSec = ctrl.value.duration.inSeconds.clamp(1, _kChannelMaxSec);
        await ctrl.dispose();
      } catch (_) {}

      if (durationSec != null && durationSec > _kChannelMaxSec) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.channelVideoTooLong)),
        );
        return;
      }

      await _api.createObicChannelVideo(
        accessToken: token,
        videoUrl: url,
        caption: caption,
        durationSec: durationSec,
        byteSize: bytes,
      );
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      await _load(silent: true);
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

  void _play(Map<String, dynamic> v) {
    final url = v['videoUrl'] as String?;
    if (url == null || url.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ChannelVideoPlayerPage(
          url: resolveMediaUrl(url),
          caption: (v['caption'] as String?) ?? '',
          authorName: (v['authorName'] as String?) ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = ObicColors.isDark(context);
    final ch = _channel;
    final followed = ch?['followedByMe'] == true;
    final followers = ch?['followerCount'] as int? ?? 0;
    final videoCount = ch?['videoCount'] as int? ?? 0;
    final limits = ch?['limits'] as Map?;
    final maxMb = limits?['maxMb'] as int? ?? 40;
    final maxSec = limits?['maxDurationSec'] as int? ?? 60;

    return Scaffold(
      backgroundColor: dark ? ObicColors.darkCanvas : const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(l10n.channelTitle),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        surfaceTintColor: Colors.transparent,
        actions: [
          if (ch?['canPost'] == true)
            IconButton(
              tooltip: l10n.channelUpload,
              onPressed: _upload,
              icon: const Icon(Icons.video_call_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: _kGreen,
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      Container(
                        color: ObicColors.surfaceOf(context),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: ObicColors.navy,
                                  child: Text(
                                    'OB',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ch?['name'] as String? ??
                                            l10n.channelTitle,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: ObicColors.inkOf(context),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.channelStats(
                                          followers,
                                          videoCount,
                                        ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: ObicColors.mutedOf(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        followed ? Colors.grey : _kGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  onPressed: _followBusy ? null : _toggleFollow,
                                  child: Text(
                                    followed
                                        ? l10n.channelFollowing
                                        : l10n.channelFollow,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              (ch?['description'] as String?)?.trim().isNotEmpty ==
                                      true
                                  ? ch!['description'] as String
                                  : l10n.channelDescription,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: ObicColors.inkOf(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.channelLimitsHint(maxMb, maxSec),
                              style: TextStyle(
                                fontSize: 12,
                                color: ObicColors.mutedOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_videos.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(child: Text(l10n.channelEmpty)),
                        )
                      else
                        for (final v in _videos)
                          _VideoCard(
                            video: v,
                            onTap: () => _play(v),
                          ),
                    ],
                  ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video, required this.onTap});

  final Map<String, dynamic> video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final caption = (video['caption'] as String?) ?? '';
    final name = (video['authorName'] as String?) ?? '';
    final dur = video['durationSec'] as int?;
    final thumb = video['thumbUrl'] as String?;

    return Material(
      color: ObicColors.surfaceOf(context),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 88,
                  height: 118,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: ObicColors.isDark(context)
                            ? ObicColors.darkSurfaceRaised
                            : const Color(0xFFE8E8E8),
                      ),
                      if (thumb != null && thumb.isNotEmpty)
                        ObicCachedImage(
                          resolveMediaUrl(thumb),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white70,
                          size: 36,
                        ),
                      ),
                      if (dur != null)
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Text(
                            '${dur}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caption.isEmpty
                          ? AppLocalizations.of(context).channelNoCaption
                          : caption,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ObicColors.inkOf(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF576B95),
                        fontSize: 13,
                      ),
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

class _ChannelVideoPlayerPage extends StatefulWidget {
  const _ChannelVideoPlayerPage({
    required this.url,
    required this.caption,
    required this.authorName,
  });

  final String url;
  final String caption;
  final String authorName;

  @override
  State<_ChannelVideoPlayerPage> createState() =>
      _ChannelVideoPlayerPageState();
}

class _ChannelVideoPlayerPageState extends State<_ChannelVideoPlayerPage> {
  late final VideoPlayerController _ctrl;
  bool _ready = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _ctrl.play();
      }).catchError((e) {
        if (!mounted) return;
        setState(() => _err = e.toString());
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.authorName.isEmpty ? 'OBIC' : widget.authorName,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _err != null
                  ? Text(
                      _err!,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    )
                  : !_ready
                      ? const CircularProgressIndicator(color: Colors.white)
                      : AspectRatio(
                          aspectRatio: _ctrl.value.aspectRatio == 0
                              ? 9 / 16
                              : _ctrl.value.aspectRatio,
                          child: GestureDetector(
                            onTap: () {
                              if (_ctrl.value.isPlaying) {
                                _ctrl.pause();
                              } else {
                                _ctrl.play();
                              }
                              setState(() {});
                            },
                            child: VideoPlayer(_ctrl),
                          ),
                        ),
            ),
          ),
          if (widget.caption.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Text(
                widget.caption,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
