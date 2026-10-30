// Made by Dr Ali
// Shared gear + share actions for hub heroes.

import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import 'hub_id.dart';
import 'hub_settings_page.dart';
import 'hub_share.dart';
import 'hub_strings.dart';

class HubHeroActions extends StatelessWidget {
  const HubHeroActions({
    super.key,
    required this.hub,
    required this.langCode,
    this.authController,
    this.cityChoices = const [],
  });

  final ObicHubId hub;
  final String langCode;
  final AuthController? authController;
  final List<String> cityChoices;

  @override
  Widget build(BuildContext context) {
    final s = HubChromeStrings(langCode, hub);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _glassIcon(
          context,
          icon: Icons.ios_share_rounded,
          tooltip: s.shareHub,
          onTap: () => shareObicHub(hub: hub, strings: s),
        ),
        const SizedBox(width: 6),
        _glassIcon(
          context,
          icon: Icons.settings_rounded,
          tooltip: s.settingsTitle,
          onTap: () => openHubSettings(
            context: context,
            hub: hub,
            langCode: langCode,
            authController: authController,
            cityChoices: cityChoices,
          ),
        ),
      ],
    );
  }

  Widget _glassIcon(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFFF8F5EE), size: 20),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
