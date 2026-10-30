// Made by Dr Ali
// First-party OBIC website, hubs, productivity suite + approved partner pages.
// The public list is not a raw URL opener.

import 'package:flutter/material.dart' show IconData, Icons;

import '../../core/api_config.dart';
import 'mini_app_navigation.dart';

/// First-party site that already opens inside the app.
const kObicWebsiteMiniAppUrl = 'https://www.obicgp.com';
const kObicMusicMiniAppId = 'obic-music';
const kObicYemenMiniAppId = 'obic-yemen-in-hand';
const kObicChinaMiniAppId = 'obic-china-in-hand';
const kObicMideastMiniAppId = 'obic-mideast-in-hand';
const kObicAfricaMiniAppId = 'obic-africa-in-hand';
const kObicDailyMiniAppId = 'obic-daily';
const kObicTravelMiniAppId = 'obic-travel';
const kObicNotesMiniAppId = 'obic-notes';
const kObicDocumentsMiniAppId = 'obic-documents';
const kObicSpreadsheetsMiniAppId = 'obic-spreadsheets';
const kObicPdfMiniAppId = 'obic-pdf';
const kObicSlidesMiniAppId = 'obic-slides';

/// Geo tags for soft regional filtering (catalog still lists all when "All").
enum MiniAppGeo {
  global,
  china,
  mideast,
  africa,
  yemen,
}

class MiniAppEntry {
  const MiniAppEntry({
    required this.id,
    required this.name,
    required this.startUrl,
    this.description = '',
    this.iconUrl,
    this.firstParty = false,
    this.native = true,
    this.comingSoon = false,
    this.keywords = '',
    this.geo = MiniAppGeo.global,
    this.icon,
  });

  final String id;
  final String name;
  final String startUrl;
  final String description;
  final String? iconUrl;
  final bool firstParty;
  final bool native;
  final bool comingSoon;
  final String keywords;
  final MiniAppGeo geo;
  final IconData? icon;

  bool get canOpen {
    if (comingSoon) return false;
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
    native: false,
    keywords: 'website site موقع 网站 site web',
    icon: Icons.language_rounded,
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
    icon: Icons.music_note_rounded,
  );
}

MiniAppEntry obicYemenInHandMiniApp(String langCode) {
  final name = langCode.startsWith('ar')
      ? 'اليمن بين يديك'
      : langCode.startsWith('zh')
          ? '也门尽在掌握'
          : langCode.startsWith('fr')
              ? 'Le Yémen en main'
              : 'Yemen in your hand';
  return MiniAppEntry(
    id: kObicYemenMiniAppId,
    name: name,
    startUrl: 'obic://yemen-in-hand',
    firstParty: true,
    native: true,
    keywords: 'yemen yemeni يمن 也门 yémen hub خدمات',
    geo: MiniAppGeo.yemen,
    icon: Icons.flag_rounded,
  );
}

