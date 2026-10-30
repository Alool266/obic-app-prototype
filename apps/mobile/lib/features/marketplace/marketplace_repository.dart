// Made by Dr Ali
// Marketplace data port — swap Mock → live Booking/Meituan APIs later.

import '../daily_life/daily_media.dart';
import '../travel_hub/travel_media.dart';
import 'marketplace_models.dart';

abstract class MarketplaceRepository {
  Future<List<HotelListing>> searchHotels({String? city});
  Future<List<FlightOffer>> searchFlights({
    String? from,
    String? to,
  });
  Future<List<TrainTrip>> searchTrains({String? from, String? to});
  Future<List<AttractionTicket>> listAttractions({String? city});
  Future<List<TourPackage>> listTours();
  Future<List<TransferOption>> listTransfers();
  Future<List<CarRentalOffer>> listCarRentals();
  Future<List<MerchantListing>> listMerchants(MarketplaceVertical category);
}

/// In-app mock. Replace with HTTP client implementing the same interface.
class MockMarketplaceRepository implements MarketplaceRepository {
  const MockMarketplaceRepository();

  @override
  Future<List<HotelListing>> searchHotels({String? city}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final all = const [
      HotelListing(
        id: 'h1',
        nameAr: 'فندق أوبك ييوو',
        nameEn: 'OBIC Yiwu Hotel',
        photo: TravelMedia.hotel,
        city: 'Yiwu',
        rating: 4.7,
        reviewCount: 1284,
        pricePerNightYuan: 388,
        stars: 4,
        tags: ['إفطار', 'واي فاي'],
        distanceKm: 1.2,
      ),
      HotelListing(
        id: 'h2',
        nameAr: 'شانغهاي بيزنس إن',
        nameEn: 'Shanghai Business Inn',
        photo: TravelMedia.hotel,
        city: 'Shanghai',
        rating: 4.5,
        reviewCount: 892,
        pricePerNightYuan: 520,
        stars: 4,
        tags: ['مطار', 'مسبح'],
        distanceKm: 3.4,
      ),
      HotelListing(
        id: 'h3',
        nameAr: 'جناح الخليج الذهبي',
        nameEn: 'Golden Bay Suite',
        photo: TravelMedia.landmark,
        city: 'Hangzhou',
        rating: 4.9,
        reviewCount: 456,
        pricePerNightYuan: 680,
        stars: 5,
        tags: ['إطلالة', 'سبا'],
        distanceKm: 0.8,
      ),
    ];
    if (city == null || city.isEmpty) return all;
    final q = city.toLowerCase();
    return all
        .where((h) =>
            h.city.toLowerCase().contains(q) ||
            h.nameEn.toLowerCase().contains(q) ||
            h.nameAr.contains(city))
        .toList();
  }

  @override
  Future<List<FlightOffer>> searchFlights({String? from, String? to}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return const [
      FlightOffer(
        id: 'f1',
        airline: 'China Eastern',
        fromCode: 'HGH',
        toCode: 'CAN',
        departTime: '08:40',
        arriveTime: '11:05',
        durationMin: 145,
        priceYuan: 680,
        stops: 0,
      ),
      FlightOffer(
        id: 'f2',
        airline: 'Air China',
        fromCode: 'PVG',
        toCode: 'PEK',
        departTime: '14:20',
        arriveTime: '16:55',
        durationMin: 155,
        priceYuan: 920,
        stops: 0,
      ),
      FlightOffer(
        id: 'f3',
        airline: 'China Southern',
        fromCode: 'CAN',
        toCode: 'DXB',
        departTime: '22:10',
        arriveTime: '02:45+1',
        durationMin: 515,
        priceYuan: 2450,
        stops: 1,
      ),
    ];
  }

