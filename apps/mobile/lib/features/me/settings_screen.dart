// Made by Dr Ali
// WeChat-inspired Settings — dense rows; Moments prefs server-backed.
// Guests get limited settings (language / appearance / about / contact).

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/legal_links.dart';
import '../../l10n/locale_controller.dart';
import '../../l10n/theme_mode_controller.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../auth/account_switcher_screen.dart';
import '../auth/require_auth.dart';
import '../mini_apps/mini_apps_settings_screen.dart';
import '../moments/moments_notify_prefs.dart';
import '../notifications/notifications_screen.dart';
import '../social/social_api.dart';
import 'account_security_screen.dart';
import 'chats_settings_screen.dart';
import 'friend_permissions_screen.dart';
import 'dark_mode_settings_screen.dart';
import 'language_settings_screen.dart';
import 'profile_settings_screen.dart';
import 'report_bug_screen.dart';
import 'support_chat.dart';
import 'settings_widgets.dart';
import 'sounds_settings_screen.dart';
import 'storage_settings_screen.dart';
import 'voice_video_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.authController,
    required this.localeController,
    required this.themeModeController,
    this.onBadgeRefresh,
  });

  final AuthController authController;
  final LocaleController localeController;
  final ThemeModeController themeModeController;
  final Future<void> Function()? onBadgeRefresh;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifyEnabled = true;
  bool _muteUpdates = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final token = await widget.authController.ensureAccessToken();
    if (token != null) {
      try {
        final snap = await MomentsNotifyPrefs.syncFromServer(
          accessToken: token,
          api: SocialApi(),
        );
        if (!mounted) return;
        setState(() {
          _notifyEnabled = snap.notifyEnabled;
          _muteUpdates = snap.muteUpdates;
          _loaded = true;
        });
        return;
      } catch (_) {}
    }
    final notify = await MomentsNotifyPrefs.notifyEnabled();
    final mute = await MomentsNotifyPrefs.muteUpdates();
    if (!mounted) return;
    setState(() {
      _notifyEnabled = notify;
      _muteUpdates = mute;
      _loaded = true;
    });
  }

  Future<void> _openProtected(Widget Function() builder) async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => builder()));
  }

  Future<void> _setNotify(bool v) async {
    setState(() {
      _notifyEnabled = v;
      if (v) _muteUpdates = false;
      if (!v) _muteUpdates = true;
    });
    final token = await widget.authController.ensureAccessToken();
    if (token != null) {
      try {
        await MomentsNotifyPrefs.pushGlobal(
          accessToken: token,
          notifyEnabled: v,
          muteUpdates: !v,
        );
      } catch (_) {
        await MomentsNotifyPrefs.setNotifyEnabled(v);
        await MomentsNotifyPrefs.setMuteUpdates(!v);
      }
    } else {
      await MomentsNotifyPrefs.setNotifyEnabled(v);
      await MomentsNotifyPrefs.setMuteUpdates(!v);
    }
    await widget.onBadgeRefresh?.call();
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final passwordCtrl = TextEditingController();
    final isSa = widget.authController.user?.role == 'SuperAdmin';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.deleteAccountBody),
            if (isSa) ...[
              const SizedBox(height: 8),
              Text(
                l10n.deleteAccountSuperAdminRule,
                style: TextStyle(
                  fontSize: 13,
                  color: ObicColors.mutedOf(ctx),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              autofocus: true,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              decoration: InputDecoration(
                labelText: l10n.deleteAccountPasswordRequired,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.chatHandoffCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.deleteAccountConfirm,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    final password = passwordCtrl.text;
    passwordCtrl.dispose();
    if (ok != true || !mounted) return;
    if (password.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountPasswordRequired)),
      );
      return;
    }
    final deleted = await widget.authController.deleteAccount(
      currentPassword: password,
    );
    if (!mounted) return;
    if (deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountDone)),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.authController.lastError ?? l10n.callErrorGeneric,
          ),
        ),
      );
    }
  }

  Future<void> _setMute(bool v) async {
    setState(() {
      _muteUpdates = v;
      _notifyEnabled = !v;
    });
    final token = await widget.authController.ensureAccessToken();
    if (token != null) {
      try {
        await MomentsNotifyPrefs.pushGlobal(
          accessToken: token,
          notifyEnabled: !v,
          muteUpdates: v,
        );
      } catch (_) {
        await MomentsNotifyPrefs.setMuteUpdates(v);
        await MomentsNotifyPrefs.setNotifyEnabled(!v);
      }
    } else {
      await MomentsNotifyPrefs.setMuteUpdates(v);
      await MomentsNotifyPrefs.setNotifyEnabled(!v);
    }
    await widget.onBadgeRefresh?.call();
  }

  Future<void> _openContact() async {
    if (widget.authController.isAuthenticated) {
      await openSupportChat(context, widget.authController);
      return;
    }
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.settingsContactSupport,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ObicColors.inkOf(ctx),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.authRequiredBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: ObicColors.mutedOf(ctx),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    openLoginScreen(context, widget.authController);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: ObicColors.blue,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(l10n.authLogin),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    openRegisterScreen(context, widget.authController);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ObicColors.blueDeep,
                    side: const BorderSide(color: ObicColors.blueDeep),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(l10n.authRegister),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.authController,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final signedIn = widget.authController.isAuthenticated;
        final canvas = ObicColors.canvasOf(context);
        final surface = ObicColors.surfaceOf(context);
        final ink = ObicColors.inkOf(context);

        return Scaffold(
          backgroundColor: canvas,
          appBar: AppBar(
            title: Text(l10n.settingsTitle),
            backgroundColor: surface,
            foregroundColor: ink,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: ListView(
            children: [
              const SizedBox(height: 6),
              if (!signedIn) ...[
                SettingsSectionLabel(l10n.settingsAccount),
                SettingsGroup(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.meGuestHint,
                            style: TextStyle(
                              fontSize: 13,
                              color: ObicColors.mutedOf(context),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => openLoginScreen(
                                    context,
                                    widget.authController,
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: ObicColors.blue,
                                    minimumSize: const Size(0, 42),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(l10n.authLogin),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => openRegisterScreen(
                                    context,
                                    widget.authController,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ObicColors.blue,
                                    side: const BorderSide(
                                      color: ObicColors.blue,
                                    ),
                                    minimumSize: const Size(0, 42),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(l10n.authRegister),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (signedIn) ...[
                SettingsSectionLabel(l10n.settingsAccount),
                SettingsGroup(
                  children: [
                    SettingsNavTile(
                      title: l10n.settingsProfile,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProfileSettingsScreen(
                            authController: widget.authController,
                          ),
                        ),
                      ),
                    ),
                    SettingsNavTile(
                      title: l10n.settingsAccountSecurity,
                      onTap: () => _openProtected(
                        () => AccountSecurityScreen(
                          authController: widget.authController,
                        ),
                      ),
                    ),
                    SettingsNavTile(
                      title: l10n.switchAccountTitle,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AccountSwitcherScreen(
                            auth: widget.authController,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SettingsSectionLabel(l10n.settingsGeneral),
              SettingsGroup(
                children: [
                  SettingsNavTile(
                    title: l10n.settingsLanguage,
                    subtitle: l10n.settingsInterface,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LanguageSettingsScreen(
                            localeController: widget.localeController,
                          ),
                        ),
                      );
                    },
                  ),
                  SettingsNavTile(
                    title: l10n.settingsDarkMode,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DarkModeSettingsScreen(
                            themeModeController: widget.themeModeController,
                          ),
                        ),
                      );
                    },
                  ),
                  if (signedIn) ...[
                    SettingsNavTile(
                      title: l10n.settingsNotifications,
                      onTap: () async {
                        await _openProtected(
                          () => NotificationsScreen(
                            authController: widget.authController,
                            onUnreadChanged: widget.onBadgeRefresh,
                          ),
                        );
                        await widget.onBadgeRefresh?.call();
                      },
                    ),
                    if (_loaded) ...[
                      SettingsSwitchTile(
                        title: l10n.settingsMomentsNotifications,
                        subtitle: l10n.settingsMomentsNotifyFriends,
                        value: _notifyEnabled && !_muteUpdates,
                        onChanged: _setNotify,
                      ),
                      SettingsSwitchTile(
                        title: l10n.settingsMomentsMute,
                        value: _muteUpdates,
                        onChanged: _setMute,
                      ),
                    ],
                    SettingsNavTile(
                      title: l10n.settingsFriendsPermissions,
                      onTap: () => _openProtected(
                        () => FriendPermissionsScreen(
                          authController: widget.authController,
                          onChanged: widget.onBadgeRefresh,
                        ),
                      ),
                    ),
                    SettingsNavTile(
                      title: l10n.settingsStorage,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const StorageSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
              SettingsSectionLabel(l10n.settingsSupportSafety),
              SettingsGroup(
                children: [
                  SettingsNavTile(
                    title: l10n.settingsContactSupport,
                    onTap: _openContact,
                  ),
                  if (signedIn) ...[
                    SettingsNavTile(
                      title: l10n.settingsReportBug,
                      onTap: () => _openProtected(
                        () => ReportBugScreen(
                          authController: widget.authController,
                        ),
                      ),
                    ),
                    SettingsNavTile(
                      title: l10n.settingsRestoreAccount,
                      subtitle: l10n.restoreAccountHint,
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.settingsRestoreAccount),
                            content: Text(l10n.restoreAccountDialog),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(l10n.chatHandoffCancel),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  openSupportChat(
                                    context,
                                    widget.authController,
                                  );
                                },
                                child: Text(l10n.settingsContactSupport),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SettingsNavTile(
                      title: l10n.deleteAccountTitle,
                      onTap: _confirmDeleteAccount,
                    ),
                  ],
                ],
              ),
              if (signedIn) ...[
                SettingsSectionLabel(l10n.settingsFeatures),
                SettingsGroup(
                  children: [
                    SettingsNavTile(
                      title: l10n.settingsMiniApps,
                      subtitle: l10n.settingsMiniAppsHint,
                      onTap: () {
                        _openProtected(
                          () => const MiniAppsSettingsScreen(),
                        );
                      },
                    ),
                    SettingsNavTile(
                      title: l10n.settingsSounds,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SoundsSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    SettingsNavTile(
                      title: l10n.settingsChats,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ChatsSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    SettingsNavTile(
                      title: l10n.settingsVoiceVideo,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const VoiceVideoSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
              SettingsSectionLabel(l10n.appTitle),
              SettingsGroup(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aboutObicBlurb,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: ObicColors.mutedOf(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.aboutCredit,
                          style: TextStyle(
                            fontSize: 12,
                            color: ObicColors.mutedOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SettingsNavTile(
                    title: l10n.legalTerms,
                    onTap: () => ObicLegal.open(ObicLegal.terms),
                  ),
                  SettingsNavTile(
                    title: l10n.legalPrivacy,
                    onTap: () => ObicLegal.open(ObicLegal.privacy),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
