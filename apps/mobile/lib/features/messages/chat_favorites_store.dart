// Made by Dr Ali
// Local Favorites (WeChat-style) — chat items + Moments.
// Device-only for now; sync to API can come later.

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ChatFavorite {
  ChatFavorite({
    required this.id,
    required this.kind,
    this.body,
    this.name,
    this.pathOrUrl,
    this.momentId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  /// text | image | video | file | moment
  final String kind;
  final String? body;
  final String? name;
  final String? pathOrUrl;
  final String? momentId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'body': body,
        'name': name,
        'pathOrUrl': pathOrUrl,
        'momentId': momentId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatFavorite.fromJson(Map<String, dynamic> json) {
    return ChatFavorite(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? 'text',
      body: json['body'] as String?,
      name: json['name'] as String?,
      pathOrUrl: json['pathOrUrl'] as String?,
      momentId: json['momentId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get preview {
    if (kind == 'moment') {
      final author = (name ?? '').trim();
      final t = (body ?? '').trim();
      if (t.isEmpty) {
        return author.isEmpty ? 'Moment' : '$author · Moment';
      }
      final short = t.length > 40 ? '${t.substring(0, 40)}…' : t;
      return author.isEmpty ? short : '$author: $short';
    }
    if (kind == 'text') {
      final t = (body ?? '').trim();
      if (t.isEmpty) return 'Text';
      return t.length > 48 ? '${t.substring(0, 48)}…' : t;
    }
    final n = (name ?? '').trim();
    if (n.isNotEmpty) return n;
    final p = (pathOrUrl ?? '').trim();
    if (p.isNotEmpty) {
      final slash = p.lastIndexOf('/');
      return slash >= 0 && slash < p.length - 1 ? p.substring(slash + 1) : p;
    }
    return kind;
  }
}

class ChatFavoritesStore {
  ChatFavoritesStore._();
  static final ChatFavoritesStore instance = ChatFavoritesStore._();

  List<ChatFavorite>? _cache;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/obic_chat_favorites.json');
  }

  Future<List<ChatFavorite>> list() async {
    if (_cache != null) return List.of(_cache!);
    try {
      final f = await _file();
      if (!await f.exists()) {
        _cache = [];
        return [];
      }
      final raw = jsonDecode(await f.readAsString());
      if (raw is! List) {
        _cache = [];
        return [];
      }
      _cache = raw
          .whereType<Map>()
          .map((e) => ChatFavorite.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.of(_cache!);
    } catch (_) {
      _cache = [];
      return [];
    }
  }

  Future<void> _persist() async {
    final f = await _file();
    final data = (_cache ?? []).map((e) => e.toJson()).toList();
    await f.writeAsString(jsonEncode(data));
  }

  Future<ChatFavorite> add({
    required String kind,
    String? body,
    String? name,
    String? pathOrUrl,
    String? momentId,
  }) async {
    await list();
    // Only collapse re-favorites of the same Moment id — never hide distinct saves.
    if (kind == 'moment' && momentId != null && momentId.isNotEmpty) {
      final existing = (_cache ?? []).where(
        (e) => e.kind == 'moment' && e.momentId == momentId,
      );
      if (existing.isNotEmpty) return existing.first;
    }
    final item = ChatFavorite(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      kind: kind,
      body: body,
      name: name,
      pathOrUrl: pathOrUrl,
      momentId: momentId,
    );
    _cache = [item, ...?_cache];
    await _persist();
    return item;
  }

  Future<void> remove(String id) async {
    await list();
    _cache = (_cache ?? []).where((e) => e.id != id).toList();
    await _persist();
  }
}
