// Made by Dr Ali
// Route يومي / سفر taps → real category UIs (not generic request forms).

import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../services/open_sub_service.dart';
import '../services/service_catalog.dart';
import '../services/service_sub_catalog.dart';
import '../services/services_api.dart';
import 'marketplace_models.dart';
import 'pages/daily_browse_pages.dart';
import 'pages/travel_browse_pages.dart';

/// Daily hub grid id → marketplace vertical.
MarketplaceVertical? dailyVerticalForId(String id) {
  switch (id) {
    case 'food':
    case 'chinese-food':
    case 'sweets':
    case 'drinks':
    case 'delivery':
      return MarketplaceVertical.food;
    case 'pharmacy':
      return MarketplaceVertical.pharmacy;
    case 'supermarket':
    case 'produce':
      return MarketplaceVertical.market;
    case 'errands':
      return MarketplaceVertical.errand;
    case 'health':
      return MarketplaceVertical.clinic;
    case 'beauty':
      return MarketplaceVertical.beauty;
    case 'local-shop':
      return MarketplaceVertical.shop;
    default:
      return null;
  }
}

/// Travel cat id → vertical. Visa/guide/insurance are NOT tours.
MarketplaceVertical? travelVerticalForId(String id) {
  switch (id) {
    case 'hotels':
    case 'stay':
      return MarketplaceVertical.hotel;
    case 'flights':
      return MarketplaceVertical.flight;
    case 'trains':
      return MarketplaceVertical.train;
    case 'attractions':
    case 'tickets':
      return MarketplaceVertical.attraction;
    case 'holidays':
    case 'tours':
      return MarketplaceVertical.tour;
    case 'airport':
      return MarketplaceVertical.transfer;
    case 'rental':
      return MarketplaceVertical.carRental;
    default:
      return null;
  }
}

/// Ids that open a catalog ServiceRequest form (not a tour dump).
bool isTravelServiceRequestId(String id) {
  switch (id) {
    case 'visa':
    case 'guide':
    case 'insurance':
    case 'travel-insurance':
    case 'vip-taxi':
    case 'medical-tourism':
      return true;
    default:
      return false;
  }
}

(String parent, String sub) travelRequestRoute(String id) {
  switch (id) {
    case 'visa':
      return ('travel', 'visa');
    case 'guide':
      return ('travel', 'guide');
    case 'insurance':
    case 'travel-insurance':
      return ('travel', 'travel-insurance');
    case 'vip-taxi':
      return ('transport', 'vip-taxi');
    case 'medical-tourism':
      return ('travel', 'medical-tourism');
    default:
      return ('travel', id);
  }
}

Future<ObicService?> _resolveParent(String parentSlug) async {
  try {
    final catalog = await ServicesApi().fetchCatalog();
    for (final s in catalog) {
      if (s.slug == parentSlug) return s;
    }
  } catch (_) {}
  for (final s in localCatalogSeed()) {
    if (s.slug == parentSlug) return s;
  }
  return null;
}

Future<void> openTravelServiceRequest({
  required BuildContext context,
  required AuthController authController,
  required String langCode,
  required String catId,
}) async {
  final route = travelRequestRoute(catId);
  final parentSlug = route.$1;
  final subId = route.$2;

  final service = await _resolveParent(parentSlug);
  if (service == null || !context.mounted) return;

  ObicSubService? sub;
  for (final item in subServicesForParent(parentSlug)) {
    if (item.id == subId) {
      sub = item;
      break;
    }
  }
  if (sub == null && subId == 'visa') {
    for (final item in subServicesForParent('travel')) {
      if (item.id == 'visa') {
        sub = item;
        break;
      }
    }
  }
  if (sub == null) {
    // Last resort: still open travel visa-shaped request via hotel? No —
    // open a titled tour request only if sub missing is wrong. Prefer hotel.
    if (!context.mounted) return;
    await openMarketplaceCategory(
      context: context,
      authController: authController,
      langCode: langCode,
      vertical: MarketplaceVertical.hotel,
    );
    return;
  }

  await openSubServiceDirect(
    context: context,
    authController: authController,
    langCode: langCode,
    service: service,
    sub: sub,
  );
}

Future<void> openMarketplaceCategory({
  required BuildContext context,
  required AuthController authController,
  required String langCode,
  required MarketplaceVertical vertical,
  String? titleOverride,
  String? foodFilter,
  String? city,
}) {
  final Widget page;
  switch (vertical) {
    case MarketplaceVertical.hotel:
      page = HotelBrowsePage(
        authController: authController,
        langCode: langCode,
        initialCity: city,
      );
    case MarketplaceVertical.flight:
      page = FlightBrowsePage(
        authController: authController,
        langCode: langCode,
      );
    case MarketplaceVertical.train:
      page = TrainBrowsePage(
        authController: authController,
        langCode: langCode,
      );
    case MarketplaceVertical.attraction:
      page = AttractionBrowsePage(
        authController: authController,
        langCode: langCode,
        initialCity: city,
      );
    case MarketplaceVertical.tour:
      page = TourBrowsePage(
        authController: authController,
        langCode: langCode,
        titleOverride: titleOverride,
      );
    case MarketplaceVertical.transfer:
      page = TransferBrowsePage(
        authController: authController,
        langCode: langCode,
      );
    case MarketplaceVertical.carRental:
      page = CarRentalBrowsePage(
        authController: authController,
        langCode: langCode,
      );
    case MarketplaceVertical.food:
      page = FoodBrowsePage(
        authController: authController,
        langCode: langCode,
        filterHint: foodFilter,
      );
    case MarketplaceVertical.pharmacy:
      page = PharmacyBrowsePage(
        authController: authController,
        langCode: langCode,
      );
    case MarketplaceVertical.market:
      page = MarketBrowsePage(
        authController: authController,
        langCode: langCode,
        titleOverride: titleOverride,
      );
    case MarketplaceVertical.errand:
      page = ErrandBrowsePage(
        authController: authController,
        langCode: langCode,
      );
    case MarketplaceVertical.clinic:
      page = ClinicBrowsePage(
        authController: authController,
        langCode: langCode,
      );
    case MarketplaceVertical.beauty:
      page = BeautyBrowsePage(
        authController: authController,
        langCode: langCode,
      );
    case MarketplaceVertical.shop:
      page = ShopBrowsePage(
        authController: authController,
        langCode: langCode,
      );
  }
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => page),
  );
}
