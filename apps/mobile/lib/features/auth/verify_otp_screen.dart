// Made by Dr Ali
// OTP entry after register/login — WeChat-clean, localized.
// Phone masks always LTR. Trial phone verify = email OTP (honest copy, no SMS claim).

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/api_errors.dart';
import '../../theme/obic_colors.dart';
import 'auth_controller.dart';
import 'obic_otp_boxes.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({
    super.key,
    required this.auth,
    required this.verifySession,
    required this.channel,
    required this.destinationMasked,
    this.phoneMasked,
    this.debugCode,
    this.delivery,
    this.onSuccess,
  });

  final AuthController auth;
  final String verifySession;
  final String channel;
  final String destinationMasked;
  final String? phoneMasked;
  final String? debugCode;
  final String? delivery;
  final VoidCallback? onSuccess;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _code = TextEditingController();
  final _otpKey = GlobalKey<ObicOtpBoxesState>();
  late String _session;
  late String _channel;
  late String _destinationMasked;
  String? _phoneMasked;
  String? _debugCode;
  String? _delivery;
  bool _busy = false;
  bool _otpError = false;
  bool _finishing = false;
  String? _inlineError;
  int _cooldown = 0;

  @override
  void initState() {
    super.initState();
    _session = widget.verifySession;
    _channel = widget.channel;
    _destinationMasked = widget.destinationMasked;
    _phoneMasked = widget.phoneMasked;
    _debugCode = widget.debugCode;
    _delivery = widget.delivery;
    _startCooldown();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _cooldown = (_cooldown - 1).clamp(0, 60));
      return _cooldown > 0;
    });
  }

  bool get _isPhoneChannel => _channel == 'phone';

  bool get _realSms =>
      _delivery == 'sms' ||
      _delivery == 'aliyun' ||
      _delivery == 'tencent' ||
      _delivery == 'twilio';

  bool get _emailDelivery =>
      _delivery == 'email_backup' ||
      (!_isPhoneChannel && _delivery != 'log');

  String? _maskEmail(String? email) {
    final e = email?.trim();
    if (e == null || e.isEmpty) return null;
    final at = e.indexOf('@');
    if (at <= 0) return e;
    final head = e.substring(0, at.clamp(0, 2));
    return '$head***@${e.substring(at + 1)}';
  }

  String _hint(AppLocalizations l10n) {
    if (!_isPhoneChannel) return l10n.verifyOtpEmailHint;
    if (_realSms) return l10n.verifyOtpPhoneHint;
    // Trial / default phone path: code emailed — never claim SMS.
    return l10n.verifyOtpPhoneViaEmailHint;
  }

  Widget _ltrLine(String text, {required bool emphasize}) {
    final cleaned = text.replaceAll('\u200E', '');
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          cleaned,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            fontSize: emphasize ? 16 : 15,
            color: emphasize
                ? ObicColors.titleOf(context)
                : ObicColors.inkOf(context),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      _otpError = true;
      _inlineError = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Single exit: pop this route with true. Parent (gate / login) finishes.
  /// Calling [onSuccess] here used to double-pop past Home (black screen).
  void _finishSuccess() {
    if (!mounted || _finishing) return;
    _finishing = true;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop(true);
      return;
    }
    // No route to pop — still notify login/register if they passed a callback.
    widget.onSuccess?.call();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final code = _code.text.trim();
    if (code.length != 6) {
      _showError(l10n.verifyOtpInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _otpError = false;
      _inlineError = null;
    });
    try {
      final ok = await widget.auth.verifyOtp(
        verifySession: _session,
        code: code,
      );
      if (!mounted) return;
      if (ok) {
        _finishSuccess();
      } else {
        final msg = friendlyApiError(
          widget.auth.lastError ?? l10n.verifyOtpWrongCode,
          l10n: l10n,
          langCode: lang,
        );
        _otpKey.currentState?.clear();
        _showError(msg);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _busy = true;
      _otpError = false;
      _inlineError = null;
    });
    try {
      final next = await widget.auth.resendOtp(_session);
      if (!mounted) return;
      if (next != null) {
        _session = next.verifySession;
        _channel = next.channel;
        _destinationMasked = next.destinationMasked;
        _phoneMasked = next.phoneMasked;
        _debugCode = next.debugCode;
        _delivery = next.delivery;
        _otpKey.currentState?.clear();
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.verifyOtpResent)),
        );
        setState(() {});
      } else {
        _showError(
          friendlyApiError(
            widget.auth.lastError ?? l10n.errorGenericRetry,
            l10n: l10n,
            langCode: lang,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Hide on-screen trial code whenever email/SMS actually delivered the OTP.
    final showTrialCode =
        _debugCode != null && _delivery == 'log' && !_emailDelivery && !_realSms;

    final destClean = _destinationMasked.replaceAll('\u200E', '');
    final destLooksPhone =
        destClean.startsWith('+') || RegExp(r'^\d').hasMatch(destClean);

    // Phone being bound (trial email_backup may put the phone in destinationMasked).
    final phoneLine = _phoneMasked ??
        (_isPhoneChannel && (_realSms || (_emailDelivery && destLooksPhone))
            ? _destinationMasked
            : (_isPhoneChannel && _realSms ? _destinationMasked : null));

    // Where the code was actually delivered.
    String? emailOrDestLine;
    if (_emailDelivery) {
      if (!destLooksPhone && destClean.contains('@')) {
        emailOrDestLine = _destinationMasked;
      } else {
        emailOrDestLine = _maskEmail(widget.auth.user?.email);
      }
    } else if (!_isPhoneChannel) {
      emailOrDestLine = _destinationMasked;
    } else if (!_realSms) {
      emailOrDestLine = destLooksPhone ? null : _destinationMasked;
    }

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(title: Text(l10n.verifyOtpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          Text(
            _hint(l10n),
            style: TextStyle(
              fontSize: 15,
              color: ObicColors.inkOf(context),
              height: 1.4,
            ),
          ),
          if (phoneLine != null && phoneLine.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ltrLine(phoneLine, emphasize: true),
          ],
          if (emailOrDestLine != null &&
              emailOrDestLine.isNotEmpty &&
              emailOrDestLine != phoneLine) ...[
            const SizedBox(height: 6),
            _ltrLine(emailOrDestLine, emphasize: phoneLine == null),
          ],
          if (showTrialCode) ...[
            const SizedBox(height: 12),
            Text(
              l10n.verifyOtpTrialCode(_debugCode!),
              style: TextStyle(
                fontSize: 13,
                color: ObicColors.mutedOf(context),
              ),
            ),
          ],
          const SizedBox(height: 28),
          ObicOtpBoxes(
            key: _otpKey,
            controller: _code,
            enabled: !_busy,
            hasError: _otpError,
            onChanged: (_) {
              if (_otpError || _inlineError != null) {
                setState(() {
                  _otpError = false;
                  _inlineError = null;
                });
              }
            },
            onCompleted: (_) {
              if (!_busy) _submit();
            },
          ),
          if (_inlineError != null) ...[
            const SizedBox(height: 10),
            Text(
              _inlineError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ObicColors.badgeRed,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: ObicColors.navy,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.verifyOtpConfirm),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: (_busy || _cooldown > 0) ? null : _resend,
            child: Text(
              _cooldown > 0
                  ? l10n.verifyOtpResendIn(_cooldown)
                  : l10n.verifyOtpResend,
            ),
          ),
        ],
      ),
    );
  }
}
