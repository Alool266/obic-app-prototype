// Made by Dr Ali
// Guides / checklists / FAQs for الصين بين يديك (public info; dated).

enum ChinaContentKind { guide, checklist, faq, glossary, pack }

class ChinaContentItem {
  const ChinaContentItem({
    required this.id,
    required this.categoryIds,
    required this.kind,
    required this.titleAr,
    required this.titleEn,
    required this.titleZh,
    required this.summaryAr,
    required this.summaryEn,
    required this.summaryZh,
    required this.bodyAr,
    required this.bodyEn,
    required this.bodyZh,
    required this.updatedAt,
    this.imageAsset,
    this.ctaSubId,
    this.ctaParentSlug,
    this.ctaLabelAr,
    this.ctaLabelEn,
    this.ctaLabelZh,
  });

  final String id;
  final List<String> categoryIds;
  final ChinaContentKind kind;
  final String titleAr;
  final String titleEn;
  final String titleZh;
  final String summaryAr;
  final String summaryEn;
  final String summaryZh;
  final String bodyAr;
  final String bodyEn;
  final String bodyZh;
  final String updatedAt;
  final String? imageAsset;
  final String? ctaSubId;
  final String? ctaParentSlug;
  final String? ctaLabelAr;
  final String? ctaLabelEn;
  final String? ctaLabelZh;

  String title(String lang) => _p(lang, titleAr, titleEn, titleZh);
  String summary(String lang) => _p(lang, summaryAr, summaryEn, summaryZh);
  String body(String lang) => _p(lang, bodyAr, bodyEn, bodyZh);
  String? ctaLabel(String lang) {
    if (ctaLabelAr == null) return null;
    return _p(lang, ctaLabelAr!, ctaLabelEn ?? ctaLabelAr!, ctaLabelZh ?? ctaLabelEn ?? ctaLabelAr!);
  }

  static String _p(String lang, String ar, String en, String zh) {
    if (lang.startsWith('ar')) return ar;
    if (lang.startsWith('zh')) return zh;
    return en;
  }
}

List<ChinaContentItem> chinaContentForCategory(String categoryId) {
  return kChinaContentItems
      .where((c) => c.categoryIds.contains(categoryId))
      .toList();
}

const kChinaContentUpdated = '2026-10-27';

