// Made by Dr Ali
// WeChat-style full-screen photo / video viewer with download.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

import '../../widgets/obic_cached_image.dart';
import 'media_download.dart';

const _kWeChatName = Color(0xFF576B95);

Future<void> openMomentPhotoViewer(
  BuildContext context, {
  required List<String> urls,
  required int initialIndex,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          MomentPhotoViewer(urls: urls, initialIndex: initialIndex),
      transitionsBuilder: (_, anim, _, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    ),
  );
}

Future<void> openMomentVideoViewer(
  BuildContext context, {
  required String url,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => MomentVideoViewer(url: url),
      transitionsBuilder: (_, anim, _, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    ),
  );
}

class MomentPhotoViewer extends StatefulWidget {
  const MomentPhotoViewer({
    super.key,
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<MomentPhotoViewer> createState() => _MomentPhotoViewerState();
}

class _MomentPhotoViewerState extends State<MomentPhotoViewer> {
  late final PageController _pc = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  bool _saving = false;
  bool _chromeVisible = true;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await saveImageToGallery(widget.urls[_index]);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.momentsSaved)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.momentsSaveFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyLink() async {
    final url = widget.urls[_index];
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.momentsCopied)));
  }

  void _showActions() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download_rounded, color: _kWeChatName),
              title: Text(l10n.momentsDownload),
              onTap: () {
                Navigator.pop(ctx);
                _save();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded, color: _kWeChatName),
              title: Text(l10n.momentsCopyLink),
              onTap: () {
                Navigator.pop(ctx);
                _copyLink();
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

  @override
  Widget build(BuildContext context) {
    final total = widget.urls.length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              itemCount: total,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                return GestureDetector(
                  onTap: () => setState(() => _chromeVisible = !_chromeVisible),
                  onLongPress: _showActions,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: ObicCachedImage(
                        widget.urls[i],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_chromeVisible) ...[
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const Spacer(),
                      if (total > 1)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '${_index + 1}/$total',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MomentVideoViewer extends StatefulWidget {
  const MomentVideoViewer({super.key, required this.url});

  final String url;

  @override
  State<MomentVideoViewer> createState() => _MomentVideoViewerState();
}

class _MomentVideoViewerState extends State<MomentVideoViewer> {
  late final VideoPlayerController _c = VideoPlayerController.networkUrl(
    Uri.parse(widget.url),
  );
  bool _ready = false;
  bool _saving = false;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _c
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          _c.play();
        })
        .catchError((_) {});
    _c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await saveVideoToGallery(widget.url);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.momentsSaved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.momentsSaveFailed}: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _chromeVisible = !_chromeVisible);
              if (_ready) {
                if (_c.value.isPlaying) {
                  _c.pause();
                } else {
                  _c.play();
                }
              }
            },
            child: Center(
              child: !_ready
                  ? const CircularProgressIndicator(color: Colors.white)
                  : AspectRatio(
                      aspectRatio: _c.value.aspectRatio == 0
                          ? 16 / 9
                          : _c.value.aspectRatio,
                      child: VideoPlayer(_c),
                    ),
            ),
          ),
          if (_ready && !_c.value.isPlaying)
            const IgnorePointer(
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white70,
                  size: 72,
                ),
              ),
            ),
          if (_chromeVisible)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          if (_ready && _chromeVisible)
            Positioned(
              left: 16,
              right: 16,
              bottom: 28,
              child: VideoProgressIndicator(
                _c,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF07C160),
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
