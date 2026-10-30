// Made by Dr Ali
// Service detail — browse OK; Request/Book goes through requireAuth.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../../core/china_phone_gate.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../offers/offers_browse.dart';
import '../registration/registration_page.dart';
import '../vip/vip_page.dart';
import 'service_catalog.dart';
import 'service_request_page.dart';
import 'service_sub_catalog.dart';
import 'visa_country_prices.dart';

class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({
    super.key,
    required this.service,
    required this.authController,
    required this.langCode,
    this.subService,
  });

  final ObicService service;
  final AuthController authController;
  final String langCode;
  final ObicSubService? subService;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ServiceTheme.of(service.colorKey);
    final title = subService?.name(langCode) ?? service.name(langCode);
    final description = subService?.desc(langCode) ?? service.desc(langCode);
    final priceLabel = subService?.price(langCode) ?? service.price(langCode);

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
            decoration: BoxDecoration(
              gradient: theme.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.end.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.officialBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Icon(
                  serviceIconData(service.icon),
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (offerBrowseKind(
                parentSlug: service.slug,
                subId: subService?.id,
              ) !=
              null) ...[
            const SizedBox(height: 18),
            OffersSection(
              kind: offerBrowseKind(
                parentSlug: service.slug,
                subId: subService?.id,
              )!,
              arabic: langCode == 'ar',
              authController: authController,
              service: service,
              cuisineFilter: service.slug == 'food' ? subService?.id : null,
            ),
          ],
          const SizedBox(height: 18),
          Text(
            l10n.includedTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ObicColors.titleOf(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _IncludedRow(
            icon: Icons.person_outline_rounded,
            soft: theme.soft,
            ink: theme.ink,
            title: l10n.advisorTitle,
            body: l10n.advisorDesc,
          ),
          _IncludedRow(
            icon: Icons.checklist_rounded,
            soft: theme.soft,
            ink: theme.ink,
            title: l10n.checklistTitle,
            body: l10n.checklistDesc,
          ),
          _IncludedRow(
            icon: Icons.notifications_none_rounded,
            soft: theme.soft,
            ink: theme.ink,
            title: l10n.statusUpdatesTitle,
            body: l10n.statusUpdatesDesc,
          ),
          const SizedBox(height: 8),
          Text(
            priceLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ObicColors.titleOf(context),
            ),
          ),
          if (_isVisaSub(subService?.id, service.slug)) ...[
            const SizedBox(height: 10),
            Text(
              visaPriceHint(langCode),
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: ObicColors.mutedOf(context),
              ),
            ),
            const SizedBox(height: 12),
            _VisaPricePreview(langCode: langCode),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final ok = await requireAuth(context, authController);
                    if (!context.mounted || !ok) return;
                    if (clientNeedsEmailVerification(
                          user: authController.user,
                        ) ||
                        clientNeedsPhoneVerification(
                          user: authController.user,
                        )) {
                      await openChinaVerificationGates(
                        context: context,
                        auth: authController,
                      );
                      if (!context.mounted) return;
                      if (clientNeedsEmailVerification(
                            user: authController.user,
                          ) ||
                          clientNeedsPhoneVerification(
                            user: authController.user,
                          )) {
                        return;
                      }
                    }
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        // Company Registration has its own boss W1 flow
                        // (eligibility, checklist, OCR, tracking) — not the
                        // generic request form.
                        builder: (_) => subService?.id == 'company-registration'
                            ? RegistrationPage(
                                authController: authController,
                                langCode: langCode,
                              )
                            : subService?.id == 'vip-trip'
                            ? VipPage(
                                authController: authController,
                                langCode: langCode,
                              )
                            : ServiceRequestPage(
                                service: service,
                                authController: authController,
                                langCode: langCode,
                                subService: subService,
                              ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: ObicColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(l10n.requestSvc),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await requireAuth(
                      context,
                      authController,
                      message: l10n.authRequiredBody,
                    );
                    if (!context.mounted || !ok) return;
                    if (clientNeedsEmailVerification(
                          user: authController.user,
                        ) ||
                        clientNeedsPhoneVerification(
                          user: authController.user,
                        )) {
                      await openChinaVerificationGates(
                        context: context,
                        auth: authController,
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.chatComingSoon)),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ObicColors.titleOf(context),
                    side: BorderSide(color: ObicColors.lineOf(context)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(l10n.chatSupport),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool _isVisaSub(String? subId, String parentSlug) {
  if (subId == 'visa' || subId == 'visas') return true;
  return parentSlug == 'government' && subId == 'visas';
}

class _VisaPricePreview extends StatelessWidget {
  const _VisaPricePreview({required this.langCode});
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final ar = langCode.startsWith('ar');
    final sample = [...kObicVisaOnline.take(6), ...kObicVisaOffline.take(4)];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ObicColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ObicColors.lineOf(context).withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ar ? 'أمثلة أسعار معتمدة' : 'Sample approved prices',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ObicColors.titleOf(context),
            ),
          ),
          const SizedBox(height: 8),
          ...sample.map((v) {
            final name = ar ? v.countryAr : v.countryEn;
            final price = ar ? v.priceLabelAr : v.priceLabelEn;
            final tag = v.offline
                ? (ar ? 'أوفلاين' : 'offline')
                : (ar ? 'أونلاين' : 'online');
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$name · $tag',
                      style: TextStyle(
                        fontSize: 13,
                        color: ObicColors.inkOf(context),
                      ),
                    ),
                  ),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ObicColors.titleOf(context),
                    ),
                  ),
                ],
              ),
            );
          }),
          Text(
            ar
                ? 'القائمة الكاملة عند تقديم الطلب (دولة التأشيرة).'
                : 'Full country list when you submit a request.',
            style: TextStyle(fontSize: 12, color: ObicColors.mutedOf(context)),
          ),
        ],
      ),
    );
  }
}

class _IncludedRow extends StatelessWidget {
  const _IncludedRow({
    required this.icon,
    required this.soft,
    required this.ink,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color soft;
  final Color ink;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ObicColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ObicColors.lineOf(context).withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ObicColors.titleOf(context),
                  ),
                ),
                Text(
                  body,
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
