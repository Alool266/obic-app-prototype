// Made by Dr Ali
// WeChat-style Moments cover adjust — pan (and light zoom) before save.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

/// Result of cover adjust: local file path + vertical focus (−1…1).
class MomentsCoverAdjustResult {
  const MomentsCoverAdjustResult({
    required this.imagePath,
    required this.focusY,
  });

  final String imagePath;
  final double focusY;
}

class MomentsCoverAdjustScreen extends StatefulWidget {
  const MomentsCoverAdjustScreen({
    super.key,
    required this.imagePath,
    this.initialFocusY = 0,
  });

  final String imagePath;
  final double initialFocusY;

  @override
  State<MomentsCoverAdjustScreen> createState() =>
      _MomentsCoverAdjustScreenState();
}

class _MomentsCoverAdjustScreenState extends State<MomentsCoverAdjustScreen> {
  late double _focusY;
  double _scale = 1.0;
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _focusY = widget.initialFocusY.clamp(-1.0, 1.0);
  }

  void _onScaleStart(ScaleStartDetails _) {
    _baseScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _scale = (_baseScale * d.scale).clamp(1.0, 2.5);
      // Drag maps to focusY; larger scale → more room to pan.
      if (d.pointerCount == 1 || d.focalPointDelta.dy.abs() > 0.5) {
        final h = MediaQuery.sizeOf(context).height;
        final delta = d.focalPointDelta.dy / (h * 0.22 * _scale);
        _focusY = (_focusY - delta).clamp(-1.0, 1.0);
      }
    });
  }

  void _save() {
    Navigator.pop(
      context,
      MomentsCoverAdjustResult(
        imagePath: widget.imagePath,
        focusY: _focusY,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    // WeChat Moments cover is a wide banner (~screen width × ~0.55–0.6 height).
    final frameH = size.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.momentsCoverAdjust),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              l10n.momentsCoverSave,
              style: const TextStyle(
                color: Color(0xFF07C160),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: size.width,
                height: frameH,
                child: ClipRect(
                  child: GestureDetector(
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: Colors.grey.shade900),
                        Transform.scale(
                          scale: _scale,
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                            alignment: Alignment(0, _focusY),
                            width: size.width,
                            height: frameH,
                          ),
                        ),
                        // Dim outside feel — thin edge guides.
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Text(
              l10n.momentsCoverAdjustHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
