// Made by Dr Ali
// Shared unread-count parsing for thread rows and tab badge totals.

int threadUnreadCount(Map<String, dynamic> thread, {String? myUserId}) {
  final n = thread['unreadCount'];
  if (n is int) return n;
  if (n is num) return n.toInt();
  if (n is String) return int.tryParse(n) ?? 0;

  // Fallback when API has no unreadCount yet.
  final last = thread['lastMessage'];
  if (last is! Map) return 0;
  final senderId = last['senderId'] as String?;
  if (senderId == null || myUserId == null || senderId == myUserId) return 0;
  return 1;
}

int totalUnreadCount(List<Map<String, dynamic>> threads, {String? myUserId}) {
  return threads.fold<int>(
    0,
    (sum, t) => sum + threadUnreadCount(t, myUserId: myUserId),
  );
}
