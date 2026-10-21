// Made by Dr Ali
// WeChat-style Favorites — chat + Moments (picker or browse from Me).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_cached_image.dart';
import '../auth/auth_controller.dart';
import '../moments/moments_screen.dart';
import 'chat_attach_helpers.dart';
import 'chat_favorites_store.dart';
import 'chat_media_bubbles.dart';

/// Chat: pick an item to send. Me tab: browse / delete / open.
Future<ChatFavorite?> showChatFavoritesPicker(
  BuildContext context, {
  bool pickMode = true,
  AuthController? authController,
}) {
  return showModalBottomSheet<ChatFavorite>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ObicColors.surfaceOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _FavoritesSheet(
      pickMode: pickMode,
      authController: authController,
    ),
  );
}

class _FavoritesSheet extends StatefulWidget {
  const _FavoritesSheet({
    this.pickMode = true,
    this.authController,
  });

  final bool pickMode;
  final AuthController? authController;

  @override
  State<_FavoritesSheet> createState() => _FavoritesSheetState();
}

class _FavoritesSheetState extends State<_FavoritesSheet> {
  late Future<List<ChatFavorite>> _future;

  @override
  void initState() {
    super.initState();
    _future = ChatFavoritesStore.instance.list();
  }

  Future<void> _addText() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add text to Favorites'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Type something to save…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;
    await ChatFavoritesStore.instance.add(kind: 'text', body: text);
    if (!mounted) return;
    setState(() => _future = ChatFavoritesStore.instance.list());
  }

  IconData _icon(String kind) {
    switch (kind) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'file':
        return Icons.insert_drive_file_outlined;
      case 'audio':
        return Icons.mic_none_rounded;
      case 'moment':
        return Icons.auto_awesome_outlined;
      default:
        return Icons.notes_rounded;
    }
  }

  bool _urlLooksVideo(String? url) {
    final u = (url ?? '').toLowerCase();
    return u.contains('.mp4') ||
        u.contains('.mov') ||
        u.contains('.m4v') ||
        u.contains('.webm');
  }

  Future<void> _onTap(ChatFavorite item) async {
    // Chat picker: return item to attach/send (moments stay browse-only).
    if (widget.pickMode && item.kind != 'moment') {
      Navigator.pop(context, item);
      return;
    }

    switch (item.kind) {
      case 'image':
        final imageUrl = item.pathOrUrl?.trim() ?? '';
        if (imageUrl.isEmpty) return;
        await openChatImageViewer(context, url: imageUrl);
        return;
      case 'video':
        final videoUrl = item.pathOrUrl?.trim() ?? '';
        if (videoUrl.isEmpty) return;
        await openChatVideoViewer(
          context,
          url: videoUrl,
          title: item.name,
        );
        return;
      case 'text':
        await _showFullText(item);
        return;
      case 'moment':
        await _openMoment(item);
        return;
      case 'file':
      case 'audio':
        await _openFileOrUrl(item);
        return;
      default:
        if ((item.body ?? '').trim().isNotEmpty) {
          await _showFullText(item);
        }
    }
  }

  Future<void> _showFullText(ChatFavorite item) async {
    final text = (item.body ?? '').trim();
    if (text.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.kind == 'moment' ? 'Moment' : 'Favorite'),
        content: SingleChildScrollView(
          child: SelectableText(text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMoment(ChatFavorite item) async {
    final auth = widget.authController;
    final momentId = item.momentId?.trim();
    if (auth != null && momentId != null && momentId.isNotEmpty) {
      final nav = Navigator.of(context);
      nav.pop(); // close Favorites sheet
      await nav.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MomentsScreen(
            authController: auth,
            focusMomentId: momentId,
          ),
        ),
      );
      return;
    }
    // Fallback: show saved text / open saved media thumb.
    final media = item.pathOrUrl?.trim() ?? '';
    if (media.isNotEmpty) {
      if (_urlLooksVideo(media)) {
        await openChatVideoViewer(context, url: media, title: item.name);
      } else {
        await openChatImageViewer(context, url: media);
      }
      return;
    }
    await _showFullText(item);
  }

  Future<void> _openFileOrUrl(ChatFavorite item) async {
    final raw = item.pathOrUrl?.trim() ?? '';
    if (raw.isEmpty) {
      if ((item.body ?? '').trim().isNotEmpty) {
        await _showFullText(item);
      }
      return;
    }
    if (isLocalAttachmentPath(raw)) {
      final path = resolvedChatMediaUrl(raw);
      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }
    final resolved = resolvedChatMediaUrl(raw);
    final uri = Uri.tryParse(resolved);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _leading(ChatFavorite item) {
    final media = item.pathOrUrl?.trim() ?? '';
    if (item.kind == 'image' && media.isNotEmpty) {
      return _FavoriteImageThumb(url: media);
    }
    if (item.kind == 'video' && media.isNotEmpty) {
      return _FavoriteVideoThumb(url: media);
    }
    if (item.kind == 'moment' && media.isNotEmpty) {
      if (_urlLooksVideo(media)) {
        return _FavoriteVideoThumb(url: media);
      }
      return _FavoriteImageThumb(url: media);
    }
    return CircleAvatar(
      backgroundColor: ObicColors.blueSoft,
      child: Icon(
        _icon(item.kind),
        color: ObicColors.blue,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.62;
    return SizedBox(
      height: h,
      child: Column(
        children: [
          SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: ObicColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Favorites',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: ObicColors.titleOf(context),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addText,
                  icon: Icon(Icons.note_add_outlined, size: 18),
                  label: Text('Text'),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Save Moments, chat text, photos, videos, and files — like WeChat. '
              'Long-press a Moment or a chat bubble to favorite it.',
              style: TextStyle(fontSize: 12, color: ObicColors.mutedOf(context)),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<ChatFavorite>>(
              future: _future,
              builder: (context, snap) {
                final rows = snap.data ?? [];
                if (snap.connectionState == ConnectionState.waiting &&
                    snap.data == null) {
                  return Center(child: CircularProgressIndicator());
                }
                if (rows.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No favorites yet.\n'
                        'Long-press a Moment or a chat message to save it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ObicColors.mutedOf(context)),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = rows[i];
                    return ListTile(
                      leading: _leading(item),
                      title: Text(
                        item.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(item.kind),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ChatFavoritesStore.instance.remove(item.id);
                          if (!mounted) return;
                          setState(
                            () => _future = ChatFavoritesStore.instance.list(),
                          );
                        },
                      ),
                      onTap: () => _onTap(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteImageThumb extends StatelessWidget {
  const _FavoriteImageThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final raw = url.trim();
    final resolved = resolvedChatMediaUrl(raw);
    final Widget image;
    if (isLocalAttachmentPath(raw)) {
      image = Image.file(
        File(resolved),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _broken(context),
      );
    } else {
      image = ObicCachedImage(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _broken(context),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: 48, height: 48, child: image),
    );
  }

  Widget _broken(BuildContext context) {
    return ColoredBox(
      color: ObicColors.blueSoft,
      child: Icon(Icons.broken_image_outlined, color: ObicColors.blue, size: 22),
    );
  }
}

class _FavoriteVideoThumb extends StatefulWidget {
  const _FavoriteVideoThumb({required this.url});

  final String url;

  @override
  State<_FavoriteVideoThumb> createState() => _FavoriteVideoThumbState();
}

class _FavoriteVideoThumbState extends State<_FavoriteVideoThumb> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final raw = widget.url.trim();
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black87,
              child: _ready && _controller != null
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.videocam_outlined,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
            ),
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white70,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
