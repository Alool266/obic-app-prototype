// Made by Dr Ali
// Lock-screen and notification controls. iOS implements the channel.

import 'package:flutter/services.dart';

import 'music_player.dart';

class MusicControls {
  MusicControls._();

  static const _channel = MethodChannel('obic/music');
  static var _bound = false;

  static void bind(MusicPlayerController player) {
    if (_bound) return;
    _bound = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'play':
          if (!player.playing) await player.toggle();
          break;
        case 'pause':
          if (player.playing) await player.toggle();
          break;
        case 'next':
          await player.next();
          break;
        case 'previous':
          await player.previous();
          break;
        default:
          break;
      }
    });
  }

  static Future<void> sync(MusicPlayerController player) async {
    final track = player.current;
    try {
      if (track == null) {
        await _channel.invokeMethod<void>('clear');
        return;
      }
      await _channel.invokeMethod<void>('nowPlaying', {
        'title': track.title,
        'artist': track.artist,
        'playing': player.playing,
        'durationMs': player.duration.inMilliseconds,
        'positionMs': player.position.inMilliseconds,
      });
    } catch (_) {}
  }
}
