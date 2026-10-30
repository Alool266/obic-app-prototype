// Made by Dr Ali
// Glass floating OBIC AI mark — frosted translucent face, no heavy shadow.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';

/// Shared glass face + clean mark used by the Home float and Messages AppBar.
class ObicAiGlassMark extends StatelessWidget {
  const ObicAiGlassMark({super.key, this.size = 52, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    final face = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Frosted glass: translucent white + light brand tint — not opaque navy.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.72),
                Colors.white.withValues(alpha: 0.58),
                ObicColors.blueSoft.withValues(alpha: 0.45),
              ],
              stops: const [0, 0.55, 1],
            ),
            border: Border.all(
              color: ObicColors.navy.withValues(alpha: 0.22),
              width: 1,
            ),
            // No BoxShadow — hairline border only.
          ),
          child: CustomPaint(
            size: Size.square(size * 0.44),
            painter: _ObicAiMarkPainter(
              color: ObicColors.navy.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return face;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        borderRadius: BorderRadius.circular(radius),
        child: face,
      ),
    );
  }
}

/// Minimal monochrome four-point sparkles — pro assistant glyph (not emoji / “AI” type).
class _ObicAiMarkPainter extends CustomPainter {
  _ObicAiMarkPainter({required this.color});

  final Color color;

  Path _spark(Offset c, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * (math.pi / 2);
      final aMid = a + math.pi / 4;
      final tip = Offset(
        c.dx + math.cos(a) * outer,
        c.dy + math.sin(a) * outer,
      );
      final waist = Offset(
        c.dx + math.cos(aMid) * inner,
        c.dy + math.sin(aMid) * inner,
      );
      if (i == 0) {
        path.moveTo(tip.dx, tip.dy);
      } else {
        path.lineTo(tip.dx, tip.dy);
      }
      path.lineTo(waist.dx, waist.dy);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide / 2;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Primary spark (slightly left of center for balance with accent).
    canvas.drawPath(
      _spark(Offset(cx - r * 0.1, cy + r * 0.06), r * 0.7, r * 0.2),
      fill,
    );

    // Smaller accent spark — classic assistant mark language.
    canvas.drawPath(
      _spark(Offset(cx + r * 0.4, cy - r * 0.36), r * 0.28, r * 0.085),
      fill..color = color.withValues(alpha: 0.78),
    );
  }

  @override
  bool shouldRepaint(covariant _ObicAiMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Floating assistant bubble for the Home stack. Tap opens OBIC AI.
///
/// Idle motion: gentle vertical bob + soft scale pulse. Honors
/// [MediaQuery.disableAnimations] / reduce-motion.
class ObicAiFloatingBubble extends StatefulWidget {
  const ObicAiFloatingBubble({super.key, required this.onTap, this.tooltip});

  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<ObicAiFloatingBubble> createState() => _ObicAiFloatingBubbleState();
}

class _ObicAiFloatingBubbleState extends State<ObicAiFloatingBubble>
    with TickerProviderStateMixin {
  static const double _size = 52;

  late final AnimationController _bob;
  late final AnimationController _pulse;
  late final Animation<double> _bobY;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _bobY = Tween<double>(
      begin: -3.5,
      end: 3.5,
    ).animate(CurvedAnimation(parent: _bob, curve: Curves.easeInOut));
    _scale = Tween<double>(
      begin: 1,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _bob.stop();
      _pulse.stop();
      _bob.value = 0.5;
      _pulse.value = 0;
      return;
    }
    if (!_bob.isAnimating) {
      _bob.repeat(reverse: true);
    }
    if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tooltip = widget.tooltip;
    final child = AnimatedBuilder(
      animation: Listenable.merge([_bob, _pulse]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bobY.value),
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
      child: ObicAiGlassMark(size: _size, onTap: widget.onTap),
    );

    if (tooltip == null || tooltip.isEmpty) return child;
    return Tooltip(message: tooltip, child: child);
  }
}

/// Left-edge placement on the full-screen shell, above the tab bar.
class ObicAiFloatingBubbleOverlay extends StatelessWidget {
  const ObicAiFloatingBubbleOverlay({
    super.key,
    required this.onTap,
    this.tooltip,
  });

  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final viewBottom = MediaQuery.viewPaddingOf(context).bottom;
    // This overlay is mounted on the full-screen shell, so the 68px
    // NavigationBar and the system inset are still under it. The extra
    // band keeps the 52px bubble above the tab icon/label and above the
    // contacts count line (that line keeps 148px of list padding).
    const bar = 68.0;
    const aboveBar = 72.0;
    final bottom = viewBottom + bar + aboveBar;

    return Positioned(
      left: 10 + pad.left,
      bottom: bottom,
      child: ObicAiFloatingBubble(onTap: onTap, tooltip: tooltip),
    );
  }
}
