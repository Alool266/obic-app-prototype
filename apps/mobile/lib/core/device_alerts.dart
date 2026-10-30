// Made by Dr Ali
// System alerts while the app is backgrounded or the phone is locked.
// Customers, employees, and admins all register. No phone-activation gate.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/admin/admin_api.dart';
import '../features/auth/auth_controller.dart';
import '../features/social/social_api.dart';
import 'active_chat_tracker.dart';
import 'alert_policy.dart';
import 'app_foreground.dart';
import 'friend_alerts.dart';
import 'obic_org.dart';
import 'realtime_client.dart';

typedef OpenChatHandler = void Function(String conversationId, String title);
typedef OpenHrefHandler = void Function(String href, String title);
typedef CallActionHandler = void Function(Map<String, dynamic> payload);

class DeviceAlerts {
  DeviceAlerts._();
  static final DeviceAlerts instance = DeviceAlerts._();

  static const _channel = MethodChannel('obic/push');

  AuthController? _auth;
  OpenChatHandler? onOpenChat;
  OpenHrefHandler? onOpenHref;
  CallActionHandler? onAcceptCall;
  CallActionHandler? onDeclineCall;

  bool _started = false;
  String? _lastToken;
  String? _lastPlatform;
  Map<String, dynamic>? _pendingCall;
  String? _pendingCallAction;
  Timer? _staffTimer;
  int _badge = 0;
  final Set<String> _seenStaffIds = {};
  bool _staffBaselined = false;
  final Map<String, Map<String, dynamic>> _ringing = {};
  final Set<String> _recentBodies = {};
  final Set<String> _friendShown = {};

  void attach({
    required AuthController auth,
    required OpenChatHandler onOpenChat,
    required OpenHrefHandler onOpenHref,
    required CallActionHandler onAcceptCall,
    required CallActionHandler onDeclineCall,
  }) {
    _auth = auth;
    this.onOpenChat = onOpenChat;
    this.onOpenHref = onOpenHref;
    this.onAcceptCall = onAcceptCall;
    this.onDeclineCall = onDeclineCall;
    final pending = _pendingCall;
    final action = _pendingCallAction;
    _pendingCall = null;
    _pendingCallAction = null;
    if (pending == null || action == null) return;
    if (action == 'decline') {
      onDeclineCall(pending);
    } else {
      onAcceptCall(pending);
    }
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _channel.setMethodCallHandler(_onNative);
    try {
      await _channel.invokeMethod<bool>('prepare');
      await _channel.invokeMethod<bool>('register');
      await _channel.invokeMethod<bool>('ready');
    } catch (_) {}
    RealtimeClient.instance.onChatMessage.listen(_onChat);
    RealtimeClient.instance.onNotification.listen(_onInbox);
    AppForeground.instance.addListener(_syncForeground);
    unawaited(_syncForeground());
    _auth?.addListener(_onAuth);
    _armStaffWatch();
  }

  Future<void> _syncForeground() async {
    try {
      await _channel.invokeMethod<void>(
        'foreground',
        AppForeground.instance.isActive,
      );
    } catch (_) {}
  }

  Future<void> setBadge(int count) async {
    final next = count < 0 ? 0 : count;
    _badge = next;
    try {
      await _channel.invokeMethod<void>('badge', next);
    } catch (_) {}
  }

  /// Fired when a push arrives while the app is already open, so the
  /// full-screen ring can show without a second system banner.
  void Function(Map<String, dynamic> payload)? onIncomingWhileOpen;

