// Made by Dr Ali
// First-party OBIC website plus approved partner pages.
// The public list is not a raw URL opener.

import '../../core/api_config.dart';
import 'mini_app_navigation.dart';

/// First-party site that already opens inside the app.
const kObicWebsiteMiniAppUrl = 'https://www.obicgp.com';
const kObicMusicMiniAppId = 'obic-music';

class MiniAppEntry {
  const MiniAppEntry({
    required this.id,
    required this.name,
    required this.startUrl,
    this.description = '',
    this.iconUrl,
    this.firstParty = false,
    this.native = false,
    this.keywords = '',
  });

  final String id;
  final String name;
  final String startUrl;
  final String description;
  final String? iconUrl;
  final bool firstParty;
  final bool native;
  final String keywords;

  bool get canOpen {
    if (native) return true;
    if (firstParty) {
      final uri = approvedMiniAppUri(startUrl);
      return uri != null && uri.host == 'www.obicgp.com';
    }
    return isHostedPackageStart(id, startUrl);
  }
}

MiniAppEntry obicWebsiteMiniApp(String localizedName) {
  return MiniAppEntry(
    id: 'obic-web',
    name: localizedName,
    startUrl: kObicWebsiteMiniAppUrl,
    firstParty: true,
    keywords: 'website site موقع 网站 site web',
  );
}

MiniAppEntry obicMusicMiniApp(String langCode) {
  final name = langCode.startsWith('ar')
      ? 'موسيقى OBIC'
      : langCode.startsWith('zh')
      ? 'OBIC 音乐'
      : langCode.startsWith('fr')
      ? 'OBIC Musique'
      : 'OBIC Music';
  return MiniAppEntry(
    id: kObicMusicMiniAppId,
    name: name,
    startUrl: 'obic://music',
    firstParty: true,
    native: true,
    keywords: 'music musique موسيقى 音乐 song أغنية 歌曲 chanson',
  );
}

/// Keep the website tile, then approved pages that are not the same URL.
List<MiniAppEntry> mergeApprovedMiniApps(
  MiniAppEntry website,
  List<MiniAppEntry> approved,
) {
  final seen = <String>{_urlKey(website.startUrl)};
  final out = <MiniAppEntry>[website];
  for (final app in approved) {
    if (!app.canOpen || app.id.isEmpty) continue;
    final key = _urlKey(app.startUrl);
    if (!seen.add(key)) continue;
    out.add(app);
  }
  return out;
}

String _urlKey(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return raw.trim();
  var path = uri.path;
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return '${uri.scheme}://${uri.host}$path';
}

MiniAppEntry? miniAppFromPublicJson(Map<String, dynamic> json) {
  final status = json['status'];
  if (status != 'approved') return null;
  final id = json['id'];
  final name = json['name'];
  final startUrl = json['startUrl'];
  if (id is! String || name is! String || startUrl is! String) return null;
  if (!isHostedPackageStart(id, startUrl)) return null;
  final entry = MiniAppEntry(
    id: id,
    name: name.trim(),
    startUrl: hostedPackageIndexPath(id),
    description: json['description'] is String ? json['description'] as String : '',
    iconUrl: json['iconUrl'] is String ? json['iconUrl'] as String : null,
  );
  if (!entry.canOpen || entry.name.isEmpty) return null;
  return entry;
}

/// Absolute URL the engine loads. Partner items always use the API host.
String? engineStartUrlFor(MiniAppEntry app) {
  if (!app.canOpen) return null;
  if (app.firstParty) return approvedMiniAppUri(app.startUrl)?.toString();
  final absolute = '$kApiBaseUrl${hostedPackageIndexPath(app.id)}';
  return approvedMiniAppUri(absolute)?.toString();
}
