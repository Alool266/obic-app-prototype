// Made by Dr Ali
// Shared WeChat-style media pick helpers (chat + Moments).

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'upload_filename.dart';

/// Trial Postgres bytea ceiling — larger files are disk-only (ephemeral on Render).
const int kMediaUploadDurableMaxBytes = 12 * 1024 * 1024;

/// API multipart ceiling (uploads controller).
const int kMediaUploadHardMaxBytes = 80 * 1024 * 1024;

/// Default chat / Moments short-clip length.
const Duration kMediaVideoMaxDuration = Duration(seconds: 60);

/// Moments / Channel longer clip allowance.
const Duration kMomentsVideoMaxDuration = Duration(minutes: 3);

class PickedLocalMedia {
  const PickedLocalMedia({
    required this.path,
    required this.filename,
    required this.kind,
  });

  final String path;
  final String filename;

  /// `image` | `video`
  final String kind;
}

/// Album multi-select (WeChat Photos / Album).
Future<List<PickedLocalMedia>> pickAlbumImages(
  ImagePicker picker, {
  int imageQuality = 85,
  double? maxWidth = 2400,
  int? limit,
}) async {
  final shots = await picker.pickMultiImage(
    imageQuality: imageQuality,
    maxWidth: maxWidth,
    limit: limit,
  );
  return [
    for (final x in shots)
      PickedLocalMedia(
        path: x.path,
        filename: uploadFilenameForImage(x),
        kind: 'image',
      ),
  ];
}

/// Device camera still photo.
Future<PickedLocalMedia?> takeCameraPhoto(
  ImagePicker picker, {
  int imageQuality = 85,
  double? maxWidth = 2400,
}) async {
  final shot = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: imageQuality,
    maxWidth: maxWidth,
  );
  if (shot == null) return null;
  return PickedLocalMedia(
    path: shot.path,
    filename: uploadFilenameForImage(shot),
    kind: 'image',
  );
}

/// Gallery or camera video within [maxDuration].
Future<PickedLocalMedia?> pickOrRecordVideo(
  ImagePicker picker, {
  required ImageSource source,
  Duration maxDuration = kMediaVideoMaxDuration,
}) async {
  final shot = await picker.pickVideo(
    source: source,
    maxDuration: maxDuration,
  );
  if (shot == null) return null;
  return PickedLocalMedia(
    path: shot.path,
    filename: uploadFilenameForVideo(shot),
    kind: 'video',
  );
}

Future<int?> localFileLength(String path) async {
  try {
    return await File(path).length();
  } catch (_) {
    return null;
  }
}

/// Result of size gate: `ok`, `too_large`, `unreadable`, or `large_warning`.
String classifyVideoSize(int? byteLength) {
  if (byteLength == null) return 'unreadable';
  if (byteLength > kMediaUploadHardMaxBytes) return 'too_large';
  if (byteLength > kMediaUploadDurableMaxBytes) return 'large_warning';
  return 'ok';
}

/// Map picker / permission failures to stable tokens for localized copy.
///
/// Tokens: `camera_denied`, `photos_denied`, `mic_denied`, `cancelled`, `failed`.
String classifyMediaPickError(Object error) {
  if (error is PlatformException) {
    final code = error.code.toLowerCase();
    final msg = '${error.message ?? ''} ${error.details ?? ''}'.toLowerCase();
    if (code.contains('camera') ||
        msg.contains('camera') ||
        code == 'camera_access_denied' ||
        code == 'cameraaccessdenied') {
      return 'camera_denied';
    }
    if (code.contains('photo') ||
        code.contains('gallery') ||
        code.contains('library') ||
        msg.contains('photo') ||
        msg.contains('gallery') ||
        msg.contains('library') ||
        code == 'photo_access_denied') {
      return 'photos_denied';
    }
    if (code.contains('micro') ||
        msg.contains('micro') ||
        code == 'microphone_access_denied') {
      return 'mic_denied';
    }
    if (code == 'multiple_request' || code.contains('cancel')) {
      return 'cancelled';
    }
  }
  final raw = error.toString().toLowerCase();
  if (raw.contains('camera')) return 'camera_denied';
  if (raw.contains('photo') || raw.contains('gallery') || raw.contains('library')) {
    return 'photos_denied';
  }
  if (raw.contains('micro')) return 'mic_denied';
  if (raw.contains('cancel')) return 'cancelled';
  return 'failed';
}

String mediaKindFromFilename(String name) {
  final lower = name.toLowerCase();
  final ext = p.extension(lower);
  if (const {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'}.contains(ext)) {
    return 'image';
  }
  if (const {'.mp4', '.mov', '.m4v', '.webm'}.contains(ext)) {
    return 'video';
  }
  return 'file';
}
