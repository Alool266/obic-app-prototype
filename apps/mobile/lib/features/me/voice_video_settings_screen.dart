// Made by Dr Ali
// Voice & video call prefs — local defaults used by CallScreen.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/obic_colors.dart';
import 'settings_widgets.dart';

const kCallSpeakerDefault = 'obic_call_speaker_default';
const kCallVideoPreview = 'obic_call_video_preview';

class CallSettingsPrefs {
  static Future<bool> speakerDefault() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(kCallSpeakerDefault) ?? false;
  }

  static Future<void> setSpeakerDefault(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kCallSpeakerDefault, v);
  }

  static Future<bool> videoPreview() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(kCallVideoPreview) ?? true;
  }

  static Future<void> setVideoPreview(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kCallVideoPreview, v);
  }
}

class VoiceVideoSettingsScreen extends StatefulWidget {
  const VoiceVideoSettingsScreen({super.key});

  @override
  State<VoiceVideoSettingsScreen> createState() =>
      _VoiceVideoSettingsScreenState();
}

class _VoiceVideoSettingsScreenState extends State<VoiceVideoSettingsScreen> {
  bool _speaker = false;
  bool _preview = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await CallSettingsPrefs.speakerDefault();
    final b = await CallSettingsPrefs.videoPreview();
    if (!mounted) return;
    setState(() {
      _speaker = a;
      _preview = b;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(l10n.settingsVoiceVideo),
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
                      title: l10n.voiceSpeakerDefault,
                      value: _speaker,
                      onChanged: (v) async {
                        setState(() => _speaker = v);
                        await CallSettingsPrefs.setSpeakerDefault(v);
                      },
                    ),
                    SettingsSwitchTile(
                      title: l10n.voiceVideoPreview,
                      value: _preview,
                      onChanged: (v) async {
                        setState(() => _preview = v);
                        await CallSettingsPrefs.setVideoPreview(v);
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
