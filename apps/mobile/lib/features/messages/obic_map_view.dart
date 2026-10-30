// Made by Dr Ali
// Shared FlutterMap chrome — cascading tiles + never-blank loading/error UI.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/obic_colors.dart';
import 'obic_map_tiles.dart';

/// Full-bleed map with multi-CDN tiles; shows spinner then error if tiles die.
class ObicMapView extends StatefulWidget {
  const ObicMapView({
    super.key,
    required this.initialCenter,
    this.initialZoom = 15.5,
    this.preferChina = false,
    this.mapController,
    this.onPositionChanged,
    this.onMapReady,
    this.children = const <Widget>[],
    this.interactiveFlags = InteractiveFlag.all,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final bool preferChina;
  final MapController? mapController;
  final void Function(MapCamera camera, bool hasGesture)? onPositionChanged;
  final VoidCallback? onMapReady;
  final List<Widget> children;
  final int interactiveFlags;

  @override
  State<ObicMapView> createState() => _ObicMapViewState();
}

class _ObicMapViewState extends State<ObicMapView> {
  int _ok = 0;
  int _fail = 0;
  bool _timedOut = false;
  Timer? _watchdog;
  int _reloadToken = 0;

  bool get _hasSignal => _ok > 0 || _fail > 0;
  bool get _allFailing => _hasSignal && _ok == 0 && _fail >= 4;
  bool get _showError => _allFailing || (_timedOut && _ok == 0);

  @override
  void initState() {
    super.initState();
    _armWatchdog();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  void _armWatchdog() {
    _watchdog?.cancel();
    _timedOut = false;
    _watchdog = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (_ok == 0) setState(() => _timedOut = true);
    });
  }

  void _onTileResult({required bool ok}) {
    if (!mounted) return;
    setState(() {
      if (ok) {
        _ok++;
        _timedOut = false;
      } else {
        _fail++;
      }
    });
  }

  void _retry() {
    setState(() {
      _ok = 0;
      _fail = 0;
      _timedOut = false;
      _reloadToken++;
    });
    _armWatchdog();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final prefer =
        widget.preferChina ||
        coordsSuggestChina(
          widget.initialCenter.latitude,
          widget.initialCenter.longitude,
        );
    final tiles = resolveObicMapTiles(
      preferChina: prefer,
      brightness: brightness,
    );
    final mapBg = brightness == Brightness.dark
        ? const Color(0xFF1A1F24)
        : const Color(0xFFDCE6EE);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: mapBg),
        FlutterMap(
          key: ValueKey<int>(_reloadToken),
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom.clamp(
              tiles.minNativeZoom.toDouble(),
              tiles.maxNativeZoom.toDouble(),
            ),
            minZoom: tiles.minNativeZoom.toDouble(),
            // Hard stop — never pan into blank z beyond CDN native tiles.
            maxZoom: tiles.maxNativeZoom.toDouble(),
            backgroundColor: mapBg,
            interactionOptions: InteractionOptions(
              flags: widget.interactiveFlags,
            ),
            onMapReady: widget.onMapReady,
            onPositionChanged: widget.onPositionChanged,
          ),
          children: [
            buildObicTileLayer(source: tiles, onTileResult: _onTileResult),
            ...widget.children,
          ],
        ),
        if (!_hasSignal && !_showError)
          const IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
        if (_showError)
          _MapTileErrorBanner(attribution: tiles.attribution, onRetry: _retry),
        Positioned(
          left: 12,
          bottom: 8,
          child: IgnorePointer(
            child: Text(
              tiles.attribution,
              style: TextStyle(
                fontSize: 9,
                color: ObicColors.mutedOf(context).withValues(alpha: 0.9),
                shadows: const [Shadow(color: Colors.white70, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapTileErrorBanner extends StatelessWidget {
  const _MapTileErrorBanner({required this.attribution, required this.onRetry});

  final String attribution;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final title = switch (lang) {
      'zh' => '地图加载失败',
      'ar' => 'تعذّر تحميل الخريطة',
      'fr' => 'Impossible de charger la carte',
      _ => 'Map tiles failed to load',
    };
    final hint = switch (lang) {
      'zh' => '请检查网络后重试（中国大陆可用高德，海外用 CARTO/Esri）',
      'ar' => 'تحقق من الشبكة ثم أعد المحاولة',
      'fr' => 'Vérifiez le réseau, puis réessayez',
      _ => 'Check network, then retry (CN: Gaode · ROW: CARTO/Esri)',
    };
    final retry = switch (lang) {
      'zh' => '重试',
      'ar' => 'إعادة',
      'fr' => 'Réessayer',
      _ => 'Retry',
    };

    return Center(
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: ObicColors.surfaceOf(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 36,
                  color: ObicColors.mutedOf(context),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: ObicColors.inkOf(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: ObicColors.mutedOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  attribution,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: ObicColors.mutedOf(context).withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: ObicColors.navy,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
