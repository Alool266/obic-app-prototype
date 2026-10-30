// Made by Dr Ali
// App-wide foreground gate — pause network polls while backgrounded.

import 'package:flutter/widgets.dart';

/// Singleton lifecycle signal. Attach once from [ObicApp].
class AppForeground extends ChangeNotifier with WidgetsBindingObserver {
  AppForeground._();
  static final AppForeground instance = AppForeground._();

  bool _attached = false;
  bool _active = true;

  /// True while the app is resumed (interactive).
  bool get isActive => _active;

  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null) {
      _active = state != AppLifecycleState.paused &&
          state != AppLifecycleState.detached;
    }
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep "active" through inactive/hidden so Socket.IO call signaling
    // survives permission dialogs, the notification shade, and brief OS
    // overlays. Only paused/detached mean the app is truly backgrounded.
    final next = switch (state) {
      AppLifecycleState.resumed ||
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden =>
        true,
      AppLifecycleState.paused || AppLifecycleState.detached => false,
    };
    if (next == _active) return;
    _active = next;
    notifyListeners();
  }
}
