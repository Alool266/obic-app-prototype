// Made by Dr Ali
// One slim offline strip for the whole app. Pages must not draw their own.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.statusTop});

  final double statusTop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: const Color(0xFF1C2333),
      child: Padding(
        padding: EdgeInsets.only(top: statusTop),
        child: SizedBox(
          height: 36,
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFF4F7FB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.offlineBanner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF4F7FB),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Short helper for SnackBars / inline hints when an action needs the network.
String offlineNeedsNetworkMessage(AppLocalizations l10n) =>
    l10n.offlineNeedsNetwork;

/// Red strip for an action that cannot run without a connection.
void showNoInternetBanner(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentMaterialBanner();
  messenger.showMaterialBanner(
    MaterialBanner(
      backgroundColor: const Color(0xFFB42318),
      content: Text(
        AppLocalizations.of(context).offlineNoInternet,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: Text(
            AppLocalizations.of(context).actionOk,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

Future<void> showNetworkUnavailableDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.networkUnavailable),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionOk),
        ),
      ],
    ),
  );
}
