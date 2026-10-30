// Made by Dr Ali
// Multi-source HTTPS map tiles — China-reachable + worldwide.
// Never rely on a single CDN: OSM/Carto often blank on mainland CN;
// Amap may fail on ROAM / some Wi‑Fi. Cascading provider tries several URLs.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

/// Resolved tile templates for one map screen (ordered primary → fallbacks).
class ObicMapTileSource {
  const ObicMapTileSource({
    required this.urlTemplates,
    this.subdomains = const <String>[],
    required this.attribution,
    /// Highest z the primary CDN actually serves. Beyond this, flutter_map
    /// scales last-native tiles — never request blank z=19+ from Amap.
    this.maxNativeZoom = 18,
    this.minNativeZoom = 3,
  });

  /// Ordered URL templates (`{z}` `{x}` `{y}` `{s}`). First success wins.
  final List<String> urlTemplates;
  final List<String> subdomains;
  final String attribution;
  final int maxNativeZoom;
  final int minNativeZoom;

  String get urlTemplate => urlTemplates.first;
  String? get fallbackUrl =>
      urlTemplates.length > 1 ? urlTemplates[1] : null;
}

/// Gaode/Amap Web Mercator (no key) — usually reachable in mainland China.
const String kAmapWprdUrl =
    'https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=7';

/// Alternate Amap host (some networks prefer webrd).
const String kAmapWebrdUrl =
    'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}';

/// Carto Voyager — clear light basemap (global CDN).
const String kCartoVoyagerUrl =
    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

/// Carto dark — readable pins on dark UI.
const String kCartoDarkUrl =
    'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

/// Esri World Street — strong worldwide fallback (note z/y/x order).
const String kEsriStreetUrl =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';

/// OSM France HOT — extra worldwide fallback (identifying UA required).
const String kOsmHotUrl =
    'https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';

/// Rough mainland+ bounding box — English locale in CN still gets Amap-first.
bool coordsSuggestChina(double lat, double lng) {
  return lat >= 17.5 && lat <= 53.8 && lng >= 73.4 && lng <= 135.2;
}

/// Browser-like UA — some CDNs reject bare `flutter_map (package)` or empty UA.
const String kObicMapUserAgent =
    'OBICMobile/1.0 (Android; +https://obic.app) flutter_map';

/// Mutable headers for [NetworkTileProvider] / [ObicCascadingTileProvider].
///
/// CRITICAL: never pass a `const` map — [TileLayer] calls `headers.putIfAbsent`
/// for User-Agent; an unmodifiable map throws and the map stays blank white.
Map<String, String> obicMapTileHeaders() => <String, String>{
      'User-Agent': kObicMapUserAgent,
      'Accept': 'image/png,image/jpeg,image/*,*/*;q=0.8',
    };

/// Pick tiles that work on iOS + Android (Honor/Pixel/Oppo/Xiaomi/Samsung), CN + ROW.
ObicMapTileSource resolveObicMapTiles({
  required bool preferChina,
  required Brightness brightness,
}) {
  final dark = brightness == Brightness.dark;
  if (preferChina) {
    // Amap first (GFW-friendly), then Esri, then Carto (ROAM / foreign Wi‑Fi).
    // Amap Web Mercator typically tops out ~18 — higher z = white tiles.
    return ObicMapTileSource(
      urlTemplates: [
        kAmapWprdUrl,
        kAmapWebrdUrl,
        kEsriStreetUrl,
        dark ? kCartoDarkUrl : kCartoVoyagerUrl,
      ],
      subdomains: const ['1', '2', '3', '4'],
      attribution: '© Gaode · © Esri · © CARTO',
      maxNativeZoom: 18,
      minNativeZoom: 3,
    );
  }
  if (dark) {
    return const ObicMapTileSource(
      urlTemplates: [
        kCartoDarkUrl,
        kEsriStreetUrl,
        kOsmHotUrl,
        kAmapWprdUrl,
      ],
      subdomains: ['1', '2', '3', '4'],
      attribution: '© CARTO · © Esri · © OSM · © Gaode',
      maxNativeZoom: 19,
      minNativeZoom: 3,
    );
  }
  return const ObicMapTileSource(
    urlTemplates: [
      kCartoVoyagerUrl,
      kEsriStreetUrl,
      kOsmHotUrl,
      kAmapWprdUrl,
    ],
    subdomains: ['1', '2', '3', '4'],
    attribution: '© CARTO · © Esri · © OSM · © Gaode',
    maxNativeZoom: 19,
    minNativeZoom: 3,
  );
}

