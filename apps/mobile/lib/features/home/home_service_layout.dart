// Made by Dr Ali
// Per-user Home mega-icon order, favorites, and hidden tiles.
// Guest: SharedPreferences. Logged-in: local cache + server sync.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/service_catalog.dart';
import 'home_layout_api.dart';

class HomeServiceLayout {
  const HomeServiceLayout({
    this.order = const [],
    this.favorites = const {},
    this.hidden = const {},
  });

  final List<String> order;
  final Set<String> favorites;
  final Set<String> hidden;

  static const empty = HomeServiceLayout();

  bool get isEmpty =>
      order.isEmpty && favorites.isEmpty && hidden.isEmpty;

  Map<String, dynamic> toJson() => {
        'order': order,
        'favorites': favorites.toList(),
        'hidden': hidden.toList(),
      };

  factory HomeServiceLayout.fromJson(Map<String, dynamic> json) {
    final order =
        (json['order'] as List?)?.whereType<String>().toList() ?? const [];
    final favorites =
        (json['favorites'] as List?)?.whereType<String>().toSet() ?? const {};
    final hidden =
        (json['hidden'] as List?)?.whereType<String>().toSet() ?? const {};
    return HomeServiceLayout(
      order: order,
      favorites: favorites,
      hidden: hidden,
    );
  }

  HomeServiceLayout copyWith({
    List<String>? order,
    Set<String>? favorites,
    Set<String>? hidden,
  }) {
    return HomeServiceLayout(
      order: order ?? this.order,
      favorites: favorites ?? this.favorites,
      hidden: hidden ?? this.hidden,
    );
  }
}

class HomeServiceLayoutStore {
  HomeServiceLayoutStore({
    required this.userId,
    HomeLayoutApi? api,
  }) : _api = api ?? HomeLayoutApi();

  final String userId;
  final HomeLayoutApi _api;

  String get _key =>
      'obic_home_layout_${userId.isEmpty ? 'guest' : userId}';

  Future<HomeServiceLayout> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return HomeServiceLayout.empty;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return HomeServiceLayout.empty;
      return HomeServiceLayout.fromJson(Map<String, dynamic>.from(json));
    } catch (_) {
      return HomeServiceLayout.empty;
    }
  }

  Future<void> saveLocal(HomeServiceLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(layout.toJson()));
  }

  /// Local first; when [accessToken] is set, pull server and merge if local empty.
  Future<HomeServiceLayout> load({String? accessToken}) async {
    final local = await loadLocal();
    if (accessToken == null || accessToken.isEmpty) return local;
    try {
      final remote = await _api.fetch(accessToken);
      if (remote.isEmpty) {
        if (!local.isEmpty) {
          await _api.put(accessToken: accessToken, layout: local);
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
    HomeServiceLayout layout, {
    String? accessToken,
  }) async {
    await saveLocal(layout);
    if (accessToken == null || accessToken.isEmpty) return;
    try {
      await _api.put(accessToken: accessToken, layout: layout);
    } catch (_) {
      // Offline / transient — local already saved; next login syncs.
    }
  }
}

/// Drop duplicate catalog rows — one tile per slug (favorites never double).
List<ObicService> dedupeServicesBySlug(List<ObicService> services) {
  final seen = <String>{};
  final out = <ObicService>[];
  for (final s in services) {
    if (!seen.add(s.slug)) continue;
    out.add(s);
  }
  return out;
}

/// Favorites first (stable among themselves by [order]), then remaining visible.
List<ObicService> applyHomeServiceLayout(
  List<ObicService> services,
  HomeServiceLayout layout,
) {
  final visible = dedupeServicesBySlug(services)
      .where((s) => !layout.hidden.contains(s.slug))
      .toList();
  final index = <String, int>{
    for (var i = 0; i < layout.order.length; i++) layout.order[i]: i,
  };

  visible.sort((a, b) {
    final af = layout.favorites.contains(a.slug);
    final bf = layout.favorites.contains(b.slug);
    if (af != bf) return af ? -1 : 1;
    final ai = index[a.slug];
    final bi = index[b.slug];
    if (ai == null && bi == null) {
      return a.sortOrder.compareTo(b.sortOrder);
    }
    if (ai == null) return 1;
    if (bi == null) return -1;
    return ai.compareTo(bi);
  });
  return visible;
}

List<ObicService> homeFavoriteServices(
  List<ObicService> laidOut,
  HomeServiceLayout layout,
) {
  if (layout.favorites.isEmpty) return const [];
  return laidOut
      .where((s) => layout.favorites.contains(s.slug))
      .toList();
}

List<ObicService> homeRegularServices(
  List<ObicService> laidOut,
  HomeServiceLayout layout,
) {
  if (layout.favorites.isEmpty) return laidOut;
  return laidOut
      .where((s) => !layout.favorites.contains(s.slug))
      .toList();
}
