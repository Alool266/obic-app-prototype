// Made by Dr Ali
// Marketplace HTTP client — always OUR API (kApiBaseUrl), never trial Render.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/media_url.dart';
import '../daily_life/daily_media.dart';
import '../travel_hub/travel_media.dart';
import 'marketplace_models.dart';
import 'marketplace_repository.dart';

class ApiMarketplaceRepository implements MarketplaceRepository {
  ApiMarketplaceRepository({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _base = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _base;
  final _local = const MockMarketplaceRepository();

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$_base/v1$path').replace(queryParameters: q);

  String _photo(String? raw, String fallback) {
    final p = (raw ?? '').trim();
    if (p.isEmpty) return fallback;
    if (p.startsWith('assets/')) return p;
    // Map seeded API upload paths → bundled assets until real CDN files exist.
    if (p.contains('hotel')) return TravelMedia.hotel;
    if (p.contains('flight')) return TravelMedia.flight;
    if (p.contains('train')) return TravelMedia.train;
    if (p.contains('landmark')) return TravelMedia.landmark;
    if (p.contains('food')) return DailyMedia.food;
    if (p.contains('cafe')) return DailyMedia.cafe;
    if (p.contains('pharmacy')) return DailyMedia.pharmacy;
    if (p.contains('market')) return DailyMedia.market;
    return resolveMediaUrl(p).isEmpty ? fallback : resolveMediaUrl(p);
  }

  Future<List<dynamic>?> _getList(String path, [Map<String, String>? q]) async {
    try {
      final res = await _client
          .get(_u(path, q), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<HotelListing>> searchHotels({String? city}) async {
    final rows = await _getList(
      '/marketplace/hotels',
      city == null || city.isEmpty ? null : {'city': city},
    );
    if (rows == null || rows.isEmpty) {
      return _local.searchHotels(city: city);
    }
    return rows.whereType<Map<String, dynamic>>().map((j) {
      final h = HotelListing.fromJson(j);
      return HotelListing(
        id: h.id,
        nameAr: h.nameAr,
        nameEn: h.nameEn,
        photo: _photo(h.photo, TravelMedia.hotel),
        city: h.city,
        rating: h.rating,
        reviewCount: h.reviewCount,
        pricePerNightYuan: h.pricePerNightYuan,
        stars: h.stars,
        tags: h.tags,
        distanceKm: h.distanceKm,
      );
    }).toList();
  }

  @override
  Future<List<FlightOffer>> searchFlights({String? from, String? to}) async {
    final q = <String, String>{};
    if (from != null && from.trim().isNotEmpty) q['from'] = from.trim();
    if (to != null && to.trim().isNotEmpty) q['to'] = to.trim();
    final rows = await _getList(
      '/marketplace/flights',
      q.isEmpty ? null : q,
    );
    if (rows == null || rows.isEmpty) {
      return _local.searchFlights(from: from, to: to);
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .map(FlightOffer.fromJson)
        .toList();
  }

  @override
  Future<List<TrainTrip>> searchTrains({String? from, String? to}) async {
    final rows = await _getList('/marketplace/trains');
    if (rows == null || rows.isEmpty) {
      return _local.searchTrains(from: from, to: to);
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .map(TrainTrip.fromJson)
        .toList();
  }

  @override
  Future<List<AttractionTicket>> listAttractions({String? city}) async {
    final rows = await _getList(
      '/marketplace/attractions',
      city == null || city.isEmpty ? null : {'city': city},
    );
    if (rows == null || rows.isEmpty) {
      return _local.listAttractions(city: city);
    }
    return rows.whereType<Map<String, dynamic>>().map((j) {
      final a = AttractionTicket.fromJson(j);
      return AttractionTicket(
        id: a.id,
        nameAr: a.nameAr,
        nameEn: a.nameEn,
        photo: _photo(a.photo, TravelMedia.landmark),
        city: a.city,
        rating: a.rating,
        priceYuan: a.priceYuan,
        openHours: a.openHours,
      );
    }).toList();
  }

  @override
  Future<List<TourPackage>> listTours() async {
    final rows = await _getList('/marketplace/tours');
    if (rows == null || rows.isEmpty) return _local.listTours();
    return rows.whereType<Map<String, dynamic>>().map((j) {
      final t = TourPackage.fromJson(j);
      return TourPackage(
        id: t.id,
        nameAr: t.nameAr,
        nameEn: t.nameEn,
        photo: _photo(t.photo, TravelMedia.hotel),
        days: t.days,
        priceYuan: t.priceYuan,
        highlights: t.highlights,
      );
    }).toList();
  }

  @override
  Future<List<TransferOption>> listTransfers() async {
    final rows = await _getList('/marketplace/transfers');
    if (rows == null || rows.isEmpty) return _local.listTransfers();
    return [
      for (final j in rows.whereType<Map<String, dynamic>>())
        TransferOption(
          id: j['id'] as String? ?? '',
          titleAr: j['titleAr'] as String? ?? '',
          titleEn: j['titleEn'] as String? ?? '',
          vehicle: j['vehicle'] as String? ?? '',
          priceYuan: (j['priceYuan'] as num?)?.toInt() ?? 0,
          etaMin: (j['etaMin'] as num?)?.toInt() ?? 0,
          seats: (j['seats'] as num?)?.toInt() ?? 0,
        ),
    ];
  }

  @override
  Future<List<CarRentalOffer>> listCarRentals() async {
    final rows = await _getList('/marketplace/cars');
    if (rows == null || rows.isEmpty) return _local.listCarRentals();
    return [
      for (final j in rows.whereType<Map<String, dynamic>>())
        CarRentalOffer(
          id: j['id'] as String? ?? '',
          nameAr: j['nameAr'] as String? ?? '',
          nameEn: j['nameEn'] as String? ?? '',
          photo: _photo(j['photo'] as String?, TravelMedia.train),
          pricePerDayYuan: (j['pricePerDayYuan'] as num?)?.toInt() ?? 0,
          seats: (j['seats'] as num?)?.toInt() ?? 0,
          transmission: j['transmission'] as String? ?? '',
        ),
    ];
  }

  @override
  Future<List<MerchantListing>> listMerchants(
    MarketplaceVertical category,
  ) async {
    final rows = await _getList('/marketplace/merchants', {
      'category': category.name,
      // Live OSM food overlay defaults to Yiwu; travel hubs pass city on hotels.
      'city': 'Yiwu',
    });
    if (rows == null || rows.isEmpty) {
      return _local.listMerchants(category);
    }
    return rows.whereType<Map<String, dynamic>>().map((j) {
      final m = MerchantListing.fromJson(j);
      return MerchantListing(
        id: m.id,
        nameAr: m.nameAr,
        nameEn: m.nameEn,
        photo: _photo(m.photo, DailyMedia.food),
        rating: m.rating,
        distanceKm: m.distanceKm,
        etaMin: m.etaMin,
        feeYuan: m.feeYuan,
        tags: m.tags,
        category: m.category,
        minOrderYuan: m.minOrderYuan,
        openNow: m.openNow,
      );
    }).toList();
  }
}

/// Global repo — hits api.obicgp.com (or dart-define), falls back to mock.
MarketplaceRepository marketplaceRepo = ApiMarketplaceRepository();
