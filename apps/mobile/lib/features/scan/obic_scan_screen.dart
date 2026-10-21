// Made by Dr Ali
// WeChat-style scan: a framed camera, album, torch, and my own code.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/api_errors.dart';
import '../../core/obic_phrases.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../friends/add_friend_screen.dart';
import '../friends/contact_profile_screen.dart';
import '../me/pay_services_demo_screen.dart';
import '../messages/chat_screen.dart';
import '../mini_apps/mini_apps_api.dart';
import '../mini_apps/mini_apps_catalog.dart';
import '../mini_apps/mini_apps_pull_panel.dart';
import 'image_translate_screen.dart';

enum ObicScanOpen { scan, translate }

Future<void> openObicScanner(
  BuildContext context,
  AuthController authController, {
  ObicScanOpen start = ObicScanOpen.scan,
}) async {
  final ok = await requireAuth(context, authController);
  if (!context.mounted || !ok) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ObicScanScreen(
        authController: authController,
        startTranslate: start == ObicScanOpen.translate,
      ),
    ),
  );
}

Future<void> openObicMyQr(
  BuildContext context,
  AuthController authController,
) async {
  final ok = await requireAuth(context, authController);
  if (!context.mounted || !ok) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ObicMyQrScreen(authController: authController),
    ),
  );
}

class ObicScanScreen extends StatefulWidget {
  const ObicScanScreen({
    super.key,
    required this.authController,
    this.startTranslate = false,
  });

  final AuthController authController;
  final bool startTranslate;

  @override
  State<ObicScanScreen> createState() => _ObicScanScreenState();
}

