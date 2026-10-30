// Made by Dr Ali
// Client for /v1/hub-content — guides, places, deals, category copy.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/media_url.dart';

class HubGuideDto {
  const HubGuideDto({
    required this.id,
    required this.hub,
    required this.titleAr,
    required this.titleEn,
    required this.titleZh,
    required this.summaryAr,
    required this.summaryEn,
    required this.summaryZh,
    required this.bodyAr,
    required this.bodyEn,
    required this.bodyZh,
    this.imageUrl,
    this.categoryId,
    this.ctaLabelAr,
    this.ctaLabelEn,
  });

  final String id;
  final String hub;
  final String titleAr;
  final String titleEn;
  final String titleZh;
  final String summaryAr;
  final String summaryEn;
  final String summaryZh;
  final String bodyAr;
  final String bodyEn;
  final String bodyZh;
  final String? imageUrl;
  final String? categoryId;
  final String? ctaLabelAr;
  final String? ctaLabelEn;

  factory HubGuideDto.fromJson(Map<String, dynamic> j) => HubGuideDto(
        id: j['id'] as String? ?? '',
        hub: j['hub'] as String? ?? '',
        titleAr: j['titleAr'] as String? ?? '',
        titleEn: j['titleEn'] as String? ?? '',
        titleZh: j['titleZh'] as String? ?? '',
        summaryAr: j['summaryAr'] as String? ?? '',
        summaryEn: j['summaryEn'] as String? ?? '',
        summaryZh: j['summaryZh'] as String? ?? '',
        bodyAr: j['bodyAr'] as String? ?? '',
        bodyEn: j['bodyEn'] as String? ?? '',
        bodyZh: j['bodyZh'] as String? ?? '',
        imageUrl: j['imageUrl'] as String?,
        categoryId: j['categoryId'] as String?,
        ctaLabelAr: j['ctaLabelAr'] as String?,
        ctaLabelEn: j['ctaLabelEn'] as String?,
      );

  String title(String lang) => _pick(lang, titleAr, titleEn, titleZh);
  String summary(String lang) => _pick(lang, summaryAr, summaryEn, summaryZh);
  String body(String lang) => _pick(lang, bodyAr, bodyEn, bodyZh);

  static String _pick(String lang, String ar, String en, String zh) {
    if (lang.startsWith('ar')) return ar;
    if (lang.startsWith('zh')) return zh;
    return en;
  }
}

class HubPlaceDto {
  const HubPlaceDto({
    required this.id,
    required this.hub,
    required this.nameAr,
    required this.nameEn,
    required this.nameZh,
    required this.lat,
    required this.lng,
    this.city,
    this.rating,
    this.hoursAr,
    this.hoursEn,
    this.imageUrl,
    this.categoryId,
  });

  final String id;
  final String hub;
  final String nameAr;
  final String nameEn;
  final String nameZh;
  final double lat;
  final double lng;
  final String? city;
  final double? rating;
  final String? hoursAr;
  final String? hoursEn;
  final String? imageUrl;
  final String? categoryId;

  factory HubPlaceDto.fromJson(Map<String, dynamic> j) => HubPlaceDto(
        id: j['id'] as String? ?? '',
        hub: j['hub'] as String? ?? '',
        nameAr: j['nameAr'] as String? ?? '',
        nameEn: j['nameEn'] as String? ?? '',
        nameZh: j['nameZh'] as String? ?? '',
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        city: j['city'] as String?,
        rating: (j['rating'] as num?)?.toDouble(),
        hoursAr: j['hoursAr'] as String?,
        hoursEn: j['hoursEn'] as String?,
        imageUrl: j['imageUrl'] as String?,
        categoryId: j['categoryId'] as String?,
      );

  String name(String lang) {
    if (lang.startsWith('ar')) return nameAr;
    if (lang.startsWith('zh')) return nameZh;
    return nameEn;
  }

  String? resolvedImage() {
    final u = imageUrl?.trim();
    if (u == null || u.isEmpty) return null;
    if (u.startsWith('assets/')) return u;
    return resolveMediaUrl(u);
  }
}

class HubDealDto {
  const HubDealDto({
    required this.id,
    required this.hub,
    required this.titleAr,
    required this.titleEn,
    this.photo,
    this.target,
  });

  final String id;
  final String hub;
  final String titleAr;
  final String titleEn;
  final String? photo;
  final String? target;

  factory HubDealDto.fromJson(Map<String, dynamic> j) => HubDealDto(
        id: j['id'] as String? ?? '',
        hub: j['hub'] as String? ?? '',
        titleAr: j['titleAr'] as String? ?? j['ar'] as String? ?? '',
        titleEn: j['titleEn'] as String? ?? j['en'] as String? ?? '',
        photo: j['photo'] as String? ?? j['imageUrl'] as String?,
        target: j['target'] as String? ?? j['scope'] as String?,
      );

  String title(String lang) => lang.startsWith('ar') ? titleAr : titleEn;
}

class HubContentBundle {
  const HubContentBundle({
    this.guides = const [],
    this.places = const [],
    this.deals = const [],
  });

  final List<HubGuideDto> guides;
  final List<HubPlaceDto> places;
  final List<HubDealDto> deals;
}

class HubContentApi {
  HubContentApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _base = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _base;

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$_base/v1$path').replace(queryParameters: q);

  Future<HubContentBundle> fetch({
    required String hub,
    String? city,
  }) async {
    try {
      final q = <String, String>{'hub': hub};
      if (city != null && city.trim().isNotEmpty) q['city'] = city.trim();
      final res = await _client
          .get(_u('/hub-content', q), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return const HubContentBundle();
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return const HubContentBundle();
      final m = Map<String, dynamic>.from(decoded);
      return HubContentBundle(
        guides: _list(m['guides']).map(HubGuideDto.fromJson).toList(),
        places: _list(m['places']).map(HubPlaceDto.fromJson).toList(),
        deals: _list(m['deals']).map(HubDealDto.fromJson).toList(),
      );
    } catch (_) {
      return const HubContentBundle();
    }
  }

  Future<List<HubDealDto>> fetchDeals(String hub) async {
    final b = await fetch(hub: hub);
    if (b.deals.isNotEmpty) return b.deals;
    // Fallback: marketplace promos already live on api.obicgp.com.
    try {
      final res = await _client
          .get(
            _u('/marketplace/promos', {'scope': hub}),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      final decoded = jsonDecode(res.body);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => HubDealDto.fromJson(Map<String, dynamic>.from(e)))
          .where((d) => d.titleAr.isNotEmpty || d.titleEn.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
