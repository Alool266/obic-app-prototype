// Made by Dr Ali
// Map inbox rows (kind + data) → in-app destinations.

import '../../core/friend_alerts.dart';

/// Where a notification tap should land.
enum NotificationDest {
  chat,
  moments,
  friends,
  friendAccepted,
  orders,
  adminOrders,
  none,
}

/// Resolved navigation target for one notification DTO.
class NotificationOpenTarget {
  const NotificationOpenTarget({
    required this.dest,
    this.conversationId,
    this.orderId,
    this.peerUserId,
    this.title,
  });

  final NotificationDest dest;
  final String? conversationId;
  final String? orderId;
  final String? peerUserId;
  final String? title;

  /// Pure resolver — unit-tested; no Flutter / network.
  factory NotificationOpenTarget.resolve(
    Map<String, dynamic> notification, {
    required bool isStaff,
  }) {
    final kind =
        (notification['kind'] ?? notification['type'])?.toString() ?? '';
    final rawData = notification['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    final conversationId = _nonEmpty(data['conversationId']);
    final orderId = _nonEmpty(data['orderId']);
    final title = _nonEmpty(notification['title']) ??
        _nonEmpty(data['titleEn']) ??
        _nonEmpty(data['titleAr']);

    // Prefer explicit thread id whenever present (message / order_chat / handoff).
    if (conversationId != null) {
      return NotificationOpenTarget(
        dest: NotificationDest.chat,
        conversationId: conversationId,
        orderId: orderId,
        title: title,
      );
    }

    switch (kind) {
      case 'moment':
        return const NotificationOpenTarget(dest: NotificationDest.moments);
      case 'friend_request':
        return NotificationOpenTarget(
          dest: NotificationDest.friends,
          peerUserId:
              _nonEmpty(data['peerUserId']) ?? _nonEmpty(data['fromUserId']),
          title: title,
        );
      case 'friend_accepted':
        return NotificationOpenTarget(
          dest: NotificationDest.friendAccepted,
          peerUserId:
              _nonEmpty(data['peerUserId']) ?? _nonEmpty(data['fromUserId']),
          title: friendPersonName(
            explicit: data['fromName']?.toString(),
            title: title,
            body: notification['body']?.toString(),
          ),
        );
      case 'order_created':
      case 'order_status':
        if (orderId != null) {
          return NotificationOpenTarget(
            dest: NotificationDest.orders,
            orderId: orderId,
            title: title,
          );
        }
        return NotificationOpenTarget(
          dest: isStaff
              ? NotificationDest.adminOrders
              : NotificationDest.orders,
          title: title,
        );
      case 'message':
        if (orderId != null) {
          return NotificationOpenTarget(
            dest: NotificationDest.orders,
            orderId: orderId,
            title: title,
          );
        }
        return const NotificationOpenTarget(dest: NotificationDest.none);
      case 'system':
        return const NotificationOpenTarget(dest: NotificationDest.none);
      default:
        if (orderId != null) {
          return NotificationOpenTarget(
            dest: NotificationDest.orders,
            orderId: orderId,
            title: title,
          );
        }
        return const NotificationOpenTarget(dest: NotificationDest.none);
    }
  }

  static String? _nonEmpty(Object? v) {
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }
}
