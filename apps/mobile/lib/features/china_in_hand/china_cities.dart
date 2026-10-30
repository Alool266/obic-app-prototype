// Made by Dr Ali
// China city catalog — searchable AR / ZH / Pinyin (assets/china/china_cities.json).

import 'dart:convert';

import 'package:flutter/services.dart';

import 'china_visit_places.dart';

class ChinaCity {
  const ChinaCity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameZh,
    required this.pinyin,
    required this.lat,
    required this.lng,
    required this.tier,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String nameZh;
  final String pinyin;
  final double lat;
  final double lng;
  final String tier;

  String name(String lang) {
    if (lang.startsWith('ar')) return nameAr;
    if (lang.startsWith('zh')) return nameZh;
    return nameEn;
  }

  bool matches(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return true;
    final blob = '$nameAr $nameEn $nameZh $pinyin $id'.toLowerCase();
    return blob.contains(q);
  }

  factory ChinaCity.fromJson(Map<String, dynamic> j) {
    return ChinaCity(
      id: '${j['id']}',
      nameAr: '${j['nameAr'] ?? j['nameEn']}',
      nameEn: '${j['nameEn']}',
      nameZh: '${j['nameZh']}',
      pinyin: '${j['pinyin'] ?? j['nameEn']}'.toLowerCase(),
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),
      tier: '${j['tier'] ?? 'prefecture'}',
    );
  }
}

class ChinaCitiesCatalog {
  ChinaCitiesCatalog._();
  static ChinaCitiesCatalog? _instance;
  static ChinaCitiesCatalog get instance => _instance ??= ChinaCitiesCatalog._();

  List<ChinaCity>? _cities;
  String? _updatedAt;

  String get updatedAt => _updatedAt ?? '2026-10-27';

  Future<List<ChinaCity>> ensureLoaded() async {
    if (_cities != null) return _cities!;
    final raw =
        await rootBundle.loadString('assets/china/china_cities.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _updatedAt = '${map['updatedAt'] ?? ''}';
    final list = (map['cities'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ChinaCity.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    list.sort((a, b) => a.pinyin.compareTo(b.pinyin));
    _cities = list;
    return list;
  }

  ChinaCity? byId(String id) {
    final all = _cities;
    if (all == null) return null;
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Soft default when GPS / prefs unavailable.
  ChinaCity get yiwuFallback =>
      byId('yiwu') ??
      const ChinaCity(
        id: 'yiwu',
        nameAr: 'ييوو',
        nameEn: 'Yiwu',
        nameZh: '义乌',
        pinyin: 'yiwu',
        lat: 29.3069,
        lng: 120.0753,
        tier: 'trade',
      );

  ChinaCity nearestTo(double lat, double lng) {
    final all = _cities;
    if (all == null || all.isEmpty) return yiwuFallback;
    if (!isRoughlyInOrNearChina(lat, lng)) return yiwuFallback;
    ChinaCity best = all.first;
    var bestKm = haversineKm(lat, lng, best.lat, best.lng);
    for (final c in all.skip(1)) {
      final km = haversineKm(lat, lng, c.lat, c.lng);
      if (km < bestKm) {
        bestKm = km;
        best = c;
      }
    }
    // If still very far from any listed city center, keep soft default.
    if (bestKm > 250) return yiwuFallback;
    return best;
  }
}
