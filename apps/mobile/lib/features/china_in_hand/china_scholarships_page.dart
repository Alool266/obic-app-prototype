// Made by Dr Ali
// منح دراسية — real public CSC/uni info + Obic order CTA (no fake admits).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_back_button.dart';
import '../../widgets/obic_cached_image.dart';
import '../auth/auth_controller.dart';
import 'china_in_hand_strings.dart';
import 'china_scholarships.dart';
import 'china_tile_nav.dart';

class ChinaScholarshipsPage extends StatelessWidget {
  const ChinaScholarshipsPage({
    super.key,
    required this.authController,
    required this.langCode,
  });

  final AuthController authController;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final s = ChinaInHandStrings(langCode);
    final programs = kChinaScholarshipPrograms;

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      body: CustomScrollView(
        slivers: [
          ContainedSliver(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).top + 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ObicCachedImage(
                    'assets/china/shanghai.jpg',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66071628), Color(0xF0071628)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 6,
                    left: 12,
                    child: const ObicBackButton(),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Text(
                      s.scholarshipsTitle,
                      style: const TextStyle(
                        color: Color(0xFFF8F5EE),
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ContainedSliver(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ObicColors.navy.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFC9A227).withValues(alpha: 0.45),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              color: Color(0xFFC9A227),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.scholarshipsDisclaimerTitle,
                                style: const TextStyle(
                                  color: Color(0xFFF8F5EE),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.scholarshipsDisclaimerBody,
                          style: TextStyle(
                            color:
                                const Color(0xFFF8F5EE).withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A227),
                      foregroundColor: ObicColors.navy,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => openChinaSubById(
                      context: context,
                      authController: authController,
                      langCode: langCode,
                      parentSlug: 'education',
                      subId: 'scholarships',
                    ),
                    icon: const Icon(Icons.support_agent_rounded),
                    label: Text(
                      s.scholarshipsCta,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    s.scholarshipsProgramsHeading,
                    style: TextStyle(
                      color: ObicColors.titleOf(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final p in programs) ...[
                    _ProgramCard(program: p, langCode: langCode, strings: s),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContainedSliver extends StatelessWidget {
  const ContainedSliver({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(child: child);
}

class _ProgramCard extends StatefulWidget {
  const _ProgramCard({
    required this.program,
    required this.langCode,
    required this.strings,
  });

  final ChinaScholarshipProgram program;
  final String langCode;
  final ChinaInHandStrings strings;

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  bool _open = false;

  Color get _kindColor {
    switch (widget.program.kind) {
      case ScholarshipKind.csc:
        return const Color(0xFFC9A227);
      case ScholarshipKind.university:
        return const Color(0xFF38BDF8);
      case ScholarshipKind.language:
        return const Color(0xFF34D399);
    }
  }

  String get _kindLabel {
    switch (widget.program.kind) {
      case ScholarshipKind.csc:
        return widget.strings.scholarshipsKindCsc;
      case ScholarshipKind.university:
        return widget.strings.scholarshipsKindUni;
      case ScholarshipKind.language:
        return widget.strings.scholarshipsKindLang;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.program;
    final lang = widget.langCode;
    final s = widget.strings;

    return Material(
      color: ObicColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ObicCachedImage(p.imageAsset, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC071628)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kindColor.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _kindLabel,
                        style: const TextStyle(
                          color: Color(0xFF071628),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title(lang),
                    style: TextStyle(
                      color: ObicColors.inkOf(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.host(lang),
                    style: TextStyle(
                      color: ObicColors.mutedOf(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  if (_open) ...[
                    const SizedBox(height: 12),
                    _block(context, s.scholarshipsEligibility, p.eligibility(lang)),
                    _block(context, s.scholarshipsCoverage, p.coverage(lang)),
                    _block(context, s.scholarshipsDeadline, p.deadline(lang)),
                    _block(context, s.scholarshipsHowToApply, p.apply(lang)),
                    Text(
                      '${p.sourceNote(lang)} · ${s.contentUpdated} ${p.updatedAt}',
                      style: TextStyle(
                        color: ObicColors.mutedOf(context),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(p.officialUrl);
                        if (uri == null) return;
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(p.officialUrl),
                    ),
                  ] else
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: ObicColors.mutedOf(context),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _block(BuildContext context, String label, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC9A227),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              color: ObicColors.inkOf(context),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