const kChinaContentItems = <ChinaContentItem>[
  ChinaContentItem(
    id: 'docs-common-china',
    categoryIds: ['visa-docs', 'education'],
    kind: ChinaContentKind.guide,
    titleAr: 'دليل الوثائق الشائعة في الصين',
    titleEn: 'Common documents guide in China',
    titleZh: '中国常用文件指南',
    summaryAr: 'ترجمة، توثيق، سفارة — نظرة عامة غير قانونية.',
    summaryEn: 'Translation, notarization, embassy — high-level, not legal advice.',
    summaryZh: '翻译、公证、使馆 — 概览，非法律意见。',
    updatedAt: kChinaContentUpdated,
    imageAsset: 'assets/china/convention.jpg',
    ctaParentSlug: 'government',
    ctaSubId: 'document-attestation',
    ctaLabelAr: 'اطلب توثيق/ترجمة عبر Obic',
    ctaLabelEn: 'Request attestation/translation via Obic',
    ctaLabelZh: '通过 Obic 申请公证/翻译',
    bodyAr: '''
هذا الدليل معلومات عامة فقط — ليس استشارة قانونية.

1) جواز سفر ساري + صفحة التأشيرة/الإقامة.
2) ترجمة معتمدة للعربية/الإنجليزية عند الطلب الرسمي (جامعات، بنوك، جهات حكومية).
3) توثيق (公证) في مكتب عدل صيني ثم أحياناً تصديق خارجي عبر السفارة.
4) شهادات الميلاد/الزواج/الدرجة العلمية: غالباً سلسلة توثيق في بلد الإصدار ثم الصين.
5) احتفظ بنسخ رقمية واضحة؛ الأسماء يجب أن تطابق الجواز حرفياً.

أخطاء شائعة: ترجمة غير معتمدة، تواريخ منتهية، اختلاف إملائي للاسم.
''',
    bodyEn: '''
General information only — not legal advice.

1) Valid passport + visa/residence page.
2) Certified translation when an office requires AR/EN.
3) Chinese notarization (公证), sometimes plus embassy legalization.
4) Birth/marriage/degree certificates often need a chain of authentication.
5) Keep clear digital copies; names must match the passport exactly.

Common mistakes: uncertified translation, expired stamps, name spelling drift.
''',
    bodyZh: '''
仅供一般参考 — 非法律意见。

1) 有效护照 + 签证/居留页。
2) 机关要求时提供认证翻译。
3) 国内公证，有时还需使领馆认证。
4) 出生/结婚/学历证明常需认证链条。
5) 保留清晰电子件；姓名须与护照一致。

常见错误：非认证翻译、过期手续、姓名拼写不一致。
''',
  ),
  ChinaContentItem(
    id: 'scholarship-checklist',
    categoryIds: ['education'],
    kind: ChinaContentKind.checklist,
    titleAr: 'قائمة مستندات المنح والقبول',
    titleEn: 'Scholarship & admission documents checklist',
    titleZh: '奖学金与录取材料清单',
    summaryAr: 'جواز، شهادات، خطة دراسة، HSK، توصيات…',
    summaryEn: 'Passport, transcripts, study plan, HSK, recommendations…',
    summaryZh: '护照、成绩单、学习计划、HSK、推荐信…',
    updatedAt: kChinaContentUpdated,
    imageAsset: 'assets/china/shanghai.jpg',
    ctaParentSlug: 'education',
    ctaSubId: 'scholarships',
    ctaLabelAr: 'اطلب مساعدة Obic للمنح',
    ctaLabelEn: 'Request Obic scholarship help',
    ctaLabelZh: '申请 Obic 奖学金协助',
    bodyAr: '''
□ جواز ساري + صورة شخصية بالمواصفات
□ شهادات وكشوف درجات (موثقة/مترجمة إن لزم)
□ خطة دراسة أو مقترح بحث
□ HSK / HSKK أو إثبات لغة إنجليزية حسب البرنامج
□ خطابا توصية (غالباً أستاذان)
□ سجل طبي / نموذج جسماني إن طُلب
□ خطاب تمويل أو نموذج CSC حسب المسار
□ إثبات عدم وجود سجل جنائي إن طُلب

نصيحة: ابدأ قبل الموعد بـ 8–12 أسبوعاً. Obic يساعد في الترتيب — القبول من الجامعة/CSC فقط.
''',
    bodyEn: '''
□ Valid passport + photo to spec
□ Diplomas & transcripts (notarized/translated if required)
□ Study plan or research proposal
□ HSK/HSKK or English proof per program
□ Two recommendation letters (often professors)
□ Medical form if required
□ Funding / CSC forms per track
□ Police clearance if required

Tip: start 8–12 weeks early. Obic helps organize — admission is university/CSC only.
''',
    bodyZh: '''
□ 有效护照 + 符合规格照片
□ 学历成绩单（如需公证/翻译）
□ 学习计划或研究计划
□ 按项目要求的 HSK/HSKK 或英语证明
□ 两封推荐信
□ 如需体检表
□ 按渠道准备经费/CSC 表格
□ 如需无犯罪记录证明

建议提前 8–12 周准备。Obic 协助整理 — 录取权在院校/CSC。
''',
  ),
  ChinaContentItem(
    id: 'bank-sim-address',
    categoryIds: ['visa-docs', 'stay-tour', 'business'],
    kind: ChinaContentKind.guide,
    titleAr: 'دليل عملي: بنك / شريحة / عنوان',
    titleEn: 'Practical: bank / SIM / address',
    titleZh: '实用：银行 / 电话卡 / 住址',
    summaryAr: 'نصائح عامة + اطلب خدمة Obic للترتيب.',
    summaryEn: 'Practical tips + request Obic to arrange.',
    summaryZh: '实用提示 + 可让 Obic 协助安排。',
    updatedAt: kChinaContentUpdated,
    imageAsset: 'assets/china/business-skyline.jpg',
    ctaParentSlug: 'business',
    ctaSubId: 'business-consult',
    ctaLabelAr: 'اطلب ترتيب Obic',
    ctaLabelEn: 'Request Obic arrangement',
    ctaLabelZh: '申请 Obic 协助安排',
    bodyAr: '''
بنك: معظم الفروع تطلب جواز + تأشيرة/إقامة + رقم هاتف صيني. السياسات تختلف حسب البنك والمدينة.

شريحة SIM: متاجر رسمية تطلب جواز؛ فعّل التحقق الحقيقي للاسم.

عنوان: احتفظ بعقد إيجار أو إثبات فندق؛ بعض المعاملات تحتاج عنواناً محلياً مسجلاً.

لا نعرض أرصدة ولا نفتح حسابات داخل التطبيق — Obic يرتب الموعد/المرافقة عبر طلب خدمة.
''',
    bodyEn: '''
Bank: most branches want passport + visa/residence + a China phone number. Rules vary by bank and city.

SIM: official shops need passport; complete real-name registration.

Address: keep a lease or hotel proof; some processes need a registered local address.

We don’t show balances or open accounts in-app — Obic arranges appointment/escort via a service order.
''',
    bodyZh: '''
银行：多数网点需要护照 + 签证/居留 + 中国手机号；各行各市政策不同。

电话卡：营业厅需护照并完成实名。

住址：保留租房合同或酒店证明；部分业务需要登记住址。

应用内不展示余额、不开户 — Obic 通过服务订单协助预约/陪同。
''',
  ),
  ChinaContentItem(
    id: 'uni-glossary',
    categoryIds: ['education'],
    kind: ChinaContentKind.glossary,
    titleAr: 'قاموس مصطلحات جامعية عربي–صيني',
    titleEn: 'Short university glossary AR–ZH',
    titleZh: '高校常用词阿汉对照',
    summaryAr: 'مصطلحات قبول وإدارة قصيرة.',
    summaryEn: 'Short admissions & admin terms.',
    summaryZh: '录取与行政常用词。',
    updatedAt: kChinaContentUpdated,
    imageAsset: 'assets/china/shanghai.jpg',
    bodyAr: '''
منحة = 奖学金
قبول مشروط = 预录取
خطاب قبول = 录取通知书
تأشيرة دراسة X1/X2 = 学习签证
إقامة = 居留许可
سكن جامعي = 宿舍
تسجيل = 报到/注册
قسط دراسي = 学费
منحة CSC = 中国政府奖学金
اختبار HSK = 汉语水平考试
''',
    bodyEn: '''
Scholarship = 奖学金
Conditional offer = 预录取
Admission letter = 录取通知书
Study visa X1/X2 = 学习签证
Residence permit = 居留许可
Dorm = 宿舍
Registration = 报到/注册
Tuition = 学费
CSC scholarship = 中国政府奖学金
HSK = 汉语水平考试
''',
    bodyZh: '''
奖学金 / Scholarship
预录取 / Conditional offer
录取通知书 / Admission letter
学习签证 X1/X2
居留许可 / Residence permit
宿舍 / Dorm
报到·注册 / Registration
学费 / Tuition
中国政府奖学金 / CSC
汉语水平考试 / HSK
''',
  ),
  ChinaContentItem(
    id: 'study-visa-faq',
    categoryIds: ['education', 'visa-docs'],
    kind: ChinaContentKind.faq,
    titleAr: 'FAQ: فيزا دراسة وإقامة وتأمين طلابي',
    titleEn: 'FAQ: study visa, residence, student insurance',
    titleZh: '常见问题：学习签证、居留、学生保险',
    summaryAr: 'معلومات عامة من مسارات معلنة — تحقق دائماً من السفارة.',
    summaryEn: 'Public-path overview — always verify with the embassy.',
    summaryZh: '公开路径概览 — 请以使馆/院校通知为准。',
    updatedAt: kChinaContentUpdated,
    imageAsset: 'assets/china/convention.jpg',
    ctaParentSlug: 'government',
    ctaSubId: 'visas',
    ctaLabelAr: 'اطلب مساعدة تأشيرة عبر Obic',
    ctaLabelEn: 'Request visa help via Obic',
    ctaLabelZh: '通过 Obic 申请签证协助',
    bodyAr: '''
س: ما الفرق X1 و X2؟
ج: غالباً X1 للدراسة طويلة الأمد (ثم تحويل لإقامة)، X2 للقصيرة. القرار النهائي للسفارة.

س: هل المنحة تضمن التأشيرة؟
ج: لا. المنحة/القبول formalities منفصلة عن قرار التأشيرة.

س: التأمين الصحي؟
ج: الجامعات غالباً تطلب تأميناً طلابياً؛ التفاصيل في دليل القبول السنوي.

س: هل Obic يصدر تأشيرة؟
ج: لا. نساعد في الملف والمواعيد؛ الإصدار من الجهات الرسمية فقط.
''',
    bodyEn: '''
Q: X1 vs X2?
A: Often X1 for long study (then residence permit), X2 for short. Embassy decides.

Q: Does a scholarship guarantee a visa?
A: No. Award/admission paperwork is separate from the visa decision.

Q: Health insurance?
A: Universities usually require student cover; see the yearly admission guide.

Q: Does Obic issue visas?
A: No. We help with files and appointments; only authorities issue visas.
''',
    bodyZh: '''
问：X1 与 X2？
答：长学期多为 X1（后换居留），短期多为 X2；最终由使馆决定。

问：奖学金是否保证签证？
答：否。录取/奖学金手续与签证审批相互独立。

问：医保？
答：院校通常要求学生保险，以当年录取指南为准。

问：Obic 能否出签？
答：不能。我们协助材料与预约；签证仅由官方签发。
''',
  ),
  ChinaContentItem(
    id: 'biz-start-company',
    categoryIds: ['business'],
    kind: ChinaContentKind.guide,
    titleAr: 'كيف تبدأ شركة في الصين — نظرة سريعة',
    titleEn: 'Starting a company in China — quick guide',
    titleZh: '在华注册公司 — 速览',
    summaryAr: 'خطوات عامة ثم نموذج تسجيل Obic.',
    summaryEn: 'High-level steps then Obic registration form.',
    summaryZh: '概要步骤后进入 Obic 注册表单。',
    updatedAt: kChinaContentUpdated,
    imageAsset: 'assets/china/business-skyline.jpg',
    ctaParentSlug: 'business',
    ctaSubId: 'company-registration',
    ctaLabelAr: 'ابدأ طلب تسجيل شركة',
    ctaLabelEn: 'Start company registration request',
    ctaLabelZh: '开始公司注册申请',
    bodyAr: '''
1) حدّد النشاط والمدينة والهيكل (WFOE وغيرها حسب الحالة).
2) جهّز جوازات المساهمين وعنوان مكتب مبدئي.
3) اسم تجاري + نطاق أعمال مع مستشار محلي.
4) تسجيل وترخيص ثم حساب بنكي للشركة و الضرائب.

Obic ينسّق الاستشارة والتقديم عبر طلب رسمي — بدون وعود موافقة وهمية.
''',
    bodyEn: '''
1) Decide activity, city, and structure (e.g. WFOE where applicable).
2) Prepare shareholder passports and a provisional office address.
3) Trade name + business scope with local counsel.
4) Registration/license, then corporate bank and tax setup.

Obic coordinates advice and filing via a real order — no fake approval promises.
''',
    bodyZh: '''
1) 明确业务、城市与架构（如适用的外商独资等）。
2) 准备股东护照与临时办公地址。
3) 与本地顾问确定字号与经营范围。
4) 注册领证后办理对公账户与税务。

Obic 通过正式订单协调咨询与递交 — 不作虚假批准承诺。
''',
  ),
  ChinaContentItem(
    id: 'biz-trademark-qc',
    categoryIds: ['business', 'sourcing-logistics'],
    kind: ChinaContentKind.guide,
    titleAr: 'علامات تجارية وفحص بضاعة',
    titleEn: 'Trademarks & quality inspection',
    titleZh: '商标与验货',
    summaryAr: 'اربط الدليل بخدمات العلامة والفحص الموجودة.',
    summaryEn: 'Funnel into existing trademark and QC services.',
    summaryZh: '对接现有商标与质检服务。',
    updatedAt: kChinaContentUpdated,
    imageAsset: 'assets/china/expo-hall.jpg',
    ctaParentSlug: 'business',
    ctaSubId: 'trademarks',
    ctaLabelAr: 'اطلب علامة / فحص',
    ctaLabelEn: 'Request trademark / inspection',
    ctaLabelZh: '申请商标 / 验货',
    bodyAr: '''
العلامة: ابحث قبل الإطلاق؛ التسجيل في الصين مسار رسمي منفصل.

الفحص: حدّد معايير AQL والصور قبل الشحن؛ اربط النتائج بطلب لوجستيات.

حاسبة الاستيراد: من فئة التوريد — تقدير غير ملزم ثم عرض سعر شحن.
''',
    bodyEn: '''
Trademark: search before launch; China registration is its own official path.

QC: set AQL and photo standards before ship; attach results to logistics orders.

Import calculator: under sourcing — non-binding estimate, then freight quote order.
''',
    bodyZh: '''
商标：上线前先检索；中国注册为独立官方流程。

验货：出货前明确 AQL 与拍照标准；结果可附在物流订单。

进口测算：在采购物流类 — 非约束估算，随后可下运费询价单。
''',
  ),
  ChinaContentItem(
    id: 'tour-day-pack',
    categoryIds: ['stay-tour'],
    kind: ChinaContentKind.pack,
    titleAr: 'باقة: يوم واحد في المدينة',
    titleEn: 'Pack: one day in the city',
    titleZh: '行程包：城市一日游',
    summaryAr: 'مسجد + سوق + معلم — ثم اذهب مع Obic.',
    summaryEn: 'Mosque + market + landmark — then Go with Obic.',
    summaryZh: '清真寺 + 市场 + 景点 — 可跟 Obic 走。',
    updatedAt: kChinaContentUpdated,
    imageAsset: 'assets/travel/landmark.jpg',
    ctaParentSlug: 'travel',
    ctaSubId: 'guide',
    ctaLabelAr: 'اذهب مع Obic',
    ctaLabelEn: 'Go with Obic',
    ctaLabelZh: '跟 Obic 走',
    bodyAr: '''
صباحاً: معلم رئيسي أو منتزه.
ظهراً: سوق/طعام (تحقق من خيارات مناسبة لك).
عصراً: مسجد أو حي تجاري للجالية إن وُجد.
مساءً: أفق المدينة أو مول.

استخدم مبدّل المدن و«زيارة قريبة منك» للPins. إن لم تتوفر أماكن بعد لمدينتك: اطلب مرشداً.
''',
    bodyEn: '''
Morning: main landmark or park.
Midday: market/food (check options that suit you).
Afternoon: mosque or community trade area if listed.
Evening: skyline or mall.

Use the city switcher and Visit near you for pins. If your city has no curated places yet: request a guide.
''',
    bodyZh: '''
上午：主要景点或公园。
中午：市场/餐饮（按自身需求选择）。
下午：如有标注的清真寺或社群商圈。
晚上：天际线或商场。

用城市切换与「附近可访」查看坐标。若该市暂无精选点：可申请导游。
''',
  ),
  ChinaContentItem(
    id: 'tour-yiwu-markets',
    categoryIds: ['stay-tour', 'sourcing-logistics'],
    kind: ChinaContentKind.pack,
    titleAr: 'باقة: أسواق ييوو',
    titleEn: 'Pack: Yiwu markets',
    titleZh: '行程包：义乌市场',
    summaryAr: 'فوتان، بينوانغ، نصائح توريد.',
    summaryEn: 'Futian, Binwang, sourcing tips.',
    summaryZh: '福田、宾王与采购提示。',
    updatedAt: kChinaContentUpdated,
    imageAsset: 'assets/china/expo-hall.jpg',
    ctaParentSlug: 'sourcing',
    ctaSubId: 'factories',
    ctaLabelAr: 'اطلب توريد / مرافقة',
    ctaLabelEn: 'Request sourcing / escort',
    ctaLabelZh: '申请采购 / 陪同',
    bodyAr: '''
• ابدأ بخريطة المجمّع ورقم القاعة.
• عيّنات واضحة قبل الطلب الكبير.
• اربط الفحص بحاسبة الاستيراد قبل الحجز البحري.

الأماكن على الخريطة ضمن ييوو في «زيارة قريبة».
''',
    bodyEn: '''
• Start with district map and hall numbers.
• Clear samples before bulk orders.
• Tie QC to the import calculator before ocean booking.

Pins live under Yiwu in Visit near you.
''',
    bodyZh: '''
• 先看分区图与馆号。
• 大货前确认样品。
• 订舱前把验货与进口测算打通。

坐标见义乌「附近可访」。
''',
  ),
];
