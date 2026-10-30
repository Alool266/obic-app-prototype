// Made by Dr Ali
// Small empty-state motion. A still icon stands in when motion is reduced
// or the Lottie file cannot be read.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/obic_colors.dart';
import 'obic_soft_motion.dart';

class ObicLottieEmpty extends StatelessWidget {
  const ObicLottieEmpty({super.key, required this.message, this.size = 96});

  final String message;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reduce = obicReduceMotion(context);
    final fallback = Icon(
      Icons.inbox_rounded,
      size: size * 0.46,
      color: ObicColors.blue,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          if (reduce)
            fallback
          else
            Lottie.asset(
              'assets/lottie/empty_soft.json',
              width: size,
              height: size,
              repeat: true,
              errorBuilder: (_, _, _) => fallback,
            ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ObicColors.mutedOf(context),
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
