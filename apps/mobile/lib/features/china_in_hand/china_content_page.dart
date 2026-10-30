// Made by Dr Ali
// In-app guide / checklist viewer with Obic branding + Order CTA.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_back_button.dart';
import '../../widgets/obic_cached_image.dart';
import '../auth/auth_controller.dart';
import 'china_content.dart';
import 'china_in_hand_strings.dart';
import 'china_tile_nav.dart';

class ChinaContentPage extends StatelessWidget {
  const ChinaContentPage({
    super.key,
    required this.authController,
    required this.langCode,
    required this.item,
  });

  final AuthController authController;
  final String langCode;
  final ChinaContentItem item;

  @override
  Widget build(BuildContext context) {
    final s = ChinaInHandStrings(langCode);
    final img = item.imageAsset ?? 'assets/china/shanghai.jpg';

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
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ObicCachedImage(img, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66071628), Color(0xE6071628)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Text(
                      item.title(langCode),
                      style: const TextStyle(
                        color: Color(0xFFF8F5EE),
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  '${s.contentUpdated}: ${item.updatedAt}',
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.summary(langCode),
                  style: TextStyle(
                    color: const Color(0xFFC9A227),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ObicColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFC9A227).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    item.body(langCode),
                    style: TextStyle(
                      color: ObicColors.inkOf(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.contentObicFooter,
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.ctaSubId != null && item.ctaParentSlug != null) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A227),
                      foregroundColor: ObicColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => openChinaSubById(
                      context: context,
                      authController: authController,
                      langCode: langCode,
                      parentSlug: item.ctaParentSlug!,
                      subId: item.ctaSubId!,
                    ),
                    icon: const Icon(Icons.support_agent_rounded),
                    label: Text(
                      item.ctaLabel(langCode) ?? s.scholarshipsCta,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
