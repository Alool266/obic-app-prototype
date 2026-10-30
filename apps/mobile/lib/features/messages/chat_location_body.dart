// Made by Dr Ali
// Pure helper — GPS share message body + parse (WeChat-style location card).
// China-first: Amap (高德) uses lng,lat; Apple + Google use lat,lng.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/obic_phrases.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/obic_logo.dart';
import 'obic_map_tiles.dart';
import 'obic_map_view.dart';

/// Whether to lead with Amap (mainland CN often blocks Google).
bool preferChinaMapLinks({
  String? localeLanguageCode,
  String? localeCountryCode,
  String? savedRegionCountry,
  String? placemarkIsoCountry,
}) {
  final lang = (localeLanguageCode ?? '').toLowerCase();
  if (lang == 'zh') return true;
  for (final c in [
    localeCountryCode,
    savedRegionCountry,
    placemarkIsoCountry,
  ]) {
    final iso = c?.trim().toUpperCase();
    if (iso == 'CN' || iso == 'HK' || iso == 'MO') return true;
  }
  return false;
}

/// Amap marker URI — **position is longitude,latitude** (WGS84 from GPS).
String amapMarkerUrl({required double lat, required double lng, String? name}) {
  final pos = '$lng,$lat';
  final params = <String, String>{
    'position': pos,
    'coordinate': 'wgs84',
    'callnative': '1',
  };
  if (name != null && name.trim().isNotEmpty) {
    params['name'] = name.trim();
  }
  return Uri.https('uri.amap.com', '/marker', params).toString();
}

String appleMapsUrl({required double lat, required double lng, String? name}) {
  final q = (name != null && name.trim().isNotEmpty)
      ? name.trim()
      : '$lat,$lng';
  return Uri.https('maps.apple.com', '/', {
    'll': '$lat,$lng',
    'q': q,
  }).toString();
}

String googleMapsUrl({required double lat, required double lng}) {
  return 'https://maps.google.com/?q=$lat,$lng';
}

class MapLinkRow {
  const MapLinkRow({required this.label, required this.url});
  final String label;
  final String url;
}

class ParsedLocationShare {
  const ParsedLocationShare({
    required this.label,
    required this.lat,
    required this.lng,
    required this.links,
    required this.preferChina,
  });

  final String label;
  final double lat;
  final double lng;
  final List<MapLinkRow> links;
  final bool preferChina;

  String get primaryUrl =>
      links.isNotEmpty ? links.first.url : googleMapsUrl(lat: lat, lng: lng);

  String get primaryLabel => links.isNotEmpty ? links.first.label : 'Maps';
}

/// Builds a chat location message with tap-to-open map links.
///
/// Includes a machine line `[[obic:loc:lat,lng]]` for reliable card parsing.
/// China preference → Amap, Apple, Google.
/// Otherwise → Google, Apple, Amap (Amap still useful for CN recipients).
String buildLocationShareBody({
  required String label,
  required double lat,
  required double lng,
  bool preferChina = true,

  /// `zh` | `en` | `ar` — link row labels.
  String linkLocale = 'en',
}) {
  final amap = amapMarkerUrl(lat: lat, lng: lng, name: label);
  final apple = appleMapsUrl(lat: lat, lng: lng, name: label);
  final google = googleMapsUrl(lat: lat, lng: lng);

  final amapLabel = switch (linkLocale) {
    'zh' => '高德地图',
    'ar' => 'خريطة Amap',
    _ => 'Amap',
  };
  final appleLabel = switch (linkLocale) {
    'zh' => 'Apple 地图',
    'ar' => 'Apple Maps',
    _ => 'Apple Maps',
  };
  final googleLabel = switch (linkLocale) {
    'zh' => 'Google 地图',
    'ar' => 'Google Maps',
    _ => 'Google Maps',
  };

  final lines = <String>[
    '📍 $label',
    '[[obic:loc:${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}]]',
    '',
  ];
  if (preferChina) {
    lines.addAll([
      '$amapLabel: $amap',
      '$appleLabel: $apple',
      '$googleLabel: $google',
    ]);
  } else {
    lines.addAll([
      '$googleLabel: $google',
      '$appleLabel: $apple',
      '$amapLabel: $amap',
    ]);
  }
  return lines.join('\n');
}

