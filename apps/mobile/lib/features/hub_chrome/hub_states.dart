// Made by Dr Ali
// Illustrated empty / error / loading / offline states for hubs.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../theme/obic_colors.dart';
import 'hub_strings.dart';

class HubLoadingState extends StatelessWidget {
  const HubLoadingState({super.key, required this.strings});
  final HubChromeStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              strings.loading,
              style: TextStyle(
                color: ObicColors.mutedOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HubIllustratedState extends StatelessWidget {
  const HubIllustratedState({
    super.key,
    required this.strings,
    required this.kind,
    this.onRetry,
  });

  final HubChromeStrings strings;
  final HubStateKind kind;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, title, hint) = switch (kind) {
      HubStateKind.empty => (
          Icons.inbox_outlined,
          strings.emptyTitle,
          strings.emptyHint,
        ),
      HubStateKind.error => (
          Icons.error_outline_rounded,
          strings.errorTitle,
          strings.errorHint,
        ),
      HubStateKind.offline => (
          Icons.wifi_off_rounded,
          strings.offline,
          strings.offlineHint,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/lottie/empty_soft.json',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  icon,
                  size: 56,
                  color: ObicColors.mutedOf(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ObicColors.titleOf(context),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ObicColors.mutedOf(context),
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(backgroundColor: ObicColors.blue),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(strings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum HubStateKind { empty, error, offline }
