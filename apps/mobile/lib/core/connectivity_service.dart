// Made by Dr Ali
// App-wide connectivity — WeChat-style offline banner + reconnect flush.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'app_foreground.dart';

/// Link-layer online/offline for UI. Not a guarantee of API reachability.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _started = false;
  bool _online = true;
  bool _connecting = false;
  bool _wasForeground = true;
  Timer? _connectTimer;

  bool get isOnline => _online;
  bool get isOffline => !_online;
  bool get isConnecting => _connecting;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    AppForeground.instance.addListener(_onForeground);
    try {
      await _apply(await _connectivity.checkConnectivity());
    } catch (_) {
      // Assume online if the plugin fails — avoid false offline walls.
      _online = true;
    }
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
  }

  Future<void> refresh() async {
    try {
      await _apply(await _connectivity.checkConnectivity());
    } catch (_) {}
  }

  void _onForeground() {
    final active = AppForeground.instance.isActive;
    if (active && !_wasForeground) {
      unawaited(refresh());
    }
    _wasForeground = active;
  }

  Future<void> _apply(List<ConnectivityResult> results) async {
    final next = results.any((r) => r != ConnectivityResult.none);
    if (next == _online) return;
    final wasOffline = !_online;
    _online = next;
    if (wasOffline && next) {
      _connecting = true;
      _connectTimer?.cancel();
      _connectTimer = Timer(const Duration(seconds: 2), () {
        _connecting = false;
        notifyListeners();
      });
    } else {
      _connecting = false;
      _connectTimer?.cancel();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _connectTimer?.cancel();
    _sub = null;
    if (_started) {
      AppForeground.instance.removeListener(_onForeground);
      _started = false;
    }
    super.dispose();
  }
}
