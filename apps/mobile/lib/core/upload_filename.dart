// Made by Dr Ali
// Normalize picker paths so multipart uploads always carry an allowed extension.

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

/// Android Photo Picker / image_picker sometimes yields cache names without an
/// extension (`scaled_1234`). Trial API rejects those as `File type not allowed`.
String uploadFilenameForImage(XFile shot) {
  final raw = (shot.name.trim().isNotEmpty ? shot.name : p.basename(shot.path))
      .trim();
  final base = raw.isEmpty ? 'photo' : raw;
  if (_hasImageExt(base)) return base;

  final pathExt = p.extension(shot.path).toLowerCase();
  if (_isImageExt(pathExt)) {
    return '${p.basenameWithoutExtension(base)}$pathExt';
  }

  final mime = (shot.mimeType ?? '').toLowerCase();
  final fromMime = _extForImageMime(mime);
  if (fromMime != null) {
    return '${p.basenameWithoutExtension(base)}$fromMime';
  }

  // image_picker compresses to JPEG when imageQuality/maxWidth are set.
  return '${p.basenameWithoutExtension(base)}.jpg';
}

/// Same normalization for camera / gallery video picks.
String uploadFilenameForVideo(XFile shot) {
  final raw = (shot.name.trim().isNotEmpty ? shot.name : p.basename(shot.path))
      .trim();
  final base = raw.isEmpty ? 'video' : raw;
  if (_hasVideoExt(base)) return base;

  final pathExt = p.extension(shot.path).toLowerCase();
  if (_isVideoExt(pathExt)) {
    return '${p.basenameWithoutExtension(base)}$pathExt';
  }

  final mime = (shot.mimeType ?? '').toLowerCase();
  final fromMime = _extForVideoMime(mime);
  if (fromMime != null) {
    return '${p.basenameWithoutExtension(base)}$fromMime';
  }

  return '${p.basenameWithoutExtension(base)}.mp4';
}

bool _hasImageExt(String name) {
  return _isImageExt(p.extension(name).toLowerCase());
}

bool _isImageExt(String ext) {
  return const {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.heic',
  }.contains(ext);
}

bool _hasVideoExt(String name) {
  return _isVideoExt(p.extension(name).toLowerCase());
}

bool _isVideoExt(String ext) {
  return const {'.mp4', '.mov', '.m4v', '.webm'}.contains(ext);
}

String? _extForImageMime(String mime) {
  if (mime.contains('jpeg') || mime.contains('jpg')) return '.jpg';
  if (mime.contains('png')) return '.png';
  if (mime.contains('webp')) return '.webp';
  if (mime.contains('gif')) return '.gif';
  if (mime.contains('heic') || mime.contains('heif')) return '.heic';
  return null;
}

String? _extForVideoMime(String mime) {
  if (mime.contains('mp4') || mime.contains('mpeg')) return '.mp4';
  if (mime.contains('quicktime')) return '.mov';
  if (mime.contains('webm')) return '.webm';
  if (mime.contains('m4v')) return '.m4v';
  return null;
}
