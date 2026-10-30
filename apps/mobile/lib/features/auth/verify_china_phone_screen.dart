// Made by Dr Ali
// Blocking China phone verify — locked +86; trial OTP emailed (not SMS).

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/api_errors.dart';
import '../../core/profile_locations.dart';
import '../../theme/obic_colors.dart';
import 'auth_controller.dart';
import 'china_phone_field.dart';
import 'verify_otp_screen.dart';

class VerifyChinaPhoneScreen extends StatefulWidget {
  const VerifyChinaPhoneScreen({
    super.key,
    required this.auth,
    this.allowSettingsShortcut = false,
    this.onVerified,
    this.onOpenSettings,
    this.stillRequired,
    this.recheckListenable,
  });

  final AuthController auth;

  /// Show language/appearance shortcut only — never dismisses this route.
  final bool allowSettingsShortcut;
  final VoidCallback? onVerified;
  final VoidCallback? onOpenSettings;

  /// When false (cohort cleared), route pops itself.
  final bool Function()? stillRequired;
  final Listenable? recheckListenable;

  @override
  State<VerifyChinaPhoneScreen> createState() => _VerifyChinaPhoneScreenState();
}

class _VerifyChinaPhoneScreenState extends State<VerifyChinaPhoneScreen> {
  final _localPhone = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;

  /// Prevents OTP success + auth recheck from double-popping past Home.
  bool _closing = false;

  bool get _needsEmail {
    final e = widget.auth.user?.email?.trim();
    return e == null || e.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    widget.recheckListenable?.addListener(_recheckCohort);
    final existing = widget.auth.user?.email?.trim();
    if (existing != null && existing.isNotEmpty) {
      _email.text = existing;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _recheckCohort());
  }

  @override
  void didUpdateWidget(covariant VerifyChinaPhoneScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recheckListenable != widget.recheckListenable) {
      oldWidget.recheckListenable?.removeListener(_recheckCohort);
      widget.recheckListenable?.addListener(_recheckCohort);
    }
  }

  @override
  void dispose() {
    widget.recheckListenable?.removeListener(_recheckCohort);
    _localPhone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _recheckCohort() {
    final check = widget.stillRequired;
    if (check == null || !mounted || _closing) return;
    if (check()) return;
    // OTP / Settings may be on top — never pop the top route from here.
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    _finishVerified();
  }

  void _finishVerified() {
    if (!mounted || _closing) return;
    _closing = true;
    widget.onVerified?.call();
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop(true);
    }
  }

  void _activateLater() {
    if (!mounted || _closing) return;
    _closing = true;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop(false);
    }
  }

  Future<void> _sendCode() async {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final full = chinaMobileFromLocalDigits(_localPhone.text);
    if (full == null) {
      _toast(
        _localPhone.text.trim().isEmpty
            ? l10n.authPhoneRequired
            : l10n.phoneChinaOnly,
      );
      return;
    }
    if (!isChinaMobile(full)) {
      _toast(l10n.phoneChinaOnly);
      return;
    }
    final email = _email.text.trim();
    if (_needsEmail && email.isEmpty) {
      _toast(l10n.authEmailRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      final pending = await widget.auth.startPhoneVerify(
        phone: full,
        email: _needsEmail ? email : null,
        locale: lang,
      );
      if (!mounted) return;
      if (pending == null) {
        _toast(
          friendlyApiError(
            widget.auth.lastError ?? l10n.errorGenericRetry,
            l10n: l10n,
            langCode: lang,
          ),
        );
        return;
      }
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(
            auth: widget.auth,
            verifySession: pending.verifySession,
            channel: pending.channel,
            destinationMasked: pending.destinationMasked,
            phoneMasked: pending.phoneMasked,
            debugCode: pending.debugCode,
            delivery: pending.delivery,
          ),
        ),
      );
      if (ok == true && mounted) {
        _finishVerified();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ObicColors.scaffoldOf(context),
        appBar: AppBar(
          title: Text(l10n.phoneVerifyTitle),
          automaticallyImplyLeading: false,
          backgroundColor: ObicColors.surfaceOf(context),
          foregroundColor: ObicColors.inkOf(context),
          surfaceTintColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            const Icon(
              Icons.phone_android_rounded,
              size: 48,
              color: ObicColors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.phoneVerifyHeadline,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ObicColors.titleOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.phoneVerifyBodyEmailOtp,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: ObicColors.mutedOf(context),
              ),
            ),
            const SizedBox(height: 24),
            ChinaPhoneField(
              controller: _localPhone,
              label: l10n.authPhone,
              enabled: !_busy,
            ),
            if (_needsEmail) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.authEmail,
                  hintText: l10n.phoneVerifyEmailForCodeHint,
                  filled: true,
                  fillColor: ObicColors.surfaceOf(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.phoneChinaOnly,
              style: TextStyle(
                fontSize: 12,
                color: ObicColors.mutedOf(context),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _sendCode,
              style: FilledButton.styleFrom(
                backgroundColor: ObicColors.blue,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.phoneVerifySendCode),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _activateLater,
              child: Text(l10n.phoneVerifyLater),
            ),
            if (widget.allowSettingsShortcut &&
                widget.onOpenSettings != null) ...[
              TextButton(
                onPressed: widget.onOpenSettings,
                child: Text(l10n.phoneVerifyOpenSettings),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
