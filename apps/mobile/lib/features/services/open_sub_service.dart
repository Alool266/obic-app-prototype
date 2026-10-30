// Made by Dr Ali
// Open the right destination for a sub-service — skip intermediate detail pages.

import 'package:flutter/material.dart';

import '../../core/china_phone_gate.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../exhibitions/exhibitions_hub_page.dart';
import '../logistics/logistics_hub_page.dart';
import '../registration/registration_company_types.dart';
import '../registration/registration_page.dart';
import '../vip/vip_page.dart';
import 'service_catalog.dart';
import 'service_request_page.dart';
import 'service_sub_catalog.dart';

/// Auth + China email/phone gates. Returns false if the user backed out.
Future<bool> ensureServiceRequestAuth(
  BuildContext context,
  AuthController auth,
) async {
  final ok = await requireAuth(context, auth);
  if (!context.mounted || !ok) return false;
  if (clientNeedsEmailVerification(user: auth.user) ||
      clientNeedsPhoneVerification(user: auth.user)) {
    await openChinaVerificationGates(context: context, auth: auth);
    if (!context.mounted) return false;
    if (clientNeedsEmailVerification(user: auth.user) ||
        clientNeedsPhoneVerification(user: auth.user)) {
      return false;
    }
  }
  return true;
}

/// Straight to form / VIP / exhibitions / registration — no «ما يشمله» screen.
Future<void> openSubServiceDirect({
  required BuildContext context,
  required AuthController authController,
  required String langCode,
  required ObicService service,
  required ObicSubService sub,
}) async {
  if (sub.id == 'china-exhibitions' || sub.id == 'exhibitions') {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ExhibitionsHubPage(
          authController: authController,
          langCode: langCode,
        ),
      ),
    );
    return;
  }

  if (service.slug == 'logistics' &&
      (sub.id == 'intl-shipping' ||
          sub.id == 'shipment-tracking' ||
          sub.id == 'customs')) {
    await openLogisticsTools(
      context: context,
      authController: authController,
      langCode: langCode,
      tool: sub.id == 'shipment-tracking'
          ? LogisticsTool.track
          : LogisticsTool.calculator,
    );
    return;
  }

  if (sub.id == 'company-registration' ||
      isCompanyRegistrationProductId(sub.id)) {
    if (!await ensureServiceRequestAuth(context, authController)) return;
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RegistrationPage(
          authController: authController,
          langCode: langCode,
          companyType:
              isCompanyPackageProductId(sub.id) ? sub.id : null,
        ),
      ),
    );
    return;
  }

  if (!await ensureServiceRequestAuth(context, authController)) return;
  if (!context.mounted) return;

  if (sub.id == 'vip-trip') {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => VipPage(
          authController: authController,
          langCode: langCode,
        ),
      ),
    );
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ServiceRequestPage(
        service: service,
        authController: authController,
        langCode: langCode,
        subService: sub,
      ),
    ),
  );
}