/// Tile provider that tries each URL template until one image decodes.
class ObicCascadingTileProvider extends TileProvider {
  ObicCascadingTileProvider({
    required this.urlTemplates,
    Map<String, String>? headers,
    http.Client? httpClient,
    this.silenceExceptions = true,
    this.onTileResult,
    this.maxNativeZoom = 18,
    this.minNativeZoom = 3,
  })  : _isInternallyCreatedClient = httpClient == null,
        _httpClient = httpClient ?? RetryClient(http.Client()),
        super(headers: headers ?? obicMapTileHeaders());

  final List<String> urlTemplates;
  final bool silenceExceptions;
  final void Function({required bool ok})? onTileResult;
  final int maxNativeZoom;
  final int minNativeZoom;

  final http.Client _httpClient;
  final bool _isInternallyCreatedClient;

  @override
  bool get supportsCancelLoading => true;

  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) {
    // cancelLoading reserved — cascading fetch ignores mid-flight abort.
    final urls = <String>[];
    for (final template in urlTemplates) {
      urls.add(_fillTemplate(template, coordinates, options));
    }
    // Also honour TileLayer.fallbackUrl if set and not already listed.
    final fb = options.fallbackUrl;
    if (fb != null) {
      final filled = _fillTemplate(fb, coordinates, options);
      if (!urls.contains(filled)) urls.add(filled);
    }

    return _CascadingTileImageProvider(
      urls: urls,
      headers: headers,
      httpClient: _httpClient,
      silenceExceptions: silenceExceptions,
      onTileResult: onTileResult,
    );
  }

  /// Same placeholder rules as flutter_map [TileProvider] (x/y/z/s).
  /// Clamp z into [minNativeZoom, maxNativeZoom] so we never hit blank CDN z.
  String _fillTemplate(
    String urlTemplate,
    TileCoordinates coordinates,
    TileLayer options,
  ) {
    final rawZoom = (options.zoomOffset +
            (options.zoomReverse
                ? options.maxZoom - coordinates.z.toDouble()
                : coordinates.z.toDouble()))
        .round();
    final zoom = rawZoom.clamp(minNativeZoom, maxNativeZoom);
    // When camera asks for a deeper z than CDN has, request the parent tile
    // at maxNativeZoom (flutter_map also scales via maxNativeZoom).
    final scale = rawZoom > maxNativeZoom ? (1 << (rawZoom - maxNativeZoom)) : 1;
    final x = scale > 1 ? (coordinates.x ~/ scale) : coordinates.x;
    final rawY = scale > 1 ? (coordinates.y ~/ scale) : coordinates.y;
    final y = options.tms ? ((1 << zoom) - 1) - rawY : rawY;
    final s = options.subdomains.isEmpty
        ? ''
        : options.subdomains[(x + rawY) % options.subdomains.length];
    final map = <String, String>{
      'x': x.toString(),
      'y': y.toString(),
      'z': zoom.toString(),
      's': s,
      'r': options.resolvedRetinaMode == RetinaMode.server ? '@2x' : '',
      'd': options.tileDimension.toString(),
      ...options.additionalOptions,
    };
    return urlTemplate.replaceAllMapped(
      RegExp('{([^{}]*)}'),
      (match) {
        final value = map[match.group(1)!];
        if (value != null) return value;
        throw ArgumentError('Missing placeholder: {${match.group(1)}}');
      },
    );
  }

  @override
  void dispose() {
    if (_isInternallyCreatedClient) _httpClient.close();
    super.dispose();
  }
}

