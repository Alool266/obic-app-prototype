// Made by Dr Ali
// One player for OBIC Music, the mini bar, and the lock screen.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'music_controls.dart';
import 'music_downloads.dart';
import 'music_library.dart';

enum MusicRepeat { off, all, one }

class MusicPlaylist {
  const MusicPlaylist({
    required this.id,
    required this.name,
    required this.tracks,
  });

  final String id;
  final String name;
  final List<MusicTrack> tracks;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tracks': [for (final track in tracks) track.toJson()],
  };

  static MusicPlaylist? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String || name.trim().isEmpty) return null;
    final raw = json['tracks'];
    final tracks = <MusicTrack>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          final track = MusicTrack.fromJson(item);
          if (track != null) tracks.add(track);
        } else if (item is Map) {
          final track = MusicTrack.fromJson(Map<String, dynamic>.from(item));
          if (track != null) tracks.add(track);
        }
      }
    }
    return MusicPlaylist(id: id, name: name, tracks: tracks);
  }
}

class MusicPlayerController extends ChangeNotifier {
  MusicPlayerController._();

  static final instance = MusicPlayerController._();

  final AudioPlayer _player = AudioPlayer();
  var _ready = false;
  var _playing = false;
  var _shuffle = false;
  var _advancing = false;
  MusicRepeat _repeat = MusicRepeat.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<MusicTrack> _queue = const [];
  int _index = 0;
  final List<MusicTrack> _favorites = [];
  final List<MusicTrack> _recent = [];
  final List<MusicPlaylist> _playlists = [];
  final Random _random = Random();
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;
  String? _error;

  bool get playing => _playing;
  String? get error => _error;
  bool get shuffle => _shuffle;
  MusicRepeat get repeat => _repeat;
  Duration get position => _position;
  Duration get duration => _duration;
  MusicTrack? get current =>
      _queue.isEmpty || _index < 0 || _index >= _queue.length ? null : _queue[_index];
  List<MusicTrack> get favorites => List.unmodifiable(_favorites);
  List<MusicTrack> get recent => List.unmodifiable(_recent);
  List<MusicPlaylist> get playlists => List.unmodifiable(_playlists);

  Future<void> ensureReady() async {
    if (_ready) return;
    _ready = true;
    MusicControls.bind(this);
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {}
    _posSub = _player.positionStream.listen((value) {
      _position = value;
      notifyListeners();
    });
    _durSub = _player.durationStream.listen((value) {
      final next = value ?? Duration.zero;
      final wasZero = _duration == Duration.zero;
      _duration = next;
      notifyListeners();
      if (wasZero && next > Duration.zero) unawaited(_publish());
    });
    _stateSub = _player.playerStateStream.listen((state) {
      final was = _playing;
      _playing = state.playing;
      if (state.processingState == ProcessingState.completed) {
        unawaited(_onComplete());
        return;
      }
      if (was != _playing) {
        notifyListeners();
        unawaited(_publish());
      }
    });
    await _loadSaved();
  }

  Future<void> playQueue(List<MusicTrack> tracks, int index) async {
    if (tracks.isEmpty) return;
    await ensureReady();
    _queue = List.of(tracks);
    _index = index.clamp(0, tracks.length - 1);
    await _playCurrent();
  }

  Future<void> stop() async {
    await ensureReady();
    await _player.stop();
    _playing = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _queue = const [];
    _index = 0;
    _error = null;
    notifyListeners();
    await _publish();
  }

  Future<void> toggle() async {
    await ensureReady();
    if (current == null) return;
    if (_playing) {
      await _player.pause();
      _playing = false;
    } else {
      await _player.play();
      _playing = true;
    }
    notifyListeners();
    await _publish();
  }