  Future<void> showIncomingCall(
    Map<String, dynamic> payload, {
    required bool foreground,
  }) async {
    final id = payload['callId']?.toString() ?? '';
    if (id.isEmpty) return;
    _ringing[id] = Map<String, dynamic>.from(payload);
    // App is open: the full-screen ring is the only UI. Drop any banner a
    // push already posted so the two never sit on screen together.
    if (foreground) {
      await dismissIncomingCall(id);
      return;
    }
    final name = (payload['fromName'] as String?)?.trim();
    final video = payload['mode']?.toString() == 'video';
    try {
      await _channel.invokeMethod<void>('showCall', {
        'callId': id,
        'name': (name == null || name.isEmpty) ? 'OBIC' : name,
        'video': video,
        'conversationId': payload['conversationId']?.toString() ?? '',
        'mode': video ? 'video' : 'voice',
        'fromName': (name == null || name.isEmpty) ? 'OBIC' : name,
        'fromUserId': payload['fromUserId']?.toString() ?? '',
        'conversationKind': payload['conversationKind']?.toString() ?? '',
        'conversationTitle': payload['conversationTitle']?.toString() ?? '',
        'isGroup': payload['isGroup'] == true ? '1' : '0',
      });
    } catch (_) {}
  }

  Future<void> dismissIncomingCall(String? callId) async {
    if (callId == null || callId.isEmpty) {
      _ringing.clear();
    } else {
      _ringing.remove(callId);
    }
    try {
      await _channel.invokeMethod<void>('endCall', {
        'callId': callId ?? '',
      });
    } catch (_) {}
  }

  /// System banner the user has not answered yet. Ends that banner and
  /// returns its payload so the open app can show the full-screen ring.
  Future<Map<String, dynamic>?> takeSystemRing() async {
    try {
      final raw = await _channel.invokeMethod<Object?>('takeSystemRing');
      if (raw is Map && raw.isNotEmpty) {
        final map = _normalizeCall(Map<String, dynamic>.from(raw));
        final id = map['callId']?.toString() ?? '';
        if (id.isNotEmpty) _ringing.remove(id);
        return map;
      }
    } catch (_) {}
    if (_ringing.isEmpty) return null;
    final first = _normalizeCall(
      Map<String, dynamic>.from(_ringing.values.first),
    );
    final id = first['callId']?.toString() ?? '';
    if (id.isNotEmpty) _ringing.remove(id);
    await dismissIncomingCall(id);
    return first;
  }

  Map<String, dynamic> _normalizeCall(Map<String, dynamic> raw) {
    final next = Map<String, dynamic>.from(raw);
    final group = next['isGroup']?.toString().toLowerCase();
    if (group == '1' || group == 'true') next['isGroup'] = true;
    if (group == '0' || group == 'false') next['isGroup'] = false;
    if ((next['fromName']?.toString() ?? '').trim().isEmpty) {
      final name = next['name']?.toString() ?? next['title']?.toString() ?? '';
      if (name.trim().isNotEmpty) next['fromName'] = name.trim();
    }
    return next;
  }

  Future<void> callEnded(Map<String, dynamic> payload) async {
    final id = payload['callId']?.toString();
    if (id == null || id.isEmpty) return;
    final ringing = _ringing.remove(id);
    try {
      await _channel.invokeMethod<void>('endCall', {'callId': id});
    } catch (_) {}
    if (ringing == null || AppForeground.instance.isActive) return;
    final video = ringing['mode']?.toString() == 'video';
    final name = (ringing['fromName'] as String?)?.trim();
    final arabic = await _arabic();
    await _showMessage(
      id: 'missed-$id',
      title: (name == null || name.isEmpty) ? 'OBIC' : name,
      body: missedCallLabel(video: video, arabic: arabic),
      conversationId: ringing['conversationId']?.toString() ?? '',
      kind: 'message',
    );
  }

  Future<void> _onNative(MethodCall call) async {
    switch (call.method) {
      case 'token':
        await _onToken(call.arguments);
      case 'opened':
        final raw = call.arguments;
        if (raw is Map) {
          await _opened(Map<String, dynamic>.from(raw));
        }
      case 'callAnswered':
        _acceptFromNative(_callPayload(call.arguments));
      case 'callDeclined':
        _declineFromNative(_callPayload(call.arguments));
      case 'callEnded':
        final payload = _callPayload(call.arguments);
        await callEnded(payload);
      case 'callWhileOpen':
        final open = _normalizeCall(_callPayload(call.arguments));
        if ((open['callId']?.toString() ?? '').isEmpty) return;
        onIncomingWhileOpen?.call(open);
      default:
        break;
    }
  }

