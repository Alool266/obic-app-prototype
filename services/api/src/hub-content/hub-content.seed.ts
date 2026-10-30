// Made by Dr Ali
// Rich demo seed for China / Daily / Travel hubs (Yiwu + major cities).

export type HubKey = 'china' | 'daily' | 'travel';

export type HubGuide = {
  id: string;
  hub: HubKey;
  categoryId?: string;
  city?: string;
  titleAr: string;
  titleEn: string;
  titleZh: string;
  summaryAr: string;
  summaryEn: string;
  summaryZh: string;
  bodyAr: string;
  bodyEn: string;
  bodyZh: string;
  imageUrl?: string;
  ctaLabelAr?: string;
  ctaLabelEn?: string;
  published: boolean;
};

export type HubPlace = {
  id: string;
  hub: HubKey;
  categoryId?: string;
  city: string;
  nameAr: string;
  nameEn: string;
  nameZh: string;
  lat: number;
  lng: number;
  rating?: number;
  hoursAr?: string;
  hoursEn?: string;
  imageUrl?: string;
  published: boolean;
};

export type HubDeal = {
  id: string;
  hub: HubKey;
  titleAr: string;
  titleEn: string;
  photo?: string;
  target?: string;
  published: boolean;
};

export type HubCategoryCopy = {
  id: string;
  hub: HubKey;
  titleAr: string;
  titleEn: string;
  titleZh: string;
  blurbAr: string;
  blurbEn: string;
  blurbZh: string;
};

