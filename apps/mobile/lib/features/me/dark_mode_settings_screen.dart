// Made by Dr Ali
// Dark mode — system / light / dark (persisted).

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../l10n/theme_mode_controller.dart';
import '../../theme/obic_colors.dart';

class DarkModeSettingsScreen extends StatelessWidget {
  const DarkModeSettingsScreen({
    super.key,
    required this.themeModeController,
  });

  final ThemeModeController themeModeController;

  static const _options = <ThemeMode>[
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  String _label(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
      ThemeMode.system => l10n.themeSystem,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: themeModeController,
      builder: (context, _) {
        final active = themeModeController.mode;
        return Scaffold(
          backgroundColor: ObicColors.canvasOf(context),
          appBar: AppBar(
            title: Text(l10n.settingsDarkMode),
            backgroundColor: ObicColors.surfaceOf(context),
            foregroundColor: ObicColors.inkOf(context),
            surfaceTintColor: Colors.transparent,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              for (var i = 0; i < _options.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _OptionCard(
                  title: _label(l10n, _options[i]),
                  selected: active == _options[i],
                  onTap: () => themeModeController.setMode(_options[i]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
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
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: ObicColors.inkOf(context),
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
