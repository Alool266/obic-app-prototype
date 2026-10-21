// Made by Dr Ali
// AR · EN · 中文 switcher — highlights active locale.

import 'package:flutter/material.dart';

import '../l10n/locale_controller.dart';
import '../theme/obic_colors.dart';

class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({
    super.key,
    required this.controller,
    this.foregroundColor,
    this.backgroundColor,
    this.padding,
  });

  final LocaleController controller;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final fg = foregroundColor ?? ObicColors.titleOf(context);
        return TextButton(
          onPressed: controller.toggle,
          style: TextButton.styleFrom(
            foregroundColor: fg,
            backgroundColor: backgroundColor,
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: LanguageSwitcherLabel(controller: controller, color: fg),
        );
      },
    );
  }
}

class LanguageSwitcherLabel extends StatelessWidget {
  const LanguageSwitcherLabel({
    super.key,
    required this.controller,
    this.color,
    this.fontSize = 13,
  });

  final LocaleController controller;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final active = controller.langCode;
    final base = color ?? ObicColors.titleOf(context);
    TextStyle styleFor(String code) => TextStyle(
      color: base.withValues(alpha: active == code ? 1 : 0.55),
      fontWeight: active == code ? FontWeight.w800 : FontWeight.w500,
      fontSize: fontSize,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('AR', style: styleFor('ar')),
          Text(
            ' · ',
            style: TextStyle(
              color: base.withValues(alpha: 0.45),
              fontSize: fontSize,
            ),
          ),
          Text('EN', style: styleFor('en')),
          Text(
            ' · ',
            style: TextStyle(
              color: base.withValues(alpha: 0.45),
              fontSize: fontSize,
            ),
          ),
          Text('中文', style: styleFor('zh')),
          Text(
            ' · ',
            style: TextStyle(
              color: base.withValues(alpha: 0.45),
              fontSize: fontSize,
            ),
          ),
          Text('FR', style: styleFor('fr')),
        ],
      ),
    );
  }
}

String languageMenuTitle(String langCode) {
  switch (langCode) {
    case 'zh':
      return '语言';
    case 'en':
      return 'Language';
    case 'fr':
      return 'Langue';
    default:
      return 'اللغة';
  }
}

/// Native display name for the active locale (used on Me → Language row).
String languageNativeName(String langCode) {
  switch (langCode) {
    case 'zh':
      return '中文';
    case 'en':
      return 'English';
    case 'fr':
      return 'Français';
    default:
      return 'العربية';
  }
}
