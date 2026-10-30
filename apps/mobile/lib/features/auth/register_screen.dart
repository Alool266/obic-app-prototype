// Made by Dr Ali
// Register page — distinct route from Login (WeChat-style).

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_errors.dart';
import '../../core/legal_links.dart';
import '../../core/profile_locations.dart';
import '../../core/region_controller.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/script_text_field.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';
import 'china_phone_field.dart';
import 'sms_phone_field.dart';
import 'social_sign_in.dart';
import 'verify_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.auth,
    required this.onGoLogin,
    this.onSuccess,
    this.scrollController,
  });

  final AuthController auth;
  final VoidCallback onGoLogin;
  final VoidCallback? onSuccess;
  final ScrollController? scrollController;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  late final TabController _channelTabs;
  late final AnimationController _entrance;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  late final AnimationController _ctaPulse;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _smsDial = smsDialChina;
  final _passwordCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _handledSuccess = false;
  bool _ctaPressed = false;

  bool _forceChinaPhone = false;

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

    for (final n in [_nameFocus, _emailFocus, _phoneFocus, _passwordFocus]) {
      n.addListener(_onFocusChange);
    }

    widget.auth.addListener(_onAuth);
    _entrance.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final china = await _isChinaRegisterContext();
      if (!mounted) return;
      if (china) {
        setState(() {
          _forceChinaPhone = true;
          _channelTabs.index = 1;
        });
      }
    });
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    for (final n in [_nameFocus, _emailFocus, _phoneFocus, _passwordFocus]) {
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
      _handledSuccess = true;
      widget.onSuccess?.call();
    });
  }

  bool get _usePhone => _channelTabs.index == 1;

  Future<String?> _regionCountry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kRegionCountryKey);
  }

  Future<bool> _isChinaRegisterContext() async {
    // Region / GPS only — Chinese UI language must not force China phone.
    final region = await _regionCountry();
    return isChinaRegionCode(region);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    final password = _passwordCtrl.text;
    if (password.length < 8) {
      _showSnack(l10n.authPasswordHint);
      return;
    }

    final chinaCtx = await _isChinaRegisterContext();
    if (!mounted) return;
    final usePhone = chinaCtx || _usePhone;
    // China register: phone + email (OTP emailed to confirm phone binding).
    final email = usePhone && !chinaCtx ? null : _emailCtrl.text.trim();
    final phone = usePhone
        ? (chinaCtx
              ? chinaMobileFromLocalDigits(_phoneCtrl.text)
              : smsMobileFromLocalDigits(_smsDial, _phoneCtrl.text))
        : null;
    if ((!usePhone || chinaCtx) && (email == null || email.isEmpty)) {
      _showSnack(l10n.authEmailRequired);
      return;
    }
    if (usePhone && (phone == null || phone.isEmpty)) {
      _showSnack(
        chinaCtx ? l10n.authChinaPhoneRequired : l10n.smsPhoneCountries,
      );
      return;
    }

    final region = await _regionCountry();
    final ok = await widget.auth.register(
      email: email,
      phone: phone,
      password: password,
      name: _nameCtrl.text.trim(),
      locale: Localizations.localeOf(context).languageCode,
      regionCountry: region,
    );

    if (!mounted) return;
    if (ok) {
      // Immediate navigation — don't rely solely on auth listener timing.
      if (!_handledSuccess && widget.onSuccess != null) {
        _handledSuccess = true;
        widget.onSuccess!();
      }
      return;
    }
    final pending = widget.auth.pendingVerify;
    if (pending != null) {
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
      if ((verified == true || widget.auth.isAuthenticated) &&
          !_handledSuccess &&
          widget.onSuccess != null) {
        _handledSuccess = true;
        widget.onSuccess!();
      }
      return;
    }
    final err = widget.auth.lastError;
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

  Future<void> _social(SocialProvider provider) async {
    if (widget.auth.busy) return;
    final l10n = AppLocalizations.of(context);
    try {
      final ok = await startSocialSignIn(auth: widget.auth, provider: provider);
      if (!mounted) return;
      if (ok) {
        if (!_handledSuccess && widget.onSuccess != null) {
          _handledSuccess = true;
          widget.onSuccess!();
        }
        return;
      }
      final err = widget.auth.lastError;
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
    } on SocialAuthException catch (error) {
      if (!mounted) return;
      switch (error.failure) {
        case SocialAuthFailure.cancelled:
          return;
        case SocialAuthFailure.notConfigured:
          _showSnack(l10n.authSocialNotConfigured);
        case SocialAuthFailure.failed:
          _showSnack(l10n.authInvalidSocialToken);
      }
    }
  }

  void _setChannel(int index) {
    _channelTabs.animateTo(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = widget.auth.busy;
    final embedded = widget.scrollController != null;
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
                l10n.authJoinHeadline,
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
                l10n.authRegisterSupport,
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
                    if (_forceChinaPhone)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.authChinaPhoneRequired,
                          style: TextStyle(
                            fontSize: 12,
                            color: ObicColors.mutedOf(context),
                          ),
                        ),
                      )
                    else
                      AuthChannelToggle(
                        left: l10n.authEmailTab,
                        right: l10n.authPhoneTab,
                        index: _channelTabs.index,
                        onChanged: _setChannel,
                      ),
                    const SizedBox(height: 8),
                    ObicScriptTextField(
                      controller: _nameCtrl,
                      focusNode: _nameFocus,
                      textInputAction: TextInputAction.next,
                      decoration: authUnderlineDecoration(
                        context: context,
                        label: l10n.authName,
                        focused: _nameFocus.hasFocus,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_forceChinaPhone) ...[
                      TextField(
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
                          hint: l10n.phoneVerifyEmailForCodeHint,
                          focused: _emailFocus.hasFocus,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ChinaPhoneField(
                        key: const ValueKey('phone'),
                        controller: _phoneCtrl,
                        focusNode: _phoneFocus,
                        label: l10n.authPhone,
                        underline: true,
                        focused: _phoneFocus.hasFocus,
                        textInputAction: TextInputAction.next,
                      ),
                    ] else
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
                          onPressed: () => setState(() => _obscure = !_obscure),
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
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.legalAgreePrefix,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ObicColors.mutedOf(context)),
                        ),
                        TextButton(
                          onPressed: () => ObicLegal.open(ObicLegal.terms),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(l10n.legalTerms),
                        ),
                        Text(
                          l10n.legalAnd,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ObicColors.mutedOf(context)),
                        ),
                        TextButton(
                          onPressed: () => ObicLegal.open(ObicLegal.privacy),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(l10n.legalPrivacy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AuthPrimaryCta(
                      pressed: _ctaPressed,
                      scale: _ctaPulse,
                      busy: busy,
                      label: l10n.authCreateAccount,
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
                ),
              ),
              const SizedBox(height: 20),
              AuthBottomSwitch(
                prompt: l10n.authHasAccount,
                actionLabel: l10n.authGoLogin,
                onAction: widget.onGoLogin,
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
