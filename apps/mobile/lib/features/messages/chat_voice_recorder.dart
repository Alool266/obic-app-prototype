// Made by Dr Ali
// WeChat hold-to-talk: release to send, slide to cancel or turn speech into text.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/obic_phrases.dart';
import '../../theme/obic_colors.dart';
import 'chat_attach_helpers.dart';

class VoiceRecordResult {
  const VoiceRecordResult({
    required this.path,
    required this.durationSeconds,
    required this.filename,
  });

  final String path;
  final int durationSeconds;
  final String filename;
}

enum _HoldZone { send, cancel, text }

/// Mic icon or full bar. Holding starts the recording overlay.
class ChatHoldToTalkButton extends StatefulWidget {
  const ChatHoldToTalkButton({
    super.key,
    required this.enabled,
    required this.holdLabel,
    required this.releaseLabel,
    required this.cancelLabel,
    required this.tooShortLabel,
    required this.micDeniedLabel,
    required this.onRecorded,
    required this.onError,
    this.compact = false,
    this.transcribe,
    this.onSendText,
  });

  final bool enabled;
  final String holdLabel;
  final String releaseLabel;
  final String cancelLabel;
  final String tooShortLabel;
  final String micDeniedLabel;
  final Future<void> Function(VoiceRecordResult result) onRecorded;
  final void Function(String message) onError;
  final bool compact;
  final Future<String?> Function(String path)? transcribe;
  final Future<void> Function(String text)? onSendText;

  @override
  State<ChatHoldToTalkButton> createState() => _ChatHoldToTalkButtonState();
}

