// Made by Dr Ali
// Share hub / place + open exact pin in native maps.

import 'package:share_plus/share_plus.dart';

import '../messages/chat_location_body.dart';
import 'hub_id.dart';
import 'hub_strings.dart';

Future<void> shareObicHub({
  required ObicHubId hub,
  required HubChromeStrings strings,
}) {
  final title = strings.hubTitle;
  final url = 'https://www.obicgp.com/app/${hub.sharePath()}';
  return SharePlus.instance.share(
    ShareParams(text: '$title\n$url', subject: title),
  );
}

Future<void> shareObicPlace({
  required String name,
  required double lat,
  required double lng,
  required HubChromeStrings strings,
}) {
  final apple = appleMapsUrl(lat: lat, lng: lng, name: name);
  return SharePlus.instance.share(
    ShareParams(
      text: '${strings.sharePlace}: $name\n$apple',
      subject: name,
    ),
  );
}

Future<bool> openExactPinInMaps({
  required double lat,
  required double lng,
  String? name,
  bool preferChina = false,
}) async {
  final urls = <String>[
    if (preferChina) amapMarkerUrl(lat: lat, lng: lng, name: name),
    appleMapsUrl(lat: lat, lng: lng, name: name),
    googleMapsUrl(lat: lat, lng: lng),
    if (!preferChina) amapMarkerUrl(lat: lat, lng: lng, name: name),
  ];
  for (final url in urls) {
    if (await openMapUrl(url)) return true;
  }
  return false;
}
