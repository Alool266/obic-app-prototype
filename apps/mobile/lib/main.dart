// Made by Dr Ali
// OBIC mobile entry — Arabic default + RTL; guest may browse without login.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/about_alerts.dart';
import 'core/app_foreground.dart';
import 'core/device_alerts.dart';
import 'core/obic_bidi.dart';
import 'core/obic_nav.dart';
import 'features/home/home_shortcuts.dart';
import 'core/connectivity_service.dart';
import 'core/region_controller.dart';
import 'features/auth/auth_controller.dart';
import 'features/messages/call_ring_controller.dart';
import 'features/messages/call_ringtone.dart';
import 'features/messages/call_float.dart';
import 'features/messages/call_screen.dart';
import 'features/shell/main_shell.dart';
import 'l10n/locale_controller.dart';
import 'l10n/theme_mode_controller.dart';
import 'theme/obic_theme.dart';
import 'widgets/obic_logo.dart';
import 'widgets/offline_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cap decoded image RAM — Image.network / Moments were a jank+OOM risk.
  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 << 20; // 40 MB
  AppForeground.instance.attach();
  unawaited(ConnectivityService.instance.start());
  // Restore language before first frame so zh/en survive kill (not Arabic flash).
  final savedLocale = await LocaleController.loadSavedLocale();
  unawaited(LiquidGlassWidgets.initialize());
  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      child: ObicApp(initialLocale: savedLocale),
    ),
  );
}

class ObicApp extends StatefulWidget {
  const ObicApp({super.key, this.initialLocale});

  final Locale? initialLocale;

  @override
  State<ObicApp> createState() => _ObicAppState();
}

class _ObicAppState extends State<ObicApp> {
  late final LocaleController _localeController = LocaleController(
    initial: widget.initialLocale,
  );
  final ThemeModeController _themeModeController = ThemeModeController();
  final RegionController _regionController = RegionController();
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _localeController.addListener(_onChanged);
    _themeModeController.addListener(_onChanged);
    _regionController.addListener(_onChanged);
    _authController.addListener(_onChanged);
    CallRingController.instance.addListener(_onChanged);
    CallRingtone.instance.attach();
    _authController.bootstrap();
    ObicHomeShortcuts.install(
      langCode: _localeController.langCode,
      auth: _authController,
    );
    unawaited(_themeModeController.bootstrap());
    unawaited(_regionController.bootstrap());
    unawaited(AboutAlerts.start());
  }

  @override
  void dispose() {
    _localeController.removeListener(_onChanged);
    _themeModeController.removeListener(_onChanged);
    _regionController.removeListener(_onChanged);
    _authController.removeListener(_onChanged);
    CallRingController.instance.removeListener(_onChanged);
    CallRingtone.instance.detach();
    AppForeground.instance.detach();
    _localeController.dispose();
    _themeModeController.dispose();
    _regionController.dispose();
    _authController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    ObicHomeShortcuts.sync(_localeController.langCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: obicNavKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildObicTheme(langCode: _localeController.langCode),
      darkTheme: buildObicDarkTheme(langCode: _localeController.langCode),
      themeMode: _themeModeController.mode,
      locale: _localeController.locale,
      // Arabic first — product default; English is first-class.
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MainShell(
        localeController: _localeController,
        themeModeController: _themeModeController,
        regionController: _regionController,
        authController: _authController,
      ),
      // Force RTL for Arabic so layout mirrors the prototype UX.
      // Never render a null child — empty navigator + dark canvas = solid black.
      // Incoming call overlay is HERE (not in MainShell) so it covers ChatScreen
      // and every other pushed route on Honor/Oppo/Xiaomi/Pixel/Samsung alike.
      builder: (context, child) {
        final isRtl = obicIsRtlLanguage(_localeController.langCode);
        final content =
            child ??
            Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ObicLogo(size: 72, borderRadius: 18),
                    SizedBox(height: 20),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            );
        final ring = CallRingController.instance.payload;
        // Touch taps outside a field do not unfocus on Android/iOS by default.
        return ListenableBuilder(
          listenable: ConnectivityService.instance,
          builder: (context, _) {
            final offline = ConnectivityService.instance.isOffline;
            final media = MediaQuery.of(context);
            final statusTop = media.padding.top;
            final bannerHeight = offline ? 36.0 : 0.0;
            final shell = CallFloatLayer(
              child: _ObicUnfocusOnTap(
                child: Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      content,
                      if (offline)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: OfflineBanner(statusTop: statusTop),
                        ),
                      if (ring != null)
                        Positioned.fill(
                          child: IncomingCallOverlay(
                            fromName:
                                (ring['fromName'] as String?)?.trim().isNotEmpty ==
                                    true
                                ? ring['fromName'] as String
                                : 'OBIC',
                            fromAvatarUrl: ring['fromAvatarUrl'] as String?,
                            mode: (ring['mode'] as String?) == 'video'
                                ? ObicCallMode.video
                                : ObicCallMode.voice,
                            arabic: _localeController.isArabic,
                            isGroup:
                                ring['isGroup'] == true ||
                                ring['conversationKind'] == 'group',
                            groupTitle: ring['conversationTitle'] as String?,
                            onAccept: () {
                              final id = ring['callId']?.toString();
                              unawaited(CallRingtone.instance.stop());
                              unawaited(
                                DeviceAlerts.instance.dismissIncomingCall(id),
                              );
                              unawaited(CallRingController.instance.accept());
                            },
                            onDecline: () {
                              final id = ring['callId']?.toString();
                              unawaited(CallRingtone.instance.stop());
                              unawaited(
                                DeviceAlerts.instance.dismissIncomingCall(id),
                              );
                              unawaited(CallRingController.instance.decline());
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
            return MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(top: statusTop + bannerHeight),
              ),
              child: offline
                  ? AnnotatedRegion<SystemUiOverlayStyle>(
                      value: const SystemUiOverlayStyle(
                        statusBarColor: Color(0xFF1C2333),
                        statusBarIconBrightness: Brightness.light,
                        statusBarBrightness: Brightness.dark,
                      ),
                      child: shell,
                    )
                  : shell,
            );
          },
        );
      },
    );
  }
}