class _ChatHoldToTalkButtonState extends State<ChatHoldToTalkButton> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  _HoldZone _zone = _HoldZone.send;
  DateTime? _startedAt;
  String? _path;
  Timer? _tick;
  int _elapsed = 0;
  double _level = 0;
  StreamSubscription<Amplitude>? _amp;
  OverlayEntry? _overlay;
  Offset? _origin;
  bool _fingerDown = false;
  bool _abort = false;

  static const _maxSeconds = 60;

  @override
  void dispose() {
    _tick?.cancel();
    _amp?.cancel();
    _overlay?.remove();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<bool> _ensureMic() async {
    final current = await Permission.microphone.status;
    if (current.isGranted) return true;
    if (!mounted) return false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ObicColors.surfaceRaisedOf(ctx),
        title: Text(
          obicPhrase(ctx, ar: 'الميكروفون', en: 'Microphone', zh: '麦克风'),
          style: TextStyle(color: ObicColors.inkOf(ctx)),
        ),
        content: Text(
          obicPhrase(
            ctx,
            ar: 'أوبيك يحتاج الميكروفون لتسجيل رسالة صوتية وإرسالها في هذه المحادثة.',
            en: 'OBIC needs the microphone to record a voice message in this chat.',
            zh: 'OBIC 需要麦克风才能在这个聊天里录制语音。',
          ),
          style: TextStyle(color: ObicColors.inkOf(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(obicPhrase(ctx, ar: 'إلغاء', en: 'Cancel', zh: '取消')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(obicPhrase(ctx, ar: 'متابعة', en: 'Continue', zh: '继续')),
          ),
        ],
      ),
    );
    if (go != true) return false;
    final next = await Permission.microphone.request();
    if (next.isGranted) return true;
    if (!mounted) return false;
    widget.onError(widget.micDeniedLabel);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ObicColors.surfaceRaisedOf(ctx),
        content: Text(
          widget.micDeniedLabel,
          style: TextStyle(color: ObicColors.inkOf(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(obicPhrase(ctx, ar: 'إلغاء', en: 'Cancel', zh: '取消')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              unawaited(openAppSettings());
            },
            child: Text(obicPhrase(ctx, ar: 'الإعدادات', en: 'Settings', zh: '设置')),
          ),
        ],
      ),
    );
    return false;
  }

  void _press(Offset position) {
    if (!widget.enabled || _recording) return;
    _fingerDown = true;
    _abort = false;
    _origin = position;
    _zone = _HoldZone.send;
    unawaited(_start());
  }

  void _release() {
    _fingerDown = false;
    if (_recording) {
      unawaited(_finish());
      return;
    }
    _abort = true;
  }

  void _cancelPress() {
    if (_overlay != null) return;
    _fingerDown = false;
    if (_recording) {
      unawaited(_finish());
      return;
    }
    _abort = true;
  }

  Future<void> _start() async {
    if (!widget.enabled || _recording || !_fingerDown) return;
    if (!await _ensureMic()) return;
    if (!mounted || _abort || !_fingerDown) return;
    _zone = _HoldZone.send;
    _elapsed = 0;
    _level = 0.35;
    _showOverlay();
    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'obic_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted || _abort || !_fingerDown) {
        _removeOverlay();
        try {
          await _recorder.stop();
        } catch (_) {}
        try {
          await File(path).delete();
        } catch (_) {}
        return;
      }
      HapticFeedback.mediumImpact();
      _amp = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amp) {
        if (!mounted) return;
        _level = ((amp.current + 45) / 45).clamp(0.05, 1.0);
        _overlay?.markNeedsBuild();
      });
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_recording) return;
        _elapsed++;
        _overlay?.markNeedsBuild();
        if (_elapsed >= _maxSeconds) {
          unawaited(_finish());
        }
      });
      _recording = true;
      _zone = _HoldZone.send;
      _startedAt = DateTime.now();
      _path = path;
      _elapsed = 0;
      _overlay?.markNeedsBuild();
    } catch (e) {
      _removeOverlay();
      if (!mounted) return;
      widget.onError(
        obicPhrase(
          context,
          ar: 'تعذّر بدء التسجيل. حاول مرة أخرى.',
          en: 'Could not start recording. Please try again.',
          zh: '无法开始录音，请重试。',
        ),
      );
    }
  }

  void _showOverlay() {
    _overlay?.remove();
    final overlay = Overlay.of(context, rootOverlay: true);
    _overlay = OverlayEntry(builder: (ctx) => _HoldOverlay(host: this));
    overlay.insert(_overlay!);
  }

  void _move(Offset global) {
    if (!_recording) return;
    final origin = _origin ?? global;
    final dx = global.dx - origin.dx;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final next = dx < -56
        ? (rtl ? _HoldZone.text : _HoldZone.cancel)
        : dx > 56
            ? (rtl ? _HoldZone.cancel : _HoldZone.text)
            : _HoldZone.send;
    if (next == _zone) return;
    HapticFeedback.selectionClick();
    _zone = next;
    _overlay?.markNeedsBuild();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _arm(_HoldZone zone) {
    if (!_recording || zone == _zone) return;
    HapticFeedback.selectionClick();
    _zone = zone;
    _overlay?.markNeedsBuild();
  }

  Future<void> _finish() async {
    if (!_recording) {
      _removeOverlay();
      return;
    }
    final zone = _zone;
    _recording = false;
    _tick?.cancel();
    _amp?.cancel();
    _removeOverlay();
    String? path;
    try {
      path = await _recorder.stop().timeout(
        const Duration(seconds: 4),
        onTimeout: () => _path,
      );
    } catch (_) {
      path = _path;
    }
    final started = _startedAt;
    if (mounted) {
      setState(() {
        _zone = _HoldZone.send;
        _startedAt = null;
        _path = null;
        _elapsed = 0;
        _level = 0;
      });
    }
    _removeOverlay();
    if (path == null || path.isEmpty) return;
    final secs = started == null
        ? 0
        : DateTime.now().difference(started).inMilliseconds ~/ 1000;
    if (zone == _HoldZone.cancel) {
      try {
        await File(path).delete();
      } catch (_) {}
      return;
    }
    if (secs < 1) {
      try {
        await File(path).delete();
      } catch (_) {}
      widget.onError(widget.tooShortLabel);
      return;
    }
    var bytes = 0;
    try {
      bytes = await File(path).length();
    } catch (_) {}
    if (bytes < 1000) {
      try {
        await File(path).delete();
      } catch (_) {}
      if (!mounted) return;
      widget.onError(
        obicPhrase(
          context,
          ar: 'التسجيل فاضي. اضغط الميكروفون وتكلم ثم اتركه.',
          en: 'The recording is empty. Hold the mic and speak, then release.',
          zh: '录音是空的。按住麦克风说话后再松开。',
        ),
      );
      return;
    }
    final name = voiceAttachmentName(secs.clamp(1, _maxSeconds));
    final result = VoiceRecordResult(
      path: path,
      durationSeconds: secs,
      filename: name,
    );
    try {
      if (zone == _HoldZone.text) {
        await _offerText(result);
        return;
      }
      await widget.onRecorded(result);
    } catch (_) {
      if (!mounted) return;
      widget.onError(
        obicPhrase(
          context,
          ar: 'تعذّر الإرسال. حاول مرة أخرى.',
          en: 'Could not send. Please try again.',
          zh: '发送失败，请重试。',
        ),
      );
    } finally {
      _removeOverlay();
    }
  }

  Future<void> _offerText(VoiceRecordResult result) async {
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _TextChoice? chosen;
    try {
      chosen = await showDialog<_TextChoice>(
        context: context,
        barrierDismissible: true,
        useRootNavigator: true,
        builder: (ctx) => _TextChoiceDialog(
          transcribe: widget.transcribe == null
              ? null
              : () => widget.transcribe!(result.path),
        ),
      );
    } catch (_) {
      chosen = const _TextChoice(_TextKind.failed, '');
    }
    if (!mounted) return;
    if (chosen == null ||
        chosen.kind == _TextKind.cancel ||
        chosen.kind == _TextKind.failed) {
      if (chosen?.kind == _TextKind.failed) {
        widget.onError(
          obicPhrase(
            context,
            ar: 'تعذّر تحويل الصوت. حاول مرة أخرى.',
            en: 'Could not convert this voice message. Please try again.',
            zh: '无法转换这条语音，请重试。',
          ),
        );
      }
      try {
        await File(result.path).delete();
      } catch (_) {}
      return;
    }
    if (chosen.kind == _TextKind.voice) {
      await widget.onRecorded(result);
      return;
    }
    final body = chosen.text.trim();
    if (body.isEmpty) {
      widget.onError(widget.tooShortLabel);
      try {
        await File(result.path).delete();
      } catch (_) {}
      return;
    }
    await widget.onSendText?.call(body);
    try {
      await File(result.path).delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Listener(
        onPointerDown: widget.enabled ? (e) => _press(e.position) : null,
        onPointerMove: (e) => _move(e.position),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _cancelPress(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.mic_none_rounded,
            color: widget.enabled ? ObicColors.blue : ObicColors.mutedOf(context),
          ),
        ),
      );
    }
    final label = !_recording
        ? widget.holdLabel
        : (_zone == _HoldZone.cancel
            ? widget.cancelLabel
            : widget.releaseLabel);
    return Listener(
      onPointerDown: widget.enabled ? (e) => _press(e.position) : null,
      onPointerMove: (e) => _move(e.position),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _cancelPress(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _recording
              ? ObicColors.blue
              : ObicColors.surfaceRaisedOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _recording ? Colors.transparent : ObicColors.lineOf(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: _recording ? Colors.white : ObicColors.inkOf(context),
          ),
        ),
      ),
    );
  }
}

