// Made by Dr Ali
// Shared gate: HTTP polls idle when realtime WS is live.

import 'package:flutter/foundation.dart';

/// Flip [realtimeLive] from RealtimeClient when Socket.IO is connected.
/// Pollers (chat / thread list / badges) use a slower HTTP safety net while true.
class MessageSyncGate extends ChangeNotifier {
  MessageSyncGate._();
  static final MessageSyncGate instance = MessageSyncGate._();

  bool _realtimeLive = false;

  /// True while a message WebSocket is connected and trusted.
  bool get realtimeLive => _realtimeLive;

  set realtimeLive(bool value) {
    if (_realtimeLive == value) return;
    _realtimeLive = value;
    notifyListeners();
  }

  /// Prefer HTTP poll when WS is down (fallback / cold start).
  bool get preferHttpPoll => !_realtimeLive;
}
