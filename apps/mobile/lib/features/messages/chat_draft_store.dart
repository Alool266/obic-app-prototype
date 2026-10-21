// Made by Dr Ali
// WeChat-style composer drafts — local per thread (survive back navigation).

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ChatDraftStore {
  ChatDraftStore._();
  static final ChatDraftStore instance = ChatDraftStore._();

  Future<File> _file() async {
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/obic_chat_drafts');
    if (!await d.exists()) await d.create(recursive: true);
    return File('${d.path}/drafts.json');
  }

  Future<Map<String, String>> _loadAll() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      final raw = jsonDecode(await f.readAsString());
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAll(Map<String, String> map) async {
    try {
      final f = await _file();
      final cleaned = <String, String>{};
      for (final e in map.entries) {
        final t = e.value.trim();
        if (t.isNotEmpty) cleaned[e.key] = e.value;
      }
      await f.writeAsString(jsonEncode(cleaned));
    } catch (_) {}
  }

  Future<String?> load(String threadId) async {
    final all = await _loadAll();
    final v = all[threadId];
    if (v == null || v.trim().isEmpty) return null;
    return v;
  }

  Future<void> save(String threadId, String text) async {
    final all = await _loadAll();
    if (text.trim().isEmpty) {
      all.remove(threadId);
    } else {
      all[threadId] = text;
    }
    await _saveAll(all);
  }

  Future<void> clear(String threadId) async {
    final all = await _loadAll();
    all.remove(threadId);
    await _saveAll(all);
  }

  Future<Map<String, String>> loadAll() => _loadAll();
}
