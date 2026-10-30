// Made by Dr Ali
// Marketplace catalog — seed + free OSM live overlay (Nominatim/Overpass).

import { Injectable, Logger } from '@nestjs/common';
import {
  liveAttractions,
  liveFoodMerchants,
  liveHotels,
} from './marketplace-live';

@Injectable()
export class MarketplaceService {
  private readonly logger = new Logger(MarketplaceService.name);

  /** Never block browse on slow/blocked OSM mirrors (common on CN ECS). */
  private async liveOrEmpty<T>(
    label: string,
    work: Promise<T[]>,
    budgetMs = 3_200,
  ): Promise<T[]> {
    try {
      return await Promise.race([
        work,
        new Promise<T[]>((resolve) =>
          setTimeout(() => resolve([]), budgetMs),
        ),
      ]);
    } catch (e) {
      this.logger.warn(`${label}_fail ${String(e)}`);
      return [];
    }
  }

  private seedHotels(city?: string) {
    const all = [
      {
        id: 'h1',
        nameAr: 'فندق أوبك ييوو',
        nameEn: 'OBIC Yiwu Hotel',
        photo: '/uploads/marketplace/hotel.jpg',
        city: 'Yiwu',
        rating: 4.7,
        reviewCount: 1284,
        pricePerNightYuan: 388,
        stars: 4,
        tags: ['إفطار', 'واي فاي'],
        distanceKm: 1.2,
      },
      {
        id: 'h2',
        nameAr: 'شانغهاي بيزنس إن',
        nameEn: 'Shanghai Business Inn',
        photo: '/uploads/marketplace/hotel.jpg',
        city: 'Shanghai',
        rating: 4.5,
        reviewCount: 892,
        pricePerNightYuan: 520,
        stars: 4,
        tags: ['مطار', 'مسبح'],
        distanceKm: 3.4,
      },
      {
        id: 'h3',
        nameAr: 'جناح الخليج الذهبي',
        nameEn: 'Golden Bay Suite',
        photo: '/uploads/marketplace/landmark.jpg',
        city: 'Hangzhou',
        rating: 4.9,
        reviewCount: 456,
        pricePerNightYuan: 680,
        stars: 5,
        tags: ['إطلالة', 'سبا'],
        distanceKm: 0.8,
      },
    ];
    if (!city?.trim()) return all;
    const q = city.trim().toLowerCase();
    return all.filter(
      (h) =>
        h.city.toLowerCase().includes(q) ||
        h.nameEn.toLowerCase().includes(q) ||
        h.nameAr.includes(city.trim()),
    );
  }

  async hotels(city?: string) {
    const seed = this.seedHotels(city);
    const live = await this.liveOrEmpty(
      'live_hotels',
      liveHotels(city || 'Yiwu'),
    );
    if (live.length === 0) return seed;
    // Live OSM first (real places), then seed fillers — one row per name.
    return this.dedupeByName([...live, ...seed]).slice(0, 24);
  }

  /** Collapse live+seed duplicates that share the same display name. */
  private dedupeByName<
    T extends { id?: string; nameEn?: string; nameAr?: string; name?: string },
  >(rows: T[]): T[] {
    const seen = new Set<string>();
    const out: T[] = [];
    for (const row of rows) {
      const raw =
        row.nameEn?.trim() ||
        row.nameAr?.trim() ||
        row.name?.trim() ||
        row.id?.trim() ||
        '';
      const key = raw.toLowerCase();
      if (!key || seen.has(key)) continue;
      seen.add(key);
      out.push(row);
    }
    return out;
  }

  flights(from?: string, to?: string) {
    const all = [
      {
        id: 'f1',
        airline: 'China Eastern',
        fromCode: 'HGH',
        toCode: 'CAN',
        departTime: '08:40',
        arriveTime: '11:05',
        durationMin: 145,
        priceYuan: 680,
        stops: 0,
      },
      {
        id: 'f2',
        airline: 'Air China',
        fromCode: 'PVG',
        toCode: 'PEK',
        departTime: '14:20',
        arriveTime: '16:55',
        durationMin: 155,
        priceYuan: 920,
        stops: 0,
      },
      {
        id: 'f3',
        airline: 'China Southern',
        fromCode: 'CAN',
        toCode: 'DXB',
        departTime: '22:10',
        arriveTime: '02:45+1',
        durationMin: 515,
        priceYuan: 2450,
        stops: 1,
      },
      {
        id: 'f4',
        airline: 'China Eastern',
        fromCode: 'HGH',
        toCode: 'PEK',
        departTime: '07:15',
        arriveTime: '09:35',
        durationMin: 140,
        priceYuan: 890,
        stops: 0,
      },
      {
        id: 'f5',
        airline: 'Spring Airlines',
        fromCode: 'PVG',
        toCode: 'CAN',
        departTime: '16:50',
        arriveTime: '19:25',
        durationMin: 155,
        priceYuan: 560,
        stops: 0,
      },
      {
        id: 'f6',
        airline: 'Air China',
        fromCode: 'PEK',
        toCode: 'DXB',
        departTime: '00:35',
        arriveTime: '05:55',
        durationMin: 500,
        priceYuan: 2680,
        stops: 0,
      },
      {
        id: 'f7',
        airline: 'Emirates',
        fromCode: 'DXB',
        toCode: 'PVG',
        departTime: '03:15',
        arriveTime: '16:40',
        durationMin: 565,
        priceYuan: 3120,
        stops: 0,
      },
      {
        id: 'f8',
        airline: 'China Southern',
        fromCode: 'CAN',
        toCode: 'JED',
        departTime: '01:20',
        arriveTime: '07:05',
        durationMin: 585,
        priceYuan: 2890,
        stops: 1,
      },
      {
        id: 'f9',
        airline: 'XiamenAir',
        fromCode: 'HGH',
        toCode: 'SZX',
        departTime: '12:05',
        arriveTime: '14:20',
        durationMin: 135,
        priceYuan: 720,
        stops: 0,
      },
      {
        id: 'f10',
        airline: 'China Eastern',
        fromCode: 'PVG',
        toCode: 'KUL',
        departTime: '09:00',
        arriveTime: '14:35',
        durationMin: 335,
        priceYuan: 1580,
        stops: 0,
      },
    ];
    const f = from?.trim().toUpperCase();
    const t = to?.trim().toUpperCase();
    return all.filter((row) => {
      if (f && row.fromCode !== f && !row.fromCode.startsWith(f.slice(0, 2))) {
        return false;
      }
      if (t && row.toCode !== t && !row.toCode.startsWith(t.slice(0, 2))) {
        return false;
      }
      return true;
    });
  }

