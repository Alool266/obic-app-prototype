// Made by Dr Ali
// In-app OBIC brand mark — same asset as the launcher icon.

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

/// Navy square with bold white **OBIC** wordmark and blue accent bar.
/// Uses [app_icon_1024.png] so in-app branding matches the app icon.
class ObicLogo extends StatelessWidget {
  const ObicLogo({
    super.key,
    this.size = 88,
    this.borderRadius,
    this.metal = false,
  });

  /// High-res launcher icon — reused for all in-app logo placements.
  static const assetPath = 'assets/icon/app_icon_1024.png';

  final double size;

  /// Defaults to ~25% of [size] (matches auth screen rounding).
  final double? borderRadius;

  /// Slow metal sheen on Home and the login mark. Off when motion is reduced.
  final bool metal;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? size * 0.25;
    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Image.asset(
          'assets/icon/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
    if (!metal || MediaQuery.disableAnimationsOf(context)) return mark;
    return _ObicMetalMark(size: size, borderRadius: r, child: mark);
  }
}

class _ObicMetalMark extends StatefulWidget {
  const _ObicMetalMark({
    required this.size,
    required this.borderRadius,
    required this.child,
  });

  final double size;
  final double borderRadius;
  final Widget child;

  @override
  State<_ObicMetalMark> createState() => _ObicMetalMarkState();
}

class _ObicMetalMarkState extends State<_ObicMetalMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ShaderBuilder(
        (context, shader, child) {
          return AnimatedBuilder(
            animation: _sweep,
            builder: (context, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ?child,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: CustomPaint(
                      painter: _MetalSheenPainter(shader, _sweep.value),
                    ),
                  ),
                ],
              );
            },
          );
        },
        assetKey: 'shaders/obic_metal.frag',
        child: widget.child,
      ),
    );
  }
}

class _MetalSheenPainter extends CustomPainter {
  _MetalSheenPainter(this.shader, this.time);

  final FragmentShader shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, time);
    shader.setFloat(1, size.width);
    shader.setFloat(2, size.height);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.softLight,
    );
  }

  @override
  bool shouldRepaint(covariant _MetalSheenPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