  @override
  Future<List<TrainTrip>> searchTrains({String? from, String? to}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const [
      TrainTrip(
        id: 't1',
        trainNo: 'G1501',
        fromStation: 'Yiwu',
        toStation: 'Hangzhou East',
        departTime: '09:12',
        arriveTime: '09:48',
        durationMin: 36,
        priceYuan: 73,
        seatClass: '2nd',
      ),
      TrainTrip(
        id: 't2',
        trainNo: 'G7328',
        fromStation: 'Hangzhou East',
        toStation: 'Shanghai Hongqiao',
        departTime: '11:05',
        arriveTime: '12:02',
        durationMin: 57,
        priceYuan: 112,
        seatClass: '2nd',
      ),
      TrainTrip(
        id: 't3',
        trainNo: 'D3125',
        fromStation: 'Yiwu',
        toStation: 'Ningbo',
        departTime: '15:40',
        arriveTime: '17:18',
        durationMin: 98,
        priceYuan: 98,
        seatClass: '1st',
      ),
    ];
  }

  @override
  Future<List<AttractionTicket>> listAttractions({String? city}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const [
      AttractionTicket(
        id: 'a1',
        nameAr: 'الحديقة الغربية',
        nameEn: 'West Lake',
        photo: TravelMedia.landmark,
        city: 'Hangzhou',
        rating: 4.8,
        priceYuan: 0,
        openHours: '06:00–21:00',
      ),
      AttractionTicket(
        id: 'a2',
        nameAr: 'برج شنغهاي',
        nameEn: 'Shanghai Tower',
        photo: TravelMedia.landmark,
        city: 'Shanghai',
        rating: 4.7,
        priceYuan: 180,
        openHours: '08:30–21:30',
      ),
      AttractionTicket(
        id: 'a3',
        nameAr: 'سوق ييوو الدولي',
        nameEn: 'Yiwu International Trade City',
        photo: TravelMedia.hotel,
        city: 'Yiwu',
        rating: 4.6,
        priceYuan: 0,
        openHours: '09:00–17:00',
      ),
    ];
  }

