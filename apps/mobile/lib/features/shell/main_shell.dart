// Made by Dr Ali
// Main customer shell (Home · Services · Messages · Contacts · Discover · Me).
// Orders live under Me. Opens for guests; protected actions use requireAuth.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/services.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/active_chat_tracker.dart';
import '../../core/app_foreground.dart';
import '../../core/badge_store.dart';
import '../../core/china_phone_gate.dart';
import '../../core/connectivity_service.dart';
import '../../core/message_sync_gate.dart';
import '../../core/phone_activation_lock.dart';
import '../../core/device_alerts.dart';
import '../../core/push_registrar.dart';
import '../../core/realtime_client.dart';
import '../../core/region_controller.dart';
import '../ai/obic_ai_floating_bubble.dart';
import '../ai/obic_ai_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../friends/friend_alert_open.dart';
import '../friends/friends_screen.dart';
import '../home/home_tab.dart';
import '../me/me_tab.dart';
import '../music/music_screen.dart';
import '../messages/call_float.dart';
import '../messages/call_ring_controller.dart';
import '../messages/call_ringtone.dart';
import '../messages/call_screen.dart';
import '../messages/calls_api.dart';
import '../messages/chat_call_body.dart';
import '../messages/chat_screen.dart';
import '../messages/app_sounds.dart';
import '../messages/chat_plus_menu.dart';
import '../messages/group_avatar_collage.dart';
import '../messages/messages_tab.dart';
import '../messages/outbound_message_queue.dart';
import '../channels/discover_screen.dart';
import '../ops/ops_hub_screen.dart';
import '../services/services_api.dart';
import '../services/services_tab.dart';
import '../social/social_api.dart';
import '../../l10n/locale_controller.dart';
import '../../l10n/theme_mode_controller.dart';
import '../../theme/obic_colors.dart';
import '../../theme/obic_elevation.dart';
import 'demo_walkthrough.dart';
import 'shell_badges.dart';
import 'tab_badge.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.localeController,
    required this.themeModeController,
    required this.regionController,
    required this.authController,
  });

  final LocaleController localeController;
  final ThemeModeController themeModeController;
  final RegionController regionController;
  final AuthController authController;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _kServicesTab = 1;
  static const _kMessagesTab = 2;
  static const _kContactsTab = 3;
  static const _kMomentsTab = 4;
  static const _kMeTab = 5;

  /// Slow HTTP fallback; realtime WS (when live) should own message badges.
  static const _pollInterval = Duration(seconds: 15);
  static const _pollIntervalWithRealtime = Duration(seconds: 45);

  /// Backup for missed Socket.IO `call:incoming` (Render WS flaps + OEM kills).
  /// Keep polling while signed-in even if the OS briefly pauses the app —
  /// Honor/Oppo/Xiaomi often pause mid-permission dialog or chat.
  static const _callPollInterval = Duration(seconds: 2);

  /// Friend add/accept while the process is alive, including the background.
  /// Slower than call polling so the trial API is not flooded.
  static const _friendAlertInterval = Duration(seconds: 15);

  int _index = 0;
  bool _messageSearch = false;
  String _messageQuery = '';
  final _messageSearchController = TextEditingController();
  final GlobalKey _chatPlusKey = GlobalKey();
  final GlobalKey<MessagesTabState> _messagesKey =
      GlobalKey<MessagesTabState>();
  final CatalogRepository _catalog = CatalogRepository();
  final SubCatalogRepository _subCatalog = SubCatalogRepository();
  final ShellBadgePoller _badgePoller = ShellBadgePoller();
  bool _demoStarted = false;
  bool _showOpsHub = false;

  /// In-shell OBIC AI (keeps bottom NavigationBar). Never push full-screen.
  ShellBadgeCounts _badges = const ShellBadgeCounts();
  DateTime? _lastSeenMomentsAt;
  Timer? _badgeTimer;
  Timer? _callPollTimer;
  Timer? _friendAlertTimer;
  StreamSubscription<Map<String, dynamic>>? _rtBadgeSub;
  StreamSubscription<Map<String, dynamic>>? _rtNotifSub;
  StreamSubscription<Map<String, dynamic>>? _rtCallSub;
  StreamSubscription<Map<String, dynamic>>? _rtCallEndedSub;
  bool _callBusy = false;
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _phoneGateOpen = false;

  /// Shell has already rebuilt for the current signed-in session.
  bool _shellSignedIn = false;

  /// User chose Activate later. They can look around; writes still open activation.
  bool _phoneDeferred = false;

  @override
  void initState() {
    super.initState();
    PhoneActivationLock.needsActivation = () {
      if (!mounted || !widget.authController.isAuthenticated) return false;
      return clientNeedsPhoneVerification(
        user: widget.authController.user,
        region: widget.regionController,
      );
    };
    PhoneActivationLock.isStaff = () {
      if (!mounted || !widget.authController.isAuthenticated) return false;
      return widget.authController.isStaffRole;
    };
    PhoneActivationLock.ask = () {
      if (!mounted || _phoneGateOpen) return;
      unawaited(_maybeOpenPhoneGate(force: true));
    };
    RealtimeClient.instance.start();
    DeviceAlerts.instance.attach(
      auth: widget.authController,
      onOpenChat: _openChatFromAlert,
      onOpenHref: _openHrefFromAlert,
      onAcceptCall: (payload) {
        unawaited(CallRingtone.instance.stop());
        CallRingController.instance.dismissIfCall(
          payload['callId']?.toString(),
        );
        unawaited(
          DeviceAlerts.instance.dismissIncomingCall(
            payload['callId']?.toString(),
          ),
        );
        unawaited(_acceptIncoming(payload));
      },
      onDeclineCall: (payload) {
        unawaited(CallRingtone.instance.stop());
        CallRingController.instance.dismissIfCall(
          payload['callId']?.toString(),
        );
        unawaited(
          DeviceAlerts.instance.dismissIncomingCall(
            payload['callId']?.toString(),
          ),
        );
        unawaited(_declineIncoming(payload));
      },
    );
    DeviceAlerts.instance.onIncomingWhileOpen = (payload) {
      if (!mounted) return;
      _onIncomingCall(payload);
    };
    unawaited(PushRegistrar.start(widget.authController));
    widget.authController.addListener(_onAuthChanged);
    widget.regionController.addListener(_onRegionChanged);
    ConnectivityService.instance.addListener(_onConnectivityChanged);
    AppForeground.instance.addListener(_onForegroundChanged);
    MessageSyncGate.instance.addListener(_onRealtimeChanged);
    _rtBadgeSub = RealtimeClient.instance.onBadgeHint.listen((payload) {
      if (!mounted || !widget.authController.isAuthenticated) return;
      if (!AppForeground.instance.isActive) return;
      // WeChat: open chat owns that thread — skip badge bump for it.
      final reason = payload['reason']?.toString();
      final convId = payload['conversationId']?.toString();
      if (reason == 'chat' && ActiveChatTracker.instance.isOpen(convId)) {
        return;
      }
      unawaited(_pollBadges());
    });
    _rtNotifSub = RealtimeClient.instance.onNotification.listen((payload) {
      if (!mounted || !widget.authController.isAuthenticated) return;
      final raw = payload['notification'];
      if (raw is! Map) return;
      final n = Map<String, dynamic>.from(raw);
      // Viewing that conversation — dismiss quietly; do not bump Me badge.
      if (ActiveChatTracker.instance.suppressesNotification(n)) {
        final id = n['id']?.toString();
        if (id != null && id.isNotEmpty) {
          unawaited(_ackOpenChatNotification(id));
        }
        return;
      }
      unawaited(_pollBadges());
      final kind = (n['kind'] ?? n['type'])?.toString() ?? '';
      if (kind != 'message' &&
          kind != 'friend_request' &&
          kind != 'friend_accepted' &&
          AppForeground.instance.isActive) {
        unawaited(AppSounds.instance.playNotification());
      }
    });
    _rtCallSub = RealtimeClient.instance.onCallIncoming.listen(_onIncomingCall);
    _rtCallEndedSub = RealtimeClient.instance.onCallEnded.listen((payload) {
      final id = payload['callId'] as String?;
      CallRingController.instance.dismissIfCall(id);
      unawaited(DeviceAlerts.instance.callEnded(payload));
    });
    _syncCatalogRegion();
    _badgePoller.onFriendAlerts = (alerts) {
      for (final alert in alerts) {
        unawaited(DeviceAlerts.instance.presentFriendAlert(alert));
      }
    };
    _startFriendAlertWatch();
    unawaited(_loadLastSeenMoments());
    _startBadgePolling();
    _startCallPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeOpenPhoneGate());
    });
    if (kDemoWalkthrough || kDemoShot.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_demoStarted || !mounted) return;
        _demoStarted = true;
        runDemoWalkthrough(
          context: context,
          setTab: (i) => _selectTab(i),
          authController: widget.authController,
          localeController: widget.localeController,
          catalog: _catalog,
          onShowOpsHub: () {
            if (mounted) setState(() => _showOpsHub = true);
          },
        );
      });
    }
  }

  @override
  void dispose() {
    PhoneActivationLock.needsActivation = null;
    PhoneActivationLock.isStaff = null;
    PhoneActivationLock.ask = null;
    _messageSearchController.dispose();
    _badgeTimer?.cancel();
    _callPollTimer?.cancel();
    _friendAlertTimer?.cancel();
    _rtBadgeSub?.cancel();
    _rtNotifSub?.cancel();
    _rtCallSub?.cancel();
    _rtCallEndedSub?.cancel();
    AppForeground.instance.removeListener(_onForegroundChanged);
    DeviceAlerts.instance.onIncomingWhileOpen = null;
    MessageSyncGate.instance.removeListener(_onRealtimeChanged);
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    widget.authController.removeListener(_onAuthChanged);
    widget.regionController.removeListener(_onRegionChanged);
    super.dispose();
  }

  Future<void> _ackOpenChatNotification(String id) async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      // Delete — mark-read would still leave a stub in Notifications inbox.
      await SocialApi().dismissNotification(accessToken: token, id: id);
    } catch (_) {}
  }

  void _onIncomingCall(Map<String, dynamic> payload) {
    if (!mounted || !widget.authController.isAuthenticated) return;
    if (_callBusy || CallRingController.instance.hasIncoming) return;
    final snap = Map<String, dynamic>.from(payload);
    if (!AppForeground.instance.isActive) {
      // Locked or background: system banner only. The full-screen ring
      // appears if they open the app before answering.
      unawaited(
        DeviceAlerts.instance.showIncomingCall(snap, foreground: false),
      );
      return;
    }
    _presentInAppRing(snap);
  }

  void _presentInAppRing(Map<String, dynamic> snap) {
    if (_callBusy || CallRingController.instance.hasIncoming) return;
    CallRingController.instance.present(
      snap,
      onAccept: () => _acceptIncoming(snap),
      onDecline: () => _declineIncoming(snap),
    );
    unawaited(
      DeviceAlerts.instance.showIncomingCall(snap, foreground: true),
    );
  }

  void _openHrefFromAlert(String href, String title) {
    if (!mounted) return;
    unawaited(
      openFriendAlertHref(
        context: context,
        auth: widget.authController,
        href: href,
        title: title,
      ),
    );
  }

  void _openChatFromAlert(String conversationId, String title) {
    if (!mounted || conversationId.isEmpty) return;
    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            authController: widget.authController,
            threadId: conversationId,
            title: title.trim().isEmpty ? 'OBIC' : title.trim(),
          ),
        ),
      ),
    );
  }

  Future<void> _acceptIncoming(Map<String, dynamic> payload) async {
    if (_callBusy) return;
    _callBusy = true;
    final earlyId = payload['callId']?.toString();
    unawaited(CallRingtone.instance.stop());
    unawaited(DeviceAlerts.instance.dismissIncomingCall(earlyId));
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final callId = payload['callId'] as String?;
    final conversationId = payload['conversationId'] as String?;
    final fromName = (payload['fromName'] as String?)?.trim().isNotEmpty == true
        ? payload['fromName'] as String
        : 'OBIC';
    final fromAvatar = payload['fromAvatarUrl'] as String?;
    final isGroup =
        payload['isGroup'] == true || payload['conversationKind'] == 'group';
    final groupTitle = (payload['conversationTitle'] as String?)?.trim();
    final displayName = isGroup
        ? ((groupTitle != null && groupTitle.isNotEmpty)
              ? groupTitle
              : (ar ? 'مجموعة' : 'Group'))
        : fromName;
    final video = (payload['mode'] as String?) == 'video';
    // Push before any await so Accept lands on the call UI in the same frame
    // the ring overlay is removed.
    final joinCompleter = Completer<ObicCallJoin>();
    final box = CompleterBox();
    CallFloatController.instance.show(
      ObicCallScreen(
        peerName: displayName,
        peerSubtitle: isGroup
            ? (ar ? 'من $fromName' : 'From $fromName')
            : 'OBIC',
        avatarUrl: isGroup ? null : fromAvatar,
        mode: video ? ObicCallMode.video : ObicCallMode.voice,
        arabic: ar,
        isGroup: isGroup,
        callId: callId,
        pendingJoin: joinCompleter.future,
        onHangup: () async {
          if (callId == null) return;
          final t = await widget.authController.accessToken();
          if (t == null) return;
          try {
            if (isGroup) {
              await CallsApi().leaveCall(accessToken: t, callId: callId);
            } else {
              await CallsApi().endCall(accessToken: t, callId: callId);
            }
          } catch (_) {}
        },
        accessToken: widget.authController.ensureAccessToken,
      ),
      title: displayName,
      box: box,
    );
    final finishFuture = box.future;
    ObicCallJoin? join;
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null || callId == null) {
        throw StateError(ar ? 'المكالمة غير متاحة' : 'Call unavailable');
      }
      final joinMap = await CallsApi().mintToken(
        accessToken: token,
        callId: callId,
      );
      join = ObicCallJoin.fromJson(joinMap);
      if (!joinCompleter.isCompleted) joinCompleter.complete(join);
    } catch (e) {
      if (!joinCompleter.isCompleted) joinCompleter.completeError(e);
    }
    final finish = await finishFuture;
    if (join != null && !isGroup && conversationId != null) {
      await _postIncomingCallRecord(
        conversationId: conversationId,
        mode: join.mode,
        finish: finish,
        outcome: null,
      );
    }
    _callBusy = false;
  }

  Future<void> _declineIncoming(Map<String, dynamic> payload) async {
    final callId = payload['callId'] as String?;
    unawaited(CallRingtone.instance.stop());
    unawaited(DeviceAlerts.instance.dismissIncomingCall(callId));
    if (callId == null) return;
    final isGroup =
        payload['isGroup'] == true || payload['conversationKind'] == 'group';
    final conversationId = payload['conversationId'] as String?;
    final mode = (payload['mode'] as String?) == 'video'
        ? ObicCallMode.video
        : ObicCallMode.voice;
    // Group: declining dismisses only this device — others keep ringing.
    if (isGroup) return;
    final token = await widget.authController.accessToken();
    if (token == null) return;
    try {
      await CallsApi().endCall(accessToken: token, callId: callId);
    } catch (_) {}
    if (conversationId != null) {
      await _postIncomingCallRecord(
        conversationId: conversationId,
        mode: mode,
        finish: null,
        outcome: ObicCallRecordOutcome.missed,
      );
    }
  }

  Future<void> _postIncomingCallRecord({
    required String conversationId,
    required ObicCallMode mode,
    required ObicCallFinish? finish,
    required ObicCallRecordOutcome? outcome,
  }) async {
    if (finish?.joinFailed == true && outcome == null) return;
    final myId = widget.authController.user?.id;
    final resolved =
        outcome ??
        ((finish != null && finish.connected && finish.durationSeconds > 0)
            ? ObicCallRecordOutcome.ended
            : ObicCallRecordOutcome.cancelled);
    final body = buildCallRecordBody(
      ObicCallRecord(
        mode: mode == ObicCallMode.video
            ? ObicCallRecordMode.video
            : ObicCallRecordMode.voice,
        outcome: resolved,
        durationSeconds: resolved == ObicCallRecordOutcome.ended
            ? (finish?.durationSeconds ?? 0)
            : 0,
        endedByUserId: myId,
        side: ObicCallRecordSide.incoming,
      ),
    );
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      await SocialApi().sendMessage(
        accessToken: token,
        threadId: conversationId,
        body: body,
      );
    } catch (_) {}
  }

  void _onForegroundChanged() {
    if (AppForeground.instance.isActive) {
      unawaited(_swapSystemRingToFullScreen());
      unawaited(_pollBadges());
      _startBadgePolling();
      // Re-show gate after app reopen / resume until verified.
      unawaited(_maybeOpenPhoneGate());
    } else {
      _badgeTimer?.cancel();
      _badgeTimer = null;
      _handRingToSystemBanner();
      // Do NOT cancel call poll — Chinese OEMs pause apps during permission
      // dialogs / split-screen; HTTP poll is the reliable ring path.
    }
    if (widget.authController.isAuthenticated) {
      _startCallPolling();
    }
  }

  void _handRingToSystemBanner() {
    if (_callBusy) return;
    final ringing = CallRingController.instance.payload;
    if (ringing == null) return;
    final snap = Map<String, dynamic>.from(ringing);
    CallRingController.instance.clear();
    unawaited(DeviceAlerts.instance.showIncomingCall(snap, foreground: false));
  }

  Future<void> _swapSystemRingToFullScreen() async {
    if (!mounted || _callBusy || CallRingController.instance.hasIncoming) return;
    final native = await DeviceAlerts.instance.takeSystemRing();
    if (!mounted || native == null) return;
    if (_callBusy || CallRingController.instance.hasIncoming) return;
    if (!AppForeground.instance.isActive) {
      unawaited(
        DeviceAlerts.instance.showIncomingCall(native, foreground: false),
      );
      return;
    }
    _presentInAppRing(native);
  }

  void _onRealtimeChanged() => _startBadgePolling();

  void _onConnectivityChanged() {
    if (!ConnectivityService.instance.isOnline) return;
    unawaited(_onBackOnline());
  }

  Future<void> _onBackOnline() async {
    if (!mounted || !widget.authController.isAuthenticated) return;
    await OutboundMessageQueue.instance.flush(
      api: SocialApi(),
      auth: widget.authController,
    );
    // Resume WS after offline queue flush (token may have refreshed).
    final token = await widget.authController.ensureAccessToken();
    if (token != null) {
      unawaited(RealtimeClient.instance.bindAuth(token));
    }
    if (!mounted) return;
    unawaited(_pollBadges());
  }

  void _onRegionChanged() => _syncCatalogRegion();

  void _syncCatalogRegion() {
    _catalog.setRegion(
      countryCode: widget.regionController.countryCode,
      cityName: widget.regionController.cityName,
    );
    _subCatalog.setRegion(
      countryCode: widget.regionController.countryCode,
      cityName: widget.regionController.cityName,
    );
  }

  Future<void> _loadLastSeenMoments() async {
    final seen = await readLastSeenMomentsAt();
    if (mounted) setState(() => _lastSeenMomentsAt = seen);
  }

  void _onAuthChanged() {
    if (!widget.authController.isAuthenticated) {
      _shellSignedIn = false;
      _badgePoller.clear();
      _friendAlertTimer?.cancel();
      _friendAlertTimer = null;
      _callPollTimer?.cancel();
      _callPollTimer = null;
      CallRingController.instance.clear();
      if (mounted) {
        setState(() {
          _badges = const ShellBadgeCounts();
        });
      }
      return;
    }
    if (!_shellSignedIn && mounted) {
      _shellSignedIn = true;
      setState(() {});
    }
    unawaited(_pollBadges());
    _startFriendAlertWatch();
    _startCallPolling();
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) unawaited(_pollBadges());
    });
    // Login pops itself in this same turn. Opening the gate now pushes a
    // route on top, and that route swallows the pop — the session is saved
    // but the user stays on Login until they press back.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.authController.isAuthenticated) return;
      unawaited(_maybeOpenPhoneGate());
    });
  }

  bool get _needsChinaPhone {
    return clientNeedsPhoneVerification(
      user: widget.authController.user,
      region: widget.regionController,
    );
  }

  bool get _needsChinaEmail {
    return clientNeedsEmailVerification(
      user: widget.authController.user,
      region: widget.regionController,
    );
  }

  bool get _needsChinaVerification => _needsChinaEmail || _needsChinaPhone;

  /// Customers see the wall on login. Employees do not — chat stays open.
  bool get _blocksEntryUntilActivation => clientRequiresEntryActivation(
        user: widget.authController.user,
        region: widget.regionController,
      );

  Future<void> _maybeOpenPhoneGate({bool force = false}) async {
    if (!mounted || !widget.authController.isAuthenticated) return;
    if (!_needsChinaVerification) {
      if (_phoneDeferred) setState(() => _phoneDeferred = false);
      return;
    }
    // A booking, clock-in, save, or post passes force and still opens the wall.
    if (!force && !_blocksEntryUntilActivation) return;
    if (_phoneDeferred && !force) return;
    if (_phoneGateOpen && !force) return;
    await _openPhoneGate();
  }

  Future<void> _openPhoneGate() async {
    if (!mounted || _phoneGateOpen) return;
    _phoneGateOpen = true;
    try {
      await openChinaVerificationGates(
        context: context,
        auth: widget.authController,
        localeController: widget.localeController,
        themeModeController: widget.themeModeController,
        region: widget.regionController,
      );
    } finally {
      _phoneGateOpen = false;
    }
    if (!mounted) return;
    // Later leaves every tab open. Writes still ask for the number.
    if (_needsChinaPhone && !_needsChinaEmail) {
      setState(() => _phoneDeferred = true);
      return;
    }
    if (_phoneDeferred) setState(() => _phoneDeferred = false);
    if (!_needsChinaPhone) {
      unawaited(
        OutboundMessageQueue.instance.flush(
          api: SocialApi(),
          auth: widget.authController,
        ),
      );
    }
    if (!_needsChinaVerification && _index != 0) {
      setState(() => _index = 0);
    }
  }

  void _startBadgePolling() {
    _badgeTimer?.cancel();
    if (!AppForeground.instance.isActive) return;
    unawaited(_pollBadges());
    final interval = MessageSyncGate.instance.realtimeLive
        ? _pollIntervalWithRealtime
        : _pollInterval;
    _badgeTimer = Timer.periodic(interval, (_) => unawaited(_pollBadges()));
  }

  void _startCallPolling() {
    _callPollTimer?.cancel();
    if (!widget.authController.isAuthenticated) return;
    // Keep polling while signed-in even if OS reports paused (OEM battery mgrs).
    unawaited(_pollIncomingCalls());
    _callPollTimer = Timer.periodic(
      _callPollInterval,
      (_) => unawaited(_pollIncomingCalls()),
    );
  }

  Future<void> _pollIncomingCalls() async {
    if (!mounted || _callBusy || CallRingController.instance.hasIncoming) {
      return;
    }
    if (!widget.authController.isAuthenticated) return;
    if (ConnectivityService.instance.isOffline) return;
    try {
      final token = await widget.authController.accessToken();
      if (token == null || !mounted) return;
      final list = await CallsApi().listIncoming(token);
      if (!mounted || _callBusy || CallRingController.instance.hasIncoming) {
        return;
      }
      if (list.isEmpty) return;
      // Newest first — API returns insertion order; take last as latest.
      final payload = list.last;
      _onIncomingCall(payload);
    } catch (_) {}
  }

  Future<void> _pollBadges() async {
    if (!mounted) return;
    if (!AppForeground.instance.isActive) return;
    if (!widget.authController.isAuthenticated) {
      _badgePoller.clear();
      if (_badges != const ShellBadgeCounts()) {
        setState(() => _badges = const ShellBadgeCounts());
      }
      return;
    }
    // Offline: keep last known badge counts (WeChat-style).
    if (ConnectivityService.instance.isOffline) return;
    final next = await _badgePoller.poll(
      auth: widget.authController,
      momentsTabActive: _index == _kMomentsTab,
    );
    if (!mounted) return;
    if (!widget.authController.isAuthenticated) {
      _badgePoller.clear();
      if (_badges != const ShellBadgeCounts()) {
        setState(() => _badges = const ShellBadgeCounts());
      }
      return;
    }
    if (next != _badges) {
      setState(() => _badges = next);
    }
    unawaited(DeviceAlerts.instance.setBadge(next.messagesUnread));
  }

  void _setMessagesUnread(int n) {
    if (!mounted) return;
    // Guests must never accumulate message badges from demo/list callbacks.
    final next = widget.authController.isAuthenticated ? n : 0;
    if (_badges.messagesUnread == next) return;
    unawaited(DeviceAlerts.instance.setBadge(next));
    setState(
      () => _badges = ShellBadgeCounts(
        messagesUnread: next,
        momentsUnread: _badges.momentsUnread,
        pendingFriends: _badges.pendingFriends,
        unreadNotifications: _badges.unreadNotifications,
      ),
    );
  }

  Future<void> _selectTab(int i) async {
    if (widget.authController.isAuthenticated &&
        _needsChinaEmail &&
        _blocksEntryUntilActivation) {
      await _openPhoneGate();
      if (!mounted || _needsChinaEmail) return;
    }
    setState(() => _index = i);
    if (i == _kMomentsTab) {
      await _badgePoller.markMomentsSeen();
      final seen = await readLastSeenMomentsAt();
      if (!mounted) return;
      setState(() {
        _lastSeenMomentsAt = seen;
        _badges = ShellBadgeCounts(
          messagesUnread: _badges.messagesUnread,
          momentsUnread: 0,
          pendingFriends: _badges.pendingFriends,
          unreadNotifications: _badges.unreadNotifications,
        );
      });
    }
    if (i == _kMessagesTab) {
      // Refresh immediately so tab badge matches mark-read from open threads.
      unawaited(_pollBadges());
    }
  }

  void _startFriendAlertWatch() {
    _friendAlertTimer?.cancel();
    if (!widget.authController.isAuthenticated) {
      _friendAlertTimer = null;
      return;
    }
    unawaited(_pollFriendAlerts());
    _friendAlertTimer = Timer.periodic(
      _friendAlertInterval,
      (_) => unawaited(_pollFriendAlerts()),
    );
  }

  /// Existing friend-request list. Works while open or backgrounded.
  Future<void> _pollFriendAlerts() async {
    if (!mounted || !widget.authController.isAuthenticated) return;
    if (ConnectivityService.instance.isOffline) return;
    final token = await widget.authController.accessToken();
    if (token == null || !mounted) return;
    try {
      await _badgePoller.pollFriendAlerts(token);
    } catch (_) {}
  }

  Future<void> _refreshMeBadges() async => _pollBadges();

  Future<void> _openObicAi() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    if (_needsChinaEmail && _blocksEntryUntilActivation) {
      await _openPhoneGate();
      if (!mounted || _needsChinaEmail) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ObicAiScreen(authController: widget.authController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showOpsHub) {
      return const OpsHubScreen();
    }

    final l10n = AppLocalizations.of(context);
    final auth = widget.authController;
    final locale = widget.localeController;
    final signedIn = auth.isAuthenticated;
    final messagesUnread = signedIn ? _badges.messagesUnread : 0;
    final meTabBadge = signedIn ? _badges.meTabBadge : 0;
    final pendingFriends = signedIn ? _badges.pendingFriends : 0;
    final unreadNotifications = signedIn ? _badges.unreadNotifications : 0;

    final pages = [
      HomeTab(
        authController: auth,
        localeController: locale,
        regionController: widget.regionController,
        catalogRepository: _catalog,
        subCatalogRepository: _subCatalog,
        onSeeAllServices: () => unawaited(_selectTab(_kServicesTab)),
      ),
      ServicesTab(
        authController: auth,
        localeController: locale,
        catalogRepository: _catalog,
      ),
      MessagesTab(
        key: _messagesKey,
        authController: auth,
        isActive: _index == _kMessagesTab,
        onUnreadTotalChanged: _setMessagesUnread,
        listQuery: _messageQuery,
      ),
      FriendsScreen(
        authController: auth,
        embedded: true,
        isActive: _index == _kContactsTab,
      ),
      DiscoverScreen(
        authController: auth,
        lastSeenMomentsAt: _lastSeenMomentsAt,
        isActive: _index == _kMomentsTab,
        onMomentsOpened: () {
          unawaited(_badgePoller.markMomentsSeen());
          unawaited(_pollBadges());
        },
      ),
      MeTab(
        localeController: locale,
        themeModeController: widget.themeModeController,
        authController: auth,
        regionController: widget.regionController,
        pendingFriendRequests: pendingFriends,
        unreadNotifications: unreadNotifications,
        onBadgeRefresh: _refreshMeBadges,
        onOpenServices: () => unawaited(_selectTab(_kServicesTab)),
      ),
    ];

    final showAppBar = _index == _kMessagesTab || _index == _kMeTab;
    final onMessages = _index == _kMessagesTab;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: ObicColors.scaffoldOf(context),
            appBar: showAppBar
                ? AppBar(
                    title: onMessages && _messageSearch
                        ? TextField(
                            controller: _messageSearchController,
                            autofocus: true,
                            style: TextStyle(color: ObicColors.inkOf(context)),
                            cursorColor: ObicColors.blue,
                            textDirection: inputTextDirection(
                              _messageSearchController.text,
                              Directionality.of(context),
                            ),
                            textAlign: TextAlign.start,
                            decoration: InputDecoration(
                              hintText: l10n.messagesSearchHint,
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (value) =>
                                setState(() => _messageQuery = value),
                          )
                        : Text(onMessages ? l10n.messagesTitle : l10n.meTitle),
                    backgroundColor: ObicColors.surfaceOf(context),
                    foregroundColor: ObicColors.inkOf(context),
                    surfaceTintColor: Colors.transparent,
                    actions: onMessages
                        ? [
                            if (_messageSearch)
                              IconButton(
                                onPressed: () => setState(() {
                                  _messageSearch = false;
                                  _messageQuery = '';
                                  _messageSearchController.clear();
                                }),
                                icon: const Icon(Icons.close_rounded),
                              )
                            else ...[
                              IconButton(
                                onPressed: () =>
                                    setState(() => _messageSearch = true),
                                icon: const Icon(Icons.search_rounded),
                              ),
                              PopupMenuButton<String>(
                                tooltip: l10n.messagesMarkAllRead,
                                icon: const Icon(Icons.more_horiz_rounded),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'read':
                                      unawaited(
                                        _messagesKey.currentState
                                            ?.markAllRead(),
                                      );
                                    default:
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'read',
                                    child: Text(l10n.messagesMarkAllRead),
                                  ),
                                ],
                              ),
                              IconButton(
                                key: _chatPlusKey,
                                onPressed: () {
                                  final box =
                                      _chatPlusKey.currentContext
                                              ?.findRenderObject()
                                          as RenderBox?;
                                  if (box == null) return;
                                  final offset = box.localToGlobal(Offset.zero);
                                  final size = box.size;
                                  showChatPlusMenu(
                                    context,
                                    authController: auth,
                                    position: RelativeRect.fromLTRB(
                                      offset.dx,
                                      offset.dy + size.height,
                                      offset.dx + size.width,
                                      offset.dy,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ]
                        : null,
                  )
                : null,
            body: Column(
              children: [
                if (_phoneDeferred && _needsChinaPhone)
                  AnnotatedRegion<SystemUiOverlayStyle>(
                    value: const SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.light,
                      statusBarBrightness: Brightness.dark,
                    ),
                    child: Material(
                      color: ObicColors.blue,
                      child: SafeArea(
                        top: !showAppBar,
                        bottom: false,
                        child: InkWell(
                          onTap: () =>
                              unawaited(_maybeOpenPhoneGate(force: true)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone_android_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.phoneVerifyLocked,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.phoneVerifyActivate,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: _phoneDeferred && _needsChinaPhone && !showAppBar,
                    child: IndexedStack(index: _index, children: pages),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MusicMiniPlayer(),
                DecoratedBox(
              decoration: BoxDecoration(
                color: ObicColors.surfaceOf(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(ObicElevation.radiusLg),
                ),
                border: Border(
                  top: BorderSide(
                    color: ObicColors.lineOf(context).withValues(alpha: 0.65),
                  ),
                ),
                boxShadow: ObicColors.isDark(context)
                    ? const <BoxShadow>[]
                    : ObicElevation.level3,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(ObicElevation.radiusLg),
                ),
                child: GlassContainer(
                  useOwnLayer: true,
                  quality: GlassQuality.standard,
                  child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  selectedIndex: _index,
                  onDestinationSelected: (i) => unawaited(_selectTab(i)),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: l10n.tabHome,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.grid_view_outlined),
                      selectedIcon: const Icon(Icons.grid_view_rounded),
                      label: l10n.tabServices,
                    ),
                    NavigationDestination(
                      icon: ObicNavBadgeIcon(
                        unread: messagesUnread,
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                      selectedIcon: ObicNavBadgeIcon(
                        unread: messagesUnread,
                        icon: const Icon(Icons.chat_bubble_rounded),
                      ),
                      label: l10n.tabMessages,
                    ),
                    NavigationDestination(
                      icon: ObicNavBadgeIcon(
                        unread: pendingFriends,
                        icon: const Icon(Icons.contacts_outlined),
                      ),
                      selectedIcon: ObicNavBadgeIcon(
                        unread: pendingFriends,
                        icon: const Icon(Icons.contacts),
                      ),
                      label: l10n.tabContacts,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.explore_outlined),
                      selectedIcon: const Icon(Icons.explore),
                      label: l10n.tabDiscover,
                    ),
                    NavigationDestination(
                      icon: ObicNavBadgeIcon(
                        unread: meTabBadge,
                        icon: const Icon(Icons.person_outline),
                      ),
                      selectedIcon: ObicNavBadgeIcon(
                        unread: meTabBadge,
                        icon: const Icon(Icons.person_rounded),
                      ),
                      label: l10n.tabMe,
                    ),
                  ],
                ),
                ),
              ),
            ),
              ],
            ),
          ),
          ObicAiFloatingBubbleOverlay(
            onTap: () => unawaited(_openObicAi()),
            tooltip: l10n.obicAiTitle,
          ),
        ],
      ),
    );
  }
}
