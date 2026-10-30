// Made by Dr Ali
// Settings → Mini apps. Submission lives on the public OBIC website.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/legal_links.dart';
import '../../theme/obic_colors.dart';

/// Public submit page. Not the admin review desk.
const kMiniAppsSubmitUrl = 'https://www.obicgp.com/mini-apps.html';

class MiniAppsSettingsScreen extends StatelessWidget {
  const MiniAppsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsMiniApps)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(l10n.miniAppsWebsiteBody, style: text.bodyLarge),
          const SizedBox(height: 16),
          SelectableText(
            kMiniAppsSubmitUrl,
            textDirection: TextDirection.ltr,
            style: text.bodyLarge?.copyWith(
              color: ObicColors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => ObicLegal.open(kMiniAppsSubmitUrl),
            child: Text(l10n.miniAppsOpenWebsite),
          ),
        ],
      ),
    );
  }
}
