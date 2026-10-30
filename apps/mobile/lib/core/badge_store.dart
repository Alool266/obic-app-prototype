// Made by Dr Ali
// Local persistence for WeChat-style "last seen" badge timestamps.

import 'package:shared_preferences/shared_preferences.dart';

const _kLastSeenMomentsMs = 'obic_last_seen_moments_ms';
const _kLastSeenChannelsMs = 'obic_last_seen_channels_ms';

/// When the user last opened the Moments tab (epoch ms, UTC).
Future<DateTime?> readLastSeenMomentsAt() async {
  final prefs = await SharedPreferences.getInstance();
  final ms = prefs.getInt(_kLastSeenMomentsMs);
  if (ms == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
}

Future<void> writeLastSeenMomentsAt(DateTime when) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kLastSeenMomentsMs, when.toUtc().millisecondsSinceEpoch);
}

/// When the user last opened Discover → Channels (epoch ms, UTC).
Future<DateTime?> readLastSeenChannelsAt() async {
  final prefs = await SharedPreferences.getInstance();
  final ms = prefs.getInt(_kLastSeenChannelsMs);
  if (ms == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
}

Future<void> writeLastSeenChannelsAt(DateTime when) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kLastSeenChannelsMs, when.toUtc().millisecondsSinceEpoch);
}

DateTime? parseMomentCreatedAt(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw.toLocal();
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw)?.toLocal();
  }
  return null;
}

/// Count feed posts newer than [lastSeen]. Returns 0 when [lastSeen] is null.
/// Own posts ([excludeAuthorId]) never count — WeChat does not badge yourself.
/// Muted authors ([mutedAuthorIds]) never count.
int countUnseenMoments(
  List<Map<String, dynamic>> moments, {
  DateTime? lastSeen,
  String? excludeAuthorId,
  Set<String>? mutedAuthorIds,
}) {
  if (lastSeen == null) return 0;
  var count = 0;
  for (final m in moments) {
    final authorId = m['authorId'] as String?;
    if (excludeAuthorId != null &&
        excludeAuthorId.isNotEmpty &&
        authorId == excludeAuthorId) {
      continue;
    }
    if (mutedAuthorIds != null &&
        authorId != null &&
        mutedAuthorIds.contains(authorId)) {
      continue;
    }
    final created = parseMomentCreatedAt(m['createdAt']);
    if (created != null && created.isAfter(lastSeen)) count++;
  }
  return count;
}

/// Newest [createdAt] in the feed, or [DateTime.now] if empty.
DateTime newestMomentTime(List<Map<String, dynamic>> moments) {
  DateTime? newest;
  for (final m in moments) {
    final created = parseMomentCreatedAt(m['createdAt']);
    if (created == null) continue;
    if (newest == null || created.isAfter(newest)) newest = created;
  }
  return newest ?? DateTime.now();
}

bool isMomentUnseen(Map<String, dynamic> moment, {DateTime? lastSeen}) {
  if (lastSeen == null) return false;
  final created = parseMomentCreatedAt(moment['createdAt']);
  return created != null && created.isAfter(lastSeen);
}

/// Newest [createdAt] among Channel discover preview maps (official / friends).
DateTime newestChannelPreviewTime(Iterable<Map<String, dynamic>?> previews) {
  DateTime? newest;
  for (final p in previews) {
    if (p == null) continue;
    final created = parseMomentCreatedAt(p['createdAt']);
    if (created == null) continue;
    if (newest == null || created.isAfter(newest)) newest = created;
  }
  return newest ?? DateTime.now();
}

/// Discover Channels red tip — true when a preview is newer than [lastSeen].
/// Returns false when [lastSeen] is null (same as Moments: baseline first).
bool hasUnseenChannelPreview(
  Iterable<Map<String, dynamic>?> previews, {
  DateTime? lastSeen,
}) {
  if (lastSeen == null) return false;
  for (final p in previews) {
    if (p == null) continue;
    final created = parseMomentCreatedAt(p['createdAt']);
    if (created != null && created.isAfter(lastSeen)) return true;
  }
  return false;
}
