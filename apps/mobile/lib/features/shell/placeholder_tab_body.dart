// Made by Dr Ali
// Shared placeholder body used by Phase 1 tab screens.

import 'package:flutter/material.dart';

import '../../widgets/obic_surface.dart';

class PlaceholderTabBody extends StatelessWidget {
  const PlaceholderTabBody({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ObicEmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }
}
