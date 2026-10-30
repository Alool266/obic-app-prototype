// Made by Dr Ali
// Chat screen — WeChat-style + panel (GPS share, real /v1/uploads, calls).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/active_chat_tracker.dart';
import '../../core/api_errors.dart';
import '../../core/app_foreground.dart';
import '../../core/connectivity_service.dart';
import '../../core/media_pick.dart';
import '../../core/message_sync_gate.dart';
import '../../core/obic_org.dart';
import '../../core/obic_phrases.dart';
import '../../core/offline_cache_store.dart';
import '../../core/phone_activation_lock.dart';
import '../../core/realtime_client.dart';
import '../../core/region_controller.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/wechat_media_actions.dart';
import '../admin/admin_api.dart';
import '../ai/ai_api.dart';
import '../ai/translation_cache.dart';
import '../auth/auth_api.dart';
import '../ai/obic_ai_avatar.dart';
import '../auth/auth_controller.dart';
import '../me/chats_settings_screen.dart';
import '../friends/contact_profile_screen.dart';
import '../moments/moment_avatar.dart';
import '../scan/image_translate_screen.dart';
import '../social/social_api.dart';
import 'call_float.dart';
import 'call_screen.dart';
import 'calls_api.dart';
import 'group_call_picker.dart';
import 'chat_attach_helpers.dart';
import 'chat_call_body.dart';
import 'obic_stickers.dart';
import 'chat_draft_store.dart';
import 'chat_favorites_sheet.dart';
import 'chat_day_separator.dart';
import 'chat_favorites_store.dart';
import 'chat_hidden_store.dart';
import 'chat_in_thread_search.dart';
import 'chat_location_body.dart';
import 'unread_count.dart';
import 'chat_location_picker.dart';
import 'chat_media_bubbles.dart';
import 'chat_voice_recorder.dart';
import 'group_avatar_collage.dart';
import 'group_info_screen.dart';
import 'live_location_screen.dart';
import 'voice_text_store.dart';
import 'message_search.dart';
import 'outbound_message_queue.dart';
import 'support_handoff_intent.dart';
import 'support_handoff_sheet.dart';
import 'add_staff_sheet.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.authController,
    required this.threadId,
    required this.title,
    this.initialKind,
    this.demoOpenAttachPanel = false,
    this.demoOpenMessageMenu = false,
    this.focusMessageId,
    this.onThreadOpened,
  });

  final AuthController authController;
  final String threadId;
  final String title;

  /// Known thread kind when opening (support/order) so auto-reply burst
  /// works before listThreads meta returns.
  final String? initialKind;

  /// Capture helper: open the + attach panel after load (DEMO_SHOT=chat_panel).
  final bool demoOpenAttachPanel;

  /// Capture helper: open WeChat long-press message actions (DEMO_SHOT=chat_menu).
  final bool demoOpenMessageMenu;

  /// Message to bring on screen when it is already loaded (search hit).
  final String? focusMessageId;

  /// Fired after first successful messages load (API marks thread read).
  final VoidCallback? onThreadOpened;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = SocialApi();
  final _aiApi = AiApi();
  final _callsApi = CallsApi();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final GlobalKey _focusMessageKey = GlobalKey();
  int _focusEpoch = 0;
  bool _focusDone = false;
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _participants = [];
  late String _kind = widget.initialKind ?? 'direct';
  late String _threadTitle = widget.title;
  String? _handoffSummary;
  bool _threadMuted = false;
  String? _orderId;
  String? _orderStatus;

  /// Order preferredBranch (for Yiwu Secretary status ACL).
  String? _preferredBranch;
  bool _aiAutoReplyEnabled = true;
  bool _requestStaffBusy = false;
  bool _statusBusy = false;
  bool _loading = true;
  bool _sending = false;
  bool _panelOpen = false;

  /// Bumps on each [_load] so a stale poll cannot wipe a newer send/append.
  int _loadSeq = 0;
  Timer? _autoReplyBurst;

  /// WeChat hold-to-talk mode (mic toggles composer).
  bool _voiceMode = false;
  String? _error;
  String _pendingAttachKind = 'none';
  String? _pendingAttachName;

  /// Local file path until upload completes (pending bubble / offline queue).
  String? _pendingAttachPath;
  String? _pendingBodyOverride;

  /// WeChat quote/reply preview above the input.
  Map<String, dynamic>? _quoted;

  /// WeChat multi-select mode.
  bool _selectMode = false;
  final Set<String> _selectedIds = {};
  Timer? _pollTimer;

  /// Idle HTTP poll — pauses in background; slows when WS realtime is live.
  static const _pollInterval = Duration(seconds: 6);
  static const _pollIntervalWithRealtime = Duration(seconds: 40);
  StreamSubscription<Map<String, dynamic>>? _rtMsgSub;
  StreamSubscription<Map<String, dynamic>>? _rtNotifSub;
  StreamSubscription<Map<String, dynamic>>? _liveSub;
  int _liveSharers = 0;
  Map<String, dynamic>? _activeGroupCall;
  final Map<String, VoiceTextMemory> _voiceText = {};
  final Set<String> _voiceBusy = {};
  final Set<String> _voiceTranslated = {};
  final Map<String, String> _voiceNote = {};
  bool _openedNotified = false;

  /// messageId → translation (WeChat-style; cached, non-blocking).
  final Map<String, String> _translations = {};
  final Set<String> _translatingIds = {};
  final Set<String> _translationHidden = {};
  bool _enterToSend = false;
  bool _confirmDelete = true;
  final _searchInput = TextEditingController();
  bool _searchOpen = false;
  ChatSearchFilter _searchFilter = ChatSearchFilter.all;
  List<ChatSearchHit> _searchHits = [];
  int _searchHitIndex = 0;
  List<Map<String, dynamic>> _searchCache = [];
  String? _jumpMessageId;
  final Set<String> _hiddenIds = {};
  Future<void>? _unreadSnap;
  bool _entryUnreadReady = false;
  int _entryUnread = 0;
  String? _firstUnreadId;
  bool _searchTyped = false;

  bool get _isOrder => _kind == 'order';

  bool get _isSupportOrOrder => _kind == 'support' || _kind == 'order';

  /// Yiwu: Secretary (+ SuperAdmin). Other branches: any staff role (server still checks assignee).
  bool get _canUpdateOrderStatus {
    if (!widget.authController.isStaffRole) return false;
    final u = widget.authController.user;
    if (u == null) return false;
    if (widget.authController.isSuperAdmin) return true;
    if (!isYiwuRequestBranch(_preferredBranch)) {
      // Non-Yiwu: show chips for staff; API enforces assignee.
      return true;
    }
    return isYiwuSecretary(
      role: u.role,
      staffTitle: u.staffTitle,
      branchLabel: u.branchLabel,
      email: u.email,
    );
  }

  bool get _showAddPeople {
    if (!widget.authController.isStaffRole) return false;
    return _isSupportOrOrder;
  }

  bool get _showTalkToStaff {
    if (widget.authController.isStaffRole) return false;
    if (!_isSupportOrOrder) return false;
    // Handed off (AI paused by staff reply or prior request) → hide.
    return _aiAutoReplyEnabled;
  }

  /// Selected app language. The secretary summary follows this, including French.
  String get _aiLocaleCode {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'ar' || code == 'zh' || code == 'fr') return code;
    return 'en';
  }

  String _statusText(AppLocalizations l10n, String? status) {
    switch (status) {
      case 'Assigned':
        return l10n.statusAssigned;
      case 'InProgress':
        return l10n.statusInProgress;
      case 'WaitingCustomer':
        return l10n.statusWaitingCustomer;
      case 'Completed':
        return l10n.statusCompleted;
      case 'Cancelled':
        return l10n.statusCancelled;
      default:
        return l10n.statusSubmitted;
    }
  }

  /// Composer direction follows typed script so Arabic ؟ / caret stay correct.
  TextDirection get _composerDirection {
    final text = _input.text;
    if (text.trim().isEmpty) {
      return _composerDirCache ?? Directionality.of(context);
    }
    return _composerDirCache ?? chatTextDirection(text);
  }

  Future<void> _setOrderStatus(String status) async {
    final orderId = _orderId;
    if (orderId == null || _statusBusy) return;
    if (!_canUpdateOrderStatus) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).errorOnlySecretaryCanUpdateStatus,
          ),
        ),
      );
      return;
    }
    setState(() => _statusBusy = true);
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      await AdminApi().updateOrder(
        accessToken: token,
        orderId: orderId,
        status: status,
      );
      if (!mounted) return;
      setState(() => _orderStatus = status);
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyErr(e))));
    } finally {
      if (mounted) setState(() => _statusBusy = false);
    }
  }

  Future<void> _requestStaff({
    String? prefillOrderRef,
    String? prefillServiceKey,
  }) async {
    if (_requestStaffBusy || !_showTalkToStaff) return;
    if (ConnectivityService.instance.isOffline) {
      _toast(offlineNeedsNetworkMessage(AppLocalizations.of(context)));
      return;
    }

    // Order threads already have an assignee — skip the routing form.
    String? branch;
    String? serviceKey;
    String? orderRef = prefillOrderRef;
    String? note;
    if (_kind == 'support') {
      final form = await showSupportHandoffSheet(
        context,
        initialOrderRef: prefillOrderRef,
        initialServiceKey: prefillServiceKey,
      );
      if (!mounted || form == null) return; // Cancel → AI stays on
      branch = form.branch;
      serviceKey = form.serviceKey;
      orderRef = form.orderRef;
      note = form.note;
    }

    setState(() => _requestStaffBusy = true);
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      final result = await _api.requestStaff(
        accessToken: token,
        threadId: widget.threadId,
        locale: _aiLocaleCode,
        branch: branch,
        serviceKey: serviceKey,
        orderRef: orderRef,
        note: note,
      );
      if (!mounted) return;
      setState(() {
        _aiAutoReplyEnabled = result['aiAutoReplyEnabled'] != true;
        final parts = result['participants'];
        if (parts is List) {
          _participants = parts.whereType<Map<String, dynamic>>().toList();
        }
        final t = (result['title'] as String?)?.trim();
        if (t != null && t.isNotEmpty) _threadTitle = t;
        final hs = (result['handoffSummary'] as String?)?.trim();
        if (hs != null && hs.isNotEmpty) _handoffSummary = hs;
      });
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chatTalkToStaffDone)));
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyErr(e))));
    } finally {
      if (mounted) setState(() => _requestStaffBusy = false);
    }
  }

  /// Explicit `group`, or support/order with multiple other members.
  /// Never true for plain 1:1 `direct` (avoids me+peer collage looking like a group).
  bool get _isGroup => isWeChatGroupConversation(
    kind: _kind,
    otherParticipantCount: _otherParticipantCount,
  );

  int get _otherParticipantCount => countOtherParticipants(
    participants: _participants,
    myUserId: widget.authController.user?.id,
  );

  Map<String, dynamic>? get _peer {
    final myId = widget.authController.user?.id;
    for (final p in _participants) {
      if (p['userId'] != myId) return p;
    }
    return _participants.isNotEmpty ? _participants.first : null;
  }

  String get _peerName {
    final p = _peer;
    final n = p?['name'] as String?;
    if (n != null && n.trim().isNotEmpty) return n.trim();
    return widget.title;
  }

  /// AppBar title: peer name for 1:1; group/support/order title for multi-party.
  String get _headerTitle {
    if (_isGroup) {
      final t = _threadTitle.trim();
      if (t.isNotEmpty) return t;
      if (_kind == 'group') return 'Group';
      return widget.title;
    }
    return _peerName;
  }

  String? get _peerRole {
    final r = _peer?['role'] as String?;
    if (r == null || r.isEmpty) return null;
    return r;
  }

  String? get _peerAvatar => _peer?['avatarUrl'] as String?;

  Future<void> _postCallRecord({
    required ObicCallMode mode,
    required ObicCallFinish? finish,
    required bool asCaller,
    ObicCallRecordOutcome? forceOutcome,
    int people = 0,
  }) async {
    // Skip join-failure spam — user already saw the error on the call screen.
    if (finish?.joinFailed == true && forceOutcome == null) return;
    final myId = widget.authController.user?.id;
    final ObicCallRecordOutcome outcome;
    if (forceOutcome != null) {
      outcome = forceOutcome;
    } else if (finish != null &&
        finish.connected &&
        finish.durationSeconds > 0) {
      outcome = ObicCallRecordOutcome.ended;
    } else if (asCaller) {
      outcome = ObicCallRecordOutcome.cancelled;
    } else {
      outcome = ObicCallRecordOutcome.cancelled;
    }
    final body = buildCallRecordBody(
      ObicCallRecord(
        mode: mode == ObicCallMode.video
            ? ObicCallRecordMode.video
            : ObicCallRecordMode.voice,
        outcome: outcome,
        durationSeconds: outcome == ObicCallRecordOutcome.ended
            ? (finish?.durationSeconds ?? 0)
            : 0,
        endedByUserId: myId,
        people: people,
        side: asCaller
            ? ObicCallRecordSide.outgoing
            : ObicCallRecordSide.incoming,
      ),
    );
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      await _api.sendMessage(
        accessToken: token,
        threadId: widget.threadId,
        body: body,
        locale: _aiLocaleCode,
      );
    } catch (_) {}
  }

  void _openContactProfile({
    required String userId,
    String? name,
    String? avatarUrl,
    bool allowCall = true,
  }) {
    final me = widget.authController.user?.id;
    final directThread = !_isGroup && userId != me ? widget.threadId : null;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContactProfileScreen(
          authController: widget.authController,
          userId: userId,
          seedUser: {'name': ?name, 'avatarUrl': ?avatarUrl},
          threadId: directThread,
          allowCall: allowCall && userId != me,
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar() {
    if (_isGroup) {
      return GroupAvatarCollage(
        size: 34,
        members: _participants
            .map(
              (p) => (
                name: (p['name'] as String?) ?? '?',
                avatarUrl: p['avatarUrl'] as String?,
              ),
            )
            .toList(),
      );
    }
    if (_kind == 'support' && _peer == null) {
      return const ObicAiAvatar(size: 34, borderRadius: 8);
    }
    if (_kind == 'order' && _peer == null) {
      return CircleAvatar(
        radius: 17,
        backgroundColor: ObicColors.blueSoft,
        child: const Icon(
          Icons.receipt_long_rounded,
          color: ObicColors.blue,
          size: 18,
        ),
      );
    }
    return MomentAvatar(
      name: _peerName,
      avatarUrl: _peerAvatar,
      size: 34,
      borderRadius: 8,
    );
  }

  Future<void> _resendQueued(String localId) async {
    if (ConnectivityService.instance.isOffline) {
      showNoInternetBanner(context);
      return;
    }
    await OutboundMessageQueue.instance.retry(localId);
    if (!mounted) return;
    setState(() {});
    await OutboundMessageQueue.instance.flush(
      api: _api,
      auth: widget.authController,
    );
    if (mounted) setState(() {});
  }

  Future<void> _startCall({required bool video}) async {
    if (ConnectivityService.instance.isOffline) {
      await showNetworkUnavailableDialog(context);
      return;
    }
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    // Ask mic/camera BEFORE createCall so the ring is not wasted while the
    // OEM permission sheet is up (Honor/Oppo often pause the app here).
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (!mounted) return;
      await _explainCallPermission(
        obicPhrase(
          context,
          ar: 'يلزم إذن الميكروفون للمكالمات. افتح الإعدادات وفعّل الميكروفون لـ OBIC.',
          en: 'Microphone access is required for calls. Open Settings and enable Microphone for OBIC.',
          zh: '通话需要麦克风权限。请打开设置并为 OBIC 开启麦克风。',
        ),
      );
      return;
    }
    if (video) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        if (!mounted) return;
        await _explainCallPermission(
          obicPhrase(
            context,
            ar: 'يلزم إذن الكاميرا لمكالمات الفيديو. افتح الإعدادات وفعّل الكاميرا لـ OBIC.',
            en: 'Camera access is required for video calls. Open Settings and enable Camera for OBIC.',
            zh: '视频通话需要相机权限。请打开设置并为 OBIC 开启相机。',
          ),
        );
        return;
      }
    }
    List<String>? invite;
    if (_isGroup) {
      if (!mounted) return;
      invite = await pickGroupCallMembers(
        context,
        members: _participants,
        myUserId: widget.authController.user?.id,
        video: video,
      );
      if (invite == null || !mounted) return;
    }
    final token = await widget.authController.ensureAccessToken();
    if (token == null || !mounted) return;
    try {
      final joinMap = await _callsApi.createCall(
        accessToken: token,
        conversationId: widget.threadId,
        mode: video ? 'video' : 'voice',
        inviteUserIds: invite,
      );
      if (!mounted) return;
      final join = ObicCallJoin.fromJson(joinMap);
      final callId = join.callId;
      final isGroup = _isGroup || join.isGroup;
      final displayName = isGroup
          ? ((join.conversationTitle ?? widget.title).trim().isNotEmpty
                ? (join.conversationTitle ?? widget.title).trim()
                : (ar ? 'مجموعة' : 'Group'))
          : _peerName;
      final finish = await _hostCall(
        ObicCallScreen(
          peerName: displayName,
          peerSubtitle: isGroup
              ? obicPhrase(context, ar: 'مكالمة جماعية', en: 'Group call', zh: '群通话')
              : (_peerRole == null ? 'OBIC' : 'OBIC · $_peerRole'),
          avatarUrl: isGroup ? null : _peerAvatar,
          mode: join.mode,
          arabic: ar,
          isGroup: isGroup,
          callId: join.callId,
          join: join,
          members: _participants,
          onAddPeople: isGroup ? () => _inviteDuringCall(callId, video) : null,
          onHangup: () async {
            final t = await widget.authController.accessToken();
            if (t == null) return;
            try {
              if (isGroup) {
                await _callsApi.leaveCall(accessToken: t, callId: callId);
              } else {
                await _callsApi.endCall(accessToken: t, callId: callId);
              }
            } catch (_) {}
          },
          accessToken: widget.authController.ensureAccessToken,
        ),
        title: displayName,
      );
      if (!mounted) return;
      final people = isGroup ? (finish == null ? 0 : 1 + (invite?.length ?? 0)) : 0;
      await _postCallRecord(
        mode: join.mode,
        finish: finish,
        asCaller: true,
        people: people,
      );
      await _load(silent: true);
      unawaited(_refreshActiveCall());
    } catch (e) {
      if (!mounted) return;
      _toast(_friendlyErr(e));
    }
  }

  Future<ObicCallFinish?> _hostCall(Widget screen, {required String title}) {
    final box = CompleterBox();
    CallFloatController.instance.show(screen, title: title, box: box);
    return box.future;
  }

  Future<void> _explainCallPermission(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ObicColors.surfaceRaisedOf(ctx),
        title: Text(
          obicPhrase(ctx, ar: 'إذن مطلوب', en: 'Permission needed', zh: '需要权限'),
          style: TextStyle(color: ObicColors.inkOf(ctx)),
        ),
        content: Text(message, style: TextStyle(color: ObicColors.inkOf(ctx))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(obicPhrase(ctx, ar: 'إلغاء', en: 'Cancel', zh: '取消')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(openAppSettings());
            },
            child: Text(obicPhrase(ctx, ar: 'الإعدادات', en: 'Settings', zh: '设置')),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteDuringCall(String callId, bool video) async {
    final picked = await pickGroupCallMembers(
      context,
      members: _participants,
      myUserId: widget.authController.user?.id,
      video: video,
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    final token = await widget.authController.accessToken();
    if (token == null) return;
    try {
      await _callsApi.inviteCall(
        accessToken: token,
        callId: callId,
        userIds: picked,
      );
    } catch (e) {
      if (mounted) _toast(_friendlyErr(e));
    }
  }

  Future<void> _refreshActiveCall() async {
    if (!_isGroup) return;
    final token = await widget.authController.accessToken();
    if (token == null) return;
    try {
      final call = await _callsApi.activeCall(
        accessToken: token,
        conversationId: widget.threadId,
      );
      if (!mounted) return;
      setState(() => _activeGroupCall = call);
    } catch (_) {}
  }

  Future<void> _joinActiveCall() async {
    final call = _activeGroupCall;
    final callId = call?['callId']?.toString();
    if (callId == null || callId.isEmpty) return;
    final video = call?['mode'] == 'video';
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (!mounted) return;
      await _explainCallPermission(
        obicPhrase(
          context,
          ar: 'يلزم إذن الميكروفون للمكالمات. افتح الإعدادات وفعّل الميكروفون لـ OBIC.',
          en: 'Microphone access is required for calls. Open Settings and enable Microphone for OBIC.',
          zh: '通话需要麦克风权限。请打开设置并为 OBIC 开启麦克风。',
        ),
      );
      return;
    }
    if (video) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        if (!mounted) return;
        await _explainCallPermission(
          obicPhrase(
            context,
            ar: 'يلزم إذن الكاميرا لمكالمات الفيديو. افتح الإعدادات وفعّل الكاميرا لـ OBIC.',
            en: 'Camera access is required for video calls. Open Settings and enable Camera for OBIC.',
            zh: '视频通话需要相机权限。请打开设置并为 OBIC 开启相机。',
          ),
        );
        return;
      }
    }
    final token = await widget.authController.ensureAccessToken();
    if (token == null || !mounted) return;
    try {
      final joinMap = await _callsApi.mintToken(accessToken: token, callId: callId);
      if (!mounted) return;
      final join = ObicCallJoin.fromJson(joinMap);
      final title = (call?['title'] as String?)?.trim().isNotEmpty == true
          ? call!['title'] as String
          : widget.title;
      final finish = await _hostCall(
        ObicCallScreen(
          peerName: title,
          mode: join.mode,
          arabic: ar,
          isGroup: true,
          callId: callId,
          join: join,
          members: _participants,
          onAddPeople: () => _inviteDuringCall(callId, video),
          onHangup: () async {
            final t = await widget.authController.accessToken();
            if (t == null) return;
            try {
              await _callsApi.leaveCall(accessToken: t, callId: callId);
            } catch (_) {}
          },
          accessToken: widget.authController.ensureAccessToken,
        ),
        title: title,
      );
      if (!mounted) return;
      await _postCallRecord(
        mode: join.mode,
        finish: finish,
        asCaller: false,
        people: (call?['count'] as num?)?.toInt() ?? 0,
      );
      unawaited(_refreshActiveCall());
    } catch (e) {
      if (mounted) _toast(_friendlyErr(e));
    }
  }

  Future<void> _shareLocation() async {
    if (ConnectivityService.instance.isOffline) {
      _toast(offlineNeedsNetworkMessage(AppLocalizations.of(context)));
      return;
    }
    // WeChat-style: full-screen map → move/search/confirm, then send.
    final picked = await openLocationPicker(context);
    if (picked == null || !mounted) return;

    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || !mounted) return;
      final locale = Localizations.localeOf(context);
      final prefs = await SharedPreferences.getInstance();
      final savedRegion = prefs.getString(kRegionCountryKey);
      final chinaFirst =
          preferChinaMapLinks(
            localeLanguageCode: locale.languageCode,
            localeCountryCode: locale.countryCode,
            savedRegionCountry: savedRegion,
          ) ||
          picked.preferChina;
      final linkLocale = locale.languageCode == 'zh'
          ? 'zh'
          : locale.languageCode == 'ar'
          ? 'ar'
          : 'en';
      final body = buildLocationShareBody(
        label: picked.label,
        lat: picked.lat,
        lng: picked.lng,
        preferChina: chinaFirst,
        linkLocale: linkLocale,
      );
      await _api.sendMessage(
        accessToken: token,
        threadId: widget.threadId,
        body: body,
        locale: _aiLocaleCode,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        final ar2 = Localizations.localeOf(context).languageCode == 'ar';
        _toast(ar2 ? 'تعذّر إرسال الموقع' : 'Could not send location');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showContactCard() async {
    if (_isGroup) {
      _comingSoon('Contact card');
      return;
    }
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ChatContactSheet(
        name: _peerName,
        role: _peerRole,
        avatarUrl: _peerAvatar,
        arabic: ar,
        onVoiceCall: () {
          Navigator.pop(ctx);
          _startCall(video: false);
        },
        onVideoCall: () {
          Navigator.pop(ctx);
          _startCall(video: true);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // WeChat: while this thread is open, suppress notifs/badges for it.
    ActiveChatTracker.instance.enter(widget.threadId);
    _input.addListener(_onComposerChanged);
    OutboundMessageQueue.instance.addListener(_onQueueChanged);
    ConnectivityService.instance.addListener(_onNetChanged);
    AppForeground.instance.addListener(_onForegroundChanged);
    MessageSyncGate.instance.addListener(_onRealtimeChanged);
    unawaited(_prepareLocalThenHydrate());
    unawaited(_loadChatPrefs());
    unawaited(_restoreDraft());
    // Snapshot unread before listMessages marks the thread read.
    unawaited(_bindChatAfterUnreadSnapshot());
    _startPolling();
  }

  Future<void> _bindChatAfterUnreadSnapshot() async {
    await _ensureEntryUnread();
    if (!mounted) return;
    _rtMsgSub ??= RealtimeClient.instance.onChatMessage.listen(
      _onRealtimeChatMessage,
    );
    _rtNotifSub ??= RealtimeClient.instance.onNotification.listen(
      _onRealtimeNotification,
    );
    _liveSub ??= RealtimeClient.instance.onLiveLocation.listen((event) {
      if (event['conversationId']?.toString() != widget.threadId) return;
      final raw = event['shares'];
      if (raw is! List || !mounted) return;
      setState(() => _liveSharers = raw.length);
    });
    unawaited(_refreshLive());
    unawaited(_loadVoiceMemory());
    await _flushAndReload();
  }

  Future<void> _restoreDraft() async {
    final draft = await ChatDraftStore.instance.load(widget.threadId);
    if (!mounted || draft == null || draft.isEmpty) return;
    if (_input.text.isNotEmpty) return;
    _input.text = draft;
    _input.selection = TextSelection.collapsed(offset: draft.length);
  }

  void _persistDraft() {
    unawaited(ChatDraftStore.instance.save(widget.threadId, _input.text));
  }

  Future<void> _loadChatPrefs() async {
    final enter = await ChatSettingsPrefs.enterToSend();
    final confirm = await ChatSettingsPrefs.confirmDelete();
    if (!mounted) return;
    setState(() {
      _enterToSend = enter;
      _confirmDelete = confirm;
    });
  }

  TextDirection? _composerDirCache;

  void _onComposerChanged() {
    if (!mounted) return;
    _persistDraft();
    // Rebuild only when script direction flips (Arabic؟ / Latin caret).
    final next = _input.text.trim().isEmpty
        ? Directionality.of(context)
        : chatTextDirection(_input.text);
    if (next == _composerDirCache) return;
    setState(() => _composerDirCache = next);
  }

  void _onQueueChanged() {
    if (mounted) setState(() {});
  }

  void _onNetChanged() {
    if (!ConnectivityService.instance.isOnline) return;
    unawaited(_flushAndReload());
  }

  void _onForegroundChanged() {
    if (AppForeground.instance.isActive) {
      _startPolling();
      if (ConnectivityService.instance.isOnline) {
        unawaited(_flushAndReload());
      }
    } else {
      _stopPolling();
    }
  }

  /// [MessageSyncGate.realtimeLive] flipped by RealtimeClient — re-arm poll.
  void _onRealtimeChanged() => _startPolling();

  void _onRealtimeChatMessage(Map<String, dynamic> payload) {
    // Socket.IO may deliver non-String ids — never drop the row on a cast miss.
    final conversationId = payload['conversationId']?.toString();
    if (conversationId != widget.threadId) return;
    final raw = payload['message'];
    if (raw is! Map) return;
    final msg = Map<String, dynamic>.from(raw);
    final id = msg['id']?.toString();
    if (id != null && id.isNotEmpty) {
      msg['id'] = id;
      final existingIdx = _messages.indexWhere(
        (m) => m['id']?.toString() == id,
      );
      if (existingIdx >= 0) {
        // Recall / edit: replace in place (WeChat placeholder update).
        if (!mounted) return;
        setState(() {
          final next = [..._messages];
          next[existingIdx] = {...next[existingIdx], ...msg};
          _messages = next;
        });
        unawaited(
          OfflineCacheStore.instance.saveMessages(
            widget.threadId,
            _persistableMessages(_messages),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _messages = _dedupeById([..._messages, msg]);
      _error = null;
      _loading = false;
    });
    // Keep offline cache warm with live rows (don’t wipe queue/pending).
    unawaited(
      OfflineCacheStore.instance.saveMessages(
        widget.threadId,
        _persistableMessages(_messages),
      ),
    );
    _scrollToEnd();
    // WeChat: viewing this thread — mark read so badges/notifs stay quiet.
    // Open-chat mute must NOT block this UI append (only inbox/badge).
    unawaited(_markReadQuiet());
  }

  /// Inbox notifications for *this* open thread — remove (no Me-tab stub).
  void _onRealtimeNotification(Map<String, dynamic> payload) {
    final raw = payload['notification'];
    if (raw is! Map) return;
    final n = Map<String, dynamic>.from(raw);
    if (!ActiveChatTracker.instance.suppressesNotification(n)) return;
    final id = n['id']?.toString();
    if (id == null || id.isEmpty) return;
    unawaited(_dismissNotification(id));
  }

  Future<void> _markReadQuiet() async {
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      // listMessages marks the thread read server-side.
      await _api.listMessages(accessToken: token, threadId: widget.threadId);
      widget.onThreadOpened?.call();
    } catch (_) {}
  }

  Future<void> _dismissNotification(String id) async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await _api.dismissNotification(accessToken: token, id: id);
    } catch (_) {}
  }

  Future<void> _flushAndReload() async {
    await OutboundMessageQueue.instance.flush(
      api: _api,
      auth: widget.authController,
    );
    // Resume Socket.IO after flush (shell also does this on reconnect).
    final token = await widget.authController.ensureAccessToken();
    if (token != null) {
      unawaited(RealtimeClient.instance.bindAuth(token));
    }
    if (!mounted) return;
    await _load(silent: true);
  }

  bool get _textQueryActive =>
      _searchOpen &&
      _searchFilter == ChatSearchFilter.all &&
      _searchInput.text.trim().isNotEmpty;

  bool get _showingTypeFilter =>
      _searchOpen && _searchFilter != ChatSearchFilter.all;

  String get _activeSearchQuery =>
      _textQueryActive ? _searchInput.text.trim() : '';

  String? get _activeSearchHitId {
    if (!_textQueryActive || _searchHits.isEmpty) return null;
    final index = _searchHitIndex.clamp(0, _searchHits.length - 1);
    return _searchHits[index].id;
  }

  List<Map<String, dynamic>> _withoutHidden(List<Map<String, dynamic>> rows) {
    if (_hiddenIds.isEmpty) return rows;
    return [
      for (final message in rows)
        if (!_hiddenIds.contains(message['id']?.toString())) message,
    ];
  }

  Future<void> _prepareLocalThenHydrate() async {
    final hidden = await ChatHiddenStore.instance.idsFor(widget.threadId);
    if (!mounted) return;
    _hiddenIds
      ..clear()
      ..addAll(hidden);
    await _hydrateFromCache();
  }

  Future<void> _ensureEntryUnread() {
    return _unreadSnap ??= _snapshotEntryUnread();
  }

  Future<void> _snapshotEntryUnread() async {
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      final threads = await _api.listThreads(token);
      if (!mounted) return;
      for (final thread in threads) {
        if (thread['id']?.toString() != widget.threadId) continue;
        _entryUnread = threadUnreadCount(
          thread,
          myUserId: widget.authController.user?.id,
        );
        break;
      }
    } catch (_) {
    } finally {
      _entryUnreadReady = true;
      _rememberFirstUnread();
    }
  }

  void _rememberFirstUnread() {
    if (_firstUnreadId != null || !_entryUnreadReady || _entryUnread <= 0) {
      return;
    }
    final myId = widget.authController.user?.id ?? '';
    _firstUnreadId = firstUnreadMessageId(
      mergeThreadCorpus(
        loaded: _messages,
        cached: _searchCache,
        hiddenIds: _hiddenIds,
      ),
      _entryUnread,
      myId,
    );
  }

  Future<void> _loadSearchCache() async {
    final cached = await OfflineCacheStore.instance.loadMessages(
      widget.threadId,
    );
    if (!mounted) return;
    _searchCache = cached ?? const [];
    _rememberFirstUnread();
    if (_searchOpen &&
        (_searchInput.text.trim().isNotEmpty ||
            _searchFilter != ChatSearchFilter.all)) {
      _applySearch(jump: false);
    }
  }

  void _applySearch({required bool jump}) {
    final hits = searchThreadMessages(
      loaded: _displayMessages(),
      cached: _searchCache,
      query: _searchInput.text,
      filter: _searchFilter,
      hiddenIds: _hiddenIds,
    );
    final previousId = _searchHits.isEmpty
        ? null
        : _searchHits[_searchHitIndex.clamp(0, _searchHits.length - 1)].id;
    var index = hits.isEmpty ? 0 : hits.length - 1;
    if (previousId != null) {
      final keep = hits.indexWhere((hit) => hit.id == previousId);
      if (keep >= 0) index = keep;
    }
    setState(() {
      _searchHits = hits;
      _searchHitIndex = index;
    });
    if (jump && _searchFilter == ChatSearchFilter.all && hits.isNotEmpty) {
      _jumpToMessage(hits[index].id);
    }
  }

  void _onSearchChanged(String value) {
    if (!_searchOpen) return;
    final empty = value.trim().isEmpty;
    if (!empty) _searchTyped = true;
    if (empty && _searchFilter == ChatSearchFilter.all) {
      if (_searchTyped) _closeInChatSearch();
      return;
    }
    _applySearch(jump: !empty && _searchFilter == ChatSearchFilter.all);
  }

  void _setSearchFilter(ChatSearchFilter filter) {
    if (filter == ChatSearchFilter.all && _searchInput.text.trim().isEmpty) {
      _closeInChatSearch();
      return;
    }
    setState(() => _searchFilter = filter);
    _applySearch(jump: filter == ChatSearchFilter.all);
  }

  void _closeInChatSearch() {
    _searchTyped = false;
    setState(() {
      _searchOpen = false;
      _searchFilter = ChatSearchFilter.all;
      _searchHits = [];
      _searchHitIndex = 0;
      _jumpMessageId = widget.focusMessageId;
    });
    _searchInput.clear();
  }

  Widget _searchEmptyHint(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.chatSearchEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ObicColors.mutedOf(context),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Future<void> _openInChatSearch({required bool jumpUnread}) async {
    _searchTyped = false;
    setState(() {
      _searchOpen = true;
      _selectMode = false;
      _selectedIds.clear();
    });
    await _ensureEntryUnread();
    await _loadSearchCache();
    if (!mounted || !jumpUnread) return;
    _rememberFirstUnread();
    if (_entryUnread <= 0) return;
    final id = _firstUnreadId;
    if (id == null || id.isEmpty) {
      _toast(AppLocalizations.of(context).chatUnreadNotInView);
      return;
    }
    _jumpToMessage(id);
  }

  void _stepSearchHit(int delta) {
    if (_searchHits.isEmpty) return;
    final next = (_searchHitIndex + delta).clamp(0, _searchHits.length - 1);
    if (next == _searchHitIndex) return;
    setState(() => _searchHitIndex = next);
    _jumpToMessage(_searchHits[next].id);
  }

  Map<String, dynamic>? _rowForMessageId(String id) {
    for (final message in _messages) {
      if (message['id']?.toString() == id) return message;
    }
    for (final message in _searchCache) {
      if (message['id']?.toString() == id) return message;
    }
    for (final hit in _searchHits) {
      if (hit.id == id) return hit.message;
    }
    return null;
  }

  void _jumpToMessage(String id) {
    if (_hiddenIds.contains(id)) return;
    final row = _rowForMessageId(id);
    setState(() {
      final present = _messages.any(
        (message) => message['id']?.toString() == id,
      );
      if (!present && row != null) {
        final next = [..._messages, row];
        next.sort((a, b) {
          final ta =
              parseSearchTime(a['createdAt'])?.millisecondsSinceEpoch ?? 0;
          final tb =
              parseSearchTime(b['createdAt'])?.millisecondsSinceEpoch ?? 0;
          return ta.compareTo(tb);
        });
        _messages = next;
      }
      _jumpMessageId = id;
    });
    final epoch = ++_focusEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || epoch != _focusEpoch) return;
      unawaited(_revealFocusedMessage(epoch, id, scrollEndIfMissing: false));
    });
  }

  Future<void> _openSearchHit(ChatSearchHit hit) async {
    final message = hit.message;
    final url = message['attachmentUrl'] as String?;
    final name = message['attachmentName'] as String?;
    final body = (message['body'] as String?) ?? '';
    switch (_searchFilter) {
      case ChatSearchFilter.all:
        _jumpToMessage(hit.id);
      case ChatSearchFilter.photos:
        {
          final raw = url?.trim() ?? '';
          if (raw.isEmpty || !mounted) return;
          await openChatImageViewer(context, url: raw);
        }
      case ChatSearchFilter.videos:
        {
          final raw = url?.trim() ?? '';
          if (raw.isEmpty || !mounted) return;
          await openChatVideoViewer(context, url: raw, title: name);
        }
      case ChatSearchFilter.files:
        await _launchAttachment(url);
      case ChatSearchFilter.links:
        {
          final link = firstHttpUrl(body);
          if (link == null || !mounted) return;
          final uri = Uri.tryParse(link);
          if (uri == null) return;
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (_) {}
        }
    }
  }

  Future<void> _launchAttachment(String? raw) async {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || !mounted) return;
    try {
      final Uri uri;
      final local = isLocalAttachmentPath(value);
      if (local) {
        uri = Uri.file(resolvedChatMediaUrl(value));
      } else {
        final parsed = Uri.tryParse(resolvedChatMediaUrl(value));
        if (parsed == null) return;
        uri = parsed;
      }
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: local
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
        );
      }
    } catch (_) {}
  }

  Future<void> _hydrateFromCache() async {
    await OutboundMessageQueue.instance.list();
    final cached = await OfflineCacheStore.instance.loadMessages(
      widget.threadId,
    );
    if (!mounted || cached == null || cached.isEmpty) return;
    if (_messages.isNotEmpty) return;
    // Strip orphan pending_* clocks (cache-only; not in outbound queue).
    final cleaned = _withoutHidden(
      cached.where((m) => !_isOrphanPending(m)).toList(),
    );
    setState(() {
      _messages = cleaned;
      _loading = false;
    });
    _scrollToEnd();
    _rememberFirstUnread();
    if (widget.focusMessageId != null && widget.focusMessageId!.isNotEmpty) {
      _scheduleFocusScroll(scrollEndIfMissing: false);
    }
    if (cleaned.length != cached.length) {
      unawaited(
        OfflineCacheStore.instance.saveMessages(
          widget.threadId,
          _persistableMessages(cleaned),
        ),
      );
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (!AppForeground.instance.isActive) return;
    final interval = MessageSyncGate.instance.realtimeLive
        ? _pollIntervalWithRealtime
        : _pollInterval;
    _pollTimer = Timer.periodic(interval, (_) {
      if (!AppForeground.instance.isActive) return;
      if (ConnectivityService.instance.isOffline) return;
      // Drain stuck outbound (clock bubbles) then refresh transcript.
      if (OutboundMessageQueue.instance
          .forThreadSync(widget.threadId)
          .isNotEmpty) {
        unawaited(_flushAndReload());
      } else {
        unawaited(_load(silent: true));
      }
      unawaited(_refreshActiveCall());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    ActiveChatTracker.instance.leave(widget.threadId);
    OutboundMessageQueue.instance.removeListener(_onQueueChanged);
    ConnectivityService.instance.removeListener(_onNetChanged);
    AppForeground.instance.removeListener(_onForegroundChanged);
    MessageSyncGate.instance.removeListener(_onRealtimeChanged);
    _rtMsgSub?.cancel();
    _rtNotifSub?.cancel();
    _liveSub?.cancel();
    _autoReplyBurst?.cancel();
    _stickTimer?.cancel();
    _stopPolling();
    _input.removeListener(_onComposerChanged);
    // Persist before disposing controller text.
    unawaited(ChatDraftStore.instance.save(widget.threadId, _input.text));
    _input.dispose();
    _searchInput.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Drop duplicate rows by message id (optimistic append + poll/reload).
  List<Map<String, dynamic>> _dedupeById(List<Map<String, dynamic>> rows) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final m in rows) {
      final id = m['id']?.toString();
      if (id != null && id.isNotEmpty) {
        if (seen.contains(id)) continue;
        seen.add(id);
        m['id'] = id;
      }
      out.add(m);
    }
    return out;
  }

  /// Server/cache rows + queued outbound bubbles (WeChat pending clock).
  List<Map<String, dynamic>> _displayMessages() {
    final myId = widget.authController.user?.id ?? '';
    final myName = widget.authController.user?.name;
    final myAvatar = widget.authController.user?.avatarUrl;
    final pending = <Map<String, dynamic>>[];
    for (final q in OutboundMessageQueue.instance.forThreadSync(
      widget.threadId,
    )) {
      pending.add(
        q.asOptimisticBubble(
          senderId: myId,
          senderName: myName,
          senderAvatarUrl: myAvatar,
        ),
      );
    }
    if (pending.isEmpty) return _withoutHidden(_messages);
    return _withoutHidden(_dedupeById([..._messages, ...pending]));
  }

  Future<void> _load({bool silent = false}) async {
    final seq = ++_loadSeq;
    await _ensureEntryUnread();
    if (!mounted || seq != _loadSeq) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      // Refresh JWT — stale accessToken() was causing silent 401 → empty chat.
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw AuthApiException('Not signed in');
      String? since;
      for (final row in _messages) {
        if (row['pending'] == true) continue;
        final raw = row['createdAt']?.toString();
        if (raw == null || raw.isEmpty) continue;
        if (since == null || raw.compareTo(since) > 0) since = raw;
      }
      final rows = _dedupeById(
        await _api.listMessages(
          accessToken: token,
          threadId: widget.threadId,
          since: since,
        ),
      );
      // Thread meta (kind + participants) for WeChat group faces.
      var nextKind = _kind;
      String? nextOrderId = _orderId;
      String? nextOrderStatus = _orderStatus;
      String? nextPreferredBranch = _preferredBranch;
      var nextAiAuto = _aiAutoReplyEnabled;
      var nextParticipants = _participants;
      var nextMuted = _threadMuted;
      var nextTitle = _threadTitle;
      String? nextHandoff = _handoffSummary;
      try {
        final threads = await _api.listThreads(token);
        for (final t in threads) {
          if (t['id']?.toString() == widget.threadId) {
            nextKind = (t['kind'] as String?) ?? 'direct';
            nextOrderId = t['orderId'] as String?;
            nextOrderStatus = t['orderStatus'] as String?;
            nextPreferredBranch = t['preferredBranch'] as String?;
            nextAiAuto = t['aiAutoReplyEnabled'] != false;
            nextMuted = t['muted'] == true;
            final titled = (t['title'] as String?)?.trim();
            if (titled != null && titled.isNotEmpty) nextTitle = titled;
            final hs = (t['handoffSummary'] as String?)?.trim();
            if (hs != null && hs.isNotEmpty) nextHandoff = hs;
            ActiveChatTracker.instance.setMuted(widget.threadId, nextMuted);
            final parts = t['participants'];
            if (parts is List) {
              nextParticipants = parts
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
            }
            break;
          }
        }
      } catch (_) {}
      if (!mounted || seq != _loadSeq) return;
      final prevCount = _messages.length;
      // Merge: never drop rows we already showed (optimistic / realtime) if the
      // server list is briefly stale or empty due to a race.
      final merged = _withoutHidden(_mergeServerMessages(_messages, rows));
      final messagesChanged = !_sameMessageIds(_messages, merged);
      final metaChanged =
          nextKind != _kind ||
          nextOrderId != _orderId ||
          nextOrderStatus != _orderStatus ||
          nextPreferredBranch != _preferredBranch ||
          nextAiAuto != _aiAutoReplyEnabled ||
          nextMuted != _threadMuted ||
          nextTitle != _threadTitle ||
          nextHandoff != _handoffSummary ||
          !_sameParticipants(_participants, nextParticipants);
      // Silent polls: skip setState when nothing changed so AppBar leading /
      // avatars don't rebuild-flash every few seconds.
      if (silent && !messagesChanged && !metaChanged) {
        if (!_focusDone &&
            widget.focusMessageId != null &&
            widget.focusMessageId!.isNotEmpty) {
          _scheduleFocusScroll(scrollEndIfMissing: true);
        }
        return;
      }
      setState(() {
        _messages = merged;
        _kind = nextKind;
        _threadTitle = nextTitle;
        _handoffSummary = nextHandoff;
        _threadMuted = nextMuted;
        _orderId = nextOrderId;
        _orderStatus = nextOrderStatus;
        _preferredBranch = nextPreferredBranch;
        _aiAutoReplyEnabled = nextAiAuto;
        _participants = nextParticipants;
        if (widget.demoOpenAttachPanel && !silent) {
          _panelOpen = true;
        }
        _loading = false;
        _error = null;
      });
      unawaited(
        OfflineCacheStore.instance.saveMessages(
          widget.threadId,
          _persistableMessages(merged),
        ),
      );
      _rememberFirstUnread();
      // API markThreadRead runs inside listMessages — drop shell/list badges now.
      if (!_openedNotified) {
        _openedNotified = true;
        widget.onThreadOpened?.call();
      }
      // Always land on latest when opening/refreshing the thread (WeChat).
      // Hydrate can prefill N rows; server may return a newer window of same length.
      if (widget.focusMessageId != null &&
          widget.focusMessageId!.isNotEmpty &&
          !_focusDone) {
        _scheduleFocusScroll(scrollEndIfMissing: true);
      } else if (!silent && merged.isNotEmpty) {
        _scrollToEnd();
      } else if (merged.length > prevCount) {
        _scrollToEnd();
      }
      if (!silent && widget.demoOpenMessageMenu && merged.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          if (!mounted) return;
          // ignore: avoid_print
          print('OBIC_DEMO: chat_menu_ready');
          await _showWeChatMessageMenu(context, merged.last, mine: true);
        });
      } else if (widget.demoOpenMessageMenu) {
        // ignore: avoid_print
        print('OBIC_DEMO: chat_menu_ready');
      }
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;
      final cached = await OfflineCacheStore.instance.loadMessages(
        widget.threadId,
      );
      if (!mounted || seq != _loadSeq) return;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          // Keep any optimistic/realtime rows already on screen.
          _messages = _withoutHidden(_mergeServerMessages(_messages, cached));
          _loading = false;
          _error = null;
        });
        if (widget.focusMessageId != null &&
            widget.focusMessageId!.isNotEmpty &&
            !_focusDone) {
          _scheduleFocusScroll(scrollEndIfMissing: true);
        }
        return;
      }
      if (!silent && _messages.isEmpty) {
        setState(() {
          _loading = false;
          _error = ConnectivityService.instance.isOffline
              ? AppLocalizations.of(context).offlineNeedsNetwork
              : _friendlyErr(e);
        });
      } else if (!silent) {
        setState(() => _loading = false);
      }
    }
  }

  /// Prefer server rows; keep in-flight optimistic ids still on screen.
  /// Orphan pending_* from disk cache are stripped in [_hydrateFromCache].
  List<Map<String, dynamic>> _mergeServerMessages(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> server,
  ) {
    if (server.isEmpty && local.isNotEmpty) return local;
    final serverIds = <String>{};
    for (final m in server) {
      final id = m['id']?.toString();
      if (id != null && id.isNotEmpty) serverIds.add(id);
    }
    final extras = <Map<String, dynamic>>[];
    for (final m in local) {
      final id = m['id']?.toString();
      if (id == null || id.isEmpty) {
        extras.add(m);
        continue;
      }
      if (serverIds.contains(id)) continue;
      // Keep in-flight optimistic until send finishes / queue owns it.
      if (m['pending'] == true || id.startsWith('pending_')) {
        extras.add(m);
      }
    }
    if (extras.isEmpty) return _dedupeById(server);
    return _dedupeById([...server, ...extras]);
  }

  bool _isOrphanPending(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? '';
    if (m['pending'] != true && !id.startsWith('pending_')) return false;
    final queued = OutboundMessageQueue.instance.forThreadSync(widget.threadId);
    final localId = m['localId']?.toString() ?? id;
    return !queued.any((q) => q.localId == localId || q.localId == id);
  }

  /// Never persist clock/pending bubbles — queue file is the source of truth.
  List<Map<String, dynamic>> _persistableMessages(
    List<Map<String, dynamic>> rows,
  ) {
    return rows.where((m) {
      final id = m['id']?.toString() ?? '';
      if (m['pending'] == true) return false;
      if (id.startsWith('pending_')) return false;
      return true;
    }).toList();
  }

  /// After a send, poll briefly so AI auto-reply appears in-thread even if the
  /// Socket.IO event is delayed (Render cold start). Also flushes outbound.
  void _scheduleAutoReplyBurst() {
    if (_kind != 'support' && _kind != 'order') return;
    if (!_aiAutoReplyEnabled) return;
    _autoReplyBurst?.cancel();
    var step = 0;
    const delays = <Duration>[
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
    ];
    void tick() {
      if (!mounted || step >= delays.length) return;
      _autoReplyBurst = Timer(delays[step], () {
        step++;
        if (!mounted) return;
        unawaited(_flushAndReload());
        tick();
      });
    }

    tick();
  }

  bool _sameMessageIds(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i]['id'] != b[i]['id']) return false;
      // Body/status edits should still refresh without waiting for a new id.
      if (a[i]['body'] != b[i]['body']) return false;
      if (a[i]['createdAt'] != b[i]['createdAt']) return false;
    }
    return true;
  }

  bool _sameParticipants(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i]['id'] != b[i]['id']) return false;
      if (a[i]['name'] != b[i]['name']) return false;
      if (a[i]['avatarUrl'] != b[i]['avatarUrl']) return false;
    }
    return true;
  }

  Timer? _stickTimer;
  bool _stickToLatest = true;

  /// Land on the newest line. The list lays out in pieces, so one jump
  /// still leaves the first message on screen.
  void _scrollToEnd() {
    _stickToLatest = true;
    _stickTimer?.cancel();
    var ticks = 0;
    _stickTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      ticks++;
      if (!mounted || !_stickToLatest || ticks > 24) {
        timer.cancel();
        return;
      }
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if ((_scroll.position.pixels - max).abs() > 8) {
        _scroll.jumpTo(max);
      }
    });
  }

  void _scheduleFocusScroll({required bool scrollEndIfMissing}) {
    final id = widget.focusMessageId;
    if (id == null || id.isEmpty) return;
    if (scrollEndIfMissing) _focusDone = true;
    final epoch = ++_focusEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || epoch != _focusEpoch) return;
      unawaited(
        _revealFocusedMessage(
          epoch,
          id,
          scrollEndIfMissing: scrollEndIfMissing,
        ),
      );
    });
  }

  Future<void> _revealFocusedMessage(
    int epoch,
    String id, {
    required bool scrollEndIfMissing,
  }) async {
    if (!mounted || epoch != _focusEpoch) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || epoch != _focusEpoch || !_scroll.hasClients) return;
    final rows = _displayMessages();
    final index = rows.indexWhere((message) => message['id']?.toString() == id);
    if (index < 0) {
      if (scrollEndIfMissing && epoch == _focusEpoch) _scrollToEnd();
      return;
    }

    Future<bool> revealIfBuilt() async {
      final target = _focusMessageKey.currentContext;
      if (target == null || !mounted || epoch != _focusEpoch) return false;
      await Scrollable.ensureVisible(
        target,
        alignment: 0.32,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return true;
    }

    if (await revealIfBuilt()) return;

    const estimated = 96.0;
    final guess = index * estimated;
    var previousExtent = -1.0;
    for (var step = 0; step < 12; step++) {
      if (!mounted || epoch != _focusEpoch || !_scroll.hasClients) return;
      final position = _scroll.position;
      final dest = guess.clamp(0.0, position.maxScrollExtent);
      if ((position.pixels - dest).abs() > 24) {
        _scroll.jumpTo(dest);
      } else if (position.maxScrollExtent + 8 < guess) {
        if (position.maxScrollExtent == previousExtent) break;
        _scroll.jumpTo(position.maxScrollExtent);
      }
      previousExtent = position.maxScrollExtent;
      await WidgetsBinding.instance.endOfFrame;
      if (await revealIfBuilt()) return;
    }

    if (!mounted || epoch != _focusEpoch || !_scroll.hasClients) return;
    final origin = _scroll.position.pixels;
    for (final delta in const [0.0, 320.0, -320.0, 640.0, -640.0]) {
      if (!mounted || epoch != _focusEpoch || !_scroll.hasClients) return;
      final position = _scroll.position;
      _scroll.jumpTo((origin + delta).clamp(0.0, position.maxScrollExtent));
      await WidgetsBinding.instance.endOfFrame;
      if (await revealIfBuilt()) return;
    }
    if (scrollEndIfMissing && epoch == _focusEpoch) _scrollToEnd();
  }

  void _toast(String msg) {
    if (!mounted) return;
    final trimmed = msg.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.toLowerCase().contains('phoneactivationrequired')) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trimmed)));
  }

  String _friendlyErr(Object e) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return friendlyApiError(
      classifyTransportError(e),
      l10n: l10n,
      langCode: lang,
    );
  }

  void _comingSoon(String feature) {
    _toast('$feature — coming in a later update');
  }

  Future<void> _reportMessage(Map<String, dynamic> m) async {
    final id = m['id'] as String?;
    if (id == null) return;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await _api.reportContent(
        accessToken: token,
        targetType: 'message',
        targetId: id,
      );
      _toast(
        arabic
            ? 'تم الإبلاغ — سيراجعه المشرف'
            : 'Reported — SuperAdmin will review',
      );
    } catch (e) {
      _toast(_friendlyErr(e));
    }
  }

  /// Light WeChat translate — cache first; network off UI isolate; one setState.
  void _translateMessage(Map<String, dynamic> m) {
    final id = m['id'] as String?;
    final text = _messagePlainText(m).trim();
    if (id == null || text.isEmpty) return;
    final target = _aiLocaleCode;

    final cached =
        TranslationCache.instance.get(id, target) ?? _translations[id];
    if (cached != null && cached.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _translations[id] = cached;
        _translationHidden.remove(id);
      });
      return;
    }
    if (ConnectivityService.instance.isOffline) {
      _toast(offlineNeedsNetworkMessage(AppLocalizations.of(context)));
      return;
    }
    if (_translatingIds.contains(id)) return;

    setState(() => _translatingIds.add(id));
    unawaited(_fetchTranslation(id: id, text: text, target: target));
  }

  Future<void> _fetchTranslation({
    required String id,
    required String text,
    required String target,
  }) async {
    final l10n = AppLocalizations.of(context);
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw AuthApiException('Not signed in');
      final res = await _aiApi.translate(
        accessToken: token,
        text: text,
        targetLocale: target,
        messageId: id,
      );
      final translation = (res['translation'] as String?)?.trim() ?? '';
      if (!mounted) return;
      if (translation.isEmpty) {
        setState(() => _translatingIds.remove(id));
        _toast(l10n.msgTranslateFailed);
        return;
      }
      TranslationCache.instance.put(id, target, translation);
      setState(() {
        _translations[id] = translation;
        _translationHidden.remove(id);
        _translatingIds.remove(id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _translatingIds.remove(id));
      _toast(l10n.msgTranslateFailed);
    }
  }

  void _toggleShowOriginal(String id) {
    setState(() {
      if (_translationHidden.contains(id)) {
        _translationHidden.remove(id);
      } else {
        _translationHidden.add(id);
      }
    });
  }

  Future<void> _send() async {
    // Guard before any await — keyboard submit + button can both fire.
    if (_sending) return;
    var text = (_pendingBodyOverride ?? _input.text).trim();
    if (_quoted != null) {
      final q = _messagePlainText(_quoted!);
      if (q.isNotEmpty) {
        text = text.isEmpty ? '「$q」' : '「$q」\n$text';
      }
    }
    if (text.isEmpty && _pendingAttachKind == 'none') return;
    final sendKind = dtoAttachmentKind(_pendingAttachKind);
    final attachName = _pendingAttachName;
    final attachPath = _pendingAttachPath;
    final myId = widget.authController.user?.id ?? '';
    final localId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = <String, dynamic>{
      'id': localId,
      'conversationId': widget.threadId,
      'body': text.isEmpty ? '' : text,
      'attachmentKind': sendKind,
      'attachmentName': attachName,
      'attachmentUrl': attachPath,
      'senderId': myId,
      'senderName': widget.authController.user?.name,
      'senderAvatarUrl': widget.authController.user?.avatarUrl,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'pending': true,
      'localId': localId,
    };
    // Clear input + show bubble immediately (WeChat) — don’t wait on API.
    setState(() {
      _sending = true;
      _error = null;
      _loading = false;
      _input.clear();
      _pendingAttachKind = 'none';
      _pendingAttachName = null;
      _pendingAttachPath = null;
      _pendingBodyOverride = null;
      _quoted = null;
      _panelOpen = false;
      _messages = _dedupeById([..._messages, optimistic]);
    });
    unawaited(ChatDraftStore.instance.clear(widget.threadId));
    _scrollToEnd();
    RealtimeClient.instance.noteLocalChatMessage(
      conversationId: widget.threadId,
      message: optimistic,
    );

    void dropOptimistic() {
      _messages = _messages.where((m) => m['id'] != localId).toList();
    }

    Future<void> enqueueLocal({String? attachmentUrl}) async {
      await OutboundMessageQueue.instance.enqueue(
        threadId: widget.threadId,
        body: text.isEmpty ? '' : text,
        attachmentKind: sendKind,
        attachmentName: attachName,
        // Keep local path until flush uploads (or remote URL if already uploaded).
        attachmentUrl: attachmentUrl ?? attachPath,
        locale: _aiLocaleCode,
      );
      if (!mounted) return;
      setState(() {
        // Queue owns the pending bubble via [_displayMessages].
        dropOptimistic();
        _sending = false;
      });
      _scrollToEnd();
      // Critical: queue used to sit forever while "online" (no net flap).
      if (ConnectivityService.instance.isOnline) {
        unawaited(_flushAndReload());
        _scheduleAutoReplyBurst();
      }
    }

    if (ConnectivityService.instance.isOffline) {
      await enqueueLocal();
      return;
    }

    try {
      // Must refresh — bare accessToken() expires at 15m → 401 → silent queue.
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw AuthApiException('Not signed in');

      String? attachUrl;
      if (sendKind != 'none') {
        if (attachPath != null && isLocalAttachmentPath(attachPath)) {
          final items = await _api.uploadFiles(
            accessToken: token,
            files: [
              (
                path: attachPath,
                filename: attachName ?? p.basename(attachPath),
              ),
            ],
          );
          if (items.isEmpty) {
            throw AuthApiException('Upload failed');
          }
          attachUrl = items.first['url'] as String?;
          if (attachUrl == null || attachUrl.isEmpty) {
            throw AuthApiException('Upload failed');
          }
        } else if (isRemoteAttachmentUrl(attachPath)) {
          attachUrl = attachPath;
        } else {
          throw AuthApiException('Missing attachment file');
        }
      }

      final msg = await _api.sendMessage(
        accessToken: token,
        threadId: widget.threadId,
        body: text.isEmpty ? '' : text,
        attachmentKind: sendKind,
        attachmentName: attachName,
        attachmentUrl: attachUrl,
        locale: _aiLocaleCode,
      );
      final id = msg['id']?.toString();
      if (id != null) msg['id'] = id;
      RealtimeClient.instance.noteLocalChatMessage(
        conversationId: widget.threadId,
        message: msg,
      );
      if (!mounted) return;
      setState(() {
        dropOptimistic();
        final already =
            id != null && _messages.any((m) => m['id']?.toString() == id);
        _messages = already ? _messages : _dedupeById([..._messages, msg]);
        _sending = false;
      });
      unawaited(
        OfflineCacheStore.instance.saveMessages(
          widget.threadId,
          _persistableMessages(_messages),
        ),
      );
      _scrollToEnd();
      // Support auto-intent: open handoff form with prefilled ref (confirm branch).
      // Do not silent-default Yiwu — user must submit the form.
      if (_kind == 'support' &&
          _showTalkToStaff &&
          text.isNotEmpty &&
          shouldAutoRequestStaff(text)) {
        final ref = extractHandoffOrderRef(text);
        final serviceHint =
            RegExp(
              r'visa|تأشير|جواز|passport',
              caseSensitive: false,
            ).hasMatch(text)
            ? 'government'
            : null;
        unawaited(
          _requestStaff(prefillOrderRef: ref, prefillServiceKey: serviceHint),
        );
      }
      // Confirm from server + catch auto-reply without leaving the chat.
      unawaited(_load(silent: true));
      _scheduleAutoReplyBurst();
    } catch (e) {
      if (!mounted) return;
      // Gate already opened. Keep the text queued so it sends after activation.
      if (e is PhoneActivationRequired) {
        await enqueueLocal();
        return;
      }
      // Client / attach errors — toast + drop; never poison FIFO outbound queue.
      if (e is AuthApiException) {
        final code = e.statusCode;
        final httpClientErr =
            code != null &&
            code >= 400 &&
            code < 500 &&
            code != 401 &&
            code != 408;
        final attachErr =
            e.message.contains('Missing attachment') ||
            e.message.contains('Upload failed') ||
            e.message.contains('Invalid attachment');
        if (httpClientErr || attachErr) {
          setState(() {
            dropOptimistic();
            _sending = false;
          });
          RealtimeClient.instance.noteLocalChatMessage(
            conversationId: widget.threadId,
            message: {'id': localId, 'failed': true},
          );
          _toast(_friendlyErr(e));
          return;
        }
      }
      // Network / 401 / 5xx — queue + immediate flush (refresh JWT on flush).
      await enqueueLocal();
    }
  }

  void _setPending({
    required String kind,
    String? name,
    String? path,
    String? bodyOverride,
  }) {
    setState(() {
      _pendingAttachKind = kind;
      _pendingAttachName = name;
      _pendingAttachPath = path;
      _pendingBodyOverride = bodyOverride;
      _panelOpen = false;
    });
  }

  String _mediaPickErrorLabel(Object e) {
    final l10n = AppLocalizations.of(context);
    switch (classifyMediaPickError(e)) {
      case 'camera_denied':
        return l10n.mediaCameraPermissionDenied;
      case 'photos_denied':
        return l10n.mediaPhotosPermissionDenied;
      case 'mic_denied':
        return l10n.chatMicPermissionDenied;
      case 'cancelled':
        return '';
      default:
        return l10n.mediaPickFailed;
    }
  }

  Future<void> _pickGallery() async {
    try {
      final shots = await pickAlbumImages(
        _picker,
        imageQuality: 88,
        maxWidth: 2400,
      );
      if (shots.isEmpty || !mounted) return;
      // Multi-select: send each image (WeChat album). Single: stage for caption.
      if (shots.length == 1) {
        final shot = shots.first;
        _setPending(kind: 'image', name: shot.filename, path: shot.path);
        return;
      }
      for (final shot in shots) {
        if (!mounted) return;
        setState(() {
          _pendingAttachKind = 'image';
          _pendingAttachName = shot.filename;
          _pendingAttachPath = shot.path;
          _pendingBodyOverride = null;
          _panelOpen = false;
        });
        await _send();
      }
    } catch (e) {
      if (!mounted) return;
      final msg = _mediaPickErrorLabel(e);
      if (msg.isNotEmpty) _toast(msg);
    }
  }

  Future<void> _pickCamera() async {
    try {
      final shot = await takeCameraPhoto(
        _picker,
        imageQuality: 88,
        maxWidth: 2400,
      );
      if (shot == null || !mounted) return;
      _setPending(kind: 'image', name: shot.filename, path: shot.path);
    } catch (e) {
      if (!mounted) return;
      final msg = _mediaPickErrorLabel(e);
      if (msg.isNotEmpty) _toast(msg);
    }
  }

  Future<void> _pickFiles() async {
    final files = await openFiles(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'media',
          extensions: [
            'jpg',
            'jpeg',
            'png',
            'gif',
            'webp',
            'mp4',
            'mov',
            'pdf',
            'doc',
            'docx',
            'xls',
            'xlsx',
            'txt',
            'zip',
          ],
        ),
      ],
    );
    if (files.isEmpty || !mounted) return;
    final f = files.first;
    final name = f.name;
    final lower = name.toLowerCase();
    final kind = lower.endsWith('.mp4') || lower.endsWith('.mov')
        ? 'video'
        : (lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.png') ||
              lower.endsWith('.gif') ||
              lower.endsWith('.webp'))
        ? 'image'
        : 'file';
    if (kind == 'video') {
      await _stageVideoPath(f.path, name);
      return;
    }
    _setPending(kind: kind, name: name, path: f.path);
  }

  Future<void> _pickVideo() async {
    final source = await showWechatVideoSourceSheet(context);
    if (source == null || !mounted) return;
    try {
      final shot = await pickOrRecordVideo(
        _picker,
        source: source,
        maxDuration: kMediaVideoMaxDuration,
      );
      if (shot == null || !mounted) return;
      await _stageVideoPath(shot.path, shot.filename);
    } catch (e) {
      if (!mounted) return;
      final msg = _mediaPickErrorLabel(e);
      if (msg.isNotEmpty) _toast(msg);
    }
  }

  Future<void> _stageVideoPath(String path, String name) async {
    final l10n = AppLocalizations.of(context);
    final len = await localFileLength(path);
    switch (classifyVideoSize(len)) {
      case 'too_large':
        _toast(l10n.chatVideoTooLarge);
        return;
      case 'unreadable':
        _toast(l10n.chatVideoPickFailed);
        return;
      case 'large_warning':
        _toast(l10n.chatVideoLargeWarning);
      case 'ok':
        break;
      default:
        break;
    }
    if (!mounted) return;
    _setPending(kind: 'video', name: name, path: path);
  }

  Future<void> _sendTyped(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _sending) return;
    _input.text = clean;
    _pendingAttachKind = 'none';
    _pendingAttachName = null;
    _pendingAttachPath = null;
    _pendingBodyOverride = null;
    await _send();
  }

  Future<String?> _transcribeVoiceFile(String path) async {
    final token = await widget.authController.ensureAccessToken();
    if (token == null) return null;
    final bytes = await File(path).readAsBytes();
    final lower = path.toLowerCase();
    final mime = lower.endsWith('.wav')
        ? 'audio/wav'
        : lower.endsWith('.mp3')
            ? 'audio/mpeg'
            : 'audio/mp4';
    final json = await AiApi().transcribe(
      accessToken: token,
      dataBase64: base64Encode(bytes),
      mime: mime,
    );
    final text = (json['text'] as String?)?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Future<void> _sendVoiceNote(VoiceRecordResult result) async {
    if (_sending) return;
    setState(() {
      _pendingAttachKind = 'audio';
      _pendingAttachName = result.filename;
      _pendingAttachPath = result.path;
      _pendingBodyOverride = null;
      _panelOpen = false;
    });
    await _send();
  }

  Future<void> _openFavorites() async {
    final item = await showChatFavoritesPicker(
      context,
      authController: widget.authController,
    );
    if (item == null || !mounted) return;
    if (item.kind == 'text') {
      setState(() {
        _input.text = item.body ?? '';
        _pendingAttachKind = 'none';
        _pendingAttachName = null;
        _pendingAttachPath = null;
        _panelOpen = false;
      });
      return;
    }
    _setPending(
      kind: item.kind,
      name: item.name ?? item.kind,
      path: item.pathOrUrl,
    );
  }

  Future<void> _favoriteMessage(Map<String, dynamic> m) async {
    final body = (m['body'] as String?) ?? '';
    final kind = (m['attachmentKind'] as String?) ?? 'none';
    final name = m['attachmentName'] as String?;
    final url = m['attachmentUrl'] as String?;
    if (kind == 'none' && body.trim().isEmpty) {
      _toast('Nothing to favorite');
      return;
    }
    if (kind == 'none') {
      await ChatFavoritesStore.instance.add(kind: 'text', body: body);
    } else {
      // Keep relative /uploads paths as-is; resolve at display via media_url.
      await ChatFavoritesStore.instance.add(
        kind: kind == 'image'
            ? 'image'
            : kind == 'video'
            ? 'video'
            : kind == 'audio'
            ? 'audio'
            : 'file',
        body: body.isEmpty ? null : body,
        name: name,
        pathOrUrl: url,
      );
    }
    _toast('Saved to Favorites');
  }

  String _messagePlainText(Map<String, dynamic> m) {
    final body = ((m['body'] as String?) ?? '').trim();
    final kind = (m['attachmentKind'] as String?) ?? 'none';
    final name = m['attachmentName'] as String?;
    if (kind != 'none') {
      final label = name ?? kind;
      return body.isEmpty ? '[$label]' : '$body\n[$label]';
    }
    return body;
  }

  Future<void> _copyMessage(Map<String, dynamic> m) async {
    final l10n = AppLocalizations.of(context);
    final text = _messagePlainText(m);
    if (text.isEmpty) {
      _toast(l10n.chatNothingToCopy);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    _toast(l10n.chatCopied);
  }

  void _quoteMessage(Map<String, dynamic> m) {
    setState(() {
      _quoted = m;
      _selectMode = false;
      _selectedIds.clear();
    });
  }

  void _deleteLocal(Map<String, dynamic> m, {bool toast = true}) {
    final id = m['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() {
      _hiddenIds.add(id);
      _messages = _messages.where((e) => e['id']?.toString() != id).toList();
      _selectedIds.remove(id);
      _searchHits = [
        for (final hit in _searchHits)
          if (hit.id != id) hit,
      ];
      if (_searchHits.isEmpty) {
        _searchHitIndex = 0;
      } else if (_searchHitIndex >= _searchHits.length) {
        _searchHitIndex = _searchHits.length - 1;
      }
    });
    unawaited(ChatHiddenStore.instance.hide(widget.threadId, id));
    unawaited(
      OfflineCacheStore.instance.saveMessages(
        widget.threadId,
        _persistableMessages(_messages),
      ),
    );
    if (toast && mounted) {
      _toast(AppLocalizations.of(context).chatDeletedForMe);
    }
  }

  Future<void> _forwardMessages(List<Map<String, dynamic>> msgs) async {
    if (msgs.isEmpty) return;
    final token = await widget.authController.accessToken();
    if (token == null) return;
    List<Map<String, dynamic>> threads;
    try {
      threads = await _api.listThreads(token);
    } catch (e) {
      _toast(_friendlyErr(e));
      return;
    }
    if (!mounted) return;
    final target = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final others = threads
            .where((t) => t['id'] != widget.threadId)
            .toList();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  'Forward to…',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: ObicColors.titleOf(context),
                  ),
                ),
              ),
              if (others.isEmpty)
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No other chats yet',
                    style: TextStyle(color: ObicColors.mutedOf(context)),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: others.length,
                    itemBuilder: (_, i) {
                      final t = others[i];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: ObicColors.blueSoft,
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: ObicColors.blue,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          (t['title'] as String?) ??
                              (t['kind'] as String?) ??
                              'Chat',
                        ),
                        onTap: () => Navigator.pop(ctx, t),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (target == null || !mounted) return;
    final threadId = target['id'] as String?;
    if (threadId == null) return;
    try {
      for (final m in msgs) {
        final body = (m['body'] as String?) ?? '';
        var kind = (m['attachmentKind'] as String?) ?? 'none';
        await _api.sendMessage(
          accessToken: token,
          threadId: threadId,
          body: body.isEmpty && kind == 'none' ? _messagePlainText(m) : body,
          attachmentKind: dtoAttachmentKind(kind),
          attachmentName: m['attachmentName'] as String?,
          attachmentUrl: m['attachmentUrl'] as String?,
          locale: _aiLocaleCode,
        );
      }
      _toast('Forwarded');
      setState(() {
        _selectMode = false;
        _selectedIds.clear();
      });
    } catch (e) {
      _toast(_friendlyErr(e));
    }
  }

  bool get _canLiveShare {
    final kind = _kind.trim().toLowerCase();
    return kind == 'direct' || kind == 'group';
  }

  String _liveShareLabel() {
    final n = _liveSharers;
    if (n == 1) {
      return obicPhrase(
        context,
        ar: 'شخص واحد يشارك الموقع المباشر',
        en: '1 person sharing live location',
        zh: '1 人正在共享实时位置',
      );
    }
    return obicPhrase(
      context,
      ar: '$n يشاركون الموقع المباشر',
      en: '$n sharing live location',
      zh: '$n 人正在共享实时位置',
    );
  }

  Future<void> _loadVoiceMemory() async {
    final all = await VoiceTextMemory.load();
    if (!mounted) return;
    setState(() => _voiceText.addAll(all));
  }

  Future<void> _refreshLive() async {
    if (!_canLiveShare) return;
    final token = await widget.authController.accessToken();
    if (token == null || !mounted) return;
    try {
      final rows = await _api.listLiveLocation(
        accessToken: token,
        conversationId: widget.threadId,
      );
      if (!mounted) return;
      setState(() => _liveSharers = rows.length);
    } catch (_) {}
  }

  Future<void> _openLiveMap({int? minutes}) async {
    final locale = Localizations.localeOf(context);
    final prefs = await SharedPreferences.getInstance();
    final savedRegion = prefs.getString(kRegionCountryKey);
    final chinaFirst = preferChinaMapLinks(
      localeLanguageCode: locale.languageCode,
      localeCountryCode: locale.countryCode,
      savedRegionCountry: savedRegion,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveLocationScreen(
          authController: widget.authController,
          conversationId: widget.threadId,
          minutes: minutes,
          preferChina: chinaFirst,
        ),
      ),
    );
    if (mounted) await _refreshLive();
  }

  Future<void> _chooseLocationAction() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.place_outlined, color: ObicColors.blue),
              title: Text(
                obicPhrase(ctx, ar: 'إرسال الموقع', en: 'Send location', zh: '发送位置'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.pop(ctx, 'send'),
            ),
            if (_canLiveShare)
              ListTile(
                leading: const Icon(Icons.share_location, color: ObicColors.blue),
                title: Text(
                  obicPhrase(
                    ctx,
                    ar: 'مشاركة الموقع المباشر',
                    en: 'Share live location',
                    zh: '共享实时位置',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(ctx, 'live'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'send') {
      await _shareLocation();
      return;
    }
    final minutes = await pickLiveShareMinutes(context);
    if (minutes == null || !mounted) return;
    await _openLiveMap(minutes: minutes);
  }

  Future<void> _openGroupInfo() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupInfoScreen(
          authController: widget.authController,
          threadId: widget.threadId,
          title: _threadTitle,
          participants: _participants,
        ),
      ),
    );
    if (mounted) await _load(silent: true);
  }

  Future<void> _saveChatMedia(Map<String, dynamic> m) async {
    final kind = (m['attachmentKind'] as String?) ?? '';
    final suffix = kind == 'video'
        ? '.mp4'
        : kind == 'image'
            ? '.jpg'
            : (p.extension((m['attachmentName'] as String?) ?? '') .isEmpty
                ? '.bin'
                : p.extension(m['attachmentName'] as String));
    try {
      final file = await _cacheMedia(m['attachmentUrl'] as String?, suffix: suffix);
      if (file == null) throw StateError('missing');
      if (kind == 'image') {
        await Gal.putImage(file.path);
      } else if (kind == 'video') {
        await Gal.putVideo(file.path);
      } else {
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
        return;
      }
      if (!mounted) return;
      _toast(obicPhrase(context, ar: 'تم الحفظ', en: 'Saved', zh: '已保存'));
    } catch (_) {
      if (!mounted) return;
      _toast(obicPhrase(context, ar: 'تعذّر الحفظ', en: 'Could not save', zh: '无法保存'));
    }
  }

  Future<File?> _cacheMedia(String? raw, {required String suffix}) async {
    final resolved = resolvedChatMediaUrl(raw);
    if (resolved.isEmpty) return null;
    if (!resolved.startsWith('http')) {
      final file = File(resolved);
      return file.existsSync() ? file : null;
    }
    final res = await http.get(Uri.parse(resolved)).timeout(const Duration(seconds: 30));
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/obic-${DateTime.now().millisecondsSinceEpoch}$suffix',
    );
    await file.writeAsBytes(res.bodyBytes);
    return file;
  }

  String _audioMime(String path) {
    final ext = p.extension(path).toLowerCase();
    if (ext == '.mp3') return 'audio/mpeg';
    if (ext == '.wav') return 'audio/wav';
    if (ext == '.aac') return 'audio/aac';
    if (ext == '.ogg') return 'audio/ogg';
    return 'audio/mp4';
  }

  Future<void> _convertVoice(Map<String, dynamic> m) async {
    final id = m['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final cached = _voiceText[id];
    if (cached != null && cached.text.isNotEmpty) return;
    setState(() {
      _voiceBusy.add(id);
      _voiceNote.remove(id);
    });
    try {
      final file = await _cacheMedia(m['attachmentUrl'] as String?, suffix: '.m4a');
      if (file == null) throw Exception('missing');
      final bytes = await file.readAsBytes();
      final token = await widget.authController.ensureAccessToken();
      if (token == null || !mounted) return;
      final res = await _aiApi.transcribe(
        accessToken: token,
        dataBase64: base64Encode(bytes),
        mime: _audioMime(file.path),
      );
      final text = (res['text'] as String?)?.trim() ?? '';
      if (!mounted) return;
      if (text.isEmpty) {
        setState(() {
          _voiceBusy.remove(id);
          _voiceNote[id] = obicPhrase(
            context,
            ar: 'الصوت غير واضح أو ما فيه كلام',
            en: 'The audio is not clear, or there is no speech',
            zh: '语音不清晰，或没有说话声',
          );
        });
        return;
      }
      _voiceText[id] = VoiceTextMemory(text: text);
      await VoiceTextMemory.save(_voiceText);
      if (!mounted) return;
      setState(() => _voiceBusy.remove(id));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _voiceBusy.remove(id);
        _voiceNote[id] = obicPhrase(
          context,
          ar: 'ما قدرنا نحوّل هذا الصوت',
          en: 'Could not convert this voice message',
          zh: '无法转换这条语音',
        );
      });
    }
  }

  Future<void> _translateVoice(String id) async {
    final row = _voiceText[id];
    if (row == null || row.text.isEmpty) return;
    if (row.translation.isNotEmpty) {
      setState(() => _voiceTranslated.add(id));
      return;
    }
    setState(() => _voiceBusy.add(id));
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null || !mounted) return;
      final code = Localizations.localeOf(context).languageCode;
      final target = code == 'ar' || code == 'zh' ? code : 'en';
      final res = await _aiApi.translate(
        accessToken: token,
        text: row.text,
        targetLocale: target,
        messageId: id,
      );
      final translation = (res['translation'] as String?)?.trim() ?? '';
      if (!mounted) return;
      if (translation.isEmpty) {
        setState(() => _voiceBusy.remove(id));
        return;
      }
      _voiceText[id] = VoiceTextMemory(text: row.text, translation: translation);
      await VoiceTextMemory.save(_voiceText);
      if (!mounted) return;
      setState(() {
        _voiceBusy.remove(id);
        _voiceTranslated.add(id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _voiceBusy.remove(id);
        _voiceNote[id] = obicPhrase(
          context,
          ar: 'تعذّرت الترجمة',
          en: 'Could not translate',
          zh: '无法翻译',
        );
      });
    }
  }

  Future<void> _copyVoice(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _toast(obicPhrase(context, ar: 'تم النسخ', en: 'Copied', zh: '已复制'));
  }

  Widget _voicePanel(String id) {
    final row = _voiceText[id];
    final busy = _voiceBusy.contains(id);
    final note = _voiceNote[id];
    final showTranslation =
        _voiceTranslated.contains(id) && (row?.translation.isNotEmpty ?? false);
    if (row == null && !busy && (note == null || note.isEmpty)) {
      return const SizedBox.shrink();
    }
    final shown = showTranslation ? row!.translation : (row?.text ?? '');
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (busy)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  obicPhrase(context, ar: 'جاري التحويل…', en: 'Converting…', zh: '正在转换…'),
                  style: TextStyle(fontSize: 12, color: ObicColors.mutedOf(context)),
                ),
              ),
            if (note != null && note.isNotEmpty)
              Text(
                note,
                style: TextStyle(fontSize: 12, color: ObicColors.mutedOf(context)),
              ),
            if (shown.isNotEmpty)
              Text(
                shown,
                textDirection: chatTextDirection(shown),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: ObicColors.titleOf(context).withValues(alpha: 0.85),
                ),
              ),
            Wrap(
              spacing: 4,
              children: [
                if (shown.isNotEmpty)
                  TextButton(
                    onPressed: () => _copyVoice(shown),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(obicPhrase(context, ar: 'نسخ', en: 'Copy', zh: '复制')),
                  ),
                if (row != null && row.text.isNotEmpty && row.translation.isEmpty)
                  TextButton(
                    onPressed: busy ? null : () => _translateVoice(id),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(obicPhrase(context, ar: 'ترجمة', en: 'Translate', zh: '翻译')),
                  ),
                if (row != null && row.translation.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      if (showTranslation) {
                        _voiceTranslated.remove(id);
                      } else {
                        _voiceTranslated.add(id);
                      }
                    }),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      showTranslation
                          ? obicPhrase(context, ar: 'الأصل', en: 'Original', zh: '原文')
                          : obicPhrase(context, ar: 'الترجمة', en: 'Translation', zh: '译文'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openImageTranslate(Map<String, dynamic> m) async {
    try {
      final file = await _cacheMedia(m['attachmentUrl'] as String?, suffix: '.jpg');
      if (!mounted) return;
      if (file == null) {
        _toast(
          obicPhrase(
            context,
            ar: 'ما قدرنا نفتح الصورة',
            en: 'Could not open this photo',
            zh: '无法打开这张照片',
          ),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImageTranslateScreen(
            authController: widget.authController,
            imagePath: file.path,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _toast(
        obicPhrase(
          context,
          ar: 'ما قدرنا نفتح الصورة',
          en: 'Could not open this photo',
          zh: '无法打开这张照片',
        ),
      );
    }
  }

  Future<void> _showWeChatMessageMenu(
    BuildContext bubbleContext,
    Map<String, dynamic> m, {
    required bool mine,
  }) async {
    final l10n = AppLocalizations.of(context);
    final canRecall = mine && _canRecallMessage(m);
    final canDelete = (m['id']?.toString() ?? '').isNotEmpty;
    final kind = (m['attachmentKind'] as String?) ?? 'none';
    final voiceLabel = obicPhrase(
      context,
      ar: 'تحويل إلى نص',
      en: 'Convert to text',
      zh: '转文字',
    );
    final imageLabel = obicPhrase(
      context,
      ar: 'ترجمة الصورة',
      en: 'Translate image',
      zh: '翻译图片',
    );
    final saveLabel = obicPhrase(context, ar: 'حفظ', en: 'Save', zh: '保存');
    final actions = <({String id, IconData icon, String en, String ar})>[
      if (kind == 'image' || kind == 'video' || kind == 'file')
        (
          id: 'save_media',
          icon: Icons.download_rounded,
          en: saveLabel,
          ar: saveLabel,
        ),
      if (kind == 'audio')
        (
          id: 'voice_text',
          icon: Icons.subtitles_outlined,
          en: voiceLabel,
          ar: voiceLabel,
        ),
      if (kind == 'image' || kind == 'video' || kind == 'file')
        (
          id: 'save_media',
          icon: Icons.download_rounded,
          en: obicPhrase(context, ar: 'حفظ', en: 'Save', zh: '保存'),
          ar: obicPhrase(context, ar: 'حفظ', en: 'Save', zh: '保存'),
        ),
      if (kind == 'image' && !mine)
        (
          id: 'image_translate',
          icon: Icons.translate_rounded,
          en: imageLabel,
          ar: imageLabel,
        ),
      if (canRecall)
        (
          id: 'recall',
          icon: Icons.undo_rounded,
          en: l10n.chatRecall,
          ar: l10n.chatRecall,
        ),
      (
        id: 'copy',
        icon: Icons.copy_rounded,
        en: l10n.chatCopy,
        ar: l10n.chatCopy,
      ),
      (
        id: 'forward',
        icon: Icons.reply_all_outlined,
        en: 'Forward',
        ar: 'إعادة توجيه',
      ),
      (
        id: 'favorite',
        icon: Icons.favorite_border,
        en: 'Favorite',
        ar: 'المفضلة',
      ),
      (
        id: 'quote',
        icon: Icons.format_quote_rounded,
        en: l10n.chatQuote,
        ar: l10n.chatQuote,
      ),
      (
        id: 'select',
        icon: Icons.checklist_rtl_rounded,
        en: 'Select',
        ar: 'تحديد',
      ),
      if (canDelete)
        (
          id: 'delete',
          icon: Icons.delete_outline_rounded,
          en: l10n.chatDeleteForMe,
          ar: l10n.chatDeleteForMe,
        ),
      (id: 'remind', icon: Icons.alarm_outlined, en: 'Remind', ar: 'تذكير'),
      (
        id: 'translate',
        icon: Icons.translate_rounded,
        en: l10n.msgTranslate,
        ar: l10n.msgTranslate,
      ),
      if (!mine)
        (id: 'report', icon: Icons.flag_outlined, en: 'Report', ar: 'إبلاغ'),
    ];

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _ObicActionGridSheet(title: l10n.chatMessageActions, items: actions),
    );

    if (!mounted || choice == null) return;
    switch (choice) {
      case 'recall':
        await _recallMessage(m);
      case 'copy':
        await _copyMessage(m);
      case 'forward':
        await _forwardMessages([m]);
      case 'favorite':
        await _favoriteMessage(m);
      case 'quote':
        _quoteMessage(m);
      case 'select':
        setState(() {
          _selectMode = true;
          final id = m['id'] as String?;
          if (id != null) _selectedIds.add(id);
        });
      case 'delete':
        if (_confirmDelete) {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.chatDeleteForMe),
              content: Text(l10n.chatDeleteForMeConfirm),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.chatHandoffCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.chatDeleteForMe),
                ),
              ],
            ),
          );
          if (ok != true || !mounted) return;
        }
        _deleteLocal(m);
      case 'remind':
        _comingSoon('Remind');
      case 'translate':
        _translateMessage(m);
      case 'voice_text':
        await _convertVoice(m);
      case 'image_translate':
        await _openImageTranslate(m);
      case 'save_media':
        await _saveChatMedia(m);
      case 'report':
        await _reportMessage(m);
    }
  }

  bool _canRecallMessage(Map<String, dynamic> m) {
    if (m['recalled'] == true) return false;
    if (m['pending'] == true) return false;
    if (m['isAi'] == true) return false;
    final id = m['id']?.toString() ?? '';
    if (id.isEmpty || id.startsWith('pending_')) return false;
    final createdRaw = m['createdAt'];
    DateTime? created;
    if (createdRaw is String) {
      created = DateTime.tryParse(createdRaw);
    } else if (createdRaw is DateTime) {
      created = createdRaw;
    }
    if (created == null) return false;
    final age = DateTime.now().toUtc().difference(created.toUtc());
    return age.inSeconds >= 0 && age.inMinutes < 2;
  }

  Future<void> _recallMessage(Map<String, dynamic> m) async {
    final id = m['id']?.toString();
    if (id == null || id.isEmpty) return;
    final token = await widget.authController.ensureAccessToken();
    if (token == null || !mounted) return;
    try {
      final updated = await _api.recallMessage(
        accessToken: token,
        threadId: widget.threadId,
        messageId: id,
      );
      if (!mounted) return;
      setState(() {
        _messages = [
          for (final row in _messages)
            if (row['id']?.toString() == id)
              {...row, ...updated, 'recalled': true}
            else
              row,
        ];
      });
      unawaited(
        OfflineCacheStore.instance.saveMessages(widget.threadId, _messages),
      );
    } catch (e) {
      if (!mounted) return;
      _toast(_friendlyErr(e));
    }
  }

  Future<void> _patchThreadPrefs({
    bool? muted,
    bool? hidden,
    bool? clearHistory,
    bool? deleteChat,
  }) async {
    final token = await widget.authController.ensureAccessToken();
    if (token == null || !mounted) return;
    await _api.updateThreadPrefs(
      accessToken: token,
      threadId: widget.threadId,
      muted: muted,
      hidden: hidden,
      clearHistory: clearHistory,
      deleteChat: deleteChat,
    );
    if (muted != null) {
      setState(() => _threadMuted = muted);
      ActiveChatTracker.instance.setMuted(widget.threadId, muted);
    }
    if (clearHistory == true || deleteChat == true) {
      setState(() {
        _messages = [];
        _hiddenIds.clear();
      });
      unawaited(OfflineCacheStore.instance.saveMessages(widget.threadId, []));
      unawaited(ChatHiddenStore.instance.clearThread(widget.threadId));
    }
    if (hidden == true || deleteChat == true) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _onChatOverflow(String action) async {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case 'find':
        await _openInChatSearch(jumpUnread: true);
      case 'mute':
        await _patchThreadPrefs(muted: true);
        _toast(l10n.chatMuted);
      case 'unmute':
        await _patchThreadPrefs(muted: false);
        _toast(l10n.chatUnmuted);
      case 'hide':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.chatHide),
            content: Text(l10n.chatHideConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.chatHandoffCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.chatHide),
              ),
            ],
          ),
        );
        if (ok == true) await _patchThreadPrefs(hidden: true);
      case 'clear':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.chatClearHistory),
            content: Text(l10n.chatClearHistoryConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.chatHandoffCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.chatClearHistory),
              ),
            ],
          ),
        );
        if (ok == true) {
          await _patchThreadPrefs(clearHistory: true);
          await _load();
        }
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.chatDelete),
            content: Text(l10n.chatDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.chatHandoffCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n.chatDelete,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
        if (ok == true) await _patchThreadPrefs(deleteChat: true);
    }
  }

  Future<void> _onPanelAction(String id) async {
    switch (id) {
      case 'gallery':
        await _pickGallery();
      case 'camera':
        await _pickCamera();
      case 'video':
        await _pickVideo();
      case 'video_call':
        await _startCall(video: true);
      case 'voice_call':
        await _startCall(video: false);
      case 'location':
        await _chooseLocationAction();
      case 'voice':
        setState(() {
          _voiceMode = true;
          _panelOpen = false;
        });
      case 'favorites':
        await _openFavorites();
      case 'sticker':
        setState(() => _panelOpen = false);
        final stickerId = await showObicStickerSheet(context);
        if (stickerId == null || !mounted) return;
        final draft = _input.text;
        _pendingBodyOverride = obicStickerBody(stickerId);
        await _send();
        if (mounted && draft.trim().isNotEmpty) {
          _input.text = draft;
          _input.selection = TextSelection.collapsed(offset: draft.length);
        }
      case 'contact':
        await _showContactCard();
      case 'files':
        await _pickFiles();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final myId = widget.authController.user?.id;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Arabic: + and mic stay on the left, send stays on the right.
    // English and Chinese mirror that bar.
    final composerBarDirection = rtl ? TextDirection.ltr : TextDirection.rtl;

    return Scaffold(
      backgroundColor: ObicColors.chatCanvasOf(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: RepaintBoundary(
          child: AppBar(
            centerTitle: !_searchOpen,
            leading: _searchOpen
                ? IconButton(
                    tooltip: l10n.chatHandoffCancel,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _closeInChatSearch,
                  )
                : _selectMode
                ? IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => setState(() {
                      _selectMode = false;
                      _selectedIds.clear();
                    }),
                  )
                : null,
            title: _searchOpen
                ? TextField(
                    controller: _searchInput,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: ObicColors.blue,
                    decoration: InputDecoration(
                      hintText: l10n.chatSearchHint,
                      hintStyle: TextStyle(color: ObicColors.mutedOf(context)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: _onSearchChanged,
                  )
                : _selectMode
                ? Text('${_selectedIds.length} selected')
                : Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_isGroup) {
                            _openGroupInfo();
                            return;
                          }
                          final id = _peer?['userId']?.toString();
                          if (id == null || id.isEmpty) return;
                          _openContactProfile(
                            userId: id,
                            name: _peerName,
                            avatarUrl: _peerAvatar,
                          );
                        },
                        child: _buildHeaderAvatar(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isGroup ? _openGroupInfo : null,
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _headerTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_isGroup && _participants.length > 1)
                              Text(
                                arabic
                                    ? '${_participants.length} أعضاء'
                                    : '${_participants.length} members',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: ObicColors.mutedOf(context),
                                ),
                              ),
                          ],
                        ),
                        ),
                      ),
                    ],
                  ),
            actions: [
              if (_searchOpen)
                const SizedBox.shrink()
              else if (_selectMode) ...[
                IconButton(
                  tooltip: 'Favorite',
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () async {
                          final msgs = _messages
                              .where((m) => _selectedIds.contains(m['id']))
                              .toList();
                          for (final m in msgs) {
                            await _favoriteMessage(m);
                          }
                        },
                  icon: Icon(Icons.favorite_border),
                ),
                IconButton(
                  tooltip: 'Forward',
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () async {
                          final msgs = _messages
                              .where((m) => _selectedIds.contains(m['id']))
                              .toList();
                          await _forwardMessages(msgs);
                        },
                  icon: Icon(Icons.reply_all_outlined),
                ),
                IconButton(
                  tooltip: l10n.chatDeleteForMe,
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          final msgs = _messages
                              .where((m) => _selectedIds.contains(m['id']))
                              .toList();
                          for (final m in msgs) {
                            _deleteLocal(m, toast: false);
                          }
                          setState(() {
                            _selectedIds.clear();
                            _selectMode = false;
                          });
                          _toast(l10n.chatDeletedForMe);
                        },
                  icon: Icon(Icons.delete_outline),
                ),
              ] else ...[
                if (_showAddPeople)
                  IconButton(
                    tooltip: l10n.chatAddPeopleTitle,
                    onPressed: () async {
                      final ok = await showAddStaffSheet(
                        context: context,
                        authController: widget.authController,
                        threadId: widget.threadId,
                      );
                      if (ok && mounted) await _load(silent: true);
                    },
                    icon: Icon(Icons.person_add_alt_1_outlined),
                  ),
                IconButton(
                  tooltip: l10n.chatSearch,
                  onPressed: () => _openInChatSearch(jumpUnread: false),
                  icon: const Icon(Icons.search),
                ),
                PopupMenuButton<String>(
                  onSelected: _onChatOverflow,
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'find',
                      child: Text(l10n.chatFindInChat),
                    ),
                    PopupMenuItem(
                      value: _threadMuted ? 'unmute' : 'mute',
                      child: Text(
                        _threadMuted ? l10n.chatUnmute : l10n.chatMute,
                      ),
                    ),
                    PopupMenuItem(value: 'hide', child: Text(l10n.chatHide)),
                    PopupMenuItem(
                      value: 'clear',
                      child: Text(l10n.chatClearHistory),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        l10n.chatDelete,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: obicPhrase(context, ar: 'مكالمة صوتية', en: 'Voice call', zh: '语音通话'),
                  onPressed: () => _startCall(video: false),
                  icon: Icon(Icons.call_outlined),
                ),
                IconButton(
                  tooltip: obicPhrase(context, ar: 'مكالمة فيديو', en: 'Video call', zh: '视频通话'),
                  onPressed: () => _startCall(video: true),
                  icon: Icon(Icons.videocam_outlined),
                ),
              ],
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_searchOpen) ...[
            ChatInSearchFilterBar(
              filter: _searchFilter,
              l10n: l10n,
              onChanged: _setSearchFilter,
            ),
            if (_textQueryActive && _searchHits.isNotEmpty)
              ChatSearchPositionBar(
                current: _searchHitIndex + 1,
                total: _searchHits.length,
                label: l10n.chatSearchPosition(
                  _searchHitIndex + 1,
                  _searchHits.length,
                ),
                olderTooltip: l10n.chatSearchOlder,
                newerTooltip: l10n.chatSearchNewer,
                onOlder: _searchHitIndex > 0 ? () => _stepSearchHit(-1) : null,
                onNewer: _searchHitIndex < _searchHits.length - 1
                    ? () => _stepSearchHit(1)
                    : null,
              ),
          ],
          if (_isGroup &&
              _activeGroupCall != null &&
              !CallFloatController.instance.visible)
            Material(
              color: ObicColors.blue.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.call, color: ObicColors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        obicPhrase(
                          context,
                          ar: 'مكالمة جارية · ${_activeGroupCall!['count'] ?? 1} مشاركين',
                          en: 'Call in progress · ${_activeGroupCall!['count'] ?? 1} participants',
                          zh: '通话中 · ${_activeGroupCall!['count'] ?? 1} 人',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ObicColors.inkOf(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => unawaited(_joinActiveCall()),
                      child: Text(
                        obicPhrase(context, ar: 'انضمام', en: 'Join', zh: '加入'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_liveSharers > 0)
            Material(
              color: ObicColors.surfaceOf(context),
              child: InkWell(
                onTap: () => _openLiveMap(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.share_location, color: ObicColors.blue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _liveShareLabel(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ObicColors.inkOf(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: ObicColors.mutedOf(context)),
                    ],
                  ),
                ),
              ),
            ),
          if (_showTalkToStaff)
            Material(
              color: ObicColors.surfaceOf(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _requestStaffBusy ? null : _requestStaff,
                    icon: _requestStaffBusy
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.support_agent_rounded, size: 18),
                    label: Text(
                      _requestStaffBusy
                          ? l10n.chatTalkToStaffBusy
                          : l10n.chatTalkToStaff,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ObicColors.inkOf(context),
                      side: BorderSide(color: ObicColors.lineOf(context)),
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
              ),
            ),
          if (_showAddPeople &&
              _handoffSummary != null &&
              _handoffSummary!.trim().isNotEmpty)
            Material(
              color: ObicColors.blueSoftOf(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chatHandoffSummaryTitle,
                      style: TextStyle(
                        color: ObicColors.titleOf(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      _handoffSummary!,
                      style: TextStyle(
                        color: ObicColors.inkOf(context),
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isOrder && _orderStatus != null)
            Material(
              color: ObicColors.blueSoftOf(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.ordersTitle} · ${_statusText(l10n, _orderStatus)}',
                      style: TextStyle(
                        color: ObicColors.titleOf(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (widget.authController.isStaffRole &&
                        _canUpdateOrderStatus) ...[
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (_orderStatus == 'Submitted' ||
                              _orderStatus == 'Assigned' ||
                              _orderStatus == 'WaitingCustomer')
                            _StatusChip(
                              label: l10n.statusInProgress,
                              busy: _statusBusy,
                              onTap: () => _setOrderStatus('InProgress'),
                            ),
                          if (_orderStatus == 'InProgress')
                            _StatusChip(
                              label: l10n.statusWaitingCustomer,
                              busy: _statusBusy,
                              onTap: () => _setOrderStatus('WaitingCustomer'),
                            ),
                          if (_orderStatus == 'InProgress' ||
                              _orderStatus == 'WaitingCustomer')
                            _StatusChip(
                              label: l10n.statusCompleted,
                              busy: _statusBusy,
                              onTap: () => _setOrderStatus('Completed'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (_loading && _displayMessages().isEmpty)
            Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null && _displayMessages().isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ObicColors.inkOf(context),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_showingTypeFilter) {
                    if (_searchHits.isEmpty) {
                      return _searchEmptyHint(l10n);
                    }
                    return ChatSearchResultPane(
                      hits: _searchHits,
                      filter: _searchFilter,
                      onOpen: (hit) {
                        unawaited(_openSearchHit(hit));
                      },
                    );
                  }
                  if (_textQueryActive && _searchHits.isEmpty) {
                    return _searchEmptyHint(l10n);
                  }
                  final rows = _displayMessages();
                  final localeName = Localizations.localeOf(context).toString();
                  final timeline = <Object>[];
                  DateTime? prevAt;
                  for (final msg in rows) {
                    final at = parseChatCreatedAt(msg['createdAt']);
                    if (at != null && chatNeedsDaySeparator(prevAt, at)) {
                      timeline.add(
                        chatDaySeparatorLabel(
                          at,
                          l10n: l10n,
                          localeName: localeName,
                        ),
                      );
                    }
                    if (at != null) prevAt = at;
                    timeline.add(msg);
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification &&
                          notification.dragDetails != null) {
                        _stickToLatest = false;
                        _stickTimer?.cancel();
                      }
                      return false;
                    },
                    child: ListView.builder(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    scrollCacheExtent:
                        widget.focusMessageId == null &&
                            _jumpMessageId == null &&
                            !_textQueryActive
                        ? null
                        : const ScrollCacheExtent.pixels(1600),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: timeline.length,
                    itemBuilder: (context, i) {
                      final item = timeline[i];
                      final Widget child = () {
                        if (item is String) {
                          return ChatDaySeparatorChip(label: item);
                        }
                        final m = item as Map<String, dynamic>;
                        final rawBody = (m['body'] as String?) ?? '';
                        if (rawBody.startsWith('[[status]]')) {
                          final code = rawBody.substring('[[status]]'.length);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ObicColors.surfaceOf(context),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: ObicColors.line),
                                ),
                                child: Text(
                                  _statusText(l10n, code),
                                  style: TextStyle(
                                    color: ObicColors.mutedOf(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        final callRecord = parseCallRecordBody(rawBody);
                        if (callRecord != null) {
                          final mine = m['senderId'] == myId;
                          final label = callRecordLabel(
                            callRecord,
                            arabic: arabic,
                            mine: mine,
                            myUserId: myId,
                            lang: Localizations.localeOf(context).languageCode,
                          );
                          final connected = callRecordConnected(callRecord);
                          final icon = callRecord.isVideo
                              ? Icons.videocam_outlined
                              : Icons.call_outlined;
                          final callColor = connected
                              ? ObicColors.mutedOf(context)
                              : const Color(0xFFD92D20);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () =>
                                    _startCall(video: callRecord.isVideo),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ObicColors.surfaceOf(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: ObicColors.line),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 16,
                                        color: callColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: callColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (!connected) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          obicPhrase(
                                            context,
                                            ar: 'إعادة الاتصال',
                                            en: 'Call back',
                                            zh: '回拨',
                                          ),
                                          style: const TextStyle(
                                            color: ObicColors.blue,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        final id = m['id'] as String? ?? '$i';
                        final pending = m['pending'] == true;
                        final mine = m['senderId'] == myId;
                        final recalled = m['recalled'] == true;
                        if (recalled) {
                          final label = mine
                              ? l10n.chatRecalledYou
                              : l10n.chatRecalledPeer;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: ObicColors.mutedOf(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }
                        final body = (m['body'] as String?) ?? '';
                        final locationShare = parseLocationShareBody(body);
                        final sticker = parseObicSticker(body);
                        final kind = (m['attachmentKind'] as String?) ?? 'none';
                        final name = m['attachmentName'] as String?;
                        final selected = _selectedIds.contains(id);
                        final searchHit = _activeSearchHitId == id;
                        final isAi = m['isAi'] == true;
                        final senderName =
                            (m['senderName'] as String?) ?? (mine ? '' : '…');
                        final displaySender = isAi ? 'OBIC AI' : senderName;
                        final senderAvatar = m['senderAvatarUrl'] as String?;
                        final translation = _translations[id];
                        final translating = _translatingIds.contains(id);
                        final showTranslation =
                            translation != null &&
                            translation.isNotEmpty &&
                            !_translationHidden.contains(id);
                        // WeChat media bubbles: edge-to-edge when no caption text.
                        final mediaFlush =
                            locationShare != null ||
                            ((kind == 'video' || kind == 'image') &&
                                body.isEmpty);
                        final profileUserId = mine
                            ? myId
                            : m['senderId']?.toString();
                        final rawAvatar = isAi && !mine
                            ? ObicAiAvatar(size: 36, borderRadius: 6)
                            : MomentAvatar(
                                name: mine
                                    ? (widget.authController.user?.name ?? '?')
                                    : (displaySender.isEmpty
                                          ? '?'
                                          : displaySender),
                                avatarUrl: mine
                                    ? widget.authController.user?.avatarUrl
                                    : senderAvatar,
                                size: 36,
                                borderRadius: 6,
                              );
                        final avatar =
                            _selectMode ||
                                (isAi && !mine) ||
                                profileUserId == null ||
                                profileUserId.isEmpty
                            ? rawAvatar
                            : GestureDetector(
                                onTap: () => _openContactProfile(
                                  userId: profileUserId,
                                  name: mine
                                      ? widget.authController.user?.name
                                      : displaySender,
                                  avatarUrl: mine
                                      ? widget.authController.user?.avatarUrl
                                      : senderAvatar,
                                  allowCall: !mine,
                                ),
                                child: rawAvatar,
                              );

                        final bubble = Align(
                          alignment: mine
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (mine &&
                                  (pending || m['failed'] == true)) ...[
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 4,
                                    bottom: 12,
                                  ),
                                  child: m['failed'] == true
                                      ? Tooltip(
                                          message: l10n.msgTapToResend,
                                          child: GestureDetector(
                                            onTap: () => unawaited(
                                              _resendQueued(id),
                                            ),
                                            child: const Icon(
                                              Icons.error,
                                              size: 16,
                                              color: Color(0xFFD92D20),
                                            ),
                                          ),
                                        )
                                      : Tooltip(
                                          message: l10n.msgWaitingNetwork,
                                          child: Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: ObicColors.mutedOf(
                                              context,
                                            ).withValues(alpha: 0.85),
                                          ),
                                        ),
                                ),
                              ],
                              GestureDetector(
                            onLongPress: _selectMode
                                ? null
                                : () => _showWeChatMessageMenu(
                                    context,
                                    m,
                                    mine: mine,
                                  ),
                            onTap: _selectMode
                                ? () {
                                    setState(() {
                                      if (selected) {
                                        _selectedIds.remove(id);
                                      } else {
                                        _selectedIds.add(id);
                                      }
                                    });
                                  }
                                : null,
                            child: Column(
                              crossAxisAlignment: mine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!mine &&
                                    (isAi ||
                                        (_isGroup && displaySender.isNotEmpty)))
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      right: 4,
                                      bottom: 3,
                                    ),
                                    child: Text(
                                      displaySender,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: ObicColors.mutedOf(context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: mediaFlush
                                      ? EdgeInsets.zero
                                      : const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width * 0.72,
                                  ),
                                  decoration: mediaFlush
                                      ? BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: searchHit
                                                ? const Color(0xFFE6A817)
                                                : selected
                                                ? ObicColors.blue
                                                : ObicColors.lineOf(context),
                                            width: searchHit || selected
                                                ? 2
                                                : 1,
                                          ),
                                        )
                                      : BoxDecoration(
                                          color: mine
                                              ? ObicColors.blue
                                              : ObicColors.surfaceOf(context),
                                          borderRadius: BorderRadiusDirectional.only(
                                            topStart: const Radius.circular(14),
                                            topEnd: const Radius.circular(14),
                                            bottomStart: Radius.circular(
                                              mine ? 14 : 4,
                                            ),
                                            bottomEnd: Radius.circular(
                                              mine ? 4 : 14,
                                            ),
                                          ),
                                          border: Border.all(
                                            color: searchHit
                                                ? const Color(0xFFE6A817)
                                                : selected
                                                ? ObicColors.blue
                                                : (mine
                                                      ? Colors.transparent
                                                      : ObicColors.lineOf(
                                                          context,
                                                        )),
                                            width: searchHit || selected
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (locationShare != null)
                                        ChatLocationBubble(
                                          parsed: locationShare,
                                          mine: mine,
                                        )
                                      else if (sticker != null)
                                        ObicStickerFace(sticker: sticker, size: 108)
                                      else if (body.isNotEmpty)
                                        ChatMessageBodyText(
                                          body: body,
                                          mine: mine,
                                          highlightQuery: _activeSearchQuery,
                                        ),
                                      if (kind != 'none') ...[
                                        if (body.isNotEmpty)
                                          SizedBox(height: 6),
                                        if (kind == 'image')
                                          ChatImageBubble(
                                            url: m['attachmentUrl'] as String?,
                                            mine: mine,
                                            openOnTap: !_selectMode,
                                          )
                                        else if (kind == 'audio')
                                          ChatVoiceBubble(
                                            url: m['attachmentUrl'] as String?,
                                            mine: mine,
                                            durationSeconds:
                                                parseVoiceDurationSeconds(name),
                                          )
                                        else if (kind == 'video')
                                          ChatVideoBubble(
                                            url: m['attachmentUrl'] as String?,
                                            mine: mine,
                                            name: name,
                                          )
                                        else
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons
                                                    .insert_drive_file_outlined,
                                                size: 16,
                                                color: mine
                                                    ? Colors.white70
                                                    : ObicColors.mutedOf(
                                                        context,
                                                      ),
                                              ),
                                              SizedBox(width: 6),
                                              Flexible(
                                                child: ChatHighlightText(
                                                  text: name ?? kind,
                                                  query: _activeSearchQuery,
                                                  onDark: mine,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: mine
                                                        ? Colors.white70
                                                        : ObicColors.mutedOf(
                                                            context,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (kind == 'audio') _voicePanel(id),
                                if (translating)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      right: 4,
                                      bottom: 6,
                                    ),
                                    child: Text(
                                      l10n.msgTranslating,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: ObicColors.mutedOf(context),
                                      ),
                                    ),
                                  ),
                                if (showTranslation) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      right: 4,
                                      bottom: 2,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.sizeOf(context).width *
                                            0.72,
                                      ),
                                      child: Text(
                                        translation,
                                        textDirection: chatTextDirection(
                                          translation,
                                        ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: ObicColors.titleOf(
                                            context,
                                          ).withValues(alpha: 0.72),
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _toggleShowOriginal(id),
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        right: 4,
                                        bottom: 8,
                                        top: 2,
                                      ),
                                      child: Text(
                                        l10n.msgShowOriginal,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: ObicColors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else if (translation != null &&
                                    translation.isNotEmpty &&
                                    _translationHidden.contains(id))
                                  GestureDetector(
                                    onTap: () => _toggleShowOriginal(id),
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        right: 4,
                                        bottom: 8,
                                        top: 2,
                                      ),
                                      child: Text(
                                        l10n.msgShowTranslation,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: ObicColors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                            ],
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (_selectMode) ...[
                                Checkbox(
                                  value: selected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedIds.add(id);
                                      } else {
                                        _selectedIds.remove(id);
                                      }
                                    });
                                  },
                                ),
                              ],
                              if (!mine) ...[avatar, SizedBox(width: 8)],
                              Expanded(child: bubble),
                              if (mine) ...[SizedBox(width: 8), avatar],
                            ],
                          ),
                        );
                      }();
                      if (item is Map) {
                        final focusId = _jumpMessageId ?? widget.focusMessageId;
                        final messageId = item['id']?.toString();
                        if (focusId != null &&
                            focusId.isNotEmpty &&
                            messageId == focusId) {
                          return KeyedSubtree(
                            key: _focusMessageKey,
                            child: child,
                          );
                        }
                      }
                      return child;
                    },
                    ),
                  );
                },
              ),
            ),
          if (_quoted != null)
            Container(
              width: double.infinity,
              color: ObicColors.blueSoftOf(context),
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Icon(Icons.format_quote, color: ObicColors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _messagePlainText(_quoted!),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: ObicColors.titleOf(context),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _quoted = null),
                  ),
                ],
              ),
            ),
          if (_pendingAttachKind != 'none')
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(
                children: [
                  Icon(
                    _pendingAttachKind == 'image'
                        ? Icons.image_outlined
                        : _pendingAttachKind == 'video'
                        ? Icons.videocam_outlined
                        : _pendingAttachKind == 'audio'
                        ? Icons.mic_none_rounded
                        : Icons.attach_file,
                    size: 16,
                    color: ObicColors.blue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _pendingAttachName ?? _pendingAttachKind,
                      style: TextStyle(
                        color: ObicColors.mutedOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _pendingAttachKind = 'none';
                      _pendingAttachName = null;
                      _pendingAttachPath = null;
                    }),
                    child: Text(l10n.attachClear),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Row(
                    textDirection: composerBarDirection,
                    children: [
                      IconButton(
                        onPressed: _sending
                            ? null
                            : () => setState(() => _panelOpen = !_panelOpen),
                        icon: Icon(
                          _panelOpen ? Icons.close : Icons.add_circle_outline,
                        ),
                        color: ObicColors.blue,
                      ),
                      ChatHoldToTalkButton(
                        compact: true,
                        enabled: !_sending,
                        holdLabel: l10n.chatHoldToTalk,
                        releaseLabel: l10n.chatReleaseToSend,
                        cancelLabel: l10n.chatSlideToCancel,
                        tooShortLabel: l10n.chatVoiceTooShort,
                        micDeniedLabel: l10n.chatMicPermissionDenied,
                        onRecorded: _sendVoiceNote,
                        onSendText: _sendTyped,
                        transcribe: _transcribeVoiceFile,
                        onError: _toast,
                      ),
                      Expanded(
                        child: _voiceMode
                            ? ChatHoldToTalkButton(
                                enabled: !_sending,
                                holdLabel: l10n.chatHoldToTalk,
                                releaseLabel: l10n.chatReleaseToSend,
                                cancelLabel: l10n.chatSlideToCancel,
                                tooShortLabel: l10n.chatVoiceTooShort,
                                micDeniedLabel: l10n.chatMicPermissionDenied,
                                onRecorded: _sendVoiceNote,
                                onSendText: _sendTyped,
                                transcribe: _transcribeVoiceFile,
                                onError: _toast,
                              )
                            : TextField(
                                controller: _input,
                                minLines: 1,
                                maxLines: 4,
                                textDirection: _composerDirection,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.multiline,
                                textInputAction: _enterToSend
                                    ? TextInputAction.send
                                    : TextInputAction.newline,
                                decoration: InputDecoration(
                                  hintText: l10n.chatInputHint,
                                  hintTextDirection: Directionality.of(context),
                                  filled: true,
                                  fillColor: ObicColors.surfaceOf(context),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: ObicColors.lineOf(context),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: ObicColors.lineOf(context),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                ),
                                onTap: () {
                                  if (_panelOpen) {
                                    setState(() => _panelOpen = false);
                                  }
                                },
                                onSubmitted: (_) {
                                  if (_enterToSend) _send();
                                },
                              ),
                      ),
                      const SizedBox(width: 4),
                      if (!_voiceMode)
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
                          style: IconButton.styleFrom(
                            backgroundColor: ObicColors.blue,
                          ),
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Transform.flip(
                                  flipX: !rtl,
                                  child: const Icon(Icons.send_rounded),
                                ),
                        ),
                    ],
                  ),
                ),
                if (_panelOpen)
                  _WeChatAttachPanel(arabic: arabic, onAction: _onPanelAction),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeChatAttachPanel extends StatelessWidget {
  const _WeChatAttachPanel({required this.arabic, required this.onAction});

  final bool arabic;
  final Future<void> Function(String id) onAction;

  @override
  Widget build(BuildContext context) {
    final items = <({String id, IconData icon, String en, String ar})>[
      (id: 'gallery', icon: Icons.photo_outlined, en: 'Album', ar: 'الألبوم'),
      (
        id: 'camera',
        icon: Icons.photo_camera_outlined,
        en: 'Camera',
        ar: 'الكاميرا',
      ),
      (
        id: 'video',
        icon: Icons.movie_creation_outlined,
        en: 'Video',
        ar: 'فيديو',
      ),
      (
        id: 'video_call',
        icon: Icons.videocam_outlined,
        en: 'Video Call',
        ar: 'مكالمة فيديو',
      ),
      (
        id: 'location',
        icon: Icons.location_on_outlined,
        en: 'Location',
        ar: 'الموقع',
      ),
      (id: 'voice', icon: Icons.mic_none_rounded, en: 'Voice', ar: 'صوت'),
      (
        id: 'favorites',
        icon: Icons.favorite_border_rounded,
        en: 'Favorites',
        ar: 'المفضلة',
      ),
      (
        id: 'sticker',
        icon: Icons.emoji_emotions_outlined,
        en: 'Stickers',
        ar: 'ملصقات',
      ),
      (
        id: 'voice_call',
        icon: Icons.call_outlined,
        en: 'Voice Call',
        ar: 'مكالمة صوتية',
      ),
      (
        id: 'contact',
        icon: Icons.person_outline_rounded,
        en: 'Contact Card',
        ar: 'بطاقة جهة اتصال',
      ),
      (
        id: 'files',
        icon: Icons.folder_open_outlined,
        en: 'Files',
        ar: 'الملفات',
      ),
    ];

    return _ObicTileGrid(
      background: ObicColors.navy,
      tileColor: ObicColors.navySoft,
      labelColor: const Color(0xFFE2E8F0),
      iconColor: Colors.white,
      items: [
        for (final item in items)
          (
            id: item.id,
            icon: item.icon,
            label: item.id == 'voice_call'
                ? obicPhrase(context, ar: 'مكالمة صوتية', en: 'Voice call', zh: '语音通话')
                : item.id == 'video_call'
                    ? obicPhrase(context, ar: 'مكالمة فيديو', en: 'Video call', zh: '视频通话')
                    : (arabic ? item.ar : item.en),
          ),
      ],
      onTap: onAction,
    );
  }
}

class _ObicActionGridSheet extends StatelessWidget {
  const _ObicActionGridSheet({required this.title, required this.items});

  final String title;
  final List<({String id, IconData icon, String en, String ar})> items;

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          color: ObicColors.navy,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            _ObicTileGrid(
              background: Colors.transparent,
              tileColor: ObicColors.navySoft,
              labelColor: const Color(0xFFE2E8F0),
              iconColor: Colors.white,
              items: [
                for (final item in items)
                  (
                    id: item.id,
                    icon: item.icon,
                    label: arabic ? item.ar : item.en,
                  ),
              ],
              onTap: (id) async {
                Navigator.pop(context, id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ObicTileGrid extends StatelessWidget {
  const _ObicTileGrid({
    required this.background,
    required this.tileColor,
    required this.labelColor,
    required this.iconColor,
    required this.items,
    required this.onTap,
  });

  final Color background;
  final Color tileColor;
  final Color labelColor;
  final Color iconColor;
  final List<({String id, IconData icon, String label})> items;
  final Future<void> Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 8,
        childAspectRatio: 0.88,
        children: [
          for (final item in items)
            InkWell(
              onTap: () => onTap(item.id),
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ObicColors.blue.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(item.icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.onTap,
    required this.busy,
  });

  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: busy ? null : onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