  @override
  Future<List<TourPackage>> listTours() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const [
      TourPackage(
        id: 'tou1',
        nameAr: 'ييوو · 3 أيام أعمال',
        nameEn: 'Yiwu 3-day business',
        photo: TravelMedia.hotel,
        days: 3,
        priceYuan: 2100,
        highlights: ['سوق', 'فندق', 'مرشد'],
      ),
      TourPackage(
        id: 'tou2',
        nameAr: 'شنغهاي · نهاية أسبوع',
        nameEn: 'Shanghai weekend',
        photo: TravelMedia.landmark,
        days: 2,
        priceYuan: 1680,
        highlights: ['معالم', 'نقل', 'عشاء'],
      ),
    ];
  }

  @override
  Future<List<TransferOption>> listTransfers() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return const [
      TransferOption(
        id: 'tr1',
        titleAr: 'مطار ← فندق (سيدان)',
        titleEn: 'Airport → hotel (sedan)',
        vehicle: 'Sedan',
        priceYuan: 180,
        etaMin: 45,
        seats: 3,
      ),
      TransferOption(
        id: 'tr2',
        titleAr: 'مطار ← فندق (فان)',
        titleEn: 'Airport → hotel (van)',
        vehicle: 'Van',
        priceYuan: 280,
        etaMin: 45,
        seats: 6,
      ),
      TransferOption(
        id: 'tr3',
        titleAr: 'VIP مع سائق',
        titleEn: 'VIP with driver',
        vehicle: 'Business',
        priceYuan: 420,
        etaMin: 40,
        seats: 3,
      ),
    ];
  }

  @override
  Future<List<CarRentalOffer>> listCarRentals() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return const [
      CarRentalOffer(
        id: 'c1',
        nameAr: 'سيدان اقتصادية',
        nameEn: 'Economy sedan',
        photo: TravelMedia.train,
        pricePerDayYuan: 220,
        seats: 5,
        transmission: 'Auto',
      ),
      CarRentalOffer(
        id: 'c2',
        nameAr: 'SUV عائلية',
        nameEn: 'Family SUV',
        photo: TravelMedia.flight,
        pricePerDayYuan: 380,
        seats: 7,
        transmission: 'Auto',
      ),
    ];
  }

  @override
  Future<List<MerchantListing>> listMerchants(
    MarketplaceVertical category,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final all = const [
      MerchantListing(
        id: 'm1',
        nameAr: 'مندي ييوو',
        nameEn: 'Yiwu Mandi House',
        photo: DailyMedia.food,
        rating: 4.8,
        distanceKm: 0.6,
        etaMin: 28,
        feeYuan: 6,
        tags: ['عربي', 'حلال'],
        category: MarketplaceVertical.food,
        minOrderYuan: 35,
      ),
      MerchantListing(
        id: 'm2',
        nameAr: 'كافيه أوبك',
        nameEn: 'OBIC Café',
        photo: DailyMedia.cafe,
        rating: 4.6,
        distanceKm: 0.9,
        etaMin: 22,
        feeYuan: 4,
        tags: ['قهوة', 'حلويات', 'مشروبات', 'cafe'],
        category: MarketplaceVertical.food,
        minOrderYuan: 20,
      ),
      MerchantListing(
        id: 'm3',
        nameAr: 'نودلز التنين',
        nameEn: 'Dragon Noodles',
        photo: DailyMedia.food,
        rating: 4.5,
        distanceKm: 1.1,
        etaMin: 30,
        feeYuan: 5,
        tags: ['صيني', 'سريع'],
        category: MarketplaceVertical.food,
      ),
      MerchantListing(
        id: 'm4',
        nameAr: 'صيدلية النور',
        nameEn: 'Al-Noor Pharmacy',
        photo: DailyMedia.pharmacy,
        rating: 4.9,
        distanceKm: 1.2,
        etaMin: 35,
        feeYuan: 5,
        tags: ['24س', 'أدوية'],
        category: MarketplaceVertical.pharmacy,
      ),
      MerchantListing(
        id: 'm5',
        nameAr: 'صيدلية الصحة+',
        nameEn: 'Health+ Pharmacy',
        photo: DailyMedia.pharmacy,
        rating: 4.7,
        distanceKm: 2.0,
        etaMin: 40,
        feeYuan: 6,
        tags: ['وصفات', 'فيتامينات'],
        category: MarketplaceVertical.pharmacy,
      ),
      MerchantListing(
        id: 'm6',
        nameAr: 'سوق الخضار الطازج',
        nameEn: 'Fresh Produce Market',
        photo: DailyMedia.market,
        rating: 4.5,
        distanceKm: 1.5,
        etaMin: 40,
        feeYuan: 8,
        tags: ['خضار', 'فواكه'],
        category: MarketplaceVertical.market,
      ),
      MerchantListing(
        id: 'm7',
        nameAr: 'سوبرماركت المدينة',
        nameEn: 'City Mart',
        photo: DailyMedia.market,
        rating: 4.4,
        distanceKm: 0.8,
        etaMin: 32,
        feeYuan: 5,
        tags: ['بقالة', 'توصيل'],
        category: MarketplaceVertical.market,
      ),
      MerchantListing(
        id: 'm8',
        nameAr: 'عيادة الأمل',
        nameEn: 'Amal Clinic',
        photo: DailyMedia.pharmacy,
        rating: 4.8,
        distanceKm: 1.8,
        etaMin: 15,
        feeYuan: 0,
        tags: ['عام', 'عربي'],
        category: MarketplaceVertical.clinic,
      ),
      MerchantListing(
        id: 'm9',
        nameAr: 'صالون لؤلؤة',
        nameEn: 'Pearl Beauty',
        photo: DailyMedia.cafe,
        rating: 4.6,
        distanceKm: 1.0,
        etaMin: 20,
        feeYuan: 0,
        tags: ['شعر', 'عناية'],
        category: MarketplaceVertical.beauty,
      ),
      MerchantListing(
        id: 'm10',
        nameAr: 'إلكترونيات الساحة',
        nameEn: 'Plaza Electronics',
        photo: DailyMedia.market,
        rating: 4.3,
        distanceKm: 2.2,
        etaMin: 45,
        feeYuan: 10,
        tags: ['هواتف', 'إكسسوار'],
        category: MarketplaceVertical.shop,
      ),
      MerchantListing(
        id: 'm11',
        nameAr: 'مشاوير أوبك',
        nameEn: 'OBIC Errands',
        photo: DailyMedia.food,
        rating: 4.7,
        distanceKm: 0.5,
        etaMin: 25,
        feeYuan: 12,
        tags: ['توصيل', 'شراء'],
        category: MarketplaceVertical.errand,
      ),
    ];
    return all.where((m) => m.category == category).toList();
  }
}

// Prefer ApiMarketplaceRepository (marketplace_api.dart) at call sites.