  Future<void> seek(Duration to) async {
    await _player.seek(to);
    _position = to;
    notifyListeners();
    await _publish();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_shuffle && _queue.length > 1) {
      var jump = _index;
      while (jump == _index) {
        jump = _random.nextInt(_queue.length);
      }
      _index = jump;
    } else {
      _index = (_index + 1) % _queue.length;
    }
    await _playCurrent();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    _index = (_index - 1 + _queue.length) % _queue.length;
    await _playCurrent();
  }

  void setShuffle(bool value) {
    _shuffle = value;
    notifyListeners();
  }

  void cycleRepeat() {
    _repeat = switch (_repeat) {
      MusicRepeat.off => MusicRepeat.all,
      MusicRepeat.all => MusicRepeat.one,
      MusicRepeat.one => MusicRepeat.off,
    };
    notifyListeners();
  }

  bool isFavorite(MusicTrack track) => _favorites.any((item) => item.id == track.id);

  Future<void> toggleFavorite(MusicTrack track) async {
    if (isFavorite(track)) {
      _favorites.removeWhere((item) => item.id == track.id);
    } else {
      _favorites.insert(0, track);
    }
    notifyListeners();
    await _saveFavorites();
  }

  Future<MusicPlaylist> createPlaylist(String name) async {
    final playlist = MusicPlaylist(
      id: 'pl_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      tracks: const [],
    );
    _playlists.insert(0, playlist);
    notifyListeners();
    await _savePlaylists();
    return playlist;
  }

  Future<void> addToPlaylist(String playlistId, MusicTrack track) async {
    final index = _playlists.indexWhere((item) => item.id == playlistId);
    if (index < 0) return;
    final current = _playlists[index];
    if (current.tracks.any((item) => item.id == track.id)) return;
    _playlists[index] = MusicPlaylist(
      id: current.id,
      name: current.name,
      tracks: [track, ...current.tracks],
    );
    notifyListeners();
    await _savePlaylists();
  }

  Future<void> _playCurrent() async {
    final track = current;
    if (track == null) return;
    _position = Duration.zero;
    _duration = Duration.zero;
    _error = null;
    _playing = true;
    _remember(track);
    notifyListeners();
    try {
      final local = await MusicDownloads.instance.existing(track);
      if (local != null) {
        await _player.setFilePath(local.path);
      } else {
        await _player.setUrl(
          track.audioUrl,
          headers: musicRequestHeaders(track.audioUrl),
        );
      }
      await _player.play();
      _playing = true;
    } catch (_) {
      _playing = false;
      _error = 'playback';
      notifyListeners();
    }
    await _publish();
  }

  Future<void> _onComplete() async {
    if (_advancing) return;
    _advancing = true;
    try {
      if (_repeat == MusicRepeat.one) {
        await _playCurrent();
        return;
      }
      if (_repeat == MusicRepeat.off && _index >= _queue.length - 1 && !_shuffle) {
        _playing = false;
        _position = Duration.zero;
        notifyListeners();
        await _publish();
        return;
      }
      await next();
    } finally {
      _advancing = false;
    }
  }

  void _remember(MusicTrack track) {
    _recent.removeWhere((item) => item.id == track.id);
    _recent.insert(0, track);
    if (_recent.length > 20) _recent.removeRange(20, _recent.length);
    unawaited(_saveRecent());
  }

  Future<void> _publish() {
    return MusicControls.sync(this);
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites
      ..clear()
      ..addAll(_decodeTracks(prefs.getString('obic_music_favorites')));
    _recent
      ..clear()
      ..addAll(_decodeTracks(prefs.getString('obic_music_recent')));
    _playlists
      ..clear()
      ..addAll(_decodePlaylists(prefs.getString('obic_music_playlists')));
    notifyListeners();
  }

  List<MusicTrack> _decodeTracks(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final json = jsonDecode(raw);
      if (json is! List) return const [];
      return [
        for (final item in json)
          if (item is Map<String, dynamic>)
            MusicTrack.fromJson(item)
          else if (item is Map)
            MusicTrack.fromJson(Map<String, dynamic>.from(item)),
      ].whereType<MusicTrack>().toList();
    } catch (_) {
      return const [];
    }
  }

  List<MusicPlaylist> _decodePlaylists(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final json = jsonDecode(raw);
      if (json is! List) return const [];
      return [
        for (final item in json)
          if (item is Map<String, dynamic>)
            MusicPlaylist.fromJson(item)
          else if (item is Map)
            MusicPlaylist.fromJson(Map<String, dynamic>.from(item)),
      ].whereType<MusicPlaylist>().toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'obic_music_favorites',
      jsonEncode([for (final item in _favorites) item.toJson()]),
    );
  }

  Future<void> _saveRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'obic_music_recent',
      jsonEncode([for (final item in _recent) item.toJson()]),
    );
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'obic_music_playlists',
      jsonEncode([for (final item in _playlists) item.toJson()]),
    );
  }

  @override
  void dispose() {
    unawaited(_posSub?.cancel());
    unawaited(_durSub?.cancel());
    unawaited(_stateSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
