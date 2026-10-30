// Made by Dr Ali
// Visit near you — GPS + national city switcher + places.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_back_button.dart';
import '../../widgets/obic_cached_image.dart';
import '../auth/auth_controller.dart';
import 'china_cities.dart';
import 'china_city_picker.dart';
import 'china_city_store.dart';
import 'china_in_hand_strings.dart';
import 'china_place_detail_page.dart';
import 'china_tile_nav.dart';
import 'china_visit_places.dart';

class ChinaVisitNearPage extends StatefulWidget {
  const ChinaVisitNearPage({
    super.key,
    required this.authController,
    required this.langCode,
    this.initialCity,
  });

  final AuthController authController;
  final String langCode;
  final ChinaCity? initialCity;

  @override
  State<ChinaVisitNearPage> createState() => _ChinaVisitNearPageState();
}

class _ChinaVisitNearPageState extends State<ChinaVisitNearPage> {
  late final ChinaInHandStrings s = ChinaInHandStrings(widget.langCode);
  bool _loading = true;
  String? _error;
  double? _lat;
  double? _lng;
  ChinaCity? _city;
  List<({ChinaVisitPlace place, double km})> _rows = const [];

  @override
  void initState() {
    super.initState();
    _city = widget.initialCity;
    _locate();
  }

  Future<void> _locate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await ChinaCitiesCatalog.instance.ensureLoaded();
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await _loadCityOnly(note: s.visitGpsOff);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        await _loadCityOnly(note: s.visitGpsDenied);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final city = _city ??
          await ChinaCityStore.instance.resolveInitial(
            userLat: pos.latitude,
            userLng: pos.longitude,
          );
      var near = chinaVisitNearby(
        userLat: pos.latitude,
        userLng: pos.longitude,
      );
      if (near.isEmpty) {
        final local = placesForCity(city.id);
        near = local
            .map(
              (p) => (
                place: p,
                km: haversineKm(pos.latitude, pos.longitude, p.lat, p.lng),
              ),
            )
            .toList()
          ..sort((a, b) => a.km.compareTo(b.km));
      }
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _city = city;
        _rows = near;
        _loading = false;
        _error = near.isEmpty ? s.visitCityEmptySoon : null;
      });
    } catch (_) {
      await _loadCityOnly(note: s.visitGpsFail);
    }
  }

  Future<void> _loadCityOnly({String? note}) async {
    final city = _city ??
        await ChinaCityStore.instance.resolveInitial(
          userLat: _lat,
          userLng: _lng,
        );
    final local = placesForCity(city.id);
    if (!mounted) return;
    setState(() {
      _city = city;
      _rows = local.map((p) => (place: p, km: 0.0)).toList();
      _loading = false;
      _error = note ?? (local.isEmpty ? s.visitCityEmptySoon : null);
    });
  }

  Future<void> _pickCity() async {
    final picked = await showChinaCityPicker(
      context: context,
      langCode: widget.langCode,
      selected: _city,
    );
    if (picked == null || !mounted) return;
    setState(() => _city = picked);
    if (_lat != null && _lng != null && isRoughlyInOrNearChina(_lat!, _lng!)) {
      final local = placesForCity(picked.id);
      setState(() {
        _rows = local
            .map(
              (p) => (
                place: p,
                km: haversineKm(_lat!, _lng!, p.lat, p.lng),
              ),
            )
            .toList()
          ..sort((a, b) => a.km.compareTo(b.km));
        _error = local.isEmpty ? s.visitCityEmptySoon : null;
      });
    } else {
      await _loadCityOnly();
    }
  }

  IconData _kindIcon(ChinaVisitKind k) {
    switch (k) {
      case ChinaVisitKind.mosque:
        return Icons.mosque_rounded;
      case ChinaVisitKind.market:
        return Icons.storefront_rounded;
      case ChinaVisitKind.place:
        return Icons.landscape_rounded;
      case ChinaVisitKind.halal:
        return Icons.restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        leading: const ObicBackButton(),
        title: Text(s.visitTitle),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _pickCity,
            icon: const Icon(Icons.location_city_rounded),
            tooltip: s.cityPickerTitle,
          ),
          IconButton(
            onPressed: _loading ? null : _locate,
            icon: const Icon(Icons.my_location_rounded),
            tooltip: s.visitRefresh,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _locate,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (_city != null)
            Text(
              '${s.cityLabel}: ${_city!.name(widget.langCode)} · ${_city!.nameZh}',
              style: TextStyle(
                color: ObicColors.titleOf(context),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: ObicColors.mutedOf(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_rows.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ObicColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Icon(Icons.travel_explore_rounded, size: 40, color: Color(0xFFC9A227)),
                  const SizedBox(height: 10),
                  Text(
                    s.visitCityEmptySoon,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ObicColors.inkOf(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A227),
                      foregroundColor: ObicColors.navy,
                    ),
                    onPressed: () => openChinaSubById(
                      context: context,
                      authController: widget.authController,
                      langCode: widget.langCode,
                      parentSlug: 'travel',
                      subId: 'guide',
                    ),
                    child: Text(s.visitGoWithObic),
                  ),
                  TextButton(
                    onPressed: _pickCity,
                    child: Text(s.cityPickerTitle),
                  ),
                ],
              ),
            )
          else
            for (final row in _rows) ...[
              _PlaceCard(
                place: row.place,
                km: row.km,
                langCode: widget.langCode,
                kindIcon: _kindIcon(row.place.kind),
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
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.km,
    required this.langCode,
    required this.kindIcon,
    required this.onTap,
  });

  final ChinaVisitPlace place;
  final double km;
  final String langCode;
  final IconData kindIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final img = place.imageAsset ?? 'assets/china/shanghai.jpg';
    return Material(
      color: ObicColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ObicCachedImage(img, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ObicColors.navy.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(kindIcon, size: 16, color: const Color(0xFFC9A227)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name(langCode),
                      style: TextStyle(
                        color: ObicColors.inkOf(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.blurb(langCode),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ObicColors.mutedOf(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    if (km > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${km < 10 ? km.toStringAsFixed(1) : km.toStringAsFixed(0)} km',
                        style: const TextStyle(
                          color: Color(0xFFC9A227),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
