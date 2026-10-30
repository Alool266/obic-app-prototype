// Made by Dr Ali
// Legal free audio: ccMixter, Internet Archive, and the Free Music Archive
// collection on the Archive. Jamendo needs a client id we do not have.

import 'dart:convert';

import 'package:http/http.dart' as http;

part 'music_seed.dart';

class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.source,
    required this.license,
    this.genre = '',
    this.language = '',
  });

  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String source;
  final String license;
  final String genre;
  final String language;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'audioUrl': audioUrl,
    'source': source,
    'license': license,
    'genre': genre,
    'language': language,
  };

  static MusicTrack? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final audioUrl = json['audioUrl'];
    if (id is! String || title is! String || audioUrl is! String) return null;
    if (!audioUrl.startsWith('https://')) return null;
    return MusicTrack(
      id: id,
      title: title,
      artist: json['artist'] is String ? json['artist'] as String : '',
      audioUrl: audioUrl,
      source: json['source'] is String ? json['source'] as String : '',
      license: json['license'] is String ? json['license'] as String : '',
      genre: json['genre'] is String ? json['genre'] as String : '',
      language: json['language'] is String ? json['language'] as String : '',
    );
  }
}

class MusicQuery {
  const MusicQuery({
    this.text = '',
    this.language = 'all',
    this.genre = 'all',
  });

  final String text;
  final String language;
  final String genre;
}

class MusicLoad {
  const MusicLoad(this.tracks, {required this.failed});

  final List<MusicTrack> tracks;
  final bool failed;
}

/// Headers the file host requires. ccMixter returns 403 without its own referer.
Map<String, String> musicRequestHeaders(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  if (host == 'ccmixter.org' || host.endsWith('.ccmixter.org')) {
    return const {
      'Referer': 'https://ccmixter.org/',
      'User-Agent': 'OBIC',
    };
  }
  return const {'User-Agent': 'OBIC'};
}

class MusicLibrary {
  const MusicLibrary({this._client});

  final http.Client? _client;
  static List<MusicTrack> _liveCache = const [];

  List<MusicTrack> instant(MusicQuery query) {
    return _filter(<MusicTrack>[..._liveCache, ...kMusicSeed], query);
  }

  Future<MusicLoad> search(MusicQuery query) async {
    final local = instant(query);
    try {
      final live = await _live(query).timeout(
        const Duration(seconds: 16),
        onTimeout: () => const <MusicTrack>[],
      );
      if (live.isNotEmpty) {
        _liveCache = _merge(live, _liveCache).take(80).toList();
      }
      final merged = _merge(live, local);
      if (merged.isEmpty) return const MusicLoad(<MusicTrack>[], failed: true);
      return MusicLoad(merged, failed: false);
    } catch (_) {
      if (local.isNotEmpty) return MusicLoad(local, failed: false);
      return const MusicLoad(<MusicTrack>[], failed: true);
    }
  }

  List<MusicTrack> _filter(List<MusicTrack> tracks, MusicQuery query) {
    final text = query.text.trim().toLowerCase();
    final seen = <String>{};
    final out = <MusicTrack>[];
    for (final track in tracks) {
      if (!seen.add(track.id)) continue;
      if (query.language != 'all' && track.language != query.language) continue;
      if (query.genre != 'all' && track.genre != query.genre) continue;
      if (text.isNotEmpty) {
        final hay = '${track.title} ${track.artist} ${track.genre}'.toLowerCase();
        if (!hay.contains(text)) continue;
      }
      out.add(track);
    }
    return out;
  }

  List<MusicTrack> _merge(List<MusicTrack> first, List<MusicTrack> second) {
    final seen = <String>{};
    return [
      for (final track in [...first, ...second])
        if (seen.add(track.id) && track.audioUrl.startsWith('https://')) track,
    ];
  }

  Future<List<MusicTrack>> _live(MusicQuery query) async {
    final client = _client ?? http.Client();
    final close = _client == null;
    try {
      final out = <MusicTrack>[];
      try {
        out.addAll(
          await _ccmixter(client, query).timeout(
            const Duration(seconds: 8),
            onTimeout: () => const <MusicTrack>[],
          ),
        );
      } catch (_) {}
      if (out.length < 8) {
        try {
          out.addAll(
            await _archive(client, query, fma: false).timeout(
              const Duration(seconds: 8),
              onTimeout: () => const <MusicTrack>[],
            ),
          );
        } catch (_) {}
      }
      if (out.isEmpty) {
        try {
          out.addAll(
            await _archive(client, query, fma: true).timeout(
              const Duration(seconds: 8),
              onTimeout: () => const <MusicTrack>[],
            ),
          );
        } catch (_) {}
      }
      return out;
    } finally {
      if (close) client.close();
    }
  }

  String _words(MusicQuery query) {
    final parts = <String>[];
    final text = query.text.trim();
    if (text.isNotEmpty) parts.add(text);
    switch (query.language) {
      case 'ar':
        parts.add('arabic');
      case 'en':
        parts.add('english');
      case 'zh':
        parts.add('chinese');
      case 'fr':
        parts.add('french');
      default:
        break;
    }
    if (query.genre != 'all' && query.genre.isNotEmpty) parts.add(query.genre);
    return parts.join(' ');
  }

