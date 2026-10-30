// Made by Dr Ali
// API-ready marketplace models (Booking / Meituan shape). Mock now → JSON later.

enum MarketplaceVertical {
  hotel,
  flight,
  train,
  attraction,
  tour,
  transfer,
  carRental,
  food,
  pharmacy,
  market,
  errand,
  clinic,
  beauty,
  shop,
}

class HotelListing {
  const HotelListing({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.photo,
    required this.city,
    required this.rating,
    required this.reviewCount,
    required this.pricePerNightYuan,
    required this.stars,
    required this.tags,
    this.distanceKm,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String photo;
  final String city;
  final double rating;
  final int reviewCount;
  final int pricePerNightYuan;
  final int stars;
  final List<String> tags;
  final double? distanceKm;

  String name(String lang) =>
      lang.startsWith('ar') ? nameAr : nameEn;

  factory HotelListing.fromJson(Map<String, dynamic> j) => HotelListing(
        id: j['id'] as String,
        nameAr: j['nameAr'] as String? ?? j['name'] as String? ?? '',
        nameEn: j['nameEn'] as String? ?? j['name'] as String? ?? '',
        photo: j['photo'] as String? ?? '',
        city: j['city'] as String? ?? '',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
        pricePerNightYuan: (j['pricePerNightYuan'] as num?)?.toInt() ?? 0,
        stars: (j['stars'] as num?)?.toInt() ?? 3,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
      );
}

class FlightOffer {
  const FlightOffer({
    required this.id,
    required this.airline,
    required this.fromCode,
    required this.toCode,
    required this.departTime,
    required this.arriveTime,
    required this.durationMin,
    required this.priceYuan,
    required this.stops,
  });

  final String id;
  final String airline;
  final String fromCode;
  final String toCode;
  final String departTime;
  final String arriveTime;
  final int durationMin;
  final int priceYuan;
  final int stops;

  factory FlightOffer.fromJson(Map<String, dynamic> j) => FlightOffer(
        id: j['id'] as String,
        airline: j['airline'] as String? ?? '',
        fromCode: j['fromCode'] as String? ?? '',
        toCode: j['toCode'] as String? ?? '',
        departTime: j['departTime'] as String? ?? '',
        arriveTime: j['arriveTime'] as String? ?? '',
        durationMin: (j['durationMin'] as num?)?.toInt() ?? 0,
        priceYuan: (j['priceYuan'] as num?)?.toInt() ?? 0,
        stops: (j['stops'] as num?)?.toInt() ?? 0,
      );
}

class TrainTrip {
  const TrainTrip({
    required this.id,
    required this.trainNo,
    required this.fromStation,
    required this.toStation,
    required this.departTime,
    required this.arriveTime,
    required this.durationMin,
    required this.priceYuan,
    required this.seatClass,
  });

  final String id;
  final String trainNo;
  final String fromStation;
  final String toStation;
  final String departTime;
  final String arriveTime;
  final int durationMin;
  final int priceYuan;
  final String seatClass;

  factory TrainTrip.fromJson(Map<String, dynamic> j) => TrainTrip(
        id: j['id'] as String,
        trainNo: j['trainNo'] as String? ?? '',
        fromStation: j['fromStation'] as String? ?? '',
        toStation: j['toStation'] as String? ?? '',
        departTime: j['departTime'] as String? ?? '',
        arriveTime: j['arriveTime'] as String? ?? '',
        durationMin: (j['durationMin'] as num?)?.toInt() ?? 0,
        priceYuan: (j['priceYuan'] as num?)?.toInt() ?? 0,
        seatClass: j['seatClass'] as String? ?? '',
      );
}

class AttractionTicket {
  const AttractionTicket({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.photo,
    required this.city,
    required this.rating,
    required this.priceYuan,
    required this.openHours,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String photo;
  final String city;
  final double rating;
  final int priceYuan;
  final String openHours;

  String name(String lang) =>
      lang.startsWith('ar') ? nameAr : nameEn;

  factory AttractionTicket.fromJson(Map<String, dynamic> j) =>
      AttractionTicket(
        id: j['id'] as String,
        nameAr: j['nameAr'] as String? ?? '',
        nameEn: j['nameEn'] as String? ?? '',
        photo: j['photo'] as String? ?? '',
        city: j['city'] as String? ?? '',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        priceYuan: (j['priceYuan'] as num?)?.toInt() ?? 0,
        openHours: j['openHours'] as String? ?? '',
      );
}

class TourPackage {
  const TourPackage({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.photo,
    required this.days,
    required this.priceYuan,
    required this.highlights,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String photo;
  final int days;
  final int priceYuan;
  final List<String> highlights;

  String name(String lang) =>
      lang.startsWith('ar') ? nameAr : nameEn;

  factory TourPackage.fromJson(Map<String, dynamic> j) => TourPackage(
        id: j['id'] as String,
        nameAr: j['nameAr'] as String? ?? '',
        nameEn: j['nameEn'] as String? ?? '',
        photo: j['photo'] as String? ?? '',
        days: (j['days'] as num?)?.toInt() ?? 1,
        priceYuan: (j['priceYuan'] as num?)?.toInt() ?? 0,
        highlights: (j['highlights'] as List?)?.cast<String>() ?? const [],
      );
}

class MerchantListing {
  const MerchantListing({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.photo,
    required this.rating,
    required this.distanceKm,
    required this.etaMin,
    required this.feeYuan,
    required this.tags,
    required this.category,
    this.minOrderYuan,
    this.openNow = true,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String photo;
  final double rating;
  final double distanceKm;
  final int etaMin;
  final int feeYuan;
  final List<String> tags;
  final MarketplaceVertical category;
  final int? minOrderYuan;
  final bool openNow;

  String name(String lang) =>
      lang.startsWith('ar') ? nameAr : nameEn;

  factory MerchantListing.fromJson(Map<String, dynamic> j) => MerchantListing(
        id: j['id'] as String,
        nameAr: j['nameAr'] as String? ?? '',
        nameEn: j['nameEn'] as String? ?? '',
        photo: j['photo'] as String? ?? '',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
        etaMin: (j['etaMin'] as num?)?.toInt() ?? 0,
        feeYuan: (j['feeYuan'] as num?)?.toInt() ?? 0,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        category: MarketplaceVertical.values.firstWhere(
          (v) => v.name == (j['category'] as String? ?? 'food'),
          orElse: () => MarketplaceVertical.food,
        ),
        minOrderYuan: (j['minOrderYuan'] as num?)?.toInt(),
        openNow: j['openNow'] as bool? ?? true,
      );
}

class TransferOption {
  const TransferOption({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.vehicle,
    required this.priceYuan,
    required this.etaMin,
    required this.seats,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String vehicle;
  final int priceYuan;
  final int etaMin;
  final int seats;

  String title(String lang) =>
      lang.startsWith('ar') ? titleAr : titleEn;
}

class CarRentalOffer {
  const CarRentalOffer({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.photo,
    required this.pricePerDayYuan,
    required this.seats,
    required this.transmission,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String photo;
  final int pricePerDayYuan;
  final int seats;
  final String transmission;

  String name(String lang) =>
      lang.startsWith('ar') ? nameAr : nameEn;
}
