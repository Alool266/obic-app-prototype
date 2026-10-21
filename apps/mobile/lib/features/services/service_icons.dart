// Made by Dr Ali
// Map API icon keys → Material icons + accent colors that match each sub-service.

import 'package:flutter/material.dart';

/// Pro icons for mega-catalog sub-services (Alipay/WeChat hub layer 2).
IconData subServiceIcon(String icon) {
  switch (icon) {
    // —— Property ——
    case 'villa':
      return Icons.villa_rounded;
    case 'group':
    case 'groups':
      return Icons.groups_rounded;
    case 'hotel':
      return Icons.hotel_rounded;
    case 'rv_hookup':
      return Icons.rv_hookup;
    case 'apartment':
      return Icons.apartment_rounded;
    case 'sell':
      return Icons.sell_rounded;
    case 'home':
      return Icons.home_rounded;
    case 'domain':
      return Icons.domain_rounded;
    case 'business':
      return Icons.business_center_rounded;
    case 'warehouse':
      return Icons.warehouse_rounded;
    case 'property':
      return Icons.apartment_rounded;
    case 'real_estate_agent':
      return Icons.real_estate_agent_rounded;
    case 'home_work':
      return Icons.home_work_rounded;

    // —— Transport ——
    case 'flight':
    case 'flight_takeoff':
      return Icons.flight_rounded;
    case 'train':
      return Icons.train_rounded;
    case 'directions_railway':
      return Icons.directions_railway_rounded;
    case 'directions_bus':
      return Icons.directions_bus_rounded;
    case 'local_taxi':
      return Icons.local_taxi_rounded;
    case 'vip':
      return Icons.workspace_premium_rounded;
    case 'electric_scooter':
      return Icons.electric_scooter;
    case 'directions_boat':
      return Icons.directions_boat_rounded;
    case 'pedal_bike':
      return Icons.pedal_bike_rounded;
    case 'two_wheeler':
      return Icons.two_wheeler_rounded;
    case 'directions_car':
    case 'car':
      return Icons.directions_car_rounded;
    case 'moving':
      return Icons.airport_shuttle_rounded;

    // —— Travel ——
    case 'tour':
    case 'tourism':
      return Icons.tour_rounded;
    case 'person_pin':
      return Icons.person_pin_circle_rounded;
    case 'attractions':
      return Icons.attractions_rounded;
    case 'visa':
    case 'badge':
      return Icons.badge_rounded;
    case 'insurance':
      return Icons.health_and_safety_rounded;
    case 'medical_services':
      return Icons.medical_services_rounded;
    case 'mosque':
      return Icons.mosque_rounded;

    // —— Healthcare ——
    case 'local_hospital':
    case 'health':
      return Icons.local_hospital_rounded;
    case 'local_pharmacy':
      return Icons.local_pharmacy_rounded;
    case 'medical_information':
      return Icons.medical_information_rounded;
    case 'video_call':
      return Icons.video_call_rounded;
    case 'science':
      return Icons.science_rounded;
    case 'dentistry':
      return Icons.medical_services_outlined;
    case 'pets':
      return Icons.pets_rounded;

    // —— Food ——
    case 'restaurant':
    case 'restaurant_menu':
      return Icons.restaurant_rounded;
    case 'fastfood':
      return Icons.fastfood_rounded;
    case 'ramen_dining':
      return Icons.ramen_dining;
    case 'rice_bowl':
      return Icons.rice_bowl;
    case 'local_cafe':
      return Icons.local_cafe_rounded;
    case 'cake':
      return Icons.cake_rounded;
    case 'shopping_cart':
      return Icons.shopping_cart_rounded;

    // —— Shopping ——
    case 'shopping_bag':
    case 'shop':
      return Icons.shopping_bag_rounded;
    case 'checkroom':
      return Icons.checkroom_rounded;
    case 'devices':
      return Icons.devices_rounded;
    case 'chair':
      return Icons.chair_rounded;
    case 'palette':
      return Icons.palette_rounded;

    // —— Education ——
    case 'school':
      return Icons.school_rounded;
    case 'translate':
      return Icons.translate_rounded;
    case 'laptop':
      return Icons.laptop_mac_rounded;
    case 'menu_book':
      return Icons.menu_book_rounded;

    // —— Logistics ——
    case 'local_shipping':
    case 'delivery':
      return Icons.local_shipping_rounded;
    case 'inventory':
      return Icons.inventory_2_rounded;
    case 'factory':
      return Icons.factory_rounded;
    case 'recycling':
      return Icons.recycling;

    // —— Government / docs ——
    case 'account_balance':
    case 'bank':
      return Icons.account_balance_rounded;
    case 'gavel':
    case 'legal':
      return Icons.gavel_rounded;
    case 'description':
    case 'doc':
      return Icons.description_rounded;
    case 'assignment':
      return Icons.assignment_rounded;
    case 'admin_panel_settings':
      return Icons.admin_panel_settings_rounded;

    // —— Business ——
    case 'biz':
    case 'work':
      return Icons.work_rounded;
    case 'campaign':
    case 'ads':
      return Icons.campaign_rounded;
    case 'code':
      return Icons.code_rounded;
    case 'calculate':
      return Icons.calculate_rounded;
    case 'company':
      return Icons.business_rounded;

    // —— Legacy hub keys ——
    case 'book':
      return Icons.event_available_rounded;
    case 'location':
      return Icons.location_on_rounded;
    case 'speed':
      return Icons.bolt_rounded;
    case 'consult':
    case 'consultations':
      return Icons.support_agent_rounded;
    case 'verified':
      return Icons.verified_rounded;
    case 'fact_check':
      return Icons.fact_check_rounded;
    case 'workspace_premium':
      return Icons.workspace_premium_rounded;

    default:
      return Icons.apps_rounded;
  }
}