export const HUB_GUIDES: HubGuide[] = [
  {
    id: 'cn-yiwu-first-week',
    hub: 'china',
    categoryId: 'visit',
    city: 'Yiwu',
    titleAr: 'أسبوعك الأول في ييوو',
    titleEn: 'Your first week in Yiwu',
    titleZh: '义乌第一周',
    summaryAr: 'من المطار إلى السوق الدولي — خطوات عملية.',
    summaryEn: 'From airport to International Trade City — practical steps.',
    summaryZh: '从机场到国际商贸城 — 实用步骤。',
    bodyAr:
      '1) انزل في مطار ييوو أو قطار هانغتشو/جينهوا.\n2) فعّل eSIM أو بطاقة محلية عبر مكتب أوبك.\n3) سجّل عنوان الإقامة في التطبيق.\n4) زر السوق الدولي مع مرشد محلي إن لزم.\n5) احفظ فرع أوبك ييوو كنقطة دعم.\n\nهذا دليل عام — طلبات التأشيرة والتسجيل تتم عبر نماذج أوبك.',
    bodyEn:
      '1) Arrive via Yiwu airport or Hangzhou/Jinhua rail.\n2) Activate eSIM or a local SIM via OBIC desk.\n3) Save your stay address in the app.\n4) Visit the International Trade City with a local guide if needed.\n5) Pin OBIC Yiwu as your support point.\n\nGeneral guide — visas and company setup go through OBIC forms.',
    bodyZh:
      '1) 经义乌机场或杭州/金华高铁抵达。\n2) 通过 OBIC 开通 eSIM 或本地卡。\n3) 在应用中保存住宿地址。\n4) 如需可随地陪参观国际商贸城。\n5) 将义乌 OBIC 设为支持点。\n\n通用指南 — 签证与公司注册走 OBIC 表单。',
    imageUrl: '/uploads/marketplace/landmark.jpg',
    ctaLabelAr: 'اطلب مساعدة الزيارة',
    ctaLabelEn: 'Request visit help',
    published: true,
  },
  {
    id: 'cn-csc-scholarships',
    hub: 'china',
    categoryId: 'education',
    titleAr: 'منح CSC والمنح العامة',
    titleEn: 'CSC & public scholarships',
    titleZh: 'CSC 与公开奖学金',
    summaryAr: 'معلومات عامة من مصادر رسمية + مساعدة أوبك.',
    summaryEn: 'Public info from official sources + OBIC help.',
    summaryZh: '官方公开信息 + OBIC 协助。',
    bodyAr:
      'برنامج المنح الدراسية للحكومة الصينية (CSC) يُعلن عبر الجامعات والسفارات. أوبك لا يضمن القبول — نساعد في الترجمة، تجهيز الملف، ومتابعة المواعيد.\nراجع دائماً الموقع الرسمي للجامعة وبوابة CSC قبل الدفع لأي طرف ثالث.',
    bodyEn:
      'Chinese Government Scholarship (CSC) is published via universities and embassies. OBIC does not guarantee admission — we help with translation, file prep, and timelines.\nAlways check the university site and CSC portal before paying any third party.',
    bodyZh:
      '中国政府奖学金（CSC）由高校与使馆公布。OBIC 不保证录取 — 我们协助翻译、材料与时间节点。\n付款给第三方前请核对高校官网与 CSC 门户。',
    imageUrl: '/uploads/marketplace/hotel.jpg',
    ctaLabelAr: 'اطلب مساعدة المنح',
    ctaLabelEn: 'Request scholarship help',
    published: true,
  },
  {
    id: 'cn-business-setup',
    hub: 'china',
    categoryId: 'business',
    city: 'Yiwu',
    titleAr: 'تأسيس شركة في ييوو — نظرة عامة',
    titleEn: 'Company setup in Yiwu — overview',
    titleZh: '义乌公司设立概览',
    summaryAr: 'خطوات عامة قبل فتح نموذج التسجيل.',
    summaryEn: 'High-level steps before opening the registration form.',
    summaryZh: '打开注册表单前的概要步骤。',
    bodyAr:
      'حدّد نوع النشاط، العنوان القانوني، والمساهمين. جهّز جوازات السفر والترجمة. أوبك يفتح لك نموذج التسجيل ويمرّره للموظفين. الأوقات والرسوم تختلف حسب النشاط — اسأل المكتب.',
    bodyEn:
      'Define activity type, legal address, and shareholders. Prepare passports and translations. OBIC opens the registration form for staff. Timelines and fees vary — ask the desk.',
    bodyZh:
      '明确经营范围、注册地址与股东。准备护照与翻译。OBIC 打开注册表单交由员工处理。时限与费用因业态而异 — 请咨询柜台。',
    ctaLabelAr: 'فتح تسجيل الشركة',
    ctaLabelEn: 'Open company registration',
    published: true,
  },
  {
    id: 'daily-halal-yiwu',
    hub: 'daily',
    city: 'Yiwu',
    titleAr: 'أكل حلال قريب من السوق',
    titleEn: 'Halal food near the market',
    titleZh: '商贸城附近清真餐',
    summaryAr: 'مطاعم عربية وتركية مجرّبة حول ييوو.',
    summaryEn: 'Tried Arabic & Turkish spots around Yiwu.',
    summaryZh: '义乌周边口碑阿拉伯/土耳其餐厅。',
    bodyAr:
      'اطلب من قسم «أكل» واختر وسم حلال. احفظ عنوان التوصيل قبل الطلب. للعائلات الكبيرة استخدم مشاوير أوبك لشراء الجملة من السوق.',
    bodyEn:
      'Open Food and filter halal tags. Save a delivery address first. For bulk market runs, use OBIC errands.',
    bodyZh:
      '打开「美食」并筛选清真标签。先保存配送地址。大批量采购可用 OBIC 跑腿。',
    imageUrl: '/uploads/marketplace/food.jpg',
    published: true,
  },
  {
    id: 'travel-yiwu-weekend',
    hub: 'travel',
    city: 'Yiwu',
    titleAr: 'عطلة نهاية أسبوع من ييوو',
    titleEn: 'Weekend escape from Yiwu',
    titleZh: '义乌周末短途',
    summaryAr: 'هانغتشو أو شنغهاي بالقطار — فنادق ومعالم.',
    summaryEn: 'Hangzhou or Shanghai by train — hotels & sights.',
    summaryZh: '高铁去杭州或上海 — 酒店与景点。',
    bodyAr:
      'احجز القطار ثم الفندق من تبويب سفر. أضف توصيل مطار/محطة إن احتجت. احفظ المسافر الافتراضي في إعدادات المركز.',
    bodyEn:
      'Book train then hotel from Travel. Add station/airport transfer if needed. Save a default traveler in hub settings.',
    bodyZh:
      '在旅行页先订火车再订酒店。需要时可加车站/机场接送。在中心设置保存默认旅客。',
    imageUrl: '/uploads/marketplace/train.jpg',
    published: true,
  },
];

