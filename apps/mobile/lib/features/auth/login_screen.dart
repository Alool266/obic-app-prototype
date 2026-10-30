// Made by Dr Ali
// Login page — distinct route from Register (WeChat-style).

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/api_errors.dart';
import '../../theme/obic_colors.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';
import 'sms_phone_field.dart';
import 'social_sign_in.dart';
import 'verify_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.auth,
    required this.onGoRegister,
    this.onSuccess,
    this.scrollController,
  });

  final AuthController auth;
  final VoidCallback onGoRegister;
  final VoidCallback? onSuccess;
  final ScrollController? scrollController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final TabController _channelTabs;
  late final AnimationController _entrance;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  late final AnimationController _ctaPulse;

  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _smsDial = smsDialChina;
  final _passwordCtrl = TextEditingController();
  final _totpCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _totpFocus = FocusNode();

  bool _obscure = true;
  bool _phoneCodeMode = false;
  bool _handledSuccess = false;
  bool _ctaPressed = false;

  @override
  void initState() {
    super.initState();
    _channelTabs = TabController(length: 2, vsync: this);
    _channelTabs.addListener(_onChannelTab);

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    );
    _fadeIn = CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));

    _ctaPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1,
      value: 1,
    );

    for (final n in [_emailFocus, _phoneFocus, _passwordFocus, _totpFocus]) {
      n.addListener(_onFocusChange);
    }

    widget.auth.addListener(_onAuth);
    _entrance.forward();
  }

  void _onChannelTab() {
    if (_channelTabs.indexIsChanging) return;
    setState(() {});
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    widget.auth.removeListener(_onAuth);
    _channelTabs.removeListener(_onChannelTab);
    _channelTabs.dispose();
    _entrance.dispose();
    _ctaPulse.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _totpCtrl.dispose();
    for (final n in [_emailFocus, _phoneFocus, _passwordFocus, _totpFocus]) {
      n.removeListener(_onFocusChange);
      n.dispose();
    }
    super.dispose();
  }

  void _onAuth() {
    if (!mounted) return;
    setState(() {});
    if (_handledSuccess ||
        !widget.auth.isAuthenticated ||
        widget.onSuccess == null) {
      return;
    }
    // OTP may be on top — only dismiss when this screen is current.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _handledSuccess) return;
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) return;
      _enterApp();
    });
  }

  /// Leave Login for the app shell. Pop this route, not whichever route
  /// happened to be pushed during the auth notification (that pop used to
  /// dismiss the other route and leave the user sitting on Login).
  void _enterApp() {
    if (!mounted || _handledSuccess) return;
    final route = ModalRoute.of(context);
    final navigator = Navigator.of(context);
    if (route != null && route.isActive && !route.isCurrent) {
      _handledSuccess = true;
      navigator.removeRoute(route);
      return;
    }
    _handledSuccess = true;
    final onSuccess = widget.onSuccess;
    if (onSuccess != null) {
      onSuccess();
      return;
    }
    if (navigator.canPop()) navigator.pop();
  }

  bool get _usePhone => _channelTabs.index == 1;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    if (widget.auth.needsTotp) {
      final code = _totpCtrl.text.trim();
      if (code.length != 6) {
        _showSnack(l10n.authTotpHint);
        return;
      }
      final ok = await widget.auth.verifyTotp(code);
      if (!mounted) return;
      if (ok) {
        _enterApp();
        return;
      }
      _showAuthFailure(widget.auth.lastError, l10n);
      return;
    }

    if (_usePhone && _phoneCodeMode) {
      await _submitPhoneCode();
      return;
    }

    final password = _passwordCtrl.text;
    if (password.length < 8) {
      _showSnack(l10n.authPasswordHint);
      return;
    }

    final email = _usePhone ? null : _emailCtrl.text.trim();
    final phone = _usePhone
        ? smsMobileFromLocalDigits(_smsDial, _phoneCtrl.text)
        : null;
    if (!_usePhone && (email == null || email.isEmpty)) {
      _showSnack(l10n.authEmailRequired);
      return;
    }
    if (_usePhone && (phone == null || phone.isEmpty)) {
      _showSnack(l10n.smsPhoneCountries);
      return;
    }

    final ok = await widget.auth.login(
      email: email,
      phone: phone,
      password: password,
    );

    if (!mounted) return;
    if (ok) {
      _enterApp();
      return;
    }
    if (widget.auth.needsTotp) {
      setState(() {});
      return;
    }
    await _openPendingVerify();
  }

  /// WeChat-style: phone number + SMS code. New numbers register in the
  /// same step; the OTP screen completes sign-in.
  Future<void> _submitPhoneCode() async {
    final l10n = AppLocalizations.of(context);
    final phone = smsMobileFromLocalDigits(_smsDial, _phoneCtrl.text);
    if (phone == null || phone.isEmpty) {
      _showSnack(l10n.smsPhoneCountries);
      return;
    }
    await widget.auth.startPhoneCodeLogin(
      phone: phone,
      locale: Localizations.localeOf(context).languageCode,
    );
    if (!mounted) return;
    await _openPendingVerify();
  }

  /// Shared tail: route to the OTP screen when a challenge is pending and
  /// enter the app when it completes; otherwise surface the failure.
  Future<void> _openPendingVerify() async {
    final pending = widget.auth.pendingVerify;
    if (pending == null) {
      _showAuthFailure(
        widget.auth.lastError,
        AppLocalizations.of(context),
      );
      return;
    }
    final verified = await Navigator.of(context).push<bool>(
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
    if (!mounted) return;
    if (verified == true || widget.auth.isAuthenticated) {
      _enterApp();
    }
  }

  void _showAuthFailure(String? err, AppLocalizations l10n) {
    if (err == null || err.isEmpty) {
      _showSnack(l10n.authFailed);
      return;
    }
    _showSnack(
      friendlyApiError(
        err,
        l10n: l10n,
        langCode: Localizations.localeOf(context).languageCode,
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _comingSoon() {
    _showSnack(AppLocalizations.of(context).authComingSoon);
  }

  Future<void> _social(SocialProvider provider) async {
    if (widget.auth.busy) return;
    final l10n = AppLocalizations.of(context);
    try {
      final ok = await startSocialSignIn(auth: widget.auth, provider: provider);
      if (!mounted) return;
      if (ok) {
        _enterApp();
        return;
      }
      _showAuthFailure(widget.auth.lastError, l10n);
    } on SocialAuthException catch (error) {
      if (!mounted) return;
      _showSocialFailure(error.failure, l10n);
    }
  }

  void _showSocialFailure(SocialAuthFailure failure, AppLocalizations l10n) {
    switch (failure) {
      case SocialAuthFailure.cancelled:
        return;
      case SocialAuthFailure.notConfigured:
        _showSnack(l10n.authSocialNotConfigured);
      case SocialAuthFailure.failed:
        _showSnack(l10n.authInvalidSocialToken);
    }
  }

  void _setChannel(int index) {
    if (widget.auth.needsTotp) return;
    _channelTabs.animateTo(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = widget.auth.busy;
    final embedded = widget.scrollController != null;
    final needsTotp = widget.auth.needsTotp;
    final headline = needsTotp ? l10n.authTotpVerify : l10n.authWelcomeBack;
    final support = needsTotp ? l10n.authTotpHint : l10n.authSignInSupport;
    final onNavy = !embedded;

    return DecoratedBox(
      decoration: authPageDecoration(embedded: embedded, context: context),
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: ListView(
            controller: widget.scrollController,
            padding: EdgeInsets.fromLTRB(
              28,
              embedded
                  ? 8
                  : MediaQuery.paddingOf(context).top + kToolbarHeight - 8,
              28,
              28,
            ),
            children: [
              AuthBrandMark(
                title: l10n.appTitle,
                compact: embedded,
                onNavy: onNavy,
              ),
              const SizedBox(height: 28),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: onNavy ? Colors.white : ObicColors.titleOf(context),
                  fontSize: embedded ? 22 : 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                support,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onNavy
                      ? Colors.white.withValues(alpha: 0.72)
                      : ObicColors.muted,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              AuthCardShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!needsTotp) ...[
                      AuthChannelToggle(
                        left: l10n.authEmailTab,
                        right: l10n.authPhoneTab,
                        index: _channelTabs.index,
                        onChanged: _setChannel,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (needsTotp) ...[
                      TextField(
                        controller: _totpCtrl,
                        focusNode: _totpFocus,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        autocorrect: false,
                        enableSuggestions: false,
                        maxLength: 6,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => busy ? null : _submit(),
                        decoration: authUnderlineDecoration(
                          context: context,
                          label: l10n.authTotpCode,
                          focused: _totpFocus.hasFocus,
                        ).copyWith(counterText: ''),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: busy
                              ? null
                              : () {
                                  widget.auth.cancelTotp();
                                  _totpCtrl.clear();
                                  setState(() {});
                                },
                          child: Text(l10n.authTotpBack),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AuthPrimaryCta(
                        pressed: _ctaPressed,
                        scale: _ctaPulse,
                        busy: busy,
                        label: l10n.authTotpVerify,
                        onTapDown: () {
                          setState(() => _ctaPressed = true);
                          _ctaPulse.reverse();
                        },
                        onTapCancel: () {
                          setState(() => _ctaPressed = false);
                          _ctaPulse.forward();
                        },
                        onTap: busy
                            ? null
                            : () async {
                                setState(() => _ctaPressed = false);
                                await _ctaPulse.forward();
                                await _submit();
                              },
                      ),
                      AuthConnectingHint(
                        active: busy,
                        message: l10n.authStillConnecting,
                      ),
                    ] else ...[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _usePhone
                            ? SmsPhoneField(
                                key: const ValueKey('phone'),
                                controller: _phoneCtrl,
                                focusNode: _phoneFocus,
                                label: l10n.authPhone,
                                dialCode: _smsDial,
                                onDialCode: (code) =>
                                    setState(() => _smsDial = code),
                                focused: _phoneFocus.hasFocus,
                                textInputAction: TextInputAction.next,
                              )
                            : TextField(
                                key: const ValueKey('email'),
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                                autocorrect: false,
                                enableSuggestions: false,
                                textInputAction: TextInputAction.next,
                                decoration: authUnderlineDecoration(
                                  context: context,
                                  label: l10n.authEmail,
                                  focused: _emailFocus.hasFocus,
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      if (_usePhone)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: busy
                                ? null
                                : () => setState(
                                      () => _phoneCodeMode = !_phoneCodeMode,
                                    ),
                            style: TextButton.styleFrom(
                              foregroundColor: ObicColors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _phoneCodeMode
                                  ? l10n.authUsePassword
                                  : l10n.authUseSmsCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      if (!_usePhone || !_phoneCodeMode) ...[
                      TextField(
                        controller: _passwordCtrl,
                        focusNode: _passwordFocus,
                        obscureText: _obscure,
                        keyboardType: TextInputType.visiblePassword,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => busy ? null : _submit(),
                        decoration: authUnderlineDecoration(
                          context: context,
                          label: l10n.authPassword,
                          focused: _passwordFocus.hasFocus,
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: ObicColors.mutedOf(context),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: _comingSoon,
                          style: TextButton.styleFrom(
                            foregroundColor: ObicColors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.authForgotPassword,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      ],
                      if (_usePhone && _phoneCodeMode)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 4),
                          child: Text(
                            l10n.authSmsCodeHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ObicColors.mutedOf(context),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      AuthPrimaryCta(
                        pressed: _ctaPressed,
                        scale: _ctaPulse,
                        busy: busy,
                        label: _usePhone && _phoneCodeMode
                            ? l10n.authSendCode
                            : l10n.authSignIn,
                        onTapDown: () {
                          setState(() => _ctaPressed = true);
                          _ctaPulse.reverse();
                        },
                        onTapCancel: () {
                          setState(() => _ctaPressed = false);
                          _ctaPulse.forward();
                        },
                        onTap: busy
                            ? null
                            : () async {
                                setState(() => _ctaPressed = false);
                                await _ctaPulse.forward();
                                await _submit();
                              },
                      ),
                      AuthConnectingHint(
                        active: busy,
                        message: l10n.authStillConnecting,
                      ),
                    ],
                  ],
                ),
              ),
              if (!needsTotp) ...[
                const SizedBox(height: 20),
                AuthBottomSwitch(
                  prompt: l10n.authNoAccount,
                  actionLabel: l10n.authGoRegister,
                  onAction: () {
                    if (widget.auth.needsTotp) return;
                    widget.onGoRegister();
                  },
                ),
                const SizedBox(height: 14),
                AuthOrDivider(label: l10n.authOrContinue),
                const SizedBox(height: 12),
                AuthSocialStub(
                  icon: Icons.g_mobiledata_rounded,
                  label: l10n.authContinueGoogle,
                  onTap: busy ? () {} : () => _social(SocialProvider.google),
                ),
                const SizedBox(height: 8),
                AuthSocialStub(
                  icon: Icons.apple,
                  label: l10n.authContinueApple,
                  onTap: busy ? () {} : () => _social(SocialProvider.apple),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                l10n.aboutCredit,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ObicColors.mutedOf(context).withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
