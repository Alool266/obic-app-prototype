// Made by Dr Ali
// Central WeChat-style badge polling for the main shell.

import '../auth/auth_controller.dart';
import '../../core/badge_store.dart';
import '../../core/friend_alerts.dart';
import '../messages/unread_count.dart';
import '../moments/moments_notify_prefs.dart';
import '../social/social_api.dart';

/// Snapshot of all tab / Me-menu badge counts.
class ShellBadgeCounts {
  const ShellBadgeCounts({
    this.messagesUnread = 0,
    this.momentsUnread = 0,
    this.pendingFriends = 0,
    this.unreadNotifications = 0,
  });

  final int messagesUnread;
  final int momentsUnread;
  final int pendingFriends;
  final int unreadNotifications;

  /// WeChat "Me" tab — friend requests + notification inbox.
  int get meTabBadge => pendingFriends + unreadNotifications;

  @override
  bool operator ==(Object other) {
    return other is ShellBadgeCounts &&
        other.messagesUnread == messagesUnread &&
        other.momentsUnread == momentsUnread &&
        other.pendingFriends == pendingFriends &&
        other.unreadNotifications == unreadNotifications;
  }

  @override
  int get hashCode => Object.hash(
        messagesUnread,
        momentsUnread,
        pendingFriends,
        unreadNotifications,
      );
}

class ShellBadgePoller {
  ShellBadgePoller({
    SocialApi? api,
    this.onFriendAlerts,
  }) : _api = api ?? SocialApi();

  final SocialApi _api;
  void Function(List<FriendAlert> alerts)? onFriendAlerts;
  final FriendAlertWatch _friendWatch = FriendAlertWatch();

  bool _momentsBaselined = false;
  ShellBadgeCounts _lastOk = const ShellBadgeCounts();
  Future<ShellBadgeCounts>? _inFlight;
  Future<List<FriendAlert>>? _friendInFlight;

  /// Drop in-memory counts (logout / guest). Call before UI clears badges.
  void clear() {
    _friendWatch.clear();
    _lastOk = const ShellBadgeCounts();
  }

  /// Incoming add and outgoing accept. First successful read is the baseline.
  Future<List<FriendAlert>> pollFriendAlerts(String token) {
    final existing = _friendInFlight;
    if (existing != null) return existing;
    final done = _pollFriendAlertsInner(token);
    _friendInFlight = done;
    return done.whenComplete(() {
      if (identical(_friendInFlight, done)) _friendInFlight = null;
    });
  }

  Future<List<FriendAlert>> _pollFriendAlertsInner(String token) async {
    final json = await _api.listFriendRequests(token);
    final incoming = json['incoming'];
    final outgoing = json['outgoing'];
    final inRows = incoming is List ? incoming : const <dynamic>[];
    final outRows = outgoing is List ? outgoing : const <dynamic>[];
    var friendIds = const <String>{};
    if (_friendWatch.needsFriendList(outgoing: outRows)) {
      final friends = await _api.listFriends(token);
      friendIds = friendIdsFromRows(friends);
    }
    final alerts = _friendWatch.apply(
      incoming: inRows,
      outgoing: outRows,
      friendUserIds: friendIds,
    );
    if (alerts.isNotEmpty) onFriendAlerts?.call(alerts);
    return alerts;
  }

  Future<ShellBadgeCounts> poll({
    required AuthController auth,
    bool momentsTabActive = false,
  }) {
    // Don't stack — overlapping 4s timers were flooding the free API.
    final existing = _inFlight;
    if (existing != null) return existing;
    final done = _pollInner(auth: auth, momentsTabActive: momentsTabActive);
    _inFlight = done;
    return done.whenComplete(() {
      if (identical(_inFlight, done)) _inFlight = null;
    });
  }

  Future<ShellBadgeCounts> _pollInner({
    required AuthController auth,
    bool momentsTabActive = false,
  }) async {
    // Guests: never show personal unread (incl. BADGE_DEMO screenshot flags).
    if (!auth.isAuthenticated) {
      clear();
      return const ShellBadgeCounts();
    }

    // Screenshot / QA: force visible WeChat-style counts without API seed.
    // Authenticated only — never for the logged-out Me / nav chrome.
    if (const bool.fromEnvironment('BADGE_DEMO')) {
      const demo = ShellBadgeCounts(
        messagesUnread: 3,
        momentsUnread: 1,
        pendingFriends: 2,
        unreadNotifications: 8,
      );
      _lastOk = demo;
      return demo;
    }

    // Keep last good counts if a call fails (429 / blip) — never flash zero.
    var messages = _lastOk.messagesUnread;
    var moments = momentsTabActive ? 0 : _lastOk.momentsUnread;
    var friends = _lastOk.pendingFriends;
    var notifications = _lastOk.unreadNotifications;

    final token = await auth.ensureAccessToken();
    if (token == null) {
      clear();
      return const ShellBadgeCounts();
    }

    final n = await _unreadWithRetry(token);
    if (n != null) notifications = n;

    try {
      await pollFriendAlerts(token);
      friends = _friendWatch.pendingIncoming;
    } catch (_) {}

    try {
      final threads = await _api.listThreads(token);
      messages = totalUnreadCount(threads, myUserId: auth.user?.id);
    } catch (_) {}

    try {
      final feed = await _api.listMoments(accessToken: token);
      var lastSeen = await readLastSeenMomentsAt();
      if (lastSeen == null && feed.isNotEmpty && !_momentsBaselined) {
        await writeLastSeenMomentsAt(newestMomentTime(feed));
        _momentsBaselined = true;
        lastSeen = await readLastSeenMomentsAt();
      }
      // Keep server Moments mute prefs warm (migrates local once).
      try {
        await MomentsNotifyPrefs.syncFromServer(
          accessToken: token,
          api: _api,
        );
      } catch (_) {}
      final showBadge = await MomentsNotifyPrefs.shouldShowMomentsBadge();
      final muted = (await MomentsNotifyPrefs.mutedFriendIds()).toSet();
      if (!momentsTabActive && showBadge) {
        moments = countUnseenMoments(
          feed,
          lastSeen: lastSeen,
          excludeAuthorId: auth.user?.id,
          mutedAuthorIds: muted,
        );
      } else if (!showBadge) {
        moments = 0;
      }
    } catch (_) {}

    final next = ShellBadgeCounts(
      messagesUnread: messages,
      momentsUnread: moments,
      pendingFriends: friends,
      unreadNotifications: notifications,
    );
    _lastOk = next;
    return next;
  }

  Future<void> markMomentsSeen() async {
    try {
      final feed = await _api.listMoments();
      await writeLastSeenMomentsAt(newestMomentTime(feed));
      _momentsBaselined = true;
    } catch (_) {
      await writeLastSeenMomentsAt(DateTime.now());
    }
  }

  /// Retries once. Null = keep previous count (do not wipe badge to 0).
  Future<int?> _unreadWithRetry(String token) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _api.unreadNotificationCount(token);
      } catch (_) {
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
        }
      }
    }
    return null;
  }
}
