// Made by Dr Ali
// In-app mini-app engine. One WebView ships inside OBIC. Partners upload an
// HTML/CSS/JS package; OBIC hosts it. Phones open that hosted index. Partners
// do not compile a Flutter module into the binary.
//
// Closing (capsule ✕, Android back, right-edge swipe, or OBIC.close())
// only leaves this screen — the mini app stays alive in MiniAppSessionStore
// and reopens exactly where the user left it, like WeChat. The bridge never
// receives the OBIC access token, refresh token, cookies, phone, email, or
// any payment method. The page cannot mint a session.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/obic_colors.dart';
import 'mini_app_navigation.dart';
import 'mini_app_session.dart';

class MiniAppEngineScreen extends StatefulWidget {
  const MiniAppEngineScreen({
    super.key,
    required this.title,
    required this.startUrl,
    this.displayName,
  });

  final String title;
  final String startUrl;

  /// Public display name only. Null when the user is logged out.
  final String? displayName;

  @override
  State<MiniAppEngineScreen> createState() => _MiniAppEngineScreenState();
}

class _MiniAppEngineScreenState extends State<MiniAppEngineScreen> {
  MiniAppSession? _session;
  Uri? _approved;
  int _progress = 0;
  bool _failed = false;
  bool _closing = false;
  double _edgeSwipeDx = 0;

  @override
  void initState() {
    super.initState();
    final approved = approvedMiniAppUri(widget.startUrl);
    _approved = approved;
    if (approved == null) {
      _failed = true;
      return;
    }
    final session = MiniAppSessionStore.acquire(
      startUrl: widget.startUrl,
      approved: approved,
      displayName: widget.displayName,
    );
    _session = session;
    _progress = session.pageLoaded ? 100 : 0;
    _attach(session);
  }

  void _attach(MiniAppSession session) {
    session.attach(
      this,
      onProgress: (value) {
        if (!mounted) return;
        setState(() => _progress = value);
      },
      onPageStarted: () {
        if (!mounted) return;
        setState(() => _failed = false);
      },
      onPageFinished: () {
        if (!mounted) return;
        setState(() => _progress = 100);
      },
      onMainFrameError: () {
        if (!mounted) return;
        setState(() => _failed = true);
      },
      onCloseRequested: _closeScreen,
    );
  }

  @override
  void dispose() {
    // The session (and its WebView) outlives this screen on purpose.
    _session?.detach(this);
    super.dispose();
  }

  void _closeScreen() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  Future<void> _closeOrGoBack() async {
    final controller = _session?.controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return;
    }
    _closeScreen();
  }

  Future<void> _reload() async {
    final approved = _approved;
    final session = _session;
    if (approved == null || session == null) return;
    setState(() {
      _failed = false;
      _progress = 0;
    });
    await session.controller.loadRequest(approved);
  }

  /// Full reset: drop the live session and load the mini app from scratch.
  void _restart() {
    final approved = _approved;
    if (approved == null) return;
    _session?.detach(this);
    final session = MiniAppSessionStore.restart(
      startUrl: widget.startUrl,
      approved: approved,
      displayName: widget.displayName,
    );
    _session = session;
    _attach(session);
    setState(() {
      _failed = false;
      _progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final surface = ObicColors.surfaceOf(context);
    final ink = ObicColors.inkOf(context);
    final line = ObicColors.lineOf(context);
    final controller = _session?.controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _closeOrGoBack();
      },
      child: Scaffold(
        backgroundColor: surface,
        body: Stack(
          children: [
            Column(
              children: [
                ColoredBox(
                  color: surface,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, top + 6, 10, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _Capsule(
                          borderColor: line,
                          ink: ink,
                          onMore: () {
                            showModalBottomSheet<void>(
                              context: context,
                              backgroundColor: surface,
                              builder: (ctx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading:
                                          const Icon(Icons.refresh_rounded),
                                      title: Text(l10n.miniAppEngineReload),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _reload();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.restart_alt_rounded,
                                      ),
                                      title: Text(l10n.miniAppEngineRestart),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _restart();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          onClose: _closeScreen,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_progress < 100 && !_failed)
                  LinearProgressIndicator(
                    value: _progress <= 0 ? null : _progress / 100,
                    minHeight: 2,
                    color: ObicColors.blue,
                    backgroundColor: ObicColors.blueSoftOf(context),
                  ),
                Expanded(
                  child: _failed || controller == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  color: ObicColors.mutedOf(context),
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.miniAppEngineFail,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (controller != null) ...[
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: _reload,
                                    child: Text(l10n.miniAppEngineRetry),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : WebViewWidget(controller: controller),
                ),
              ],
            ),
            // Right-edge swipe (slide in from the edge) → back inside the
            // mini app, or close it when there is nowhere to go back to.
            // The session stays alive either way, like WeChat.
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 22,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (_) => _edgeSwipeDx = 0,
                onHorizontalDragUpdate: (d) => _edgeSwipeDx += d.delta.dx,
                onHorizontalDragEnd: (d) {
                  final fling = (d.primaryVelocity ?? 0) < -300;
                  if (_edgeSwipeDx < -56 || fling) _closeOrGoBack();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// WeChat capsule: more · close. Stays inside OBIC, not the system browser.
class _Capsule extends StatelessWidget {
  const _Capsule({
    required this.borderColor,
    required this.ink,
    required this.onMore,
    required this.onClose,
  });

  final Color borderColor;
  final Color ink;
  final VoidCallback onMore;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: SizedBox(
        height: 32,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _hit(Icons.more_horiz_rounded, onMore),
            Container(width: 1, height: 16, color: borderColor),
            _hit(Icons.close_rounded, onClose),
          ],
        ),
      ),
    );
  }

  Widget _hit(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 40,
        height: 32,
        child: Icon(icon, size: 18, color: ink),
      ),
    );
  }
}
