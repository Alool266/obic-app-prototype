// Made by Dr Ali
// Soft dimensional service marks — gradient, gloss, and a light press tilt.
// Drawn in Flutter so the services tab does not need image files.

import 'package:flutter/material.dart';

import '../../../theme/obic_colors.dart';
import '../../../widgets/obic_soft_motion.dart';
import '../service_catalog.dart';

class Soft3dServiceMark extends StatelessWidget {
  const Soft3dServiceMark({
    super.key,
    required this.service,
    this.size = 46,
    this.press = 0,
  });

  final ObicService service;
  final double size;
  final double press;

  @override
  Widget build(BuildContext context) {
    final theme = ServiceTheme.of(service.colorKey);
    final dark = ObicColors.isDark(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final t = press.clamp(0.0, 1.2);
    final tiltY = (rtl ? 0.28 : -0.28) * (1 + 0.35 * t);
    final tiltX = -0.38 - 0.22 * t;
    return SizedBox(
      width: size,
      height: size + size * 0.14,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          PositionedDirectional(
            start: size * 0.12,
            end: size * 0.12,
            bottom: 0,
            child: Container(
              height: size * 0.16,
              decoration: BoxDecoration(
                color: theme.end.withValues(alpha: dark ? 0.38 : 0.22),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateX(tiltX)
              ..rotateY(tiltY),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.3),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(theme.start, Colors.white, dark ? 0.05 : 0.18)!,
                    theme.start,
                    theme.end,
                  ],
                  stops: const [0, 0.45, 1],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: dark ? 0.22 : 0.55),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.end.withValues(alpha: dark ? 0.5 : 0.32),
                    blurRadius: 10,
                    offset: Offset(rtl ? -2 : 2, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: FractionallySizedBox(
                      widthFactor: 0.78,
                      heightFactor: 0.48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(size * 0.24),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.5),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      serviceIconData(service.icon),
                      color: Colors.white,
                      size: size * 0.46,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Soft3dServiceGrid extends StatelessWidget {
  const Soft3dServiceGrid({
    super.key,
    required this.services,
    required this.langCode,
    required this.onTap,
    this.columns = 5,
  });

  final List<ObicService> services;
  final String langCode;
  final ValueChanged<ObicService> onTap;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];
    for (var i = 0; i < services.length; i += columns) {
      final end = (i + columns).clamp(0, services.length);
      final chunk = services.sublist(i, end);
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 4));
      rows.add(
        _ServiceRow(
          services: chunk,
          langCode: langCode,
          onTap: onTap,
          columns: columns,
        ),
      );
    }
    return Column(children: rows);
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.services,
    required this.langCode,
    required this.onTap,
    required this.columns,
  });

  final List<ObicService> services;
  final String langCode;
  final ValueChanged<ObicService> onTap;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final slots = List<ObicService?>.from(services);
    while (slots.length < columns) {
      slots.add(null);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: slots[i] == null
                ? const SizedBox.shrink()
                : _PressTile(
                    service: slots[i]!,
                    langCode: langCode,
                    onTap: () => onTap(slots[i]!),
                  ),
          ),
        ],
      ],
    );
  }
}

class _PressTile extends StatefulWidget {
  const _PressTile({
    required this.service,
    required this.langCode,
    required this.onTap,
  });

  final ObicService service;
  final String langCode;
  final VoidCallback onTap;

  @override
  State<_PressTile> createState() => _PressTileState();
}

class _PressTileState extends State<_PressTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _tilt;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _tilt = CurvedAnimation(
      parent: _press,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down(bool pressed) {
    if (obicReduceMotion(context)) return;
    if (pressed) {
      _press.forward();
    } else {
      _press.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _down(true),
        onTapCancel: () => _down(false),
        onTapUp: (_) {
          _down(false);
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _tilt,
          builder: (context, _) {
            final t = _tilt.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 1 - 0.05 * t.clamp(0.0, 1.0),
                    child: Soft3dServiceMark(service: widget.service, press: t),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.service.name(widget.langCode),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ObicColors.titleOf(context),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
