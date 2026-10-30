// Made by Dr Ali
// WeChat-style pull-down mini-apps panel — Home + Discover entry.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/media_url.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/obic_logo.dart';
import '../../widgets/script_text_field.dart';
import '../africa_in_hand/africa_in_hand_page.dart';
import '../auth/auth_controller.dart';
import '../china_in_hand/china_in_hand_page.dart';
import '../daily_life/daily_life_page.dart';
import '../mideast_in_hand/mideast_in_hand_page.dart';
import '../music/music_mark.dart';
import '../music/music_screen.dart';
import '../office/office_home_screen.dart';
import '../travel_hub/travel_hub_page.dart';
import '../yemen_in_hand/yemen_flag_icon.dart';
import '../yemen_in_hand/yemen_in_hand_page.dart';
import 'mini_app_engine_screen.dart';
import 'mini_apps_api.dart';
import 'mini_apps_arrange_screen.dart';
import 'mini_apps_catalog.dart';
import 'mini_apps_layout.dart';

const _kTipSeenKey = 'obic_mini_apps_tip_seen_v1';

/// Opens an approved (or first-party) page in the engine. Not a raw URL field.
Future<void> openMiniAppEntry(
  BuildContext context,
  MiniAppEntry app, {
  String? displayName,
  AuthController? authController,
}) async {
  if (app.comingSoon) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OfficeComingSoonScreen(),
      ),
    );
    return;
  }
  if (app.id == kObicMusicMiniAppId) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MusicScreen()),
    );
    return;
  }
  final auth = authController;
  final lang = Localizations.localeOf(context).languageCode;
  if (app.id == kObicYemenMiniAppId) {
    if (auth == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => YemenInHandPage(
          authController: auth,
          langCode: lang,
        ),
      ),
    );
    return;
  }
  if (app.id == kObicChinaMiniAppId) {
    if (auth == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChinaInHandPage(
          authController: auth,
          langCode: lang,
        ),
      ),
    );
    return;
  }
  if (app.id == kObicMideastMiniAppId) {
    if (auth == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MideastInHandPage(
          authController: auth,
          langCode: lang,
        ),
      ),
    );
    return;
  }
  if (app.id == kObicAfricaMiniAppId) {
    if (auth == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AfricaInHandPage(
          authController: auth,
          langCode: lang,
        ),
      ),
    );
    return;
  }
  if (app.id == kObicDailyMiniAppId) {
    if (auth == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DailyLifePage(
          authController: auth,
          langCode: lang,
        ),
      ),
    );
    return;
  }
  if (app.id == kObicTravelMiniAppId) {
    if (auth == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TravelHubPage(
          authController: auth,
          langCode: lang,
        ),
      ),
    );
    return;
  }
  if (app.id == kObicNotesMiniAppId ||
      app.id == kObicDocumentsMiniAppId ||
      app.id == kObicSpreadsheetsMiniAppId ||
      app.id == kObicPdfMiniAppId) {
    if (auth == null) return;
    final kind = switch (app.id) {
      kObicNotesMiniAppId => 'note',
      kObicDocumentsMiniAppId => 'document',
      kObicSpreadsheetsMiniAppId => 'spreadsheet',
      kObicPdfMiniAppId => 'pdf',
      _ => 'note',
    };
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OfficeHomeScreen(
          authController: auth,
          kind: kind,
        ),
      ),
    );
    return;
  }
  if (app.id == kObicSlidesMiniAppId) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OfficeComingSoonScreen(),
      ),
    );
    return;
  }
  if (app.native) return;
  if (!app.canOpen) return;
  final startUrl = engineStartUrlFor(app);
  if (startUrl == null) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => MiniAppEngineScreen(
        title: app.name,
        startUrl: startUrl,
        displayName: displayName,
      ),
    ),
  );
}

/// Opens mini-apps as a full route (Discover row, deep links, etc.).
/// Same catalog / UI body as the Home pull-down panel.
Future<void> openMiniAppsPanel(
  BuildContext context, {
  String? Function()? displayName,
  String? userId,
  AuthController? authController,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => MiniAppsStandalonePage(
        displayName: displayName,
        userId: userId,
        authController: authController,
      ),
    ),
  );
}

