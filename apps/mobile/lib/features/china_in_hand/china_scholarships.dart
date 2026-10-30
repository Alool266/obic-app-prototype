// Made by Dr Ali
// Public CSC / university scholarship programs (guidance only — no fake admits).

enum ScholarshipKind { csc, university, language }

class ChinaScholarshipProgram {
  const ChinaScholarshipProgram({
    required this.id,
    required this.kind,
    required this.titleAr,
    required this.titleEn,
    required this.titleZh,
    required this.hostAr,
    required this.hostEn,
    required this.hostZh,
    required this.eligibilityAr,
    required this.eligibilityEn,
    required this.eligibilityZh,
    required this.coverageAr,
    required this.coverageEn,
    required this.coverageZh,
    required this.deadlineAr,
    required this.deadlineEn,
    required this.deadlineZh,
    required this.applyAr,
    required this.applyEn,
    required this.applyZh,
    required this.sourceNoteAr,
    required this.sourceNoteEn,
    required this.sourceNoteZh,
    required this.officialUrl,
    required this.updatedAt,
    this.imageAsset = 'assets/china/shanghai.jpg',
  });

  final String id;
  final ScholarshipKind kind;
  final String titleAr;
  final String titleEn;
  final String titleZh;
  final String hostAr;
  final String hostEn;
  final String hostZh;
  final String eligibilityAr;
  final String eligibilityEn;
  final String eligibilityZh;
  final String coverageAr;
  final String coverageEn;
  final String coverageZh;
  final String deadlineAr;
  final String deadlineEn;
  final String deadlineZh;
  final String applyAr;
  final String applyEn;
  final String applyZh;
  final String sourceNoteAr;
  final String sourceNoteEn;
  final String sourceNoteZh;
  final String officialUrl;
  final String updatedAt;
  final String imageAsset;

  String title(String lang) => _pick(lang, titleAr, titleEn, titleZh);
  String host(String lang) => _pick(lang, hostAr, hostEn, hostZh);
  String eligibility(String lang) =>
      _pick(lang, eligibilityAr, eligibilityEn, eligibilityZh);
  String coverage(String lang) =>
      _pick(lang, coverageAr, coverageEn, coverageZh);
  String deadline(String lang) =>
      _pick(lang, deadlineAr, deadlineEn, deadlineZh);
  String apply(String lang) => _pick(lang, applyAr, applyEn, applyZh);
  String sourceNote(String lang) =>
      _pick(lang, sourceNoteAr, sourceNoteEn, sourceNoteZh);

  static String _pick(String lang, String ar, String en, String zh) {
    if (lang.startsWith('ar')) return ar;
    if (lang.startsWith('zh')) return zh;
    return en;
  }
}

const kChinaScholarshipUpdated = '2026-10-27';

