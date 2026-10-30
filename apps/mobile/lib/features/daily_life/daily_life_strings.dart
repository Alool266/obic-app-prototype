// Made by Dr Ali
class DailyLifeStrings {
  DailyLifeStrings(this.langCode);
  final String langCode;

  bool get isAr => langCode.startsWith('ar');
  bool get isZh => langCode.startsWith('zh');

  String _p(String ar, String en, String zh) {
    if (isAr) return ar;
    if (isZh) return zh;
    return en;
  }

  String get title => _p('يومي', 'Daily', '日常');
  String get subtitle =>
      _p('أكل · صحة · مشاوير', 'Food · health · errands', '餐饮 · 健康 · 跑腿');
  String get location => _p('ييوو · الصين', 'Yiwu · China', '义乌 · 中国');
  String get searchHint =>
      _p('ابحث عن مطعم أو صيدلية…', 'Search food or pharmacy…', '搜索餐厅或药店…');
  String get nearby => _p('قريب منك', 'Nearby', '附近');
  String get flash => _p('عروض سريعة', 'Flash deals', '限时优惠');
  String get eta => _p('دقيقة', 'min', '分钟');
  String get fee => _p('رسوم', 'Fee', '配送费');
}