/// Opens the Home mini-apps panel from a cue / tip.
class MiniAppsPullController {
  VoidCallback? _open;

  void _bind(VoidCallback open) => _open = open;

  void _unbind(VoidCallback open) {
    if (_open == open) _open = null;
  }

  void open() => _open?.call();
}

/// Hosts Home content and reveals mini-apps when the user pulls down from the
/// top (status / app-bar zone), like WeChat. Close by drag-up or tap outside.
class MiniAppsPullDownHost extends StatefulWidget {
  const MiniAppsPullDownHost({
    super.key,
    required this.child,
    this.controller,
    this.displayName,
    this.userId,
    this.authController,
  });

  final Widget child;
  final MiniAppsPullController? controller;
  final String? Function()? displayName;
  final String? userId;
  final AuthController? authController;

  @override
  State<MiniAppsPullDownHost> createState() => _MiniAppsPullDownHostState();
}

class _MiniAppsPullDownHostState extends State<MiniAppsPullDownHost>
    with SingleTickerProviderStateMixin {
  static const double _panelMax = 380;
  /// Easy snap-open (WeChat-like — short pull is enough).
  static const double _openThreshold = 48;
  /// Pull-up this far from full-open → close (easy, not sticky).
  static const double _closeDistance = 40;
  static const double _openDragGain = 1.55;
  static const double _closeDragGain = 1.2;
  static const double _topHitExtra = 96;

  late final AnimationController _anim;
  double _extent = 0;
  double _dragStartExtent = 0;
  bool _dragging = false;
  bool _atTop = true;
  bool _pointerTracking = false;
  double _pointerStartY = 0;
  String _query = '';
  bool _showTip = false;
  List<MiniAppEntry> _remote = const [];
  Set<String> _disabledFirstParty = {};
  bool _catalogLoaded = false;
  MiniAppLayout _layout = MiniAppLayout.empty;
  MiniAppGeo? _geoFocus;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_dragging) return;
        setState(() => _extent = _anim.value * _panelMax);
      });
    widget.controller?._bind(_snapOpen);
    unawaited(_loadTip());
    unawaited(_loadCatalog());
    unawaited(_loadLayout());
  }

  Future<void> _loadLayout() async {
    final token = await widget.authController?.accessToken();
    final layout = await MiniAppLayoutStore(widget.userId ?? 'guest')
        .load(accessToken: token);
    if (!mounted) return;
    setState(() => _layout = layout);
  }

  Future<void> _loadTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_kTipSeenKey) ?? false;
      if (!mounted || seen) return;
      setState(() => _showTip = true);
    } catch (_) {}
  }

  Future<void> _dismissTip({bool openPanel = false}) async {
    setState(() => _showTip = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kTipSeenKey, true);
    } catch (_) {}
    if (openPanel) _snapOpen();
  }

  @override
  void didUpdateWidget(covariant MiniAppsPullDownHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._unbind(_snapOpen);
      widget.controller?._bind(_snapOpen);
    }
  }

  @override
  void dispose() {
    widget.controller?._unbind(_snapOpen);
    _anim.dispose();
    super.dispose();
  }

  void _beginDrag() {
    _dragging = true;
    _dragStartExtent = _extent;
    _anim.stop();
  }

  void _snapOpen() {
    _dragging = false;
    _pointerTracking = false;
    HapticFeedback.lightImpact();
    _anim.duration = const Duration(milliseconds: 240);
    _anim.animateTo(1, curve: Curves.easeOutCubic);
  }

  void _snapClosed() {
    _dragging = false;
    _pointerTracking = false;
    _query = '';
    _anim.duration = const Duration(milliseconds: 200);
    _anim.animateTo(0, curve: Curves.easeOutCubic);
  }

  void _setExtent(double value) {
    final next = value.clamp(0.0, _panelMax);
    setState(() => _extent = next);
    _anim.value = next / _panelMax;
  }

  /// Asymmetric open/close so pull-up does not “stick” mid-panel.
  void _finishDrag({double velocity = 0}) {
    _dragging = false;
    _pointerTracking = false;

    // Upward fling → always close.
    if (velocity < -280) {
      _snapClosed();
      return;
    }
    // Downward fling → open.
    if (velocity > 420) {
      _snapOpen();
      return;
    }

    final startedOpen = _dragStartExtent >= _panelMax * 0.82;
    final pulledUp = _dragStartExtent - _extent;

    if (startedOpen) {
      // Closing gesture: small upward travel is enough.
      if (pulledUp >= _closeDistance || _extent < _panelMax * 0.88) {
        _snapClosed();
      } else {
        _snapOpen();
      }
      return;
    }

    // Opening from closed / partial.
    if (_extent >= _openThreshold) {
      _snapOpen();
    } else {
      _snapClosed();
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    _atTop = n.metrics.pixels <= 2.0;
    // Ignore Home scroll while panel is up (avoids gesture fighting).
    if (_extent > 8 || _pointerTracking) return false;

    if (n is OverscrollNotification && _atTop && n.overscroll < 0) {
      if (!_dragging) _beginDrag();
      _setExtent(_extent - n.overscroll * _openDragGain);
      return false;
    }

    if (n is ScrollUpdateNotification && n.metrics.pixels < 0) {
      if (!_dragging) _beginDrag();
      _setExtent(-n.metrics.pixels * _openDragGain);
      return false;
    }

    if (n is ScrollEndNotification && _dragging) {
      _finishDrag();
    }
    return false;
  }

  void _onPointerDown(PointerDownEvent e) {
    if (_extent > 8) return; // panel owns gestures when open
    final topZone = MediaQuery.paddingOf(context).top + _topHitExtra;
    if (e.localPosition.dy <= topZone && _atTop) {
      _pointerTracking = true;
      _pointerStartY = e.position.dy;
      _dragStartExtent = _extent;
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointerTracking) return;
    final dy = e.position.dy - _pointerStartY;
    if (dy <= 0 && _extent <= 0) return;
    if (!_dragging) _beginDrag();
    _setExtent(dy * _openDragGain);
  }

  void _onPointerUp(PointerUpEvent e) {
    if (!_pointerTracking) return;
    final dy = e.position.dy - _pointerStartY;
    _finishDrag(velocity: dy > 90 ? 600 : (dy < -40 ? -400 : 0));
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (_pointerTracking) _finishDrag();
  }

  void _onPanelDragUpdate(DragUpdateDetails d) {
    if (!_dragging) _beginDrag();
    final dy = d.delta.dy;
    // Closing (finger up): light assist, 1:1-ish. Opening: mild gain.
    final gain = dy < 0 ? _closeDragGain : 1.0;
    _setExtent(_extent + dy * gain);
  }

  void _onPanelDragEnd(DragEndDetails d) {
    _finishDrag(velocity: d.primaryVelocity ?? 0);
  }

  void _onPanelDragStart(DragStartDetails d) {
    _beginDrag();
  }

  void _openApp(MiniAppEntry app) {
    final name = widget.displayName?.call();
    _snapClosed();
    unawaited(
      openMiniAppEntry(
        context,
        app,
        displayName: name,
        authController: widget.authController,
      ),
    );
  }

  List<MiniAppEntry> _catalog(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final site = obicWebsiteMiniApp(
      AppLocalizations.of(context).miniAppWebsiteName,
    );
    final first = [
      obicMusicMiniApp(lang),
      obicYemenInHandMiniApp(lang),
      ...firstPartyProductivityAndHubs(lang),
    ].where((a) => !_disabledFirstParty.contains(a.id)).toList();
    final merged = mergeApprovedMiniApps(site, first, _remote);
    return filterMiniAppsByGeo(merged, _geoFocus);
  }

  Future<void> _loadCatalog() async {
    if (_catalogLoaded) return;
    _catalogLoaded = true;
    try {
      final remote = await MiniAppsApi().listApproved();
      Set<String> disabled = {};
      try {
        final flags = await MiniAppsApi().listFirstPartyFlags();
        disabled = {
          for (final row in flags)
            if (row['enabled'] == false) (row['appId']?.toString() ?? ''),
        }..remove('');
      } catch (_) {}
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final geo = geoFromLocaleOrCountry(
        '${locale.countryCode ?? ''}_${locale.languageCode}',
      );
      if (!mounted) return;
      setState(() {
        _remote = remote;
        _disabledFirstParty = disabled;
        _geoFocus = geo;
      });
    } catch (_) {
      // Trial API may not have this route yet. The website tile still opens.
    }
  }

  List<MiniAppEntry> _filtered(BuildContext context) {
    final all = applyMiniAppLayout(_catalog(context), _layout);
    return all.where((app) => miniAppMatchesQuery(app, _query)).toList();
  }

  Future<void> _arrange(BuildContext context) async {
    final apps = _catalog(context);
    final token = await widget.authController?.accessToken();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MiniAppsArrangeScreen(
          apps: apps,
          userId: widget.userId ?? 'guest',
          accessToken: token,
        ),
      ),
    );
    await _loadLayout();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_extent / _panelMax).clamp(0.0, 1.0);
    final barrierOpacity = (progress * 0.5).clamp(0.0, 0.5);
    final topPad = MediaQuery.paddingOf(context).top;
    final panelUp = progress > 0.02;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: Transform.translate(
              offset: Offset(0, _extent * 0.22),
              child: widget.child,
            ),
          ),
          if (!panelUp)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: MiniAppsTopGrabBar(onOpen: _snapOpen),
              ),
            ),
          if (panelUp) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _snapClosed,
                onVerticalDragStart: _onPanelDragStart,
                onVerticalDragUpdate: _onPanelDragUpdate,
                onVerticalDragEnd: _onPanelDragEnd,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: barrierOpacity),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topPad + _extent,
              child: Material(
                color: ObicColors.surfaceOf(context),
                elevation: progress > 0.15 ? 8 : 0,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: EdgeInsets.only(top: topPad),
                  child: _MiniAppsPanelBody(
                    onQueryChanged: (v) => setState(() => _query = v),
                    apps: _filtered(context),
                    onOpen: _openApp,
                    onArrange: () => unawaited(_arrange(context)),
                    onClose: _snapClosed,
                    compact: _extent < _panelMax * 0.75,
                    onDragStart: _onPanelDragStart,
                    onDragUpdate: _onPanelDragUpdate,
                    onDragEnd: _onPanelDragEnd,
                    partnerEmpty: _remote.isEmpty,
                    query: _query,
                  ),
                ),
              ),
            ),
          ],
          if (_showTip && !panelUp)
            Positioned.fill(
              child: _MiniAppsFirstRunTip(
                onDismiss: () => unawaited(_dismissTip()),
                onTry: () => unawaited(_dismissTip(openPanel: true)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thin persistent affordance under the status bar — tap opens panel.
class MiniAppsTopGrabBar extends StatelessWidget {
  const MiniAppsTopGrabBar({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniAppsFirstRunTip extends StatelessWidget {
  const _MiniAppsFirstRunTip({
    required this.onDismiss,
    required this.onTry,
  });

  final VoidCallback onDismiss;
  final VoidCallback onTry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = ObicColors.surfaceOf(context);
    final title = ObicColors.titleOf(context);
    final muted = ObicColors.mutedOf(context);

    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apps_rounded, color: ObicColors.blue, size: 32),
                  const SizedBox(height: 10),
                  Text(
                    l10n.miniAppsTipTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: title,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.miniAppsTipBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: onDismiss,
                          child: Text(l10n.miniAppsTipDismiss),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: onTry,
                          style: FilledButton.styleFrom(
                            backgroundColor: ObicColors.blue,
                          ),
                          child: Text(l10n.miniAppsTipTry),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniAppsPanelBody extends StatelessWidget {
  const _MiniAppsPanelBody({
    required this.onQueryChanged,
    required this.apps,
    required this.onOpen,
    this.onArrange,
    required this.onClose,
    required this.compact,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.partnerEmpty = false,
    this.query = '',
  });

  final ValueChanged<String> onQueryChanged;
  final List<MiniAppEntry> apps;
  final ValueChanged<MiniAppEntry> onOpen;
  final VoidCallback? onArrange;
  final VoidCallback onClose;
  final bool compact;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final bool partnerEmpty;
  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = ObicColors.titleOf(context);
    final muted = ObicColors.mutedOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header — primary close drag (avoids fighting the grid ScrollView).
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: onDragStart,
          onVerticalDragUpdate: onDragUpdate,
          onVerticalDragEnd: onDragEnd,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.miniAppsTitle,
                        style: TextStyle(
                          color: title,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.miniAppsPullHint,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onArrange != null)
                  IconButton(
                    tooltip: Localizations.localeOf(context).languageCode.startsWith('ar')
                        ? 'ترتيب'
                        : 'Arrange',
                    onPressed: onArrange,
                    icon: Icon(Icons.tune_rounded, color: muted),
                  ),
                IconButton(
                  tooltip: l10n.miniAppsClose,
                  onPressed: onClose,
                  icon: Icon(Icons.keyboard_arrow_up_rounded, color: muted),
                ),
              ],
            ),
          ),
        ),
        if (!compact)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: ObicScriptTextField(
              onChanged: onQueryChanged,
              style: TextStyle(color: ObicColors.inkOf(context), fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.miniAppsSearchHint,
                hintStyle: TextStyle(color: muted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: muted, size: 20),
                filled: true,
                fillColor: ObicColors.isDark(context)
                    ? ObicColors.darkSurfaceRaised
                    : ObicColors.listCanvas,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        Expanded(
          child: apps.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.miniAppsEmptySearch,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (partnerEmpty && query.trim().isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'لا تطبيقات شركاء معتمدة حالياً — موقع أوبك والموسيقى متاحان.'
                                : Localizations.localeOf(context).languageCode ==
                                        'zh'
                                    ? '暂无合作小程序 — OBIC 官网与音乐仍可用。'
                                    : 'No partner mini-apps approved yet — OBIC site, Music & Yemen stay available.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      _MiniAppsGrid(
                        apps: apps,
                        onTap: onOpen,
                      ),
                    ],
                  ),
                ),
        ),
        // Bottom handle — large pull-up target to dismiss.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: onDragStart,
          onVerticalDragUpdate: onDragUpdate,
          onVerticalDragEnd: onDragEnd,
          onTap: onClose,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Text(
                  l10n.miniAppsCloseHint,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniAppsGrid extends StatelessWidget {
  const _MiniAppsGrid({
    required this.apps,
    required this.onTap,
  });

  final List<MiniAppEntry> apps;
  final ValueChanged<MiniAppEntry> onTap;

  static const _columns = 4;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < apps.length; i += _columns) {
      final end = (i + _columns).clamp(0, apps.length);
      final chunk = apps.sublist(i, end);
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 14));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < _columns; c++) ...[
              if (c > 0) const SizedBox(width: 6),
              Expanded(
                child: c < chunk.length
                    ? _MiniAppTile(
                        app: chunk[c],
                        onTap: () => onTap(chunk[c]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(children: rows);
  }
}

class _MiniAppTile extends StatelessWidget {
  const _MiniAppTile({
    required this.app,
    required this.onTap,
  });

  final MiniAppEntry app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = ObicColors.inkOf(context);
    final muted = ObicColors.mutedOf(context);
    final iconUrl = app.iconUrl;
    final resolved = iconUrl == null || iconUrl.isEmpty
        ? ''
        : resolveMediaUrl(iconUrl);
    final showNetwork = resolved.startsWith('https://');
    final canTap = app.canOpen || app.comingSoon;

    Widget mark;
    if (app.id == kObicMusicMiniAppId) {
      mark = const MusicMark(size: 52);
    } else if (app.id == kObicYemenMiniAppId) {
      mark = const _YemenMiniAppMark();
    } else if (app.icon != null) {
      mark = Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ObicColors.blueSoftOf(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(app.icon, color: ObicColors.blue, size: 28),
      );
    } else if (app.firstParty) {
      mark = const ObicLogo(size: 52, borderRadius: 14);
    } else {
      mark = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 52,
          height: 52,
          child: showNetwork
              ? Image.network(
                  resolved,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _FallbackIcon(),
                )
              : const _FallbackIcon(),
        ),
      );
    }

    return InkWell(
      onTap: canTap ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                mark,
                if (app.comingSoon)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: ObicColors.blue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        Localizations.localeOf(context).languageCode
                                .startsWith('ar')
                            ? 'قريباً'
                            : 'Soon',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              app.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: app.comingSoon ? muted : ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ObicColors.blueSoftOf(context),
      child: const Icon(Icons.apps_rounded, color: ObicColors.blue, size: 28),
    );
  }
}

class _YemenMiniAppMark extends StatelessWidget {
  const _YemenMiniAppMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ObicColors.navy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8D48B).withValues(alpha: 0.55),
        ),
      ),
      child: const YemenFlagIcon(width: 34, height: 24, borderRadius: 3),
    );
  }
}

