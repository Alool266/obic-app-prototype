// Made by Dr Ali
// Compose a WeChat-style Moment — text + media + privacy (who can see).

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/api_errors.dart';
import '../../core/media_pick.dart';
import '../../core/media_url.dart';
import '../../widgets/obic_cached_image.dart';
import '../../widgets/wechat_media_actions.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';
import 'moment_friend_picker.dart';

class _PendingMedia {
  _PendingMedia({
    required this.filename,
    required this.kind, // image | video | file
    this.path,
    this.remoteUrl,
    this.thumbUrl,
  }) : assert(
          (path != null && path.isNotEmpty) ||
              (remoteUrl != null && remoteUrl.isNotEmpty),
        );

  /// Local file path (picked / camera). Null when [remoteUrl] is set.
  final String? path;
  /// Already-hosted URL (Channel share) — skipped from upload.
  final String? remoteUrl;
  /// Optional poster for remote video.
  final String? thumbUrl;
  final String filename;
  final String kind;

  bool get isRemote =>
      remoteUrl != null &&
      remoteUrl!.isNotEmpty &&
      (path == null || path!.isEmpty);
}

/// WeChat Moments who-can-see modes (customers; staff default remains public).
enum _MomentPrivacy {
  friends,
  private,
  partial,
  exclude,
}

class MomentComposeScreen extends StatefulWidget {
  const MomentComposeScreen({
    super.key,
    required this.authController,
    this.initialMedia = const [],
    this.initialBody,
    this.initialRemoteMedia = const [],
  });

  final AuthController authController;

  /// Pre-filled picks from the Moments camera-button sheet.
  final List<({String path, String filename, String kind})> initialMedia;

  /// Prefill text (e.g. Channel share).
  final String? initialBody;

  /// Already-hosted media URLs (Channel share) — skipped from upload.
  final List<Map<String, dynamic>> initialRemoteMedia;

  @override
  State<MomentComposeScreen> createState() => _MomentComposeScreenState();
}

class _MomentComposeScreenState extends State<MomentComposeScreen> {
  final _api = SocialApi();
  final _text = TextEditingController();
  final _picker = ImagePicker();
  late final List<_PendingMedia> _media;
  bool _posting = false;
  _MomentPrivacy _privacy = _MomentPrivacy.friends;
  List<String> _selectedFriendIds = [];

  static const _kMaxMedia = 9;

  @override
  void initState() {
    super.initState();
    _media = [
      for (final m in widget.initialMedia)
        _PendingMedia(path: m.path, filename: m.filename, kind: m.kind),
      for (final m in widget.initialRemoteMedia)
        if ((m['url'] as String?)?.trim().isNotEmpty == true)
          _PendingMedia(
            remoteUrl: resolveMediaUrl((m['url'] as String).trim()),
            thumbUrl: (m['thumbUrl'] as String?)?.trim().isNotEmpty == true
                ? resolveMediaUrl((m['thumbUrl'] as String).trim())
                : null,
            filename: (m['name'] as String?)?.trim().isNotEmpty == true
                ? (m['name'] as String).trim()
                : ((m['kind'] as String?) == 'video'
                    ? 'video.mp4'
                    : 'image.jpg'),
            kind: (m['kind'] as String?)?.trim().isNotEmpty == true
                ? (m['kind'] as String).trim()
                : 'image',
          ),
    ];
    // Caption only — never dump raw media URLs into the body (WeChat-style).
    final seed = widget.initialBody?.trim();
    if (seed != null && seed.isNotEmpty) {
      _text.text = _stripMediaUrls(seed);
    }
  }