class _ObicScanScreenState extends State<ObicScanScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  late final MobileScannerController _cam = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  var _translate = false;
  var _busy = false;
  var _lit = false;

  @override
  void initState() {
    super.initState();
    _translate = widget.startTranslate;
  }

  @override
  void dispose() {
    _line.dispose();
    unawaited(_cam.dispose());
    super.dispose();
  }

  Future<void> _onCode(String raw) async {
    if (_busy || _translate) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    try {
      await _route(raw.trim());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _route(String raw) async {
    final friendId = parseObicUserQr(raw);
    if (friendId != null) {
      final me = widget.authController.user?.id;
      if (me != null && me == friendId) {
        _toast(
          obicPhrase(
            context,
            ar: 'هذا رمزك',
            en: 'This is your code',
            zh: '这是你自己的码',
          ),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ContactProfileScreen(
            authController: widget.authController,
            userId: friendId,
            offerAddFriend: true,
            allowCall: false,
          ),
        ),
      );
      return;
    }
    final group = RegExp(
      r'obic:group:([0-9a-fA-F-]{36})',
      caseSensitive: false,
    ).firstMatch(raw);
    if (group != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _JoinGroupScreen(
            authController: widget.authController,
            conversationId: group.group(1)!,
          ),
        ),
      );
      return;
    }
    final lower = raw.toLowerCase();
    if (lower.contains('obic:pay')) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PayServicesDemoScreen(),
        ),
      );
      return;
    }
    final mini = RegExp(
      r'obic:mini:([A-Za-z0-9_-]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (mini != null) {
      await _openMini(mini.group(1)!);
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => _InAppLink(url: uri)),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ObicColors.surfaceRaisedOf(context),
      builder: (ctx) => _UnknownCodeSheet(raw: raw),
    );
  }

  Future<void> _openMini(String id) async {
    final lang = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    MiniAppEntry? match;
    if (id == 'obic-web') {
      match = obicWebsiteMiniApp(l10n.miniAppWebsiteName);
    } else if (id == kObicMusicMiniAppId || id == 'music') {
      match = obicMusicMiniApp(lang);
    } else {
      try {
        final rows = await MiniAppsApi().listApproved();
        for (final row in rows) {
          if (row.id == id) {
            match = row;
            break;
          }
        }
      } catch (e) {
        if (!mounted) return;
        _toast(_err(e));
        return;
      }
    }
    if (!mounted) return;
    if (match == null || !match.canOpen) {
      _toast(
        obicPhrase(
          context,
          ar: 'ما نقدر نفتح هذا الرابط',
          en: 'This link cannot be opened',
          zh: '无法打开这个链接',
        ),
      );
      return;
    }
    await openMiniAppEntry(
      context,
      match,
      displayName: widget.authController.user?.name,
    );
  }

  String _err(Object e) {
    return friendlyApiError(
      classifyTransportError(e),
      l10n: AppLocalizations.of(context),
      langCode: Localizations.localeOf(context).languageCode,
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _album() async {
    final shot = await _picker.pickImage(source: ImageSource.gallery);
    if (shot == null || !mounted) return;
    if (_translate) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImageTranslateScreen(
            authController: widget.authController,
            imagePath: shot.path,
          ),
        ),
      );
      return;
    }
    final found = await _cam.analyzeImage(shot.path);
    final raw = found?.barcodes.isNotEmpty == true
        ? found!.barcodes.first.rawValue
        : null;
    if (!mounted) return;
    if (raw == null || raw.isEmpty) {
      _toast(
        obicPhrase(
          context,
          ar: 'ما لقينا رمز QR في هذه الصورة',
          en: 'No QR code was found in that photo',
          zh: '这张照片里没有二维码',
        ),
      );
      return;
    }
    await _onCode(raw);
  }

  Future<void> _shootTranslate() async {
    final shot = await _picker.pickImage(source: ImageSource.camera);
    if (shot == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageTranslateScreen(
          authController: widget.authController,
          imagePath: shot.path,
        ),
      ),
    );
  }

  Future<void> _torch() async {
    await _cam.toggleTorch();
    if (mounted) setState(() => _lit = !_lit);
  }

  @override
  Widget build(BuildContext context) {
    final scanLabel = obicPhrase(context, ar: 'مسح', en: 'Scan', zh: '扫一扫');
    final translateLabel = obicPhrase(context, ar: 'ترجمة', en: 'Translate', zh: '翻译');
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: _translate
                ? _translateBody()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _cam,
                        onDetect: (capture) {
                          final raw = capture.barcodes.isEmpty
                              ? null
                              : capture.barcodes.first.rawValue;
                          if (raw == null || raw.isEmpty) return;
                          unawaited(_onCode(raw));
                        },
                        errorBuilder: (context, error) => _CameraDenied(error: error),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _line,
                            builder: (context, _) => CustomPaint(
                              painter: _DimFramePainter(_line.value, lit: _busy),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Builder(
                          builder: (context) {
                            final box = (MediaQuery.sizeOf(context).width * 0.68)
                                .clamp(200.0, 280.0);
                            return SizedBox(
                              width: box,
                              height: box,
                              child: Align(
                                alignment: AlignmentDirectional.bottomEnd,
                                child: IconButton(
                                  onPressed: _torch,
                                  icon: const Icon(
                                    Icons.flashlight_on_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 12,
                        child: Text(
                          obicPhrase(
                            context,
                            ar: 'ضع رمز QR داخل الإطار للمسح',
                            en: 'Place the QR code inside the frame to scan',
                            zh: '将二维码放入框内即可扫描',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: 8,
                        top: MediaQuery.paddingOf(context).top + 4,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.arrow_forward_ios
                                : Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 14,
                        left: 56,
                        right: 56,
                        child: Text(
                          scanLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  _tool(
                    Icons.photo_library_outlined,
                    obicPhrase(context, ar: 'الصور', en: 'Album', zh: '相册'),
                    _album,
                  ),
                  Expanded(child: _mode(scanLabel, !_translate, () {
                    setState(() => _translate = false);
                  })),
                  Expanded(child: _mode(translateLabel, _translate, () {
                    setState(() => _translate = true);
                  })),
                  _tool(
                    Icons.qr_code_2_rounded,
                    obicPhrase(context, ar: 'رمزي', en: 'My QR', zh: '我的二维码'),
                    () => openObicMyQr(context, widget.authController),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _translateBody() {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward_ios
                        : Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                obicPhrase(
                  context,
                  ar: 'صوّر قائمة أو لوحة أو مستنداً، أو اختر صورة من الألبوم.',
                  en: 'Take a photo of a menu, sign or document, or pick one from the gallery.',
                  zh: '拍摄菜单、招牌或文件，或从相册选择一张。',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 16),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _shootTranslate,
                style: FilledButton.styleFrom(backgroundColor: ObicColors.blue),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(obicPhrase(context, ar: 'تصوير', en: 'Camera', zh: '拍照')),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tool(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: 64,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mode(String label, bool on, VoidCallback tap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: on ? ObicColors.blue : Colors.white12,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _DimFramePainter extends CustomPainter {
  _DimFramePainter(this.t, {required this.lit});

  final double t;
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final box = (size.width * 0.68).clamp(200.0, 280.0);
    final hole = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: box,
      height: box,
    );
    final shade = Path()
      ..addRect(Offset.zero & size)
      ..addRect(hole)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(shade, Paint()..color = const Color(0xB3000000));
    final corner = Paint()
      ..color = lit ? Colors.white : ObicColors.blue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    const len = 26.0;
    void arm(Offset a, Offset b) => canvas.drawLine(a, b, corner);
    arm(hole.topLeft, hole.topLeft + const Offset(len, 0));
    arm(hole.topLeft, hole.topLeft + const Offset(0, len));
    arm(hole.topRight, hole.topRight + const Offset(-len, 0));
    arm(hole.topRight, hole.topRight + const Offset(0, len));
    arm(hole.bottomLeft, hole.bottomLeft + const Offset(len, 0));
    arm(hole.bottomLeft, hole.bottomLeft + const Offset(0, -len));
    arm(hole.bottomRight, hole.bottomRight + const Offset(-len, 0));
    arm(hole.bottomRight, hole.bottomRight + const Offset(0, -len));
    final y = hole.top + 8 + (hole.height - 16) * t;
    canvas.drawLine(
      Offset(hole.left + 8, y),
      Offset(hole.right - 8, y),
      Paint()
        ..color = ObicColors.blue
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _DimFramePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.lit != lit;
}

class _CameraDenied extends StatelessWidget {
  const _CameraDenied({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text(
                obicPhrase(
                  context,
                  ar: 'أوبيك يحتاج الكاميرا لمسح رمز QR.',
                  en: 'OBIC needs the camera to scan a QR code.',
                  zh: 'OBIC 需要相机才能扫描二维码。',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, height: 1.35),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: openAppSettings,
                style: FilledButton.styleFrom(backgroundColor: ObicColors.blue),
                child: Text(obicPhrase(context, ar: 'الإعدادات', en: 'Settings', zh: '设置')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ObicMyQrScreen extends StatelessWidget {
  const ObicMyQrScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final id = authController.user?.id ?? '';
    final name = authController.user?.name ?? 'OBIC';
    final ink = ObicColors.inkOf(context);
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ink,
        title: Text(
          obicPhrase(context, ar: 'رمزي', en: 'My QR code', zh: '我的二维码'),
          style: TextStyle(color: ink, fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 20)),
              const SizedBox(height: 16),
              ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: id.isEmpty
                      ? const SizedBox(width: 220, height: 220)
                      : QrImageView(
                          data: obicUserQrPayload(id),
                          size: 220,
                          backgroundColor: Colors.white,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                obicPhrase(
                  context,
                  ar: 'اطلب من صديقك مسح هذا الرمز لإضافتك',
                  en: 'Ask a friend to scan this code to add you',
                  zh: '让朋友扫这个码来添加你',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: ObicColors.mutedOf(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinGroupScreen extends StatelessWidget {
  const _JoinGroupScreen({
    required this.authController,
    required this.conversationId,
  });

  final AuthController authController;
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final ink = ObicColors.inkOf(context);
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ink,
        title: Text(
          obicPhrase(context, ar: 'انضمام للمجموعة', en: 'Join group', zh: '加入群聊'),
          style: TextStyle(color: ink, fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              obicPhrase(
                context,
                ar: 'هذا رمز مجموعة. افتح المحادثة إذا كنت عضواً فيها.',
                en: 'This is a group code. Open the chat if you are already a member.',
                zh: '这是群二维码。如果你已在群里，可以打开聊天。',
              ),
              style: TextStyle(color: ink, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatScreen(
                      authController: authController,
                      threadId: conversationId,
                      title: obicPhrase(
                        context,
                        ar: 'مجموعة',
                        en: 'Group',
                        zh: '群聊',
                      ),
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: ObicColors.blue),
              child: Text(obicPhrase(context, ar: 'فتح المجموعة', en: 'Open group', zh: '打开群聊')),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownCodeSheet extends StatelessWidget {
  const _UnknownCodeSheet({required this.raw});

  final String raw;

  @override
  Widget build(BuildContext context) {
    final ink = ObicColors.inkOf(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              raw,
              style: TextStyle(color: ink, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: raw));
                      Navigator.pop(context);
                    },
                    child: Text(obicPhrase(context, ar: 'نسخ', en: 'Copy', zh: '复制')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final uri = Uri.tryParse(raw);
                      Navigator.pop(context);
                      if (uri != null &&
                          (uri.scheme == 'https' || uri.scheme == 'http')) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: FilledButton.styleFrom(backgroundColor: ObicColors.blue),
                    child: Text(obicPhrase(context, ar: 'فتح', en: 'Open', zh: '打开')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InAppLink extends StatefulWidget {
  const _InAppLink({required this.url});

  final Uri url;

  @override
  State<_InAppLink> createState() => _InAppLinkState();
}

class _InAppLinkState extends State<_InAppLink> {
  late final WebViewController _web = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(widget.url);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        title: Text(
          widget.url.host,
          style: TextStyle(color: ObicColors.inkOf(context)),
        ),
      ),
      body: WebViewWidget(controller: _web),
    );
  }
}