/// Soft circle fill + ink color so each sub-icon reads like Alipay (distinct per name).
({Color soft, Color ink}) subServiceIconColors(String icon) {
  switch (icon) {
    case 'villa':
    case 'apartment':
    case 'home':
    case 'property':
    case 'home_work':
    case 'domain':
      return (soft: const Color(0xFFE8F1FF), ink: const Color(0xFF2F6FED));
    case 'hotel':
      return (soft: const Color(0xFFFFF0E6), ink: const Color(0xFFE67E22));
    case 'sell':
    case 'real_estate_agent':
      return (soft: const Color(0xFFE8F8EF), ink: const Color(0xFF1B9E5A));
    case 'business':
    case 'warehouse':
    case 'factory':
      return (soft: const Color(0xFFF0EEFF), ink: const Color(0xFF5B4BDB));
    case 'rv_hookup':
      return (soft: const Color(0xFFEAF7F4), ink: const Color(0xFF0D9488));

    case 'flight':
    case 'flight_takeoff':
      return (soft: const Color(0xFFE8F4FF), ink: const Color(0xFF0284C7));
    case 'train':
    case 'directions_railway':
      return (soft: const Color(0xFFEEF2FF), ink: const Color(0xFF4F46E5));
    case 'directions_bus':
      return (soft: const Color(0xFFFFF7E6), ink: const Color(0xFFD97706));
    case 'local_taxi':
    case 'car':
    case 'directions_car':
      return (soft: const Color(0xFFFFF3E0), ink: const Color(0xFFF59E0B));
    case 'vip':
      return (soft: const Color(0xFFFFF8E7), ink: const Color(0xFFB45309));
    case 'electric_scooter':
    case 'pedal_bike':
    case 'two_wheeler':
      return (soft: const Color(0xFFE8FBF3), ink: const Color(0xFF059669));
    case 'directions_boat':
      return (soft: const Color(0xFFE0F2FE), ink: const Color(0xFF0369A1));
    case 'moving':
    case 'local_shipping':
    case 'delivery':
      return (soft: const Color(0xFFFFF1E8), ink: const Color(0xFFEA580C));

    case 'tour':
    case 'tourism':
    case 'attractions':
      return (soft: const Color(0xFFEAF8FF), ink: const Color(0xFF0891B2));
    case 'person_pin':
    case 'location':
      return (soft: const Color(0xFFFFEBEE), ink: const Color(0xFFE11D48));
    case 'visa':
    case 'badge':
      return (soft: const Color(0xFFEEF2FF), ink: const Color(0xFF4338CA));
    case 'insurance':
    case 'health':
    case 'medical_services':
    case 'local_hospital':
      return (soft: const Color(0xFFFFE8EC), ink: const Color(0xFFDC2626));
    case 'mosque':
      return (soft: const Color(0xFFE8F8F0), ink: const Color(0xFF15803D));

    case 'local_pharmacy':
      return (soft: const Color(0xFFFFE4E6), ink: const Color(0xFFE11D48));
    case 'medical_information':
    case 'science':
      return (soft: const Color(0xFFEDE9FE), ink: const Color(0xFF7C3AED));
    case 'video_call':
      return (soft: const Color(0xFFE0F2FE), ink: const Color(0xFF0284C7));
    case 'dentistry':
      return (soft: const Color(0xFFE0F7FA), ink: const Color(0xFF0E7490));
    case 'pets':
      return (soft: const Color(0xFFFFF3E0), ink: const Color(0xFFC2410C));

    case 'restaurant':
    case 'restaurant_menu':
      return (soft: const Color(0xFFFFF1E8), ink: const Color(0xFFEA580C));
    case 'ramen_dining':
      return (soft: const Color(0xFFFFE8E0), ink: const Color(0xFFC2410C));
    case 'rice_bowl':
      return (soft: const Color(0xFFFFF7ED), ink: const Color(0xFFB45309));
    case 'fastfood':
      return (soft: const Color(0xFFFFF3E0), ink: const Color(0xFFF59E0B));
    case 'cake':
      return (soft: const Color(0xFFFCE7F3), ink: const Color(0xFFDB2777));
    case 'local_cafe':
      return (soft: const Color(0xFFF5E6D3), ink: const Color(0xFF92400E));
    case 'shopping_cart':
      return (soft: const Color(0xFFE8F8EF), ink: const Color(0xFF16A34A));

    case 'shopping_bag':
    case 'shop':
      return (soft: const Color(0xFFFCE7F3), ink: const Color(0xFFDB2777));
    case 'checkroom':
      return (soft: const Color(0xFFF3E8FF), ink: const Color(0xFF9333EA));
    case 'devices':
      return (soft: const Color(0xFFE0F2FE), ink: const Color(0xFF2563EB));
    case 'chair':
      return (soft: const Color(0xFFF5F0E8), ink: const Color(0xFFA16207));
    case 'palette':
      return (soft: const Color(0xFFFCE7F3), ink: const Color(0xFFC026D3));
    case 'inventory':
      return (soft: const Color(0xFFEEF2FF), ink: const Color(0xFF4F46E5));
    case 'recycling':
      return (soft: const Color(0xFFE8F8EF), ink: const Color(0xFF16A34A));

    case 'school':
    case 'menu_book':
      return (soft: const Color(0xFFEEF2FF), ink: const Color(0xFF4F46E5));
    case 'translate':
      return (soft: const Color(0xFFE0F2FE), ink: const Color(0xFF0284C7));
    case 'laptop':
    case 'code':
      return (soft: const Color(0xFFE8EEFF), ink: const Color(0xFF3730A3));

    case 'account_balance':
    case 'bank':
      return (soft: const Color(0xFFE8F1FF), ink: const Color(0xFF1D4ED8));
    case 'gavel':
    case 'legal':
      return (soft: const Color(0xFFF3F4F6), ink: const Color(0xFF374151));
    case 'description':
    case 'doc':
    case 'assignment':
      return (soft: const Color(0xFFEEF2FF), ink: const Color(0xFF4338CA));
    case 'admin_panel_settings':
      return (soft: const Color(0xFFEDE9FE), ink: const Color(0xFF6D28D9));

    case 'biz':
    case 'work':
    case 'company':
      return (soft: const Color(0xFFE8F1FF), ink: const Color(0xFF1E40AF));
    case 'campaign':
    case 'ads':
      return (soft: const Color(0xFFFFE4E6), ink: const Color(0xFFE11D48));
    case 'calculate':
      return (soft: const Color(0xFFE8F8EF), ink: const Color(0xFF15803D));
    case 'group':
    case 'groups':
      return (soft: const Color(0xFFE0F2FE), ink: const Color(0xFF0369A1));

    case 'book':
      return (soft: const Color(0xFFE8F4FF), ink: const Color(0xFF2563EB));
    case 'speed':
      return (soft: const Color(0xFFFFF7E6), ink: const Color(0xFFD97706));
    case 'consult':
    case 'consultations':
      return (soft: const Color(0xFFEDE9FE), ink: const Color(0xFF7C3AED));
    case 'verified':
      return (soft: const Color(0xFFE8F8EF), ink: const Color(0xFF15803D));
    case 'fact_check':
      return (soft: const Color(0xFFFFF7E6), ink: const Color(0xFFD97706));
    case 'workspace_premium':
      return (soft: const Color(0xFFFFF8E7), ink: const Color(0xFFB45309));

    default:
      return (soft: const Color(0xFFEEF2FF), ink: const Color(0xFF334155));
  }
}
