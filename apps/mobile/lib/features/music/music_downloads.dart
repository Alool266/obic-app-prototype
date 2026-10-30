// Made by Dr Ali
// Songs saved on the phone for offline play. Licence is checked by the caller.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'music_library.dart';

class MusicDownloads {
  MusicDownloads._();
  static final MusicDownloads instance = MusicDownloads._();
  static const _indexKey = 'obic_music_download_index';

  Future<Directory> directory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/obic_music_downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _safe(String id) => id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  Future<File> fileFor(MusicTrack track) async {
    final dir = await directory();
    final uri = Uri.tryParse(track.audioUrl);
    var ext = p.extension(uri?.path ?? '');
    if (ext.isEmpty || ext.length > 5) ext = '.mp3';
    return File('${dir.path}/${_safe(track.id)}$ext');
  }

  Future<bool> has(MusicTrack track) async {
    final file = await fileFor(track);
    return await file.exists() && await file.length() > 0;
  }

  Future<File?> existing(MusicTrack track) async {
    final file = await fileFor(track);
    if (await file.exists() && await file.length() > 0) return file;
    return null;
  }

  /// Returns the local file, or null when the source refused the download.
  Future<File?> download(MusicTrack track) async {
    final url = track.audioUrl;
    if (!url.startsWith('https://')) return null;
    final file = await fileFor(track);
    if (await file.exists() && await file.length() > 0) return file;
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 40));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
      final tmp = File('${file.path}.part');
      await tmp.writeAsBytes(res.bodyBytes, flush: true);
      if (await file.exists()) await file.delete();
      await tmp.rename(file.path);
      await _remember(track);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<List<MusicTrack>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_indexKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final saved = <MusicTrack>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final track = MusicTrack.fromJson(Map<String, dynamic>.from(item));
      if (track == null) continue;
      if (await has(track)) saved.add(track);
    }
    return saved;
  }

  Future<void> _remember(MusicTrack track) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_indexKey);
    final rows = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map && item['id'] != track.id) {
            rows.add(Map<String, dynamic>.from(item));
          }
        }
      }
    }
    rows.insert(0, track.toJson());
    await prefs.setString(_indexKey, jsonEncode(rows));
  }

  Future<int> sizeBytes() async {
    try {
      final dir = await directory();
      var total = 0;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) total += await entity.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<int> clear() async {
    final before = await sizeBytes();
    try {
      final dir = await directory();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_indexKey);
    } catch (_) {}
    return before;
  }
}