/// Parse a location share body (new + legacy multi-URL text).
ParsedLocationShare? parseLocationShareBody(String body) {
  final text = body.trim();
  if (text.isEmpty) return null;

  final machine = RegExp(
    r'\[\[obic:loc:(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)\]\]',
  ).firstMatch(text);

  double? lat;
  double? lng;
  if (machine != null) {
    lat = double.tryParse(machine.group(1)!);
    lng = double.tryParse(machine.group(2)!);
  }

  // Legacy / fallback: Google ?q=lat,lng or Apple ll=lat,lng or Amap position=lng,lat
  if (lat == null || lng == null) {
    final google = RegExp(
      r'maps\.google\.com/\?q=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)',
    ).firstMatch(text);
    if (google != null) {
      lat = double.tryParse(google.group(1)!);
      lng = double.tryParse(google.group(2)!);
    }
  }
  if (lat == null || lng == null) {
    final apple = RegExp(
      r'maps\.apple\.com/[^\s]*[?&]ll=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)',
    ).firstMatch(text);
    if (apple != null) {
      lat = double.tryParse(apple.group(1)!);
      lng = double.tryParse(apple.group(2)!);
    }
  }
  if (lat == null || lng == null) {
    final amap = RegExp(
      r'uri\.amap\.com/marker[^\s]*position=(-?\d+(?:\.\d+)?)%2C(-?\d+(?:\.\d+)?)|'
      r'uri\.amap\.com/marker[^\s]*position=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)',
    ).firstMatch(text);
    if (amap != null) {
      final a = amap.group(1) ?? amap.group(3);
      final b = amap.group(2) ?? amap.group(4);
      if (a != null && b != null) {
        lng = double.tryParse(a);
        lat = double.tryParse(b);
      }
    }
  }

  if (lat == null || lng == null) {
    // Not a location message (must have pin emoji + map URL, or machine tag).
    final looksLike =
        text.contains('📍') &&
        (text.contains('uri.amap.com') ||
            text.contains('maps.apple.com') ||
            text.contains('maps.google.com') ||
            text.contains('[[obic:loc:'));
    if (!looksLike) return null;
    return null;
  }

  String label = '';
  final firstLine = text.split('\n').first.trim();
  if (firstLine.startsWith('📍')) {
    label = firstLine.replaceFirst('📍', '').trim();
  }
  if (label.isEmpty) {
    label = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  final preferChina =
      text.contains('uri.amap.com') &&
      (text.indexOf('uri.amap.com') <
          (text.contains('maps.google.com')
              ? text.indexOf('maps.google.com')
              : 1 << 30));

  final links = <MapLinkRow>[];
  void addLink(String labelZh, String labelEn, String url) {
    if (url.isEmpty) return;
    final useZh = text.contains(labelZh);
    links.add(MapLinkRow(label: useZh ? labelZh : labelEn, url: url));
  }

  final amapM = RegExp(r'https://uri\.amap\.com/marker[^\s]+').firstMatch(text);
  final appleM = RegExp(r'https://maps\.apple\.com/[^\s]+').firstMatch(text);
  final googleM = RegExp(r'https://maps\.google\.com/[^\s]+').firstMatch(text);

  if (preferChina) {
    if (amapM != null) addLink('高德地图', 'Amap', amapM.group(0)!);
    if (appleM != null) addLink('Apple 地图', 'Apple Maps', appleM.group(0)!);
    if (googleM != null) {
      addLink('Google 地图', 'Google Maps', googleM.group(0)!);
    }
  } else {
    if (googleM != null) {
      addLink('Google 地图', 'Google Maps', googleM.group(0)!);
    }
    if (appleM != null) addLink('Apple 地图', 'Apple Maps', appleM.group(0)!);
    if (amapM != null) addLink('高德地图', 'Amap', amapM.group(0)!);
  }

  if (links.isEmpty) {
    final rebuilt = preferChina
        ? [
            MapLinkRow(
              label: 'Amap',
              url: amapMarkerUrl(lat: lat, lng: lng, name: label),
            ),
            MapLinkRow(
              label: 'Apple Maps',
              url: appleMapsUrl(lat: lat, lng: lng, name: label),
            ),
            MapLinkRow(
              label: 'Google Maps',
              url: googleMapsUrl(lat: lat, lng: lng),
            ),
          ]
        : [
            MapLinkRow(
              label: 'Google Maps',
              url: googleMapsUrl(lat: lat, lng: lng),
            ),
            MapLinkRow(
              label: 'Apple Maps',
              url: appleMapsUrl(lat: lat, lng: lng, name: label),
            ),
            MapLinkRow(
              label: 'Amap',
              url: amapMarkerUrl(lat: lat, lng: lng, name: label),
            ),
          ];
    links.addAll(rebuilt);
  }

  return ParsedLocationShare(
    label: label,
    lat: lat,
    lng: lng,
    links: links,
    preferChina: preferChina,
  );
}

/// Native Amap app (高德). `dev=1` means the coordinates are GPS/WGS84.
Uri amapNativeAppUri({required double lat, required double lng, String? name}) {
  final scheme = defaultTargetPlatform == TargetPlatform.iOS
      ? 'iosamap'
      : 'androidamap';
  final poiname = Uri.encodeComponent(
    (name == null || name.trim().isEmpty) ? 'OBIC' : name.trim(),
  );
  return Uri.parse(
    '$scheme://viewMap?sourceApplication=OBIC&poiname=$poiname&lat=$lat&lon=$lng&dev=1',
  );
}

Uri baiduNativeUri({required double lat, required double lng, String? name}) {
  final title = (name == null || name.trim().isEmpty) ? 'OBIC' : name.trim();
  return Uri.parse(
    'baidumap://map/marker?location=$lat,$lng&title=${Uri.encodeComponent(title)}&content=${Uri.encodeComponent(title)}&coord_type=wgs84',
  );
}

String baiduWebUrl({required double lat, required double lng, String? name}) {
  final title = (name == null || name.trim().isEmpty) ? 'OBIC' : name.trim();
  return Uri.https('api.map.baidu.com', '/marker', {
    'location': '$lat,$lng',
    'title': title,
    'content': title,
    'output': 'html',
    'coord_type': 'wgs84',
  }).toString();
}

Uri googleNativeUri({required double lat, required double lng, String? name}) {
  final q = (name != null && name.trim().isNotEmpty) ? name.trim() : '$lat,$lng';
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return Uri.parse('comgooglemaps://?q=${Uri.encodeComponent(q)}&center=$lat,$lng');
  }
  return Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(q)})');
}

