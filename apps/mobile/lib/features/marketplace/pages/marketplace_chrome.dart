// Made by Dr Ali
// Shared chrome for marketplace mini-app pages.

import 'package:flutter/material.dart';

import '../../../theme/obic_colors.dart';
import '../../../widgets/obic_back_button.dart';
import '../../../widgets/obic_soft_motion.dart';
import '../../auth/auth_controller.dart';
import '../marketplace_models.dart';
import '../marketplace_request.dart';

String mp(String lang, String ar, String en, [String? zh]) {
  if (lang.startsWith('ar')) return ar;
  if (lang.startsWith('zh')) return zh ?? en;
  return en;
}

class MarketplaceScaffold extends StatelessWidget {
  const MarketplaceScaffold({
    super.key,
    required this.title,
    required this.accent,
    required this.body,
    this.searchHint,
    this.onSearch,
    this.headerExtra,
  });

  final String title;
  final Color accent;
  final Widget body;
  final String? searchHint;
  final ValueChanged<String>? onSearch;
  final Widget? headerExtra;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(12, top + 6, 12, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ObicColors.navyDeep,
                  accent.withValues(alpha: 0.85),
                  ObicColors.navy,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ObicBackButton(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF8F5EE),
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
                if (searchHint != null && onSearch != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: onSearch,
                    style: TextStyle(color: ObicColors.inkOf(context)),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: ObicColors.blue,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ],
                if (headerExtra != null) ...[
                  const SizedBox(height: 10),
                  headerExtra!,
                ],
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class MarketplaceCtaBar extends StatelessWidget {
  const MarketplaceCtaBar({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: ObicColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}

/// Book/request CTA — creates an OBIC order (replaces Airwallex hold dialog).
Future<void> showMarketplaceHoldDialog(
  BuildContext context, {
  required AuthController auth,
  required String langCode,
  required String title,
  required MarketplaceVertical vertical,
  String? notes,
  Map<String, String>? formData,
  String? city,
}) {
  return submitMarketplaceRequest(
    context,
    auth: auth,
    langCode: langCode,
    vertical: vertical,
    title: title,
    notes: notes,
    formData: formData,
    city: city,
  );
}

class MarketplaceListCard extends StatelessWidget {
  const MarketplaceListCard({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: ObicBounce(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: ObicColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ObicColors.lineOf(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}
