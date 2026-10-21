// Made by Dr Ali
// WeChat-style mini-app sessions. Closing the mini-app screen keeps the
// web app alive in memory — page, scroll, form state, and login cookies
// are exactly where the user left them when they reopen it. A session
// ends only when the app process dies, when it is evicted (max 3 kept),
// or when the user picks "Restart" in the capsule menu.
//
// The OBIC JS bridge contract is unchanged and stays token-free:
//   OBIC.close()   — closes the visible screen (session stays alive).
//   OBIC.profile   — `{ displayName }` or null. Never tokens/cookies/PII.

import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/obic_colors.dart';
import 'mini_app_navigation.dart';

class MiniAppSession {
  MiniAppSession._({
    required this.startUrl,
    required this.approved,
    required this.controller,
    this.displayName,
  });

  final String startUrl;
  final Uri approved;
  final WebViewController controller;
  String? displayName;

  /// True once a page finished loading (used to hide the progress bar
  /// instantly when a live session is re-shown).
  bool pageLoaded = false;

  Object? _owner;
  void Function(int progress)? _onProgress;
  void Function()? _onPageStarted;
  void Function()? _onPageFinished;
  void Function()? _onMainFrameError;
  void Function()? _onCloseRequested;

  /// The visible engine screen registers its callbacks while mounted.
  void attach(
    Object owner, {
    required void Function(int progress) onProgress,
    required void Function() onPageStarted,
    required void Function() onPageFinished,
    required void Function() onMainFrameError,
    required void Function() onCloseRequested,
  }) {
    _owner = owner;
    _onProgress = onProgress;
    _onPageStarted = onPageStarted;
    _onPageFinished = onPageFinished;
    _onMainFrameError = onMainFrameError;
    _onCloseRequested = onCloseRequested;
    installBridge();
  }

  void detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _onProgress = null;
    _onPageStarted = null;
    _onPageFinished = null;
    _onMainFrameError = null;
    _onCloseRequested = null;
  }

  /// Replace the raw channel (`OBIC.postMessage`) with the small safe API.
  /// Re-run after each document load. Tokens are never interpolated.
  void installBridge() {
    final name = displayName?.trim();
    final profile = (name == null || name.isEmpty)
        ? 'null'
        : '{displayName:${jsonEncode(name)}}';
    controller.runJavaScript('''
(function(){
  var channel = window.OBIC;
  if (!channel || typeof channel.postMessage !== 'function') return;
  var post = channel.postMessage.bind(channel);
  window.OBIC = {
    close: function(){ post('close'); },
    profile: $profile
  };
})();
''');
  }

  void _onBridgeMessage(JavaScriptMessage message) {
    final raw = message.message.trim();
    if (raw == 'close') {
      _onCloseRequested?.call();
      return;
    }
    if (raw.length > 200) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['method'] == 'close') {
        _onCloseRequested?.call();
      }
    } catch (_) {}
  }

  static MiniAppSession create({
    required String startUrl,
    required Uri approved,
    String? displayName,
  }) {
    late final MiniAppSession session;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(ObicColors.background)
      ..addJavaScriptChannel(
        'OBIC',
        onMessageReceived: (m) => session._onBridgeMessage(m),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (miniAppNavigationAllowed(
              approved: approved,
              target: request.url,
            )) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onProgress: (value) => session._onProgress?.call(value),
          onPageStarted: (_) {
            session.pageLoaded = false;
            session._onPageStarted?.call();
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            if (miniAppNavigationAllowed(approved: approved, target: url)) {
              return;
            }
            session.controller.loadRequest(approved);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            session._onMainFrameError?.call();
          },
          onPageFinished: (_) {
            session.pageLoaded = true;
            session.installBridge();
            session._onPageFinished?.call();
          },
        ),
      )
      ..loadRequest(approved);
    session = MiniAppSession._(
      startUrl: startUrl,
      approved: approved,
      controller: controller,
      displayName: displayName,
    );
    return session;
  }
}

/// Process-wide registry of live mini-app sessions (most-recent last).
class MiniAppSessionStore {
  MiniAppSessionStore._();

  static const int maxSessions = 3;
  static final Map<String, MiniAppSession> _sessions = {};
  static final List<String> _order = [];

  /// Reuse the live session for [startUrl] (resuming where the user left
  /// off), or create and load a fresh one.
  static MiniAppSession acquire({
    required String startUrl,
    required Uri approved,
    String? displayName,
  }) {
    _order.remove(startUrl);
    _order.add(startUrl);
    final existing = _sessions[startUrl];
    if (existing != null) {
      existing.displayName = displayName;
      existing.installBridge();
      return existing;
    }
    final session = MiniAppSession.create(
      startUrl: startUrl,
      approved: approved,
      displayName: displayName,
    );
    _sessions[startUrl] = session;
    while (_order.length > maxSessions) {
      final evicted = _order.removeAt(0);
      _sessions.remove(evicted);
    }
    return session;
  }

  /// Drop the live session and load the mini app from scratch.
  static MiniAppSession restart({
    required String startUrl,
    required Uri approved,
    String? displayName,
  }) {
    _sessions.remove(startUrl);
    _order.remove(startUrl);
    return acquire(
      startUrl: startUrl,
      approved: approved,
      displayName: displayName,
    );
  }
}
