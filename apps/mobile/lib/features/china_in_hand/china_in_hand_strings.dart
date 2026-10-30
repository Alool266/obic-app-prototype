// Made by Dr Ali
// Strings for «الصين بين يديك».

class ChinaInHandStrings {
  ChinaInHandStrings(this.langCode);
  final String langCode;

  bool get isAr => langCode.startsWith('ar');
  bool get isZh => langCode.startsWith('zh');

  String _pick(String ar, String en, String zh) {
    if (isAr) return ar;
    if (isZh) return zh;
    return en;
  }

  String get title =>
      _pick('الصين بين يديك', 'China in your hands', '中国尽在掌握');

  String get subtitle => _pick(
        'كل ما تحتاجه في الصين — خدمات ومعلومات وأماكن',
        'Everything you need in China — services, guides, places',
        '中国所需一站汇聚 — 服务、指南与地点',
      );

  String get searchHint => _pick(
        'ابحث عن خدمة أو دليل…',
        'Search a service or guide…',
        '搜索服务或指南…',
      );

  String get noResults => _pick('لا نتائج', 'No results', '无结果');

  String get bannerTagline1 => _pick(
        'الصين أقرب… حين تكون أعمالك منظّمة',
        'China closer — when your business is organized',
        '中国更近 — 业务更清晰',
      );

  String get bannerTagline2 => _pick(
        'أعمال · عقارات · تأشيرات · تعليم · توريد · جولات',
        'Business · property · visas · study · sourcing · tours',
        '商务 · 房产 · 签证 · 留学 · 采购 · 旅游',
      );

  String get bannerTagline3 => _pick(
        'من التسجيل إلى المنح والجولات — أوبك معك',
        'From setup to scholarships and tours — OBIC with you',
        '从注册到奖学金与行程 — OBIC陪伴',
      );

  String get sectionServices => _pick('خدمات', 'Services', '服务');
  String get sectionContent =>
      _pick('معلومات وملفات', 'Guides & files', '资料与文件');
  String get sectionPlaces =>
      _pick('أماكن قريبة', 'Nearby places', '附近地点');

  String get categoryServicesHint => _pick(
        'اضغط خدمة لفتح طلب Obic مباشرة',
        'Tap a service to open an Obic request',
        '点选服务即可直接发起 Obic 申请',
      );

  String categoryServicesCount(int n) => _pick(
        '$n خدمة',
        '$n services',
        '$n 项服务',
      );

  String categoryBlurb(String id) {
    switch (id) {
      case 'business':
        return _pick(
          'تسجيل، استشارات، علامات، محاسبة وضرائب — مع أدلة عملية.',
          'Setup, consulting, trademarks, accounting & tax — plus practical guides.',
          '注册、咨询、商标、财税 — 另附实用指南。',
        );
      case 'property':
        return _pick(
          'مكاتب وعقارات وإيجار/شراء عبر نماذج استعلام Obic.',
          'Offices and property buy/rent via Obic inquiry forms.',
          '写字楼与房产租购 — 通过 Obic 询价表单。',
        );
      case 'visa-docs':
        return _pick(
          'فيزا، إقامة، ترجمة وتوثيق — مع أدلة وثائق عامة.',
          'Visas, residence, translation & attestation — plus document guides.',
          '签证、居留、翻译公证 — 另附文件指南。',
        );
      case 'education':
        return _pick(
          'لغة وجامعات ومنح دراسية حقيقية (CSC وغيرها) — بدون قبول وهمي.',
          'Language, universities, real scholarships (CSC etc.) — no fake admits.',
          '语言、高校与真实奖学金（CSC等）— 无虚假录取。',
        );
      case 'sourcing-logistics':
        return _pick(
          'توريد وفحص وحاسبة استيراد ولوجستيات Obic.',
          'Sourcing, QC, import calculator & Obic logistics.',
          '采购、质检、进口测算与 Obic 物流。',
        );
      case 'stay-tour':
        return _pick(
          'فنادق وجولات ومعالم — وزيارة قريبة حسب موقعك أو المدينة.',
          'Hotels, tours, landmarks — visit near you by GPS or city.',
          '酒店、行程与景点 — 按定位或城市查看附近。',
        );
      default:
        return subtitle;
    }
  }

  // —— City ——
  String get cityPickerTitle =>
      _pick('اختر مدينة', 'Choose a city', '选择城市');
  String get cityPickerHint => _pick(
        'ابحث بالعربية أو الصينية أو Pinyin…',
        'Search Arabic, Chinese, or Pinyin…',
        '搜索中文、拼音或阿拉伯语…',
      );
  String get cityLabel => _pick('المدينة', 'City', '城市');
  String get cityUseGps => _pick(
        'استخدم موقعي الحالي',
        'Use my current location',
        '使用我的当前位置',
      );

  // —— Content ——
  String get contentUpdated =>
      _pick('آخر تحديث', 'Last updated', '最近更新');
  String get contentObicFooter => _pick(
        '© Obic — معلومات عامة. ليست استشارة قانونية ولا ضمان قبول.',
        '© Obic — general info. Not legal advice and no admission guarantee.',
        '© Obic — 一般信息。非法律意见，不保证录取。',
      );

  // —— Scholarships ——
  String get scholarshipsTitle =>
      _pick('منح دراسية', 'Scholarships', '奖学金');