/// Dismiss the keyboard when the user taps outside the focused text field.
///
/// Android and iOS ignore [EditableTextTapOutsideIntent] for touch, so a tap
/// on the message list never hides the keyboard. Overriding that intent keeps
/// the tap on the field itself (fields share one tap-region group) and still
/// delivers the tap to buttons and list rows. A parent [GestureDetector] would
/// lose those taps in the gesture arena.
class _ObicUnfocusOnTap extends StatefulWidget {
  const _ObicUnfocusOnTap({required this.child});

  final Widget child;

  @override
  State<_ObicUnfocusOnTap> createState() => _ObicUnfocusOnTapState();
}

class _ObicUnfocusOnTapState extends State<_ObicUnfocusOnTap> {
  PointerDownEvent? _pointerDown;

  void _onTapOutside(EditableTextTapOutsideIntent intent) {
    _pointerDown = intent.pointerDownEvent;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        _unfocusTouchOutside(intent);
        break;
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        intent.focusNode.unfocus();
    }
  }

  void _unfocusTouchOutside(EditableTextTapOutsideIntent intent) {
    switch (intent.pointerDownEvent.kind) {
      case PointerDeviceKind.touch:
      case PointerDeviceKind.trackpad:
        if (kIsWeb &&
            intent.pointerDownEvent.kind == PointerDeviceKind.touch) {
          intent.focusNode.unfocus();
        }
        break;
      case PointerDeviceKind.mouse:
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
      case PointerDeviceKind.unknown:
        intent.focusNode.unfocus();
    }
  }

  void _onTapUpOutside(EditableTextTapUpOutsideIntent intent) {
    final down = _pointerDown;
    _pointerDown = null;
    if (down == null) return;
    final distance = (down.position - intent.pointerUpEvent.position).distance;
    // A stationary tap dismisses. A drag is left to the list's own
    // scroll-to-dismiss so flicking the message list still closes the keyboard.
    if (distance < kTouchSlop) {
      intent.focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
              onInvoke: _onTapOutside,
            ),
        EditableTextTapUpOutsideIntent:
            CallbackAction<EditableTextTapUpOutsideIntent>(
              onInvoke: _onTapUpOutside,
            ),
      },
      child: widget.child,
    );
  }
}
