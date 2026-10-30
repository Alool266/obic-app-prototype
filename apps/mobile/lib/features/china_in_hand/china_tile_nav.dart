// Made by Dr Ali
// Shared open paths for الصين بين يديك tiles (orders / forms stay intact).

import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../exhibitions/exhibitions_hub_page.dart';
import '../logistics/logistics_hub_page.dart';
import '../services/open_sub_service.dart';
import '../services/service_catalog.dart';
import '../services/service_sub_catalog.dart';
import '../services/services_api.dart';
import 'china_in_hand_catalog.dart';
import 'china_scholarships_page.dart';
import 'china_visit_near_page.dart';

Future<ObicService?> resolveChinaParent(String slug) async {
  for (final svc in localCatalogSeed()) {
    if (svc.slug == slug) return svc;
  }
  try {
    final catalog = await ServicesApi().fetchCatalog();
    for (final svc in catalog) {
      if (svc.slug == slug) return svc;
    }
  } catch (_) {}
  return null;
}

Future<void> openChinaHubTile({
  required BuildContext context,
  required AuthController authController,
  required String langCode,
  required ChinaHubTile tile,
}) async {
  switch (tile.action) {
    case ChinaTileAction.exhibitions:
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ExhibitionsHubPage(
            authController: authController,
            langCode: langCode,
          ),
        ),
      );
      return;
    case ChinaTileAction.logisticsTools:
      await openLogisticsTools(
        context: context,
        authController: authController,
        langCode: langCode,
        tool: switch (tile.id) {
          'obic-import-calc' => LogisticsTool.calculator,
          'obic-cbm-quote' => LogisticsTool.cbm,
          'obic-track-ship' => LogisticsTool.track,
          'obic-ship-quote' => LogisticsTool.quote,
          _ => null,
        },
      );
      return;
    case ChinaTileAction.scholarships:
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ChinaScholarshipsPage(
            authController: authController,
            langCode: langCode,
          ),
        ),
      );
      return;
    case ChinaTileAction.visitNearMe:
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ChinaVisitNearPage(
            authController: authController,
            langCode: langCode,
          ),
        ),
      );
      return;
    case ChinaTileAction.companyRegistration:
    case ChinaTileAction.subService:
      final service = await resolveChinaParent(tile.parentSlug);
      final sub = tile.resolveSub();
      if (!context.mounted || service == null || sub == null) return;
      await openSubServiceDirect(
        context: context,
        authController: authController,
        langCode: langCode,
        service: service,
        sub: sub,
      );
      return;
  }
}

Future<void> openChinaSubById({
  required BuildContext context,
  required AuthController authController,
  required String langCode,
  required String parentSlug,
  required String subId,
}) async {
  final service = await resolveChinaParent(parentSlug);
  if (!context.mounted || service == null) return;
  ObicSubService? sub;
  for (final s in subServicesForParent(parentSlug)) {
    if (s.id == subId) {
      sub = s;
      break;
    }
  }
  // Fallback: resolve from tile catalog if parent list miss.
  if (sub == null) {
    for (final section in kChinaInHandSections()) {
      for (final t in section.tiles) {
        if (t.id == subId || t.subServiceId == subId) {
          sub = t.resolveSub();
          break;
        }
      }
      if (sub != null) break;
    }
  }
  if (!context.mounted || sub == null) return;
  await openSubServiceDirect(
    context: context,
    authController: authController,
    langCode: langCode,
    service: service,
    sub: sub,
  );
}
