// Made by Dr Ali
// Open OBIC support chat from settings / restore-account flows.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/connectivity_service.dart';
import '../../widgets/offline_banner.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../messages/chat_screen.dart';
import '../social/social_api.dart';

Future<void> openSupportChat(
  BuildContext context,
  AuthController auth,
) async {
  final ok = await requireAuth(context, auth);
  if (!context.mounted || !ok) return;
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
    final token = await auth.ensureAccessToken();
    if (token == null || !context.mounted) return;
    final thread = await SocialApi().openSupportThread(token);
    if (!context.mounted) return;
    final id = thread['id']?.toString();
    if (id == null || id.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          authController: auth,
          threadId: id,
          title: l10n.chatSupportTitle,
          initialKind: 'support',
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}
