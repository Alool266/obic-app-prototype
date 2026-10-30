// Made by Dr Ali
// Ctrip-style travel categories → existing catalog parents/subs.

import 'package:flutter/material.dart';

import 'travel_media.dart';

class TravelCat {
  const TravelCat({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.labelZh,
    required this.icon,
    required this.photo,
    required this.parentSlug,
    this.subServiceId,
    this.accent = const Color(0xFF1A6DFF),
  });

  final String id;
  final String labelAr;
  final String labelEn;
  final String labelZh;
  final IconData icon;
  final String photo;
  final String parentSlug;
  final String? subServiceId;
  final Color accent;

  String label(String lang) {
    if (lang.startsWith('ar')) return labelAr;
    if (lang.startsWith('zh')) return labelZh;
    return labelEn;
  }
}

class TravelPromo {
  const TravelPromo({
    required this.ar,
    required this.en,
    required this.photo,
    required this.tint,
    required this.parentSlug,
    this.subServiceId,
  });

  final String ar;
  final String en;
  final String photo;
  final Color tint;
  final String parentSlug;
  final String? subServiceId;
}

/// Big top row — فنادق، معالم، طيران، قطارات، إجازات
const kTravelTop = <TravelCat>[
  TravelCat(
    id: 'hotels',
    labelAr: 'فنادق',
    labelEn: 'Hotels',
    labelZh: '酒店',
    icon: Icons.hotel_rounded,
    photo: TravelMedia.hotel,
    parentSlug: 'travel',
    subServiceId: 'hotels',
    accent: Color(0xFF1A6DFF),
  ),
  TravelCat(
    id: 'attractions',
    labelAr: 'معالم',
    labelEn: 'Sights',
    labelZh: '景点',
    icon: Icons.attractions,
    photo: TravelMedia.landmark,
    parentSlug: 'travel',
    subServiceId: 'attractions',
    accent: Color(0xFF0891B2),
  ),
  TravelCat(
    id: 'flights',
    labelAr: 'طيران',
    labelEn: 'Flights',
    labelZh: '机票',
    icon: Icons.flight_rounded,
    photo: TravelMedia.flight,
    parentSlug: 'transport',
    subServiceId: 'flights',
    accent: Color(0xFF2563EB),
  ),
  TravelCat(
    id: 'trains',
    labelAr: 'قطارات',
    labelEn: 'Trains',
    labelZh: '火车',
    icon: Icons.train_rounded,
    photo: TravelMedia.train,
    parentSlug: 'transport',
    subServiceId: 'bullet-train',
    accent: Color(0xFF0B4FD6),
  ),
  TravelCat(
    id: 'holidays',
    labelAr: 'إجازات',
    labelEn: 'Holidays',
    labelZh: '度假',
    icon: Icons.beach_access_rounded,
    photo: TravelMedia.landmark,
    parentSlug: 'travel',
    subServiceId: 'tours',
    accent: Color(0xFF059669),
  ),
];

/// Second row — إقامة، تذاكر، توصيل مطار، تأجير، جولات
const kTravelSecond = <TravelCat>[
  TravelCat(
    id: 'tickets',
    labelAr: 'تذاكر',
    labelEn: 'Tickets',
    labelZh: '门票',
    icon: Icons.confirmation_number_rounded,
    photo: TravelMedia.landmark,
    parentSlug: 'travel',
    subServiceId: 'attractions',
  ),
  TravelCat(
    id: 'airport',
    labelAr: 'توصيل مطار',
    labelEn: 'Airport',
    labelZh: '接机',
    icon: Icons.airport_shuttle_rounded,
    photo: TravelMedia.flight,
    parentSlug: 'transport',
    subServiceId: 'private-transfer',
  ),
  TravelCat(
    id: 'rental',
    labelAr: 'تأجير',
    labelEn: 'Rental',
    labelZh: '租车',
    icon: Icons.directions_car_filled_rounded,
    photo: TravelMedia.flight,
    parentSlug: 'transport',
    subServiceId: 'car-rental',
  ),
  TravelCat(
    id: 'tours',
    labelAr: 'جولات',
    labelEn: 'Tours',
    labelZh: '跟团',
    icon: Icons.tour_rounded,
    photo: TravelMedia.landmark,
    parentSlug: 'travel',
    subServiceId: 'tours',
  ),
];

/// More sheet extras
const kTravelMore = <TravelCat>[
  TravelCat(
    id: 'guide',
    labelAr: 'مرشد',
    labelEn: 'Guide',
    labelZh: '导游',
    icon: Icons.person_pin_circle_rounded,
    photo: TravelMedia.landmark,
    parentSlug: 'travel',
    subServiceId: 'guide',
  ),
  TravelCat(
    id: 'visa',
    labelAr: 'تأشيرة',
    labelEn: 'Visa',
    labelZh: '签证',
    icon: Icons.badge_rounded,
    photo: TravelMedia.flight,
    parentSlug: 'travel',
    subServiceId: 'visa',
  ),
  TravelCat(
    id: 'insurance',
    labelAr: 'تأمين',
    labelEn: 'Insurance',
    labelZh: '保险',
    icon: Icons.health_and_safety_rounded,
    photo: TravelMedia.hotel,
    parentSlug: 'travel',
    subServiceId: 'travel-insurance',
  ),
  TravelCat(
    id: 'vip-taxi',
    labelAr: 'VIP',
    labelEn: 'VIP car',
    labelZh: '专车',
    icon: Icons.airport_shuttle_rounded,
    photo: TravelMedia.flight,
    parentSlug: 'transport',
    subServiceId: 'vip-taxi',
  ),
  TravelCat(
    id: 'medical-tourism',
    labelAr: 'سياحة طبية',
    labelEn: 'Medical',
    labelZh: '医疗游',
    icon: Icons.medical_services_rounded,
    photo: TravelMedia.hotel,
    parentSlug: 'travel',
    subServiceId: 'medical-tourism',
  ),
];

const kTravelCities = <({String ar, String en, String zh})>[
  (ar: 'ييوو', en: 'Yiwu', zh: '义乌'),
  (ar: 'شنغهاي', en: 'Shanghai', zh: '上海'),
  (ar: 'بكين', en: 'Beijing', zh: '北京'),
  (ar: 'غوانزو', en: 'Guangzhou', zh: '广州'),
  (ar: 'هانغتشو', en: 'Hangzhou', zh: '杭州'),
  (ar: 'شنتشن', en: 'Shenzhen', zh: '深圳'),
];

const kTravelPromos = <TravelPromo>[
  TravelPromo(
    ar: 'فنادق ييوو · خصم نهاية الأسبوع',
    en: 'Yiwu hotels · weekend deal',
    photo: TravelMedia.hotel,
    tint: Color(0xFF0B1F3A),
    parentSlug: 'travel',
    subServiceId: 'hotels',
  ),
  TravelPromo(
    ar: 'طيران دولي · عروض محدودة',
    en: 'International flights · limited',
    photo: TravelMedia.flight,
    tint: Color(0xFF1A6DFF),
    parentSlug: 'transport',
    subServiceId: 'flights',
  ),
  TravelPromo(
    ar: 'معالم الصين · تذاكر فورية',
    en: 'China sights · instant tickets',
    photo: TravelMedia.landmark,
    tint: Color(0xFF0891B2),
    parentSlug: 'travel',
    subServiceId: 'attractions',
  ),
];