  trains() {
    return [
      {
        id: 't1',
        trainNo: 'G1501',
        fromStation: 'Yiwu',
        toStation: 'Hangzhou East',
        departTime: '09:12',
        arriveTime: '09:48',
        durationMin: 36,
        priceYuan: 73,
        seatClass: '2nd',
      },
      {
        id: 't2',
        trainNo: 'G7328',
        fromStation: 'Hangzhou East',
        toStation: 'Shanghai Hongqiao',
        departTime: '11:05',
        arriveTime: '12:02',
        durationMin: 57,
        priceYuan: 112,
        seatClass: '2nd',
      },
      {
        id: 't3',
        trainNo: 'G7502',
        fromStation: 'Yiwu',
        toStation: 'Shanghai Hongqiao',
        departTime: '13:40',
        arriveTime: '15:28',
        durationMin: 108,
        priceYuan: 148,
        seatClass: '2nd',
      },
      {
        id: 't4',
        trainNo: 'G31',
        fromStation: 'Hangzhou East',
        toStation: 'Beijing South',
        departTime: '07:36',
        arriveTime: '12:28',
        durationMin: 292,
        priceYuan: 662,
        seatClass: '2nd',
      },
      {
        id: 't5',
        trainNo: 'G7340',
        fromStation: 'Shanghai Hongqiao',
        toStation: 'Nanjing South',
        departTime: '10:18',
        arriveTime: '11:32',
        durationMin: 74,
        priceYuan: 144,
        seatClass: '2nd',
      },
      {
        id: 't6',
        trainNo: 'D3126',
        fromStation: 'Yiwu',
        toStation: 'Ningbo',
        departTime: '16:05',
        arriveTime: '17:22',
        durationMin: 77,
        priceYuan: 69,
        seatClass: '2nd',
      },
    ];
  }

  private seedAttractions() {
    return [
      {
        id: 'a1',
        nameAr: 'الحديقة الغربية',
        nameEn: 'West Lake',
        photo: '/uploads/marketplace/landmark.jpg',
        city: 'Hangzhou',
        rating: 4.8,
        priceYuan: 0,
        openHours: '06:00–21:00',
      },
      {
        id: 'a2',
        nameAr: 'برج شنغهاي',
        nameEn: 'Shanghai Tower',
        photo: '/uploads/marketplace/landmark.jpg',
        city: 'Shanghai',
        rating: 4.7,
        priceYuan: 180,
        openHours: '08:30–21:30',
      },
    ];
  }

  async attractions(city?: string) {
    const seed = this.seedAttractions();
    const live = await this.liveOrEmpty(
      'live_attractions',
      liveAttractions(city || 'Hangzhou'),
    );
    if (live.length === 0) return seed;
    return [...live, ...seed].slice(0, 20);
  }

  tours() {
    return [
      {
        id: 'tou1',
        nameAr: 'ييوو · 3 أيام أعمال',
        nameEn: 'Yiwu 3-day business',
        photo: '/uploads/marketplace/hotel.jpg',
        days: 3,
        priceYuan: 2100,
        highlights: ['سوق', 'فندق', 'مرشد'],
      },
    ];
  }

  transfers() {
    return [
      {
        id: 'tr1',
        titleAr: 'مطار ← فندق (سيدان)',
        titleEn: 'Airport → hotel (sedan)',
        vehicle: 'Sedan',
        priceYuan: 180,
        etaMin: 45,
        seats: 3,
      },
      {
        id: 'tr2',
        titleAr: 'مطار ← فندق (فان)',
        titleEn: 'Airport → hotel (van)',
        vehicle: 'Van',
        priceYuan: 280,
        etaMin: 45,
        seats: 6,
      },
    ];
  }

