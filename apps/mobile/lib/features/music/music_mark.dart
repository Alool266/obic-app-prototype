// Made by Dr Ali
// OBIC Music mark. Not the company logo and not another service's icon.

import 'package:flutter/material.dart';

class MusicMark extends StatelessWidget {
  const MusicMark({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MusicMarkPainter()),
    );
  }
}

class _MusicMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.27));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1F3A), Color(0xFF12305C)],
        ).createShader(rect),
    );
    final note = Paint()
      ..color = const Color(0xFF1A6DFF)
      ..style = PaintingStyle.fill;
    final head = Rect.fromCircle(
      center: Offset(size.width * 0.38, size.height * 0.68),
      radius: size.width * 0.11,
    );
    canvas.drawOval(head, note);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.46, size.height * 0.28, size.width * 0.06, size.height * 0.42),
        Radius.circular(size.width * 0.02),
      ),
      note,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.46, size.height * 0.26, size.width * 0.26, size.height * 0.08),
        Radius.circular(size.width * 0.02),
      ),
      note,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
