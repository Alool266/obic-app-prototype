// Made by Dr Ali
// Call / message / notification tones the user picks in Settings.

import 'package:shared_preferences/shared_preferences.dart';

class SoundPrefs {
  static const callKey = 'obic_sound_call';
  static const messageKey = 'obic_sound_message';
  static const notificationKey = 'obic_sound_notification';
  static const choices = ['classic', 'soft', 'bright'];

  static Future<String> choice(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null && choices.contains(raw)) return raw;
    return 'classic';
  }

  static Future<void> setChoice(String key, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, choices.contains(id) ? id : 'classic');
  }

  /// AssetSource path (under assets/).
  static String asset(String kind, String id) => 'sounds/${kind}_$id.wav';

  static Future<String> callAsset() async =>
      asset('call', await choice(callKey));

  static Future<String> messageAsset() async =>
      asset('message', await choice(messageKey));

  static Future<String> notificationAsset() async =>
      asset('notify', await choice(notificationKey));
}
