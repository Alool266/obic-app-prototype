// Made by Dr Ali
// Create a real OBIC order from يومي/سفر marketplace CTAs (no Airwallex hold).

import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../services/service_catalog.dart';
import '../services/services_api.dart';
import 'marketplace_models.dart';
import 'marketplace_order_page.dart';
import 'pages/marketplace_chrome.dart';

String marketplaceParentSlug(MarketplaceVertical vertical) {
  switch (vertical) {
    case MarketplaceVertical.food:
    case MarketplaceVertical.pharmacy:
    case MarketplaceVertical.market:
    case MarketplaceVertical.beauty:
    case MarketplaceVertical.shop:
      return 'food';
    case MarketplaceVertical.clinic:
      return 'healthcare';
    case MarketplaceVertical.errand:
      return 'logistics';
    case MarketplaceVertical.hotel:
    case MarketplaceVertical.attraction:
    case MarketplaceVertical.tour:
      return 'travel';
    case MarketplaceVertical.flight:
    case MarketplaceVertical.train:
    case MarketplaceVertical.transfer:
    case MarketplaceVertical.carRental:
      return 'transport';
  }
}

String marketplaceSubServiceId(MarketplaceVertical vertical) {
  switch (vertical) {
    case MarketplaceVertical.food:
      return 'marketplace-food';
    case MarketplaceVertical.pharmacy:
      return 'marketplace-pharmacy';
    case MarketplaceVertical.market:
      return 'marketplace-market';
    case MarketplaceVertical.errand:
      return 'marketplace-errand';
    case MarketplaceVertical.clinic:
      return 'marketplace-clinic';
    case MarketplaceVertical.beauty:
      return 'marketplace-beauty';
    case MarketplaceVertical.shop:
      return 'marketplace-shop';
    case MarketplaceVertical.hotel:
      return 'hotels';
    case MarketplaceVertical.flight:
      return 'flights';
    case MarketplaceVertical.train:
      return 'trains';
    case MarketplaceVertical.attraction:
      return 'attractions';
    case MarketplaceVertical.tour:
      return 'tours';
    case MarketplaceVertical.transfer:
      return 'airport-transfer';
    case MarketplaceVertical.carRental:
      return 'car-rental';
  }
}

Future<ObicService?> _resolveService(String parentSlug) async {
  try {
    final catalog = await ServicesApi().fetchCatalog();
    for (final s in catalog) {
      if (s.slug == parentSlug) return s;
    }
  } catch (_) {}
  final local = localCatalogSeed();
  for (final s in local) {
    if (s.slug == parentSlug) return s;
  }
  return null;
}

/// Book / request CTA — creates an order on OUR API when the catalog UUID exists.
Future<void> submitMarketplaceRequest(
  BuildContext context, {
  required AuthController auth,
  required String langCode,
  required MarketplaceVertical vertical,
  required String title,
  String? notes,
  Map<String, String>? formData,
  String? city,
}) async {
  final ok = await requireAuth(context, auth);
  if (!context.mounted || !ok) return;

  final parentSlug = marketplaceParentSlug(vertical);
  final subId = marketplaceSubServiceId(vertical);

  var spinnerOpen = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  void dismissSpinner() {
    if (!spinnerOpen || !context.mounted) return;
    spinnerOpen = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  try {
    final token = await auth.accessToken();
    if (token == null) throw Exception('auth');

    final service = await _resolveService(parentSlug);
    if (service == null) throw Exception('no-service');

    final looksUuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(service.id);

    final summary = StringBuffer(title);
    if (notes != null && notes.trim().isNotEmpty) {
      summary.writeln();
      summary.write(notes.trim());
    }
    if (formData != null) {
      for (final e in formData.entries) {
        if (e.value.trim().isEmpty) continue;
        summary.writeln();
        summary.write('${e.key}: ${e.value}');
      }
    }

    dismissSpinner();
    if (!context.mounted) return;

    if (!looksUuid) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(
            mp(
              langCode,
              'تم تسجيل طلبك داخل أوبك. سيظهر في طلباتي عند اتصال الخادم بالكتالوج الكامل.',
              'Your request is recorded inside OBIC. It will appear under My orders once the live catalog is linked.',
              '已在 OBIC 内登记请求。目录就绪后会出现在「我的订单」。',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(mp(langCode, 'حسناً', 'OK', '好的')),
            ),
          ],
        ),
      );
      return;
    }

    final created = await ServicesApi().createOrder(
      accessToken: token,
      serviceId: service.id,
      preferredBranch: city,
      notes: summary.toString(),
      subServiceId: subId,
      subServiceNameEn: title,
      subServiceNameAr: title,
      formData: {
        'source': 'marketplace',
        'vertical': vertical.name,
        'title': title,
        if (city != null && city.isNotEmpty) 'city': city,
        ...?formData,
      },
    );

    if (!context.mounted) return;
    // Stay in marketplace UX — order receipt card, not secretary chat.
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MarketplaceOrderPage(
          authController: auth,
          order: created,
          langCode: langCode,
        ),
      ),
    );
  } catch (_) {
    dismissSpinner();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mp(
              langCode,
              'تعذر إرسال الطلب. حاول مرة أخرى.',
              'Could not send the request. Try again.',
              '提交失败，请重试。',
            ),
          ),
        ),
      );
    }
  }
}
