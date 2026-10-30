// Made by Dr Ali
// Inline chat bubbles — voice / image / video (tap → play or fullscreen).

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

import '../../core/media_url.dart';
import '../../core/obic_phrases.dart';
import '../../widgets/obic_cached_image.dart';
import '../../theme/obic_colors.dart';
import 'chat_attach_helpers.dart';

/// Local file path or absolute HTTPS URL suitable for Image / video_player.
String resolvedChatMediaUrl(String? raw) {
  final u = raw?.trim() ?? '';
  if (u.isEmpty) return '';
  if (isLocalAttachmentPath(u)) {
    return u.startsWith('file://') ? Uri.parse(u).toFilePath() : u;
  }
  return resolveMediaUrl(u);
}

Future<void> openChatImageViewer(
  BuildContext context, {
  required String url,
}) {
  final raw = url.trim();
  if (raw.isEmpty) return Future.value();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => ChatImageViewer(url: raw),
      transitionsBuilder: (_, anim, _, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    ),
  );
}

Future<void> openChatVideoViewer(
  BuildContext context, {
  required String url,
  String? title,
}) {
  final raw = url.trim();
  if (raw.isEmpty) return Future.value();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChatVideoFullscreen(url: raw, title: title),
    ),
  );
}

class ChatVoiceBubble extends StatefulWidget {
  const ChatVoiceBubble({
    super.key,
    required this.url,
    required this.mine,
    this.durationSeconds,
  });

  final String? url;
  final bool mine;
  final int? durationSeconds;

  @override
  State<ChatVoiceBubble> createState() => _ChatVoiceBubbleState();
}

