// Made by Dr Ali
// Local snapshots for WeChat-style offline browse (threads / messages / moments).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'media_disk_cache.dart';

class OfflineCacheStore {
  OfflineCacheStore._();
  static final OfflineCacheStore instance = OfflineCacheStore._();

  /// One write at a time per file so a full save and a live append cannot
  /// clobber each other.
  final Map<String, Future<void>> _writeTails = {};

  Future<T> _serialized<T>(String name, Future<T> Function() action) {
    final prev = _writeTails[name] ?? Future<void>.value();
    final gate = Completer<void>();
    _writeTails[name] = gate.future;
    return prev.catchError((Object _) {}).then((_) => action()).whenComplete(() {
      if (!gate.isCompleted) gate.complete();
    });
  }

  Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/obic_offline_cache');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<File> _file(String name) async {
    final d = await _dir();
    return File('${d.path}/$name.json');
  }

  Future<void> _writeList(String name, List<Map<String, dynamic>> rows) async {
    try {
      final f = await _file(name);
      await f.writeAsString(jsonEncode(rows));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>?> _readList(String name) async {
    try {
      final f = await _file(name);
      if (!await f.exists()) return null;
      final raw = jsonDecode(await f.readAsString());
      if (raw is! List) return null;
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeMap(String name, Map<String, dynamic> data) async {
    try {
      final f = await _file(name);
      await f.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _readMap(String name) async {
    try {
      final f = await _file(name);
      if (!await f.exists()) return null;
      final raw = jsonDecode(await f.readAsString());
      if (raw is! Map) return null;
      return Map<String, dynamic>.from(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveThreads(String userId, List<Map<String, dynamic>> rows) async {
    await _writeList('threads_${_safe(userId)}', rows);
    await MediaDiskCache.instance.prefetchMaps(rows);
  }

  Future<List<Map<String, dynamic>>?> loadThreads(String userId) =>
      _readList('threads_${_safe(userId)}');

  Future<void> saveMessages(
    String threadId,
    List<Map<String, dynamic>> rows,
  ) {
    final name = 'msgs_${_safe(threadId)}';
    return _serialized(name, () async {
      await _writeList(name, rows);
      unawaited(MediaDiskCache.instance.prefetchMaps(rows));
    });
  }

  /// Insert or replace one message without dropping the rest of the thread.
  /// Search can find the text before the next full reload.
  Future<void> appendMessage(
    String threadId,
    Map<String, dynamic> message,
  ) {
    final name = 'msgs_${_safe(threadId)}';
    return _serialized(name, () async {
      final existing = await _readList(name) ?? <Map<String, dynamic>>[];
      final next = [...existing];
      final id = message['id']?.toString() ?? '';
      final row = Map<String, dynamic>.from(message);
      if (id.isNotEmpty) {
        final i = next.indexWhere((m) => m['id']?.toString() == id);
        if (i >= 0) {
          next[i] = {...next[i], ...row};
        } else {
          next.add(row);
        }
      } else {
        next.add(row);
      }
      await _writeList(name, next);
    });
  }

  Future<List<Map<String, dynamic>>?> loadMessages(String threadId) =>
      _readList('msgs_${_safe(threadId)}');

  Future<void> saveMoments(String userId, List<Map<String, dynamic>> rows) async {
    await _writeList('moments_${_safe(userId)}', rows);
    await MediaDiskCache.instance.prefetchMaps(rows);
  }

  Future<void> saveFriends(String userId, List<Map<String, dynamic>> rows) async {
    await _writeList('friends_${_safe(userId)}', rows);
    await MediaDiskCache.instance.prefetchMaps(rows);
  }

  Future<List<Map<String, dynamic>>?> loadFriends(String userId) =>
      _readList('friends_${_safe(userId)}');

  /// Last Discover hub payload (Moments row + Channels tip) for offline open.
  Future<void> saveDiscover(String userId, Map<String, dynamic> preview) async {
    await _writeMap('discover_${_safe(userId)}', preview);
    await MediaDiskCache.instance.prefetchMaps([preview]);
  }

  Future<Map<String, dynamic>?> loadDiscover(String userId) =>
      _readMap('discover_${_safe(userId)}');

  /// Album header (name, avatar, cover) so My Posts still renders offline.
  Future<void> saveAlbumProfile(String userId, Map<String, dynamic> profile) async {
    await _writeMap('album_profile_${_safe(userId)}', profile);
    await MediaDiskCache.instance.prefetchMaps([profile]);
  }

  Future<Map<String, dynamic>?> loadAlbumProfile(String userId) =>
      _readMap('album_profile_${_safe(userId)}');

  Future<List<Map<String, dynamic>>?> loadMoments(String userId) =>
      _readList('moments_${_safe(userId)}');

  /// Chat, contact, and profile snapshots. Not media files.
  Future<int> snapshotBytes() async {
    try {
      final d = await _dir();
      if (!await d.exists()) return 0;
      var total = 0;
      await for (final e in d.list(recursive: true, followLinks: false)) {
        if (e is File) total += await e.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<int> cacheSizeBytes() async {
    try {
      final d = await _dir();
      if (!await d.exists()) return 0;
      var total = 0;
      await for (final e in d.list(recursive: true, followLinks: false)) {
        if (e is File) total += await e.length();
      }
      return total + await MediaDiskCache.instance.sizeBytes();
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearAll() async {
    try {
      final d = await _dir();
      if (await d.exists()) await d.delete(recursive: true);
    } catch (_) {}
    await MediaDiskCache.instance.clear();
  }

  String _safe(String id) =>
      id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}