  Future<List<MusicTrack>> _archive(
    http.Client client,
    MusicQuery query, {
    required bool fma,
  }) async {
    final words = _words(query);
    final collection = fma ? ' AND collection:freemusicarchive' : '';
    final q = words.isEmpty
        ? 'mediatype:audio AND format:MP3 AND licenseurl:*creativecommons*$collection'
        : 'mediatype:audio AND format:MP3 AND licenseurl:*creativecommons*$collection AND ($words)';
    final uri = Uri.parse(
      'https://archive.org/advancedsearch.php?q=${Uri.encodeQueryComponent(q)}'
      '&fl[]=identifier&fl[]=title&fl[]=creator&rows=3&page=1&output=json',
    );
    final res = await client
        .get(uri, headers: musicRequestHeaders(uri.toString()))
        .timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    final response = body is Map ? body['response'] : null;
    final docs = response is Map ? response['docs'] : null;
    if (docs is! List) return const [];
    final out = <MusicTrack>[];
    for (final doc in docs.take(2)) {
      if (doc is! Map) continue;
      final id = doc['identifier'];
      if (id is! String || id.isEmpty) continue;
      final track = await _archiveFile(
        client,
        identifier: id,
        title: _string(doc['title']),
        artist: _string(doc['creator']),
        source: fma ? 'Free Music Archive' : 'Internet Archive',
        query: query,
      );
      if (track != null) out.add(track);
    }
    return out;
  }

  Future<MusicTrack?> _archiveFile(
    http.Client client, {
    required String identifier,
    required String title,
    required String artist,
    required String source,
    required MusicQuery query,
  }) async {
    final uri = Uri.parse('https://archive.org/metadata/$identifier');
    final res = await client
        .get(uri, headers: musicRequestHeaders(uri.toString()))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    final files = body is Map ? body['files'] : null;
    if (files is! List) return null;
    for (final file in files) {
      if (file is! Map) continue;
      final name = file['name'];
      if (name is! String || !name.toLowerCase().endsWith('.mp3')) continue;
      final url =
          'https://archive.org/download/${Uri.encodeComponent(identifier)}/${Uri.encodeComponent(name)}';
      return MusicTrack(
        id: 'ia:$identifier',
        title: title.isEmpty ? name : title,
        artist: artist.isEmpty ? source : artist,
        audioUrl: url,
        source: source,
        license: 'Creative Commons',
        genre: query.genre == 'all' ? '' : query.genre,
        language: query.language == 'all' ? '' : query.language,
      );
    }
    return null;
  }

  Future<List<MusicTrack>> _ccmixter(http.Client client, MusicQuery query) async {
    final words = _words(query);
    final uri = Uri.https('ccmixter.org', '/api/query', {
      'f': 'json',
      'limit': '18',
      'search_type': 'any',
      if (words.isNotEmpty) 'query': words,
    });
    final res = await client
        .get(uri, headers: musicRequestHeaders(uri.toString()))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    if (body is! List) return const [];
    final out = <MusicTrack>[];
    for (final item in body) {
      if (item is! Map) continue;
      final files = item['files'];
      if (files is! List) continue;
      String? url;
      for (final file in files) {
        if (file is! Map) continue;
        final download = file['download_url'];
        final name = file['file_name'];
        if (download is String &&
            download.startsWith('https://') &&
            name is String &&
            name.toLowerCase().endsWith('.mp3')) {
          url = download;
          break;
        }
      }
      if (url == null) continue;
      final uploadId = item['upload_id'];
      final title = _string(item['upload_name']);
      if (title.isEmpty) continue;
      out.add(
        MusicTrack(
          id: 'cc:${uploadId ?? title}',
          title: title,
          artist: _string(item['user_name']),
          audioUrl: url,
          source: 'ccMixter',
          license: _string(item['license_name']).isEmpty
              ? 'Creative Commons'
              : _string(item['license_name']),
          genre: query.genre == 'all' ? '' : query.genre,
          language: query.language == 'all' ? '' : query.language,
        ),
      );
    }
    return out;
  }

  String _string(Object? value) {
    if (value is String) return value.trim();
    if (value is List && value.isNotEmpty) return _string(value.first);
    return '';
  }
}

List<MusicTrack> musicFeatured(List<MusicTrack> tracks) {
  final buckets = <String, List<MusicTrack>>{};
  for (final track in tracks) {
    final key = track.language.isEmpty ? 'all' : track.language;
    buckets.putIfAbsent(key, () => []).add(track);
  }
  final out = <MusicTrack>[];
  final seen = <String>{};
  var index = 0;
  while (out.length < 12) {
    var added = false;
    for (final key in const ['ar', 'en', 'zh', 'fr', 'all']) {
      final list = buckets[key];
      if (list == null || index >= list.length) continue;
      final track = list[index];
      if (seen.add(track.id)) out.add(track);
      added = true;
    }
    if (!added) break;
    index++;
  }
  return out;
}
