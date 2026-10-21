// Made by Dr Ali
// Chat settings — local prefs that actually gate chat UX.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/obic_colors.dart';
import 'settings_widgets.dart';

const kChatEnterToSend = 'obic_chat_enter_to_send';
const kChatConfirmDelete = 'obic_chat_confirm_delete';

class ChatSettingsPrefs {
  static Future<bool> enterToSend() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(kChatEnterToSend) ?? false;
  }

  static Future<void> setEnterToSend(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kChatEnterToSend, v);
  }

  static Future<bool> confirmDelete() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(kChatConfirmDelete) ?? true;
  }

  static Future<void> setConfirmDelete(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kChatConfirmDelete, v);
  }
}

class ChatsSettingsScreen extends StatefulWidget {
  const ChatsSettingsScreen({super.key});

  @override
  State<ChatsSettingsScreen> createState() => _ChatsSettingsScreenState();
}

class _ChatsSettingsScreenState extends State<ChatsSettingsScreen> {
  bool _enterSend = false;
  bool _confirmDelete = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await ChatSettingsPrefs.enterToSend();
    final b = await ChatSettingsPrefs.confirmDelete();
    if (!mounted) return;
    setState(() {
      _enterSend = a;
      _confirmDelete = b;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(l10n.settingsChats),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : ListView(
              children: [
                const SizedBox(height: 8),
                SettingsGroup(
                  children: [
                    SettingsSwitchTile(
                      title: l10n.chatsEnterSend,
                      value: _enterSend,
                      onChanged: (v) async {
                        setState(() => _enterSend = v);
                        await ChatSettingsPrefs.setEnterToSend(v);
                      },
                    ),
                    SettingsSwitchTile(
                      title: l10n.chatsConfirmDelete,
                      value: _confirmDelete,
                      onChanged: (v) async {
                        setState(() => _confirmDelete = v);
                        await ChatSettingsPrefs.setConfirmDelete(v);
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