class _HoldOverlay extends StatelessWidget {
  const _HoldOverlay({required this.host});

  final _ChatHoldToTalkButtonState host;

  @override
  Widget build(BuildContext context) {
    final zone = host._zone;
    final left = host._elapsed >= 50 ? _maxLeft(host._elapsed) : null;
    final hint = zone == _HoldZone.cancel
        ? obicPhrase(context, ar: 'حرّر للإلغاء', en: 'Release to cancel', zh: '松开取消')
        : zone == _HoldZone.text
            ? obicPhrase(context, ar: 'حرّر للتحويل', en: 'Release to convert', zh: '松开转文字')
            : obicPhrase(context, ar: 'حرّر للإرسال', en: 'Release to send', zh: '松开发送');
    return BackButtonListener(
      onBackButtonPressed: () async {
        host._arm(_HoldZone.cancel);
        unawaited(host._finish());
        return true;
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerMove: (event) => host._move(event.position),
        onPointerUp: (_) => host._release(),
        onPointerCancel: (_) => host._release(),
        child: ColoredBox(
          color: const Color(0x99000000),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Column(
                children: [
                  const Spacer(),
                  _RecordBubble(
                    level: host._level,
                    label: left != null ? '$left' : _clock(host._elapsed),
                    cancel: zone == _HoldZone.cancel,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _ArcButton(
                          label: obicPhrase(context, ar: 'إلغاء', en: 'Cancel', zh: '取消'),
                          on: zone == _HoldZone.cancel,
                          danger: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ArcButton(
                          label: obicPhrase(
                            context,
                            ar: 'تحويل إلى نص',
                            en: 'Convert to text',
                            zh: '转文字',
                          ),
                          on: zone == _HoldZone.text,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _maxLeft(int elapsed) => math.max(0, 60 - elapsed);

  String _clock(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _RecordBubble extends StatelessWidget {
  const _RecordBubble({
    required this.level,
    required this.label,
    required this.cancel,
  });

  final double level;
  final String label;
  final bool cancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: cancel ? const Color(0xFFB91C1C) : ObicColors.navy,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        children: [
          _Wave(level: level),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _Wave extends StatelessWidget {
  const _Wave({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(9, (i) {
          final h = 8 + (level * 28) * ((i % 3) + 1) / 3;
          return Container(
            width: 4,
            height: h.clamp(6, 36),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

class _ArcButton extends StatelessWidget {
  const _ArcButton({required this.label, required this.on, this.danger = false});

  final String label;
  final bool on;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = on
        ? (danger ? const Color(0xFFEF4444) : ObicColors.blue)
        : Colors.white;
    final fg = on ? Colors.white : (danger ? const Color(0xFFB91C1C) : ObicColors.navy);
    return Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800),
      ),
    );
  }
}

enum _TextKind { text, voice, cancel, failed }

class _TextChoice {
  const _TextChoice(this.kind, this.text);
  final _TextKind kind;
  final String text;
}

class _TextChoiceDialog extends StatefulWidget {
  const _TextChoiceDialog({required this.transcribe});

  final Future<String?> Function()? transcribe;

  @override
  State<_TextChoiceDialog> createState() => _TextChoiceDialogState();
}

class _TextChoiceDialogState extends State<_TextChoiceDialog> {
  final TextEditingController _text = TextEditingController();
  bool _loading = false;
  bool _closed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final transcribe = widget.transcribe;
    if (transcribe == null) return;
    _loading = true;
    unawaited(_load(transcribe));
  }

  Future<void> _load(Future<String?> Function() transcribe) async {
    try {
      final text = await transcribe().timeout(const Duration(seconds: 25));
      if (!mounted || _closed) return;
      setState(() {
        _loading = false;
        _error = null;
        _text.text = text?.trim() ?? '';
      });
    } catch (_) {
      if (!mounted || _closed) return;
      setState(() {
        _loading = false;
        _error = obicPhrase(
          context,
          ar: 'تعذّر تحويل الصوت. حاول مرة أخرى.',
          en: 'Could not convert this voice message. Please try again.',
          zh: '无法转换这条语音，请重试。',
        );
      });
    }
  }

  void _close(_TextChoice choice) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(choice);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = ObicColors.inkOf(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _closed = true;
      },
      child: Dialog(
        backgroundColor: ObicColors.surfaceRaisedOf(context),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  obicPhrase(context, ar: 'النص', en: 'Text', zh: '文字'),
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _text,
                  minLines: 2,
                  maxLines: 5,
                  cursorColor: ObicColors.blue,
                  style: TextStyle(color: ink),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: ObicColors.surfaceOf(context),
                    hintText: _loading
                        ? obicPhrase(
                            context,
                            ar: 'جاري التحويل…',
                            en: 'Converting…',
                            zh: '正在转换…',
                          )
                        : _error != null
                            ? null
                            : obicPhrase(
                                context,
                                ar: 'ما تم التعرف على كلام',
                                en: 'No speech was recognised',
                                zh: '没有识别到语音',
                              ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => _close(
                      _TextChoice(_TextKind.text, _text.text),
                    ),
                    child: Text(
                      obicPhrase(context, ar: 'إرسال النص', en: 'Send text', zh: '发送文字'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _close(
                      _TextChoice(_TextKind.voice, _text.text),
                    ),
                    child: Text(
                      obicPhrase(context, ar: 'إرسال الصوت', en: 'Send voice', zh: '发送语音'),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _close(
                    const _TextChoice(_TextKind.cancel, ''),
                  ),
                  child: Text(obicPhrase(context, ar: 'إلغاء', en: 'Cancel', zh: '取消')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
