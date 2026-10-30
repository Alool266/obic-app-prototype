// Made by Dr Ali
// Shared identifiers for الصين / يومي / سفر hubs.

enum ObicHubId {
  china,
  daily,
  travel;

  String get prefsKey {
    switch (this) {
      case ObicHubId.china:
        return 'china';
      case ObicHubId.daily:
        return 'daily';
      case ObicHubId.travel:
        return 'travel';
    }
  }

  /// Home mega-icon slug when this hub has one (China only today).
  String? get homeFavoriteSlug {
    switch (this) {
      case ObicHubId.china:
        return 'china-in-hand';
      case ObicHubId.daily:
      case ObicHubId.travel:
        return null;
    }
  }

  String sharePath() {
    switch (this) {
      case ObicHubId.china:
        return 'china';
      case ObicHubId.daily:
        return 'daily';
      case ObicHubId.travel:
        return 'travel';
    }
  }
}
