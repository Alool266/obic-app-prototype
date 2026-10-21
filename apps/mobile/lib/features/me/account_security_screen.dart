// Made by Dr Ali
// Account security — linked phone/email + change password via API.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import 'settings_widgets.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);
    final token = await widget.authController.ensureAccessToken();
    if (token == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await AuthApi().changePassword(
        accessToken: token,
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (!mounted) return;
      _current.clear();
      _next.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.securityPasswordChanged)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final u = widget.authController.user;

    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(l10n.settingsAccountSecurity),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          SettingsSectionLabel(l10n.securityLinkedAccounts),
          SettingsGroup(
            children: [
              SettingsReadonlyTile(
                title: l10n.profilePhone,
                value: u?.phone ?? '',
                identifierValue: true,
              ),
              SettingsReadonlyTile(
                title: l10n.profileEmail,
                value: u?.email ?? '',
                hint: l10n.profileEmailReadOnly,
                identifierValue: true,
              ),
            ],
          ),
          SettingsSectionLabel(l10n.securityChangePassword),
          SettingsGroup(
            children: [
              _PasswordField(
                label: l10n.securityCurrentPassword,
                controller: _current,
              ),
              _PasswordField(
                label: l10n.securityNewPassword,
                controller: _next,
              ),
              ListTile(
                dense: true,
                title: Text(
                  l10n.securityChangePassword,
                  style: const TextStyle(
                    color: ObicColors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                onTap: _busy ? null : _changePassword,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        label,
        style: TextStyle(fontSize: 13, color: ObicColors.mutedOf(context)),
      ),
      subtitle: TextField(
        controller: controller,
        obscureText: true,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        style: const TextStyle(fontSize: 15),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 8),
        ),
      ),
    );
  }
}
