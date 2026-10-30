// Made by Dr Ali
// Short message and notification tones. Call ringtone stays on CallRingtone.

import 'package:audioplayers/audioplayers.dart';

import 'sound_prefs.dart';

class AppSounds {
  AppSounds._();
  static final AppSounds instance = AppSounds._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playMessage() => _play(SoundPrefs.messageAsset);

  Future<void> playNotification() => _play(SoundPrefs.notificationAsset);

  Future<void> preview(String assetPath) async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.play(AssetSource(assetPath));
    } catch (_) {}
  }

  Future<void> _play(Future<String> Function() assetOf) async {
    try {
      final path = await assetOf();
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.play(AssetSource(path));
    } catch (_) {}
  }
}
