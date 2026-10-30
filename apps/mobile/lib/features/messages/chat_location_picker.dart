// Made by Dr Ali
// WeChat-style location picker — pan map under fixed pin, search, confirm.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/region_controller.dart';
import '../../theme/obic_colors.dart';
import 'chat_location_body.dart';
import 'obic_map_tiles.dart';
import 'obic_map_view.dart';

/// Result of WeChat-style “Send this location”.
class PickedLocation {
  const PickedLocation({
    required this.lat,
    required this.lng,
    required this.label,
    required this.preferChina,
  });

  final double lat;
  final double lng;
  final String label;
  final bool preferChina;
}

/// Opens full-screen picker; returns null if cancelled.
Future<PickedLocation?> openLocationPicker(BuildContext context) {
  return Navigator.of(context).push<PickedLocation>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const ChatLocationPickerScreen(),
    ),
  );
}

class ChatLocationPickerScreen extends StatefulWidget {
  const ChatLocationPickerScreen({super.key});

  @override
  State<ChatLocationPickerScreen> createState() =>
      _ChatLocationPickerScreenState();
}

class _ChatLocationPickerScreenState extends State<ChatLocationPickerScreen> {
  final MapController _map = MapController();
  final TextEditingController _search = TextEditingController();

  LatLng _center = const LatLng(29.30691, 120.07532); // Yiwu default
  LatLng? _pendingMove;
  PlaceAddress _address = const PlaceAddress();
  int _geoGen = 0;
  bool _busyGps = true;
  bool _busyGeo = false;
  bool _preferChina = true;
  bool _mapReady = false;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _moveMap(LatLng target, double zoom) {
    if (_mapReady) {
      _map.move(target, zoom);
    } else {
      _pendingMove = target;
    }
  }

  void _onMapReady() {
    _mapReady = true;
    final pending = _pendingMove;
    if (pending != null) {
      _map.move(pending, 16);
      _pendingMove = null;
    }
  }

  Future<void> _bootstrap() async {
    final locale = Localizations.localeOf(context);
    final prefs = await SharedPreferences.getInstance();
    final savedRegion = prefs.getString(kRegionCountryKey);
    _preferChina = preferChinaMapLinks(
      localeLanguageCode: locale.languageCode,
      localeCountryCode: locale.countryCode,
      savedRegionCountry: savedRegion,
    );

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (enabled &&
          permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
        _center = LatLng(pos.latitude, pos.longitude);
        if (coordsSuggestChina(pos.latitude, pos.longitude)) {
          _preferChina = true;
        }
        _moveMap(_center, 16);
      }
    } catch (_) {
      // Keep default center.
    }

    if (!mounted) return;
    setState(() => _busyGps = false);
    await _reverseGeocode(_center);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    final gen = ++_geoGen;
    setState(() => _busyGeo = true);
    final lang = Localizations.localeOf(context).languageCode;
    final address = await lookupPlaceAddress(
      lat: point.latitude,
      lng: point.longitude,
      languageCode: lang,
    );
    if (!mounted || gen != _geoGen) return;
    final iso = address.isoCountryCode;
    setState(() {
      if (iso != null && preferChinaMapLinks(placemarkIsoCountry: iso)) {
        _preferChina = true;
      }
      _address = address;
      _busyGeo = false;
    });
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _center = camera.center;
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 450), () {
      _reverseGeocode(_center);
    });
  }

  Future<void> _goMyLocation() async {
    setState(() => _busyGps = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _center = LatLng(pos.latitude, pos.longitude);
      _moveMap(_center, 16);
      await _reverseGeocode(_center);
    } catch (_) {
      if (mounted) {
        final lang = Localizations.localeOf(context).languageCode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (lang) {
              'zh' => '无法获取当前位置',
              'ar' => 'تعذّر الحصول على موقعك',
              'fr' => 'Position actuelle indisponible',
              _ => 'Could not get current location',
            }),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyGps = false);
    }
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _busyGeo = true);
    try {
      final lang = Localizations.localeOf(context).languageCode;
      await setLocaleIdentifier(geocoderLocaleTag(lang));
      final found = await locationFromAddress(q);
      if (found.isEmpty) throw StateError('none');
      final loc = found.first;
      _center = LatLng(loc.latitude, loc.longitude);
      _moveMap(_center, 16);
      await _reverseGeocode(_center);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyGeo = false);
      final lang = Localizations.localeOf(context).languageCode;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapPlaceNotFound(lang))));
    }
  }

  void _confirm() {
    final lang = Localizations.localeOf(context).languageCode;
    final label = _address.isEmpty
        ? mapSelectedPlaceFallback(lang)
        : _address.shareLabel;
    Navigator.of(context).pop(
      PickedLocation(
        lat: _center.latitude,
        lng: _center.longitude,
        label: label,
        preferChina:
            _preferChina ||
            coordsSuggestChina(_center.latitude, _center.longitude),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final title = switch (lang) {
      'zh' => '选择位置',
      'ar' => 'اختر الموقع',
      'fr' => 'Choisir un lieu',
      _ => 'Choose location',
    };
    final searchHint = switch (lang) {
      'zh' => '搜索地点',
      'ar' => 'ابحث عن مكان',
      'fr' => 'Rechercher un lieu',
      _ => 'Search place',
    };
    final send = switch (lang) {
      'zh' => '发送该位置',
      'ar' => 'إرسال هذا الموقع',
      'fr' => 'Envoyer ce lieu',
      _ => 'Send this location',
    };
    final sheetBg = ObicColors.surfaceOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ObicMapView(
            initialCenter: _center,
            initialZoom: 15.5,
            preferChina: _preferChina,
            mapController: _map,
            onMapReady: _onMapReady,
            onPositionChanged: _onPositionChanged,
            interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          // Fixed center pin (WeChat-style — map moves under pin).
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.location_on,
                  size: 52,
                  color: Color(0xFFE53935),
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 16,
            bottom: 210,
            child: Material(
              color: sheetBg,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _busyGps ? null : _goMyLocation,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: _busyGps
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.my_location_rounded,
                          color: ObicColors.blue,
                          size: 26,
                        ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      Material(
                        color: sheetBg.withValues(alpha: 0.96),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: ObicColors.inkOf(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Material(
                          color: sheetBg.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(22),
                          child: TextField(
                            controller: _search,
                            cursorColor: ObicColors.blue,
                            style: TextStyle(
                              color: ObicColors.inkOf(context),
                              fontSize: 16,
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: _runSearch,
                            decoration: InputDecoration(
                              hintText: searchHint,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.search_rounded),
                                onPressed: () => _runSearch(_search.text),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ObicColors.mutedOf(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _busyGeo && _address.isEmpty
                                  ? mapAddressPending(lang)
                                  : (_address.isEmpty
                                        ? mapAddressUnavailable(lang)
                                        : _address.lines.join('\n')),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                color: ObicColors.inkOf(context),
                              ),
                            ),
                          ),
                          if (_busyGeo)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF07C160),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          send,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
