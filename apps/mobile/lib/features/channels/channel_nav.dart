// Made by Dr Ali
// Shared Channel navigation — Me → Works, Moments TV, Discover.

import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../social/social_api.dart';
import 'channel_viewer_screen.dart';

/// Personal channel already stored for [userId]. Null when they have none.
class ObicPersonalChannel {
  const ObicPersonalChannel({required this.name, this.thumbUrl});

  final String name;
  final String? thumbUrl;
}

/// Slug written when a personal channel is created (`u-` + first 16 id chars).
/// Looking up this slug does not create a channel.
String? personalChannelSlug(String userId) {
  final compact = userId.replaceAll('-', '');
  if (compact.isEmpty) return null;
  final head = compact.length <= 16 ? compact : compact.substring(0, 16);
  return 'u-$head';
}

/// Existing personal channel for [userId], or null. Does not create one.
Future<ObicPersonalChannel?> lookupPersonalChannel({
  required SocialApi api,
  required String userId,
  String? accessToken,
}) async {
  final slug = personalChannelSlug(userId);
  if (slug == null) return null;
  final channel = await api.getChannelBySlug(
    slug: slug,
    accessToken: accessToken,
  );
  if (channel == null || channel['official'] == true) return null;
  final owner = channel['ownerUserId'] as String?;
  if (owner != null && owner != userId) return null;
  final name = (channel['name'] as String?)?.trim();
  if (name == null || name.isEmpty) return null;
  String? thumb;
  try {
    final videos = await api.listChannelVideos(
      idOrSlug: slug,
      accessToken: accessToken,
    );
    for (final video in videos) {
      final url = video['thumbUrl'] as String?;
      if (url != null && url.isNotEmpty) {
        thumb = url;
        break;
      }
    }
  } catch (_) {
    // Name still shows when the video list is unavailable.
  }
  return ObicPersonalChannel(name: name, thumbUrl: thumb);
}

/// Opens the signed-in user's Channel (Me → Works / 视频号).
Future<void> openMyChannel(
  BuildContext context,
  AuthController authController,
) async {
  await openUserChannel(context, authController);
}

/// Opens a user's Channel. [userId] null = signed-in user.
/// Friends see personal feed via Friends tab; strangers get limited visibility
/// from the API (empty feed / contentVisible=false).
Future<void> openUserChannel(
  BuildContext context,
  AuthController authController, {
  String? userId,
}) async {
  final ok = await requireAuth(context, authController);
  if (!context.mounted || !ok) return;
  final me = authController.user?.id;
  final target = userId ?? me;
  final isMine = target != null && target == me;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(
        name: '/channel/user',
        arguments: {'userId': target},
      ),
      builder: (_) => ChannelViewerScreen(
        authController: authController,
        initialTab: ChannelFeedTab.friends,
        openMyChannelOnStart: isMine,
      ),
    ),
  );
}

/// Official OBIC Channel viewer (Follow / Nearby / Friends / Hot).
Future<void> openObicOfficialChannel(
  BuildContext context,
  AuthController authController,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/channel/obic'),
      builder: (_) => ChannelViewerScreen(
        authController: authController,
        initialTab: ChannelFeedTab.hot,
      ),
    ),
  );
}

/// Discover → Channels entry (same viewer, Hot tab).
Future<void> openChannelsDiscover(
  BuildContext context,
  AuthController authController,
) async {
  await openObicOfficialChannel(context, authController);
}