List<MiniAppEntry> firstPartyProductivityAndHubs(String langCode) {
  final ar = langCode.startsWith('ar');
  final zh = langCode.startsWith('zh');
  final fr = langCode.startsWith('fr');
  String t(String en, String a, String z, String f) =>
      ar ? a : zh ? z : fr ? f : en;

  return [
    MiniAppEntry(
      id: kObicNotesMiniAppId,
      name: t('Notes', 'ملاحظات', '笔记', 'Notes'),
      startUrl: 'obic://office/notes',
      firstParty: true,
      native: true,
      keywords: 'notes ملاحظات 笔记 memo',
      icon: Icons.sticky_note_2_rounded,
    ),
    MiniAppEntry(
      id: kObicDocumentsMiniAppId,
      name: t('Documents', 'مستندات', '文档', 'Documents'),
      startUrl: 'obic://office/documents',
      firstParty: true,
      native: true,
      keywords: 'docs word مستند 文档 document',
      icon: Icons.description_rounded,
    ),
    MiniAppEntry(
      id: kObicSpreadsheetsMiniAppId,
      name: t('Spreadsheets', 'جداول', '表格', 'Feuilles'),
      startUrl: 'obic://office/spreadsheets',
      firstParty: true,
      native: true,
      keywords: 'excel sheets جداول 表格 spreadsheet',
      icon: Icons.grid_on_rounded,
    ),
    MiniAppEntry(
      id: kObicPdfMiniAppId,
      name: t('PDF', 'PDF', 'PDF', 'PDF'),
      startUrl: 'obic://office/pdf',
      firstParty: true,
      native: true,
      keywords: 'pdf viewer عرض',
      icon: Icons.picture_as_pdf_rounded,
    ),
    MiniAppEntry(
      id: kObicSlidesMiniAppId,
      name: t('Slides', 'عروض', '演示', 'Diapositives'),
      startUrl: 'obic://office/slides',
      firstParty: true,
      native: true,
      comingSoon: true,
      keywords: 'slides powerpoint عروض 演示',
      icon: Icons.slideshow_rounded,
    ),
    MiniAppEntry(
      id: kObicChinaMiniAppId,
      name: t('China in your hand', 'الصين بين يديك', '中国尽在掌握', 'Chine en main'),
      startUrl: 'obic://china-in-hand',
      firstParty: true,
      native: true,
      keywords: 'china الصين 中国 hub',
      geo: MiniAppGeo.china,
      icon: Icons.public_rounded,
    ),
    MiniAppEntry(
      id: kObicMideastMiniAppId,
      name: t(
        'Middle East in your hand',
        'الشرق الأوسط بين يديك',
        '中东尽在掌握',
        'Moyen-Orient en main',
      ),
      startUrl: 'obic://mideast-in-hand',
      firstParty: true,
      native: true,
      keywords: 'mideast middle east الشرق 中东 hub',
      geo: MiniAppGeo.mideast,
      icon: Icons.mosque_rounded,
    ),
    MiniAppEntry(
      id: kObicAfricaMiniAppId,
      name: t(
        'Africa in your hand',
        'أفريقيا بين يديك',
        '非洲尽在掌握',
        'Afrique en main',
      ),
      startUrl: 'obic://africa-in-hand',
      firstParty: true,
      native: true,
      keywords: 'africa أفريقيا 非洲 hub',
      geo: MiniAppGeo.africa,
      icon: Icons.travel_explore_rounded,
    ),
    MiniAppEntry(
      id: kObicDailyMiniAppId,
      name: t('Daily', 'يومي', '日常', 'Quotidien'),
      startUrl: 'obic://daily',
      firstParty: true,
      native: true,
      keywords: 'daily يومي 日常 marketplace',
      icon: Icons.storefront_rounded,
    ),
    MiniAppEntry(
      id: kObicTravelMiniAppId,
      name: t('Travel', 'سفر', '旅行', 'Voyage'),
      startUrl: 'obic://travel',
      firstParty: true,
      native: true,
      keywords: 'travel سفر 旅行 hotel flight',
      icon: Icons.flight_takeoff_rounded,
    ),
  ];
}

/// Soft geo filter — keeps global + matching region; empty region = all.
List<MiniAppEntry> filterMiniAppsByGeo(
  List<MiniAppEntry> apps,
  MiniAppGeo? focus,
) {
  if (focus == null || focus == MiniAppGeo.global) return apps;
  return apps
      .where((a) => a.geo == MiniAppGeo.global || a.geo == focus)
      .toList();
}

MiniAppGeo? geoFromLocaleOrCountry(String? countryOrLocale) {
  final c = (countryOrLocale ?? '').toLowerCase();
  if (c.contains('cn') || c.contains('china') || c.contains('zh')) {
    return MiniAppGeo.china;
  }
  if (c.contains('ye') || c.contains('yemen')) return MiniAppGeo.yemen;
  if (c.contains('sa') ||
      c.contains('ae') ||
      c.contains('eg') ||
      c.contains('ar') ||
      c.contains('mideast') ||
      c.contains('middle')) {
    return MiniAppGeo.mideast;
  }
  if (c.contains('ng') ||
      c.contains('za') ||
      c.contains('ke') ||
      c.contains('africa')) {
    return MiniAppGeo.africa;
  }
  return null;
}

/// Keep the website tile, hubs, productivity, then approved pages — no URL dupes.
List<MiniAppEntry> mergeApprovedMiniApps(
  MiniAppEntry website,
  List<MiniAppEntry> firstParty,
  List<MiniAppEntry> approved,
) {
  final seenIds = <String>{};
  final seenUrls = <String>{_urlKey(website.startUrl)};
  final out = <MiniAppEntry>[website];
  seenIds.add(website.id);

  for (final app in [...firstParty, ...approved]) {
    if (app.id.isEmpty || !seenIds.add(app.id)) continue;
    if (app.comingSoon) {
      out.add(app);
      continue;
    }
    if (!app.canOpen && !app.native) continue;
    final key = _urlKey(app.startUrl);
    if (app.startUrl.startsWith('obic://') || seenUrls.add(key)) {
      out.add(app);
    }
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
    description:
        json['description'] is String ? json['description'] as String : '',
    iconUrl: json['iconUrl'] is String ? json['iconUrl'] as String : null,
    firstParty: false,
    native: false,
  );
  if (!entry.canOpen || entry.name.isEmpty) return null;
  return entry;
}

/// Absolute URL the engine loads. Partner items always use the API host.
String? engineStartUrlFor(MiniAppEntry app) {
  if (app.comingSoon || !app.canOpen) return null;
  if (app.native) return null;
  if (app.firstParty) return approvedMiniAppUri(app.startUrl)?.toString();
  final absolute = '$kApiBaseUrl${hostedPackageIndexPath(app.id)}';
  return approvedMiniAppUri(absolute)?.toString();
}
