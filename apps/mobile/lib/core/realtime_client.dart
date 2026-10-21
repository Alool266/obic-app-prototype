// Made by Dr Ali
// Authenticated Socket.IO client — WeChat-feel push for chat + badges.
// Falls back to light HTTP polls when disconnected.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_config.dart';
import 'app_foreground.dart';
import 'active_chat_tracker.dart';
import 'connectivity_service.dart';
import 'message_sync_gate.dart';

/// Event names — keep in sync with services/api realtime.events.ts
const String kRtChatMessage = 'chat:message';
const String kRtBadgeHint = 'badge:hint';
const String kRtNotification = 'notification:new';
const String kRtReady = 'realtime:ready';
const String kRtCallIncoming = 'call:incoming';
const String kRtCallEnded = 'call:ended';
const String kRtChatViewing = 'chat:viewing';
const String kRtChatUnviewing = 'chat:unviewing';
const String kRtLiveLocation = 'live:location';

class RealtimeClient extends ChangeNotifier {
  RealtimeClient._();
  static final RealtimeClient instance = RealtimeClient._();

  io.Socket? _socket;
  String? _token;
  bool _wanted = false;
  bool _connected = false;
  bool _listenersAttached = false;
  Timer? _reconnectTimer;

  final _chatMessageCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  /// Open-chat UI listens to [onChatMessage]. The thread list listens here so
  /// a send on this phone can update the preview without echoing into the
  /// open transcript a second time.
  final _inboxCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _badgeHintCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callIncomingCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _liveCtrl = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onChatMessage => _chatMessageCtrl.stream;
  /// Socket messages plus [noteLocalChatMessage] (this phone's own sends).
  Stream<Map<String, dynamic>> get onInboxMessage => _inboxCtrl.stream;

  /// Update the chat list immediately when this phone sends, before the
  /// server echo. Does not notify the open transcript.
  void noteLocalChatMessage({
    required String conversationId,
    required Map<String, dynamic> message,
  }) {
    if (conversationId.isEmpty || _inboxCtrl.isClosed) return;
    _emitInbox({
      'conversationId': conversationId,
      'message': Map<String, dynamic>.from(message),
    });
  }
  Stream<Map<String, dynamic>> get onBadgeHint => _badgeHintCtrl.stream;
  Stream<Map<String, dynamic>> get onNotification => _notificationCtrl.stream;
  Stream<Map<String, dynamic>> get onCallIncoming => _callIncomingCtrl.stream;
  Stream<Map<String, dynamic>> get onCallEnded => _callEndedCtrl.stream;
  Stream<Map<String, dynamic>> get onLiveLocation => _liveCtrl.stream;

  bool get isConnected => _connected;

  /// Prefer WS when true; callers use slower poll as safety net.
  bool get preferRealtime =>
      _connected &&
      ConnectivityService.instance.isOnline &&
      AppForeground.instance.isActive;

  void start() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    AppForeground.instance.addListener(_onLifecycle);
    ConnectivityService.instance.addListener(_onLifecycle);
    ActiveChatTracker.instance.addListener(_syncViewingPresence);
  }

  void _syncGate() {
    MessageSyncGate.instance.realtimeLive = preferRealtime;
  }

  /// Tell API which chat is open so inbox rows are not written for it.
  void _syncViewingPresence() {
    final id = ActiveChatTracker.instance.conversationId;
    final s = _socket;
    if (s == null || !_connected) return;
    if (id != null && id.isNotEmpty) {
      s.emit(kRtChatViewing, {'conversationId': id});
    } else {
      s.emit(kRtChatUnviewing, <String, dynamic>{});
    }
  }

  /// Call when user signs in (or token refreshed).
  Future<void> bindAuth(String? accessToken) async {
    start();
    _token = accessToken;
    _wanted = accessToken != null && accessToken.isNotEmpty;
    if (!_wanted) {
      await disconnect();
      return;
    }
    await _ensureSocket();
  }

  Future<void> clearAuth() async {
    _wanted = false;
    _token = null;
    await disconnect();
  }

  void _onLifecycle() {
    if (!_wanted) return;
    // Stay connected in the background so a locked phone can still ring
    // and show a message banner. Only a dead network drops the socket.
    if (ConnectivityService.instance.isOffline) {
      unawaited(disconnect());
      return;
    }
    unawaited(_ensureSocket());
  }

  Future<void> _ensureSocket() async {
    if (!_wanted || _token == null) return;
    if (ConnectivityService.instance.isOffline) return;
    if (_socket != null && _connected) return;

    _reconnectTimer?.cancel();
    await disconnect(notify: false);

    final url = kApiBaseUrl;
    final socket = io.io(
      '$url/realtime',
      io.OptionBuilder()
          // Polling fallback — Render/free proxies often flap pure websocket.
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableForceNew()
          .setAuth({'token': _token})
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      _connected = true;
      _syncGate();
      notifyListeners();
      _syncViewingPresence();
    });
    socket.onDisconnect((_) {
      _connected = false;
      _syncGate();
      notifyListeners();
      _scheduleReconnect();
    });
    socket.onConnectError((_) {
      _connected = false;
      _syncGate();
      notifyListeners();
      _scheduleReconnect();
    });
    socket.on(kRtReady, (_) {
      _connected = true;
      _syncGate();
      notifyListeners();
      _syncViewingPresence();
    });
    socket.on(kRtChatMessage, (data) {
      final map = _asMap(data);
      if (map == null) return;
      _chatMessageCtrl.add(map);
      _emitInbox(map);
    });
    socket.on(kRtBadgeHint, (data) {
      final map = _asMap(data);
      if (map != null) _badgeHintCtrl.add(map);
    });
    socket.on(kRtNotification, (data) {
      final map = _asMap(data);
      if (map != null) _notificationCtrl.add(map);
    });
    socket.on(kRtCallIncoming, (data) {
      final map = _asMap(data);
      if (map != null) _callIncomingCtrl.add(map);
    });
    socket.on(kRtCallEnded, (data) {
      final map = _asMap(data);
      if (map != null) _callEndedCtrl.add(map);
    });
    socket.on(kRtLiveLocation, (data) {
      final map = _asMap(data);
      if (map != null && !_liveCtrl.isClosed) _liveCtrl.add(map);
    });

    socket.connect();
  }

  void _scheduleReconnect() {
    if (!_wanted) return;
    if (ConnectivityService.instance.isOffline) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      unawaited(_ensureSocket());
    });
  }

  Future<void> disconnect({bool notify = true}) async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final s = _socket;
    _socket = null;
    if (s != null) {
      try {
        s.disconnect();
        s.dispose();
      } catch (_) {}
    }
    if (_connected || MessageSyncGate.instance.realtimeLive) {
      _connected = false;
      _syncGate();
      if (notify) notifyListeners();
    }
  }

  void _emitInbox(Map<String, dynamic> map) {
    if (_inboxCtrl.isClosed) return;
    _inboxCtrl.add(map);
  }

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    if (_listenersAttached) {
      AppForeground.instance.removeListener(_onLifecycle);
      ConnectivityService.instance.removeListener(_onLifecycle);
      ActiveChatTracker.instance.removeListener(_syncViewingPresence);
      _listenersAttached = false;
    }
    unawaited(disconnect());
    unawaited(_chatMessageCtrl.close());
    unawaited(_inboxCtrl.close());
    unawaited(_badgeHintCtrl.close());
    unawaited(_notificationCtrl.close());
    unawaited(_callIncomingCtrl.close());
    unawaited(_callEndedCtrl.close());
    unawaited(_liveCtrl.close());
    super.dispose();
  }
}
