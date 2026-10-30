// Made by Dr Ali
// Messages tab — thread list + open support chat (auth required).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/active_chat_tracker.dart';
import '../../core/app_foreground.dart';
import '../../core/connectivity_service.dart';
import '../../core/message_sync_gate.dart';
import '../../core/api_errors.dart';
import '../../core/offline_cache_store.dart';
import '../../core/realtime_client.dart';
import '../shell/tab_badge.dart';
import '../../theme/obic_colors.dart';
import '../../theme/obic_elevation.dart';
import '../../widgets/obic_surface.dart';
import '../../widgets/offline_banner.dart';
import '../ai/obic_ai_avatar.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../moments/moment_avatar.dart';
import '../social/social_api.dart';
import 'app_sounds.dart';
import 'unread_count.dart';
import 'chat_call_body.dart';
import 'obic_stickers.dart';
import 'chat_draft_store.dart';
import 'chat_list_row.dart';
import 'chat_screen.dart';
import 'group_avatar_collage.dart';
import 'message_search.dart';
import 'wechat_context_menu.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({
    super.key,
    required this.authController,
    this.isActive = false,
    this.onUnreadTotalChanged,
    this.listQuery = '',
  });

  final AuthController authController;

  /// True when this tab is the selected bottom-nav destination.
  final bool isActive;
  final ValueChanged<int>? onUnreadTotalChanged;

  /// WeChat search box on the chat list.
  final String listQuery;

  @override
  State<MessagesTab> createState() => MessagesTabState();
}

class MessagesTabState extends State<MessagesTab> {
  final _api = SocialApi();
  List<Map<String, dynamic>> _threads = [];

  /// threadId → draft text (WeChat list preview).
  Map<String, String> _drafts = {};
  int _searchGen = 0;
  bool _searching = false;
  String _appliedQuery = '';
  List<Map<String, dynamic>> _nameHits = [];
  List<ThreadHistoryMatch> _historyHits = [];

  /// A list refresh was requested while one was already running. The in-flight
  /// response can be older than a message that just arrived, so we load again.
  bool _reloadQueued = false;

  /// Message ids already applied to the list (socket echo + local send).
  final Set<String> _appliedInboxIds = {};

  /// Threads a new message brought back while the server still marks them hidden.
  final Set<String> _broughtBackIds = {};

  /// Optimistic sends that failed before the server accepted them.
  final Set<String> _rejectedInboxIds = {};
  ChatListFilter _filter = ChatListFilter.all;

  /// Threads marked read on this device before the server confirms.
  final Set<String> _pendingRead = {};
  bool _loading = false;
  String? _error;
  Timer? _pollTimer;