/// Full-screen mini-apps sheet for non-Home entry points (e.g. Discover).
class MiniAppsStandalonePage extends StatefulWidget {
  const MiniAppsStandalonePage({
    super.key,
    this.displayName,
    this.userId,
    this.authController,
  });

  final String? Function()? displayName;
  final String? userId;
  final AuthController? authController;

  @override
  State<MiniAppsStandalonePage> createState() => _MiniAppsStandalonePageState();
}

class _MiniAppsStandalonePageState extends State<MiniAppsStandalonePage> {
  String _query = '';
  List<MiniAppEntry> _remote = const [];
  Set<String> _disabledFirstParty = {};
  MiniAppLayout _layout = MiniAppLayout.empty;
  MiniAppGeo? _geoFocus;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCatalog());
    unawaited(_loadLayout());
  }

  Future<void> _loadLayout() async {
    final token = await widget.authController?.accessToken();
    final layout = await MiniAppLayoutStore(widget.userId ?? 'guest')
        .load(accessToken: token);
    if (!mounted) return;
    setState(() => _layout = layout);
  }

  Future<void> _loadCatalog() async {
    try {
      final remote = await MiniAppsApi().listApproved();
      Set<String> disabled = {};
      try {
        final flags = await MiniAppsApi().listFirstPartyFlags();
        disabled = {
          for (final row in flags)
            if (row['enabled'] == false) (row['appId']?.toString() ?? ''),
        }..remove('');
      } catch (_) {}
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final geo = geoFromLocaleOrCountry(
        '${locale.countryCode ?? ''}_${locale.languageCode}',
      );
      if (!mounted) return;
      setState(() {
        _remote = remote;
        _disabledFirstParty = disabled;
        _geoFocus = geo;
      });
    } catch (_) {}
  }

  List<MiniAppEntry> _all(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final site = obicWebsiteMiniApp(
      AppLocalizations.of(context).miniAppWebsiteName,
    );
    final first = [
      obicMusicMiniApp(lang),
      obicYemenInHandMiniApp(lang),
      ...firstPartyProductivityAndHubs(lang),
    ].where((a) => !_disabledFirstParty.contains(a.id)).toList();
    return filterMiniAppsByGeo(
      mergeApprovedMiniApps(site, first, _remote),
      _geoFocus,
    );
  }

  List<MiniAppEntry> _filtered(BuildContext context) {
    final all = applyMiniAppLayout(_all(context), _layout);
    return all.where((app) => miniAppMatchesQuery(app, _query)).toList();
  }

  void _close() => Navigator.of(context).maybePop();

  void _openApp(MiniAppEntry app) {
    unawaited(
      openMiniAppEntry(
        context,
        app,
        displayName: widget.displayName?.call(),
        authController: widget.authController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      body: Padding(
        padding: EdgeInsets.only(top: topPad),
        child: _MiniAppsPanelBody(
          onQueryChanged: (v) => setState(() => _query = v),
          apps: _filtered(context),
          onOpen: _openApp,
          onArrange: () async {
            final token = await widget.authController?.accessToken();
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MiniAppsArrangeScreen(
                  apps: _all(context),
                  userId: widget.userId ?? 'guest',
                  accessToken: token,
                ),
              ),
            );
            await _loadLayout();
          },
          onClose: _close,
          compact: false,
          onDragStart: (_) {},
          onDragUpdate: (_) {},
          onDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) < -280) _close();
          },
          partnerEmpty: _remote.isEmpty,
          query: _query,
        ),
      ),
    );
  }
}

/// Large Home discovery chip — tap opens the panel.
class MiniAppsPullCue extends StatelessWidget {
  const MiniAppsPullCue({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = ObicColors.isDark(context);
    final soft = ObicColors.blueSoftOf(context);
    final ink = isDark ? ObicColors.darkInk : ObicColors.navy;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: soft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ObicColors.blue.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    color: ObicColors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.miniAppsPullCue,
                        style: TextStyle(
                          color: ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.miniAppsPullHint,
                        style: TextStyle(
                          color: ObicColors.mutedOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ObicColors.blue,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
