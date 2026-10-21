// Made by Dr Ali
// Long-press the app icon: Scan, My QR, Money, Translate.

import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../core/obic_nav.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../me/pay_services_demo_screen.dart';
import '../scan/obic_scan_screen.dart';

class ObicHomeShortcuts {
  ObicHomeShortcuts._();

  static final QuickActions _actions = QuickActions();
  static AuthController? _auth;
  static String? _pending;
  static var _ready = false;

  static void install({
    required String langCode,
    required AuthController auth,
  }) {
    _auth = auth;
    _actions.initialize((type) {
      _pending = type;
      _openPending();
    });
    sync(langCode);
    _ready = true;
    _openPending();
  }

  static void sync(String langCode) {
    final ar = langCode == 'ar';
    final zh = langCode == 'zh';
    String label(String a, String e, String z) => zh ? z : (ar ? a : e);
    _actions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'scan',
        localizedTitle: label('مسح', 'Scan', '扫一扫'),
        icon: 'shortcut_scan',
      ),
      ShortcutItem(
        type: 'myqr',
        localizedTitle: label('رمزي', 'My QR code', '我的二维码'),
        icon: 'shortcut_qr',
      ),
      ShortcutItem(
        type: 'money',
        localizedTitle: label('المال', 'Money', '收付款'),
        icon: 'shortcut_money',
      ),
      ShortcutItem(
        type: 'translate',
        localizedTitle: label('ترجمة', 'Translate', '翻译'),
        icon: 'shortcut_translate',
      ),
    ]);
  }

  static void _openPending() {
    if (!_ready) return;
    final type = _pending;
    final auth = _auth;
    final nav = obicNavKey.currentState;
    final ctx = obicNavKey.currentContext;
    if (type == null || auth == null || nav == null || ctx == null) return;
    _pending = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = obicNavKey.currentContext;
      if (context == null || !context.mounted) {
        _pending = type;
        return;
      }
      final ok = await requireAuth(context, auth);
      if (!context.mounted || !ok) return;
      switch (type) {
        case 'scan':
          await openObicScanner(context, auth);
          break;
        case 'translate':
          await openObicScanner(context, auth, start: ObicScanOpen.translate);
          break;
        case 'myqr':
          await openObicMyQr(context, auth);
          break;
        case 'money':
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PayServicesDemoScreen(),
            ),
          );
          break;
        default:
          break;
      }
    });
  }
}
