// Made by Dr Ali
// Per-user mini-app order, pins, and hidden tiles — local + home-layout API.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../home/home_layout_api.dart';
import '../home/home_service_layout.dart';
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

  bool get isEmpty =>
      order.isEmpty && pinned.isEmpty && hidden.isEmpty;

  Map<String, dynamic> toJson() => {
        'order': order,
        'favorites': pinned.toList(),
        'hidden': hidden.toList(),
      };

  factory MiniAppLayout.fromJson(Map<String, dynamic> json) {
    final order =
        (json['order'] as List?)?.whereType<String>().toList() ?? const [];
    final pinned = (json['favorites'] as List?)?.whereType<String>().toSet() ??
        (json['pinned'] as List?)?.whereType<String>().toSet() ??
        const {};
    final hidden =
        (json['hidden'] as List?)?.whereType<String>().toSet() ?? const {};
    return MiniAppLayout(order: order, pinned: pinned, hidden: hidden);
  }
}

class MiniAppLayoutStore {
  MiniAppLayoutStore(this.userId, {HomeLayoutApi? api})
      : _api = api ?? HomeLayoutApi();

  final String userId;
  final HomeLayoutApi _api;

  String get _key => 'obic_mini_layout_${userId.isEmpty ? 'guest' : userId}';

  Future<MiniAppLayout> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return MiniAppLayout.empty;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return MiniAppLayout.empty;
      return MiniAppLayout.fromJson(Map<String, dynamic>.from(json));
    } catch (_) {
      return MiniAppLayout.empty;
    }
  }

  Future<void> saveLocal(MiniAppLayout layout) async {
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

  /// Local first; when [accessToken] is set, pull server miniApps and merge.
  Future<MiniAppLayout> load({String? accessToken}) async {
    final local = await loadLocal();
    if (accessToken == null || accessToken.isEmpty) return local;
    try {
      final remoteHome = await _api.fetch(accessToken);
      final remote = MiniAppLayout(
        order: remoteHome.miniOrder,
        pinned: remoteHome.miniFavorites,
        hidden: remoteHome.miniHidden,
      );
      if (remote.isEmpty) {
        if (!local.isEmpty) {
          await save(local, accessToken: accessToken);
        }
        return local;
      }
      await saveLocal(remote);
      return remote;
    } catch (_) {
      return local;
    }
  }

  Future<void> save(
    MiniAppLayout layout, {
    String? accessToken,
  }) async {
    await saveLocal(layout);
    if (accessToken == null || accessToken.isEmpty) return;
    try {
      final current = await _api.fetch(accessToken);
      final next = HomeServiceLayout(
        order: current.order,
        favorites: current.favorites,
        hidden: current.hidden,
        miniOrder: layout.order,
        miniFavorites: layout.pinned,
        miniHidden: layout.hidden,
      );
      await _api.put(accessToken: accessToken, layout: next);
    } catch (_) {
      // Offline — local already saved.
    }
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
