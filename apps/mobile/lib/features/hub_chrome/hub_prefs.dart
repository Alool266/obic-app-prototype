// Made by Dr Ali
// Per-hub settings: city, units, notifications, favorites, recent, onboarding.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'hub_id.dart';

enum HubDistanceUnit { km, mi }

class HubPrefs {
  HubPrefs(this.hub);

  final ObicHubId hub;

  String get _p => 'obic_hub_${hub.prefsKey}';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> onboardingDone() async {
    final p = await _prefs;
    return p.getBool('${_p}_onboarding_done') ?? false;
  }

  Future<void> setOnboardingDone() async {
    final p = await _prefs;
    await p.setBool('${_p}_onboarding_done', true);
  }

  Future<String?> defaultCity() async {
    final p = await _prefs;
    return p.getString('${_p}_default_city');
  }

  Future<void> setDefaultCity(String? city) async {
    final p = await _prefs;
    final key = '${_p}_default_city';
    if (city == null || city.trim().isEmpty) {
      await p.remove(key);
    } else {
      await p.setString(key, city.trim());
    }
  }

  Future<HubDistanceUnit> distanceUnit() async {
    final p = await _prefs;
    final raw = p.getString('${_p}_distance_unit');
    return raw == 'mi' ? HubDistanceUnit.mi : HubDistanceUnit.km;
  }

  Future<void> setDistanceUnit(HubDistanceUnit unit) async {
    final p = await _prefs;
    await p.setString(
      '${_p}_distance_unit',
      unit == HubDistanceUnit.mi ? 'mi' : 'km',
    );
  }

  Future<bool> notifyDeals() async {
    final p = await _prefs;
    return p.getBool('${_p}_notify_deals') ?? true;
  }

  Future<void> setNotifyDeals(bool v) async {
    final p = await _prefs;
    await p.setBool('${_p}_notify_deals', v);
  }

  Future<bool> notifyOrders() async {
    final p = await _prefs;
    return p.getBool('${_p}_notify_orders') ?? true;
  }

  Future<void> setNotifyOrders(bool v) async {
    final p = await _prefs;
    await p.setBool('${_p}_notify_orders', v);
  }

  /// Daily-only dietary notes (optional free text).
  Future<String?> dietaryNotes() async {
    final p = await _prefs;
    return p.getString('${_p}_dietary');
  }

  Future<void> setDietaryNotes(String? notes) async {
    final p = await _prefs;
    final key = '${_p}_dietary';
    if (notes == null || notes.trim().isEmpty) {
      await p.remove(key);
    } else {
      await p.setString(key, notes.trim());
    }
  }

  /// Travel default traveler display name.
  Future<String?> defaultTraveler() async {
    final p = await _prefs;
    return p.getString('${_p}_traveler');
  }

  Future<void> setDefaultTraveler(String? name) async {
    final p = await _prefs;
    final key = '${_p}_traveler';
    if (name == null || name.trim().isEmpty) {
      await p.remove(key);
    } else {
      await p.setString(key, name.trim());
    }
  }

  Future<String> currencyDisplay() async {
    final p = await _prefs;
    return p.getString('${_p}_currency') ?? 'CNY';
  }

  Future<void> setCurrencyDisplay(String code) async {
    final p = await _prefs;
    await p.setString('${_p}_currency', code.trim().toUpperCase());
  }

  Future<Set<String>> favorites() async {
    final p = await _prefs;
    final raw = p.getStringList('${_p}_favorites') ?? const [];
    return raw.toSet();
  }

  Future<void> toggleFavorite(String id) async {
    final p = await _prefs;
    final set = (p.getStringList('${_p}_favorites') ?? <String>[]).toSet();
    if (!set.add(id)) set.remove(id);
    await p.setStringList('${_p}_favorites', set.toList());
  }

  Future<bool> isFavorite(String id) async {
    final set = await favorites();
    return set.contains(id);
  }

  Future<List<String>> recentSearches() async {
    final p = await _prefs;
    return p.getStringList('${_p}_recent') ?? const [];
  }

  Future<void> pushRecentSearch(String q) async {
    final t = q.trim();
    if (t.isEmpty) return;
    final p = await _prefs;
    final list = [...(p.getStringList('${_p}_recent') ?? <String>[])];
    list.removeWhere((e) => e.toLowerCase() == t.toLowerCase());
    list.insert(0, t);
    if (list.length > 12) list.removeRange(12, list.length);
    await p.setStringList('${_p}_recent', list);
  }

  Future<void> clearRecentSearches() async {
    final p = await _prefs;
    await p.remove('${_p}_recent');
  }

  Future<void> clearCache() async {
    final p = await _prefs;
    await p.remove('${_p}_cache_blob');
    await p.remove('${_p}_cache_at');
  }

  Future<void> writeCacheBlob(Map<String, dynamic> json) async {
    final p = await _prefs;
    await p.setString('${_p}_cache_blob', jsonEncode(json));
    await p.setInt('${_p}_cache_at', DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>?> readCacheBlob({Duration maxAge = const Duration(hours: 6)}) async {
    final p = await _prefs;
    final at = p.getInt('${_p}_cache_at');
    final raw = p.getString('${_p}_cache_blob');
    if (at == null || raw == null || raw.isEmpty) return null;
    final age = DateTime.now().millisecondsSinceEpoch - at;
    if (age > maxAge.inMilliseconds) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  /// Clears hub favorites + recent; caller may also unfavorite Home tile.
  Future<void> resetHubFavorites() async {
    final p = await _prefs;
    await p.remove('${_p}_favorites');
    await p.remove('${_p}_recent');
  }
}

String formatHubDistance(double km, HubDistanceUnit unit) {
  if (unit == HubDistanceUnit.mi) {
    final mi = km * 0.621371;
    return '${mi.toStringAsFixed(mi < 10 ? 1 : 0)} mi';
  }
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
}
