// Made by Dr Ali
// Remembers service slugs opened on this phone. No API call.

import 'package:shared_preferences/shared_preferences.dart';

class RecentServicesStore {
  static const _key = 'obic_recent_service_slugs_v1';
  static const _max = 6;

  Future<List<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> remember(String slug) async {
    if (slug.isEmpty) return load();
    final current = await load();
    final next = <String>[
      slug,
      ...current.where((item) => item != slug),
    ].take(_max).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, next);
    } catch (_) {}
    return next;
  }
}
