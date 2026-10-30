// Made by Dr Ali
// Tap a friend banner: requests list, or the chat when one already exists.

import 'package:flutter/material.dart';

import '../../core/friend_alerts.dart';
import '../auth/auth_controller.dart';
import '../messages/chat_screen.dart';
import '../social/social_api.dart';
import 'contact_profile_screen.dart';
import 'new_friends_screen.dart';

enum FriendAlertHref {
  requests,
  profile,
  accepted,
  ignored,
}

FriendAlertHref friendAlertHrefKind(String href) {
  if (href == 'friends') return FriendAlertHref.requests;
  if (href.startsWith('friend-profile:')) return FriendAlertHref.profile;
  if (href.startsWith('friend-accept:') ||
      href.startsWith('friend-accept-name:')) {
    return FriendAlertHref.accepted;
  }
  return FriendAlertHref.ignored;
}

Future<void> openFriendAlertHref({
  required BuildContext context,
  required AuthController auth,
  required String href,
  required String title,
}) async {
  final kind = friendAlertHrefKind(href);
  switch (kind) {
    case FriendAlertHref.requests:
      if (!context.mounted) return;
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => NewFriendsScreen(authController: auth),
        ),
      );
    case FriendAlertHref.profile:
      final id = href.substring('friend-profile:'.length).trim();
      if (id.isEmpty || !context.mounted) return;
      await _openProfile(context, auth, id, title);
    case FriendAlertHref.accepted:
      final byName = href.startsWith('friend-accept-name:');
      final peerId = byName
          ? ''
          : href.substring('friend-accept:'.length).trim();
      final named = byName
          ? Uri.decodeComponent(href.substring('friend-accept-name:'.length))
          : title;
      if (!context.mounted) return;
      await openAcceptedFriend(
        context: context,
        auth: auth,
        peerUserId: peerId,
        name: named,
      );
    case FriendAlertHref.ignored:
      return;
  }
}

/// Chat when a direct thread is already in the list. Otherwise their profile.
Future<void> openAcceptedFriend({
  required BuildContext context,
  required AuthController auth,
  required String peerUserId,
  required String name,
}) async {
  var peerId = peerUserId.trim();
  final token = await auth.accessToken();
  if (!context.mounted) return;
  if (peerId.isEmpty && token != null) {
    peerId = await _uniqueFriendId(token, name) ?? '';
  }
  if (!context.mounted || peerId.isEmpty) return;
  String? threadId;
  if (token != null) {
    try {
      final threads = await SocialApi().listThreads(token);
      threadId = directThreadIdForPeer(threads: threads, peerUserId: peerId);
    } catch (_) {}
  }
  if (!context.mounted) return;
  final openId = threadId;
  if (openId != null && openId.isNotEmpty) {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          authController: auth,
          threadId: openId,
          title: name.trim().isEmpty ? 'OBIC' : name.trim(),
        ),
      ),
    );
    return;
  }
  await _openProfile(context, auth, peerId, name);
}

Future<String?> _uniqueFriendId(String token, String name) async {
  final wanted = name.trim().toLowerCase();
  if (wanted.isEmpty || _isGenericLabel(wanted)) return null;
  try {
    final rows = await SocialApi().listFriends(token);
    final ids = <String>[];
    for (final row in rows) {
      final user = row['user'];
      if (user is! Map) continue;
      final id = user['id']?.toString() ?? '';
      final person = (user['name'] as String?)?.trim().toLowerCase() ?? '';
      if (id.isEmpty || person != wanted) continue;
      ids.add(id);
    }
    if (ids.length == 1) return ids.first;
  } catch (_) {}
  return null;
}

bool _isGenericLabel(String value) {
  switch (value) {
    case 'someone':
    case 'obic':
    case 'friend request':
    case 'friend request accepted':
      return true;
    default:
      return false;
  }
}

Future<void> _openProfile(
  BuildContext context,
  AuthController auth,
  String userId,
  String name,
) async {
  if (!context.mounted || userId.isEmpty) return;
  final shown = name.trim().isEmpty ? 'Someone' : name.trim();
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => ContactProfileScreen(
        authController: auth,
        userId: userId,
        seedUser: {'id': userId, 'name': shown},
        allowCall: true,
      ),
    ),
  );
}