Uri appleNativeUri({required double lat, required double lng, String? name}) {
  final q = (name != null && name.trim().isNotEmpty) ? name.trim() : '$lat,$lng';
  return Uri.parse('maps://?ll=$lat,$lng&q=${Uri.encodeComponent(q)}');
}

Future<bool> _launchUri(Uri uri, {required bool native}) async {
  try {
    return await launchUrl(
      uri,
      mode: native
          ? LaunchMode.externalNonBrowserApplication
          : LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

Future<bool> openMapUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (uri.host == 'uri.amap.com') {
    final pos = uri.queryParameters['position'];
    if (pos != null && pos.contains(',')) {
      final parts = pos.split(',');
      final lng = double.tryParse(parts[0]);
      final lat = parts.length > 1 ? double.tryParse(parts[1]) : null;
      if (lat != null && lng != null) {
        final native = amapNativeAppUri(
          lat: lat,
          lng: lng,
          name: uri.queryParameters['name'],
        );
        if (await _launchUri(native, native: true)) return true;
      }
    }
    return _launchUri(uri, native: false);
  }
  final nativeScheme = uri.scheme == 'androidamap' ||
      uri.scheme == 'iosamap' ||
      uri.scheme == 'amapuri' ||
      uri.scheme == 'baidumap' ||
      uri.scheme == 'comgooglemaps' ||
      uri.scheme == 'maps' ||
      uri.scheme == 'geo';
  if (await _launchUri(uri, native: nativeScheme)) return true;
  if (uri.scheme == 'https' || uri.scheme == 'http') {
    return _launchUri(uri, native: false);
  }
  return false;
}

class _MapChoice {
  const _MapChoice({required this.label, this.native, required this.web});
  final String label;
  final Uri? native;
  final Uri web;
}

/// Installed map apps only. Apple Maps is always listed on iPhone.
/// If the native app still fails, the web page opens in the browser.
Future<void> showMapAppPicker(
  BuildContext context, {
  required double lat,
  required double lng,
  String? name,
}) async {
  final choices = <_MapChoice>[];
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    choices.add(
      _MapChoice(
        label: 'Apple Maps',
        native: appleNativeUri(lat: lat, lng: lng, name: name),
        web: Uri.parse(appleMapsUrl(lat: lat, lng: lng, name: name)),
      ),
    );
  }
  Future<void> addIfInstalled(_MapChoice choice) async {
    final native = choice.native;
    if (native == null) {
      choices.add(choice);
      return;
    }
    try {
      if (await canLaunchUrl(native)) choices.add(choice);
    } catch (_) {}
  }

  await addIfInstalled(
    _MapChoice(
      label: 'Amap',
      native: amapNativeAppUri(lat: lat, lng: lng, name: name),
      web: Uri.parse(amapMarkerUrl(lat: lat, lng: lng, name: name)),
    ),
  );
  await addIfInstalled(
    _MapChoice(
      label: 'Baidu Maps',
      native: baiduNativeUri(lat: lat, lng: lng, name: name),
      web: Uri.parse(baiduWebUrl(lat: lat, lng: lng, name: name)),
    ),
  );
  await addIfInstalled(
    _MapChoice(
      label: 'Google Maps',
      native: googleNativeUri(lat: lat, lng: lng, name: name),
      web: Uri.parse(googleMapsUrl(lat: lat, lng: lng)),
    ),
  );
  if (!context.mounted) return;
  if (choices.isEmpty) {
    choices.addAll([
      _MapChoice(
        label: 'Amap',
        web: Uri.parse(amapMarkerUrl(lat: lat, lng: lng, name: name)),
      ),
      _MapChoice(
        label: 'Baidu Maps',
        web: Uri.parse(baiduWebUrl(lat: lat, lng: lng, name: name)),
      ),
      _MapChoice(
        label: 'Google Maps',
        web: Uri.parse(googleMapsUrl(lat: lat, lng: lng)),
      ),
    ]);
  }
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: ObicColors.surfaceRaisedOf(context),
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            children: [
              for (final choice in choices)
                ListTile(
                  title: Text(
                    choice.label,
                    style: TextStyle(
                      color: ObicColors.inkOf(ctx),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final native = choice.native;
                    final opened = native != null &&
                        await _launchUri(native, native: true);
                    if (!opened) {
                      await _launchUri(choice.web, native: false);
                    }
                  },
                ),
              ListTile(
                title: Text(
                  obicPhrase(ctx, ar: 'إلغاء', en: 'Cancel', zh: '取消'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ObicColors.mutedOf(ctx)),
                ),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Placemark → human label; falls back to rounded coordinates.
String locationLabelFromPlacemark({
  String? locality,
  String? administrativeArea,
  String? country,
  required double lat,
  required double lng,
}) {
  final city = (locality != null && locality.trim().isNotEmpty)
      ? locality.trim()
      : (administrativeArea != null && administrativeArea.trim().isNotEmpty)
      ? administrativeArea.trim()
      : null;
  final c = country?.trim();
  if (city != null && city.isNotEmpty) {
    if (c != null && c.isNotEmpty) return '$city, $c';
    return city;
  }
  if (c != null && c.isNotEmpty) return c;
  return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}

/// `language`_[country] tag for [setLocaleIdentifier] so addresses follow the app language.
String geocoderLocaleTag(String languageCode) {
  return switch (languageCode) {
    'zh' => 'zh_CN',
    'ar' => 'ar',
    'fr' => 'fr_FR',
    'en' => 'en_US',
    _ => 'en_US',
  };
}

bool looksLikeCoordinates(String raw) {
  final t = raw.trim();
  return RegExp(r'^-?\d{1,3}\.\d+\s*,\s*-?\d{1,3}\.\d+$').hasMatch(t);
}

bool _placeNoise(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return true;
  if (looksLikeCoordinates(t)) return true;
  if (RegExp(r'^\d+$').hasMatch(t)) return true;
  if (RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}').hasMatch(t)) return true;
  final lower = t.toLowerCase();
  if (lower == 'unnamed road' || lower == 'null') return true;
  return false;
}

/// Street → district → city → region → country, in the geocoder’s language.
class PlaceAddress {
  const PlaceAddress({this.lines = const [], this.isoCountryCode});

  final List<String> lines;
  final String? isoCountryCode;

  bool get isEmpty => lines.isEmpty;

  String get title => lines.isEmpty ? '' : lines.first;

  List<String> get details => lines.length < 2 ? const [] : lines.sublist(1);

  /// One line for a chat card. Never a raw lat,lng pair.
  String get shareLabel => lines.join(', ');
}

PlaceAddress placeAddressFromPlacemark(Placemark place) {
  final streetBits = <String>[];
  void addStreet(String? raw) {
    final t = raw?.trim() ?? '';
    if (_placeNoise(t)) return;
    if (streetBits.any((b) => b.toLowerCase() == t.toLowerCase())) return;
    streetBits.add(t);
  }

  addStreet(place.subThoroughfare);
  addStreet(place.thoroughfare);
  if (streetBits.isEmpty) addStreet(place.street);
  final street = streetBits.join(' ').trim();

  final lines = <String>[];
  void add(String? raw) {
    final t = raw?.trim() ?? '';
    if (_placeNoise(t)) return;
    if (lines.any((b) => b.toLowerCase() == t.toLowerCase())) return;
    lines.add(t);
  }

  // Most specific first: place name, then street, then city and country.
  add(place.name);
  add(street);
  add(place.subLocality);
  add(place.locality);
  add(place.subAdministrativeArea);
  add(place.administrativeArea);
  add(place.country);

  return PlaceAddress(lines: lines, isoCountryCode: place.isoCountryCode);
}

/// Reverse-geocode in the app language. Empty lines mean the address is unknown.
Future<PlaceAddress> lookupPlaceAddress({
  required double lat,
  required double lng,
  required String languageCode,
}) async {
  try {
    await setLocaleIdentifier(geocoderLocaleTag(languageCode));
    final places = await placemarkFromCoordinates(lat, lng);
    if (places.isEmpty) return const PlaceAddress();
    return placeAddressFromPlacemark(places.first);
  } catch (_) {
    return const PlaceAddress();
  }
}

String mapAddressPending(String lang) {
  return switch (lang) {
    'zh' => '正在获取地址…',
    'ar' => 'جارٍ تحديد العنوان…',
    'fr' => 'Recherche de l’adresse…',
    _ => 'Finding address…',
  };
}

String mapAddressUnavailable(String lang) {
  return switch (lang) {
    'zh' => '无法获取详细地址',
    'ar' => 'تعذّر عرض تفاصيل العنوان',
    'fr' => 'Adresse détaillée indisponible',
    _ => 'Detailed address unavailable',
  };
}

String mapPlaceNotFound(String lang) {
  return switch (lang) {
    'zh' => '未找到该地点',
    'ar' => 'لم يُعثر على المكان',
    'fr' => 'Lieu introuvable',
    _ => 'Place not found',
  };
}

String mapSelectedPlaceFallback(String lang) {
  return switch (lang) {
    'zh' => '所选位置',
    'ar' => 'الموقع المحدد',
    'fr' => 'Lieu sélectionné',
    _ => 'Selected location',
  };
}

/// WeChat-style location bubble — map strip + label; tap opens map sheet.
class ChatLocationBubble extends StatelessWidget {
  const ChatLocationBubble({
    super.key,
    required this.parsed,
    required this.mine,
  });

  final ParsedLocationShare parsed;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final locLabel = switch (lang) {
      'zh' => '位置',
      'ar' => 'الموقع',
      'fr' => 'Lieu',
      _ => 'Location',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showLocationMapSheet(context, parsed),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: mine
                        ? const [Color(0xFF5B8C5A), Color(0xFF3D6B4F)]
                        : const [Color(0xFF8FBC8F), Color(0xFF5F8F6A)],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft “map” grid feel without external tiles.
                    CustomPaint(
                      size: const Size(220, 96),
                      painter: _MapGridPainter(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      size: 40,
                      color: Color(0xFFE53935),
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: mine ? Colors.white : const Color(0xFFF7F7F7),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      looksLikeCoordinates(parsed.label)
                          ? mapSelectedPlaceFallback(lang)
                          : parsed.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF191919),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
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

class _MapGridPainter extends CustomPainter {
  _MapGridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 18.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// WeChat-like: open in-app OBIC map (external apps secondary).
Future<void> showLocationMapSheet(
  BuildContext context,
  ParsedLocationShare parsed,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ObicMapScreen(parsed: parsed)),
  );
}

/// Address under the pin — street, district, city, region, country in the app language.
class MapPlaceDetails extends StatefulWidget {
  const MapPlaceDetails({
    super.key,
    required this.lat,
    required this.lng,
    this.fallbackLabel,
  });

  final double lat;
  final double lng;
  final String? fallbackLabel;

  @override
  State<MapPlaceDetails> createState() => _MapPlaceDetailsState();
}

class _MapPlaceDetailsState extends State<MapPlaceDetails> {
  String? _lang;
  PlaceAddress _place = const PlaceAddress();
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (_lang == lang) return;
    _lang = lang;
    _load(lang);
  }

  Future<void> _load(String lang) async {
    setState(() => _loading = true);
    final place = await lookupPlaceAddress(
      lat: widget.lat,
      lng: widget.lng,
      languageCode: lang,
    );
    if (!mounted || _lang != lang) return;
    setState(() {
      _place = place;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final muted = ObicColors.mutedOf(context);
    final ink = ObicColors.inkOf(context);
    final fallback = widget.fallbackLabel?.trim() ?? '';
    final fallbackOk = fallback.isNotEmpty && !looksLikeCoordinates(fallback);

    if (_loading && _place.isEmpty) {
      return Text(
        fallbackOk ? fallback : mapAddressPending(lang),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
      );
    }

    final lines = _place.lines.isNotEmpty
        ? _place.lines
        : (fallbackOk ? [fallback] : <String>[]);
    if (lines.isEmpty) {
      return Text(
        mapAddressUnavailable(lang),
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lines.first,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        for (final line in lines.skip(1)) ...[
          const SizedBox(height: 2),
          Text(line, style: TextStyle(fontSize: 13, height: 1.3, color: muted)),
        ],
      ],
    );
  }
}

/// Full-screen OBIC map — multi-CDN tiles (CN + worldwide) + pin.
class ObicMapScreen extends StatelessWidget {
  const ObicMapScreen({super.key, required this.parsed});

  final ParsedLocationShare parsed;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final brand = switch (lang) {
      'zh' => 'OBIC 地图',
      'ar' => 'خريطة OBIC',
      'fr' => 'Carte OBIC',
      _ => 'OBIC Map',
    };
    final openExt = switch (lang) {
      'zh' => '在地图中打开',
      'ar' => 'فتح في الخرائط',
      'fr' => 'Ouvrir dans Plans',
      _ => 'Open in maps',
    };
    final point = LatLng(parsed.lat, parsed.lng);
    final preferChina =
        parsed.preferChina ||
        lang == 'zh' ||
        coordsSuggestChina(parsed.lat, parsed.lng);
    final sheetBg = ObicColors.surfaceOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFDCE6EE),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ObicMapView(
            initialCenter: point,
            preferChina: preferChina,
            interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            children: [
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      size: 48,
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
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  Material(
                    color: sheetBg.withValues(alpha: 0.94),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: ObicColors.inkOf(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: sheetBg.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ObicLogo(size: 22, borderRadius: 5),
                        const SizedBox(width: 6),
                        Text(
                          brand,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: ObicColors.titleOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.46,
                ),
                child: SingleChildScrollView(
              child: Container(
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
                    MapPlaceDetails(
                      lat: parsed.lat,
                      lng: parsed.lng,
                      fallbackLabel: parsed.label,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => showMapAppPicker(
                        context,
                        lat: parsed.lat,
                        lng: parsed.lng,
                        name: parsed.label,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: ObicColors.navy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(openExt),
                    ),
                  ],
                ),
              ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
