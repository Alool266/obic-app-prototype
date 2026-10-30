// Made by Dr Ali
// WeChat chat-list “+” menu: New Chat, Add Contacts, Scan, Money.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../friends/add_friend_screen.dart';
import '../me/pay_services_demo_screen.dart';
import '../scan/obic_scan_screen.dart';
import 'create_group_screen.dart';
import 'new_chat_screen.dart';

Future<void> showChatPlusMenu(
  BuildContext context, {
  required AuthController authController,
  required RelativeRect position,
}) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showMenu<String>(
    context: context,
    color: const Color(0xFF4C4C4C),
    position: position,
    items: [
      _item('chat', Icons.chat_bubble_outline, l10n.chatNewChat),
      _item('group', Icons.group_add_outlined, l10n.chatGroup),
      _item('contacts', Icons.person_add_alt_1, l10n.friendsAdd),
      _item('scan', Icons.qr_code_scanner, l10n.friendsScanQr),
      _item('money', Icons.account_balance_wallet_outlined, l10n.payDemoSectionMoney),
    ],
  );
  if (choice == null || !context.mounted) return;
  final ok = await requireAuth(context, authController);
  if (!context.mounted || !ok) return;
  switch (choice) {
    case 'chat':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NewChatScreen(authController: authController),
        ),
      );
    case 'group':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CreateGroupScreen(authController: authController),
        ),
      );
    case 'contacts':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AddFriendScreen(authController: authController),
        ),
      );
    case 'scan':
      await openObicScanner(context, authController);
    case 'money':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PayServicesDemoScreen(),
        ),
      );
    default:
      break;
  }
}

PopupMenuItem<String> _item(String value, IconData icon, String label) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    ),
  );
}