  Future<void> _onToken(Object? arguments) async {
    if (arguments is String && arguments.isNotEmpty) {
      await _registerToken(arguments, platform: await _pushPlatform());
      return;
    }
    if (arguments is Map) {
      final token = arguments['token']?.toString() ?? '';
      final platform = arguments['platform']?.toString() ?? '';
      if (token.isEmpty) return;
      await _registerToken(
        token,
        platform: platform.isEmpty ? await _pushPlatform() : platform,
      );
    }
  }

  Map<String, dynamic> _callPayload(Object? arguments) {
    if (arguments is Map) {
      final raw = Map<String, dynamic>.from(arguments);
      final id = raw['callId']?.toString() ?? '';
      final stored = id.isEmpty ? null : _ringing[id];
      if (stored != null) {
        return {...stored, ...raw};
      }
      if ((raw['fromName']?.toString() ?? '').isEmpty) {
        final title = raw['title']?.toString() ?? raw['name']?.toString();
        if (title != null && title.isNotEmpty) raw['fromName'] = title;
      }
      return raw;
    }
    final id = arguments?.toString() ?? '';
    if (id.isNotEmpty && _ringing[id] != null) {
      return Map<String, dynamic>.from(_ringing[id]!);
    }
    return {'callId': id};
  }

  void _acceptFromNative(Map<String, dynamic> payload) {
    if (payload['callId']?.toString().isEmpty ?? true) return;
    final handler = onAcceptCall;
    if (handler == null) {
      _pendingCall = payload;
      _pendingCallAction = 'accept';
      return;
    }
    handler(payload);
  }

  void _declineFromNative(Map<String, dynamic> payload) {
    if (payload['callId']?.toString().isEmpty ?? true) return;
    final handler = onDeclineCall;
    if (handler == null) {
      _pendingCall = payload;
      _pendingCallAction = 'decline';
      return;
    }
    handler(payload);
  }

  Future<String> _pushPlatform() async {
    if (Platform.isIOS) return 'ios';
    try {
      final china = await _channel.invokeMethod<bool>('needsChinaPush');
      if (china == true) return 'android_cn';
    } catch (_) {}
    return 'android';
  }