  /// Drop bare http(s) upload/media links so share landings stay caption-only.
  static String _stripMediaUrls(String raw) {
    final withoutUrls = raw.replaceAll(
      RegExp(r'https?:\/\/\S+', caseSensitive: false),
      '',
    );
    return withoutUrls
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  int get _remaining => _kMaxMedia - _media.length;

  void _toast(String msg) {
    if (!mounted || msg.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _mediaPickErrorLabel(Object e) {
    final l10n = AppLocalizations.of(context);
    switch (classifyMediaPickError(e)) {
      case 'camera_denied':
        return l10n.mediaCameraPermissionDenied;
      case 'photos_denied':
        return l10n.mediaPhotosPermissionDenied;
      case 'mic_denied':
        return l10n.chatMicPermissionDenied;
      case 'cancelled':
        return '';
      default:
        return l10n.mediaPickFailed;
    }
  }

  Future<bool> _gateVideo(String path) async {
    final l10n = AppLocalizations.of(context);
    final len = await localFileLength(path);
    switch (classifyVideoSize(len)) {
      case 'too_large':
        _toast(l10n.chatVideoTooLarge);
        return false;
      case 'unreadable':
        _toast(l10n.chatVideoPickFailed);
        return false;
      case 'large_warning':
        _toast(l10n.chatVideoLargeWarning);
        return true;
      case 'ok':
        return true;
      default:
        return true;
    }
  }

  void _append(List<_PendingMedia> next) {
    if (next.isEmpty) return;
    setState(() {
      for (final m in next) {
        if (_media.length >= _kMaxMedia) break;
        _media.add(m);
      }
    });
  }

  Future<void> _addPhotos() async {
    if (_remaining <= 0) return;
    try {
      final shots = await pickAlbumImages(
        _picker,
        imageQuality: 85,
        limit: _remaining,
      );
      if (shots.isEmpty || !mounted) return;
      _append([
        for (final s in shots)
          _PendingMedia(path: s.path, filename: s.filename, kind: s.kind),
      ]);
    } catch (e) {
      _toast(_mediaPickErrorLabel(e));
    }
  }

  Future<void> _addCamera() async {
    if (_remaining <= 0) return;
    try {
      final shot = await takeCameraPhoto(_picker, imageQuality: 85);
      if (shot == null || !mounted) return;
      _append([
        _PendingMedia(path: shot.path, filename: shot.filename, kind: shot.kind),
      ]);
    } catch (e) {
      _toast(_mediaPickErrorLabel(e));
    }
  }

  Future<void> _addVideos() async {
    if (_remaining <= 0) return;
    final source = await showWechatVideoSourceSheet(context);
    if (source == null || !mounted) return;
    try {
      final shot = await pickOrRecordVideo(
        _picker,
        source: source,
        maxDuration: kMomentsVideoMaxDuration,
      );
      if (shot == null || !mounted) return;
      if (!await _gateVideo(shot.path)) return;
      _append([
        _PendingMedia(path: shot.path, filename: shot.filename, kind: shot.kind),
      ]);
    } catch (e) {
      _toast(_mediaPickErrorLabel(e));
    }
  }

  Future<void> _addFiles() async {
    if (_remaining <= 0) return;
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'media',
            extensions: [
              'jpg',
              'jpeg',
              'png',
              'gif',
              'webp',
              'mp4',
              'mov',
              'pdf',
              'doc',
              'docx',
              'xls',
              'xlsx',
              'txt',
              'zip',
            ],
          ),
        ],
      );
      if (files.isEmpty || !mounted) return;
      final next = <_PendingMedia>[];
      for (final f in files.take(_remaining)) {
        final kind = mediaKindFromFilename(f.name);
        if (kind == 'video' && !await _gateVideo(f.path)) continue;
        next.add(
          _PendingMedia(path: f.path, filename: f.name, kind: kind),
        );
      }
      if (!mounted) return;
      _append(next);
    } catch (e) {
      _toast(_mediaPickErrorLabel(e));
    }
  }

  Future<void> _openAttachSheet() async {
    final choice = await showMomentsComposeAttachSheet(context);
    if (!mounted) return;
    switch (choice) {
      case 'album':
        await _addPhotos();
      case 'camera':
        await _addCamera();
      case 'video':
        await _addVideos();
      case 'files':
        await _addFiles();
      default:
        break;
    }
  }

  String _privacyLabel(AppLocalizations l10n) {
    switch (_privacy) {
      case _MomentPrivacy.friends:
        return l10n.momentsPrivacyFriends;
      case _MomentPrivacy.private:
        return l10n.momentsPrivacyPrivate;
      case _MomentPrivacy.partial:
        return l10n.momentsPrivacyPartialSelected(_selectedFriendIds.length);
      case _MomentPrivacy.exclude:
        return l10n.momentsPrivacyExcludeSelected(_selectedFriendIds.length);
    }
  }

  Future<void> _pickPrivacy() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<_MomentPrivacy>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.momentsPrivacyWhoCanSee,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.public_outlined),
              title: Text(l10n.momentsPrivacyFriends),
              subtitle: Text(l10n.momentsPrivacyFriendsHint),
              onTap: () => Navigator.pop(ctx, _MomentPrivacy.friends),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.momentsPrivacyPrivate),
              subtitle: Text(l10n.momentsPrivacyPrivateHint),
              onTap: () => Navigator.pop(ctx, _MomentPrivacy.private),
            ),
            ListTile(
              leading: const Icon(Icons.group_outlined),
              title: Text(l10n.momentsPrivacyPartial),
              subtitle: Text(l10n.momentsPrivacyPartialHint),
              onTap: () => Navigator.pop(ctx, _MomentPrivacy.partial),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: Text(l10n.momentsPrivacyExclude),
              subtitle: Text(l10n.momentsPrivacyExcludeHint),
              onTap: () => Navigator.pop(ctx, _MomentPrivacy.exclude),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    if (choice == _MomentPrivacy.partial || choice == _MomentPrivacy.exclude) {
      final title = choice == _MomentPrivacy.partial
          ? l10n.momentsPrivacyPartial
          : l10n.momentsPrivacyExclude;
      final ids = await pickMomentFriends(
        context: context,
        authController: widget.authController,
        title: title,
        initiallySelected: _selectedFriendIds,
      );
      if (!mounted) return;
      if (ids == null || ids.isEmpty) {
        _toast(l10n.momentsPrivacyNeedFriends);
        return;
      }
      setState(() {
        _privacy = choice;
        _selectedFriendIds = ids;
      });
      return;
    }

    setState(() {
      _privacy = choice;
      _selectedFriendIds = [];
    });
  }

  Future<void> _post() async {
    final body = _text.text.trim();
    if (body.isEmpty && _media.isEmpty) return;
    if ((_privacy == _MomentPrivacy.partial ||
            _privacy == _MomentPrivacy.exclude) &&
        _selectedFriendIds.isEmpty) {
      _toast(AppLocalizations.of(context).momentsPrivacyNeedFriends);
      return;
    }
    setState(() => _posting = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw AuthApiException('Not signed in');

      final local = _media.where((m) => !m.isRemote).toList();
      final remote = [
        for (final m in _media.where((m) => m.isRemote))
          {
            'kind': m.kind,
            'url': m.remoteUrl,
            'name': m.filename,
          },
      ];

      List<Map<String, dynamic>> uploaded = [];
      if (local.isNotEmpty) {
        uploaded = await _api.uploadFiles(
          accessToken: token,
          files: local
              .map((m) => (path: m.path!, filename: m.filename))
              .toList(),
        );
      }

      final visibility = switch (_privacy) {
        _MomentPrivacy.friends => 'friends',
        _MomentPrivacy.private => 'private',
        _MomentPrivacy.partial => 'partial',
        _MomentPrivacy.exclude => 'exclude',
      };

      await _api.createMoment(
        accessToken: token,
        body: body,
        media: [...uploaded, ...remote],
        visibility: visibility,
        allowedUserIds:
            _privacy == _MomentPrivacy.partial ? _selectedFriendIds : null,
        deniedUserIds:
            _privacy == _MomentPrivacy.exclude ? _selectedFriendIds : null,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final msg = friendlyApiError(
        classifyTransportError(e),
        l10n: l10n,
        langCode: Localizations.localeOf(context).languageCode,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canPost =
        !_posting && (_text.text.trim().isNotEmpty || _media.isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        foregroundColor: const Color(0xFF191919),
        elevation: 0,
        title: Text(l10n.momentsCreate),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton(
              onPressed: canPost ? _post : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF07C160),
                disabledBackgroundColor: const Color(0xFF07C160).withValues(
                  alpha: 0.35,
                ),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 34),
              ),
              child: _posting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.momentsPost),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          TextField(
            controller: _text,
            maxLines: 6,
            maxLength: 4000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.momentsHint,
              border: InputBorder.none,
              counterText: '',
            ),
            style: const TextStyle(fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 8),
          _ComposeGrid(
            items: _media,
            showAdd: _media.length < _kMaxMedia,
            onAdd: _openAttachSheet,
            onRemove: (i) => setState(() => _media.removeAt(i)),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline, color: Color(0xFF576B95)),
            title: Text(l10n.momentsPrivacyWhoCanSee),
            subtitle: Text(
              _privacyLabel(l10n),
              style: const TextStyle(color: Color(0xFF576B95), fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFB2B2B2)),
            onTap: _posting ? null : _pickPrivacy,
          ),
        ],
      ),
    );
  }
}