class _CascadingTileImageProvider
    extends ImageProvider<_CascadingTileImageProvider> {
  const _CascadingTileImageProvider({
    required this.urls,
    required this.headers,
    required this.httpClient,
    required this.silenceExceptions,
    this.onTileResult,
  });

  final List<String> urls;
  final Map<String, String> headers;
  final http.Client httpClient;
  final bool silenceExceptions;
  final void Function({required bool ok})? onTileResult;

  @override
  Future<_CascadingTileImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _CascadingTileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _load(key, chunkEvents.sink, decode).whenComplete(chunkEvents.close),
      chunkEvents: chunkEvents.stream,
      scale: 1,
      debugLabel: key.urls.isEmpty ? 'obic-tile-empty' : key.urls.first,
    );
  }

  Future<ui.Codec> _load(
    _CascadingTileImageProvider key,
    StreamSink<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    Object? lastError;
    for (final url in key.urls) {
      try {
        final uri = Uri.parse(url);
        final request = http.Request('GET', uri);
        request.headers.addAll(headers);
        final streamed = await httpClient.send(request).timeout(
              const Duration(seconds: 12),
            );
        // abortTrigger reserved for future cancel; ignore mid-flight for now.
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          await streamed.stream.drain<void>();
          lastError = HttpExceptionWithStatus(
            streamed.statusCode,
            'HTTP ${streamed.statusCode} for $url',
          );
          continue;
        }
        final bytes = await streamed.stream.toBytes();
        if (bytes.isEmpty) {
          lastError = StateError('Empty tile $url');
          continue;
        }
        final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
        onTileResult?.call(ok: true);
        return codec;
      } catch (e) {
        lastError = e;
      }
    }
    onTileResult?.call(ok: false);
    if (silenceExceptions) {
      return _decodeTransparent(decode);
    }
    throw lastError ?? StateError('No tile URLs');
  }

  Future<ui.Codec> _decodeTransparent(ImageDecoderCallback decode) async {
    return decode(
      await ui.ImmutableBuffer.fromUint8List(TileProvider.transparentImage),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _CascadingTileImageProvider &&
        listEquals(other.urls, urls);
  }

  @override
  int get hashCode => Object.hashAll(urls);
}

/// Minimal HTTP status error (avoid depending on dart:io in tests).
class HttpExceptionWithStatus implements Exception {
  HttpExceptionWithStatus(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}

/// Builds a [TileLayer] with cascading CN/ROW sources + load/error hooks.
///
/// [maxNativeZoom] stops blank white: beyond CDN limits, flutter_map scales
/// the last good tile level instead of fetching missing z.
TileLayer buildObicTileLayer({
  required ObicMapTileSource source,
  void Function({required bool ok})? onTileResult,
}) {
  return TileLayer(
    urlTemplate: source.urlTemplate,
    fallbackUrl: source.fallbackUrl,
    subdomains: source.subdomains,
    userAgentPackageName: 'com.obic.app.obic_mobile',
    minZoom: source.minNativeZoom.toDouble(),
    maxZoom: source.maxNativeZoom.toDouble(),
    minNativeZoom: source.minNativeZoom,
    maxNativeZoom: source.maxNativeZoom,
    keepBuffer: 2,
    panBuffer: 1,
    tileProvider: ObicCascadingTileProvider(
      urlTemplates: source.urlTemplates,
      headers: obicMapTileHeaders(),
      silenceExceptions: true,
      onTileResult: onTileResult,
      maxNativeZoom: source.maxNativeZoom,
      minNativeZoom: source.minNativeZoom,
    ),
  );
}
