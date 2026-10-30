// Made by Dr Ali
// One-tap GPS → placemark / default delivery address for Daily (+ shared).

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';

class HubGpsResult {
  const HubGpsResult({
    required this.lat,
    required this.lng,
    required this.city,
    this.line1,
    this.label,
  });

  final double lat;
  final double lng;
  final String city;
  final String? line1;
  final String? label;
}

Future<HubGpsResult?> readHubGps({
  bool forcePrompt = true,
}) async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) return null;

  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    if (forcePrompt && perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    return null;
  }

  Position pos;
  try {
    pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  } catch (_) {
    final last = await Geolocator.getLastKnownPosition();
    if (last == null) return null;
    pos = last;
  }

  String city = 'Yiwu';
  String? line1;
  String? label;
  try {
    final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (marks.isNotEmpty) {
      final m = marks.first;
      city = (m.locality?.trim().isNotEmpty == true
              ? m.locality!
              : m.subAdministrativeArea?.trim().isNotEmpty == true
                  ? m.subAdministrativeArea!
                  : m.administrativeArea)
          ?.trim() ??
          city;
      final street = [
        if (m.subLocality?.trim().isNotEmpty == true) m.subLocality!.trim(),
        if (m.thoroughfare?.trim().isNotEmpty == true) m.thoroughfare!.trim(),
        if (m.subThoroughfare?.trim().isNotEmpty == true)
          m.subThoroughfare!.trim(),
      ].join(' ');
      if (street.trim().isNotEmpty) line1 = street.trim();
      label = m.name?.trim().isNotEmpty == true ? m.name!.trim() : null;
    }
  } catch (_) {}

  return HubGpsResult(
    lat: pos.latitude,
    lng: pos.longitude,
    city: city,
    line1: line1,
    label: label,
  );
}

/// Saves GPS as the default delivery address when authenticated.
Future<HubGpsResult?> applyGpsAsDefaultAddress(AuthController auth) async {
  final gps = await readHubGps();
  if (gps == null) return null;
  final token = await auth.accessToken();
  if (token == null) return gps;

  final existing = List<ObicAddress>.from(auth.user?.addresses ?? const []);
  final id = 'gps-${DateTime.now().millisecondsSinceEpoch}';
  final next = ObicAddress(
    id: id,
    label: gps.label ?? 'GPS',
    line1: gps.line1 ?? gps.city,
    city: gps.city,
    notes: 'gps:${gps.lat.toStringAsFixed(5)},${gps.lng.toStringAsFixed(5)}',
    isDefault: true,
  );
  final cleared = [
    for (final a in existing) a.copyWith(isDefault: false),
    next,
  ];
  try {
    final user = await AuthApi().updateAddresses(
      accessToken: token,
      addresses: cleared,
    );
    await auth.applyUser(user);
  } catch (_) {
    // Still return GPS so UI can show city even if save failed.
  }
  return gps;
}
