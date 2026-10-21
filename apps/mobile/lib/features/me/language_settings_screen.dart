// Made by Dr Ali
// Language settings — dedicated AR / EN / 中文 page (locale + RTL).

import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/language_switcher.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key, required this.localeController});

  final LocaleController localeController;

  static const _options =
      <(String code, String nativeName, String englishName)>[
        ('ar', 'العربية', 'Arabic'),
        ('en', 'English', 'English'),
        ('zh', '中文', 'Chinese'),
        ('fr', 'Français', 'French'),
      ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final active = localeController.langCode;
        return Scaffold(
          backgroundColor: ObicColors.canvasOf(context),
          appBar: AppBar(
            title: Text(languageMenuTitle(active)),
            backgroundColor: ObicColors.surfaceOf(context),
            foregroundColor: ObicColors.inkOf(context),
            surfaceTintColor: Colors.transparent,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              for (var i = 0; i < _options.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _LanguageOptionCard(
                  nativeName: _options[i].$2,
                  englishName: _options[i].$3,
                  selected: active == _options[i].$1,
                  onTap: () =>
                      localeController.setLocale(Locale(_options[i].$1)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.nativeName,
    required this.englishName,
    required this.selected,
    required this.onTap,
  });

  final String nativeName;
  final String englishName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ObicColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? ObicColors.blue : ObicColors.lineOf(context),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          nativeName,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: ObicColors.inkOf(context),
          ),
        ),
        subtitle: englishName == nativeName
            ? null
            : Text(
                englishName,
                style: TextStyle(
                  color: ObicColors.mutedOf(context),
                  fontSize: 13,
                ),
              ),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded, color: ObicColors.blue)
            : Icon(
                Icons.circle_outlined,
                color: ObicColors.mutedOf(context).withValues(alpha: 0.45),
              ),
        onTap: onTap,
      ),
    );
  }
}
