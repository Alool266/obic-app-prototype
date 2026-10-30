// Made by Dr Ali
// Shared chrome copy for China / Daily / Travel hubs (AR · EN · ZH).

import 'hub_id.dart';

class HubChromeStrings {
  HubChromeStrings(this.langCode, this.hub);
  final String langCode;
  final ObicHubId hub;

  bool get isAr => langCode.startsWith('ar');
  bool get isZh => langCode.startsWith('zh');

  String _p(String ar, String en, [String? zh]) {
    if (isAr) return ar;
    if (isZh) return zh ?? en;
    return en;
  }

  String get settingsTitle => _p('إعدادات المركز', 'Hub settings', '中心设置');
  String get languageFollowsApp =>
      _p('اللغة تتبع التطبيق', 'Language follows app', '语言跟随应用');
  String get distanceUnit => _p('وحدة المسافة', 'Distance unit', '距离单位');
  String get unitKm => _p('كيلومتر', 'Kilometers', '公里');
  String get unitMi => _p('ميل', 'Miles', '英里');
  String get defaultCity => _p('المدينة الافتراضية', 'Default city', '默认城市');
  String get notifyDeals =>
      _p('تنبيهات العروض', 'Deal notifications', '优惠通知');
  String get notifyOrders =>
      _p('تنبيهات الطلبات', 'Order updates', '订单通知');
  String get clearCache => _p('مسح الذاكرة المؤقتة', 'Clear cache', '清除缓存');
  String get cacheCleared => _p('تم المسح', 'Cache cleared', '已清除');
  String get privacyLocation =>
      _p('خصوصية الموقع', 'Location privacy', '位置隐私');
  String get openSystemSettings =>
      _p('فتح إعدادات النظام', 'Open system settings', '打开系统设置');
  String get resetFavorites => _p(
        'إعادة تعيين المفضلة لهذا المركز',
        'Reset favorites for this hub',
        '重置此中心收藏',
      );
  String get resetDone => _p('تمت الإعادة', 'Reset done', '已重置');
  String get dietaryNotes =>
      _p('ملاحظات غذائية (اختياري)', 'Dietary notes (optional)', '饮食备注（可选）');
  String get defaultTraveler =>
      _p('المسافر الافتراضي', 'Default traveler', '默认旅客');
  String get currencyDisplay =>
      _p('عرض العملة', 'Currency display', '货币显示');
  String get save => _p('حفظ', 'Save', '保存');
  String get done => _p('تم', 'Done', '完成');

  String get profileAddresses =>
      _p('العناوين', 'Addresses', '地址');
  String get profileFavorites =>
      _p('المفضلة', 'Favorites', '收藏');
  String get profileRecent =>
      _p('عمليات بحث أخيرة', 'Recent searches', '最近搜索');
  String get profileOrders =>
      _p('سجل الطلبات', 'Order history', '订单记录');
  String get emptyFavorites =>
      _p('لا مفضّلات بعد', 'No favorites yet', '暂无收藏');
  String get emptyRecent =>
      _p('لا عمليات بحث بعد', 'No recent searches', '暂无搜索');
  String get emptyOrders =>
      _p('لا طلبات بعد', 'No orders yet', '暂无订单');

  String get loading => _p('جاري التحميل…', 'Loading…', '加载中…');
  String get offline =>
      _p('أنت غير متصل', 'You are offline', '当前离线');
  String get offlineHint => _p(
        'تحقق من الشبكة ثم أعد المحاولة.',
        'Check your network, then retry.',
        '请检查网络后重试。',
      );
  String get errorTitle => _p('تعذّر التحميل', 'Could not load', '加载失败');
  String get errorHint => _p(
        'حدث خطأ. يمكنك إعادة المحاولة.',
        'Something went wrong. You can retry.',
        '出错了，请重试。',
      );
  String get retry => _p('إعادة المحاولة', 'Retry', '重试');
  String get emptyTitle => _p('لا يوجد شيء هنا', 'Nothing here yet', '这里还没有内容');
  String get emptyHint => _p(
        'جرّب بحثاً آخر أو تصفّح الأقسام.',
        'Try another search or browse categories.',
        '试试其他搜索或浏览分类。',
      );

  String get shareHub => _p('مشاركة المركز', 'Share hub', '分享中心');
  String get sharePlace => _p('مشاركة المكان', 'Share place', '分享地点');
  String get openInMaps => _p('فتح في الخرائط', 'Open in Maps', '在地图中打开');
  String get useGps => _p('موقعي الحالي', 'Use my location', '使用当前位置');
  String get gpsBusy => _p('جاري تحديد الموقع…', 'Locating…', '定位中…');

  String get onboardingSkip => _p('تخطي', 'Skip', '跳过');
  String get onboardingNext => _p('التالي', 'Next', '下一步');
  String get onboardingStart => _p('ابدأ', 'Get started', '开始');

  String get hubTitle {
    switch (hub) {
      case ObicHubId.china:
        return _p('الصين بين يديك', 'China in your hands', '中国尽在掌握');
      case ObicHubId.daily:
        return _p('يومي', 'Daily', '日常');
      case ObicHubId.travel:
        return _p('سفر وسياحة', 'Travel', '旅行');
    }
  }

  List<({String title, String body})> get onboardingPages {
    switch (hub) {
      case ObicHubId.china:
        return [
          (
            title: _p('الصين في جيبك', 'China in your pocket', '中国装进口袋'),
            body: _p(
              'بدن، أعمال، تأشيرات، تعليم وأماكن قريبة — مع GPS حقيقي.',
              'Cities, business, visas, study & nearby places — with real GPS.',
              '城市、商务、签证、留学与附近地点 — 真实定位。',
            ),
          ),
          (
            title: _p('اطلب عبر أوبك', 'Request via OBIC', '通过 OBIC 申请'),
            body: _p(
              'كل خدمة تفتح نموذجاً أو مكتب الدعم. لا محتوى وهمي.',
              'Every service opens a form or the desk. No fake content.',
              '每项服务可开表单或工单。无虚假内容。',
            ),
          ),
        ];
      case ObicHubId.daily:
        return [
          (
            title: _p('حياتك اليومية', 'Your daily life', '你的日常'),
            body: _p(
              'أكل، صيدلية، سوق ومشاوير — توصيل إلى عنوانك.',
              'Food, pharmacy, market & errands — delivered to your address.',
              '美食、药店、超市与跑腿 — 配送到你的地址。',
            ),
          ),
          (
            title: _p('عنوان واحد يكفي', 'One address is enough', '一个地址就够'),
            body: _p(
              'اضغط الموقع الحالي أو اختر من دفتر العناوين.',
              'Tap current location or pick from your address book.',
              '点当前位置或从地址簿选择。',
            ),
          ),
        ];
      case ObicHubId.travel:
        return [
          (
            title: _p('رحلتك مع أوبك', 'Travel with OBIC', '与 OBIC 同行'),
            body: _p(
              'فنادق، طيران، قطارات، معالم وتوصيل مطار — داخل التطبيق.',
              'Hotels, flights, trains, sights & airport transfer — in-app.',
              '酒店、机票、火车、景点与接机 — 应用内完成。',
            ),
          ),
          (
            title: _p('رحلاتي', 'My trips', '我的行程'),
            body: _p(
              'تابع الطلبات القادمة والسابقة من تبويب رحلاتي.',
              'Track upcoming and past requests in My trips.',
              '在「我的行程」查看即将到来与过往申请。',
            ),
          ),
        ];
    }
  }
}
