// Made by Dr Ali
// Download Moments media to the device Photos library (or app docs for files).

import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/media_disk_cache.dart';
import '../../core/media_url.dart';

Future<void> saveImageToGallery(String url) async {
  if (!await Gal.hasAccess()) {
    final granted = await Gal.requestAccess();
    if (!granted && !await Gal.hasAccess()) {
      throw StateError('gallery');
    }
  }
  final bytes = await _imageBytesForGallery(url);
  if (bytes.isEmpty) throw StateError('empty');
  await Gal.putImageBytes(
    bytes,
    name: 'obic_${DateTime.now().millisecondsSinceEpoch}',
  );
}

Future<void> saveVideoToGallery(String url) async {
  final file = await _downloadToTemp(url, preferredExt: '.mp4');
  await Gal.putVideo(file.path, album: 'OBIC');
  try {
    await file.delete();
  } catch (_) {}
}

/// Files that are not photos/videos — save into app Documents and return path.
Future<String> saveFileToDocuments(String url, {String? filename}) async {
  final name = filename ?? p.basename(Uri.parse(url).path);
  final dir = await getApplicationDocumentsDirectory();
  final dest = File(p.join(dir.path, 'obic_downloads', name));
  await dest.parent.create(recursive: true);
  final bytes = await _downloadBytes(url);
  await dest.writeAsBytes(bytes, flush: true);
  return dest.path;
}

/// Disk cache first (ObicCachedImage / MediaDiskCache), then the network URL.
Future<Uint8List> _imageBytesForGallery(String url) async {
  final local = _existingLocalFile(url);
  if (local != null) {
    final bytes = await local.readAsBytes();
    if (bytes.isNotEmpty) return bytes;
  }
  final resolved = resolveMediaUrl(url);
  final target = resolved.isEmpty ? url : resolved;
  final cached = await MediaDiskCache.instance.resolve(target);
  if (cached != null && await cached.exists()) {
    final bytes = await cached.readAsBytes();
    if (bytes.isNotEmpty) return bytes;
  }
  return _downloadBytes(target);
}

File? _existingLocalFile(String url) {
  if (url.startsWith('file://')) {
    final file = File(Uri.parse(url).toFilePath());
    return file.existsSync() ? file : null;
  }
  if (url.startsWith('/') && !url.startsWith('//')) {
    final file = File(url);
    return file.existsSync() ? file : null;
  }
  return null;
}

Future<Uint8List> _downloadBytes(String url) async {
  final res = await http.get(Uri.parse(url));
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Download failed (${res.statusCode})');
  }
  return res.bodyBytes;
}

Future<File> _downloadToTemp(String url, {String preferredExt = ''}) async {
  final bytes = await _downloadBytes(url);
  final tmp = await getTemporaryDirectory();
  var ext = p.extension(Uri.parse(url).path);
  if (ext.isEmpty) ext = preferredExt;
  final file = File(
    p.join(tmp.path, 'obic_${DateTime.now().millisecondsSinceEpoch}$ext'),
  );
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
