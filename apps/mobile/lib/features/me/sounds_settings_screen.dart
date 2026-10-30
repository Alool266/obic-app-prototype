// Made by Dr Ali
// Settings → Sounds: call ringtone, message tone, notification tone.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../messages/app_sounds.dart';
import '../messages/sound_prefs.dart';
import 'settings_widgets.dart';

class SoundsSettingsScreen extends StatefulWidget {
  const SoundsSettingsScreen({super.key});

  @override
  State<SoundsSettingsScreen> createState() => _SoundsSettingsScreenState();
}

class _SoundsSettingsScreenState extends State<SoundsSettingsScreen> {
  String _call = 'classic';
  String _message = 'classic';
  String _notify = 'classic';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final call = await SoundPrefs.choice(SoundPrefs.callKey);
    final message = await SoundPrefs.choice(SoundPrefs.messageKey);
    final notify = await SoundPrefs.choice(SoundPrefs.notificationKey);
    if (!mounted) return;
    setState(() {
      _call = call;
      _message = message;
      _notify = notify;
      _ready = true;
    });
  }

  Future<void> _set(String key, String id, void Function(String) apply) async {
    await SoundPrefs.setChoice(key, id);
    if (!mounted) return;
    setState(() => apply(id));
    final kind = switch (key) {
      SoundPrefs.callKey => 'call',
      SoundPrefs.messageKey => 'message',
      _ => 'notify',
    };
    await AppSounds.instance.preview(SoundPrefs.asset(kind, id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(l10n.settingsSounds),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        surfaceTintColor: Colors.transparent,
      ),
      body: _ready
          ? ListView(
              children: [
                const SizedBox(height: 8),
                _group(
                  context,
                  title: l10n.soundCall,
                  selected: _call,
                  onPick: (id) => _set(SoundPrefs.callKey, id, (v) => _call = v),
                  l10n: l10n,
                ),
                _group(
                  context,
                  title: l10n.soundMessage,
                  selected: _message,
                  onPick: (id) =>
                      _set(SoundPrefs.messageKey, id, (v) => _message = v),
                  l10n: l10n,
                ),
                _group(
                  context,
                  title: l10n.soundNotification,
                  selected: _notify,
                  onPick: (id) =>
                      _set(SoundPrefs.notificationKey, id, (v) => _notify = v),
                  l10n: l10n,
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _group(
    BuildContext context, {
    required String title,
    required String selected,
    required ValueChanged<String> onPick,
    required AppLocalizations l10n,
  }) {
    String label(String id) => switch (id) {
          'soft' => l10n.soundSoft,
          'bright' => l10n.soundBright,
          _ => l10n.soundClassic,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionLabel(title),
        SettingsGroup(
          children: [
            for (final id in SoundPrefs.choices)
              ListTile(
                dense: true,
                title: Text(label(id)),
                trailing: selected == id
                    ? const Icon(Icons.check_rounded, color: ObicColors.blue)
                    : null,
                onTap: () => onPick(id),
              ),
          ],
        ),
      ],
    );
  }
}
