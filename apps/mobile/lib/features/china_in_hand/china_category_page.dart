// Made by Dr Ali
// Category hub: hero + خدمات + معلومات وملفات + أماكن (tourism).

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_back_button.dart';
import '../../widgets/obic_cached_image.dart';
import '../../widgets/obic_soft_motion.dart';
import '../auth/auth_controller.dart';
import 'china_content.dart';
import 'china_content_page.dart';
import 'china_in_hand_catalog.dart';
import 'china_in_hand_icons.dart';
import 'china_in_hand_strings.dart';
import 'china_media.dart';
import 'china_scholarships_page.dart';
import 'china_tile_nav.dart';
import 'china_visit_banner.dart';

class ChinaCategoryPage extends StatelessWidget {
  const ChinaCategoryPage({
    super.key,
    required this.authController,
    required this.langCode,
    required this.section,
  });

  final AuthController authController;
  final String langCode;
  final ChinaHubSection section;

  @override
  Widget build(BuildContext context) {
    final s = ChinaInHandStrings(langCode);
    final dark = ObicColors.isDark(context);
    final cat = chinaCategoryVisual(section.id);
    final hero = ChinaMedia.categoryHero(section.id);
    final content = chinaContentForCategory(section.id);
    final showPlaces = section.id == 'stay-tour';
    final showScholarshipsCta = section.id == 'education';

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: ObicColors.navy,
            leading: const ObicBackButton(),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                end: 16,
                bottom: 14,
              ),
              title: Text(
                section.title(langCode),
                style: const TextStyle(
                  color: Color(0xFFF8F5EE),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ObicCachedImage(hero, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ObicColors.navy.withValues(alpha: 0.55),
                          Color.lerp(ObicColors.navy, cat.ink, 0.25)!
                              .withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.bottomEnd,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Icon(
                        cat.icon,
                        size: 72,
                        color: const Color(0xFFC9A227).withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ContainedSliver(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                s.categoryBlurb(section.id),
                style: TextStyle(
                  color: ObicColors.mutedOf(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (showScholarshipsCta)
            ContainedSliver(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A227),
                    foregroundColor: ObicColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChinaScholarshipsPage(
                          authController: authController,
                          langCode: langCode,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.school_rounded),
                  label: Text(
                    s.scholarshipsTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          if (showPlaces)
            ContainedSliver(
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SectionLabel(text: s.sectionPlaces),
                    ),
                    const SizedBox(height: 10),
                    ChinaVisitBanner(
                      authController: authController,
                      langCode: langCode,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ContainedSliver(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
              child: _SectionLabel(text: s.sectionServices),
            ),
          ),
          ContainedSliver(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                s.categoryServicesHint,
                style: TextStyle(
                  color: ObicColors.mutedOf(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          ContainedSliver(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  for (var i = 0; i < section.tiles.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    ObicSlideIn(
                      index: i,
                      child: _ServiceTile(
                        tile: section.tiles[i],
                        langCode: langCode,
                        dark: dark,
                        onTap: () => openChinaHubTile(
                          context: context,
                          authController: authController,
                          langCode: langCode,
                          tile: section.tiles[i],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (content.isNotEmpty) ...[
            ContainedSliver(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                child: _SectionLabel(text: s.sectionContent),
              ),
            ),
            ContainedSliver(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: Column(
                  children: [
                    for (var i = 0; i < content.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      ObicSlideIn(
                        index: i,
                        child: _ContentCard(
                          item: content[i],
                          langCode: langCode,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ChinaContentPage(
                                  authController: authController,
                                  langCode: langCode,
                                  item: content[i],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else
            const ContainedSliver(child: SizedBox(height: 40)),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFC9A227),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: ObicColors.titleOf(context),
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.tile,
    required this.langCode,
    required this.dark,
    required this.onTap,
  });

  final ChinaHubTile tile;
  final String langCode;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = chinaHubVisual(tile.id);
    return Material(
      color: ObicColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      visual.soft,
                      visual.soft.withValues(alpha: dark ? 0.5 : 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: visual.ink.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(visual.icon, color: visual.ink, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  tile.label(langCode),
                  style: TextStyle(
                    color: ObicColors.inkOf(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ObicColors.mutedOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.item,
    required this.langCode,
    required this.onTap,
  });

  final ChinaContentItem item;
  final String langCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final img = item.imageAsset ?? ChinaMedia.shanghai;
    return Material(
      color: ObicColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: ObicCachedImage(img, fit: BoxFit.cover),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title(langCode),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ObicColors.inkOf(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.summary(langCode),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ObicColors.mutedOf(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
