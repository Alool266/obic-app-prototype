// Made by Dr Ali — haversine distance (km) between two WGS84 points.

import 'dart:math' as math;

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double _rad(double deg) => deg * math.pi / 180.0;

String formatDistanceKm(double km, {required bool zh, required bool ar}) {
  if (km < 1) {
    final m = (km * 1000).round();
    if (zh) return '${m}米';
    if (ar) return '$m م';
    return '${m}m';
  }
  final rounded = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
  if (zh) return '${rounded}公里';
  if (ar) return '$rounded كم';
  return '${rounded} km';
}
