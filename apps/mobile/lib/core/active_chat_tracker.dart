// Made by Dr Ali
// Tracks the conversation currently open in ChatScreen (WeChat: no notif for it).

import 'package:flutter/foundation.dart';

/// Singleton — chat_screen sets on enter, clears on leave.
class ActiveChatTracker extends ChangeNotifier {
  ActiveChatTracker._();
  static final ActiveChatTracker instance = ActiveChatTracker._();

  String? _conversationId;
  final Set<String> _mutedThreadIds = {};

  String? get conversationId => _conversationId;

  bool isOpen(String? id) =>
      id != null && id.isNotEmpty && id == _conversationId;

  bool isMuted(String? id) =>
      id != null && id.isNotEmpty && _mutedThreadIds.contains(id);

  /// WeChat: open chat or muted thread — no list/tab badge bumps.
  bool suppressesUnreadBadge(String? id) => isOpen(id) || isMuted(id);

  /// Extract conversationId from an inbox / realtime notification payload.
  static String? conversationIdOf(Map<String, dynamic>? notification) {
    if (notification == null) return null;
    final raw = notification['data'];
    if (raw is! Map) return null;
    final id = raw['conversationId']?.toString().trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  /// WeChat: open conversation → skip banner + inbox for that thread.
  bool suppressesNotification(Map<String, dynamic>? notification) =>
      isOpen(conversationIdOf(notification));

  void setMuted(String conversationId, bool muted) {
    if (conversationId.isEmpty) return;
    if (muted) {
      if (!_mutedThreadIds.add(conversationId)) return;
    } else {
      if (!_mutedThreadIds.remove(conversationId)) return;
    }
    notifyListeners();
  }

  void syncMutedFromThreads(Iterable<Map<String, dynamic>> threads) {
    var changed = false;
    final seen = <String>{};
    for (final t in threads) {
      final id = t['id']?.toString();
      if (id == null || id.isEmpty) continue;
      seen.add(id);
      final muted = t['muted'] == true;
      if (muted) {
        if (_mutedThreadIds.add(id)) changed = true;
      } else if (_mutedThreadIds.remove(id)) {
        changed = true;
      }
    }
    _mutedThreadIds.removeWhere((id) => !seen.contains(id));
    if (changed) notifyListeners();
  }

  void enter(String conversationId) {
    if (_conversationId == conversationId) return;
    _conversationId = conversationId;
    notifyListeners();
  }

  void leave(String conversationId) {
    if (_conversationId != conversationId) return;
    _conversationId = null;
    notifyListeners();
  }

  void clear() {
    if (_conversationId == null) return;
    _conversationId = null;
    notifyListeners();
  }
}
