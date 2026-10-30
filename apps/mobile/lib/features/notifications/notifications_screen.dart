// Made by Dr Ali
// Notifications inbox — JWT + mark read; ownership enforced by API.
// Open inbox → mark-all read (badge drops). Tap → related screen.
// Live poll while open so new rows appear without leaving.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/app_foreground.dart';
import '../../core/active_chat_tracker.dart';
import '../../core/message_sync_gate.dart';
import '../../core/realtime_client.dart';
import '../../theme/obic_colors.dart';
import '../admin/admin_api.dart';
import '../admin/admin_orders_screen.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../friends/friend_alert_open.dart';
import '../friends/new_friends_screen.dart';
import '../messages/chat_screen.dart';
import '../moments/moments_screen.dart';
import '../orders/orders_tab.dart';
import '../services/services_api.dart';
import '../social/social_api.dart';
import 'notification_open.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.authController,
    this.onUnreadChanged,
  });

  final AuthController authController;

  /// Called after unread count may have changed (mark one / mark all / open).
  final Future<void> Function()? onUnreadChanged;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = SocialApi();
  final _servicesApi = ServicesApi();
  final _adminApi = AdminApi();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  Timer? _livePoll;
  Future<void>? _loadInFlight;
  StreamSubscription<Map<String, dynamic>>? _rtNotifSub;
  static const _liveInterval = Duration(seconds: 10);
  static const _liveIntervalRealtime = Duration(seconds: 40);

  @override
  void initState() {
    super.initState();
    AppForeground.instance.addListener(_onForegroundChanged);
    MessageSyncGate.instance.addListener(_onRealtimeChanged);
    _rtNotifSub = RealtimeClient.instance.onNotification.listen((payload) {
      if (!mounted || !widget.authController.isAuthenticated) return;
      if (!AppForeground.instance.isActive) return;
      final raw = payload['notification'];
      if (raw is Map) {
        final n = Map<String, dynamic>.from(raw);
        // Open chat owns that thread — never surface in inbox UI.
        if (ActiveChatTracker.instance.suppressesNotification(n)) {
          final id = n['id']?.toString();
          if (id != null && id.isNotEmpty) {
            unawaited(_dismissOpenChatRow(id));
          }
          return;
        }
      }
      unawaited(_load(silent: true, markReadWhileOpen: true));
    });
    _bootstrap();
  }

  @override
  void dispose() {
    _livePoll?.cancel();
    _rtNotifSub?.cancel();
    AppForeground.instance.removeListener(_onForegroundChanged);
    MessageSyncGate.instance.removeListener(_onRealtimeChanged);
    super.dispose();
  }

  void _onForegroundChanged() {
    if (AppForeground.instance.isActive) {
      _startLivePoll();
    } else {
      _livePoll?.cancel();
      _livePoll = null;
    }
  }

  void _onRealtimeChanged() => _startLivePoll();

  void _startLivePoll() {
    _livePoll?.cancel();
    if (!AppForeground.instance.isActive) return;
    final interval = MessageSyncGate.instance.realtimeLive
        ? _liveIntervalRealtime
        : _liveInterval;
    _livePoll = Timer.periodic(interval, (_) {
      if (!mounted || !widget.authController.isAuthenticated) return;
      if (!AppForeground.instance.isActive) return;
      unawaited(_load(silent: true, markReadWhileOpen: true));
    });
  }

  Future<void> _bootstrap() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted) return;
    if (!ok) {
      Navigator.of(context).maybePop();
      return;
    }
    await _load(markReadWhileOpen: true);
    if (mounted) _startLivePoll();
  }

  Future<void> _notifyUnreadChanged() async {
    await widget.onUnreadChanged?.call();
  }

  Future<void> _load({
    bool markReadWhileOpen = false,
    bool silent = false,
  }) async {
    final existing = _loadInFlight;
    if (existing != null) {
      await existing;
      return;
    }
    final done = _loadInner(
      markReadWhileOpen: markReadWhileOpen,
      silent: silent,
    );
    _loadInFlight = done;
    try {
      await done;
    } finally {
      if (identical(_loadInFlight, done)) _loadInFlight = null;
    }
  }

  Future<void> _loadInner({
    bool markReadWhileOpen = false,
    bool silent = false,
  }) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw AuthApiException('Not signed in');
      var rows = await _api.listNotifications(token);

      // WeChat: hide + dismiss any rows for the conversation currently open.
      final openId = ActiveChatTracker.instance.conversationId;
      if (openId != null && openId.isNotEmpty) {
        final suppress = <Map<String, dynamic>>[];
        final keep = <Map<String, dynamic>>[];
        for (final n in rows) {
          if (ActiveChatTracker.instance.suppressesNotification(n)) {
            suppress.add(n);
          } else {
            keep.add(n);
          }
        }
        if (suppress.isNotEmpty) {
          for (final n in suppress) {
            final id = n['id']?.toString();
            if (id == null || id.isEmpty) continue;
            unawaited(
              _api.dismissNotification(accessToken: token, id: id),
            );
          }
          rows = keep;
        }
      }

      final hadUnread = rows.any((n) => n['readAt'] == null);

      // While inbox is open, clear unread so Me / nav badge drops immediately.
      if (markReadWhileOpen && hadUnread) {
        await _api.markAllNotificationsRead(token);
        final now = DateTime.now().toUtc().toIso8601String();
        rows = [
          for (final n in rows)
            {
              ...n,
              'readAt': n['readAt'] ?? now,
            },
        ];
      }

      if (!mounted) return;
      final changed = !_sameIds(_items, rows) || _items.length != rows.length;
      if (silent && !changed && !hadUnread) return;
      setState(() {
        _items = rows;
        _loading = false;
        _error = null;
      });
      if (markReadWhileOpen && hadUnread) {
        await _notifyUnreadChanged();
      } else if (silent && changed) {
        // New rows while viewing — refresh shell badge snapshot.
        await _notifyUnreadChanged();
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  bool _sameIds(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i]['id'] != b[i]['id']) return false;
    }
    return true;
  }

  Future<void> _markAll() async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await _api.markAllNotificationsRead(token);
      await _load();
      await _notifyUnreadChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _markOne(String id) async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await _api.markNotificationRead(accessToken: token, id: id);
      if (!mounted) return;
      setState(() {
        _items = [
          for (final n in _items)
            if (n['id'] == id)
              {
                ...n,
                'readAt':
                    n['readAt'] ?? DateTime.now().toUtc().toIso8601String(),
              }
            else
              n,
        ];
      });
      await _notifyUnreadChanged();
    } catch (_) {}
  }

  Future<void> _dismissOpenChatRow(String id) async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await _api.dismissNotification(accessToken: token, id: id);
      if (!mounted) return;
      setState(() {
        _items = [for (final n in _items) if (n['id'] != id) n];
      });
      await _notifyUnreadChanged();
    } catch (_) {}
  }

  Future<void> _openChat({
    required String threadId,
    required String title,
  }) async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          authController: widget.authController,
          threadId: threadId,
          title: title,
        ),
      ),
    );
  }

  Future<void> _openOrderChat(String orderId, String? fallbackTitle) async {
    final token = await widget.authController.accessToken();
    if (token == null) return;
    final isStaff = widget.authController.isStaffRole;
    try {
      Map<String, dynamic> chat;
      try {
        chat = await _servicesApi.openOrderChat(
          accessToken: token,
          orderId: orderId,
        );
      } catch (_) {
        if (!isStaff) rethrow;
        chat = await _adminApi.openOrderChat(
          accessToken: token,
          orderId: orderId,
        );
      }
      final threadId = chat['conversationId']?.toString();
      final title = chat['title']?.toString() ??
          fallbackTitle ??
          (orderId.length >= 8 ? orderId.substring(0, 8) : orderId);
      if (threadId == null || !mounted) return;
      await _openChat(threadId: threadId, title: title);
    } catch (e) {
      if (!mounted) return;
      if (isStaff) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => AdminOrdersScreen(
              authController: widget.authController,
              isSuperAdmin: widget.authController.isSuperAdmin,
              canReassignOrders: widget.authController.isSuperAdmin,
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openOrdersList() async {
    final l10n = AppLocalizations.of(context);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: ObicColors.scaffoldOf(context),
          appBar: AppBar(title: Text(l10n.ordersTitle)),
          body: OrdersTab(authController: widget.authController),
        ),
      ),
    );
  }

  Future<void> _onTapItem(Map<String, dynamic> n) async {
    final id = n['id'] as String?;
    final unread = n['readAt'] == null;
    if (id != null && unread) {
      await _markOne(id);
    }
    if (!mounted) return;

    final target = NotificationOpenTarget.resolve(
      n,
      isStaff: widget.authController.isStaffRole,
    );
    final title = target.title ??
        (n['title'] as String?)?.trim() ??
        AppLocalizations.of(context).notificationsTitle;

    switch (target.dest) {
      case NotificationDest.chat:
        final threadId = target.conversationId;
        if (threadId == null) return;
        await _openChat(threadId: threadId, title: title);
      case NotificationDest.moments:
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => MomentsScreen(
              authController: widget.authController,
            ),
          ),
        );
      case NotificationDest.friends:
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => NewFriendsScreen(
              authController: widget.authController,
            ),
          ),
        );
      case NotificationDest.friendAccepted:
        if (!mounted) return;
        await openAcceptedFriend(
          context: context,
          auth: widget.authController,
          peerUserId: target.peerUserId ?? '',
          name: title,
        );
      case NotificationDest.orders:
        final orderId = target.orderId;
        if (orderId != null) {
          await _openOrderChat(orderId, title);
        } else {
          await _openOrdersList();
        }
      case NotificationDest.adminOrders:
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => AdminOrdersScreen(
              authController: widget.authController,
              isSuperAdmin: widget.authController.isSuperAdmin,
              canReassignOrders: widget.authController.isSuperAdmin,
            ),
          ),
        );
      case NotificationDest.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          TextButton(
            onPressed: _items.isEmpty ? null : _markAll,
            child: Text(
              l10n.notificationsMarkAll,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(markReadWhileOpen: true),
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: 80),
                          Icon(Icons.notifications_none_rounded,
                            size: 48,
                            color: ObicColors.mutedOf(context),
                          ),
                          SizedBox(height: 12),
                          Text(
                            l10n.notificationsEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ObicColors.mutedOf(context)),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final n = _items[i];
                          final unread = n['readAt'] == null;
                          return Material(
                            color: ObicColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _onTapItem(n),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: unread
                                        ? ObicColors.blue
                                            .withValues(alpha: 0.35)
                                        : ObicColors.line,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      unread
                                          ? Icons.notifications_active_outlined
                                          : Icons.notifications_none_rounded,
                                      color: unread
                                          ? ObicColors.blue
                                          : ObicColors.muted,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              if (unread) ...[
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  margin:
                                                      const EdgeInsetsDirectional
                                                          .only(end: 8),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: ObicColors.badgeRed,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  (n['title'] as String?) ??
                                                      '',
                                                  style: TextStyle(
                                                    fontWeight: unread
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: ObicColors.titleOf(context),
                                                  ),
                                                ),
                                              ),
                                              Icon(Icons.chevron_right_rounded,
                                                color: ObicColors.mutedOf(context),
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            (n['body'] as String?) ?? '',
                                            style: TextStyle(
                                              color: ObicColors.mutedOf(context),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