export const HUB_PLACES: HubPlace[] = [
  {
    id: 'pl-yiwu-itc',
    hub: 'china',
    categoryId: 'visit',
    city: 'Yiwu',
    nameAr: 'السوق الدولي ييوو',
    nameEn: 'Yiwu International Trade City',
    nameZh: '义乌国际商贸城',
    lat: 29.3385,
    lng: 120.0789,
    rating: 4.7,
    hoursAr: '٩:٠٠–١٧:٠٠',
    hoursEn: '09:00–17:00',
    imageUrl: '/uploads/marketplace/landmark.jpg',
    published: true,
  },
  {
    id: 'pl-yiwu-obic',
    hub: 'china',
    categoryId: 'business',
    city: 'Yiwu',
    nameAr: 'فرع أوبك ييوو',
    nameEn: 'OBIC Yiwu branch',
    nameZh: 'OBIC 义乌分公司',
    lat: 29.3067,
    lng: 120.0752,
    rating: 4.9,
    hoursAr: '٩:٣٠–١٨:٣٠',
    hoursEn: '09:30–18:30',
    imageUrl: '/uploads/marketplace/hotel.jpg',
    published: true,
  },
  {
    id: 'pl-sh-bund',
    hub: 'travel',
    categoryId: 'attractions',
    city: 'Shanghai',
    nameAr: 'البوند',
    nameEn: 'The Bund',
    nameZh: '外滩',
    lat: 31.2403,
    lng: 121.4905,
    rating: 4.8,
    hoursAr: 'مفتوح دائماً',
    hoursEn: 'Open 24h',
    imageUrl: '/uploads/marketplace/landmark.jpg',
    published: true,
  },
  {
    id: 'pl-hz-westlake',
    hub: 'travel',
    categoryId: 'attractions',
    city: 'Hangzhou',
    nameAr: 'بحيرة الغرب',
    nameEn: 'West Lake',
    nameZh: '西湖',
    lat: 30.242,
    lng: 120.148,
    rating: 4.9,
    hoursAr: 'مفتوح دائماً',
    hoursEn: 'Open 24h',
    imageUrl: '/uploads/marketplace/landmark.jpg',
    published: true,
  },
  {
    id: 'pl-yiwu-mandi',
    hub: 'daily',
    categoryId: 'food',
    city: 'Yiwu',
    nameAr: 'مندي ييوو',
    nameEn: 'Yiwu Mandi House',
    nameZh: '义乌曼迪餐厅',
    lat: 29.31,
    lng: 120.08,
    rating: 4.8,
    hoursAr: '١١:٠٠–٢٣:٠٠',
    hoursEn: '11:00–23:00',
    imageUrl: '/uploads/marketplace/food.jpg',
    published: true,
  },
];

export const HUB_DEALS: HubDeal[] = [
  {
    id: 'deal-daily-delivery',
    hub: 'daily',
    titleAr: 'خصم على التوصيل اليوم',
    titleEn: 'Delivery discount today',
    photo: '/uploads/marketplace/food.jpg',
    target: 'food',
    published: true,
  },
  {
    id: 'deal-daily-pharmacy',
    hub: 'daily',
    titleAr: 'صيدليات قريبة · توصيل سريع',
    titleEn: 'Nearby pharmacies · fast ETA',
    photo: '/uploads/marketplace/pharmacy.jpg',
    target: 'pharmacy',
    published: true,
  },
  {
    id: 'deal-travel-yiwu-hotel',
    hub: 'travel',
    titleAr: 'فنادق ييوو · خصم نهاية الأسبوع',
    titleEn: 'Yiwu hotels · weekend deal',
    photo: '/uploads/marketplace/hotel.jpg',
    target: 'hotels',
    published: true,
  },
  {
    id: 'deal-travel-flights',
    hub: 'travel',
    titleAr: 'طيران دولي · عروض محدودة',
    titleEn: 'International flights · limited',
    photo: '/uploads/marketplace/flight.jpg',
    target: 'flights',
    published: true,
  },
];

export const HUB_CATEGORY_COPY: HubCategoryCopy[] = [
  {
    id: 'visit',
    hub: 'china',
    titleAr: 'زيارة واستكشاف',
    titleEn: 'Visit & explore',
    titleZh: '到访与探索',
    blurbAr: 'أماكن قريبة، جولات وأدلة مدينة.',
    blurbEn: 'Nearby places, tours, and city guides.',
    blurbZh: '附近地点、行程与城市指南。',
  },
  {
    id: 'business',
    hub: 'china',
    titleAr: 'أعمال وتأسيس',
    titleEn: 'Business & setup',
    titleZh: '商务与注册',
    blurbAr: 'تسجيل، استشارات، علامات وتراخيص.',
    blurbEn: 'Registration, consulting, trademarks & licenses.',
    blurbZh: '注册、咨询、商标与许可。',
  },
];
