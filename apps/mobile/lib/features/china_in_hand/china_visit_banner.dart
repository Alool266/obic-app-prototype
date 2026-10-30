// Made by Dr Ali
// Location-aware visit banner + city chip for China hub / tourism.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_cached_image.dart';
import '../../widgets/obic_soft_motion.dart';
import '../auth/auth_controller.dart';
import 'china_cities.dart';
import 'china_city_picker.dart';
import 'china_city_store.dart';
import 'china_in_hand_strings.dart';
import 'china_place_detail_page.dart';
import 'china_visit_near_page.dart';
import 'china_visit_places.dart';

class ChinaVisitBanner extends StatefulWidget {
  const ChinaVisitBanner({
    super.key,
    required this.authController,
    required this.langCode,
    this.compact = false,
  });

  final AuthController authController;
  final String langCode;
  final bool compact;

  @override
  State<ChinaVisitBanner> createState() => _ChinaVisitBannerState();
}

class _ChinaVisitBannerState extends State<ChinaVisitBanner> {
  late final ChinaInHandStrings s = ChinaInHandStrings(widget.langCode);
  bool _loading = true;
  bool _gpsBusy = false;
  ChinaCity? _city;
  List<({ChinaVisitPlace place, double km})> _near = const [];
  String? _note;

  static const _gpsSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 12),
  );

  @override
  void initState() {
    super.initState();
    _boot(forceGps: false);
  }

  Future<Position?> _readPosition({required bool forcePrompt}) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _note = s.visitGpsOff;
      return null;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      _note = s.visitGpsDenied;
      return null;
    }
    if (perm == LocationPermission.deniedForever) {
      _note = s.visitGpsDenied;
      if (forcePrompt && mounted) {
        final open = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ObicColors.surfaceOf(ctx),
            title: Text(
              s.visitRefresh,
              style: TextStyle(color: ObicColors.inkOf(ctx)),
            ),
            content: Text(
              s.visitGpsDenied,
              style: TextStyle(color: ObicColors.mutedOf(ctx)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.cityPickerTitle),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.visitRetry),
              ),
            ],
          ),
        );
        if (open == true) {
          await Geolocator.openAppSettings();
        }
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _gpsSettings,
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      _note = s.visitGpsFail;
      return null;
    }
  }

  Future<void> _applyLocation({
    required double? lat,
    required double? lng,
    required bool preferGpsCity,
  }) async {
    await ChinaCitiesCatalog.instance.ensureLoaded();
    final city = preferGpsCity && lat != null && lng != null
        ? (isRoughlyInOrNearChina(lat, lng)
            ? ChinaCitiesCatalog.instance.nearestTo(lat, lng)
            : ChinaCitiesCatalog.instance.yiwuFallback)
        : await ChinaCityStore.instance.resolveInitial(
            userLat: lat,
            userLng: lng,
          );
    await ChinaCityStore.instance.saveCityId(city.id);

    List<({ChinaVisitPlace place, double km})> near = const [];
    if (lat != null && lng != null && isRoughlyInOrNearChina(lat, lng)) {
      near = chinaVisitNearby(userLat: lat, userLng: lng, maxKm: 80);
      if (near.isEmpty) {
        final cityPlaces = placesForCity(city.id);
        near = cityPlaces
            .map(
              (p) => (
                place: p,
                km: haversineKm(lat, lng, p.lat, p.lng),
              ),
            )
            .toList()
          ..sort((a, b) => a.km.compareTo(b.km));
      }
      _note = null;
    } else {
      final cityPlaces = placesForCity(city.id);
      near = cityPlaces.map((p) => (place: p, km: 0.0)).toList();
      if (lat != null && lng != null && !isRoughlyInOrNearChina(lat, lng)) {
        _note = s.visitFarFromChina;
      } else {
        _note ??= s.visitPickCityHint;
      }
    }

    if (!mounted) return;
    setState(() {
      _city = city;
      _near = near.take(4).toList();
      _loading = false;
      _gpsBusy = false;
    });
  }

  Future<void> _boot({required bool forceGps}) async {
    if (forceGps) {
      if (_gpsBusy) return;
      setState(() {
        _gpsBusy = true;
        _note = null;
      });
    } else {
      setState(() => _loading = true);
    }

    try {
      final pos = await _readPosition(forcePrompt: forceGps);
      if (!mounted) return;
      if (pos == null) {
        await _applyLocation(
          lat: null,
          lng: null,
          preferGpsCity: false,
        );
        if (forceGps && mounted && _note != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_note!)),
          );
        }
        return;
      }
      await _applyLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        preferGpsCity: forceGps,
      );
      if (forceGps && mounted && _city != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${s.cityUseGps}: ${_city!.name(widget.langCode)}',
            ),
          ),
        );
      }
    } catch (_) {
      _note = s.visitGpsFail;
      try {
        await _applyLocation(lat: null, lng: null, preferGpsCity: false);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _gpsBusy = false;
        });
      }
      if (forceGps && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.visitGpsFail)),
        );
      }
    } finally {
      if (mounted && (_gpsBusy || _loading)) {
        setState(() {
          _gpsBusy = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickCity() async {
    final picked = await showChinaCityPicker(
      context: context,
      langCode: widget.langCode,
      selected: _city,
    );
    if (picked == null || !mounted) return;
    final places = placesForCity(picked.id);
    setState(() {
      _city = picked;
      _near = places.map((p) => (place: p, km: 0.0)).toList();
      _note = places.isEmpty ? s.visitCityEmptySoon : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: widget.compact ? 120 : 168,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: ObicColors.navy.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final city = _city;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChinaVisitNearPage(
                      authController: widget.authController,
                      langCode: widget.langCode,
                      initialCity: city,
                    ),
                  ),
                );
              },
              child: Ink(
                height: widget.compact ? 132 : 168,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFC9A227).withValues(alpha: 0.4),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ObicCachedImage(
                        'assets/travel/landmark.jpg',
                        fit: BoxFit.cover,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xF0071628), Color(0x99071628)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.visitBannerTitle,
                              style: const TextStyle(
                                color: Color(0xFFF8F5EE),
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.visitBannerSubtitle,
                              style: TextStyle(
                                color: const Color(0xFFE8D48B)
                                    .withValues(alpha: 0.95),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_rounded,
                                  size: 16,
                                  color: Color(0xFFC9A227),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    city?.name(widget.langCode) ?? '—',
                                    style: const TextStyle(
                                      color: Color(0xFFF8F5EE),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  s.visitSeeAll,
                                  style: const TextStyle(
                                    color: Color(0xFFC9A227),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _gpsBusy ? null : _pickCity,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ObicColors.inkOf(context),
                    side: BorderSide(
                      color: const Color(0xFFC9A227).withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.location_city_rounded, size: 18),
                  label: Text(s.cityPickerTitle),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _gpsBusy ? null : () => _boot(forceGps: true),
                style: IconButton.styleFrom(
                  backgroundColor: ObicColors.navy,
                  foregroundColor: const Color(0xFFC9A227),
                ),
                icon: _gpsBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFC9A227),
                        ),
                      )
                    : const Icon(Icons.my_location_rounded),
                tooltip: s.visitRefresh,
              ),
            ],
          ),
          if (_note != null) ...[
            const SizedBox(height: 8),
            Text(
              _note!,
              style: TextStyle(
                color: ObicColors.mutedOf(context),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          if (_near.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _near.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final row = _near[i];
                  return ObicSlideIn(
                    index: i,
                    child: _PlaceChip(
                      place: row.place,
                      km: row.km,
                      langCode: widget.langCode,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChinaPlaceDetailPage(
                              authController: widget.authController,
                              langCode: widget.langCode,
                              place: row.place,
                              distanceKm: row.km > 0 ? row.km : null,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ] else if (!_loading) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ObicColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                s.visitCityEmptySoon,
                style: TextStyle(
                  color: ObicColors.inkOf(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({
    required this.place,
    required this.km,
    required this.langCode,
    required this.onTap,
  });

  final ChinaVisitPlace place;
  final double km;
  final String langCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final img = place.imageAsset ?? 'assets/china/shanghai.jpg';
    return ObicBounce(
      onTap: onTap,
      child: SizedBox(
        width: 148,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ObicCachedImage(img, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6071628)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      place.name(langCode),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF8F5EE),
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        height: 1.2,
                      ),
                    ),
                    if (km > 0)
                      Text(
                        '${km < 10 ? km.toStringAsFixed(1) : km.toStringAsFixed(0)} km',
                        style: const TextStyle(
                          color: Color(0xFFC9A227),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
