// Made by Dr Ali
// Disk copy of photos already opened — chats, Moments, avatars — so they show offline.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'connectivity_service.dart';
import 'media_url.dart';
import 'obic_http.dart';

class MediaDiskCache {
  MediaDiskCache._();
  static final MediaDiskCache instance = MediaDiskCache._();

  final Map<String, Future<File?>> _inflight = {};
  final List<String> _prefetchQueue = [];
  int _prefetchRunning = 0;
  Directory? _dir;

  Future<Directory> directory() async {
    final cached = _dir;
    if (cached != null) return cached;
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/obic_media_cache');
    if (!await d.exists()) await d.create(recursive: true);
    _dir = d;
    return d;
  }

  /// Local file when this URL was saved before, or after a successful download.
  Future<File?> resolve(String rawUrl) {
    final url = resolveMediaUrl(rawUrl);
    if (!_cacheable(url)) return Future.value(null);
    final pending = _inflight[url];
    if (pending != null) return pending;
    final run = _resolve(url);
    _inflight[url] = run;
    return run.whenComplete(() => _inflight.remove(url));
  }

  Future<void> prefetch(Iterable<String?> rawUrls) async {
    if (ConnectivityService.instance.isOffline) return;
    final seen = <String>{};
    var queued = 0;
    for (final raw in rawUrls) {
      if (queued >= 40) break;
      final url = resolveMediaUrl(raw);
      if (!_cacheable(url) || !seen.add(url)) continue;
      if (_isVideo(url)) continue;
      if (_prefetchQueue.contains(url)) continue;
      queued++;
      _prefetchQueue.add(url);
    }
    _pumpPrefetch();
  }

  /// Three at a time. A burst of new TLS handshakes was stalling API calls
  /// on iOS while avatars downloaded.
  void _pumpPrefetch() {
    while (_prefetchRunning < 3 && _prefetchQueue.isNotEmpty) {
      final url = _prefetchQueue.removeAt(0);
      _prefetchRunning++;
      unawaited(
        resolve(url).whenComplete(() {
          _prefetchRunning--;
          _pumpPrefetch();
        }),
      );
    }
  }

  /// Walk chat / Moments JSON for photo fields.
  Future<void> prefetchMaps(List<Map<String, dynamic>> rows) {
    return prefetch(_collect(rows));
  }

  Future<int> sizeBytes() async {
    final parts = await sizeByKind();
    var total = 0;
    for (final value in parts.values) {
      total += value;
    }
    return total;
  }

  /// images, videos, voice, files — by the saved file extension.
  Future<Map<String, int>> sizeByKind() async {
    final out = <String, int>{
      'images': 0,
      'videos': 0,
      'voice': 0,
      'files': 0,
    };
    try {
      final d = await directory();
      if (!await d.exists()) return out;
      await for (final e in d.list(followLinks: false)) {
        if (e is! File) continue;
        final len = await e.length();
        final lower = e.path.toLowerCase();
        final kind = _kindForPath(lower);
        out[kind] = (out[kind] ?? 0) + len;
      }
    } catch (_) {}
    return out;
  }

  String _kindForPath(String lower) {
    const images = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic'];
    const videos = ['.mp4', '.mov', '.m4v', '.webm'];
    const voice = ['.m4a', '.aac', '.mp3', '.wav', '.ogg', '.caf'];
    for (final ext in images) {
      if (lower.endsWith(ext)) return 'images';
    }
    for (final ext in videos) {
      if (lower.endsWith(ext)) return 'videos';
    }
    for (final ext in voice) {
      if (lower.endsWith(ext)) return 'voice';
    }
    if (lower.endsWith('.img')) return 'images';
    return 'files';
  }

  /// Drop cached media older than [days]. Chats and login stay.
  Future<int> purgeOlderThan(int days) async {
    if (days <= 0) return 0;
    var freed = 0;
    try {
      final d = await directory();
      if (!await d.exists()) return 0;
      final cutoff = DateTime.now().subtract(Duration(days: days));
      await for (final e in d.list(followLinks: false)) {
        if (e is! File) continue;
        final modified = await e.lastModified();
        if (modified.isAfter(cutoff)) continue;
        final len = await e.length();
        await e.delete();
        freed += len;
      }
    } catch (_) {}
    return freed;
  }

  Future<void> clear() async {
    try {
      final d = await directory();
      if (await d.exists()) await d.delete(recursive: true);
    } catch (_) {}
    _dir = null;
  }

  Future<File?> _resolve(String url) async {
    final file = await _fileFor(url);
    if (await file.exists() && await file.length() > 0) return file;
    if (ConnectivityService.instance.isOffline) return null;
    try {
      final res = await obicHttpClient()
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
      if (res.bodyBytes.length > 12 * 1024 * 1024) return null;
      final tmp = File('${file.path}.part');
      await tmp.writeAsBytes(res.bodyBytes, flush: true);
      if (await file.exists()) await file.delete();
      await tmp.rename(file.path);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<File> _fileFor(String url) async {
    final d = await directory();
    return File('${d.path}/${_key(url)}.img');
  }

  bool _cacheable(String url) {
    if (url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  bool _isVideo(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v') ||
        path.endsWith('.webm');
  }

  Iterable<String> _collect(Object? node) sync* {
    if (node is Map) {
      for (final entry in node.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is String && _urlKey(key)) {
          yield value;
        } else {
          yield* _collect(value);
        }
      }
    } else if (node is List) {
      for (final item in node) {
        yield* _collect(item);
      }
    }
  }

  bool _urlKey(String key) {
    return key == 'url' ||
        key == 'avatarUrl' ||
        key == 'imageUrl' ||
        key == 'attachmentUrl' ||
        key == 'coverUrl' ||
        key == 'momentsCoverUrl' ||
        key == 'thumbUrl' ||
        key == 'authorAvatarUrl' ||
        key == 'senderAvatarUrl';
  }

  String _key(String url) {
    var h = 0xcbf29ce484222325;
    for (final b in utf8.encode(url)) {
      h ^= b;
      h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return h.toRadixString(16);
  }
}
