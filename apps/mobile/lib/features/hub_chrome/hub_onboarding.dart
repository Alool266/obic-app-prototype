// Made by Dr Ali
// First-open hub onboarding (1–2 screens) — never nags after done.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import 'hub_id.dart';
import 'hub_prefs.dart';
import 'hub_strings.dart';

Future<void> maybeShowHubOnboarding({
  required BuildContext context,
  required ObicHubId hub,
  required String langCode,
}) async {
  final prefs = HubPrefs(hub);
  if (await prefs.onboardingDone()) return;
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => HubOnboardingPage(hub: hub, langCode: langCode),
    ),
  );
}

class HubOnboardingPage extends StatefulWidget {
  const HubOnboardingPage({
    super.key,
    required this.hub,
    required this.langCode,
  });

  final ObicHubId hub;
  final String langCode;

  @override
  State<HubOnboardingPage> createState() => _HubOnboardingPageState();
}

class _HubOnboardingPageState extends State<HubOnboardingPage> {
  final _page = PageController();
  late final HubChromeStrings s =
      HubChromeStrings(widget.langCode, widget.hub);
  int _index = 0;

  Future<void> _finish() async {
    await HubPrefs(widget.hub).setOnboardingDone();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = s.onboardingPages;
    final last = _index >= pages.length - 1;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _finish,
                child: Text(s.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = pages[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Icon(
                          widget.hub == ObicHubId.china
                              ? Icons.public_rounded
                              : widget.hub == ObicHubId.daily
                                  ? Icons.storefront_rounded
                                  : Icons.flight_takeoff_rounded,
                          size: 56,
                          color: ObicColors.blue,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          p.title,
                          style: TextStyle(
                            color: ObicColors.titleOf(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.body,
                          style: TextStyle(
                            color: ObicColors.mutedOf(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _index
                          ? ObicColors.blue
                          : ObicColors.mutedOf(context).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (last) {
                      _finish();
                    } else {
                      _page.nextPage(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: ObicColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(last ? s.onboardingStart : s.onboardingNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
