// Made by Dr Ali
// Lightweight rotating globe. A still drawing is used when motion is reduced
// or the UI or raster thread stays slow — no 3D engine.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../theme/obic_colors.dart';
import '../../../widgets/obic_soft_motion.dart';

class ServicesGlobeHero extends StatefulWidget {
  const ServicesGlobeHero({super.key, required this.title});

  final String title;

  @override
  State<ServicesGlobeHero> createState() => _ServicesGlobeHeroState();
}

class _ServicesGlobeHeroState extends State<ServicesGlobeHero>
    with SingleTickerProviderStateMixin {
  static const _chinaFacing = 105 / 360;

  /// Opening the tab (and Android's first frames) are slow on every phone.
  /// Those frames must not freeze the globe for the rest of the visit.
  static const _warmupFrames = 48;

  /// Recent frames kept after warmup. The still drawing is used only when
  /// most of this window is actually slow.
  static const _window = 24;
  static const _slowFramesToStop = 18;

  /// Real UI-thread or raster-thread work. [FrameTiming.totalSpan] also
  /// includes vsync wait and the Android pipeline gap, which stays high
  /// while the sphere is still turning smoothly.
  static const _slowWork = Duration(milliseconds: 50);

  late final AnimationController _spin;
  bool _flat = false;
  bool _reduce = false;
  int _warmupLeft = _warmupFrames;
  final List<bool> _recentSlow = <bool>[];

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  bool _frameIsSlow(FrameTiming timing) {
    return timing.buildDuration > _slowWork ||
        timing.rasterDuration > _slowWork;
  }

  void _onTimings(List<FrameTiming> timings) {
    if (_flat || !mounted || _reduce) return;
    for (final timing in timings) {
      if (_warmupLeft > 0) {
        _warmupLeft -= 1;
        continue;
      }
      _recentSlow.add(_frameIsSlow(timing));
      if (_recentSlow.length > _window) _recentSlow.removeAt(0);
    }
    if (_recentSlow.length < _window) return;
    var slowCount = 0;
    for (final slow in _recentSlow) {
      if (slow) slowCount += 1;
    }
    if (slowCount < _slowFramesToStop) return;
    _flat = true;
    _spin.stop();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _syncSpin() {
    if (_reduce || _flat) {
      if (_spin.isAnimating) _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = obicReduceMotion(context);
    _syncSpin();
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = ObicColors.isDark(context);
    final reduce = obicReduceMotion(context);
    final flat = _flat || reduce;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ObicColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ObicColors.lineOf(context).withValues(alpha: 0.75),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              SizedBox(
                height: 148,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _spin,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _GlobePainter(
                          turn: flat ? _chinaFacing : _spin.value,
                          dark: dark,
                          dimensional: !flat,
                        ),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
              ),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ObicColors.titleOf(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  const _GlobePainter({
    required this.turn,
    required this.dark,
    required this.dimensional,
  });

  final double turn;
  final bool dark;
  final bool dimensional;

  static const _china = <(double, double)>[
    (73.5, 39.5),
    (75.0, 36.5),
    (79.0, 31.5),
    (85.0, 28.2),
    (91.0, 27.5),
    (97.0, 28.2),
    (98.8, 23.5),
    (101.5, 21.8),
    (106.5, 22.8),
    (109.5, 18.5),
    (114.0, 22.4),
    (118.5, 24.5),
    (121.5, 29.5),
    (122.2, 37.2),
    (126.0, 41.0),
    (131.0, 45.0),
    (134.5, 47.5),
    (127.5, 49.5),
    (119.5, 53.0),
    (112.0, 46.0),
    (104.0, 41.8),
    (95.0, 44.0),
    (87.5, 48.5),
    (80.0, 46.0),
    (73.5, 40.0),
  ];

  static const _africa = <(double, double)>[
    (-5, 35),
    (-10, 28),
    (-17, 15),
    (-16, 5),
    (-10, -5),
    (8, -12),
    (15, -28),
    (25, -34),
    (32, -28),
    (40, -15),
    (43, 2),
    (40, 12),
    (32, 30),
    (12, 32),
    (-5, 35),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final radius = math.min(size.width, size.height) * 0.36;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: dark ? 0.4 : 0.12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.95),
        width: radius * 1.35,
        height: radius * 0.28,
      ),
      shadow,
    );

    final disc = Rect.fromCircle(center: center, radius: radius);
    final colors = dimensional
        ? (dark
              ? const [Color(0xFF8EB6FF), ObicColors.blue, ObicColors.navyDeep]
              : const [Color(0xFFD6E6FF), ObicColors.blue, ObicColors.blueDeep])
        : (dark
              ? const [ObicColors.blue, ObicColors.navy]
              : const [Color(0xFF4C8DFF), ObicColors.blue]);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: dimensional
              ? const Alignment(-0.35, -0.45)
              : Alignment.center,
          radius: dimensional ? 1.05 : 0.9,
          colors: colors,
        ).createShader(disc),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(disc));
    if (dimensional) _grid(canvas, center, radius);
    _land(
      canvas,
      center,
      radius,
      _africa,
      Colors.white.withValues(alpha: dimensional ? 0.28 : 0.22),
    );
    _land(
      canvas,
      center,
      radius,
      _china,
      Colors.white.withValues(alpha: dimensional ? 0.88 : 0.95),
    );
    canvas.restore();

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dimensional ? 1.4 : 1
        ..color = Colors.white.withValues(alpha: dark ? 0.28 : 0.7),
    );

    if (!dimensional) return;
    final glareCenter = center + Offset(-radius * 0.28, -radius * 0.32);
    canvas.drawCircle(
      glareCenter,
      radius * 0.22,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: glareCenter, radius: radius * 0.22),
            ),
    );
  }

  void _grid(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.28);
    for (var i = 0; i < 6; i++) {
      final lon = i * 60.0;
      final path = Path();
      var moved = false;
      for (var lat = -72.0; lat <= 72; lat += 6) {
        final point = _project(center, radius, lon, lat);
        if (point == null) {
          moved = false;
          continue;
        }
        if (!moved) {
          path.moveTo(point.dx, point.dy);
          moved = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  void _land(
    Canvas canvas,
    Offset center,
    double radius,
    List<(double, double)> outline,
    Color color,
  ) {
    final path = Path();
    var moved = false;
    for (final spot in outline) {
      final point = _project(center, radius, spot.$1, spot.$2);
      if (point == null) {
        moved = false;
        continue;
      }
      if (!moved) {
        path.moveTo(point.dx, point.dy);
        moved = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  Offset? _project(Offset center, double radius, double lonDeg, double latDeg) {
    final lon = lonDeg * math.pi / 180 - turn * math.pi * 2;
    final lat = latDeg * math.pi / 180;
    final cosLat = math.cos(lat);
    final facing = cosLat * math.cos(lon);
    if (facing <= 0.05) return null;
    final x = cosLat * math.sin(lon);
    final y = -math.sin(lat);
    return center + Offset(x * radius * 0.92, y * radius * 0.92);
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) {
    return oldDelegate.turn != turn ||
        oldDelegate.dark != dark ||
        oldDelegate.dimensional != dimensional;
  }
}