/// Curated from publicly announced CSC / university international routes.
const kChinaScholarshipPrograms = <ChinaScholarshipProgram>[
  ChinaScholarshipProgram(
    id: 'csc-bilateral',
    kind: ScholarshipKind.csc,
    titleAr: 'منحة الحكومة الصينية (CSC) — مسار السفارة',
    titleEn: 'Chinese Government Scholarship (CSC) — Bilateral',
    titleZh: '中国政府奖学金（CSC）— 双边/使馆渠道',
    hostAr: 'China Scholarship Council · عبر سفارة الصين',
    hostEn: 'China Scholarship Council · via Chinese embassy',
    hostZh: '国家留学基金管理委员会 · 经驻外使领馆',
    eligibilityAr:
        'جنسية غير صينية؛ مؤهل مطابق للمرحلة؛ عمر وصحة حسب دليل CSC السنوي؛ غالباً ترشيح جهتك الوطنية.',
    eligibilityEn:
        'Non-Chinese; matching degree level; age/health per yearly CSC guide; usually national nomination.',
    eligibilityZh: '非中国籍；学历匹配；年龄健康按当年CSC指南；通常经本国推荐。',
    coverageAr:
        'غالباً: إعفاء رسوم دراسية + سكن جامعي أو بدل + راتب شهري حسب المستوى (كما يعلن CSC سنوياً).',
    coverageEn:
        'Typically: tuition waiver + dorm or stipend + monthly living allowance by level (per yearly CSC notice).',
    coverageZh: '通常：免学费 + 住宿或补贴 + 按层次生活费（以当年CSC通知为准）。',
    deadlineAr: 'عادةً نوفمبر–مارس/أبريل حسب السفارة (يتغير سنوياً).',
    deadlineEn: 'Typically Nov–Mar/Apr by embassy (changes yearly).',
    deadlineZh: '通常11月至翌年3/4月，视使馆（每年可能调整）。',
    applyAr:
        'راجع إعلان السفارة → سجّل على studyinchina.csc.edu.cn (Bilateral) → جهّز جواز/شهادات/خطة/HSK/توصيات → قدّم للسفارة.',
    applyEn:
        'Read embassy call → register on studyinchina.csc.edu.cn (Bilateral) → prepare passport/transcripts/plan/HSK/recs → submit to embassy.',
    applyZh: '查看使馆通知 → 在 studyinchina.csc.edu.cn 注册双边 → 准备材料 → 递交使馆。',
    sourceNoteAr: 'مصدر عام: studyinchina.csc.edu.cn',
    sourceNoteEn: 'Public source: studyinchina.csc.edu.cn',
    sourceNoteZh: '公开来源：studyinchina.csc.edu.cn',
    officialUrl: 'https://www.campuschina.org/',
    updatedAt: kChinaScholarshipUpdated,
    imageAsset: 'assets/china/shanghai.jpg',
  ),
  ChinaScholarshipProgram(
    id: 'csc-university',
    kind: ScholarshipKind.csc,
    titleAr: 'منحة CSC عبر الجامعة',
    titleEn: 'CSC Chinese University Program',
    titleZh: '中国政府奖学金—高校自主招生项目',
    hostAr: 'جامعات صينية مشاركة + CSC',
    hostEn: 'Participating Chinese universities + CSC',
    hostZh: '中国高校 + 国家留学基金委',
    eligibilityAr: 'غير صيني؛ تقدّم مباشر للجامعة المدرجة؛ لغة وتخصص حسب الكلية.',
    eligibilityEn: 'Non-Chinese; apply to listed university; language/major per faculty.',
    eligibilityZh: '非中国籍；向CSC高校项目院校申请；语言专业由院系定。',
    coverageAr: 'مشابه لمسار CSC الكامل أو جزئي حسب إعلان الجامعة.',
    coverageEn: 'Full or partial CSC-style coverage per university notice.',
    coverageZh: '全额或部分资助视院校通知。',
    deadlineAr: 'غالباً ديسمبر–أبريل.',
    deadlineEn: 'Often Dec–Apr.',
    deadlineZh: '多为12月至4月。',
    applyAr:
        'بوابة الجامعة + رقم CSC → انتظار pre-admission ثم مراجعة الصندوق.',
    applyEn: 'University portal + CSC number → pre-admission then CSC review.',
    applyZh: '院校门户 + CSC申请号 → 预录取后基金委审核。',
    sourceNoteAr: 'دليل CSC + صفحات المنح الدولية للجامعات',
    sourceNoteEn: 'CSC guide + university international scholarship pages',
    sourceNoteZh: 'CSC指南 + 各校国际奖学金页',
    officialUrl: 'https://www.campuschina.org/',
    updatedAt: kChinaScholarshipUpdated,
    imageAsset: 'assets/china/convention.jpg',
  ),
  ChinaScholarshipProgram(
    id: 'cis-language',
    kind: ScholarshipKind.language,
    titleAr: 'منحة معلّمي اللغة الصينية الدولية (CIS)',
    titleEn: 'International Chinese Language Teachers Scholarship (CIS)',
    titleZh: '国际中文教师奖学金',
    hostAr: 'مركز اللغة الصينية / جامعات مستضيفة',
    hostEn: 'CLEC · host universities',
    hostZh: '中外语言交流合作中心 · 接收院校',
    eligibilityAr: 'غير صيني؛ HSK/HSKK حسب نوع المنحة.',
    eligibilityEn: 'Non-Chinese; HSK/HSKK by award type.',
    eligibilityZh: '非中国籍；HSK/HSKK按奖项类型。',
    coverageAr: 'رسوم دراسة لغة + بدل معيشة حسب نوع المنحة المعلن.',
    coverageEn: 'Language tuition + living stipend per published award type.',
    coverageZh: '汉语学习费用 + 生活补助按公开奖项类型。',
    deadlineAr: 'دورات متعددة — cis.chinese.cn',
    deadlineEn: 'Multiple rounds — cis.chinese.cn',
    deadlineZh: '一年多轮 — cis.chinese.cn',
    applyAr: 'حساب على cis.chinese.cn → جامعة ونوع → جواز وHSK وتوصيات.',
    applyEn: 'Account on cis.chinese.cn → pick host/type → passport, HSK, recs.',
    applyZh: '在 cis.chinese.cn 注册 → 选择院校类型 → 上传材料。',
    sourceNoteAr: 'بوابة: cis.chinese.cn',
    sourceNoteEn: 'Portal: cis.chinese.cn',
    sourceNoteZh: '门户：cis.chinese.cn',
    officialUrl: 'https://cis.chinese.cn/',
    updatedAt: kChinaScholarshipUpdated,
    imageAsset: 'assets/china/expo-hall.jpg',
  ),
  ChinaScholarshipProgram(
    id: 'zju-intl',
    kind: ScholarshipKind.university,
    titleAr: 'منح Zhejiang University الدولية',
    titleEn: 'Zhejiang University international scholarships',
    titleZh: '浙江大学国际学生奖学金',
    hostAr: 'Zhejiang University (Hangzhou)',
    hostEn: 'Zhejiang University (Hangzhou)',
    hostZh: '浙江大学（杭州）',
    eligibilityAr: 'طلاب دوليون حسب إعلان ZJU السنوي.',
    eligibilityEn: 'International students per yearly ZJU notice.',
    eligibilityZh: '按浙大当年国际生通知。',
    coverageAr: 'جزئي أو كامل حسب نوع المنحة الجامعية المعلن.',
    coverageEn: 'Partial or full per published university award.',
    coverageZh: '校级奖学金额度以公开通知为准。',
    deadlineAr: 'غالباً ربيع — isee.zju.edu.cn',
    deadlineEn: 'Usually spring — isee.zju.edu.cn',
    deadlineZh: '多为春季 — isee.zju.edu.cn',
    applyAr: 'قبول ZJU ثم طلب المنحة/CSC إن فُتح.',
    applyEn: 'ZJU admission then scholarship/CSC if open.',
    applyZh: '先申请浙大录取，再按通知提交奖学金。',
    sourceNoteAr: 'قبول ZJU الدولي العام',
    sourceNoteEn: 'ZJU public international admissions',
    sourceNoteZh: '浙大国际招生公开页',
    officialUrl: 'https://www.zju.edu.cn/',
    updatedAt: kChinaScholarshipUpdated,
    imageAsset: 'assets/travel/landmark.jpg',
  ),
  ChinaScholarshipProgram(
    id: 'thu-pku',
    kind: ScholarshipKind.university,
    titleAr: 'منح Tsinghua / Peking University',
    titleEn: 'Tsinghua / Peking University tracks',
    titleZh: '清华 / 北京大学奖学金通道',
    hostAr: 'Tsinghua · Peking University (Beijing)',
    hostEn: 'Tsinghua · Peking University (Beijing)',
    hostZh: '清华大学 · 北京大学（北京）',
    eligibilityAr: 'درجة مطابقة؛ لغة حسب البرنامج؛ لا ضمان قبول.',
    eligibilityEn: 'Matching degree; language per program; no admit guarantee.',
    eligibilityZh: '学历匹配；语言按项目；不保证录取。',
    coverageAr: 'حسب إعلان كل كلية (CSC أو منحة جامعية).',
    coverageEn: 'Per school notice (CSC or university award).',
    coverageZh: '按各院系通知（CSC或校奖）。',
    deadlineAr: 'غالباً ديسمبر–مارس.',
    deadlineEn: 'Often Dec–Mar.',
    deadlineZh: '多为12–3月。',
    applyAr: 'بوابة القبول الدولي فقط — لا وسطاء غير رسميين.',
    applyEn: 'Official international portals only — no unofficial brokers.',
    applyZh: '仅官方国际招生门户 — 勿信非官方中介。',
    sourceNoteAr: 'international.tsinghua.edu.cn · isd.pku.edu.cn',
    sourceNoteEn: 'international.tsinghua.edu.cn · isd.pku.edu.cn',
    sourceNoteZh: 'international.tsinghua.edu.cn · isd.pku.edu.cn',
    officialUrl: 'https://international.tsinghua.edu.cn/',
    updatedAt: kChinaScholarshipUpdated,
    imageAsset: 'assets/china/night-city.jpg',
  ),
  ChinaScholarshipProgram(
    id: 'ynnu-yiwu-region',
    kind: ScholarshipKind.university,
    titleAr: 'جامعات Zhejiang / منطقة ييوو',
    titleEn: 'Zhejiang / Yiwu-area universities',
    titleZh: '浙江 / 义乌周边高校',
    hostAr: 'جامعات المقاطعة (إعلانات عامة)',
    hostEn: 'Provincial hosts (public notices)',
    hostZh: '省内高校（公开通知）',
    eligibilityAr: 'دوليون حسب كل إعلان؛ لغة أو بكالوريوس.',
    eligibilityEn: 'International per each notice; language or bachelor tracks.',
    eligibilityZh: '按各校通知；汉语或本科学历路径。',
    coverageAr: 'متفاوت — رسوم أو سكن أو جزئي حسب الإعلان.',
    coverageEn: 'Varies — tuition/housing/partial per notice.',
    coverageZh: '不等 — 学费/住宿/部分资助视通知。',
    deadlineAr: 'قبل كل فصل — راقب مواقع القبول.',
    deadlineEn: 'Before each term — watch admissions sites.',
    deadlineZh: '每学期前关注国际招生页。',
    applyAr: 'Obic يجهّز الملف؛ القبول من الجامعة فقط.',
    applyEn: 'Obic prepares the file; admission is university-only.',
    applyZh: 'Obic协助材料；录取权在院校。',
    sourceNoteAr: 'إعلانات قبول Zhejiang العامة',
    sourceNoteEn: 'Public Zhejiang international admissions notices',
    sourceNoteZh: '浙江省高校国际招生公开通知',
    officialUrl: 'https://www.zjnu.edu.cn/',
    updatedAt: kChinaScholarshipUpdated,
    imageAsset: 'assets/china/business-skyline.jpg',
  ),
];
