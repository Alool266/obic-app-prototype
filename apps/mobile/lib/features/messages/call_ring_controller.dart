// Made by Dr Ali
// App-wide incoming-call ring — must sit above ChatScreen / pushed routes.
// OEM-agnostic: Honor/Oppo/Xiaomi/Samsung/Pixel all push chat on the root
 // navigator; a shell-local overlay is buried and never shown.

import 'package:flutter/foundation.dart';

/// Singleton ring state. [MainShell] arms accept/decline; [ObicApp] paints
/// [IncomingCallOverlay] in the MaterialApp builder so it covers every route.
class CallRingController extends ChangeNotifier {
  CallRingController._();
  static final CallRingController instance = CallRingController._();

  Map<String, dynamic>? _payload;
  Future<void> Function()? _onAccept;
  Future<void> Function()? _onDecline;
  bool _busy = false;

  Map<String, dynamic>? get payload => _payload;
  bool get busy => _busy;
  bool get hasIncoming => _payload != null;

  /// Present a ring. Ignored while another ring or accept flow is active.
  void present(
    Map<String, dynamic> payload, {
    required Future<void> Function() onAccept,
    required Future<void> Function() onDecline,
  }) {
    if (_busy || _payload != null) return;
    final id = payload['callId']?.toString();
    if (id == null || id.isEmpty) return;
    _payload = Map<String, dynamic>.from(payload);
    _onAccept = onAccept;
    _onDecline = onDecline;
    notifyListeners();
  }

  /// Drop the UI when the peer hangs up or the session expires.
  void dismissIfCall(String? callId) {
    if (callId == null || _payload == null) return;
    if (_payload!['callId']?.toString() != callId) return;
    _clear(notify: true);
  }

  void clear() => _clear(notify: true);

  Future<void> accept() async {
    if (_busy || _payload == null) return;
    _busy = true;
    final fn = _onAccept;
    // Handler must push the call route before its first await. Run that
    // synchronous prefix first so the call screen is already in the navigator
    // when the ring overlay is removed — otherwise the frame goes black.
    final pending = fn?.call();
    _payload = null;
    _onAccept = null;
    _onDecline = null;
    notifyListeners();
    try {
      await pending;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> decline() async {
    if (_busy || _payload == null) return;
    final fn = _onDecline;
    _payload = null;
    _onAccept = null;
    _onDecline = null;
    notifyListeners();
    await fn?.call();
  }

  void _clear({required bool notify}) {
    _payload = null;
    _onAccept = null;
    _onDecline = null;
    if (notify) notifyListeners();
  }
}
