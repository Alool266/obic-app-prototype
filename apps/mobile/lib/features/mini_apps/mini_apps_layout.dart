// Made by Dr Ali
// Per-user mini-app order, pins, and hidden tiles.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mini_apps_catalog.dart';

class MiniAppLayout {
  const MiniAppLayout({
    this.order = const [],
    this.pinned = const {},
    this.hidden = const {},
  });

  final List<String> order;
  final Set<String> pinned;
  final Set<String> hidden;

  static const empty = MiniAppLayout();
}

class MiniAppLayoutStore {
  MiniAppLayoutStore(this.userId);

  final String userId;

  String get _key => 'obic_mini_layout_${userId.isEmpty ? 'guest' : userId}';

  Future<MiniAppLayout> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return MiniAppLayout.empty;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return MiniAppLayout.empty;
      final order = (json['order'] as List?)?.whereType<String>().toList() ?? const [];
      final pinned = (json['pinned'] as List?)?.whereType<String>().toSet() ?? const {};
      final hidden = (json['hidden'] as List?)?.whereType<String>().toSet() ?? const {};
      return MiniAppLayout(order: order, pinned: pinned, hidden: hidden);
    } catch (_) {
      return MiniAppLayout.empty;
    }
  }

  Future<void> save(MiniAppLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'order': layout.order,
        'pinned': layout.pinned.toList(),
        'hidden': layout.hidden.toList(),
      }),
    );
  }
}

List<MiniAppEntry> applyMiniAppLayout(
  List<MiniAppEntry> apps,
  MiniAppLayout layout,
) {
  final visible = apps.where((app) => !layout.hidden.contains(app.id)).toList();
  final index = <String, int>{
    for (var i = 0; i < layout.order.length; i++) layout.order[i]: i,
  };
  visible.sort((a, b) {
    final ap = layout.pinned.contains(a.id);
    final bp = layout.pinned.contains(b.id);
    if (ap != bp) return ap ? -1 : 1;
    final ai = index[a.id];
    final bi = index[b.id];
    if (ai == null && bi == null) return 0;
    if (ai == null) return 1;
    if (bi == null) return -1;
    return ai.compareTo(bi);
  });
  return visible;
}

bool miniAppMatchesQuery(MiniAppEntry app, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return app.name.toLowerCase().contains(q) ||
      app.description.toLowerCase().contains(q) ||
      app.keywords.toLowerCase().contains(q);
}