  cars() {
    return [
      {
        id: 'c1',
        nameAr: 'سيدان اقتصادية',
        nameEn: 'Economy sedan',
        photo: '/uploads/marketplace/train.jpg',
        pricePerDayYuan: 220,
        seats: 5,
        transmission: 'Auto',
      },
    ];
  }

  private seedMerchants(category?: string) {
    const all = [
      {
        id: 'm1',
        nameAr: 'مندي ييوو',
        nameEn: 'Yiwu Mandi House',
        photo: '/uploads/marketplace/food.jpg',
        rating: 4.8,
        distanceKm: 0.6,
        etaMin: 28,
        feeYuan: 6,
        tags: ['عربي', 'حلال'],
        category: 'food',
        minOrderYuan: 35,
        openNow: true,
      },
      {
        id: 'm2',
        nameAr: 'كافيه أوبك',
        nameEn: 'OBIC Café',
        photo: '/uploads/marketplace/cafe.jpg',
        rating: 4.6,
        distanceKm: 0.9,
        etaMin: 22,
        feeYuan: 4,
        tags: ['قهوة', 'حلويات', 'مشروبات', 'cafe'],
        category: 'food',
        minOrderYuan: 20,
        openNow: true,
      },
      {
        id: 'm4',
        nameAr: 'صيدلية النور',
        nameEn: 'Al-Noor Pharmacy',
        photo: '/uploads/marketplace/pharmacy.jpg',
        rating: 4.9,
        distanceKm: 1.2,
        etaMin: 35,
        feeYuan: 5,
        tags: ['24س', 'أدوية'],
        category: 'pharmacy',
        openNow: true,
      },
      {
        id: 'm6',
        nameAr: 'سوق الخضار الطازج',
        nameEn: 'Fresh Produce Market',
        photo: '/uploads/marketplace/market.jpg',
        rating: 4.5,
        distanceKm: 1.5,
        etaMin: 40,
        feeYuan: 8,
        tags: ['خضار', 'فواكه'],
        category: 'market',
        openNow: true,
      },
      {
        id: 'm8',
        nameAr: 'عيادة الأمل',
        nameEn: 'Amal Clinic',
        photo: '/uploads/marketplace/pharmacy.jpg',
        rating: 4.8,
        distanceKm: 1.8,
        etaMin: 15,
        feeYuan: 0,
        tags: ['عام', 'عربي'],
        category: 'clinic',
        openNow: true,
      },
      {
        id: 'm9',
        nameAr: 'صالون لؤلؤة',
        nameEn: 'Pearl Beauty',
        photo: '/uploads/marketplace/cafe.jpg',
        rating: 4.6,
        distanceKm: 1.0,
        etaMin: 20,
        feeYuan: 0,
        tags: ['شعر', 'عناية'],
        category: 'beauty',
        openNow: true,
      },
      {
        id: 'm10',
        nameAr: 'إلكترونيات الساحة',
        nameEn: 'Plaza Electronics',
        photo: '/uploads/marketplace/market.jpg',
        rating: 4.3,
        distanceKm: 2.2,
        etaMin: 45,
        feeYuan: 10,
        tags: ['هواتف', 'إكسسوار'],
        category: 'shop',
        openNow: true,
      },
      {
        id: 'm11',
        nameAr: 'مشاوير أوبك',
        nameEn: 'OBIC Errands',
        photo: '/uploads/marketplace/food.jpg',
        rating: 4.7,
        distanceKm: 0.5,
        etaMin: 25,
        feeYuan: 12,
        tags: ['توصيل', 'شراء'],
        category: 'errand',
        openNow: true,
      },
    ];
    if (!category?.trim()) return all;
    return all.filter((m) => m.category === category.trim());
  }

  async merchants(category?: string, city?: string) {
    const seed = this.seedMerchants(category);
    const cat = category?.trim() || 'food';
    if (cat !== 'food') return seed;
    const live = await this.liveOrEmpty(
      'live_food',
      liveFoodMerchants(city || 'Yiwu'),
    );
    if (live.length === 0) return seed;
    return [...live, ...seed.filter((m) => m.category === 'food')].slice(0, 24);
  }

  promos(scope?: string) {
    const travel = [
      {
        id: 'tp1',
        ar: 'فنادق ييوو · خصم نهاية الأسبوع',
        en: 'Yiwu hotels · weekend deal',
        photo: '/uploads/marketplace/hotel.jpg',
        scope: 'travel',
      },
      {
        id: 'tp2',
        ar: 'طيران دولي · عروض محدودة',
        en: 'International flights · limited',
        photo: '/uploads/marketplace/flight.jpg',
        scope: 'travel',
      },
    ];
    const daily = [
      {
        id: 'dp1',
        ar: 'خصم على التوصيل اليوم',
        en: 'Delivery discount today',
        photo: '/uploads/marketplace/food.jpg',
        scope: 'daily',
      },
    ];
    if (scope === 'daily') return daily;
    if (scope === 'travel') return travel;
    return [...travel, ...daily];
  }
}
