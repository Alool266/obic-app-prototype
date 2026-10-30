// Made by Dr Ali
// Looping ringtone — incoming overlay + outgoing "ringing…" screen.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'call_ring_controller.dart';
import 'sound_prefs.dart';

/// Plays [assets/sounds/call_ringtone.wav] on loop until stop.
class CallRingtone {
  CallRingtone._();
  static final CallRingtone instance = CallRingtone._();

  final AudioPlayer _player = AudioPlayer();
  bool _wired = false;
  bool _playing = false;
  /// Bumps on every stop so a late play() cannot restart the ring.
  int _generation = 0;
  /// Extra holds from outgoing call UI (incoming uses CallRingController).
  int _outgoingHolds = 0;

  void attach() {
    if (_wired) return;
    _wired = true;
    CallRingController.instance.addListener(_sync);
    unawaited(_player.setReleaseMode(ReleaseMode.loop));
    unawaited(_player.setVolume(1.0));
    // Ambient, not playback: playback paints an "OBIC Audio" pill in the
    // Dynamic Island and holds the session so Agora cannot start.
    unawaited(
      _player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notificationRingtone,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
        ),
      ),
    );
    _sync();
  }

  void detach() {
    if (!_wired) return;
    _wired = false;
    CallRingController.instance.removeListener(_sync);
    _outgoingHolds = 0;
    unawaited(stop());
  }

  /// Outgoing call screen: ring until peer joins or hangup.
  void holdOutgoing() {
    _outgoingHolds++;
    _sync();
  }

  void releaseOutgoing() {
    if (_outgoingHolds > 0) _outgoingHolds--;
    _sync();
  }

  Future<void> stop() async {
    _generation++;
    _playing = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  void _sync() {
    final want = CallRingController.instance.hasIncoming || _outgoingHolds > 0;
    if (want && !_playing) {
      _playing = true;
      unawaited(_start());
    } else if (!want && _playing) {
      unawaited(stop());
    }
  }

  Future<void> _start() async {
    final generation = _generation;
    try {
      await _player.stop();
      if (generation != _generation || !_playing) return;
      final asset = await SoundPrefs.callAsset();
      if (generation != _generation || !_playing) return;
      await _player.play(AssetSource(asset));
      if (generation != _generation || !_playing) {
        await _player.stop();
      }
    } catch (e) {
      debugPrint('CallRingtone play failed: $e');
      if (generation == _generation) _playing = false;
    }
  }
}
