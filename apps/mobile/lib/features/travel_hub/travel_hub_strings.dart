// Made by Dr Ali
class TravelHubStrings {
  TravelHubStrings(this.langCode);
  final String langCode;

  bool get isAr => langCode.startsWith('ar');
  bool get isZh => langCode.startsWith('zh');

  String _p(String ar, String en, String zh) {
    if (isAr) return ar;
    if (isZh) return zh;
    return en;
  }

  String get title => _p('سفر وسياحة', 'Travel', '旅行');
  String get subtitle =>
      _p('فنادق · طيران · سياحة', 'Hotels · flights · tours', '酒店 · 机票 · 旅游');
  String get searchHint => _p(
        'ابحث عن فندق أو وجهة…',
        'Search hotels or destinations…',
        '搜索酒店或目的地…',
      );
  String get cities => _p('مدن شائعة', 'Popular cities', '热门城市');
  String get promos => _p('عروض السفر', 'Travel deals', '旅行优惠');
  String get aiTrip => _p('رحلة بالذكاء', 'AI trip planner', 'AI行程规划');
  String get aiTripBody => _p(
        'صف رحلتك وسنرتب فنادق وطيران وجولات.',
        'Describe your trip — hotels, flights, tours.',
        '描述行程，我们安排酒店、机票与行程。',
      );
  String get aiCta => _p('ابدأ التخطيط', 'Start planning', '开始规划');
  String get more => _p('المزيد', 'More', '更多');
  String get topCats => _p('الأقسام الرئيسية', 'Top categories', '热门分类');
}
