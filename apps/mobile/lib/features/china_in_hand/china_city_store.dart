// Made by Dr Ali
// Persist last-picked China city for visit banner / tourism.

import 'package:shared_preferences/shared_preferences.dart';

import 'china_cities.dart';

const _kCityId = 'obic_china_hub_city_id';

class ChinaCityStore {
  ChinaCityStore._();
  static final ChinaCityStore instance = ChinaCityStore._();

  String? _cachedId;

  Future<String?> lastCityId() async {
    if (_cachedId != null) return _cachedId;
    final p = await SharedPreferences.getInstance();
    _cachedId = p.getString(_kCityId);
    return _cachedId;
  }

  Future<void> saveCityId(String id) async {
    _cachedId = id;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCityId, id);
  }

  Future<ChinaCity> resolveInitial({
    double? userLat,
    double? userLng,
  }) async {
    await ChinaCitiesCatalog.instance.ensureLoaded();
    if (userLat != null && userLng != null) {
      return ChinaCitiesCatalog.instance.nearestTo(userLat, userLng);
    }
    final id = await lastCityId();
    if (id != null) {
      final c = ChinaCitiesCatalog.instance.byId(id);
      if (c != null) return c;
    }
    return ChinaCitiesCatalog.instance.yiwuFallback;
  }
}