  Future<void> _registerToken(String token, {required String platform}) async {
    _lastToken = token;
    _lastPlatform = platform;
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated) return;
    final access = await auth.ensureAccessToken();
    if (access == null) return;
    await SocialApi().registerPushDevice(
      accessToken: access,
      platform: platform,
      token: token,
    );
  }

  Future<void> _opened(Map<String, dynamic> args) async {
    final kind = args['kind']?.toString() ?? '';
    final action = args['action']?.toString() ?? 'open';
    if (kind == 'call_ended') {
      await callEnded(args);
      return;
    }
    if (kind == 'call') {
      final payload = _callPayload(args);
      if (action == 'accept') {
        _acceptFromNative(payload);
        return;
      }
      if (action == 'decline') {
        _declineFromNative(payload);
        return;
      }
    }
    final conversationId = args['conversationId']?.toString() ?? '';
    if (conversationId.isEmpty) {
      final href = args['href']?.toString() ?? '';
      if (href == 'friends' ||
          href.startsWith('friend-accept:') ||
          href.startsWith('friend-accept-name:') ||
          href.startsWith('friend-profile:')) {
        onOpenHref?.call(href, args['title']?.toString() ?? '');
        return;
      }
      if (href == 'orders' || href == 'bug' || href == 'mini' || href == 'moderation') {
        return;
      }
      return;
    }
    onOpenChat?.call(conversationId, args['title']?.toString() ?? 'OBIC');
  }

  /// Name + short line, with the message-channel sound. Open or backgrounded.
  Future<void> presentFriendAlert(FriendAlert alert) async {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated) return;
    if (!_friendShown.add(alert.dedupeKey)) return;
    final arabic = await _arabic();
    await _showMessage(
      id: alert.dedupeKey,
      title: alert.title,
      body: alert.line(arabic: arabic),
      conversationId: '',
      kind: alert.notificationKind,
      href: alert.href,
      dedupeKey: alert.dedupeKey,
    );
  }

  void _onChat(Map<String, dynamic> payload) {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated) return;
    final conversationId = payload['conversationId']?.toString() ?? '';
    final raw = payload['message'];
    if (conversationId.isEmpty || raw is! Map) return;
    final message = Map<String, dynamic>.from(raw);
    final senderId = message['senderId']?.toString();
    if (!shouldAlertChatMessage(
      myUserId: auth.user?.id,
      senderId: senderId,
      chatOpen: ActiveChatTracker.instance.isOpen(conversationId),
      muted: ActiveChatTracker.instance.isMuted(conversationId),
      appInForeground: AppForeground.instance.isActive,
    )) {
      return;
    }
    final name = (message['senderName'] as String?)?.trim();
    final id = message['id']?.toString() ?? conversationId;
    unawaited(() async {
      final arabic = await _arabic();
      final preview = chatMessagePreview(message, arabic: arabic);
      await _showMessage(
        id: id,
        title: (name == null || name.isEmpty)
            ? (arabic ? 'رسالة جديدة' : 'New message')
            : name,
        body: preview,
        conversationId: conversationId,
        kind: 'message',
        avatarUrl: message['senderAvatarUrl']?.toString(),
      );
    }());
  }

  /// Arabic is the product default until the person picks another language.
  Future<bool> _arabic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('obic_locale_v1');
      return code == null || code.isEmpty || code == 'ar';
    } catch (_) {
      return true;
    }
  }

  void _onInbox(Map<String, dynamic> payload) {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated) return;
    final raw = payload['notification'];
    if (raw is! Map) return;
    final note = Map<String, dynamic>.from(raw);
    final dataRaw = note['data'];
    final data = dataRaw is Map
        ? Map<String, dynamic>.from(dataRaw)
        : <String, dynamic>{};
    final conversationId = data['conversationId']?.toString() ?? '';
    if (!shouldAlertInbox(
      chatOpen: ActiveChatTracker.instance.isOpen(conversationId),
      muted: ActiveChatTracker.instance.isMuted(conversationId),
    )) {
      return;
    }
    final actorId = data['customerUserId']?.toString() ??
        data['fromUserId']?.toString() ??
        data['ownerUserId']?.toString() ??
        data['reporterId']?.toString();
    if (actorId != null && actorId.isNotEmpty && actorId == auth.user?.id) {
      return;
    }
    final kind = note['kind']?.toString() ?? '';
    if (kind == 'friend_request' || kind == 'friend_accepted') {
      final alert = friendAlertFromNotification(
        note,
        myUserId: auth.user?.id,
      );
      if (alert != null) {
        unawaited(presentFriendAlert(alert));
      }
      return;
    }
    final type = data['type']?.toString() ?? '';
    final customerWork = kind == 'order_created' ||
        kind == 'system' ||
        type == 'staff_handoff' ||
        type == 'service_request' ||
        type == 'offer_request' ||
        type == 'order_chat' ||
        type == 'bug_report' ||
        type == 'mini_app' ||
        type == 'content_report';
    if (AppForeground.instance.isActive && !customerWork) return;
    if (customerWork && !_isSecretary()) return;
    final title = (note['title'] as String?)?.trim();
    final body = (note['body'] as String?)?.trim();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }
    final id = note['id']?.toString() ?? '$title-$body';
    unawaited(
      _showMessage(
        id: id,
        title: (title == null || title.isEmpty) ? 'OBIC' : title,
        body: (body == null || body.isEmpty) ? 'OBIC' : body,
        conversationId: conversationId,
        kind: 'inbox',
        href: _hrefFor(data, note['kind']?.toString() ?? ''),
      ),
    );
  }

  String _hrefFor(Map<String, dynamic> data, String kind) {
    final type = data['type']?.toString() ?? '';
    if (type == 'bug_report') return 'bug';
    if (type == 'mini_app') return 'mini';
    if (type == 'content_report') return 'moderation';
    if (kind == 'order_created' ||
        type == 'service_request' ||
        type == 'offer_request') {
      return 'orders';
    }
    return '';
  }

  Future<void> _showMessage({
    required String id,
    required String title,
    required String body,
    required String conversationId,
    required String kind,
    String href = '',
    String? dedupeKey,
    String? avatarUrl,
  }) async {
    final key = dedupeKey ?? '$conversationId|$body';
    if (!_recentBodies.add(key)) return;
    Timer(const Duration(seconds: 8), () => _recentBodies.remove(key));
    if (kind == 'message') _badge += 1;
    try {
      await _channel.invokeMethod<void>('showMessage', {
        'id': id,
        'title': title,
        'body': body,
        'conversationId': conversationId,
        'kind': kind,
        'href': href,
        'badge': _badge,
        'avatarUrl': avatarUrl ?? '',
      });
    } catch (_) {}
  }

  void _onAuth() {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated) {
      _staffTimer?.cancel();
      _staffTimer = null;
      _seenStaffIds.clear();
      _staffBaselined = false;
      _friendShown.clear();
      _badge = 0;
      unawaited(setBadge(0));
      return;
    }
    _armStaffWatch();
    unawaited(_flushToken());
    unawaited(_channel.invokeMethod<bool>('register'));
  }

  Future<void> _flushToken() async {
    final token = _lastToken;
    final platform = _lastPlatform;
    if (token == null || platform == null) return;
    await _registerToken(token, platform: platform);
  }

  void _armStaffWatch() {
    if (!_isSecretary()) {
      _staffTimer?.cancel();
      _staffTimer = null;
      return;
    }
    if (_staffTimer != null) return;
    unawaited(_pollSecretaryQueue());
    _staffTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_pollSecretaryQueue()),
    );
  }

  bool _isSecretary() {
    final user = _auth?.user;
    if (user == null) return false;
    return isYiwuSecretary(
      role: user.role,
      staffTitle: user.staffTitle,
      branchLabel: user.branchLabel,
      email: user.email,
    );
  }

  /// Existing lists the Yiwu Secretary can already read. Not every employee.
  Future<void> _pollSecretaryQueue() async {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated || !_isSecretary()) return;
    final token = await auth.accessToken();
    if (token == null) return;
    final api = AdminApi();
    final found = <_StaffItem>[];
    try {
      final orders = await api.listOrders(token);
      for (final row in orders) {
        if (row['userId']?.toString() == auth.user?.id) continue;
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final name = (row['customerName'] as String?)?.trim();
        final title = (row['subServiceNameEn'] as String?)?.trim();
        final service = (row['serviceTitleEn'] as String?)?.trim();
        final label = (title != null && title.isNotEmpty)
            ? title
            : ((service != null && service.isNotEmpty) ? service : 'a request');
        found.add(
          _StaffItem(
            id: 'order-$id',
            title: 'New service request',
            body: (name == null || name.isEmpty)
                ? 'Customer submitted: $label'
                : '$name submitted: $label',
            href: 'orders',
          ),
        );
      }
    } catch (_) {}
    try {
      final bugs = await api.listBugReports(token);
      for (final row in bugs) {
        if (row['status']?.toString() != 'open') continue;
        if (row['userId']?.toString() == auth.user?.id) continue;
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final text = (row['description'] as String?)?.trim() ?? '';
        found.add(
          _StaffItem(
            id: 'bug-$id',
            title: 'New bug report',
            body: text.isEmpty
                ? 'A customer sent a bug report'
                : (text.length > 80 ? '${text.substring(0, 77)}…' : text),
            href: 'bug',
          ),
        );
      }
    } catch (_) {}
    if (!_staffBaselined) {
      _seenStaffIds.addAll(found.map((item) => item.id));
      _staffBaselined = true;
      return;
    }
    for (final item in found) {
      if (!_seenStaffIds.add(item.id)) continue;
      await _showMessage(
        id: item.id,
        title: item.title,
        body: item.body,
        conversationId: '',
        kind: 'inbox',
        href: item.href,
      );
    }
  }
}

class _StaffItem {
  const _StaffItem({
    required this.id,
    required this.title,
    required this.body,
    required this.href,
  });

  final String id;
  final String title;
  final String body;
  final String href;
}
