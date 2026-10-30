// Made by Dr Ali
// Client-side China verification gate helpers (region + profile + server flags).
// UI language (zh) is NOT a cohort signal — diaspora may use Chinese UI abroad.
// Gate routes stay inescapable; Settings shortcut is Language + Appearance only.

import 'package:flutter/material.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_models.dart';
import '../features/auth/verify_china_email_screen.dart';
import '../features/auth/verify_china_phone_screen.dart';
import '../features/me/dark_mode_settings_screen.dart';
import '../features/me/language_settings_screen.dart';
import '../l10n/locale_controller.dart';
import '../l10n/theme_mode_controller.dart';
import '../theme/obic_colors.dart';
import 'profile_locations.dart';
import 'region_controller.dart';

/// SuperAdmin must never be blocked by China email/phone verify gates.
bool _isVerificationExempt(ObicUser user) => user.role == 'SuperAdmin';

bool _inChinaCohort({
  required ObicUser user,
  RegionController? region,
}) {
  if (user.needsEmailVerification || user.needsPhoneVerification) return true;
  final regionCode = region?.countryCode?.toUpperCase();
  final profileCode = (user.country ?? '').trim().toUpperCase();
  return isChinaRegionCode(regionCode) ||
      isChinaRegionCode(profileCode) ||
      (user.phone != null && isChinaMobile(user.phone!));
}

/// China cohort must verify email (Resend OTP) before full use.
bool clientNeedsEmailVerification({
  required ObicUser? user,
  RegionController? region,
}) {
  if (user == null) return false;
  if (_isVerificationExempt(user)) return false;
  if (user.emailVerified) return false;
  if (user.needsEmailVerification) return true;
  return _inChinaCohort(user: user, region: region) && !user.emailVerified;
}

/// China cohort for forced mainland phone OTP (true signals only).
bool clientNeedsPhoneVerification({
  required ObicUser? user,
  RegionController? region,
}) {
  if (user == null) return false;
  if (_isVerificationExempt(user)) return false;

  final hasVerifiedCnMobile = user.phoneVerified &&
      user.phone != null &&
      isChinaMobile(user.phone!);
  if (hasVerifiedCnMobile) return false;

  if (user.needsPhoneVerification) return true;

  final regionCode = region?.countryCode?.toUpperCase();
  final profileCode = (user.country ?? '').trim().toUpperCase();
  final inChinaCohort = isChinaRegionCode(regionCode) ||
      isChinaRegionCode(profileCode) ||
      (user.phone != null && isChinaMobile(user.phone!));

  if (!inChinaCohort) return false;
  return !(user.phone != null &&
      isChinaMobile(user.phone!) &&
      user.phoneVerified);
}

/// Login, resume, and tab changes. Employees enter and can open chat first.
/// Booking, clock-in, save, and post still use [clientNeedsPhoneVerification].
/// SuperAdmin is already clear inside those checks. A customer email never skips.
bool clientRequiresEntryActivation({
  required ObicUser? user,
  RegionController? region,
}) {
  if (user == null) return false;
  if (user.role == 'Employee') return false;
  return clientNeedsEmailVerification(user: user, region: region) ||
      clientNeedsPhoneVerification(user: user, region: region);
}

void Function()? _settingsOpener({
  required BuildContext gateContext,
  LocaleController? localeController,
  ThemeModeController? themeModeController,
}) {
  if (localeController == null || themeModeController == null) return null;
  return () {
    Navigator.of(gateContext).push(
      MaterialPageRoute<void>(
        builder: (_) => _PhoneGateSettingsHub(
          localeController: localeController,
          themeModeController: themeModeController,
        ),
      ),
    );
  };
}

/// Opens blocking email verify. Returns true after success / cohort clear.
Future<bool> openChinaEmailGate({
  required BuildContext context,
  required AuthController auth,
  LocaleController? localeController,
  ThemeModeController? themeModeController,
  RegionController? region,
}) async {
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (gateContext) => VerifyChinaEmailScreen(
        auth: auth,
        allowSettingsShortcut:
            localeController != null && themeModeController != null,
        onOpenSettings: _settingsOpener(
          gateContext: gateContext,
          localeController: localeController,
          themeModeController: themeModeController,
        ),
        onVerified: () {
          // ignore: discarded_futures
          auth.refreshProfile();
        },
        stillRequired: () => clientNeedsEmailVerification(
          user: auth.user,
          region: region,
        ),
        recheckListenable: region == null
            ? auth
            : Listenable.merge([auth, region]),
      ),
    ),
  );
  return ok == true;
}

/// Opens the blocking phone verify screen (unchanged escape/Settings behavior).
Future<bool> openChinaPhoneGate({
  required BuildContext context,
  required AuthController auth,
  LocaleController? localeController,
  ThemeModeController? themeModeController,
  RegionController? region,
}) async {
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (gateContext) => VerifyChinaPhoneScreen(
        auth: auth,
        allowSettingsShortcut:
            localeController != null && themeModeController != null,
        onOpenSettings: _settingsOpener(
          gateContext: gateContext,
          localeController: localeController,
          themeModeController: themeModeController,
        ),
        onVerified: () {
          // ignore: discarded_futures
          auth.refreshProfile();
        },
        stillRequired: () => clientNeedsPhoneVerification(
          user: auth.user,
          region: region,
        ),
        recheckListenable: region == null
            ? auth
            : Listenable.merge([auth, region]),
      ),
    ),
  );
  return ok == true;
}

/// Email first (if needed), then phone — both inescapable for China cohort.
Future<void> openChinaVerificationGates({
  required BuildContext context,
  required AuthController auth,
  LocaleController? localeController,
  ThemeModeController? themeModeController,
  RegionController? region,
}) async {
  if (clientNeedsEmailVerification(user: auth.user, region: region)) {
    await openChinaEmailGate(
      context: context,
      auth: auth,
      localeController: localeController,
      themeModeController: themeModeController,
      region: region,
    );
  }
  if (!context.mounted) return;
  if (clientNeedsPhoneVerification(user: auth.user, region: region)) {
    await openChinaPhoneGate(
      context: context,
      auth: auth,
      localeController: localeController,
      themeModeController: themeModeController,
      region: region,
    );
  }
}

/// Language + appearance only — no chat / orders / Moments escape hatch.
class _PhoneGateSettingsHub extends StatelessWidget {
  const _PhoneGateSettingsHub({
    required this.localeController,
    required this.themeModeController,
  });

  final LocaleController localeController;
  final ThemeModeController themeModeController;

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode.startsWith('zh');
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(
          zh
              ? '语言与外观'
              : ar
                  ? 'اللغة والمظهر'
                  : 'Language + Appearance',
        ),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language, color: ObicColors.blue),
            title: Text(
              zh
                  ? '语言'
                  : ar
                      ? 'اللغة'
                      : 'Language',
              style: TextStyle(color: ObicColors.inkOf(context)),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: ObicColors.mutedOf(context),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LanguageSettingsScreen(
                    localeController: localeController,
                  ),
                ),
              );
            },
          ),
          Divider(height: 1, color: ObicColors.lineOf(context)),
          ListTile(
            leading:
                const Icon(Icons.dark_mode_outlined, color: ObicColors.blue),
            title: Text(
              zh
                  ? '外观'
                  : ar
                      ? 'المظهر'
                      : 'Appearance',
              style: TextStyle(color: ObicColors.inkOf(context)),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: ObicColors.mutedOf(context),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DarkModeSettingsScreen(
                    themeModeController: themeModeController,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
