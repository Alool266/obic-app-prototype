// Made by Dr Ali
// Place detail — photo, pin, map / native / اذهب مع Obic.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_back_button.dart';
import '../../widgets/obic_cached_image.dart';
import '../auth/auth_controller.dart';
import '../messages/chat_location_body.dart';
import 'china_in_hand_strings.dart';
import 'china_tile_nav.dart';
import 'china_visit_places.dart';

class ChinaPlaceDetailPage extends StatelessWidget {
  const ChinaPlaceDetailPage({
    super.key,
    required this.authController,
    required this.langCode,
    required this.place,
    this.distanceKm,
  });

  final AuthController authController;
  final String langCode;
  final ChinaVisitPlace place;
  final double? distanceKm;

  void _openObicMap(BuildContext context) {
    final name = place.name(langCode);
    showLocationMapSheet(
      context,
      ParsedLocationShare(
        label: name,
        lat: place.lat,
        lng: place.lng,
        preferChina: true,
        links: [
          MapLinkRow(
            label: langCode.startsWith('zh') ? '高德地图' : 'Amap',
            url: amapMarkerUrl(lat: place.lat, lng: place.lng, name: name),
          ),
          MapLinkRow(
            label: 'Apple Maps',
            url: appleMapsUrl(lat: place.lat, lng: place.lng, name: name),
          ),
          MapLinkRow(
            label: 'Google Maps',
            url: googleMapsUrl(lat: place.lat, lng: place.lng),
          ),
        ],
      ),
    );
  }

  Future<void> _openNative() async {
    final name = place.name(langCode);
    // Prefer Amap on Chinese UI; Apple Maps on iOS otherwise; Google last.
    final urls = <String>[
      if (langCode.startsWith('zh'))
        amapMarkerUrl(lat: place.lat, lng: place.lng, name: name),
      appleMapsUrl(lat: place.lat, lng: place.lng, name: name),
      googleMapsUrl(lat: place.lat, lng: place.lng),
      if (!langCode.startsWith('zh'))
        amapMarkerUrl(lat: place.lat, lng: place.lng, name: name),
    ];
    for (final url in urls) {
      if (await openMapUrl(url)) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ChinaInHandStrings(langCode);
    final img = place.imageAsset ?? 'assets/china/shanghai.jpg';
    final tips = place.tips(langCode);

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
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
                        colors: [Color(0x44071628), Color(0xEE071628)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 18,
                    child: Text(
                      place.name(langCode),
                      style: const TextStyle(
                        color: Color(0xFFF8F5EE),
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.2,
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
                if (distanceKm != null)
                  Text(
                    '${distanceKm! < 10 ? distanceKm!.toStringAsFixed(1) : distanceKm!.toStringAsFixed(0)} km',
                    style: const TextStyle(
                      color: Color(0xFFC9A227),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  place.blurb(langCode),
                  style: TextStyle(
                    color: ObicColors.inkOf(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                if (tips != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    tips,
                    style: TextStyle(
                      color: ObicColors.mutedOf(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  place.sourceNote,
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                _btn(
                  filled: false,
                  icon: Icons.map_rounded,
                  label: s.visitOpenObicMap,
                  onTap: () => _openObicMap(context),
                ),
                const SizedBox(height: 10),
                _btn(
                  filled: false,
                  icon: Icons.open_in_new_rounded,
                  label: s.visitOpenNativeMaps,
                  onTap: _openNative,
                ),
                const SizedBox(height: 10),
                _btn(
                  filled: true,
                  icon: Icons.directions_walk_rounded,
                  label: s.visitGoWithObic,
                  onTap: () => openChinaSubById(
                    context: context,
                    authController: authController,
                    langCode: langCode,
                    parentSlug: 'travel',
                    subId: 'guide',
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required bool filled,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor:
              filled ? const Color(0xFFC9A227) : ObicColors.navy,
          foregroundColor:
              filled ? ObicColors.navy : const Color(0xFFF8F5EE),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
