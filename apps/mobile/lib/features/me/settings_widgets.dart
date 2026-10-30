// Made by Dr Ali
// Dense WeChat-style settings list primitives (OBIC brand).

import 'package:flutter/material.dart';

import '../../core/obic_bidi.dart';
import '../../theme/obic_colors.dart';

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: ObicColors.mutedOf(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.children,
    this.dividerIndent = 16,
  });
  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final line = ObicColors.lineOf(context);
    return Container(
      color: ObicColors.surfaceOf(context),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: dividerIndent, color: line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
    this.identifierValue = false,
  });

  final String title;
  final String? subtitle;
  final String? value;

  /// Phone numbers and similar identifiers stay left-to-right.
  final bool identifierValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = ObicColors.mutedOf(context);
    final ink = ObicColors.inkOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final showValue = value != null && value!.isNotEmpty;
    final valueStyle = TextStyle(fontSize: 13, color: muted);
    final titleStyle = TextStyle(fontSize: 15, height: 1.2, color: ink);
    // RTL trailing pins a phone number to the far edge, away from the label.
    final identifierBesideLabel = identifierValue && rtl && showValue;

    Widget valueLabel() {
      if (!showValue) return const SizedBox.shrink();
      if (identifierValue) {
        return ObicIdentifierText(value!, style: valueStyle);
      }
      return Text(
        value!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: valueStyle,
      );
    }

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minVerticalPadding: 8,
      title: identifierBesideLabel
          ? Row(
              children: [
                Text(title, style: titleStyle),
                const SizedBox(width: 10),
                Flexible(child: valueLabel()),
              ],
            )
          : Text(title, style: titleStyle),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(fontSize: 12, color: muted)),
      trailing: identifierBesideLabel
          ? Icon(
              Icons.chevron_right_rounded,
              color: muted.withValues(alpha: 0.7),
              size: 20,
              textDirection: TextDirection.ltr,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showValue)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: valueLabel(),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: muted.withValues(alpha: 0.7),
                  size: 20,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
      onTap: onTap,
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted = ObicColors.mutedOf(context);
    final ink = ObicColors.inkOf(context);
    return SwitchListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, height: 1.2, color: ink),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(fontSize: 12, color: muted)),
      value: value,
      activeTrackColor: ObicColors.blue.withValues(alpha: 0.45),
      activeThumbColor: ObicColors.blue,
      onChanged: onChanged,
    );
  }
}

class SettingsReadonlyTile extends StatelessWidget {
  const SettingsReadonlyTile({
    super.key,
    required this.title,
    required this.value,
    this.hint,
    this.identifierValue = false,
  });

  final String title;
  final String value;
  final String? hint;

  /// Phone numbers and emails stay left-to-right.
  final bool identifierValue;

  @override
  Widget build(BuildContext context) {
    final muted = ObicColors.mutedOf(context);
    final ink = ObicColors.inkOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final valueStyle = TextStyle(fontSize: 13, color: muted);
    final titleStyle = TextStyle(fontSize: 15, color: ink);
    final identifierBesideLabel =
        identifierValue && rtl && value.isNotEmpty;

    Widget valueLabel() {
      if (value.isEmpty) {
        return Text(
          '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: valueStyle,
        );
      }
      if (identifierValue) {
        return ObicIdentifierText(value, style: valueStyle);
      }
      return Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: valueStyle,
      );
    }

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minVerticalPadding: 8,
      title: identifierBesideLabel
          ? Row(
              children: [
                Text(title, style: titleStyle),
                const SizedBox(width: 10),
                Flexible(child: valueLabel()),
              ],
            )
          : Text(title, style: titleStyle),
      subtitle: hint == null
          ? null
          : Text(hint!, style: TextStyle(fontSize: 11, color: muted)),
      trailing: identifierBesideLabel
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: valueLabel(),
            ),
    );
  }
}