  String get scholarshipsDisclaimerTitle => _pick(
        'إرشاد عام — بدون قبول وهمي',
        'Guidance only — no fake admits',
        '仅作公开指引 — 无虚假录取',
      );

  String get scholarshipsDisclaimerBody => _pick(
        'المعلومات من برامج CSC والجامعات المعلنة علناً. المواعيد تتغير كل عام. Obic يساعد في تجهيز الملف؛ القبول النهائي من الجامعة أو CSC فقط.',
        'Info from publicly announced CSC and university programs. Deadlines change yearly. OBIC helps prepare files; final admission is university/CSC only.',
        '内容来自CSC与高校公开项目。截止日期每年可能变化。OBIC协助材料；最终录取仅由院校或CSC决定。',
      );

  String get scholarshipsCta => _pick(
        'اطلب مساعدة Obic للمنح',
        'Request Obic scholarship help',
        '申请 Obic 奖学金协助',
      );

  String get scholarshipsProgramsHeading => _pick(
        'برامج معلنة (عامة)',
        'Published programs (public)',
        '公开项目',
      );

  String get scholarshipsEligibility =>
      _pick('الأهلية', 'Eligibility', '申请条件');
  String get scholarshipsCoverage =>
      _pick('التغطية', 'Coverage', '资助范围');
  String get scholarshipsDeadline =>
      _pick('المواعيد', 'Deadlines', '截止日期');
  String get scholarshipsHowToApply =>
      _pick('كيف تقدّم', 'How to apply', '如何申请');
  String get scholarshipsKindCsc => _pick('CSC', 'CSC', 'CSC');
  String get scholarshipsKindUni =>
      _pick('جامعة', 'University', '高校');
  String get scholarshipsKindLang =>
      _pick('لغة', 'Language', '语言');

  // —— Visit ——
  String get visitTitle =>
      _pick('زيارة قريبة منك', 'Visit near you', '附近可访');
  String get visitBannerTitle => _pick(
        'زيارة حسب موقعك',
        'Visit by your location',
        '按定位可访',
      );
  String get visitBannerSubtitle => _pick(
        'مساجد · أسواق · معالم — اختر مدينة في كل الصين',
        'Mosques · markets · landmarks — pick any China city',
        '清真寺 · 市场 · 景点 — 可选全国城市',
      );
  String get visitSeeAll => _pick('عرض الكل', 'See all', '查看全部');
  String get visitRefresh => _pick('تحديث الموقع', 'Refresh location', '刷新定位');
  String get visitGpsOff => _pick(
        'فعّل خدمات الموقع أو اختر مدينة',
        'Turn on location or pick a city',
        '请开启定位或选择城市',
      );
  String get visitGpsDenied => _pick(
        'إذن الموقع مرفوض — اختر مدينة من القائمة',
        'Location denied — pick a city from the list',
        '定位被拒绝 — 请从列表选择城市',
      );
  String get visitGpsFail => _pick(
        'تعذّر الموقع — اختر مدينة',
        'Could not get location — pick a city',
        '无法定位 — 请选择城市',
      );
  String get visitRetry => _pick('إعادة المحاولة', 'Try again', '重试');
  String get visitFarFromChina => _pick(
        'يبدو أنك بعيداً عن الصين — اختر مدينة',
        'You seem far from China — pick a city',
        '当前位置远离中国 — 请选择城市',
      );
  String get visitEmptyNear => _pick(
        'لا أماكن قريبة ضمن النطاق',
        'No places within range',
        '范围内暂无地点',
      );
  String get visitEmptyHint => _pick(
        'اختر مدينة أو اطلب مرشداً.',
        'Pick a city or request a guide.',
        '请选择城市或申请导游。',
      );
  String get visitPickCityHint => _pick(
        'اختر مدينة لعرض المساجد والأسواق والمعالم.',
        'Pick a city to see mosques, markets, and landmarks.',
        '选择城市以查看清真寺、市场与景点。',
      );
  String get visitCityEmptySoon => _pick(
        'لا أماكن منسّقة بعد لهذه المدينة — قريباً. يمكنك فتح الخرائط أو اذهب مع Obic.',
        'No curated places for this city yet — coming soon. You can open maps or Go with Obic.',
        '该市暂无精选地点 — 即将完善。可打开地图或跟 Obic 走。',
      );

  String visitNearCount(int n) => _pick(
        '$n مكاناً قريباً (حتى $kVisitNearKmLabel كم)',
        '$n places nearby (within $kVisitNearKmLabel km)',
        '附近 $n 处（$kVisitNearKmLabel 公里内）',
      );

  static const kVisitNearKmLabel = '120';

  String get visitKindMosque => _pick('مسجد', 'Mosque', '清真寺');
  String get visitKindMarket => _pick('سوق', 'Market', '市场');
  String get visitKindPlace => _pick('مكان', 'Place', '景点');
  String get visitOpenObicMap =>
      _pick('خريطة Obic', 'Obic map', 'Obic 地图');
  String get visitOpenNativeMaps =>
      _pick('تطبيق الخرائط', 'Native maps', '打开地图App');
  String get visitGoWithObic =>
      _pick('اذهب مع Obic', 'Go with Obic', '跟 Obic 走');
}
