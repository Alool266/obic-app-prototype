// Made by Dr Ali
// WeChat-style action grid sheets for Album / Camera / Video.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../theme/obic_colors.dart';

typedef WechatMediaAction = ({String id, IconData icon, String label});

/// Navy tile grid matching chat’s “+” attach panel.
Future<String?> showWechatActionGrid(
  BuildContext context, {
  required String title,
  required List<WechatMediaAction> items,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: BoxDecoration(
            color: ObicColors.navy,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.88,
                  children: [
                    for (final item in items)
                      InkWell(
                        onTap: () => Navigator.pop(ctx, item.id),
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: ObicColors.navySoft,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: ObicColors.blue.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Icon(
                                item.icon,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
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
}

/// Album vs Record for video attach.
Future<ImageSource?> showWechatVideoSourceSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showWechatActionGrid(
    context,
    title: l10n.mediaVideoTitle,
    items: [
      (
        id: 'gallery',
        icon: Icons.photo_library_outlined,
        label: l10n.mediaFromAlbum,
      ),
      (
        id: 'camera',
        icon: Icons.videocam_outlined,
        label: l10n.mediaRecordVideo,
      ),
    ],
  ).then((id) {
    switch (id) {
      case 'gallery':
        return ImageSource.gallery;
      case 'camera':
        return ImageSource.camera;
      default:
        return null;
    }
  });
}

/// Moments camera-button entry: Album / Camera / Video / Text.
Future<String?> showMomentsCreateSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showWechatActionGrid(
    context,
    title: l10n.momentsCreate,
    items: [
      (
        id: 'album',
        icon: Icons.photo_outlined,
        label: l10n.mediaAlbum,
      ),
      (
        id: 'camera',
        icon: Icons.photo_camera_outlined,
        label: l10n.mediaCamera,
      ),
      (
        id: 'video',
        icon: Icons.movie_creation_outlined,
        label: l10n.mediaVideo,
      ),
      (
        id: 'text',
        icon: Icons.edit_outlined,
        label: l10n.momentsTextOnly,
      ),
    ],
  );
}

/// Compose “+” attach: Album / Camera / Video / Files.
Future<String?> showMomentsComposeAttachSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showWechatActionGrid(
    context,
    title: l10n.momentsAddMedia,
    items: [
      (
        id: 'album',
        icon: Icons.photo_outlined,
        label: l10n.mediaAlbum,
      ),
      (
        id: 'camera',
        icon: Icons.photo_camera_outlined,
        label: l10n.mediaCamera,
      ),
      (
        id: 'video',
        icon: Icons.movie_creation_outlined,
        label: l10n.mediaVideo,
      ),
      (
        id: 'files',
        icon: Icons.folder_open_outlined,
        label: l10n.momentsAddFiles,
      ),
    ],
  );
}
