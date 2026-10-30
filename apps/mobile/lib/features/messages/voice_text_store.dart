// Made by Dr Ali
// Keeps a voice-note transcript so the next open does not convert it again.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class VoiceTextMemory {
  const VoiceTextMemory({this.text = '', this.translation = ''});

  final String text;
  final String translation;

  static const _key = 'obic_voice_text_v1';

  static Future<Map<String, VoiceTextMemory>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, VoiceTextMemory>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        out[entry.key.toString()] = VoiceTextMemory(
          text: value['text']?.toString() ?? '',
          translation: value['translation']?.toString() ?? '',
        );
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(Map<String, VoiceTextMemory> all) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, Map<String, String>>{};
    for (final entry in all.entries) {
      if (entry.key.isEmpty) continue;
      if (entry.value.text.isEmpty && entry.value.translation.isEmpty) continue;
      encoded[entry.key] = {
        'text': entry.value.text,
        'translation': entry.value.translation,
      };
    }
    await prefs.setString(_key, jsonEncode(encoded));
  }
}
