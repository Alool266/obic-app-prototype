// Made by Dr Ali
// Bundled China photos for hub carousel + Discover cards (no broken CDN URLs).

/// Full-bleed hub carousel + Discover photo cards.
/// Paths under `assets/` load offline via [ObicCachedImage].
abstract final class ChinaMedia {
  static const shanghai = 'assets/china/shanghai.jpg';
  static const expoHall = 'assets/china/expo-hall.jpg';
  static const businessSkyline = 'assets/china/business-skyline.jpg';
  static const nightCity = 'assets/china/night-city.jpg';
  static const convention = 'assets/china/convention.jpg';

  /// Fallback when a network cover fails (Discover / hub).
  static const fallbackCover = shanghai;

  static const hubCarousel = <String>[
    shanghai,
    expoHall,
    businessSkyline,
    nightCity,
  ];

  /// Discover «الصين بين يديك» card / shortcut.
  static const discoverChinaInHand = shanghai;

  /// Discover «معارض الصين» card / shortcut.
  static const discoverExhibitions = expoHall;

  /// Category hero / card imagery (bundled, offline).
  static String categoryHero(String categoryId) {
    switch (categoryId) {
      case 'business':
        return businessSkyline;
      case 'property':
        return nightCity;
      case 'visa-docs':
        return convention;
      case 'education':
        return shanghai;
      case 'sourcing-logistics':
        return expoHall;
      case 'stay-tour':
        return 'assets/travel/landmark.jpg';
      default:
        return shanghai;
    }
  }
}
