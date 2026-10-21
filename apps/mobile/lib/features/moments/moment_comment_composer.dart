// Made by Dr Ali
// WeChat Moments–style bottom comment composer (text + photos).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/media_pick.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/wechat_media_actions.dart';

const _kWeChatName = Color(0xFF576B95);
const _kWeChatGreen = Color(0xFF07C160);
const _kBarBg = Color(0xFFF7F7F7);
const _kMaxCommentImages = 9;

class MomentCommentDraft {
  const MomentCommentDraft({
    required this.body,
    required this.images,
  });

  final String body;
  final List<({String path, String filename})> images;
}

/// Bottom-anchored WeChat-like composer. Returns null if dismissed.
Future<MomentCommentDraft?> showMomentCommentComposer(
  BuildContext context, {
  String? replyToName,
}) {
  return showModalBottomSheet<MomentCommentDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (ctx) => _MomentCommentComposerSheet(replyToName: replyToName),
  );
}

class _MomentCommentComposerSheet extends StatefulWidget {
  const _MomentCommentComposerSheet({this.replyToName});

  final String? replyToName;

  @override
  State<_MomentCommentComposerSheet> createState() =>
      _MomentCommentComposerSheetState();
}

class _MomentCommentComposerSheetState
    extends State<_MomentCommentComposerSheet> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  final _picker = ImagePicker();
  final List<({String path, String filename})> _images = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _controller.text.trim().isNotEmpty || _images.isNotEmpty;

  Future<void> _pickPhotos() async {
    if (_images.length >= _kMaxCommentImages) return;
    final remaining = _kMaxCommentImages - _images.length;
    try {
      final shots = await pickAlbumImages(
        _picker,
        imageQuality: 85,
        limit: remaining,
      );
      if (shots.isEmpty || !mounted) return;
      setState(() {
        for (final x in shots) {
          if (_images.length >= _kMaxCommentImages) break;
          _images.add((path: x.path, filename: x.filename));
        }
      });
    } catch (_) {
      // Parent Moments screen surfaces toast on send; ignore cancel.
    }
  }

  Future<void> _pickCamera() async {
    if (_images.length >= _kMaxCommentImages) return;
    try {
      final shot = await takeCameraPhoto(_picker, imageQuality: 85);
      if (shot == null || !mounted) return;
      setState(() {
        _images.add((path: shot.path, filename: shot.filename));
      });
    } catch (_) {}
  }

  void _showAttachMenu() {
    final l10n = AppLocalizations.of(context);
    showWechatActionGrid(
      context,
      title: l10n.momentsCommentAddPhoto,
      items: [
        (
          id: 'album',
          icon: Icons.photo_library_outlined,
          label: l10n.momentsAddPhotos,
        ),
        (
          id: 'camera',
          icon: Icons.photo_camera_outlined,
          label: l10n.momentsCommentTakePhoto,
        ),
      ],
    ).then((id) {
      if (!mounted) return;
      switch (id) {
        case 'album':
          _pickPhotos();
        case 'camera':
          _pickCamera();
        default:
          break;
      }
    });
  }

  void _submit() {
    if (!_canSend) return;
    Navigator.pop(
      context,
      MomentCommentDraft(
        body: _controller.text.trim(),
        images: List.of(_images),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reply = widget.replyToName?.trim();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = ObicColors.isDark(context);
    final barBg = isDark ? ObicColors.darkSurfaceRaised : _kBarBg;
    final fieldBg = isDark ? ObicColors.darkSurface : Colors.white;
    final ink = isDark ? ObicColors.darkInk : const Color(0xFF191919);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: barBg,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reply != null && reply.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Text(
                    l10n.momentsReplyTo(reply),
                    style: TextStyle(
                      color: _kWeChatName,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (_images.isNotEmpty)
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final img = _images[i];
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              File(img.path),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(i)),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF666666),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _images.length >= _kMaxCommentImages
                          ? null
                          : _showAttachMenu,
                      tooltip: l10n.momentsCommentAddPhoto,
                      icon: Icon(
                        Icons.image_outlined,
                        color: _images.length >= _kMaxCommentImages
                            ? const Color(0xFFB2B2B2)
                            : _kWeChatName,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: fieldBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          maxLength: 500,
                          maxLines: null,
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          style: TextStyle(color: ink, fontSize: 15),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            isDense: true,
                            counterText: '',
                            border: InputBorder.none,
                            hintText: reply != null && reply.isNotEmpty
                                ? l10n.momentsReplyHint
                                : l10n.momentsCommentHint,
                            hintStyle: const TextStyle(
                              color: Color(0xFFB2B2B2),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: FilledButton(
                        onPressed: _canSend ? _submit : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kWeChatGreen,
                          disabledBackgroundColor:
                              _kWeChatGreen.withValues(alpha: 0.35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          reply != null && reply.isNotEmpty
                              ? l10n.momentsReply
                              : l10n.momentsPost,
                          style: const TextStyle(fontSize: 14),
                        ),
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
