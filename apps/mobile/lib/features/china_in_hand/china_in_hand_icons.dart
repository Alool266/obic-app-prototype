// Made by Dr Ali
// Distinct icons + accents per الصين بين يديك tile (no repeated buildings).

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';

/// Big landing category cards — unique marks (not generic 4-square grids).
({IconData icon, Color soft, Color ink}) chinaCategoryVisual(String categoryId) {
  switch (categoryId) {
    case 'business':
      return (
        icon: Icons.business_center_rounded,
        soft: const Color(0xFF1E3A5F),
        ink: const Color(0xFFC9A227),
      );
    case 'property':
      return (
        icon: Icons.domain_rounded,
        soft: const Color(0xFF14532D),
        ink: const Color(0xFF86EFAC),
      );
    case 'visa-docs':
      return (
        icon: Icons.fingerprint_rounded,
        soft: const Color(0xFF134E4A),
        ink: const Color(0xFF5EEAD4),
      );
    case 'education':
      return (
        icon: Icons.menu_book_rounded,
        soft: const Color(0xFF4C1D95),
        ink: const Color(0xFFC4B5FD),
      );
    case 'sourcing-logistics':
      return (
        icon: Icons.local_shipping_rounded,
        soft: const Color(0xFF7C2D12),
        ink: const Color(0xFFFDBA74),
      );
    case 'stay-tour':
      return (
        icon: Icons.explore_rounded,
        soft: const Color(0xFF1E3A8A),
        ink: const Color(0xFF93C5FD),
      );
    default:
      return (
        icon: Icons.travel_explore_rounded,
        soft: ObicColors.navy,
        ink: const Color(0xFFC9A227),
      );
  }
}

({IconData icon, Color soft, Color ink}) chinaHubVisual(String tileId) {
  switch (tileId) {
    case 'scholarships':
      return (
        icon: Icons.school_rounded,
        soft: const Color(0xFFEDE9FE),
        ink: const Color(0xFF6D28D9),
      );
    case 'visit-near-me':
      return (
        icon: Icons.place_rounded,
        soft: const Color(0xFFFEF3C7),
        ink: const Color(0xFFB45309),
      );
    case 'company-registration':
      return (
        icon: Icons.apartment_rounded,
        soft: const Color(0xFFE0E7FF),
        ink: const Color(0xFF4338CA),
      );
    case 'china-exhibitions':
      return (
        icon: Icons.storefront_rounded,
        soft: const Color(0xFFFFF7E0),
        ink: const Color(0xFFB45309),
      );
    case 'business-consult':
      return (
        icon: Icons.handshake_rounded,
        soft: const Color(0xFFE0F2FE),
        ink: const Color(0xFF0369A1),
      );
    case 'trademarks':
      return (
        icon: Icons.copyright_rounded,
        soft: const Color(0xFFFCE7F3),
        ink: const Color(0xFFBE185D),
      );
    case 'vip-trip':
      return (
        icon: Icons.workspace_premium_rounded,
        soft: const Color(0xFFFFF7ED),
        ink: const Color(0xFFC2410C),
      );
    case 'sale':
      return (
        icon: Icons.real_estate_agent_rounded,
        soft: const Color(0xFFD1FAE5),
        ink: const Color(0xFF059669),
      );
    case 'offices':
      return (
        icon: Icons.meeting_room_rounded,
        soft: const Color(0xFFE0E7FF),
        ink: const Color(0xFF4F46E5),
      );
    case 'apartments':
      return (
        icon: Icons.holiday_village_rounded,
        soft: const Color(0xFFCCFBF1),
        ink: const Color(0xFF0F766E),
      );
    case 'warehouses':
      return (
        icon: Icons.warehouse_rounded,
        soft: const Color(0xFFF1F5F9),
        ink: const Color(0xFF475569),
      );
    case 'property-advice':
      return (
        icon: Icons.maps_home_work_rounded,
        soft: const Color(0xFFDCFCE7),
        ink: const Color(0xFF15803D),
      );
    case 'visas':
      return (
        icon: Icons.badge_rounded,
        soft: const Color(0xFFCCFBF1),
        ink: const Color(0xFF0D9488),
      );
    case 'residence':
      return (
        icon: Icons.home_work_rounded,
        soft: const Color(0xFFE0F2FE),
        ink: const Color(0xFF0284C7),
      );
    case 'document-attestation':
      return (
        icon: Icons.verified_user_rounded,
        soft: const Color(0xFFFEF3C7),
        ink: const Color(0xFFB45309),
      );
    case 'documents':
      return (
        icon: Icons.description_rounded,
        soft: const Color(0xFFF1F5F9),
        ink: const Color(0xFF334155),
      );
    case 'legal-translation':
      return (
        icon: Icons.translate_rounded,
        soft: const Color(0xFFEDE9FE),
        ink: const Color(0xFF6D28D9),
      );
    case 'contract-notarization':
      return (
        icon: Icons.gavel_rounded,
        soft: const Color(0xFFFFE4E6),
        ink: const Color(0xFFBE123C),
      );
    case 'tax-consulting':
      return (
        icon: Icons.account_balance_rounded,
        soft: const Color(0xFFDBEAFE),
        ink: ObicColors.blueDeep,
      );
    case 'accounting':
      return (
        icon: Icons.calculate_rounded,
        soft: const Color(0xFFE0E7FF),
        ink: const Color(0xFF3730A3),
      );
    case 'tax-services':
      return (
        icon: Icons.receipt_long_rounded,
        soft: const Color(0xFFFEF3C7),
        ink: const Color(0xFFA16207),
      );
    case 'quality-inspection':
      return (
        icon: Icons.fact_check_rounded,
        soft: const Color(0xFFDCFCE7),
        ink: const Color(0xFF166534),
      );
    case 'legal':
      return (
        icon: Icons.balance_rounded,
        soft: const Color(0xFFEDE9FE),
        ink: const Color(0xFF5B21B6),
      );
    case 'property-consult':
      return (
        icon: Icons.real_estate_agent_rounded,
        soft: const Color(0xFFDCFCE7),
        ink: const Color(0xFF15803D),
      );
    case 'chinese-lang':
      return (
        icon: Icons.translate_rounded,
        soft: const Color(0xFFFFE4E6),
        ink: const Color(0xFFBE123C),
      );
    case 'marketing':
      return (
        icon: Icons.campaign_rounded,
        soft: const Color(0xFFFFEDD5),
        ink: const Color(0xFFC2410C),
      );
    case 'programming':
      return (
        icon: Icons.code_rounded,
        soft: const Color(0xFFE0E7FF),
        ink: const Color(0xFF4338CA),
      );
    case 'design':
      return (
        icon: Icons.palette_rounded,
        soft: const Color(0xFFFCE7F3),
        ink: const Color(0xFFBE185D),
      );
    case 'factories':
      return (
        icon: Icons.factory_rounded,
        soft: const Color(0xFFF1F5F9),
        ink: const Color(0xFF334155),
      );
    case 'products':
      return (
        icon: Icons.inventory_2_rounded,
        soft: const Color(0xFFE0F2FE),
        ink: const Color(0xFF0369A1),
      );
    case 'hotels':
      return (
        icon: Icons.hotel_rounded,
        soft: const Color(0xFFE0F2FE),
        ink: const Color(0xFF0369A1),
      );
    case 'tours':
      return (
        icon: Icons.tour_rounded,
        soft: const Color(0xFFFEF3C7),
        ink: const Color(0xFFB45309),
      );
    default:
      return (
        icon: Icons.grid_view_rounded,
        soft: ObicColors.blueSoft,
        ink: ObicColors.blue,
      );
  }
}
