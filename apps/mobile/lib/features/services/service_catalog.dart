// Made by Dr Ali
// Catalog models + offline seed (matches prototype / API seed).

import 'package:flutter/material.dart';

import 'mega_catalog_seed.dart';
import '../../theme/obic_colors.dart';

class ObicService {
  const ObicService({
    required this.id,
    required this.slug,
    required this.icon,
    this.colorKey,
    required this.sortOrder,
    required this.nameAr,
    required this.nameEn,
    this.nameZh = '',
    required this.descAr,
    required this.descEn,
    this.descZh = '',
    required this.priceAr,
    required this.priceEn,
    this.priceZh = '',
  });

  final String id;
  final String slug;
  final String icon;
  final String? colorKey;
  final int sortOrder;
  final String nameAr;
  final String nameEn;
  final String nameZh;
  final String descAr;
  final String descEn;
  final String descZh;
  final String priceAr;
  final String priceEn;
  final String priceZh;

  String name(String langCode) {
    switch (langCode) {
      case 'ar':
        return nameAr;
      case 'zh':
        return nameZh.isNotEmpty ? nameZh : nameEn;
      default:
        return nameEn;
    }
  }

  String desc(String langCode) {
    switch (langCode) {
      case 'ar':
        return descAr;
      case 'zh':
        return descZh.isNotEmpty ? descZh : descEn;
      default:
        return descEn;
    }
  }

  String price(String langCode) {
    switch (langCode) {
      case 'ar':
        return priceAr;
      case 'zh':
        return priceZh.isNotEmpty ? priceZh : priceEn;
      default:
        return priceEn;
    }
  }

  bool get isPrimary => colorKey != null;