class _ComposeGrid extends StatelessWidget {
  const _ComposeGrid({
    required this.items,
    required this.showAdd,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_PendingMedia> items;
  final bool showAdd;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 6.0;
        final cell = (c.maxWidth - gap * 2) / 3;
        final tiles = <Widget>[
          for (var i = 0; i < items.length; i++)
            SizedBox(
              width: cell,
              height: cell,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _thumb(items[i]),
                    ),
                  ),
                  PositionedDirectional(
                    top: 2,
                    end: 2,
                    child: InkWell(
                      onTap: () => onRemove(i),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (showAdd)
            SizedBox(
              width: cell,
              height: cell,
              child: Material(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(4),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      size: 40,
                      color: Color(0xFFB2B2B2),
                    ),
                  ),
                ),
              ),
            ),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: tiles,
        );
      },
    );
  }

  Widget _thumb(_PendingMedia m) {
    if (m.kind == 'image') {
      if (m.isRemote) {
        return ObicCachedImage(
          m.remoteUrl!,
          fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
            color: Color(0xFFF0F0F0),
            child: Icon(Icons.broken_image_outlined, color: Color(0xFFB2B2B2)),
          ),
        );
      }
      return Image.file(File(m.path!), fit: BoxFit.cover);
    }
    if (m.kind == 'video') {
      final poster = m.thumbUrl;
      return ColoredBox(
        color: const Color(0xFF222222),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (poster != null && poster.isNotEmpty)
              ObicCachedImage(
                poster,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      m.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 28),
          const SizedBox(height: 4),
          Text(
            m.filename,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
