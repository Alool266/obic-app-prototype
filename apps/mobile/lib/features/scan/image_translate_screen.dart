// Made by Dr Ali
// WeChat-style image translation: find every line, cover it, write the translation in place.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/obic_phrases.dart';
import '../../theme/obic_colors.dart';
import '../ai/ai_api.dart';
import '../auth/auth_controller.dart';

class TextPatch {
  TextPatch({
    required this.text,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.angle = 0,
    this.translation = '',
    this.bg = const Color(0xFFF4F1EA),
    this.fg = const Color(0xFF1A1A1A),
  });

  final String text;
  double x;
  double y;
  double w;
  double h;
  double angle;
  String translation;
  Color bg;
  Color fg;
}

class ImageTranslateScreen extends StatefulWidget {
  const ImageTranslateScreen({
    super.key,
    required this.authController,
    required this.imagePath,
  });

  final AuthController authController;
  final String imagePath;

  @override
  State<ImageTranslateScreen> createState() => _ImageTranslateScreenState();
}

class _ImageTranslateScreenState extends State<ImageTranslateScreen> {
  final _api = AiApi();
  final _boundary = GlobalKey();
  List<TextPatch> _patches = [];
  String _target = 'en';
  double _imgW = 1;
  double _imgH = 1;
  bool _showTranslation = true;
  bool _busy = true;
  bool _reveal = false;
  bool _started = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final code = Localizations.localeOf(context).languageCode;
    _target = code == 'ar' || code == 'zh' ? code : 'en';
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _reveal = false;
      _error = null;
    });
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final decoded = await _decode(bytes);
      _imgW = decoded.width.toDouble();
      _imgH = decoded.height.toDouble();
      final device = await _onDevice(decoded.width.toDouble(), decoded.height.toDouble());
      final server = await _onServer(bytes);
      final patches = _merge(device, server);
      _sampleColors(patches, decoded.pixels, decoded.sampleW, decoded.sampleH);
      decoded.image.dispose();
      if (patches.isEmpty) {
        if (!mounted) return;
        setState(() {
          _patches = [];
          _busy = false;
          _error = obicPhrase(
            context,
            ar: 'ما لقينا نص في الصورة',
            en: 'No text found in this photo',
            zh: '照片里没有找到文字',
          );
        });
        return;
      }
      final token = await widget.authController.accessToken();
      if (token == null) throw Exception('signed out');
      await _translatePatches(token, patches);
      if (!mounted) return;
      setState(() {
        _patches = patches;
        _busy = false;
        _showTranslation = true;
      });
      _fadeIn();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = obicPhrase(
          context,
          ar: 'تعذّرت ترجمة الصورة',
          en: 'Could not translate this photo',
          zh: '无法翻译这张照片',
        );
      });
    }
  }

  Future<void> _retranslate() async {
    if (_patches.isEmpty) return;
    setState(() {
      _busy = true;
      _reveal = false;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw Exception('signed out');
      for (final patch in _patches) {
        patch.translation = '';
      }
      await _translatePatches(token, _patches);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _showTranslation = true;
      });
      _fadeIn();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = obicPhrase(
          context,
          ar: 'تعذّرت ترجمة الصورة',
          en: 'Could not translate this photo',
          zh: '无法翻译这张照片',
        );
      });
    }
  }

  void _fadeIn() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _reveal = true);
    });
  }

  Future<_Decoded> _decode(Uint8List bytes) async {
    final full = await ui.instantiateImageCodec(bytes);
    final fullFrame = await full.getNextFrame();
    final width = fullFrame.image.width;
    final height = fullFrame.image.height;
    fullFrame.image.dispose();
    final sampleEdge = math.max(width, height) > 900 ? 900 : null;
    final sample = await ui.instantiateImageCodec(
      bytes,
      targetWidth: width >= height ? sampleEdge : null,
      targetHeight: height > width ? sampleEdge : null,
    );
    final frame = await sample.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return _Decoded(
      image: frame.image,
      width: width,
      height: height,
      sampleW: frame.image.width,
      sampleH: frame.image.height,
      pixels: data?.buffer.asUint8List() ?? Uint8List(0),
    );
  }

  Future<List<TextPatch>> _onDevice(double imageW, double imageH) async {
    final found = <TextPatch>[];
    for (final script in [TextRecognitionScript.chinese, TextRecognitionScript.latin]) {
      final recognizer = TextRecognizer(script: script);
      try {
        final result = await recognizer.processImage(
          InputImage.fromFilePath(widget.imagePath),
        );
        for (final block in result.blocks) {
          for (final line in block.lines) {
            final text = line.text.trim();
            if (text.isEmpty) continue;
            final box = line.boundingBox;
            found.add(
              TextPatch(
                text: text,
                x: (box.left / imageW).clamp(0.0, 1.0),
                y: (box.top / imageH).clamp(0.0, 1.0),
                w: (box.width / imageW).clamp(0.01, 1.0),
                h: (box.height / imageH).clamp(0.008, 1.0),
                angle: _cornersAngle(line.cornerPoints),
              ),
            );
          }
        }
      } catch (_) {
      } finally {
        await recognizer.close();
      }
    }
    return found;
  }

  Future<List<TextPatch>> _onServer(Uint8List bytes) async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return [];
      final payload = await _payload(bytes);
      final res = await _api
          .seeText(
            accessToken: token,
            dataBase64: payload.$1,
            mime: payload.$2,
          )
          .timeout(const Duration(seconds: 25));
      final raw = res['blocks'];
      if (raw is! List) return [];
      final out = <TextPatch>[];
      for (final row in raw.whereType<Map>()) {
        final text = row['text']?.toString().trim() ?? '';
        if (text.isEmpty) continue;
        final degrees = (row['angle'] as num?)?.toDouble() ?? 0;
        out.add(
          TextPatch(
            text: text,
            x: ((row['x'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
            y: ((row['y'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
            w: ((row['w'] as num?)?.toDouble() ?? 0.2).clamp(0.01, 1.0),
            h: ((row['h'] as num?)?.toDouble() ?? 0.04).clamp(0.008, 1.0),
            angle: degrees * math.pi / 180,
          ),
        );
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<(String, String)> _payload(Uint8List bytes) async {
    final mime = bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50
        ? 'image/png'
        : 'image/jpeg';
    if (bytes.length <= 1400000) return (base64Encode(bytes), mime);
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1280);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    final png = data?.buffer.asUint8List() ?? bytes;
    return (base64Encode(png), 'image/png');
  }

  List<TextPatch> _merge(List<TextPatch> device, List<TextPatch> server) {
    final out = <TextPatch>[];
    for (final row in device) {
      if (!out.any((other) => _same(other, row))) out.add(row);
    }
    for (final row in server) {
      if (!out.any((other) => _same(other, row))) out.add(row);
    }
    out.sort((a, b) {
      final dy = a.y.compareTo(b.y);
      if (dy != 0) return dy;
      return a.x.compareTo(b.x);
    });
    return out;
  }

  bool _same(TextPatch a, TextPatch b) {
    if (a.text == b.text && (a.y - b.y).abs() < 0.03) return true;
    final iw = math.max(0.0, math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x));
    final ih = math.max(0.0, math.min(a.y + a.h, b.y + b.h) - math.max(a.y, b.y));
    final inter = iw * ih;
    final area = a.w * a.h + b.w * b.h - inter;
    return area > 0 && inter / area > 0.35;
  }

  double _cornersAngle(List<math.Point<int>> points) {
    if (points.length < 2) return 0;
    final dx = (points[1].x - points[0].x).toDouble();
    final dy = (points[1].y - points[0].y).toDouble();
    if (dx.abs() + dy.abs() < 2) return 0;
    return math.atan2(dy, dx);
  }

  void _sampleColors(List<TextPatch> patches, Uint8List pixels, int sw, int sh) {
    for (final patch in patches) {
      patch.bg = _around(pixels, sw, sh, patch);
      patch.fg = patch.bg.computeLuminance() > 0.55
          ? const Color(0xFF1A1A1A)
          : Colors.white;
    }
  }

  Color _around(Uint8List pixels, int sw, int sh, TextPatch patch) {
    if (pixels.length < sw * sh * 4 || sw == 0 || sh == 0) {
      return const Color(0xFFF7F4EE);
    }
    final x0 = (patch.x * sw).floor();
    final y0 = (patch.y * sh).floor();
    final x1 = ((patch.x + patch.w) * sw).ceil();
    final y1 = ((patch.y + patch.h) * sh).ceil();
    var r = 0;
    var g = 0;
    var b = 0;
    var n = 0;
    void take(int x, int y) {
      if (x < 0 || y < 0 || x >= sw || y >= sh) return;
      final i = (y * sw + x) * 4;
      r += pixels[i];
      g += pixels[i + 1];
      b += pixels[i + 2];
      n++;
    }

    for (var x = x0 - 6; x <= x1 + 6; x += 2) {
      take(x, y0 - 5);
      take(x, y1 + 5);
    }
    for (var y = y0; y <= y1; y += 2) {
      take(x0 - 6, y);
      take(x1 + 6, y);
    }
    if (n == 0) return const Color(0xFFF7F4EE);
    return Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n);
  }

  bool _needsTranslation(String text) {
    return RegExp(r'[A-Za-z\u0600-\u06FF\u4E00-\u9FFF]').hasMatch(text);
  }

  Future<void> _translatePatches(String token, List<TextPatch> patches) async {
    final todo = <TextPatch>[];
    for (final patch in patches) {
      if (_needsTranslation(patch.text)) {
        todo.add(patch);
      } else {
        patch.translation = patch.text;
      }
    }
    const size = 8;
    for (var i = 0; i < todo.length; i += size) {
      final end = math.min(i + size, todo.length);
      final slice = todo.sublist(i, end);
      final marked = slice
          .asMap()
          .entries
          .map((entry) => '⟦${entry.key}⟧ ${entry.value.text}')
          .join('\n');
      var done = false;
      try {
        final res = await _api
            .translate(
              accessToken: token,
              text:
                  'Keep each ⟦number⟧ marker and translate only the words after it, one line per marker.\n$marked',
              targetLocale: _target,
            )
            .timeout(const Duration(seconds: 22));
        final raw = (res['translation'] as String?) ?? '';
        done = _applyMarked(raw, slice);
      } catch (_) {
        done = false;
      }
      if (!done) await _oneByOne(token, slice);
    }
  }

  bool _applyMarked(String raw, List<TextPatch> slice) {
    final marked = List<String?>.filled(slice.length, null);
    final re = RegExp(r'⟦(\d+)⟧\s*(.*)');
    for (final line in raw.split('\n')) {
      final match = re.firstMatch(line.trim());
      if (match == null) continue;
      final index = int.tryParse(match.group(1)!);
      if (index == null || index < 0 || index >= slice.length) continue;
      final text = match.group(2)!.trim();
      if (text.isNotEmpty) marked[index] = text;
    }
    if (marked.every((line) => line != null)) {
      for (var i = 0; i < slice.length; i++) {
        slice[i].translation = marked[i]!;
      }
      return true;
    }
    final plain = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (plain.length != slice.length) return false;
    for (var i = 0; i < slice.length; i++) {
      slice[i].translation = plain[i];
    }
    return true;
  }

  Future<void> _oneByOne(String token, List<TextPatch> slice) async {
    for (final patch in slice) {
      if (patch.translation.trim().isNotEmpty) continue;
      try {
        final res = await _api
            .translate(
              accessToken: token,
              text: patch.text,
              targetLocale: _target,
            )
            .timeout(const Duration(seconds: 18));
        final text = (res['translation'] as String?)?.trim() ?? '';
        patch.translation = text.isEmpty ? patch.text : text;
      } catch (_) {
        patch.translation = patch.text;
      }
    }
  }

  String _sourceCode() {
    var zh = 0;
    var ar = 0;
    var en = 0;
    for (final patch in _patches) {
      for (final rune in patch.text.runes) {
        if (rune >= 0x4E00 && rune <= 0x9FFF) {
          zh++;
        } else if (rune >= 0x0600 && rune <= 0x06FF) {
          ar++;
        } else if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A)) {
          en++;
        }
      }
    }
    if (zh >= ar && zh >= en && zh > 0) return 'zh';
    if (ar >= en && ar > 0) return 'ar';
    if (en > 0) return 'en';
    return 'zh';
  }

  String _langName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  Future<void> _copySheet() async {
    if (_patches.isEmpty) return;
    final ink = ObicColors.inkOf(context);
    final muted = ObicColors.mutedOf(context);
    final rtl = _target == 'ar';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ObicColors.surfaceRaisedOf(context),
      builder: (ctx) {
        final all = _patches
            .map((patch) => '${patch.text}\n${patch.translation}')
            .join('\n\n');
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          obicPhrase(ctx, ar: 'النص', en: 'Text', zh: '文字'),
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: all));
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                obicPhrase(context, ar: 'تم النسخ', en: 'Copied', zh: '已复制'),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          obicPhrase(ctx, ar: 'نسخ الكل', en: 'Copy all', zh: '全部复制'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _patches.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: ObicColors.lineOf(ctx),
                    ),
                    itemBuilder: (_, index) {
                      final patch = _patches[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(patch.text, style: TextStyle(color: muted, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              patch.translation.isEmpty ? patch.text : patch.translation,
                              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List?> _capture() async {
    final boundary = _boundary.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _save() async {
    final bytes = await _capture();
    if (bytes == null || !mounted) return;
    await Gal.putImageBytes(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(obicPhrase(context, ar: 'تم الحفظ', en: 'Saved', zh: '已保存'))),
    );
  }

  Future<void> _share() async {
    final bytes = await _capture();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/obic-translate.png');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  Widget _cover(TextPatch patch, double width, double height) {
    final rawW = (patch.w * width).clamp(10.0, width).toDouble();
    final rawH = (patch.h * height).clamp(10.0, height).toDouble();
    var angle = patch.angle;
    var boxW = rawW;
    var boxH = rawH;
    if (rawH > rawW * 1.35 && angle.abs() < 0.35) {
      angle = -math.pi / 2;
      boxW = rawH;
      boxH = math.max(rawW, 16.0);
    }
    final left = (patch.x * width + rawW / 2 - boxW / 2)
        .clamp(0.0, math.max(0.0, width - boxW))
        .toDouble();
    final top = (patch.y * height + rawH / 2 - boxH / 2)
        .clamp(0.0, math.max(0.0, height - boxH))
        .toDouble();
    final rtl = _target == 'ar';
    final label = patch.translation.isEmpty ? patch.text : patch.translation;
    return Positioned(
      left: left,
      top: top,
      width: boxW,
      height: boxH,
      child: Transform.rotate(
        angle: angle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: patch.bg,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                label,
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                maxLines: 3,
                style: TextStyle(
                  color: patch.fg,
                  fontWeight: FontWeight.w700,
                  fontSize: boxH.clamp(11, 48),
                  height: 1.05,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stage() {
    return LayoutBuilder(
      builder: (context, box) {
        final scale = math.min(box.maxWidth / _imgW, box.maxHeight / _imgH);
        final width = _imgW * scale;
        final height = _imgH * scale;
        return Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              clipBehavior: Clip.hardEdge,
              child: Center(
                child: RepaintBoundary(
                  key: _boundary,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: Image.file(File(widget.imagePath), fit: BoxFit.fill),
                        ),
                        if (_showTranslation)
                          AnimatedOpacity(
                            opacity: _reveal ? 1 : 0,
                            duration: const Duration(milliseconds: 380),
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                for (final patch in _patches) _cover(patch, width, height),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_busy) const Positioned.fill(child: _ScanLine()),
          ],
        );
      },
    );
  }

  Widget _tool({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    final color = enabled ? ObicColors.inkOf(context) : ObicColors.mutedOf(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pair = '${_langName(_sourceCode())} → ${_langName(_target)}';
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.arrow_forward_ios
                : Icons.arrow_back_ios_new,
          ),
        ),
        title: PopupMenuButton<String>(
          onSelected: (code) {
            if (code == _target || _busy) return;
            setState(() => _target = code);
            _retranslate();
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'ar', child: Text('العربية')),
            PopupMenuItem(value: 'en', child: Text('English')),
            PopupMenuItem(value: 'zh', child: Text('中文')),
          ],
          child: Text(
            pair,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ObicColors.inkOf(context),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: ObicColors.mutedOf(context)),
              ),
            ),
          Expanded(child: _stage()),
          Material(
            color: ObicColors.surfaceRaisedOf(context),
            child: SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: ObicColors.lineOf(context))),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      _tool(
                        icon: Icons.layers_outlined,
                        label: _showTranslation
                            ? obicPhrase(context, ar: 'الأصل', en: 'Original', zh: '原文')
                            : obicPhrase(context, ar: 'الترجمة', en: 'Translation', zh: '译文'),
                        onTap: _patches.isEmpty
                            ? null
                            : () => setState(() => _showTranslation = !_showTranslation),
                      ),
                      _tool(
                        icon: Icons.copy_rounded,
                        label: obicPhrase(context, ar: 'نسخ النص', en: 'Copy text', zh: '复制文字'),
                        onTap: _patches.isEmpty ? null : _copySheet,
                      ),
                      _tool(
                        icon: Icons.save_alt_rounded,
                        label: obicPhrase(context, ar: 'حفظ', en: 'Save', zh: '保存'),
                        onTap: _busy ? null : _save,
                      ),
                      _tool(
                        icon: Icons.ios_share_rounded,
                        label: obicPhrase(context, ar: 'مشاركة', en: 'Share', zh: '分享'),
                        onTap: _busy ? null : _share,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Decoded {
  const _Decoded({
    required this.image,
    required this.width,
    required this.height,
    required this.sampleW,
    required this.sampleH,
    required this.pixels,
  });

  final ui.Image image;
  final int width;
  final int height;
  final int sampleW;
  final int sampleH;
  final Uint8List pixels;
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, box) {
              final top = _controller.value * box.maxHeight;
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: top - 36,
                    height: 72,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            const Color(0xAA3B82F6),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 18,
                    child: Text(
                      obicPhrase(context, ar: 'جاري الترجمة…', en: 'Translating…', zh: '正在翻译…'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
