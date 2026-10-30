// Made by Dr Ali
// Delete-for-me — message ids hidden on this device only. No server wipe.

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ChatHiddenStore {
  ChatHiddenStore._();
  static final ChatHiddenStore instance = ChatHiddenStore._();

  Future<File> _file() async {
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/obic_chat_hidden');
    if (!await d.exists()) await d.create(recursive: true);
    return File('${d.path}/hidden.json');
  }

  Future<Map<String, List<String>>> _loadAll() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      final raw = jsonDecode(await f.readAsString());
      if (raw is! Map) return {};
      final out = <String, List<String>>{};
      for (final entry in raw.entries) {
        final ids = entry.value;
        if (ids is! List) continue;
        out[entry.key.toString()] = [
          for (final id in ids)
            if (id != null && id.toString().isNotEmpty) id.toString(),
        ];
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAll(Map<String, List<String>> map) async {
    try {
      final f = await _file();
      final cleaned = <String, List<String>>{};
      for (final entry in map.entries) {
        if (entry.value.isEmpty) continue;
        cleaned[entry.key] = entry.value;
      }
      await f.writeAsString(jsonEncode(cleaned));
    } catch (_) {}
  }

  Future<Set<String>> idsFor(String threadId) async {
    final all = await _loadAll();
    return {...?all[threadId]};
  }

  Future<void> hide(String threadId, String messageId) async {
    if (messageId.isEmpty) return;
    final all = await _loadAll();
    final ids = {...?all[threadId], messageId}.toList();
    all[threadId] = ids;
    await _saveAll(all);
  }

  Future<void> clearThread(String threadId) async {
    final all = await _loadAll();
    all.remove(threadId);
    await _saveAll(all);
  }
}
