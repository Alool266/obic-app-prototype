// Made by Dr Ali
// Phase 5 — local OBIC AI thread cache (per user) + server sync fallback.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AiHistoryTurn {
  const AiHistoryTurn({
    required this.role,
    required this.text,
    this.isError = false,
    this.createdAt,
    this.attachmentKind,
    this.attachmentName,
    this.attachmentMime,
    this.attachmentPath,
  });

  final String role;
  final String text;
  final bool isError;
  final DateTime? createdAt;
  final String? attachmentKind;
  final String? attachmentName;
  final String? attachmentMime;
  final String? attachmentPath;

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        if (isError) 'isError': true,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (attachmentKind != null) 'attachmentKind': attachmentKind,
        if (attachmentName != null) 'attachmentName': attachmentName,
        if (attachmentMime != null) 'attachmentMime': attachmentMime,
        if (attachmentPath != null) 'attachmentPath': attachmentPath,
      };

  factory AiHistoryTurn.fromJson(Map<String, dynamic> json) {
    return AiHistoryTurn(
      role: (json['role'] as String?) ?? 'assistant',
      text: (json['text'] as String?) ??
          (json['content'] as String?) ??
          '',
      isError: json['isError'] == true,
      createdAt: DateTime.tryParse(
        (json['createdAt'] as String?) ?? '',
      ),
      attachmentKind: json['attachmentKind'] as String?,
      attachmentName: json['attachmentName'] as String?,
      attachmentMime: json['attachmentMime'] as String?,
      attachmentPath: json['attachmentPath'] as String?,
    );
  }
}

class AiHistoryThread {
  AiHistoryThread({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.turns,
    this.fromServer = false,
  });

  final String id;
  String title;
  DateTime updatedAt;
  List<AiHistoryTurn> turns;
  bool fromServer;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'turns': turns.map((t) => t.toJson()).toList(),
        if (fromServer) 'fromServer': true,
      };

  factory AiHistoryThread.fromJson(Map<String, dynamic> json) {
    final rawTurns = json['turns'] ?? json['messages'];
    final turns = <AiHistoryTurn>[];
    if (rawTurns is List) {
      for (final item in rawTurns) {
        if (item is Map<String, dynamic>) {
          turns.add(AiHistoryTurn.fromJson(item));
        } else if (item is Map) {
          turns.add(AiHistoryTurn.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return AiHistoryThread(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
      turns: turns,
      fromServer: json['fromServer'] == true,
    );
  }

  /// UUID-shaped server ids (local cache uses t_<ms>).
  bool get looksLikeServerId {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuid.hasMatch(id);
  }
}

class AiHistoryStore {
  static const _maxThreads = 40;
  static const _maxTurnsPerThread = 80;

  String _key(String userId) => 'obic_ai_threads_v1_$userId';

  String _activeKey(String userId) => 'obic_ai_active_thread_v1_$userId';

  Future<List<AiHistoryThread>> loadThreads(String userId) async {
    if (userId.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final threads = <AiHistoryThread>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final t = AiHistoryThread.fromJson(item);
          if (t.id.isNotEmpty) threads.add(t);
        } else if (item is Map) {
          final t = AiHistoryThread.fromJson(Map<String, dynamic>.from(item));
          if (t.id.isNotEmpty) threads.add(t);
        }
      }
      threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return threads;
    } catch (_) {
      return [];
    }
  }

  Future<String?> loadActiveThreadId(String userId) async {
    if (userId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeKey(userId));
  }

  Future<void> saveActiveThreadId(String userId, String? threadId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (threadId == null || threadId.isEmpty) {
      await prefs.remove(_activeKey(userId));
    } else {
      await prefs.setString(_activeKey(userId), threadId);
    }
  }

  Future<void> upsertThread(String userId, AiHistoryThread thread) async {
    if (userId.isEmpty || thread.id.isEmpty) return;
    var clipped = List<AiHistoryTurn>.from(thread.turns);
    if (clipped.length > _maxTurnsPerThread) {
      clipped = clipped.sublist(clipped.length - _maxTurnsPerThread);
    }
    thread.turns = clipped;
    thread.updatedAt = DateTime.now();

    final threads = await loadThreads(userId);
    final idx = threads.indexWhere((t) => t.id == thread.id);
    if (idx >= 0) {
      threads[idx] = thread;
    } else {
      threads.insert(0, thread);
    }
    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final trimmed = threads.length > _maxThreads
        ? threads.sublist(0, _maxThreads)
        : threads;
    await _persist(userId, trimmed);
    await saveActiveThreadId(userId, thread.id);
  }

  /// Merge server thread summaries + hydrated messages into local cache.
  /// Server wins on same id when newer; local-only (non-UUID) threads kept.
  Future<List<AiHistoryThread>> mergeServerThreads({
    required String userId,
    required List<AiHistoryThread> serverThreads,
  }) async {
    final local = await loadThreads(userId);
    final byId = <String, AiHistoryThread>{};
    for (final t in local) {
      byId[t.id] = t;
    }
    for (final s in serverThreads) {
      if (s.id.isEmpty) continue;
      final prev = byId[s.id];
      if (prev == null ||
          s.updatedAt.isAfter(prev.updatedAt) ||
          (s.turns.isNotEmpty && prev.turns.isEmpty)) {
        byId[s.id] = s..fromServer = true;
      } else {
        prev.fromServer = true;
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final trimmed = merged.length > _maxThreads
        ? merged.sublist(0, _maxThreads)
        : merged;
    await _persist(userId, trimmed);
    return trimmed;
  }

  Future<void> deleteThread(String userId, String threadId) async {
    if (userId.isEmpty || threadId.isEmpty) return;
    final threads = await loadThreads(userId);
    threads.removeWhere((t) => t.id == threadId);
    await _persist(userId, threads);
    final active = await loadActiveThreadId(userId);
    if (active == threadId) {
      await saveActiveThreadId(
        userId,
        threads.isEmpty ? null : threads.first.id,
      );
    }
  }

  Future<void> replaceThreadId({
    required String userId,
    required String oldId,
    required AiHistoryThread newThread,
  }) async {
    if (userId.isEmpty) return;
    final threads = await loadThreads(userId);
    threads.removeWhere((t) => t.id == oldId || t.id == newThread.id);
    threads.insert(0, newThread);
    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _persist(
      userId,
      threads.length > _maxThreads
          ? threads.sublist(0, _maxThreads)
          : threads,
    );
    await saveActiveThreadId(userId, newThread.id);
  }

  Future<void> _persist(String userId, List<AiHistoryThread> threads) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(userId),
      jsonEncode(threads.map((t) => t.toJson()).toList()),
    );
  }

  static String titleFromTurns(List<AiHistoryTurn> turns) {
    for (final t in turns) {
      final label = t.text.trim().isNotEmpty
          ? t.text.trim()
          : (t.attachmentName ?? '').trim();
      if (t.role == 'user' && label.isNotEmpty) {
        final text = label.replaceAll(RegExp(r'\s+'), ' ');
        if (text.length <= 48) return text;
        return '${text.substring(0, 47)}…';
      }
    }
    return 'OBIC AI';
  }
}
