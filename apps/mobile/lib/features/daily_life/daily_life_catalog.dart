// Made by Dr Ali
// Meituan-class daily categories → existing catalog parents/subs.

import 'package:flutter/material.dart';

class DailyGridItem {
  const DailyGridItem({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.labelZh,
    required this.icon,
    required this.color,
    required this.parentSlug,
    this.subServiceId,
  });

  final String id;
  final String labelAr;
  final String labelEn;
  final String labelZh;
  final IconData icon;
  final Color color;
  final String parentSlug;
  final String? subServiceId;

  String label(String lang) {
    if (lang.startsWith('ar')) return labelAr;
    if (lang.startsWith('zh')) return labelZh;
    return labelEn;
  }
}

class DailyMerchant {
  const DailyMerchant({
    required this.nameAr,
    required this.nameEn,
    required this.photo,
    required this.rating,
    required this.distanceKm,
    required this.etaMin,
    required this.feeYuan,
    required this.tags,
    required this.parentSlug,
    this.subServiceId,
  });

  final String nameAr;
  final String nameEn;
  final String photo;
  final double rating;
  final double distanceKm;
  final int etaMin;
  final int feeYuan;
  final List<String> tags;
  final String parentSlug;
  final String? subServiceId;

  String name(String lang) =>
      lang.startsWith('ar') ? nameAr : nameEn;
}

const kDailyGrid = <DailyGridItem>[
  DailyGridItem(
    id: 'food',
    labelAr: 'أكل',
    labelEn: 'Food',
    labelZh: '美食',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFE11D48),
    parentSlug: 'food',
    subServiceId: 'arabic',
  ),
  DailyGridItem(
    id: 'drinks',
    labelAr: 'مشروبات',
    labelEn: 'Drinks',
    labelZh: '饮品',
    icon: Icons.local_cafe_rounded,
    color: Color(0xFFD97706),
    parentSlug: 'food',
    subServiceId: 'coffee',
  ),
  DailyGridItem(
    id: 'supermarket',
    labelAr: 'سوبرماركت',
    labelEn: 'Supermarket',
    labelZh: '超市',
    icon: Icons.storefront_rounded,
    color: Color(0xFF059669),
    parentSlug: 'food',
    subServiceId: 'supermarket',
  ),
  DailyGridItem(
    id: 'produce',
    labelAr: 'خضار',
    labelEn: 'Produce',
    labelZh: '果蔬',
    icon: Icons.eco_rounded,
    color: Color(0xFF16A34A),
    parentSlug: 'shopping',
    subServiceId: 'groceries',
  ),
  DailyGridItem(
    id: 'pharmacy',
    labelAr: 'صيدلية',
    labelEn: 'Pharmacy',
    labelZh: '药店',
    icon: Icons.local_pharmacy_rounded,
    color: Color(0xFF0891B2),
    parentSlug: 'healthcare',
    subServiceId: 'pharmacies',
  ),
  DailyGridItem(
    id: 'health',
    labelAr: 'رعاية صحية',
    labelEn: 'Healthcare',
    labelZh: '医疗',
    icon: Icons.medical_services_rounded,
    color: Color(0xFF2563EB),
    parentSlug: 'healthcare',
    subServiceId: 'clinics',
  ),
  DailyGridItem(
    id: 'errands',
    labelAr: 'مشاوير',
    labelEn: 'Errands',
    labelZh: '跑腿',
    icon: Icons.delivery_dining_rounded,
    color: Color(0xFF7C3AED),
    parentSlug: 'logistics',
    subServiceId: 'delivery',
  ),
  DailyGridItem(
    id: 'local-shop',
    labelAr: 'تسوق محلي',
    labelEn: 'Local shop',
    labelZh: '本地购',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFDB2777),
    parentSlug: 'shopping',
    subServiceId: 'electronics',
  ),
  DailyGridItem(
    id: 'chinese-food',
    labelAr: 'صيني',
    labelEn: 'Chinese',
    labelZh: '中餐',
    icon: Icons.ramen_dining_rounded,
    color: Color(0xFFDC2626),
    parentSlug: 'food',
    subServiceId: 'chinese',
  ),
  DailyGridItem(
    id: 'sweets',
    labelAr: 'حلويات',
    labelEn: 'Sweets',
    labelZh: '甜品',
    icon: Icons.cake_rounded,
    color: Color(0xFFEA580C),
    parentSlug: 'food',
    subServiceId: 'sweets',
  ),
  DailyGridItem(
    id: 'delivery',
    labelAr: 'توصيل',
    labelEn: 'Delivery',
    labelZh: '外卖',
    icon: Icons.moped_rounded,
    color: Color(0xFF4F46E5),
    parentSlug: 'food',
    subServiceId: 'food-delivery',
  ),
  DailyGridItem(
    id: 'beauty',
    labelAr: 'جمال',
    labelEn: 'Beauty',
    labelZh: '美妆',
    icon: Icons.spa_rounded,
    color: Color(0xFFC026D3),
    parentSlug: 'shopping',
    subServiceId: 'beauty',
  ),
];

const kDailyPromos = <({String ar, String en, String photo, Color tint})>[
  (
    ar: 'خصم على التوصيل اليوم',
    en: 'Delivery discount today',
    photo: 'assets/daily/food.jpg',
    tint: Color(0xFF1A6DFF),
  ),
  (
    ar: 'صيدليات قريبة · توصيل سريع',
    en: 'Nearby pharmacies · fast ETA',
    photo: 'assets/daily/pharmacy.jpg',
    tint: Color(0xFF0891B2),
  ),
  (
    ar: 'سوق طازج هذا الصباح',
    en: 'Fresh market this morning',
    photo: 'assets/daily/market.jpg',
    tint: Color(0xFF059669),
  ),
];

const kDailyMerchants = <DailyMerchant>[
  DailyMerchant(
    nameAr: 'مندي ييوو',
    nameEn: 'Yiwu Mandi House',
    photo: 'assets/daily/food.jpg',
    rating: 4.8,
    distanceKm: 0.6,
    etaMin: 28,
    feeYuan: 6,
    tags: ['عربي', 'توصيل'],
    parentSlug: 'food',
    subServiceId: 'arabic',
  ),
  DailyMerchant(
    nameAr: 'كافيه أوبك',
    nameEn: 'OBIC Café',
    photo: 'assets/daily/cafe.jpg',
    rating: 4.6,
    distanceKm: 0.9,
    etaMin: 22,
    feeYuan: 4,
    tags: ['قهوة', 'حلويات'],
    parentSlug: 'food',
    subServiceId: 'coffee',
  ),
  DailyMerchant(
    nameAr: 'صيدلية النور',
    nameEn: 'Al-Noor Pharmacy',
    photo: 'assets/daily/pharmacy.jpg',
    rating: 4.9,
    distanceKm: 1.2,
    etaMin: 35,
    feeYuan: 5,
    tags: ['24س', 'أدوية'],
    parentSlug: 'healthcare',
    subServiceId: 'pharmacies',
  ),
  DailyMerchant(
    nameAr: 'سوق الخضار الطازج',
    nameEn: 'Fresh Produce Market',
    photo: 'assets/daily/market.jpg',
    rating: 4.5,
    distanceKm: 1.5,
    etaMin: 40,
    feeYuan: 8,
    tags: ['خضار', 'فواكه'],
    parentSlug: 'shopping',
    subServiceId: 'groceries',
  ),
];