  factory ObicService.fromJson(Map<String, dynamic> json) {
    return ObicService(
      id: json['id'] as String? ?? json['slug'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String,
      colorKey: json['colorKey'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      nameZh: json['nameZh'] as String? ?? '',
      descAr: json['descAr'] as String,
      descEn: json['descEn'] as String,
      descZh: json['descZh'] as String? ?? '',
      priceAr: json['priceAr'] as String,
      priceEn: json['priceEn'] as String,
      priceZh: json['priceZh'] as String? ?? '',
    );
  }
}

/// Ctrip-style primary tile gradients (prototype COLORS).
class ServiceTheme {
  const ServiceTheme({
    required this.start,
    required this.end,
    required this.soft,
    required this.ink,
  });

  final Color start;
  final Color end;
  final Color soft;
  final Color ink;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [start, end],
      );

  static const hotels = ServiceTheme(
    start: Color(0xFFFB7185),
    end: Color(0xFFE11D48),
    soft: Color(0xFFFFE4E6),
    ink: Color(0xFFE11D48),
  );
  static const flights = ServiceTheme(
    start: Color(0xFF60A5FA),
    end: Color(0xFF1A6DFF),
    soft: Color(0xFFDBEAFE),
    ink: Color(0xFF1A6DFF),
  );
  static const visa = ServiceTheme(
    start: Color(0xFF2DD4BF),
    end: Color(0xFF0D9488),
    soft: Color(0xFFCCFBF1),
    ink: Color(0xFF0D9488),
  );
  static const bank = ServiceTheme(
    start: Color(0xFF4ADE80),
    end: Color(0xFF16A34A),
    soft: Color(0xFFDCFCE7),
    ink: Color(0xFF16A34A),
  );
  static const vip = ServiceTheme(
    start: Color(0xFFFB923C),
    end: Color(0xFFEA580C),
    soft: Color(0xFFFFEDD5),
    ink: Color(0xFFEA580C),
  );
  static const business = ServiceTheme(
    start: Color(0xFF6366F1),
    end: Color(0xFF4338CA),
    soft: Color(0xFFE0E7FF),
    ink: Color(0xFF4338CA),
  );
  static const property = ServiceTheme(
    start: Color(0xFF34D399),
    end: Color(0xFF059669),
    soft: Color(0xFFD1FAE5),
    ink: Color(0xFF059669),
  );
  static const transport = ServiceTheme(
    start: Color(0xFF60A5FA),
    end: Color(0xFF2563EB),
    soft: Color(0xFFDBEAFE),
    ink: Color(0xFF2563EB),
  );
  static const travel = ServiceTheme(
    start: Color(0xFFFB7185),
    end: Color(0xFFE11D48),
    soft: Color(0xFFFFE4E6),
    ink: Color(0xFFE11D48),
  );
  static const healthcare = ServiceTheme(
    start: Color(0xFF2DD4BF),
    end: Color(0xFF0D9488),
    soft: Color(0xFFCCFBF1),
    ink: Color(0xFF0D9488),
  );
  static const food = ServiceTheme(
    start: Color(0xFFFB923C),
    end: Color(0xFFEA580C),
    soft: Color(0xFFFFEDD5),
    ink: Color(0xFFEA580C),
  );
  static const shopping = ServiceTheme(
    start: Color(0xFFA78BFA),
    end: Color(0xFF7C3AED),
    soft: Color(0xFFEDE9FE),
    ink: Color(0xFF7C3AED),
  );
  static const education = ServiceTheme(
    start: Color(0xFF38BDF8),
    end: Color(0xFF0284C7),
    soft: Color(0xFFE0F2FE),
    ink: Color(0xFF0284C7),
  );
  static const logistics = ServiceTheme(
    start: Color(0xFF94A3B8),
    end: Color(0xFF475569),
    soft: Color(0xFFF1F5F9),
    ink: Color(0xFF475569),
  );
  static const government = ServiceTheme(
    start: Color(0xFF4ADE80),
    end: Color(0xFF16A34A),
    soft: Color(0xFFDCFCE7),
    ink: Color(0xFF16A34A),
  );
  static const fallback = ServiceTheme(
    start: Color(0xFF93C5FD),
    end: Color(0xFF1A6DFF),
    soft: ObicColors.blueSoft,
    ink: ObicColors.blue,
  );

  static ServiceTheme of(String? colorKey) {
    switch (colorKey) {
      case 'hotels':
        return hotels;
      case 'flights':
        return flights;
      case 'visa':
        return visa;
      case 'bank':
        return bank;
      case 'vip':
        return vip;
      case 'property':
        return property;
      case 'transport':
        return transport;
      case 'travel':
        return travel;
      case 'healthcare':
        return healthcare;
      case 'food':
        return food;
      case 'shopping':
        return shopping;
      case 'education':
        return education;
      case 'logistics':
        return logistics;
      case 'government':
        return government;
      case 'business':
        return business;
      default:
        return fallback;
    }
  }
}

IconData serviceIconData(String icon) {
  switch (icon) {
    case 'hotel':
      return Icons.hotel_rounded;
    case 'flight':
      return Icons.flight_rounded;
    case 'visa':
      return Icons.badge_rounded;
    case 'bank':
    case 'account_balance':
      return Icons.account_balance_rounded;
    case 'vip':
      return Icons.workspace_premium_rounded;
    case 'legal':
    case 'gavel':
      return Icons.gavel_rounded;
    case 'company':
      return Icons.business_rounded;
    case 'scholarship':
    case 'school':
      return Icons.school_rounded;
    case 'transfer':
      return Icons.swap_horiz_rounded;
    case 'ads':
    case 'campaign':
      return Icons.campaign_rounded;
    case 'biz':
    case 'work':
      return Icons.work_rounded;
    case 'hr':
    case 'groups':
      return Icons.groups_rounded;
    case 'insurance':
      return Icons.health_and_safety_rounded;
    case 'expand':
      return Icons.public_rounded;
    case 'tech':
      return Icons.support_agent_rounded;
    case 'plan':
      return Icons.assignment_rounded;
    case 'cars':
    case 'directions_car':
      return Icons.directions_car_rounded;
    case 'property':
      return Icons.apartment_rounded;
    case 'delivery':
    case 'local_shipping':
      return Icons.local_shipping_rounded;
    case 'consultations':
      return Icons.support_agent_rounded;
    case 'translation':
    case 'translate':
      return Icons.translate_rounded;
    case 'tourism':
    case 'tour':
      return Icons.tour_rounded;
    case 'local_hospital':
      return Icons.local_hospital_rounded;
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'shopping_bag':
      return Icons.shopping_bag_rounded;
    case 'food':
      return Icons.restaurant_rounded;
    case 'transport':
      return Icons.directions_car_rounded;
    case 'healthcare':
      return Icons.local_hospital_rounded;
    case 'shopping':
      return Icons.shopping_bag_rounded;
    case 'education':
      return Icons.school_rounded;
    case 'logistics':
      return Icons.local_shipping_rounded;
    case 'government':
      return Icons.account_balance_rounded;
    case 'business':
      return Icons.work_rounded;
    default:
      return Icons.grid_view_rounded;
  }
}

/// Offline fallback when API is unreachable — 10 mega categories.
List<ObicService> localCatalogSeed({String? countryCode}) {
  return filterMegaCatalogJson(countryCode)
      .map((m) => ObicService.fromJson(m))
      .toList();
}