  /// HTTP fallback; slows further when [MessageSyncGate.realtimeLive].
  static const _pollInterval = Duration(seconds: 12);
  static const _pollIntervalWithRealtime = Duration(seconds: 45);
  Future<void>? _loadInFlight;
  StreamSubscription<Map<String, dynamic>>? _rtMsgSub;

  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuth);
    AppForeground.instance.addListener(_onForegroundChanged);
    MessageSyncGate.instance.addListener(_onRealtimeChanged);
    _rtMsgSub = RealtimeClient.instance.onInboxMessage.listen(_onInboxMessage);
    if (widget.authController.isAuthenticated) {
      _load();
      _startPolling();
    }
    unawaited(_reloadDrafts());
  }

  @override
  void didUpdateWidget(MessagesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load(silent: true);
      unawaited(_reloadDrafts());
      _startPolling();
    } else if (!widget.isActive && oldWidget.isActive) {
      // IndexedStack keeps us alive — stop HTTP when tab hidden.
      _stopPolling();
    }
    if (widget.listQuery != oldWidget.listQuery) {
      _scheduleSearch();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _rtMsgSub?.cancel();
    AppForeground.instance.removeListener(_onForegroundChanged);
    MessageSyncGate.instance.removeListener(_onRealtimeChanged);
    widget.authController.removeListener(_onAuth);
    super.dispose();
  }

  void _onForegroundChanged() {
    if (AppForeground.instance.isActive && widget.isActive) {
      _startPolling();
      unawaited(_load(silent: true));
    } else {
      _stopPolling();
    }
  }

  void _onRealtimeChanged() => _startPolling();

  void _startPolling() {
    _pollTimer?.cancel();
    if (!widget.isActive || !AppForeground.instance.isActive) return;
    if (!widget.authController.isAuthenticated) return;
    final interval = MessageSyncGate.instance.realtimeLive
        ? _pollIntervalWithRealtime
        : _pollInterval;
    _pollTimer = Timer.periodic(interval, (_) {
      if (!widget.authController.isAuthenticated) return;
      if (!AppForeground.instance.isActive || !widget.isActive) return;
      if (ConnectivityService.instance.isOffline) return;
      // When WS is live, HTTP is backup only (already on slow interval).
      unawaited(_load(silent: true));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  int _threadUnread(Map<String, dynamic> thread, {int index = 0}) {
    final id = thread['id']?.toString();
    // WeChat: open or muted conversation never shows a list badge.
    if (ActiveChatTracker.instance.suppressesUnreadBadge(id)) return 0;
    if (thread['muted'] == true) return 0;
    final n = threadUnreadCount(
      thread,
      myUserId: widget.authController.user?.id,
    );
    // Screenshot QA: ensure a few rows show circular avatar badges.
    if (const bool.fromEnvironment('BADGE_DEMO') && n <= 0) {
      const demos = [3, 1, 12];
      if (index < demos.length) return demos[index];
    }
    return n;
  }

  void _notifyUnreadTotal(List<Map<String, dynamic>> rows) {
    final myId = widget.authController.user?.id;
    final openId = ActiveChatTracker.instance.conversationId;
    var total = 0;
    for (final t in rows) {
      final id = t['id']?.toString();
      if (openId != null && id == openId) continue;
      if (ActiveChatTracker.instance.isMuted(id) || t['muted'] == true) {
        continue;
      }
      total += threadUnreadCount(t, myUserId: myId);
    }
    widget.onUnreadTotalChanged?.call(total);
  }

  /// Zero one thread's unread locally and push the new total to the shell.
  void _zeroThreadUnreadLocally(String threadId) {
    final next = [
      for (final t in _threads)
        if (t['id'] == threadId) {...t, 'unreadCount': 0} else t,
    ];
    if (!mounted) return;
    setState(() => _threads = next);
    _notifyUnreadTotal(next);
  }

  Future<void> _reloadDrafts() async {
    final all = await ChatDraftStore.instance.loadAll();
    if (!mounted) return;
    setState(() => _drafts = all);
  }

  void _toast(String message) {
    if (!mounted) return;
    if (message.toLowerCase().contains('phoneactivationrequired')) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _shownError(Object error) {
    return friendlyApiError(
      classifyTransportError(error),
      l10n: AppLocalizations.of(context),
      langCode: Localizations.localeOf(context).languageCode,
    );
  }

  Future<void> _persistThreads() async {
    final userId = widget.authController.user?.id ?? '';
    if (userId.isEmpty) return;
    await OfflineCacheStore.instance.saveThreads(userId, _threads);
  }

  List<Map<String, dynamic>> _withPendingRead(List<Map<String, dynamic>> rows) {
    if (_pendingRead.isEmpty) return rows;
    return [
      for (final t in rows)
        if (_pendingRead.contains(t['id']?.toString()))
          {...t, 'unreadCount': 0}
        else
          t,
    ];
  }

  /// Existing API has no bulk mark-read. [listMessages] marks one thread read.
  Future<void> _flushPendingReads() async {
    if (_pendingRead.isEmpty) return;
    if (ConnectivityService.instance.isOffline) return;
    final token = await widget.authController.ensureAccessToken();
    if (token == null) return;
    for (final id in _pendingRead.toList()) {
      try {
        await _api.listMessages(accessToken: token, threadId: id);
        _pendingRead.remove(id);
      } catch (_) {}
    }
  }

  /// Local unread clear, then the existing per-thread read API when online.
  Future<void> markAllRead() async {
    if (!widget.authController.isAuthenticated || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final ids = <String>[
      for (final t in _threads)
        if (_threadUnread(t) > 0) t['id']?.toString() ?? '',
    ].where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) {
      _toast(l10n.messagesMarkAllReadDone);
      return;
    }
    setState(() {
      _threads = [
        for (final t in _threads) {...t, 'unreadCount': 0},
      ];
    });
    _pendingRead.addAll(ids);
    _notifyUnreadTotal(_threads);
    await _persistThreads();
    if (!ConnectivityService.instance.isOffline) {
      await _flushPendingReads();
      await _load(silent: true);
    }
    _toast(l10n.messagesMarkAllReadDone);
  }

  Future<void> _markThreadRead(String threadId) async {
    _pendingRead.add(threadId);
    _zeroThreadUnreadLocally(threadId);
    await _persistThreads();
    if (ConnectivityService.instance.isOffline) return;
    await _flushPendingReads();
    await _load(silent: true);
  }

  /// Server prefs: pin, mute, hide, delete, mark unread. Returns false if skipped.
  Future<bool> _patchThread({
    required String threadId,
    bool? pinned,
    bool? muted,
    bool? markUnread,
    bool? hidden,
    bool? deleteChat,
  }) async {
    if (ConnectivityService.instance.isOffline) {
      _toast(offlineNeedsNetworkMessage(AppLocalizations.of(context)));
      return false;
    }
    final token = await widget.authController.ensureAccessToken();
    if (token == null) return false;
    try {
      await _api.updateThreadPrefs(
        accessToken: token,
        threadId: threadId,
        pinned: pinned,
        muted: muted,
        markUnread: markUnread,
        hidden: hidden,
        deleteChat: deleteChat,
      );
    } catch (e) {
      _toast(_shownError(e));
      return false;
    }
    if (!mounted) return false;
    if (markUnread == true) _pendingRead.remove(threadId);
    if (muted != null) {
      ActiveChatTracker.instance.setMuted(threadId, muted);
    }
    if (hidden == true || deleteChat == true) {
      setState(() {
        _threads = _threads.where((t) => t['id'] != threadId).toList();
      });
      _notifyUnreadTotal(_threads);
      await _persistThreads();
      return true;
    }
    if (markUnread == true) {
      setState(() {
        _threads = [
          for (final t in _threads)
            if (t['id'] == threadId)
              {
                ...t,
                'unreadCount':
                    (t['unreadCount'] is num && (t['unreadCount'] as num) > 0)
                    ? t['unreadCount']
                    : 1,
              }
            else
              t,
        ];
      });
      _notifyUnreadTotal(_threads);
    }
    if (pinned != null || muted != null) {
      setState(() {
        _threads = [
          for (final t in _threads)
            if (t['id'] == threadId)
              _withPinMute(t, pinned: pinned, muted: muted)
            else
              t,
        ];
      });
      if (muted == true) _notifyUnreadTotal(_threads);
    }
    await _load(silent: true);
    return true;
  }

  Map<String, dynamic> _withPinMute(
    Map<String, dynamic> thread, {
    required bool? pinned,
    required bool? muted,
  }) {
    final next = Map<String, dynamic>.from(thread);
    if (pinned != null) next['pinned'] = pinned;
    if (muted != null) next['muted'] = muted;
    if (muted == true) next['unreadCount'] = 0;
    return next;
  }

  Future<void> _onThreadLongPress(
    LongPressStartDetails details,
    Map<String, dynamic> thread,
  ) async {
    final id = thread['id']?.toString();
    if (id == null || id.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final pinned = thread['pinned'] == true;
    final muted = thread['muted'] == true;
    final unread = _threadUnread(thread);
    final choice = await showWeChatContextMenu(
      context: context,
      globalPosition: details.globalPosition,
      items: [
        (
          id: unread > 0 ? 'read' : 'unread',
          label: unread > 0 ? l10n.chatMarkRead : l10n.chatMarkUnread,
        ),
        (id: 'pin', label: pinned ? l10n.chatUnpin : l10n.chatPin),
        (id: 'mute', label: muted ? l10n.chatUnmute : l10n.chatMute),
        (id: 'hide', label: l10n.chatHide),
        (id: 'delete', label: l10n.chatDelete),
      ],
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'read':
        await _markThreadRead(id);
      case 'unread':
        await _patchThread(threadId: id, markUnread: true);
      case 'pin':
        await _patchThread(threadId: id, pinned: !pinned);
      case 'mute':
        final ok = await _patchThread(threadId: id, muted: !muted);
        if (ok && mounted) {
          _toast(muted ? l10n.chatUnmuted : l10n.chatMuted);
        }
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
        if (ok == true) await _patchThread(threadId: id, hidden: true);
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
        if (ok == true) await _patchThread(threadId: id, deleteChat: true);
      default:
        break;
    }
  }

  void _onAuth() {
    if (widget.authController.isAuthenticated) {
      _load();
      _startPolling();
    } else {
      _stopPolling();
      if (mounted) {
        widget.onUnreadTotalChanged?.call(0);
        _pendingRead.clear();
        setState(() {
          _threads = [];
          _filter = ChatListFilter.all;
          _error = null;
        });
      }
    }
  }

  String _threadKind(Map<String, dynamic> thread) =>
      (thread['kind'] as String? ?? 'direct').trim().toLowerCase();

  bool _isServiceThread(Map<String, dynamic> thread) {
    final kind = _threadKind(thread);
    return kind == 'order' || kind == 'support';
  }

  bool _matchesFilter(Map<String, dynamic> thread, ChatListFilter filter) {
    switch (filter) {
      case ChatListFilter.all:
        return true;
      case ChatListFilter.unread:
        return _threadUnread(thread) > 0;
      case ChatListFilter.groups:
        return _threadKind(thread) == 'group';
      case ChatListFilter.services:
        return _isServiceThread(thread);
    }
  }

  ChatListFilter get _effectiveFilter {
    final hasGroups = _threads.any(
      (t) => t['hidden'] != true && _threadKind(t) == 'group',
    );
    final hasServices = _threads.any(
      (t) => t['hidden'] != true && _isServiceThread(t),
    );
    if (_filter == ChatListFilter.groups && !hasGroups) {
      return ChatListFilter.all;
    }
    if (_filter == ChatListFilter.services && !hasServices) {
      return ChatListFilter.all;
    }
    return _filter;
  }

  List<Map<String, dynamic>> _visibleThreads() {
    final filter = _effectiveFilter;
    final visible = _sourceThreads.where((t) {
      if (t['hidden'] == true) return false;
      return _matchesFilter(t, filter);
    }).toList();
    visible.sort(compareChatThreads);
    return visible;
  }

  /// Screenshot QA threads when API/auth has none (BADGE_DEMO builds only).
  List<Map<String, dynamic>> get _sourceThreads {
    if (_threads.isNotEmpty) return _threads;
    if (!const bool.fromEnvironment('BADGE_DEMO')) return _threads;
    return [
      {
        'id': 'badge-demo-1',
        'kind': 'support',
        'title': 'OBIC Support',
        'unreadCount': 3,
        'lastMessage': {'body': 'مرحباً — كيف نساعدك؟'},
        'participants': [
          {'name': 'Support', 'userId': 'staff'},
        ],
      },
      {
        'id': 'badge-demo-2',
        'kind': 'dm',
        'title': 'Ali',
        'unreadCount': 1,
        'lastMessage': {'body': 'OK'},
        'participants': [
          {'name': 'Ali', 'userId': 'u2'},
        ],
      },
      {
        'id': 'badge-demo-3',
        'kind': 'group',
        'title': 'Yiwu desk',
        'unreadCount': 12,
        'lastMessage': {'body': 'Document received'},
        'participants': [
          {'name': 'A', 'userId': 'a'},
          {'name': 'B', 'userId': 'b'},
        ],
      },
    ];
  }

  void _onInboxMessage(Map<String, dynamic> payload) {
    if (!widget.authController.isAuthenticated) return;
    if (!AppForeground.instance.isActive) return;
    final convId = payload['conversationId']?.toString();
    final raw = payload['message'];
    if (convId == null || convId.isEmpty || raw is! Map) {
      unawaited(_load(silent: true));
      return;
    }
    _applyInboxMessage(convId, Map<String, dynamic>.from(raw));
  }

  /// WeChat: the row updates now. A later HTTP reload must not wipe this.
  void _applyInboxMessage(String convId, Map<String, dynamic> msg) {
    final msgId = msg['id']?.toString() ?? '';
    if (msg['failed'] == true) {
      if (msgId.isNotEmpty) {
        if (_rejectedInboxIds.length > 200) _rejectedInboxIds.clear();
        _rejectedInboxIds.add(msgId);
      }
      unawaited(_load(silent: true));
      return;
    }
    final fresh = msgId.isEmpty || _rememberInboxId(msgId);
    final myId = widget.authController.user?.id;
    final senderId = msg['senderId']?.toString();
    final mine = myId != null && senderId != null && senderId == myId;
    final open = ActiveChatTracker.instance.isOpen(convId);
    final mutedByTracker = ActiveChatTracker.instance.isMuted(convId);
    if (fresh && !open && !mutedByTracker) {
      unawaited(AppSounds.instance.playMessage());
    }

    final createdAt = _inboxMessageTime(msg);
    final last = <String, dynamic>{
      'id': msgId.isEmpty ? null : msgId,
      'body': msg['recalled'] == true ? '' : msg['body'],
      'attachmentKind': msg['attachmentKind'],
      'attachmentName': msg['attachmentName'],
      'senderId': senderId,
      'recalled': msg['recalled'] == true,
      'createdAt': createdAt,
    };

    final idx = _threads.indexWhere((t) => t['id']?.toString() == convId);
    final wasHidden = idx < 0 || _threads[idx]['hidden'] == true;
    final thread = idx >= 0
        ? Map<String, dynamic>.from(_threads[idx])
        : _stubThread(convId, msg, myId);
    thread['hidden'] = false;
    thread['lastMessage'] = last;
    thread['updatedAt'] = createdAt;
    final muted = thread['muted'] == true || mutedByTracker;
    if (open || mine || _pendingRead.contains(convId)) {
      thread['unreadCount'] = 0;
    } else if (!muted && fresh) {
      final n = thread['unreadCount'];
      final current = n is num ? n.toInt() : int.tryParse('$n') ?? 0;
      thread['unreadCount'] = current + 1;
    }

    final next = [..._threads];
    if (idx >= 0) {
      next[idx] = thread;
    } else {
      next.add(thread);
    }
    if (wasHidden) _broughtBackIds.add(convId);
    if (!mounted) return;
    setState(() => _threads = next);
    _notifyUnreadTotal(next);
    unawaited(_persistThreads());
    if (msgId.isNotEmpty && !msgId.startsWith('pending_')) {
      unawaited(OfflineCacheStore.instance.appendMessage(convId, msg));
    }
    _scheduleSearch();
    if (wasHidden) unawaited(_unhideOnServer(convId));
    unawaited(_load(silent: true));
  }

  bool _rememberInboxId(String id) {
    if (_appliedInboxIds.length > 400) _appliedInboxIds.clear();
    return _appliedInboxIds.add(id);
  }

  String _inboxMessageTime(Map<String, dynamic> msg) {
    final raw = msg['createdAt'];
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw != null) {
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) return parsed.toUtc().toIso8601String();
    }
    return DateTime.now().toUtc().toIso8601String();
  }

  Map<String, dynamic> _stubThread(
    String convId,
    Map<String, dynamic> msg,
    String? myId,
  ) {
    final participants = <Map<String, dynamic>>[];
    if (myId != null && myId.isNotEmpty) {
      participants.add({
        'userId': myId,
        'name': widget.authController.user?.name,
      });
    }
    final senderId = msg['senderId']?.toString();
    if (senderId != null && senderId.isNotEmpty && senderId != myId) {
      participants.add({
        'userId': senderId,
        'name': msg['senderName'],
        'avatarUrl': msg['senderAvatarUrl'],
      });
    }
    return {
      'id': convId,
      'kind': 'direct',
      'hidden': false,
      'pinned': false,
      'muted': false,
      'unreadCount': 0,
      'participants': participants,
    };
  }

  Future<void> _unhideOnServer(String threadId) async {
    if (ConnectivityService.instance.isOffline) return;
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      await _api.updateThreadPrefs(
        accessToken: token,
        threadId: threadId,
        hidden: false,
      );
    } catch (_) {}
    if (mounted) unawaited(_load(silent: true));
  }

  bool _localPreviewNewer(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final localAt = threadActivityAt(local);
    if (localAt == null) return false;
    final last = local['lastMessage'];
    if (last is Map) {
      final id = last['id']?.toString() ?? '';
      if (id.isNotEmpty && _rejectedInboxIds.contains(id)) return false;
    }
    final remoteAt = threadActivityAt(remote);
    if (remoteAt == null) return true;
    return localAt.isAfter(remoteAt);
  }

  /// Keep a just-arrived preview when the HTTP list is still older, and keep
  /// a thread a new message brought back while the server still omits it.
  List<Map<String, dynamic>> _mergeServerThreads(
    List<Map<String, dynamic>> server,
  ) {
    final localById = <String, Map<String, dynamic>>{
      for (final t in _threads)
        if ((t['id']?.toString() ?? '').isNotEmpty) t['id'].toString(): t,
    };
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];
    for (final raw in server) {
      final id = raw['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      seen.add(id);
      final local = localById[id];
      if (local != null && _localPreviewNewer(local, raw)) {
        merged.add({
          ...raw,
          'lastMessage': local['lastMessage'],
          'updatedAt': local['updatedAt'] ?? raw['updatedAt'],
          'unreadCount': local['unreadCount'] ?? raw['unreadCount'],
          'hidden': false,
        });
      } else {
        merged.add(raw);
      }
    }
    for (final id in Set<String>.from(_broughtBackIds)) {
      if (seen.contains(id)) {
        _broughtBackIds.remove(id);
        continue;
      }
      final local = localById[id];
      if (local != null) merged.add(local);
    }
    return merged;
  }

  Future<void> _load({bool silent = false}) async {
    if (!widget.authController.isAuthenticated) return;
    final existing = _loadInFlight;
    if (existing != null) {
      _reloadQueued = true;
      await existing;
      return;
    }
    final done = _loadInner(silent: silent);
    _loadInFlight = done;
    try {
      await done;
    } finally {
      if (identical(_loadInFlight, done)) _loadInFlight = null;
      if (_reloadQueued) {
        _reloadQueued = false;
        if (mounted) unawaited(_load(silent: true));
      }
    }
  }

  Future<void> _paintCachedThreads(String userId) async {
    if (userId.isEmpty || _threads.isNotEmpty) return;
    final cached = await OfflineCacheStore.instance.loadThreads(userId);
    if (!mounted || _threads.isNotEmpty) return;
    if (cached == null || cached.isEmpty) return;
    final shown = _withPendingRead(cached);
    _notifyUnreadTotal(shown);
    setState(() {
      _threads = shown;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _loadInner({bool silent = false}) async {
    final userId = widget.authController.user?.id ?? '';
    await _paintCachedThreads(userId);
    if (!mounted) return;
    if (ConnectivityService.instance.isOffline) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }
    if (!silent && _threads.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw AuthApiException('Not signed in');
      final rows = await _api.listThreads(token);
      if (!mounted) return;
      ActiveChatTracker.instance.syncMutedFromThreads(rows);
      final shown = _withPendingRead(_mergeServerThreads(rows));
      if (userId.isNotEmpty) {
        unawaited(OfflineCacheStore.instance.saveThreads(userId, shown));
      }
      _notifyUnreadTotal(shown);
      if (silent && _sameThreadSnapshot(_threads, shown)) {
        return;
      }
      setState(() {
        _threads = shown;
        _loading = false;
        _error = null;
      });
      _scheduleSearch();
    } catch (e) {
      if (!mounted) return;
      if (_threads.isEmpty) {
        final cached = userId.isEmpty
            ? null
            : await OfflineCacheStore.instance.loadThreads(userId);
        if (!mounted) return;
        if (cached != null && cached.isNotEmpty) {
          final shown = _withPendingRead(cached);
          _notifyUnreadTotal(shown);
          setState(() {
            _threads = shown;
            _loading = false;
            _error = null;
          });
          _scheduleSearch();
          return;
        }
      }
      if (!silent) {
        final offline = ConnectivityService.instance.isOffline;
        setState(() {
          _loading = false;
          if (_threads.isEmpty && !offline) {
            _error = _shownError(e);
          } else {
            _error = null;
          }
        });
      }
    }
  }

  bool _sameThreadSnapshot(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i]['id'] != b[i]['id']) return false;
      if (a[i]['unreadCount'] != b[i]['unreadCount']) return false;
      if (a[i]['pinned'] != b[i]['pinned']) return false;
      if (a[i]['muted'] != b[i]['muted']) return false;
      final la = a[i]['lastMessage'];
      final lb = b[i]['lastMessage'];
      if (la is Map && lb is Map) {
        if (la['id'] != lb['id'] || la['body'] != lb['body']) return false;
      } else if (la != lb) {
        return false;
      }
    }
    return true;
  }

  Future<void> _openSupport() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;
    if (ConnectivityService.instance.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            offlineNeedsNetworkMessage(AppLocalizations.of(context)),
          ),
        ),
      );
      return;
    }
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      final thread = await _api.openSupportThread(token);
      if (!mounted) return;
      final id = thread['id']?.toString();
      if (id == null || id.isEmpty) return;
      final l10n = AppLocalizations.of(context);
      _zeroThreadUnreadLocally(id);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            authController: widget.authController,
            threadId: id,
            title: l10n.chatSupportTitle,
            initialKind: 'support',
            onThreadOpened: () {
              if (!mounted) return;
              _zeroThreadUnreadLocally(id);
            },
          ),
        ),
      );
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_shownError(e))));
    }
  }

  String _peerLabel(Map<String, dynamic> thread, AppLocalizations l10n) {
    final kind = thread['kind'] as String? ?? 'direct';
    if (kind == 'support') {
      final title = (thread['title'] as String?)?.trim();
      if (title != null && title.isNotEmpty) return title;
      return l10n.chatSupportTitle;
    }
    if (kind == 'order') {
      final title = (thread['title'] as String?)?.trim();
      if (title != null && title.isNotEmpty) return title;
      final id = (thread['orderId'] as String?) ?? '';
      final short = id.length >= 8 ? id.substring(0, 8).toUpperCase() : id;
      return short.isEmpty ? l10n.ordersTitle : '${l10n.ordersTitle} · $short';
    }
    if (kind == 'group') {
      final title = (thread['title'] as String?)?.trim();
      if (title != null && title.isNotEmpty) return title;
      return l10n.chatGroup;
    }
    final parts = thread['participants'];
    if (parts is! List) return l10n.messagesTitle;
    final myId = widget.authController.user?.id;
    for (final p in parts) {
      if (p is Map && p['userId'] != myId) {
        return (p['name'] as String?) ?? l10n.messagesTitle;
      }
    }
    return l10n.messagesTitle;
  }

  String _previewText(Map<String, dynamic> thread, AppLocalizations l10n) {
    final last = thread['lastMessage'];
    var preview = last is Map
        ? ((last['body'] as String?)?.isNotEmpty == true
              ? last['body'] as String
              : (last['attachmentKind'] as String?) ?? '')
        : l10n.messagesNoPreview;
    if (parseObicSticker(preview) != null) {
      final sticker = parseObicSticker(preview)!;
      final arabic = Localizations.localeOf(context).languageCode == 'ar';
      preview = arabic ? 'ملصق ${sticker.ar}' : 'Sticker ${sticker.en}';
    } else if (preview.startsWith('[[status]]')) {
      preview = l10n.ordersTitle;
    } else if (parseCallRecordBody(preview) != null) {
      final rec = parseCallRecordBody(preview)!;
      final mine =
          last is Map && last['senderId'] == widget.authController.user?.id;
      preview = callRecordLabel(
        rec,
        arabic: Localizations.localeOf(context).languageCode == 'ar',
        mine: mine,
        myUserId: widget.authController.user?.id,
        lang: Localizations.localeOf(context).languageCode,
      );
    } else if (preview == 'audio' ||
        (last is Map &&
            (last['attachmentKind'] as String?) == 'audio' &&
            ((last['body'] as String?) ?? '').isEmpty)) {
      preview = l10n.chatPreviewVoice;
    } else if (preview == 'video' ||
        (last is Map &&
            (last['attachmentKind'] as String?) == 'video' &&
            ((last['body'] as String?) ?? '').isEmpty)) {
      preview = l10n.chatPreviewVideo;
    } else if (preview == 'image' ||
        (last is Map &&
            (last['attachmentKind'] as String?) == 'image' &&
            ((last['body'] as String?) ?? '').isEmpty)) {
      preview = l10n.chatPreviewImage;
    } else if (preview == 'file' ||
        (last is Map &&
            (last['attachmentKind'] as String?) == 'file' &&
            ((last['body'] as String?) ?? '').isEmpty)) {
      preview = l10n.chatPreviewFile;
    }
    if (last is Map && last['recalled'] == true) {
      preview = l10n.chatRecalledPeer;
    }
    return preview;
  }

  Widget _previewLine(
    Map<String, dynamic> thread,
    AppLocalizations l10n,
    int unread,
  ) {
    final threadId = thread['id']?.toString() ?? '';
    final draft = _drafts[threadId];
    final hasDraft = draft != null && draft.trim().isNotEmpty;
    final mutedStyle = TextStyle(
      color: ObicColors.mutedOf(context),
      fontSize: 14,
      height: 1.2,
    );
    if (hasDraft) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${l10n.chatDraftPrefix} ',
              style: const TextStyle(
                color: ObicColors.badgeRed,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            TextSpan(text: draft, style: mutedStyle),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: chatTextDirection(draft),
      );
    }
    final preview = _previewText(thread, l10n);
    return Text(
      preview,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: chatTextDirection(preview),
      style: TextStyle(
        color: unread > 0
            ? ObicColors.titleOf(context)
            : ObicColors.mutedOf(context),
        fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
        fontSize: 14,
        height: 1.2,
      ),
    );
  }

  Widget _avatarFor(Map<String, dynamic> thread, AppLocalizations l10n) {
    const size = 48.0;
    final kind = _threadKind(thread);
    final parts = (thread['participants'] as List?) ?? [];
    final myId = widget.authController.user?.id;
    final isGroupUi = isWeChatGroupConversation(
      kind: kind,
      otherParticipantCount: countOtherParticipants(
        participants: parts,
        myUserId: myId,
      ),
    );
    if (isGroupUi) {
      return GroupAvatarCollage(
        size: size,
        members: parts
            .whereType<Map>()
            .map(
              (p) => (
                name: (p['name'] as String?) ?? '?',
                avatarUrl: p['avatarUrl'] as String?,
              ),
            )
            .toList(),
      );
    }
    if (kind == 'order') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ObicColors.blueSoftOf(context),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.receipt_long_rounded, color: ObicColors.blue),
      );
    }
    if (kind == 'support') {
      return const ObicAiAvatar(size: size, borderRadius: 6);
    }
    return MomentAvatar(
      name: _peerLabel(thread, l10n),
      avatarUrl: () {
        for (final p in parts) {
          if (p is Map && p['userId'] != myId) {
            return p['avatarUrl'] as String?;
          }
        }
        return null;
      }(),
      size: size,
      borderRadius: 6,
    );
  }

  Future<void> _openThread(
    Map<String, dynamic> thread, {
    String? focusMessageId,
  }) async {
    final id = thread['id']?.toString();
    if (id == null || id.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    _zeroThreadUnreadLocally(id);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          authController: widget.authController,
          threadId: id,
          title: _peerLabel(thread, l10n),
          initialKind: thread['kind']?.toString(),
          focusMessageId: focusMessageId,
          onThreadOpened: () {
            if (!mounted) return;
            _zeroThreadUnreadLocally(id);
          },
        ),
      ),
    );
    await _reloadDrafts();
    await _load(silent: true);
  }

  Widget _threadTile(
    Map<String, dynamic> thread,
    AppLocalizations l10n,
    int index,
  ) {
    final unread = _threadUnread(thread, index: index);
    final pinned = thread['pinned'] == true;
    final muted = thread['muted'] == true;
    final at = threadActivityAt(thread);
    final timeLabel = at == null ? '' : formatChatListTime(context, at, l10n);
    return ChatThreadTile(
      key: ValueKey(thread['id']?.toString() ?? 'row-$index'),
      avatar: ObicMenuBadgeIcon(
        size: 48,
        unread: unread,
        icon: _avatarFor(thread, l10n),
      ),
      title: _peerLabel(thread, l10n),
      preview: _previewLine(thread, l10n, unread),
      timeLabel: timeLabel,
      muted: muted,
      pinned: pinned,
      onTap: () => unawaited(_openThread(thread)),
      onLongPressStart: (d) => unawaited(_onThreadLongPress(d, thread)),
      swipeActions: [
        ChatSwipeAction(
          label: unread > 0 ? l10n.messagesSwipeRead : l10n.messagesSwipeUnread,
          background: ObicColors.navySoft,
          onPressed: () {
            final id = thread['id']?.toString();
            if (id == null || id.isEmpty) return;
            if (unread > 0) {
              unawaited(_markThreadRead(id));
            } else {
              unawaited(_patchThread(threadId: id, markUnread: true));
            }
          },
        ),
        ChatSwipeAction(
          label: pinned ? l10n.messagesSwipeUnpin : l10n.messagesSwipePin,
          background: ObicColors.blueDeep,
          onPressed: () {
            final id = thread['id']?.toString();
            if (id == null || id.isEmpty) return;
            unawaited(_patchThread(threadId: id, pinned: !pinned));
          },
        ),
        ChatSwipeAction(
          label: muted ? l10n.messagesSwipeUnmute : l10n.messagesSwipeMute,
          background: const Color(0xFF5C6B7A),
          onPressed: () {
            final id = thread['id']?.toString();
            if (id == null || id.isEmpty) return;
            unawaited(() async {
              final ok = await _patchThread(threadId: id, muted: !muted);
              if (ok && mounted) {
                _toast(muted ? l10n.chatUnmuted : l10n.chatMuted);
              }
            }());
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final signedIn = widget.authController.isAuthenticated;

    if (!signedIn) {
      if (const bool.fromEnvironment('BADGE_DEMO')) {
        // Fall through to list UI with demo threads for badge screenshots.
      } else {
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _EmptyCard(
              title: l10n.messagesTitle,
              body: l10n.messagesEmptyGuest,
              actionLabel: l10n.actionChatStaff,
              onAction: _openSupport,
            ),
          ],
        );
      }
    }

    final rows = _visibleThreads();
    final query = widget.listQuery.trim();
    final searching = query.isNotEmpty;
    final hasGroups = _sourceThreads.any(
      (t) => t['hidden'] != true && _threadKind(t) == 'group',
    );
    final hasServices = _sourceThreads.any(
      (t) => t['hidden'] != true && _isServiceThread(t),
    );
    final waiting =
        _loading &&
        _threads.isEmpty &&
        !const bool.fromEnvironment('BADGE_DEMO');
    final failed =
        _error != null &&
        _threads.isEmpty &&
        !const bool.fromEnvironment('BADGE_DEMO');
    final filteredEmpty = rows.isEmpty && _sourceThreads.isNotEmpty;

    Widget list;
    if (waiting) {
      list = ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    } else if (failed) {
      list = ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      );
    } else if (rows.isEmpty) {
      list = ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (filteredEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Text(
                    l10n.messagesFilterEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ObicColors.mutedOf(context),
                      height: 1.4,
                    ),
                  ),
                  if (widget.listQuery.trim().isEmpty &&
                      _effectiveFilter != ChatListFilter.all)
                    TextButton(
                      onPressed: () =>
                          setState(() => _filter = ChatListFilter.all),
                      child: Text(l10n.messagesFilterAll),
                    ),
                ],
              ),
            )
          else
            _EmptyCard(
              title: l10n.messagesTitle,
              body: l10n.messagesEmpty,
              actionLabel: l10n.actionChatStaff,
              onAction: _openSupport,
            ),
        ],
      );
    } else {
      list = ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        itemCount: rows.length,
        itemBuilder: (context, i) => _threadTile(rows[i], l10n, i),
      );
    }

    return ColoredBox(
      color: ObicColors.surfaceOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!searching)
            ChatListFilterBar(
              selected: _effectiveFilter,
              showGroups: hasGroups,
              showServices: hasServices,
              onChanged: (filter) => setState(() => _filter = filter),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: searching ? _searchResults(l10n, query) : list,
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleSearch() {
    final queryEmpty = widget.listQuery.trim().isEmpty;
    if (queryEmpty &&
        !_searching &&
        _appliedQuery.isEmpty &&
        _nameHits.isEmpty &&
        _historyHits.isEmpty) {
      return;
    }
    final generation = ++_searchGen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _searchGen) return;
      unawaited(_runSearch(generation));
    });
  }

  List<String> _otherNames(Map<String, dynamic> thread) {
    final parts = thread['participants'];
    if (parts is! List) return const [];
    final myId = widget.authController.user?.id;
    final names = <String>[];
    for (final participant in parts) {
      if (participant is! Map) continue;
      if (myId != null && participant['userId']?.toString() == myId) continue;
      for (final key in const ['name', 'displayName', 'nickname']) {
        final value = participant[key];
        if (value is String && value.trim().isNotEmpty) {
          names.add(value.trim());
        }
      }
    }
    return names;
  }

  Future<void> _runSearch(int generation) async {
    final raw = widget.listQuery.trim();
    if (!mounted || generation != _searchGen) return;
    if (raw.isEmpty) {
      setState(() {
        _searching = false;
        _appliedQuery = '';
        _nameHits = [];
        _historyHits = [];
      });
      return;
    }
    final l10n = AppLocalizations.of(context);
    final folded = foldSearchText(raw);
    final threads = _sourceThreads
        .where((thread) => thread['hidden'] != true)
        .toList();
    final nameHits = <Map<String, dynamic>>[];
    for (final thread in threads) {
      if (_nameMatches(thread, folded, l10n)) nameHits.add(thread);
    }
    nameHits.sort(compareChatThreads);
    final previewHistory = _historyFor(threads, folded, l10n, cached: null);
    if (!mounted || generation != _searchGen) return;
    setState(() {
      _searching = true;
      _appliedQuery = raw;
      _nameHits = nameHits;
      _historyHits = previewHistory;
    });

    final cached = await Future.wait<List<Map<String, dynamic>>?>(
      threads.map((thread) {
        final id = thread['id']?.toString() ?? '';
        if (id.isEmpty) return Future<List<Map<String, dynamic>>?>.value(null);
        return OfflineCacheStore.instance.loadMessages(id);
      }),
    );
    if (!mounted || generation != _searchGen) return;
    final history = _historyFor(threads, folded, l10n, cached: cached);
    setState(() {
      _searching = false;
      _appliedQuery = raw;
      _nameHits = nameHits;
      _historyHits = history;
    });
  }

  bool _nameMatches(
    Map<String, dynamic> thread,
    String folded,
    AppLocalizations l10n,
  ) {
    final title = asSearchText(thread['title']).trim();
    return threadNameMatches(
      foldedQuery: folded,
      displayName: _peerLabel(thread, l10n),
      title: title.isEmpty ? null : title,
      otherNames: _otherNames(thread),
    );
  }

  List<ThreadHistoryMatch> _historyFor(
    List<Map<String, dynamic>> threads,
    String folded,
    AppLocalizations l10n, {
    required List<List<Map<String, dynamic>>?>? cached,
  }) {
    final rows = <ThreadHistoryMatch>[];
    for (var i = 0; i < threads.length; i++) {
      final thread = threads[i];
      final last = thread['lastMessage'];
      final hits = historyHitsForThread(
        foldedQuery: folded,
        preview: _previewText(thread, l10n),
        lastMessage: last is Map ? Map<String, dynamic>.from(last) : null,
        cachedMessages: cached == null ? null : cached[i],
      );
      if (hits.isEmpty) continue;
      rows.add(ThreadHistoryMatch(thread: thread, hits: hits));
    }
    rows.sort((a, b) {
      final ta =
          a.hits.first.at?.millisecondsSinceEpoch ??
          threadActivityAt(a.thread)?.millisecondsSinceEpoch ??
          0;
      final tb =
          b.hits.first.at?.millisecondsSinceEpoch ??
          threadActivityAt(b.thread)?.millisecondsSinceEpoch ??
          0;
      return tb.compareTo(ta);
    });
    return rows;
  }

  String _rowTime(DateTime? at, AppLocalizations l10n) {
    if (at == null) return '';
    return formatChatListTime(context, at, l10n);
  }

  Widget _searchResults(AppLocalizations l10n, String query) {
    final settled = _appliedQuery == query && !_searching;
    final waiting = !settled && _nameHits.isEmpty && _historyHits.isEmpty;
    if (waiting) {
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (settled && _nameHits.isEmpty && _historyHits.isEmpty) {
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: ObicColors.mutedOf(context),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.messagesSearchEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final titleStyle = TextStyle(
      fontSize: 16.5,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: ObicColors.titleOf(context),
    );
    final previewStyle = TextStyle(
      color: ObicColors.mutedOf(context),
      fontSize: 14,
      height: 1.2,
    );

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        if (_nameHits.isNotEmpty) ...[
          MessageSearchSectionLabel(label: l10n.messagesSearchChats),
          for (final thread in _nameHits)
            _searchNameRow(thread, l10n, query, titleStyle, previewStyle),
        ],
        if (_searching && _historyHits.isEmpty && _nameHits.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (_historyHits.isNotEmpty) ...[
          MessageSearchSectionLabel(label: l10n.messagesSearchHistory),
          for (final row in _historyHits)
            _searchHistoryRow(row, l10n, query, titleStyle, previewStyle),
        ],
      ],
    );
  }

  Widget _searchNameRow(
    Map<String, dynamic> thread,
    AppLocalizations l10n,
    String query,
    TextStyle titleStyle,
    TextStyle previewStyle,
  ) {
    final name = _peerLabel(thread, l10n);
    final alias = matchingOtherName(
      foldedQuery: foldSearchText(query),
      displayName: name,
      otherNames: _otherNames(thread),
    );
    final preview = _previewText(thread, l10n);
    final at = threadActivityAt(thread);
    return MessageSearchResultRow(
      avatar: _avatarFor(thread, l10n),
      title: SearchHighlightText(
        text: name,
        query: query,
        style: titleStyle,
        maxLines: 1,
      ),
      preview: alias == null
          ? Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: chatTextDirection(preview),
              style: previewStyle,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchHighlightText(
                  text: alias,
                  query: query,
                  style: previewStyle,
                  maxLines: 1,
                ),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: chatTextDirection(preview),
                  style: previewStyle,
                ),
              ],
            ),
      timeLabel: _rowTime(at, l10n),
      muted: thread['muted'] == true,
      onTap: () => unawaited(_openThread(thread)),
    );
  }

  Widget _searchHistoryRow(
    ThreadHistoryMatch row,
    AppLocalizations l10n,
    String query,
    TextStyle titleStyle,
    TextStyle previewStyle,
  ) {
    final thread = row.thread;
    final hit = row.hits.first;
    final name = _peerLabel(thread, l10n);
    final at = hit.at ?? threadActivityAt(thread);
    return MessageSearchResultRow(
      avatar: _avatarFor(thread, l10n),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: titleStyle,
      ),
      preview: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchHighlightText(
            text: hit.snippet,
            query: query,
            style: previewStyle,
          ),
          if (row.hits.length > 1) ...[
            const SizedBox(height: 2),
            Text(
              l10n.messagesSearchRelated(row.hits.length),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: previewStyle.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
      timeLabel: _rowTime(at, l10n),
      muted: thread['muted'] == true,
      onTap: () =>
          unawaited(_openThread(thread, focusMessageId: hit.messageId)),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ObicSurface(
      level: ObicSurfaceLevel.raised,
      padding: const EdgeInsets.all(20),
      borderRadius: ObicElevation.radiusLg,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ObicColors.blueSoftOf(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: ObicColors.isDark(context)
                  ? ObicElevation.level0
                  : ObicElevation.level1,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: ObicColors.blue,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: ObicColors.inkOf(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: ObicColors.mutedOf(context), height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
