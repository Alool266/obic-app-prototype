// Made by Dr Ali
// Detects user country for catalog filtering (ISO 3166-1 alpha-2).

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kRegionCountryKey = 'obic.region.country';
const kRegionCityKey = 'obic.region.city';
const kRegionLatKey = 'obic.region.lat';
const kRegionLngKey = 'obic.region.lng';

const _kCountryKey = kRegionCountryKey;
const _kCityKey = kRegionCityKey;
const _kLatKey = kRegionLatKey;
const _kLngKey = kRegionLngKey;

class RegionController extends ChangeNotifier {
  String? _countryCode;
  String? _cityName;
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  String? _error;

  String? get countryCode => _countryCode;
  String? get cityName => _cityName;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get locating => _locating;
  String? get error => _error;
  bool get hasCoordinates => _latitude != null && _longitude != null;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _countryCode = prefs.getString(_kCountryKey);
    _cityName = prefs.getString(_kCityKey);
    _latitude = prefs.getDouble(_kLatKey);
    _longitude = prefs.getDouble(_kLngKey);
    notifyListeners();
    // Badge / demo screenshot builds must never show the iOS location sheet.
    if (const bool.fromEnvironment('BADGE_DEMO') ||
        const String.fromEnvironment('DEMO_SHOT').isNotEmpty) {
      await _applyFallback('CN');
      return;
    }
    // WeChat-style: auto-detect on every app open.
    // First launch → permission prompt (silent: false). Later → quiet refresh.
    await detectLocation(silent: _countryCode != null);
  }

  Future<void> detectLocation({bool silent = false}) async {
    if (_locating) return;
    // Screenshot / badge QA: never block on the system location sheet.
    if (const bool.fromEnvironment('BADGE_DEMO')) {
      await _applyFallback('CN');
      return;
    }
    _locating = true;
    if (!silent) _error = null;
    notifyListeners();

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await _applyFallback('CN');
        if (!silent) _error = 'location_disabled';
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _applyFallback('CN');
        if (!silent) _error = 'location_denied';
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final places = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final place = places.isNotEmpty ? places.first : null;
      var iso = place?.isoCountryCode?.trim().toUpperCase();
      var city = place?.locality?.trim().isNotEmpty == true
          ? place!.locality!.trim()
          : place?.administrativeArea?.trim();

      // iOS Simulator defaults to Apple Park (US) — OBIC demo catalog is China-first.
      final applePark = (pos.latitude - 37.3349).abs() < 0.8 &&
          (pos.longitude + 122.0090).abs() < 0.8;
      if (applePark) {
        await _persist('CN', 'Guangzhou', 23.1291, 113.2644);
        return;
      }

      if (iso != null && iso.length == 2) {
        await _persist(iso, city, pos.latitude, pos.longitude);
      } else {
        await _applyFallback('CN');
      }
    } catch (_) {
      await _applyFallback('CN');
      if (!silent) _error = 'location_failed';
    } finally {
      _locating = false;
      notifyListeners();
    }
  }

  Future<void> setCountryManual(String isoCode, {String? city}) async {
    final code = isoCode.trim().toUpperCase();
    if (code.length != 2) return;
    await _persist(code, city?.trim(), _latitude, _longitude);
  }

  Future<void> _applyFallback(String iso) async {
    if (_countryCode != null) return;
    await _persist(iso, null, null, null);
  }

  Future<void> _persist(
    String iso,
    String? city,
    double? lat,
    double? lng,
  ) async {
    _countryCode = iso;
    _cityName = city;
    if (lat != null && lng != null) {
      _latitude = lat;
      _longitude = lng;
    }
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCountryKey, iso);
    if (city != null && city.isNotEmpty) {
      await prefs.setString(_kCityKey, city);
    } else {
      await prefs.remove(_kCityKey);
    }
    if (_latitude != null && _longitude != null) {
      await prefs.setDouble(_kLatKey, _latitude!);
      await prefs.setDouble(_kLngKey, _longitude!);
    }
    notifyListeners();
  }
}