class _ChatVoiceBubbleState extends State<ChatVoiceBubble> {
  final _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.durationSeconds != null) {
      _dur = Duration(seconds: widget.durationSeconds!);
    }
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _pos = Duration.zero;
      });
    });
    _player.onPositionChanged.listen((d) {
      if (!mounted) return;
      setState(() => _pos = d);
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted || d.inMilliseconds <= 0) return;
      setState(() => _dur = d);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final raw = widget.url?.trim() ?? '';
    if (raw.isEmpty) return;
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _loading = true);
    try {
      if (isLocalAttachmentPath(raw)) {
        await _player.play(DeviceFileSource(resolvedChatMediaUrl(raw)));
      } else {
        await _player.play(UrlSource(resolvedChatMediaUrl(raw)));
      }
      if (mounted) {
        setState(() {
          _playing = true;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSec = _dur.inSeconds > 0
        ? _dur.inSeconds
        : (widget.durationSeconds ?? 0);
    final shown = _playing && _pos.inMilliseconds > 0
        ? formatVoiceDuration(_pos.inSeconds)
        : formatVoiceDuration(totalSec > 0 ? totalSec : 1);
    // WeChat-ish width scales with duration (min ~72, max ~200).
    final width = (72.0 + (totalSec.clamp(0, 60) * 2.0)).clamp(72.0, 200.0);

    final fg = widget.mine ? Colors.white : ObicColors.titleOf(context);
    final muted = widget.mine ? Colors.white70 : ObicColors.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : _toggle,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: muted,
                  ),
                )
              else
                Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 26,
                  color: fg,
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: muted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: totalSec > 0
                            ? (_pos.inMilliseconds /
                                    (_dur.inMilliseconds > 0
                                        ? _dur.inMilliseconds
                                        : totalSec * 1000))
                                .clamp(0.0, 1.0)
                            : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: fg,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shown,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: muted,
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

/// WeChat-style image bubble — tap opens full-screen viewer (local or remote).
class ChatImageBubble extends StatelessWidget {
  const ChatImageBubble({
    super.key,
    required this.url,
    required this.mine,
    this.openOnTap = true,
  });

  final String? url;
  final bool mine;
  final bool openOnTap;

  void _open(BuildContext context) {
    if (!openOnTap) return;
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) return;
    openChatImageViewer(context, url: raw);
  }

  @override
  Widget build(BuildContext context) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 16,
            color: mine ? Colors.white70 : ObicColors.muted,
          ),
          const SizedBox(width: 6),
          Text(
            'Image',
            style: TextStyle(
              fontSize: 12,
              color: mine ? Colors.white70 : ObicColors.mutedOf(context),
            ),
          ),
        ],
      );
    }

    final resolved = resolvedChatMediaUrl(raw);
    final Widget image;
    if (isLocalAttachmentPath(raw)) {
      image = Image.file(
        File(resolved),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _brokenThumb(context),
      );
    } else {
      image = ObicCachedImage(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _brokenThumb(context),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 168,
          height: 168,
          child: image,
        ),
      ),
    );
  }

  Widget _brokenThumb(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: mine ? const Color(0x33000000) : ObicColors.lineOf(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_outlined,
                color: mine ? Colors.white70 : ObicColors.mutedOf(context),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.chatImageLoadFailed,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: mine ? Colors.white70 : ObicColors.mutedOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatImageViewer extends StatefulWidget {
  const ChatImageViewer({super.key, required this.url});

  final String url;

  @override
  State<ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends State<ChatImageViewer> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final raw = widget.url.trim();
    final resolved = resolvedChatMediaUrl(raw);
    final local = isLocalAttachmentPath(raw);

    Widget body;
    if (resolved.isEmpty) {
      body = _errorBody(l10n.chatImageLoadFailed);
    } else if (local) {
      body = Image.file(
        File(resolved),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _errorBody(l10n.chatImageLoadFailed),
      );
    } else {
      body = ObicCachedImage(
        resolved,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (_, _, _) => _errorBody(l10n.chatImageLoadFailed),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(child: body),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: IconButton(
                  tooltip: obicPhrase(
                    context,
                    ar: 'حفظ الصورة',
                    en: 'Save image',
                    zh: '保存图片',
                  ),
                  onPressed: () => _saveImage(context, resolved, local),
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveImage(BuildContext context, String resolved, bool local) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final bytes = local
          ? await File(resolved).readAsBytes()
          : (await http.get(Uri.parse(resolved))).bodyBytes;
      await Gal.putImageBytes(bytes);
      if (!context.mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            obicPhrase(context, ar: 'تم حفظ الصورة', en: 'Image saved', zh: '图片已保存'),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            obicPhrase(
              context,
              ar: 'تعذّر حفظ الصورة',
              en: 'Could not save the image',
              zh: '无法保存图片',
            ),
          ),
        ),
      );
    }
  }

  Widget _errorBody(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatVideoBubble extends StatefulWidget {
  const ChatVideoBubble({
    super.key,
    required this.url,
    required this.mine,
    this.name,
  });

  final String? url;
  final bool mine;
  final String? name;

  @override
  State<ChatVideoBubble> createState() => _ChatVideoBubbleState();
}

class _ChatVideoBubbleState extends State<ChatVideoBubble> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initThumb();
  }

  Future<void> _initThumb() async {
    final raw = widget.url?.trim() ?? '';
    if (raw.isEmpty) return;
    try {
      final VideoPlayerController c;
      if (isLocalAttachmentPath(raw)) {
        c = VideoPlayerController.file(File(resolvedChatMediaUrl(raw)));
      } else {
        c = VideoPlayerController.networkUrl(
          Uri.parse(resolvedChatMediaUrl(raw)),
        );
      }
      _controller = c;
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    final raw = widget.url?.trim() ?? '';
    if (raw.isEmpty) return;
    openChatVideoViewer(context, url: raw, title: widget.name);
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.url?.trim() ?? '';
    if (raw.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam_outlined,
            size: 16,
            color: widget.mine ? Colors.white70 : ObicColors.muted,
          ),
          const SizedBox(width: 6),
          Text(
            widget.name ?? 'Video',
            style: TextStyle(
              fontSize: 12,
              color: widget.mine ? Colors.white70 : ObicColors.mutedOf(context),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _openFullscreen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 200,
          height: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black,
                child: _ready && _controller != null
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    : const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        ),
                      ),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white70,
                  size: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatVideoFullscreen extends StatefulWidget {
  const ChatVideoFullscreen({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  State<ChatVideoFullscreen> createState() => _ChatVideoFullscreenState();
}

class _ChatVideoFullscreenState extends State<ChatVideoFullscreen> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final VideoPlayerController c;
      if (isLocalAttachmentPath(widget.url)) {
        c = VideoPlayerController.file(
          File(resolvedChatMediaUrl(widget.url)),
        );
      } else {
        c = VideoPlayerController.networkUrl(
          Uri.parse(resolvedChatMediaUrl(widget.url)),
        );
      }
      _controller = c;
      await c.initialize();
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? 'Video'),
      ),
      body: Center(
        child: _ready && _controller != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio == 0
                    ? 16 / 9
                    : _controller!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller!),
                    Positioned(
                      bottom: 12,
                      child: IconButton(
                        iconSize: 48,
                        color: Colors.white,
                        onPressed: () {
                          final c = _controller!;
                          if (c.value.isPlaying) {
                            c.pause();
                          } else {
                            c.play();
                          }
                          setState(() {});
                        },
                        icon: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
