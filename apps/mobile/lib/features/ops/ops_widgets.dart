// Made by Dr Ali
// Shared UI chips/cards for Internal Ops prototype.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';

class OpsBanner extends StatelessWidget {
  const OpsBanner({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9A3412),
          fontSize: 12.5,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class OpsSectionTitle extends StatelessWidget {
  const OpsSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: ObicColors.titleOf(context),
        ),
      ),
    );
  }
}

class OpsStatCard extends StatelessWidget {
  const OpsStatCard({
    super.key,
    required this.label,
    required this.value,
    this.accent = ObicColors.blue,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ObicColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ObicColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: ObicColors.mutedOf(context), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class OpsPill extends StatelessWidget {
  const OpsPill(this.text, {super.key, this.color = ObicColors.blueSoft});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: ObicColors.titleOf(context),
        ),
      ),
    );
  }
}

class OpsListCard extends StatelessWidget {
  const OpsListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ObicColors.surfaceOf(context),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: ObicColors.lineOf(context)),
      ),
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ObicColors.inkOf(context),
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: TextStyle(
                  height: 1.35,
                  color: ObicColors.mutedOf(context),
                ),
              ),
        trailing: trailing ??
            (onTap == null
                ? null
                : Icon(Icons.chevron_left, color: ObicColors.mutedOf(context))),
        onTap: onTap,
      ),
    );
  }
}
