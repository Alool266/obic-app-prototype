/* OBIC V1 Prototype — Designed & developed by Ali */
const ICONS = {
  hotel: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 21V8l8-5 8 5v13"/><path d="M9 21v-6h6v6"/><path d="M4 21h16"/><path d="M9 10h.01M15 10h.01M12 13h.01"/></svg>`,
  flight: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.8 19.2L16 11l3.5-3.5C20.5 6.5 21 6 21 5.5s-.5-1-1-1.5L18 2.5c-.5-.5-1-.5-1.5 0L13 6 4.8 4.2c-.4-.1-.8 0-1 .3L3 5.5c-.3.4-.2.9.2 1.1L10 10l-2 4-2.5-.7c-.4-.1-.8 0-1 .3l-.8.8c-.3.3-.2.8.1 1L8 18l9.8 1.2z"/></svg>`,
  visa: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="3" width="14" height="18" rx="2"/><circle cx="12" cy="10" r="2.5"/><path d="M8.5 16.5c.8-1.4 2-2 3.5-2s2.7.6 3.5 2"/><path d="M5 7h14"/></svg>`,
  bank: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10l9-7 9 7"/><path d="M5 10v8M9 10v8M15 10v8M19 10v8"/><path d="M3 18h18M3 21h18"/></svg>`,
  vip: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 16L3 7l5.5 4L12 4l3.5 7L21 7l-2 9H5z"/><path d="M5 16h14v2a2 2 0 01-2 2H7a2 2 0 01-2-2v-2z"/></svg>`,
  legal: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 3v18M5 8l7-4 7 4M6 21h12M8 12l-3 5h6l-3-5zm8 0l-3 5h6l-3-5z"/></svg>`,
  company: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 21V5a1 1 0 011-1h8a1 1 0 011 1v16M14 10h5a1 1 0 011 1v10M8 8h2M8 12h2M8 16h2"/></svg>`,
  scholarship: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M22 10L12 5 2 10l10 5 10-5zM6 12v5c0 1 3 3 6 3s6-2 6-3v-5"/></svg>`,
  transfer: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M7 10H21l-4-4M17 14H3l4 4"/></svg>`,
  ads: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 11l18-7v16L3 13v-2zM11.5 16.5V21"/></svg>`,
  biz: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>`,
  hr: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2M9 11a4 4 0 100-8 4 4 0 000 8zM22 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/></svg>`,
  insurance: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 3l8 4v5c0 5-3.5 8.5-8 10-4.5-1.5-8-5-8-10V7l8-4z"/></svg>`,
  expand: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 010 18M12 3a14 14 0 000 18"/></svg>`,
  tech: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 18v-2a4 4 0 014-4h2M15 18v-1a3 3 0 013-3h0a3 3 0 013 3v1M9 12a3 3 0 100-6 3 3 0 000 6zM18 11a2.5 2.5 0 100-5 2.5 2.5 0 000 5z"/></svg>`,
  plan: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2M9 12h6M9 16h4"/></svg>`,
  search: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>`,
  home: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 11l9-7 9 7v9a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1v-9z"/></svg>`,
  grid: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>`,
  msg: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21 12a8 8 0 01-8 8H6l-4 3V12a8 8 0 018-8h3a8 8 0 018 8z"/></svg>`,
  orders: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M7 7h12l-1 11H8L7 7zM7 7l-1-3H3M10 11v4M14 11v4"/></svg>`,
  me: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0116 0"/></svg>`,
  check: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M5 13l4 4L19 7"/></svg>`,
  doc: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M8 3h7l4 4v13a1 1 0 01-1 1H8a1 1 0 01-1-1V4a1 1 0 011-1z"/><path d="M15 3v5h5M9 13h6M9 17h4"/></svg>`,
  bell: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 9a6 6 0 1112 0c0 7 2 7 2 9H4c0-2 2-2 2-9zM10 21h4"/></svg>`,
  pin: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 21s7-5.5 7-12a7 7 0 10-14 0c0 6.5 7 12 7 12z"/><circle cx="12" cy="9" r="2.5"/></svg>`,
  web: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 010 18M12 3a14 14 0 000 18"/></svg>`,
  mail: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 7 9-7"/></svg>`,
  phone: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M22 16.9v3a2 2 0 01-2.2 2 19.8 19.8 0 01-8.6-3.1 19.5 19.5 0 01-6-6A19.8 19.8 0 012.1 4.2 2 2 0 014.1 2h3a2 2 0 012 1.7c.1.9.4 1.8.7 2.6a2 2 0 01-.5 2.1L8.1 9.9a16 16 0 006 6l1.5-1.2a2 2 0 012.1-.5c.8.3 1.7.6 2.6.7A2 2 0 0122 16.9z"/></svg>`,
  video: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="2" y="6" width="13" height="12" rx="2"/><path d="M15 10l7-3v10l-7-3v-4z"/></svg>`,
  mic: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0014 0M12 18v3"/></svg>`,
  micOff: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 9v2a3 3 0 005.1 2.1M15 9V7a3 3 0 00-5.2-2M5 11a7 7 0 0011.3 5.5M12 18v3M2 2l20 20"/></svg>`,
  speaker: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M11 5L6 9H3v6h3l5 4V5zM16 9a4 4 0 010 6M18.5 7a7 7 0 010 10"/></svg>`,
  camFlip: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M16 4h4v4M20 4l-5 5M8 20H4v-4M4 20l5-5"/><rect x="7" y="7" width="10" height="10" rx="2"/></svg>`,
  image: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="10" r="1.5"/><path d="M21 16l-5-5-8 8"/></svg>`,
  attach: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21.4 11.6l-8.5 8.5a5 5 0 01-7.1-7.1l9.2-9.2a3.2 3.2 0 014.5 4.5L10.4 19.4a1.4 1.4 0 01-2-2l8.1-8.1"/></svg>`,
  hangup: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M10 9a7 7 0 000 6M14 9a7 7 0 010 6M3 10c4-3 14-3 18 0v2c-4-2-14-2-18 0v-2z"/></svg>`,
  ai: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 3l1.6 4.2L18 9l-4.4 1.8L12 15l-1.6-4.2L6 9l4.4-1.8L12 3z"/><path d="M5 16l.9 2.2L8 19l-2.1.8L5 22l-.9-2.2L2 19l2.1-.8L5 16zM19 14l.7 1.6L21 16l-1.3.5L19 18l-.7-1.5L17 16l1.3-.4L19 14z"/></svg>`,
  moments: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><path d="M14 17.5h7M17.5 14v7"/></svg>`,
  userPlus: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2M9 11a4 4 0 100-8 4 4 0 000 8zM19 8v6M22 11h-6"/></svg>`,
  qr: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h2v2h-2zM18 14h2v2h-2zM14 18h2v2h-2zM18 18h2v2h-2z"/></svg>`,
  eye: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7S1 12 1 12z"/><circle cx="12" cy="12" r="3"/></svg>`,
};

const COLORS = {
  hotels: { bg: "linear-gradient(145deg,#FB7185,#E11D48)", soft: "#FFE4E6", ink: "#E11D48" },
  flights: { bg: "linear-gradient(145deg,#60A5FA,#1A6DFF)", soft: "#DBEAFE", ink: "#1A6DFF" },
  visa: { bg: "linear-gradient(145deg,#2DD4BF,#0D9488)", soft: "#CCFBF1", ink: "#0D9488" },
  bank: { bg: "linear-gradient(145deg,#4ADE80,#16A34A)", soft: "#DCFCE7", ink: "#16A34A" },
  vip: { bg: "linear-gradient(145deg,#FB923C,#EA580C)", soft: "#FFEDD5", ink: "#EA580C" },
  default: { bg: "linear-gradient(145deg,#93C5FD,#1A6DFF)", soft: "#E8F1FF", ink: "#1A6DFF" },
};

const I18N = {
  ar: {
    panelMuted: "نموذج تجربة مستخدم فاخر",
    panelSub: "تطبيق ثلاثي الأبعاد · الذكاء الاصطناعي · الموظفين · العربية أولاً",
    panelHint: "الإدارة متاحة في التطبيق والويب.<br/>التطبيق: علامة O صغيرة في حسابي → دخول الموظفين → لوحة الجوال.<br/>الويب: زر «لوحة الإدارة ويب» أعلاه → admin.obicgp.com.<br/>المشرف الأعلى يرى محادثات الموظفين؛ الموظف لا يضيف عملاء كأصدقاء.",
    panelCredit: "تصميم وتطوير: علي",
    modeApp: "تطبيق العميل",
    modeWeb: "لوحة الإدارة ويب",
    adminDualHint: "الإدارة: في التطبيق (دخول الموظفين) وعلى الويب (لوحة الإدارة) — مشرف أعلى / موظف",
    dualAccessTitle: "وصول الإدارة — تطبيق + ويب",
    dualAccessBody: "الموظفون والمشرفون يدخلون من التطبيق (جوال) أو من لوحة الويب. بدّل الدور أدناه لترى فرق الصلاحيات.",
    dualPathApp: "التطبيق",
    dualPathAppDesc: "دخول الموظفين → لوحة الجوال",
    dualPathWeb: "الويب",
    dualPathWebDesc: "لوحة إدارة سطح المكتب",
    staffEntryHint: "دخول الموظفين · التطبيق والجوال · ليس للعملاء",
    webAccessNote: "لوحة الويب · نفس الأدوار: مشرف أعلى / موظف · متاحة أيضاً من التطبيق",
    phoneCaption: "آيفون · العميل + إدارة الموظفين (تطبيق)",
    webCaption: "لوحة إدارة سطح المكتب · مشرف أعلى / موظف (ويب)",
    home: "الرئيسية",
    services: "الخدمات",
    messages: "الرسائل",
    orders: "الطلبات",
    me: "حسابي",
    moments: "اللحظات",
    searchPh: "ابحث عن تأشيرات، فنادق، رحلات VIP…",
    brandTag: "الصين · أعمال · سفر",
    featured: "مميز",
    vipTrip: "رحلة VIP إلى الصين",
    vipTripDesc: "استقبال من المطار · فنادق · زيارات مصانع · مدير مخصص",
    bookPkg: "احجز الباقة ←",
    fastTrack: "مسار سريع",
    visaExpress: "تأشيرة سريعة",
    visaExpressDesc: "دعم تأشيرات العمل والسياحة مع قائمة مستندات ومستشار",
    from120: "من 120$ ←",
    setup: "تهيئة",
    openBank: "فتح حساب بنكي",
    openBankDesc: "فتح حساب محلي بإرشاد وتنسيق مع الفرع",
    startReq: "ابدأ الطلب ←",
    topServices: "أبرز الخدمات",
    seeAll: "الكل",
    recommended: "موصى به",
    allServices: "كل الخدمات",
    service: "الخدمة",
    official: "رسمي من OBIC",
    included: "ما يشمله",
    advisor: "مستشار مخصص",
    advisorDesc: "يُعيَّن بعد تقديم الطلب",
    checklist: "قائمة المستندات",
    checklistDesc: "خطوات واضحة في طلبك",
    statusUpdates: "تحديثات الحالة",
    statusUpdatesDesc: "تابع التقدم في الطلبات",
    requestSvc: "اطلب هذه الخدمة",
    chatSupport: "محادثة الدعم",
    request: "طلب",
    prefBranch: "الفرع المفضل",
    fullName: "الاسم الكامل",
    yourName: "اسمك",
    phoneLabel: "الهاتف (+رمز الدولة)",
    email: "البريد الإلكتروني",
    notes: "ملاحظات",
    notesPh: "التواريخ، الأهداف، المستندات...",
    submitOrder: "إرسال الطلب",
    orderSubmitted: "تم إرسال الطلب (نموذج)",
    inProgress: "قيد التنفيذ",
    submitted: "مُقدَّم",
    completed: "مكتمل",
    timeline: "الجدول الزمني",
    msgAdvisor: "راسل المستشار",
    online: "متصل · دعم OBIC",
    today: "اليوم",
    lilyHello: "مرحباً! أنا ليلي من فريق التأشيرات في OBIC. كيف أساعدك؟",
    needVisa: "أحتاج تأشيرة عمل للشهر القادم.",
    uploadPass: "ممتاز — يرجى رفع صورة جواز السفر. أرسلت أيضاً قائمة المستندات.",
    photo: "صورة",
    file: "ملف",
    demoCall: "مكالمة تجريبية",
    send: "إرسال",
    messageLily: "رسالة إلى ليلي...",
    voiceCall: "مكالمة صوتية",
    videoCall: "مكالمة فيديو",
    mute: "كتم",
    speaker: "مكبّر",
    end: "إنهاء",
    you: "أنت",
    decline: "رفض",
    accept: "قبول",
    voiceOnly: "الرد بالصوت فقط",
    incomingVideo: "مكالمة فيديو واردة…",
    guest: "زائر",
    signInHint: "سجّل الدخول بالبريد أو الهاتف",
    login: "تسجيل الدخول",
    register: "إنشاء حساب",
    wallet: "المحفظة",
    coupons: "قسائم",
    favorites: "المفضلة",
    myOrders: "طلباتي",
    myDocs: "مستنداتي",
    branch: "الفرع",
    language: "اللغة",
    aboutObic: "عن OBIC",
    support: "الدعم",
    staff: "موظفون",
    welcomeBack: "مرحباً بعودتك — بريد أو هاتف",
    password: "كلمة المرور",
    createAccount: "إنشاء حساب",
    guestBrowse: "التصفح كزائر متاح من الرئيسية",
    registerWith: "سجّل بالبريد أو الهاتف",
    agree: "أوافق على اتفاقية المستخدم وسياسة الخصوصية",
    accountCreated: "تم إنشاء الحساب (نموذج)",
    loggedIn: "تم تسجيل الدخول (نموذج)",
    search: "بحث",
    hotSearches: "بحث شائع",
    aboutTitle: "عن OBIC",
    aboutDesc: "خدمات مؤسسية عبر الصين وما بعدها — تأشيرات، بنوك، سفر، تأسيس شركات، VIP.",
    branches: "الفروع",
    website: "الموقع",
    contact: "التواصل",
    supportChat: "الدعم عبر المحادثة داخل التطبيق",
    aboutFooter: "© 2026 OBIC · نموذج سري · تصميم وتطوير: علي",
    staffLogin: "دخول الموظفين",
    staffOnly: "للموظفين والمشرفين فقط · ليس زر عميل",
    staffPassword: "كلمة مرور الموظف",
    demoPickRole: "تجريبي: اختر الدور ثم ادخل",
    superAdmin: "مشرف أعلى",
    employee: "موظف",
    enterAdmin: "دخول تطبيق الإدارة",
    openAdminWeb: "فتح لوحة الإدارة ويب ←",
    adminApp: "إدارة OBIC",
    mobileStaff: "وضع الموظف على الجوال · ييوو",
    viewingSuper: "عرض كمشرف أعلى",
    viewingEmp: "عرض كموظف",
    openOrders: "طلبات مفتوحة",
    unreadChats: "محادثات غير مقروءة",
    staffCount: "موظفون",
    assigned: "مُسندة",
    quickActions: "إجراءات سريعة",
    modules: "الوحدات",
    assignedOrders: "الطلبات المسندة",
    customerChats: "محادثات العملاء",
    staffPriv: "الموظفون والصلاحيات",
    systemSettings: "إعدادات النظام",
    openWeb: "فتح لوحة الإدارة ويب",
    exitCustomer: "الخروج إلى تطبيق العميل",
    locked: "مقفل",
    superOnly: "للمشرف الأعلى فقط",
    empCannotPromote: "لا يمكن للموظفين ترقية الآخرين أو تعديل الصلاحيات.",
    backDash: "العودة للوحة",
    signedBy: "موقَّع / معتمد من",
    permMatrix: "مصفوفة الصلاحيات",
    capability: "القدرة",
    ordersChat: "الطلبات والمحادثة",
    assignedCust: "العملاء المسندون",
    promoteStaff: "ترقية الموظفين",
    grantPriv: "منح الصلاحيات",
    team: "الفريق",
    promote: "ترقية",
    grant: "منح",
    inviteStaff: "الموافقة / دعوة موظف",
    adminOrders: "طلبات الإدارة",
    allBranches: "كل الفروع · عرض المشرف الأعلى",
    assignedYou: "المسندة إليك · عرض الموظف",
    opsDash: "لوحة العمليات",
    desktopAdmin: "لوحة إدارة سطح المكتب",
    customers: "عملاء",
    activeChats: "محادثات نشطة",
    staffSeats: "مقاعد الموظفين",
    liveOrders: "طلبات مباشرة",
    privileges: "الصلاحيات",
    canPromote: "يمكنك ترقية الموظفين ومنح الوحدات.",
    empLocked: "عرض موظف — ترقية الموظفين مقفلة.",
    manageStaff: "إدارة الموظفين",
    viewRoster: "عرض القائمة المحدودة",
    staffMgmt: "إدارة الموظفين",
    designate: "تعيين · ترقية · منح صلاحيات · توقيع المشرف الأعلى",
    empCannot: "دور الموظف لا يستطيع ترقية الآخرين أو تعديل مصفوفة الصلاحيات.",
    signBanner: "الإجراءات تتطلب موافقة المشرف الأعلى · «موقَّع من المشرف الأعلى»",
    approveSign: "الموافقة على الموظف · توقيع",
    askCommon: "اسأل عن الأسئلة الشائعة",
    aiWelcome: "تأشيرة، بنك، تأسيس شركة، VIP، فنادق، رحلات، منح، ساعات الفروع، أو تتبع الطلب — اضغط اقتراحاً أو اكتب.",
    askAi: "اسأل OBIC AI…",
    askSomething: "اسأل OBIC AI شيئاً",
    emailTab: "البريد",
    phoneTab: "الهاتف",
    mobile: "الجوال (+رمز الدولة)",
    smsCode: "رمز الرسائل",
    emailCode: "رمز البريد",
    sendCode: "إرسال",
    typeMsg: "اكتب رسالة أولاً",
    sent: "تم الإرسال",
    imgAttached: "تم إرفاق صورة (نموذج)",
    fileAttached: "تم إرفاق ملف (نموذج)",
    muted: "مكتوم",
    unmuted: "غير مكتوم",
    speakerOn: "مكبّر مفعّل",
    earpiece: "سماعة الأذن",
    callEnded: "انتهت المكالمة",
    declined: "مرفوض",
    camFlip: "تم قلب الكاميرا (نموذج)",
    speakerTog: "تم تبديل المكبّر",
    smsSent: "تم إرسال الرمز (نموذج)",
    emailSent: "تم إرسال رمز البريد (نموذج)",
    staffIn: "تم دخول الموظف",
    restricted: "مقيّد للموظف",
    settingsProto: "إعدادات النظام (نموذج)",
    promoted: "تمت الترقية (نموذج)",
    privUpdated: "تم تحديث الصلاحيات",
    inviteSent: "تم إرسال الدعوة (نموذج)",
    promotedAdmin: "تمت الترقية إلى مشرف",
    privGranted: "تم منح الصلاحيات",
    staffApproved: "تمت الموافقة والتوقيع",
    // Moments / friends / notifications / oversight
    momentsTitle: "اللحظات",
    postMoment: "نشر",
    momentPh: "شارك لحظة نصية أو صورة…",
    adminPost: "منشور إدارة",
    userPost: "منشور مستخدم",
    noNotifyUser: "منشور المستخدم يظهر في اللحظات فقط — بلا إشعار",
    adminNotifyAll: "منشور الإدارة يُشعر كل المستخدمين",
    postedAdmin: "نُشر · تم إشعار الجميع",
    postedUser: "نُشر في اللحظات (بدون إشعار)",
    notifications: "الإشعارات",
    notifEmpty: "لا إشعارات جديدة",
    adminMomentNotif: "منشور جديد من إدارة OBIC",
    addFriend: "إضافة صديق",
    friends: "الأصدقاء",
    byPhone: "بالهاتف",
    byId: "بالمعرّف",
    byQr: "برمز QR",
    sendRequest: "إرسال طلب صداقة",
    friendReqSent: "تم إرسال طلب الصداقة",
    friendRequests: "طلبات الصداقة",
    acceptFriend: "قبول",
    rejectFriend: "رفض",
    friendAccepted: "تم قبول الصداقة",
    friendRejected: "تم رفض الطلب",
    scanQrDemo: "امسح رمز QR (تجريبي)",
    qrDemo: "رمز QR تجريبي",
    empBlockAdd: "الموظف لا يستطيع إضافة عملاء كأصدقاء أو جهات اتصال",
    empBlockHint: "إضافة العملاء متاحة للمشرف الأعلى أو للعملاء فقط",
    superCanAdd: "المشرف الأعلى يمكنه إضافة عملاء",
    custCanAdd: "يمكن للعملاء إضافة بعضهم البعض",
    oversight: "رقابة المحادثات",
    oversightTitle: "محادثات الموظفين",
    oversightDesc: "المشرف الأعلى فقط · إشراف على محادثات الموظفين مع العملاء",
    empPrivate: "الموظف لا يرى محادثات زملائه الخاصة",
    openTranscript: "فتح المحادثة",
    transcript: "نص المحادثة",
    supervision: "إشراف",
    contacts: "جهات الاتصال",
    addContact: "إضافة جهة اتصال",
    myFriends: "أصدقائي",
    pending: "قيد الانتظار",
    like: "إعجاب",
    comment: "تعليق",
    justNow: "الآن",
    hoursAgo: "س",
    markRead: "تعليم كمقروء",
    unreadBadge: "غير مقروء",
    designedBy: "تصميم وتطوير: علي",
    langAr: "العربية",
    langEn: "English",
    switchLang: "تبديل اللغة",
    chatOversight: "رقابة الدردشة",
    viewAs: "عرض كـ",
    customerAddOk: "أضف بالهاتف أو المعرف أو QR",
    demoId: "معرّف OBIC",
    idPh: "OB-CUS-2048",
    phonePh: "+966 5…",
    noOtherEmpChats: "لا تظهر محادثات الموظفين الآخرين",
    staffNavHome: "الرئيسية",
    staffNavOrders: "الطلبات",
    staffNavChat: "دردشة",
    staffNavStaff: "موظفون",
    staffNavOversight: "رقابة",
    momentsTab: "لحظات",
    postAsAdmin: "نشر كإدارة",
    postAsUser: "نشر كمستخدم",
    withImage: "مع صورة",
    textOnly: "نص فقط",
  },
  en: {
    panelMuted: "Premium UX prototype",
    panelSub: "3D app · OBIC AI · Staff · Arabic-first (switch to EN)",
    panelHint: "Admin is available in the app AND on the web.<br/>App: tiny O mark on Me → Staff Login → mobile admin dashboard.<br/>Web: tap «Admin Web» above → admin.obicgp.com desktop panel.<br/>Super Admin sees employee chats; employees cannot add customers as friends.",
    panelCredit: "Designed & developed by Ali",
    modeApp: "Customer App",
    modeWeb: "Admin Web",
    adminDualHint: "Admin: in the app (Staff Login) and on the web (Admin Web) — Super Admin / Employee",
    dualAccessTitle: "Admin access — App + Web",
    dualAccessBody: "Staff & Super Admins enter from the mobile app or the desktop web panel. Toggle role below to see privilege differences.",
    dualPathApp: "App",
    dualPathAppDesc: "Staff Login → mobile dashboard",
    dualPathWeb: "Web",
    dualPathWebDesc: "Desktop Admin Web panel",
    staffEntryHint: "Staff entry · app + mobile · not for customers",
    webAccessNote: "Admin Web · same roles: Super Admin / Employee · also reachable from the app",
    phoneCaption: "iPhone · Customer + Staff Admin (App)",
    webCaption: "Desktop Admin · Super Admin / Employee (Web)",
    home: "Home",
    services: "Services",
    messages: "Messages",
    orders: "Orders",
    me: "Me",
    moments: "Moments",
    searchPh: "Search visas, hotels, VIP trips…",
    brandTag: "China · Business · Travel",
    featured: "Featured",
    vipTrip: "VIP China Trip",
    vipTripDesc: "Airport pickup · Hotels · Factory visits · One dedicated manager",
    bookPkg: "Book package →",
    fastTrack: "Fast track",
    visaExpress: "Visa Express",
    visaExpressDesc: "Business & tourist visa support with checklist and advisor",
    from120: "From $120 →",
    setup: "Setup",
    openBank: "Open Bank Account",
    openBankDesc: "Guided local account opening with branch coordination",
    startReq: "Start request →",
    topServices: "Top services",
    seeAll: "See all",
    recommended: "Recommended",
    allServices: "All Services",
    service: "Service",
    official: "OBIC Official",
    included: "What's included",
    advisor: "Dedicated advisor",
    advisorDesc: "Assigned after you submit",
    checklist: "Document checklist",
    checklistDesc: "Clear steps in your order",
    statusUpdates: "Status updates",
    statusUpdatesDesc: "Track progress in Orders",
    requestSvc: "Request this service",
    chatSupport: "Chat with support",
    request: "Request",
    prefBranch: "Preferred branch",
    fullName: "Full name",
    yourName: "Your name",
    phoneLabel: "Phone (+country code)",
    email: "Email",
    notes: "Notes",
    notesPh: "Dates, goals, documents...",
    submitOrder: "Submit order",
    orderSubmitted: "Order submitted (prototype)",
    inProgress: "In progress",
    submitted: "Submitted",
    completed: "Completed",
    timeline: "Timeline",
    msgAdvisor: "Message advisor",
    online: "Online · OBIC Support",
    today: "Today",
    lilyHello: "Hello! I'm Lily from OBIC Visa team. How can I help?",
    needVisa: "I need a business visa for next month.",
    uploadPass: "Great — please upload your passport scan. I also sent the checklist.",
    photo: "Photo",
    file: "File",
    demoCall: "Demo call",
    send: "Send",
    messageLily: "Message Lily...",
    voiceCall: "Voice call",
    videoCall: "Video call",
    mute: "Mute",
    speaker: "Speaker",
    end: "End",
    you: "You",
    decline: "Decline",
    accept: "Accept",
    voiceOnly: "Answer with voice only",
    incomingVideo: "Incoming video call…",
    guest: "Guest",
    signInHint: "Sign in with email or phone",
    login: "Login",
    register: "Register",
    wallet: "Wallet",
    coupons: "Coupons",
    favorites: "Favorites",
    myOrders: "My Orders",
    myDocs: "My Documents",
    branch: "Branch",
    language: "Language",
    aboutObic: "About OBIC",
    support: "Support",
    staff: "Staff",
    welcomeBack: "Welcome back — email or phone",
    password: "Password",
    createAccount: "Create account",
    guestBrowse: "Guest browse stays available from Home",
    registerWith: "Register with email or phone",
    agree: "I agree to User Agreement & Privacy Policy",
    accountCreated: "Account created (prototype)",
    loggedIn: "Logged in (prototype)",
    search: "Search",
    hotSearches: "Hot searches",
    aboutTitle: "About OBIC",
    aboutDesc: "Corporate services across China & beyond — visas, banking, travel, company setup, VIP.",
    branches: "Branches",
    website: "Website",
    contact: "Contact",
    supportChat: "Support via in-app chat",
    aboutFooter: "© 2026 OBIC · Confidential prototype · Designed & developed by Ali",
    staffLogin: "Staff Login",
    staffOnly: "Employees & admins only · not a customer CTA",
    staffPassword: "Staff password",
    demoPickRole: "Demo: pick a role, then enter",
    superAdmin: "Super Admin",
    employee: "Employee",
    enterAdmin: "Enter Admin App",
    openAdminWeb: "Open Admin Web instead →",
    adminApp: "OBIC Admin",
    mobileStaff: "Mobile staff mode · Yiwu",
    viewingSuper: "Viewing as Super Admin",
    viewingEmp: "Viewing as Employee",
    openOrders: "Open orders",
    unreadChats: "Unread chats",
    staffCount: "Staff",
    assigned: "Assigned",
    quickActions: "Quick actions",
    modules: "Modules",
    assignedOrders: "Assigned orders",
    customerChats: "Customer chats",
    staffPriv: "Staff & privileges",
    systemSettings: "System settings",
    openWeb: "Open Admin Web",
    exitCustomer: "Exit to customer app",
    locked: "Locked",
    superOnly: "Super Admin only",
    empCannotPromote: "Employees cannot promote staff or edit privileges.",
    backDash: "Back to dashboard",
    signedBy: "Signed / designated by",
    permMatrix: "Permission matrix",
    capability: "Capability",
    ordersChat: "Orders & chat",
    assignedCust: "Assigned customers",
    promoteStaff: "Promote staff",
    grantPriv: "Grant privileges",
    team: "Team",
    promote: "Promote",
    grant: "Grant",
    inviteStaff: "Approve / invite staff",
    adminOrders: "Admin Orders",
    allBranches: "All branches · Super Admin view",
    assignedYou: "Assigned to you · Employee view",
    opsDash: "Operations dashboard",
    desktopAdmin: "Desktop admin panel",
    customers: "Customers",
    activeChats: "Active chats",
    staffSeats: "Staff seats",
    liveOrders: "Live orders",
    privileges: "Privileges",
    canPromote: "You can promote employees and grant modules.",
    empLocked: "Employee view — staff promotion locked.",
    manageStaff: "Manage staff",
    viewRoster: "View limited roster",
    staffMgmt: "Staff management",
    designate: "Designate · promote · grant privileges · Super Admin signature",
    empCannot: "Employee role cannot promote others or edit the permission matrix.",
    signBanner: "Actions require Super Admin approval · “Signed by Super Admin”",
    approveSign: "Approve staff · Sign",
    askCommon: "Ask anything common",
    aiWelcome: "Visa, bank, company setup, VIP, hotels, flights, scholarships, branch hours, or track order — tap a chip or type.",
    askAi: "Ask OBIC AI…",
    askSomething: "Ask OBIC AI something",
    emailTab: "Email",
    phoneTab: "Phone",
    mobile: "Mobile (+country code)",
    smsCode: "SMS code",
    emailCode: "Email code",
    sendCode: "Send",
    typeMsg: "Type a message first",
    sent: "Sent",
    imgAttached: "Image attached (prototype)",
    fileAttached: "File attached (prototype)",
    muted: "Muted",
    unmuted: "Unmuted",
    speakerOn: "Speaker on",
    earpiece: "Earpiece",
    callEnded: "Call ended",
    declined: "Declined",
    camFlip: "Camera flipped (prototype)",
    speakerTog: "Speaker toggled",
    smsSent: "SMS sent (prototype)",
    emailSent: "Email code sent (prototype)",
    staffIn: "Staff signed in",
    restricted: "Restricted for Employee",
    settingsProto: "System settings (prototype)",
    promoted: "Promoted (prototype)",
    privUpdated: "Privileges updated",
    inviteSent: "Invite sent (prototype)",
    promotedAdmin: "Promoted to Admin",
    privGranted: "Privileges granted",
    staffApproved: "Staff approved & signed",
    momentsTitle: "Moments",
    postMoment: "Post",
    momentPh: "Share text or an image…",
    adminPost: "Admin post",
    userPost: "User post",
    noNotifyUser: "User posts appear in Moments only — no notification",
    adminNotifyAll: "Admin posts notify all users",
    postedAdmin: "Posted · everyone notified",
    postedUser: "Posted to Moments (no notify)",
    notifications: "Notifications",
    notifEmpty: "No new notifications",
    adminMomentNotif: "New post from OBIC Admin",
    addFriend: "Add friend",
    friends: "Friends",
    byPhone: "By phone",
    byId: "By ID",
    byQr: "By QR",
    sendRequest: "Send friend request",
    friendReqSent: "Friend request sent",
    friendRequests: "Friend requests",
    acceptFriend: "Accept",
    rejectFriend: "Reject",
    friendAccepted: "Friend accepted",
    friendRejected: "Request rejected",
    scanQrDemo: "Scan QR (demo)",
    qrDemo: "Demo QR code",
    empBlockAdd: "Employees cannot add customers as friends/contacts",
    empBlockHint: "Only Super Admin or customers can add customers",
    superCanAdd: "Super Admin can add customers",
    custCanAdd: "Customers can add each other",
    oversight: "Chat oversight",
    oversightTitle: "Employee conversations",
    oversightDesc: "Super Admin only · supervise employee–customer chats",
    empPrivate: "Employees cannot see other employees’ private chats",
    openTranscript: "Open transcript",
    transcript: "Transcript",
    supervision: "Supervision",
    contacts: "Contacts",
    addContact: "Add contact",
    myFriends: "My friends",
    pending: "Pending",
    like: "Like",
    comment: "Comment",
    justNow: "Just now",
    hoursAgo: "h",
    markRead: "Mark read",
    unreadBadge: "Unread",
    designedBy: "Designed & developed by Ali",
    langAr: "العربية",
    langEn: "English",
    switchLang: "Language",
    chatOversight: "Chat oversight",
    viewAs: "View as",
    customerAddOk: "Add by phone, ID, or QR",
    demoId: "OBIC ID",
    idPh: "OB-CUS-2048",
    phonePh: "+966 5…",
    noOtherEmpChats: "Other employees’ chats are hidden",
    staffNavHome: "Home",
    staffNavOrders: "Orders",
    staffNavChat: "Chat",
    staffNavStaff: "Staff",
    staffNavOversight: "Watch",
    momentsTab: "Moments",
    postAsAdmin: "Post as Admin",
    postAsUser: "Post as User",
    withImage: "With image",
    textOnly: "Text only",
  },
};

const SERVICE_I18N = {
  ar: {
    hotels: { name: "فنادق", desc: "احجز فنادق في الصين لرحلات العمل.", price: "من 45$/ليلة" },
    flights: { name: "رحلات", desc: "مساعدة حجز تذاكر الصين.", price: "مساعدة من 20$" },
    visa: { name: "تأشيرة", desc: "دعم تأشيرات العمل والسياحة للصين.", price: "من 120$" },
    bank: { name: "حساب بنكي", desc: "فتح حساب محلي بإرشاد.", price: "من 299$" },
    vip: { name: "خدمة VIP", desc: "برنامج كامل: استقبال، فنادق، مصانع.", price: "عرض مخصص" },
    legal: { name: "خدمات قانونية", desc: "عقود وامتثال ودعم قانوني.", price: "من 199$" },
    company: { name: "تسجيل شركة", desc: "سجّل شركتك في الصين.", price: "من 499$" },
    scholarship: { name: "منح دراسية", desc: "دعم طلبات المنح.", price: "استشارة مجانية" },
    transfer: { name: "تحويل أموال", desc: "طلب مساعدة للتحويلات (معلومات V1).", price: "طلب فقط" },
    ads: { name: "إعلانات", desc: "دعم العلامة والإعلانات في الصين.", price: "من 150$" },
    biz: { name: "خدمات أعمال", desc: "توريد واجتماعات ودعم تشغيلي.", price: "من 99$" },
    hr: { name: "موارد بشرية", desc: "توظيف وتنسيق الموارد البشرية.", price: "من 180$" },
    insurance: { name: "تأمين", desc: "خطط حماية وتأمين.", price: "من 50$" },
    expand: { name: "توسع دولي", desc: "استشارات دخول الأسواق.", price: "مخصص" },
    tech: { name: "دعم تقني", desc: "باقات دعم تقني وتشغيلي.", price: "من 80$" },
    plan: { name: "تخطيط أعمال", desc: "ورش تخطيط الأعمال.", price: "من 220$" },
  },
  en: {
    hotels: { name: "Hotels", desc: "Book hotels across China for business trips.", price: "From $45/night" },
    flights: { name: "Flights", desc: "Flight booking assistance for China routes.", price: "Assist from $20" },
    visa: { name: "Visa", desc: "China business / tourist visa support.", price: "From $120" },
    bank: { name: "Bank Account", desc: "Open a local bank account with guidance.", price: "From $299" },
    vip: { name: "VIP Service", desc: "Full VIP itinerary, pickup, factory visits.", price: "Custom quote" },
    legal: { name: "Legal Services", desc: "Contracts, compliance, and legal support.", price: "From $199" },
    company: { name: "Company Registration", desc: "Register your company in China.", price: "From $499" },
    scholarship: { name: "Scholarships", desc: "Scholarship application support.", price: "Consult free" },
    transfer: { name: "Money Transfer", desc: "Request assistance for transfers (info V1).", price: "Request only" },
    ads: { name: "Advertisements", desc: "Brand & ads support in China.", price: "From $150" },
    biz: { name: "Business Services", desc: "Sourcing, meetings, and ops support.", price: "From $99" },
    hr: { name: "Human Resources", desc: "Hiring and HR coordination.", price: "From $180" },
    insurance: { name: "Insurance", desc: "Insurance & protection plans.", price: "From $50" },
    expand: { name: "International Expansion", desc: "Go-to-market and expansion advisory.", price: "Custom" },
    tech: { name: "Technical Support", desc: "Tech & ops support packages.", price: "From $80" },
    plan: { name: "Business Planning", desc: "Business planning workshops.", price: "From $220" },
  },
};

const SERVICE_META = [
  { id: "hotels", icon: "hotel", color: "hotels" },
  { id: "flights", icon: "flight", color: "flights" },
  { id: "visa", icon: "visa", color: "visa" },
  { id: "bank", icon: "bank", color: "bank" },
  { id: "vip", icon: "vip", color: "vip" },
  { id: "legal", icon: "legal" },
  { id: "company", icon: "company" },
  { id: "scholarship", icon: "scholarship" },
  { id: "transfer", icon: "transfer" },
  { id: "ads", icon: "ads" },
  { id: "biz", icon: "biz" },
  { id: "hr", icon: "hr" },
  { id: "insurance", icon: "insurance" },
  { id: "expand", icon: "expand" },
  { id: "tech", icon: "tech" },
  { id: "plan", icon: "plan" },
];

function t(key) {
  const pack = I18N[state.lang] || I18N.ar;
  return pack[key] || I18N.en[key] || key;
}

function SERVICES() {
  const loc = SERVICE_I18N[state.lang] || SERVICE_I18N.ar;
  return SERVICE_META.map(m => ({ ...m, ...(loc[m.id] || {}) }));
}

const AI_SUGGESTIONS_I18N = {
  ar: ["مساعدة تأشيرة", "حساب بنكي", "تسجيل شركة", "رحلة VIP", "حجز فندق", "مساعدة رحلة", "منحة دراسية", "ساعات الفرع", "تتبع طلبي"],
  en: ["Visa help", "Bank account", "Company registration", "VIP trip", "Hotel booking", "Flight assist", "Scholarship", "Branch hours", "Track my order"],
};

const AI_REPLIES_I18N = {
  ar: [
    { keys: ["تأشيرة", "visa"], text: "لتأشيرات الصين، يقدّم OBIC إرشاداً لتأشيرات العمل والسياحة مع قائمة مستندات ومستشار. البداية عادة من 120$. اضغط «تأشيرة» من الرئيسية أو اطلب «فتح تأشيرة»." },
    { keys: ["بنك", "bank"], text: "نساعد في فتح حساب بنكي محلي مع تنسيق الفرع (ييوو وقوانغتشو). الباقة الإرشادية من 299$. يؤكد المستشار الهويات المطلوبة بعد الطلب." },
    { keys: ["شركة", "company"], text: "تسجيل الشركة في الصين يبدأ عادة من 499$. يشمل فحص الاسم وخطوات التسجيل والتنسيق مع الفرع. ابدأ من تسجيل شركة → طلب." },
    { keys: ["vip", "VIP"], text: "خدمة VIP برنامج كامل: استقبال، فنادق، زيارات مصانع، ومدير مخصص. التسعير مخصص — اطلب VIP واذكر التواريخ والمدن." },
    { keys: ["فندق", "hotel"], text: "حجز الفنادق في الصين لرحلات العمل يبدأ من حوالي 45$/ليلة. شارك المدينة والتواريخ في طلب الفنادق أو عبر الدعم." },
    { keys: ["رحلة", "flight"], text: "مساعدة تذاكر الصين متاحة — من 20$. أخبرنا بالمدن ونافذة السفر في رحلات → طلب." },
    { keys: ["منحة", "scholarship"], text: "دعم المنح يبدأ باستشارة مجانية. نحدد البرامج والمستندات — افتح المنح أو اسأل المستشار." },
    { keys: ["فرع", "ساعات", "ييوو", "branch"], text: "فروع OBIC: ييوو · قوانغتشو · اليمن · فوشان · هانغتشو · هاينان. ساعات تجريبية الإثنين–السبت 09:00–18:00. اختر فرعاً في النموذج لتعيين أسرع." },
    { keys: ["تتبع", "طلب", "track", "order"], text: "تابع الطلبات من «الطلبات». تجريبي: تأشيرة #OB-1042 قيد التنفيذ — المستشارة ليلي، بانتظار صورة الجواز." },
  ],
  en: [
    { keys: ["visa", "business visa", "tourist visa"], text: "For China visas, OBIC guides business & tourist applications with a document checklist and a dedicated advisor. Typical start: from $120. Tap Visa on Home or say “open visa” to request." },
    { keys: ["bank", "bank account", "open account", "banking"], text: "We help open a local bank account with branch coordination (Yiwu & Guangzhou). Guided package from $299. An advisor will confirm required IDs after you submit a request." },
    { keys: ["company", "company registration", "register company", "wfoe"], text: "Company registration in China usually starts from $499. We cover name check, filing steps, and branch liaison. Start via Company Registration → Request order." },
    { keys: ["vip", "vip trip", "vip service", "itinerary"], text: "VIP Service is a full itinerary: airport pickup, hotels, factory visits, and one dedicated manager. Pricing is custom — request VIP and note your dates/cities." },
    { keys: ["hotel", "hotels", "stay", "accommodation"], text: "Hotel booking across China for business trips starts from about $45/night. Share city + dates in a Hotels request or chat with support." },
    { keys: ["flight", "flights", "air ticket", "airfare"], text: "Flight assistance for China routes is available — assist from $20. Tell us cities and travel window in Flights → Request." },
    { keys: ["scholarship", "scholarships", "study", "university"], text: "Scholarship application support is consult-free to start. We’ll map programs and documents — open Scholarships or ask an advisor in chat." },
    { keys: ["branch", "hours", "opening", "open time", "yiwu", "guangzhou"], text: "OBIC branches: Yiwu · Guangzhou · Yemen · Foshan · Hangzhou · Hainan. Demo hours Mon–Sat 09:00–18:00 local. Prefer a branch in your order form for faster assignment." },
    { keys: ["track", "order", "status", "tracking", "ob-1042", "progress"], text: "You can track orders under Orders. Demo: Visa #OB-1042 is In progress — advisor Lily assigned, awaiting passport scan. Open Orders → timeline for steps." },
  ],
};

function matchAiReply(text) {
  const q = (text || "").toLowerCase();
  const rows = AI_REPLIES_I18N[state.lang] || AI_REPLIES_I18N.en;
  for (const row of rows) {
    if (row.keys.some(k => q.includes(k.toLowerCase()))) return row.text;
  }
  return state.lang === "ar"
    ? "يمكنني المساعدة في التأشيرات والحسابات البنكية وتسجيل الشركات ورحلات VIP والفنادق والرحلات والمنح وساعات الفروع وتتبع الطلبات. جرّب اقتراحاً أدناه — أو تحدّث مع مستشار بشري."
    : "I can help with visas, bank accounts, company registration, VIP trips, hotels, flights, scholarships, branch hours, and order tracking. Try a suggestion chip below — or chat with a human advisor anytime.";
}

function screenLabels() {
  const ar = state.lang === "ar";
  return {
    app: [
      { id: "home", label: ar ? "01 الرئيسية" : "01 Home" },
      { id: "services", label: ar ? "02 الخدمات" : "02 Services" },
      { id: "detail", label: ar ? "03 تفاصيل الخدمة" : "03 Service Detail" },
      { id: "request", label: ar ? "04 طلب خدمة" : "04 Request Order" },
      { id: "orders", label: ar ? "05 الطلبات" : "05 Orders" },
      { id: "orderDetail", label: ar ? "06 مسار الطلب" : "06 Order Timeline" },
      { id: "messages", label: ar ? "07 الرسائل" : "07 Messages" },
      { id: "chat", label: ar ? "08 دردشة + ملفات" : "08 Chat + Files" },
      { id: "voiceCall", label: ar ? "09 مكالمة صوتية" : "09 Voice Call" },
      { id: "videoCall", label: ar ? "10 مكالمة فيديو" : "10 Video Call" },
      { id: "incomingCall", label: ar ? "11 مكالمة واردة" : "11 Incoming Call" },
      { id: "moments", label: ar ? "12 اللحظات" : "12 Moments" },
      { id: "notifications", label: ar ? "13 الإشعارات" : "13 Notifications" },
      { id: "addFriend", label: ar ? "14 إضافة صديق" : "14 Add Friend" },
      { id: "friends", label: ar ? "15 الأصدقاء" : "15 Friends" },
      { id: "me", label: ar ? "16 حسابي" : "16 Me / Profile" },
      { id: "login", label: ar ? "17 تسجيل الدخول" : "17 Login" },
      { id: "register", label: ar ? "18 إنشاء حساب" : "18 Register" },
      { id: "search", label: ar ? "19 بحث" : "19 Search" },
      { id: "about", label: ar ? "20 عن OBIC" : "20 About OBIC" },
      { id: "aiChat", label: ar ? "21 مساعد OBIC AI" : "21 OBIC AI Assist" },
      { id: "staffLogin", label: ar ? "22 دخول الموظفين" : "22 Staff Login" },
      { id: "adminDash", label: ar ? "23 لوحة الإدارة" : "23 Admin App Dashboard" },
      { id: "adminStaff", label: ar ? "24 الموظفون والصلاحيات" : "24 Staff & Privileges" },
      { id: "adminOrders", label: ar ? "25 طلبات الإدارة" : "25 Admin Orders" },
      { id: "adminOversight", label: ar ? "26 رقابة محادثات الموظفين" : "26 Chat Oversight" },
      { id: "adminTranscript", label: ar ? "27 نص محادثة موظف" : "27 Employee Transcript" },
      { id: "adminAddContact", label: ar ? "28 إضافة جهة اتصال" : "28 Admin Add Contact" },
    ],
    web: [
      { id: "adminWebDash", label: ar ? "W1 لوحة الويب" : "W1 Admin Web Dashboard" },
      { id: "adminWebStaff", label: ar ? "W2 الموظفون والأدوار" : "W2 Web · Staff & Roles" },
      { id: "adminWebOversight", label: ar ? "W3 رقابة المحادثات" : "W3 Web · Chat Oversight" },
    ],
  };
}

let state = {
  mode: "app",
  screen: "home",
  lang: "ar",
  serviceId: "visa",
  toast: null,
  muted: false,
  speakerOn: true,
  callSec: 126,
  chatExtras: [],
  authTab: "email",
  staffRole: "super",
  staffLoggedIn: false,
  aiOpen: false,
  aiTyping: false,
  aiMessages: [],
  addFriendTab: "phone",
  oversightId: "lily-omar",
  momentDraft: "",
  postAs: "user",
  momentWithImage: false,
  moments: [
    { id: 1, author: "OBIC Admin", role: "admin", textAr: "ترقية خدمة التأشيرة السريعة هذا الأسبوع — تواصل مع مستشارك.", textEn: "Visa Express upgrade this week — contact your advisor.", time: "2h", hasImage: true, imageTheme: "visa", likes: 24 },
    { id: 2, author: "Omar", role: "user", textAr: "وصلت إلى ييوو — شكراً لفريق OBIC على التنسيق!", textEn: "Arrived in Yiwu — thanks OBIC team for the coordination!", time: "5h", hasImage: false, likes: 8 },
    { id: 3, author: "Nora", role: "user", textAr: "اكتمل فتح الحساب البنكي بسلاسة.", textEn: "Bank account opening completed smoothly.", time: "1d", hasImage: true, imageTheme: "bank", likes: 12 },
  ],
  notifications: [
    { id: 1, type: "admin_moment", titleAr: "منشور جديد من إدارة OBIC", titleEn: "New post from OBIC Admin", bodyAr: "ترقية خدمة التأشيرة السريعة هذا الأسبوع", bodyEn: "Visa Express upgrade this week", unread: true, time: "2h" },
  ],
  friendRequests: [
    { id: "fr1", name: "Hassan A.", idCode: "OB-CUS-3102", phone: "+966 55 100 200", status: "pending" },
    { id: "fr2", name: "Layla M.", idCode: "OB-CUS-2881", phone: "+86 138 0000 11", status: "pending" },
  ],
  friends: [
    { id: "f1", name: "Omar K.", idCode: "OB-CUS-1042", phone: "+967 777 111" },
    { id: "f2", name: "Sara N.", idCode: "OB-CUS-1201", phone: "+966 50 222 333" },
  ],
  employeeChats: [
    {
      id: "lily-omar",
      employee: "Lily Chen",
      customer: "Omar K.",
      service: "Visa",
      previewAr: "يرجى رفع صورة الجواز",
      previewEn: "Please upload passport scan",
      messages: [
        { side: "emp", textAr: "مرحباً عمر، أنا ليلي من فريق التأشيرات.", textEn: "Hi Omar, Lily from Visa team." },
        { side: "cus", textAr: "أحتاج تأشيرة عمل للشهر القادم.", textEn: "I need a business visa next month." },
        { side: "emp", textAr: "ممتاز — أرسل قائمة المستندات. ارفع صورة الجواز.", textEn: "Great — checklist sent. Please upload passport." },
      ],
    },
    {
      id: "ahmed-nora",
      employee: "Ahmed R.",
      customer: "Nora S.",
      service: "Bank",
      previewAr: "تم حجز موعد الفرع",
      previewEn: "Branch appointment booked",
      messages: [
        { side: "emp", textAr: "نورا، تم تنسيق موعد فتح الحساب في قوانغتشو.", textEn: "Nora, bank opening appointment set in Guangzhou." },
        { side: "cus", textAr: "شكراً أحمد، سأحضر المستندات غداً.", textEn: "Thanks Ahmed, I'll bring docs tomorrow." },
      ],
    },
    {
      id: "lily-vip",
      employee: "Lily Chen",
      customer: "VIP Client",
      service: "VIP",
      previewAr: "برنامج الزيارة جاهز",
      previewEn: "Visit itinerary ready",
      messages: [
        { side: "emp", textAr: "برنامج المصانع والاستقبال جاهز للمراجعة.", textEn: "Factory & pickup itinerary ready for review." },
        { side: "cus", textAr: "ممتاز، أكّد الفندق أيضاً.", textEn: "Great, confirm the hotel too." },
      ],
    },
  ],
};

const app = document.getElementById("app");
const adminWeb = document.getElementById("adminWeb");
const nav = document.getElementById("screenNav");
const phoneWrap = document.getElementById("phoneWrap");
const desktopWrap = document.getElementById("desktopWrap");

function isAr() { return state.lang === "ar"; }
function isSuper() { return state.staffRole === "super"; }
function unreadCount() { return state.notifications.filter(n => n.unread).length; }

function applyDir() {
  const ar = isAr();
  document.documentElement.lang = ar ? "ar" : "en";
  document.documentElement.dir = ar ? "rtl" : "ltr";
  document.body.classList.toggle("lang-ar", ar);
  document.body.classList.toggle("lang-en", !ar);
  document.body.dir = ar ? "rtl" : "ltr";
  const map = [
    ["panelMuted", "panelMuted"], ["panelSub", "panelSub"], ["panelHint", "panelHint"],
    ["panelCredit", "panelCredit"], ["modeAppBtn", "modeApp"], ["modeWebBtn", "modeWeb"],
    ["phoneCaption", "phoneCaption"], ["webCaption", "webCaption"],
    ["adminDualHint", "adminDualHint"],
  ];
  map.forEach(([id, key]) => {
    const el = document.getElementById(id);
    if (el) el.innerHTML = t(key);
  });
  document.querySelectorAll("#langToggle .lang-btn").forEach(btn => {
    btn.classList.toggle("active", btn.dataset.lang === state.lang);
  });
}

function setLang(lang) {
  state.lang = lang;
  applyDir();
  render();
}

function go(screen, extra = {}) {
  const webScreens = ["adminWebDash", "adminWebStaff", "adminWebOversight"];
  const nextMode = webScreens.includes(screen) ? "adminWeb" : (extra.mode || state.mode);
  const keepAi = screen === "aiChat" || extra.aiOpen === true;
  state = { ...state, screen, ...extra, mode: nextMode, toast: null, aiOpen: keepAi ? true : false };
  if (["adminDash", "adminStaff", "adminOrders", "adminOversight", "adminTranscript", "adminAddContact"].includes(screen)) {
    state.staffLoggedIn = true;
  }
  render();
}

function setMode(mode) {
  state.mode = mode;
  if (mode === "adminWeb" && !["adminWebDash", "adminWebStaff", "adminWebOversight"].includes(state.screen)) {
    state.screen = "adminWebDash";
  }
  if (mode === "app" && ["adminWebDash", "adminWebStaff", "adminWebOversight"].includes(state.screen)) {
    state.screen = state.staffLoggedIn ? "adminDash" : "home";
  }
  render();
}

function setAuthTab(tab) { state.authTab = tab; render(); }
function setAddFriendTab(tab) { state.addFriendTab = tab; render(); }

function setStaffRole(role) {
  state.staffRole = role;
  toast(role === "super" ? t("viewingSuper") : t("viewingEmp"));
  render();
}

function toast(msg) {
  state.toast = msg;
  render();
  setTimeout(() => { state.toast = null; render(); }, 1600);
}

function fmtTime(sec) {
  const m = String(Math.floor(sec / 60)).padStart(2, "0");
  const s = String(sec % 60).padStart(2, "0");
  return `${m}:${s}`;
}

function attachImage() {
  state.chatExtras = [...state.chatExtras, { type: "image", side: "me", label: "passport-scan.jpg" }];
  toast(t("imgAttached"));
  render();
}
function attachFile() {
  state.chatExtras = [...state.chatExtras, { type: "file", side: "me", name: "Invitation_Letter.pdf", size: "240 KB" }];
  toast(t("fileAttached"));
  render();
}
function sendChatText() {
  const el = document.getElementById("chatIn");
  const text = (el && el.value || "").trim();
  if (!text) { toast(t("typeMsg")); return; }
  state.chatExtras = [...state.chatExtras, { type: "text", side: "me", text }];
  toast(t("sent"));
  render();
}
function toggleMute() {
  state.muted = !state.muted;
  toast(state.muted ? t("muted") : t("unmuted"));
  render();
}
function toggleSpeaker() {
  state.speakerOn = !state.speakerOn;
  toast(state.speakerOn ? t("speakerOn") : t("earpiece"));
  render();
}

function openAi(fromScreen) {
  state.aiOpen = true;
  if (fromScreen) state.screen = fromScreen;
  render();
}
function closeAi() {
  state.aiOpen = false;
  if (state.screen === "aiChat") state.screen = "home";
  render();
}
function sendAiMessage(preset) {
  const el = document.getElementById("aiIn");
  const text = (preset || (el && el.value) || "").trim();
  if (!text) { toast(t("askSomething")); return; }
  state.aiMessages = [...state.aiMessages, { side: "user", text }];
  state.aiTyping = true;
  state.aiOpen = true;
  render();
  const reply = matchAiReply(text);
  setTimeout(() => {
    state.aiTyping = false;
    state.aiMessages = [...state.aiMessages, { side: "ai", text: reply }];
    render();
    const thread = document.getElementById("aiThread");
    if (thread) thread.scrollTop = thread.scrollHeight;
  }, 720);
}

function postMoment() {
  const el = document.getElementById("momentIn");
  const text = (el && el.value || "").trim() || (isAr() ? "منشور تجريبي" : "Demo post");
  const asAdmin = state.postAs === "admin";
  const post = {
    id: Date.now(),
    author: asAdmin ? "OBIC Admin" : (isAr() ? "أنت" : "You"),
    role: asAdmin ? "admin" : "user",
    textAr: text,
    textEn: text,
    time: t("justNow"),
    hasImage: state.momentWithImage,
    likes: 0,
  };
  state.moments = [post, ...state.moments];
  if (asAdmin) {
    state.notifications = [{
      id: Date.now(),
      type: "admin_moment",
      titleAr: t("adminMomentNotif"),
      titleEn: "New post from OBIC Admin",
      bodyAr: text,
      bodyEn: text,
      unread: true,
      time: t("justNow"),
    }, ...state.notifications];
    toast(t("postedAdmin"));
  } else {
    toast(t("postedUser"));
  }
  state.momentWithImage = false;
  render();
}

function markNotifsRead() {
  state.notifications = state.notifications.map(n => ({ ...n, unread: false }));
  toast(t("markRead"));
  render();
}

function sendFriendRequest() {
  if (state.staffLoggedIn && !isSuper() && ["adminAddContact", "adminDash"].includes(state.screen)) {
    toast(t("empBlockAdd"));
    return;
  }
  toast(t("friendReqSent"));
  state.friendRequests = [{
    id: "fr" + Date.now(),
    name: isAr() ? "عميل جديد" : "New customer",
    idCode: "OB-CUS-9999",
    phone: "+966 50 000 000",
    status: "pending",
  }, ...state.friendRequests];
  render();
}

function acceptFriend(id) {
  const fr = state.friendRequests.find(f => f.id === id);
  if (!fr) return;
  state.friendRequests = state.friendRequests.filter(f => f.id !== id);
  state.friends = [...state.friends, { id: "f" + Date.now(), name: fr.name, idCode: fr.idCode, phone: fr.phone }];
  toast(t("friendAccepted"));
  render();
}
function rejectFriend(id) {
  state.friendRequests = state.friendRequests.filter(f => f.id !== id);
  toast(t("friendRejected"));
  render();
}

function tryAdminAddContact() {
  if (!isSuper()) {
    toast(t("empBlockAdd"));
    return;
  }
  go("adminAddContact");
}

function ico(name) { return ICONS[name] || ICONS.biz; }
function svcById(id) { return SERVICES().find(s => s.id === id) || SERVICES()[2]; }
function colorOf(s) { return COLORS[s.color] || COLORS.default; }
function thumb(s, size = 50) {
  const c = colorOf(s);
  return `<div class="thumb" style="width:${size}px;height:${size}px;background:${c.bg};color:#fff">${ico(s.icon)}</div>`;
}
function softThumb(s) {
  const c = colorOf(s);
  return `<div class="thumb" style="background:${c.soft};color:${c.ink}">${ico(s.icon)}</div>`;
}
function notifBadge() {
  const n = unreadCount();
  return n > 0 ? `<span class="notif-badge">${n}</span>` : "";
}

function tabBar(active) {
  const tabs = [
    ["home", "home", t("home")],
    ["services", "grid", t("services")],
    ["moments", "moments", t("momentsTab")],
    ["messages", "msg", t("messages")],
    ["me", "me", t("me")],
  ];
  return `<nav class="tabbar">${tabs.map(([id, icon, lab]) =>
    `<button class="tab ${active === id ? "active" : ""}" onclick="go('${id}')"><span class="ti">${ico(icon)}</span>${lab}</button>`
  ).join("")}</nav>`;
}

function renderAiMessages() {
  return state.aiMessages.map(m =>
    m.side === "user"
      ? `<div class="chat-bubble user">${m.text}</div>`
      : `<div class="chat-bubble ai">${m.text}</div>`
  ).join("");
}

function renderAiPanel() {
  const chips = AI_SUGGESTIONS_I18N[state.lang] || AI_SUGGESTIONS_I18N.en;
  return `
  <div class="ai-panel" id="aiPanel">
    <div class="ai-panel-head">
      <div class="ai-panel-mark">${ico("ai")}</div>
      <div class="ai-panel-title"><h2>OBIC AI</h2><span>${t("askCommon")}</span></div>
      <button type="button" class="ai-close" onclick="closeAi()" aria-label="Close">✕</button>
    </div>
    <div class="ai-thread" id="aiThread">
      <div class="ai-welcome"><h3>${t("askCommon")}</h3><p>${t("aiWelcome")}</p></div>
      ${renderAiMessages()}
      ${state.aiTyping ? `<div class="ai-typing"><i></i><i></i><i></i></div>` : ""}
    </div>
    <div class="ai-chips">${chips.map(s =>
      `<button type="button" class="ai-chip" onclick="sendAiMessage('${s.replace(/'/g, "\\'")}')">${s}</button>`
    ).join("")}</div>
    <div class="ai-composer">
      <input id="aiIn" placeholder="${t("askAi")}" onkeydown="if(event.key==='Enter')sendAiMessage()" />
      <button class="btn btn-primary" style="padding:10px 16px;width:auto" onclick="sendAiMessage()">${t("send")}</button>
    </div>
  </div>`;
}

function renderAiFab() {
  const hideOn = ["voiceCall", "videoCall", "incomingCall", "aiChat"];
  if (state.aiOpen || hideOn.includes(state.screen) || state.mode === "adminWeb") return "";
  return `<button type="button" class="ai-fab" onclick="openAi()" title="OBIC AI" aria-label="OBIC AI"><span class="ai-fab-pulse"></span>${ico("ai")}</button>`;
}

function renderAiChatScreen() {
  const chips = AI_SUGGESTIONS_I18N[state.lang] || AI_SUGGESTIONS_I18N.en;
  return `
  <div class="page-header"><button class="back" onclick="closeAi()">←</button><h2>OBIC AI</h2></div>
  <div class="app-body" style="display:flex;flex-direction:column;padding:0">
    <div class="ai-thread" id="aiThread" style="flex:1">
      <div class="ai-welcome"><h3>OBIC AI</h3><p>${t("aiWelcome")}</p></div>
      ${renderAiMessages()}
      ${state.aiTyping ? `<div class="ai-typing"><i></i><i></i><i></i></div>` : ""}
    </div>
    <div class="ai-chips">${chips.map(s =>
      `<button type="button" class="ai-chip" onclick="sendAiMessage('${s.replace(/'/g, "\\'")}')">${s}</button>`
    ).join("")}</div>
    <div class="ai-composer">
      <input id="aiIn" placeholder="${t("askAi")}" onkeydown="if(event.key==='Enter')sendAiMessage()" />
      <button class="btn btn-primary" style="padding:10px 16px;width:auto" onclick="sendAiMessage()">${t("send")}</button>
    </div>
  </div>`;
}

function renderHome() {
  const svcs = SERVICES();
  const primary = svcs.slice(0, 5);
  const secondary = svcs.slice(5, 13);
  const ranked = [svcs[2], svcs[4], svcs[3], svcs[0]];
  return `
  <div class="app-body">
    <div class="topbar">
      <div class="topbar-row">
        <div class="brand-lockup">
          <div class="brand-mark">O</div>
          <div>
            <div class="brand">OBIC</div>
            <div class="brand-tag">${t("brandTag")}</div>
          </div>
        </div>
        <div class="topbar-actions">
          <button type="button" class="icon-chip" onclick="go('notifications')" aria-label="${t("notifications")}">${ico("bell")}${notifBadge()}</button>
          <button type="button" class="chip lang-chip" onclick="setLang(state.lang==='ar'?'en':'ar')">${isAr() ? "AR ▾" : "EN ▾"}</button>
        </div>
      </div>
      <div class="search" onclick="go('search')"><span class="si">${ico("search")}</span>${t("searchPh")}</div>
    </div>
    <div class="section">
      <div class="primary-tiles">
        ${primary.map(s => `
          <button class="ptile ${s.color}" onclick="go('detail',{serviceId:'${s.id}'})">
            <span class="ico">${ico(s.icon)}</span><span class="lbl">${s.name}</span>
          </button>`).join("")}
      </div>
    </div>
    <div class="section">
      <div class="sec-tiles">
        ${secondary.map(s => `
          <button class="stile" onclick="go('detail',{serviceId:'${s.id}'})">
            <span class="ico">${ico(s.icon)}</span><span class="lbl">${s.name}</span>
          </button>`).join("")}
      </div>
    </div>
    <div class="section">
      <div class="banner-wrap">
        <div class="banner-track">
          <div class="banner b-vip" onclick="go('detail',{serviceId:'vip'})">
            <span class="banner-ico" aria-hidden="true">${ico("vip")}</span>
            <div class="eyebrow">${t("featured")}</div><h3>${t("vipTrip")}</h3><p>${t("vipTripDesc")}</p><span class="cta-pill">${t("bookPkg")}</span>
          </div>
          <div class="banner b-visa" onclick="go('detail',{serviceId:'visa'})">
            <span class="banner-ico" aria-hidden="true">${ico("visa")}</span>
            <div class="eyebrow">${t("fastTrack")}</div><h3>${t("visaExpress")}</h3><p>${t("visaExpressDesc")}</p><span class="cta-pill">${t("from120")}</span>
          </div>
          <div class="banner b-bank" onclick="go('detail',{serviceId:'bank'})">
            <span class="banner-ico" aria-hidden="true">${ico("bank")}</span>
            <div class="eyebrow">${t("setup")}</div><h3>${t("openBank")}</h3><p>${t("openBankDesc")}</p><span class="cta-pill">${t("startReq")}</span>
          </div>
        </div>
        <div class="banner-dots"><i class="on"></i><i></i><i></i></div>
      </div>
      <div class="promo-row">
        <div class="promo promo-show" onclick="go('detail',{serviceId:'visa'})">
          <div class="ph ph-visa">
            <span class="ph-ico">${ico("visa")}</span>
            <span class="ph-label">${svcs[2].name}</span>
          </div>
          <div class="txt">${t("visaExpress")}<div><small>${svcs[2].price}</small></div></div>
        </div>
        <div class="promo promo-plain" onclick="go('detail',{serviceId:'bank'})">
          <div class="promo-ico-wrap bank">${ico("bank")}</div>
          <div class="txt">${t("openBank")}<div><small>Yiwu & Guangzhou</small></div></div>
        </div>
      </div>
    </div>
    <div class="section">
      <div class="section-title">${t("topServices")} <span onclick="go('services')">${t("seeAll")}</span></div>
      <div class="rank-card">
        ${ranked.map((s, i) => `
          <div class="rank-item" onclick="go('detail',{serviceId:'${s.id}'})">
            <div class="rank-n">${i + 1}</div>${softThumb(s)}
            <div><h4>${s.name}</h4><p>${(s.desc || "").slice(0, 36)}…</p></div>
            <div class="price">${(s.price || "").replace(/From |من /, "")}</div>
          </div>`).join("")}
      </div>
    </div>
    <div class="section" style="padding-bottom:18px">
      <div class="section-title">${t("recommended")}</div>
      ${svcs.slice(0, 3).map(s => `
        <div class="list-card" onclick="go('detail',{serviceId:'${s.id}'})">
          ${thumb(s)}<div><h4>${s.name}</h4><p>${(s.desc || "").slice(0, 40)}…</p></div>
          <div class="price">${s.price}</div>
        </div>`).join("")}
    </div>
  </div>
  ${tabBar("home")}`;
}

function renderServices() {
  const svcs = SERVICES();
  return `
  <div class="page-header"><h2>${t("allServices")}</h2><div class="svc-count">16</div></div>
  <div class="app-body"><div class="section">
    <div class="sec-tiles" style="grid-template-columns:repeat(4,1fr)">
      ${svcs.map(s => `
        <button class="stile" onclick="go('detail',{serviceId:'${s.id}'})">
          <span class="ico" style="${s.color ? `background:${colorOf(s).soft};color:${colorOf(s).ink}` : ""}">${ico(s.icon)}</span>
          <span class="lbl">${s.name}</span>
        </button>`).join("")}
    </div>
  </div></div>
  ${tabBar("services")}`;
}

function renderDetail() {
  const s = svcById(state.serviceId);
  const c = colorOf(s);
  return `
  <div class="page-header"><button class="back" onclick="go('home')">←</button><h2>${t("service")}</h2></div>
  <div class="app-body">
    <div class="hero-svc ${s.color || ""}">
      <div class="badge" style="background:rgba(255,255,255,.18);color:#fff">${t("official")}</div>
      <h3>${s.name}</h3><p>${s.desc}</p>
    </div>
    <div class="section">
      <div class="section-title">${t("included")}</div>
      <div class="list-card"><div class="thumb" style="background:${c.soft};color:${c.ink}">${ico("check")}</div><div><h4>${t("advisor")}</h4><p>${t("advisorDesc")}</p></div></div>
      <div class="list-card"><div class="thumb" style="background:${c.soft};color:${c.ink}">${ico("doc")}</div><div><h4>${t("checklist")}</h4><p>${t("checklistDesc")}</p></div></div>
      <div class="list-card"><div class="thumb" style="background:${c.soft};color:${c.ink}">${ico("bell")}</div><div><h4>${t("statusUpdates")}</h4><p>${t("statusUpdatesDesc")}</p></div></div>
      <p style="font-size:15px;margin:14px 0 12px;font-weight:800;font-family:var(--font-display);color:var(--navy)">${s.price}</p>
      <div class="btn-row">
        <button class="btn btn-primary" onclick="go('request')">${t("requestSvc")}</button>
        <button class="btn btn-ghost" onclick="go('chat')">${t("chatSupport")}</button>
      </div>
    </div>
  </div>`;
}

function renderRequest() {
  const s = svcById(state.serviceId);
  return `
  <div class="page-header"><button class="back" onclick="go('detail')">←</button><h2>${t("request")}</h2></div>
  <div class="app-body"><div class="form">
    <div><label>${t("service")}</label><input value="${s.name}" readonly /></div>
    <div><label>${t("prefBranch")}</label>
      <select><option>Yiwu-OBIC</option><option>Guangzhou-OBIC</option><option>Yemen-OBIC</option><option>Foshan-OBIC</option><option>Hangzhou-OBIC</option><option>Hainan-OBIC</option></select>
    </div>
    <div><label>${t("fullName")}</label><input placeholder="${t("yourName")}" /></div>
    <div><label>${t("phoneLabel")}</label><input placeholder="+86 ..." /></div>
    <div><label>${t("email")}</label><input placeholder="you@email.com" /></div>
    <div><label>${t("notes")}</label><textarea rows="3" placeholder="${t("notesPh")}"></textarea></div>
    <button class="btn btn-primary" onclick="toast(t('orderSubmitted')); setTimeout(()=>go('orderDetail'),500)">${t("submitOrder")}</button>
  </div></div>`;
}

function renderOrders() {
  const svcs = SERVICES();
  return `
  <div class="page-header"><h2>${t("orders")}</h2></div>
  <div class="app-body"><div class="section">
    <div class="list-card" onclick="go('orderDetail')">${thumb(svcs[2])}<div><h4>${svcs[2].name} · #OB-1042</h4><p><span class="badge warn">${t("inProgress")}</span></p></div><div class="price">$120</div></div>
    <div class="list-card" onclick="go('orderDetail')">${thumb(svcs[3])}<div><h4>${svcs[3].name} · #OB-1031</h4><p><span class="badge">${t("submitted")}</span></p></div><div class="price">$299</div></div>
    <div class="list-card">${thumb(svcs[0])}<div><h4>${svcs[0].name} · #OB-1010</h4><p><span class="badge ok">${t("completed")}</span></p></div><div class="price">$180</div></div>
  </div></div>
  ${tabBar("orders")}`;
}

function renderOrderDetail() {
  const s = SERVICES()[2];
  return `
  <div class="page-header"><button class="back" onclick="go('orders')">←</button><h2>#OB-1042</h2></div>
  <div class="app-body">
    <div class="section"><div class="list-card">${thumb(s)}<div><h4>${s.name}</h4><p>Yiwu · $120</p></div><span class="badge warn">${t("inProgress")}</span></div></div>
    <div class="section-title" style="padding:0 16px">${t("timeline")}</div>
    <div class="status-steps">
      <div class="step done"><div><h4>${t("submitted")}</h4><p>09:12</p></div></div>
      <div class="step done"><div><h4>${isAr() ? "تعيين المستشار" : "Advisor assigned"}</h4><p>10:05 · Lily</p></div></div>
      <div class="step done"><div><h4>${t("checklist")}</h4><p>${isAr() ? "بانتظار صورة الجواز" : "Awaiting passport"}</p></div></div>
      <div class="step"><div><h4>${isAr() ? "قيد المراجعة" : "Under review"}</h4><p>${t("pending")}</p></div></div>
      <div class="step"><div><h4>${t("completed")}</h4><p>${t("pending")}</p></div></div>
    </div>
    <div class="section"><button class="btn btn-primary" onclick="go('chat')">${t("msgAdvisor")}</button></div>
  </div>`;
}

function renderMessages() {
  return `
  <div class="page-header">
    <h2>${t("messages")}</h2>
    <div class="hdr-actions">
      <button class="icon-btn" onclick="go('addFriend')" title="${t("addFriend")}">${ico("userPlus")}</button>
      <button class="icon-btn" onclick="go('notifications')">${ico("bell")}${notifBadge()}</button>
    </div>
  </div>
  <div class="app-body">
    <div class="msg-item ai-row" onclick="openAi()">
      <div class="avatar ai-av">${ico("ai")}</div>
      <div><h4>OBIC AI</h4><p>${isAr() ? "تأشيرة · بنك · VIP · تتبع" : "Visa · Bank · VIP · Track"}</p></div>
      <div class="time">AI</div>
    </div>
    <div class="msg-item" onclick="go('chat')">
      <div class="avatar">O</div>
      <div><h4>Lily · ${SERVICES()[2].name}</h4><p>${isAr() ? "صورة · ملف · صوت وفيديو" : "Photo · File · Voice & video"}</p></div>
      <div class="time">10:05</div>
    </div>
    <div class="msg-item" onclick="go('friends')">
      <div class="avatar" style="background:linear-gradient(145deg,#34D399,#059669)">${ico("userPlus")}</div>
      <div><h4>${t("friends")}</h4><p>${state.friends.length} · ${state.friendRequests.length} ${t("pending")}</p></div>
      <div class="time">›</div>
    </div>
    <div class="msg-item" onclick="go('chat')">
      <div class="avatar" style="background:linear-gradient(145deg,#94A3B8,#475569)">S</div>
      <div><h4>${isAr() ? "النظام" : "System"}</h4><p>#OB-1042 · ${t("inProgress")}</p></div>
      <div class="time">09:12</div>
    </div>
  </div>
  ${tabBar("messages")}`;
}

function renderChatExtras() {
  return state.chatExtras.map(m => {
    if (m.type === "image") {
      return `<div class="chat-bubble me media"><div class="img-bubble"><div class="img-ph">${ico("image")}<span>${m.label}</span></div></div><div class="msg-meta">${t("sent")}</div></div>`;
    }
    if (m.type === "file") {
      return `<div class="chat-bubble me file-chip"><div class="file-row"><span class="file-ico">${ico("doc")}</span><div><strong>${m.name}</strong><small>${m.size}</small></div></div></div>`;
    }
    return `<div class="chat-bubble me">${m.text}<div class="msg-meta">${t("sent")}</div></div>`;
  }).join("");
}

function renderChat() {
  return `
  <div class="page-header chat-header">
    <button class="back" onclick="go('messages')">←</button>
    <div class="chat-title"><h2>Lily · ${SERVICES()[2].name}</h2><span class="online">${t("online")}</span></div>
    <div class="chat-actions">
      <button class="icon-btn" onclick="go('voiceCall')">${ico("phone")}</button>
      <button class="icon-btn" onclick="go('videoCall')">${ico("video")}</button>
    </div>
  </div>
  <div class="app-body" style="display:flex;flex-direction:column">
    <div class="chat-box">
      <div class="day-sep">${t("today")}</div>
      <div class="chat-bubble them">${t("lilyHello")}</div>
      <div class="chat-bubble me">${t("needVisa")}</div>
      <div class="chat-bubble them">${t("uploadPass")}</div>
      <div class="chat-bubble them media"><div class="file-row them-file"><span class="file-ico">${ico("doc")}</span><div><strong>Visa_Checklist.pdf</strong><small>128 KB</small></div></div></div>
      <div class="chat-bubble them media"><div class="img-bubble them-img"><div class="img-ph alt">${ico("image")}<span>guide</span></div></div></div>
      ${renderChatExtras()}
    </div>
    <div class="composer">
      <div class="composer-tools">
        <button class="tool-btn" onclick="attachImage()">${ico("image")}<span>${t("photo")}</span></button>
        <button class="tool-btn" onclick="attachFile()">${ico("attach")}<span>${t("file")}</span></button>
        <button class="tool-btn" onclick="go('incomingCall')">${ico("phone")}<span>${t("demoCall")}</span></button>
      </div>
      <div class="chat-input">
        <input placeholder="${t("messageLily")}" id="chatIn" />
        <button class="btn btn-primary" style="padding:10px 16px" onclick="sendChatText()">${t("send")}</button>
      </div>
    </div>
  </div>`;
}

function renderVoiceCall() {
  return `
  <div class="call-screen voice">
    <div class="call-top"><span class="call-brand">OBIC</span><span class="call-type">${t("voiceCall")}</span></div>
    <div class="call-center">
      <div class="call-avatar pulse">L</div><h2>Lily Chen</h2><p>OBIC · Yiwu</p>
      <div class="call-timer">${fmtTime(state.callSec)}</div>
      <div class="wave"><i></i><i></i><i></i><i></i><i></i></div>
    </div>
    <div class="call-controls">
      <button class="call-btn ${state.muted ? "on" : ""}" onclick="toggleMute()"><span>${state.muted ? ico("micOff") : ico("mic")}</span>${t("mute")}</button>
      <button class="call-btn ${state.speakerOn ? "on" : ""}" onclick="toggleSpeaker()"><span>${ico("speaker")}</span>${t("speaker")}</button>
      <button class="call-btn end" onclick="toast(t('callEnded')); go('chat')"><span>${ico("hangup")}</span>${t("end")}</button>
    </div>
  </div>`;
}

function renderVideoCall() {
  return `
  <div class="call-screen video">
    <div class="remote-video"><div class="remote-label">Lily Chen · OBIC</div><div class="remote-avatar">L</div><div class="video-timer">${fmtTime(state.callSec + 42)}</div></div>
    <div class="local-video"><div class="local-ph">${t("you")}</div></div>
    <div class="video-controls">
      <button class="vbtn ${state.muted ? "on" : ""}" onclick="toggleMute()">${state.muted ? ico("micOff") : ico("mic")}</button>
      <button class="vbtn" onclick="toast(t('camFlip'))">${ico("camFlip")}</button>
      <button class="vbtn end" onclick="toast(t('callEnded')); go('chat')">${ico("hangup")}</button>
      <button class="vbtn" onclick="toast(t('speakerTog'))">${ico("speaker")}</button>
    </div>
  </div>`;
}

function renderIncomingCall() {
  return `
  <div class="call-screen incoming">
    <div class="incoming-bg"></div>
    <div class="call-center" style="z-index:1">
      <div class="call-brand" style="margin-bottom:18px">OBIC</div>
      <div class="call-avatar">L</div><h2>Lily Chen</h2>
      <p class="ring-label"><span class="ring-dot"></span> ${t("incomingVideo")}</p>
    </div>
    <div class="incoming-actions">
      <button class="in-btn decline" onclick="toast(t('declined')); go('chat')"><span>${ico("hangup")}</span>${t("decline")}</button>
      <button class="in-btn accept" onclick="go('videoCall')"><span>${ico("video")}</span>${t("accept")}</button>
    </div>
    <button class="voice-alt" onclick="go('voiceCall')">${t("voiceOnly")}</button>
  </div>`;
}

function authTabs() {
  return `
  <div class="auth-tabs">
    <button type="button" class="${state.authTab === "email" ? "on" : ""}" onclick="setAuthTab('email')">${t("emailTab")}</button>
    <button type="button" class="${state.authTab === "phone" ? "on" : ""}" onclick="setAuthTab('phone')">${t("phoneTab")}</button>
  </div>`;
}

function authIdentityFields(kind) {
  if (state.authTab === "phone") {
    return `
      <div><label>${t("mobile")}</label><input placeholder="${t("phonePh")}" /></div>
      ${kind === "register" ? `<div><label>${t("smsCode")}</label><div class="otp-row"><input placeholder="••••••" /><button type="button" class="btn btn-ghost otp-btn" onclick="toast(t('smsSent'))">${t("sendCode")}</button></div></div>` : ""}`;
  }
  return `
    <div><label>${t("email")}</label><input placeholder="you@email.com" /></div>
    ${kind === "register" ? `<div><label>${t("emailCode")}</label><div class="otp-row"><input placeholder="••••••" /><button type="button" class="btn btn-ghost otp-btn" onclick="toast(t('emailSent'))">${t("sendCode")}</button></div></div>` : ""}`;
}

function staffMark(label) {
  return `<button type="button" class="staff-mark" title="Staff" onclick="go('staffLogin')" aria-label="Staff">
    <span class="staff-o">O</span><span class="staff-txt">${label || t("staff")}</span>
  </button>`;
}

function renderMoments() {
  return `
  <div class="page-header">
    <h2>${t("momentsTitle")}</h2>
    <button class="icon-btn" onclick="go('notifications')">${ico("bell")}${notifBadge()}</button>
  </div>
  <div class="app-body">
    <div class="moment-composer card-soft">
      <textarea id="momentIn" rows="2" placeholder="${t("momentPh")}"></textarea>
      <div class="moment-tools">
        <div class="role-toggle compact">
          <button type="button" class="${state.postAs === "user" ? "on" : ""}" onclick="state.postAs='user';render()">${t("postAsUser")}</button>
          <button type="button" class="${state.postAs === "admin" ? "on" : ""}" onclick="state.postAs='admin';render()">${t("postAsAdmin")}</button>
        </div>
        <button type="button" class="chip ${state.momentWithImage ? "on" : ""}" onclick="state.momentWithImage=!state.momentWithImage;render()">${state.momentWithImage ? t("withImage") : t("textOnly")}</button>
        <button class="btn btn-primary" style="padding:8px 14px;width:auto" onclick="postMoment()">${t("postMoment")}</button>
      </div>
      <p class="rule-hint">${state.postAs === "admin" ? t("adminNotifyAll") : t("noNotifyUser")}</p>
    </div>
    ${state.moments.map(m => `
      <article class="moment-card">
        <div class="moment-head">
          <div class="avatar ${m.role === "admin" ? "admin-av" : ""}">${(m.author || "U")[0]}</div>
          <div>
            <h4>${m.author} ${m.role === "admin" ? `<span class="badge">${t("adminPost")}</span>` : ""}</h4>
            <p>${m.time}</p>
          </div>
        </div>
        <p class="moment-text">${isAr() ? m.textAr : m.textEn}</p>
        ${m.hasImage && m.imageTheme ? `<div class="moment-img theme-${m.imageTheme}">${ico(m.imageTheme)}</div>` : (m.hasImage ? `<div class="moment-img">${ico("image")}</div>` : "")}
        <div class="moment-actions"><span>${t("like")} · ${m.likes}</span><span>${t("comment")}</span></div>
      </article>`).join("")}
  </div>
  ${tabBar("moments")}`;
}

function renderNotifications() {
  return `
  <div class="page-header">
    <button class="back" onclick="go('home')">←</button>
    <h2>${t("notifications")}</h2>
    <button class="mini-btn" onclick="markNotifsRead()">${t("markRead")}</button>
  </div>
  <div class="app-body">
    ${state.notifications.length === 0 ? `<div class="empty"><p>${t("notifEmpty")}</p></div>` : ""}
    ${state.notifications.map(n => `
      <div class="notif-item ${n.unread ? "unread" : ""}" onclick="go('moments')">
        <div class="avatar admin-av">${ico("bell")}</div>
        <div>
          <h4>${isAr() ? n.titleAr : n.titleEn} ${n.unread ? `<span class="badge warn">${t("unreadBadge")}</span>` : ""}</h4>
          <p>${isAr() ? n.bodyAr : n.bodyEn}</p>
          <small>${n.time} · ${t("adminNotifyAll")}</small>
        </div>
      </div>`).join("")}
    <div class="rule-box">
      <p><strong>${t("adminPost")}:</strong> ${t("adminNotifyAll")}</p>
      <p><strong>${t("userPost")}:</strong> ${t("noNotifyUser")}</p>
    </div>
  </div>`;
}

function renderAddFriend() {
  const tab = state.addFriendTab;
  return `
  <div class="page-header"><button class="back" onclick="go('messages')">←</button><h2>${t("addFriend")}</h2></div>
  <div class="app-body">
    <p class="rule-hint ok">${t("custCanAdd")} — ${t("customerAddOk")}</p>
    <div class="auth-tabs">
      <button type="button" class="${tab === "phone" ? "on" : ""}" onclick="setAddFriendTab('phone')">${t("byPhone")}</button>
      <button type="button" class="${tab === "id" ? "on" : ""}" onclick="setAddFriendTab('id')">${t("byId")}</button>
      <button type="button" class="${tab === "qr" ? "on" : ""}" onclick="setAddFriendTab('qr')">${t("byQr")}</button>
    </div>
    <div class="form">
      ${tab === "phone" ? `<div><label>${t("mobile")}</label><input placeholder="${t("phonePh")}" /></div>` : ""}
      ${tab === "id" ? `<div><label>${t("demoId")}</label><input placeholder="${t("idPh")}" /></div>` : ""}
      ${tab === "qr" ? `<div class="qr-demo"><div class="qr-box">${ico("qr")}</div><p>${t("qrDemo")}</p><button class="btn btn-ghost" onclick="toast(t('scanQrDemo'))">${t("scanQrDemo")}</button></div>` : ""}
      ${tab !== "qr" ? `<button class="btn btn-primary" onclick="sendFriendRequest()">${t("sendRequest")}</button>` : ""}
    </div>
    <div class="section-title">${t("friendRequests")}</div>
    ${state.friendRequests.map(fr => `
      <div class="friend-card">
        <div class="avatar">${fr.name[0]}</div>
        <div><h4>${fr.name}</h4><p>${fr.idCode} · ${fr.phone}</p></div>
        <button class="mini-btn" onclick="acceptFriend('${fr.id}')">${t("acceptFriend")}</button>
        <button class="mini-btn ghost" onclick="rejectFriend('${fr.id}')">${t("rejectFriend")}</button>
      </div>`).join("")}
  </div>`;
}

function renderFriends() {
  return `
  <div class="page-header">
    <button class="back" onclick="go('messages')">←</button>
    <h2>${t("myFriends")}</h2>
    <button class="icon-btn" onclick="go('addFriend')">${ico("userPlus")}</button>
  </div>
  <div class="app-body">
    ${state.friends.map(f => `
      <div class="friend-card" onclick="go('chat')">
        <div class="avatar">${f.name[0]}</div>
        <div><h4>${f.name}</h4><p>${f.idCode} · ${f.phone}</p></div>
        <span>›</span>
      </div>`).join("")}
  </div>`;
}

function renderMe() {
  return `
  <div class="app-body">
    <div class="me-header">
      <div class="row">
        <div class="av">G</div>
        <div>
          <h3 style="font-size:20px;font-family:var(--font-display);font-weight:800">${t("guest")}</h3>
          <p style="font-size:12px;opacity:.88;margin-top:2px">${t("signInHint")}</p>
        </div>
      </div>
      <div style="display:flex;gap:8px;margin-top:16px">
        <button class="btn btn-ghost" style="flex:1;padding:11px;background:rgba(255,255,255,.14);border-color:rgba(255,255,255,.3);color:#fff" onclick="go('login')">${t("login")}</button>
        <button class="btn btn-primary" style="flex:1;padding:11px;box-shadow:none" onclick="go('register')">${t("register")}</button>
      </div>
    </div>
    <div class="wallet">
      <div><strong>—</strong><span>${t("wallet")}</span></div>
      <div><strong>0</strong><span>${t("coupons")}</span></div>
      <div><strong>0</strong><span>${t("favorites")}</span></div>
    </div>
    <div class="menu-list">
      <div class="menu-item" onclick="go('orders')">${t("myOrders")} <span>›</span></div>
      <div class="menu-item" onclick="go('moments')">${t("moments")} <span>›</span></div>
      <div class="menu-item" onclick="go('friends')">${t("friends")} <span>›</span></div>
      <div class="menu-item" onclick="go('notifications')">${t("notifications")} ${notifBadge()} <span>›</span></div>
      <div class="menu-item" onclick="go('addFriend')">${t("addFriend")} <span>›</span></div>
      <div class="menu-item">${t("myDocs")} <span>›</span></div>
      <div class="menu-item">${t("branch")} <span>Yiwu ›</span></div>
      <div class="menu-item" onclick="setLang(state.lang==='ar'?'en':'ar')">${t("language")} <span>${isAr() ? t("langAr") : t("langEn")} ›</span></div>
      <div class="menu-item" onclick="go('about')">${t("aboutObic")} <span>›</span></div>
      <div class="menu-item" onclick="go('chat')">${t("support")} <span>›</span></div>
    </div>
    <div class="staff-entry-row">${staffMark()}</div>
    <p class="staff-entry-hint">${t("staffEntryHint")}</p>
    <p class="credit-line">${t("designedBy")}</p>
  </div>
  ${tabBar("me")}`;
}

function renderLogin() {
  return `
  <div class="page-header"><button class="back" onclick="go('me')">←</button><h2>${t("login")}</h2></div>
  <div class="app-body"><div class="form">
    <div class="auth-hero"><div class="brand">OBIC</div><p>${t("welcomeBack")}</p></div>
    ${authTabs()}${authIdentityFields("login")}
    <div><label>${t("password")}</label><input type="password" placeholder="••••••••" /></div>
    <button class="btn btn-primary" onclick="toast(t('loggedIn')); go('me')">${t("login")}</button>
    <button class="btn btn-ghost" onclick="go('register')">${t("createAccount")}</button>
    <p style="text-align:center;font-size:12px;color:var(--muted)">${t("guestBrowse")}</p>
  </div></div>`;
}

function renderRegister() {
  return `
  <div class="page-header"><button class="back" onclick="go('me')">←</button><h2>${t("register")}</h2></div>
  <div class="app-body"><div class="form">
    <div class="auth-hero"><div class="brand">OBIC</div><p>${t("registerWith")}</p></div>
    ${authTabs()}
    <div><label>${t("fullName")}</label><input placeholder="${t("yourName")}" /></div>
    ${authIdentityFields("register")}
    <div><label>${t("password")}</label><input type="password" placeholder="••••••••" /></div>
    <label style="display:flex;gap:8px;align-items:flex-start;font-size:12px;color:var(--navy);font-weight:500">
      <input type="checkbox" style="width:auto;margin-top:2px" /> ${t("agree")}
    </label>
    <button class="btn btn-primary" onclick="toast(t('accountCreated')); go('me')">${t("register")}</button>
  </div></div>`;
}

function renderSearch() {
  const svcs = SERVICES();
  return `
  <div class="page-header"><button class="back" onclick="go('home')">←</button><h2>${t("search")}</h2></div>
  <div class="app-body">
    <div class="section"><div class="search" style="margin:0"><span class="si">${ico("search")}</span>${isAr() ? "تأشيرة" : "visa"}</div></div>
    <div class="section">
      <div class="section-title">${t("hotSearches")}</div>
      <div class="hot-tags">
        ${[["visa","visa"],["vip","vip"],["bank","bank"],["hotels","hotels"],["company","company"]].map(([id]) => {
          const s = svcs.find(x => x.id === id);
          return `<button class="chip" onclick="go('detail',{serviceId:'${id}'})">${s ? s.name : id}</button>`;
        }).join("")}
      </div>
      ${svcs.filter(s => /visa|vip|bank|hotel|تأشيرة|فنادق|VIP|حساب/i.test(s.name + s.id)).map(s => `
        <div class="list-card" onclick="go('detail',{serviceId:'${s.id}'})">${thumb(s)}<div><h4>${s.name}</h4><p>${s.price}</p></div></div>`).join("")}
    </div>
  </div>`;
}

function renderAbout() {
  return `
  <div class="page-header"><button class="back" onclick="go('me')">←</button><h2>${t("aboutTitle")}</h2></div>
  <div class="app-body"><div class="section">
    <div class="banner-wrap" style="margin-bottom:12px">
      <div class="banner b1" style="width:100%">
        <div class="eyebrow">OBIC</div><h3>OBIC</h3><p>${t("aboutDesc")}</p>
      </div>
    </div>
    <div class="list-card"><div class="thumb" style="background:#E8F1FF;color:var(--blue)">${ico("pin")}</div><div><h4>${t("branches")}</h4><p>Yiwu · Guangzhou · Yemen · Foshan · Hangzhou · Hainan</p></div></div>
    <div class="list-card"><div class="thumb" style="background:#E8F1FF;color:var(--blue)">${ico("web")}</div><div><h4>${t("website")}</h4><p>www.obicgp.com</p></div></div>
    <div class="list-card"><div class="thumb" style="background:#E8F1FF;color:var(--blue)">${ico("mail")}</div><div><h4>${t("contact")}</h4><p>${t("supportChat")}</p></div></div>
    <div class="about-footer">
      <p>${t("aboutFooter")}</p>
      ${staffMark()}
    </div>
  </div></div>`;
}

function roleChip() {
  return isSuper()
    ? `<span class="role-chip super">${t("superAdmin")}</span>`
    : `<span class="role-chip emp">${t("employee")}</span>`;
}
function roleToggle() {
  return `
  <div class="role-toggle">
    <button type="button" class="${isSuper() ? "on" : ""}" onclick="setStaffRole('super')">${t("superAdmin")}</button>
    <button type="button" class="${!isSuper() ? "on" : ""}" onclick="setStaffRole('employee')">${t("employee")}</button>
  </div>`;
}

function renderStaffLogin() {
  return `
  <div class="page-header"><button class="back" onclick="go('me')">←</button><h2>${t("staffLogin")}</h2></div>
  <div class="app-body"><div class="form">
    <div class="auth-hero">
      <div class="staff-badge-lg">O</div>
      <div class="brand" style="font-size:22px">OBIC Staff</div>
      <p>${t("staffOnly")}</p>
    </div>
    <div class="dual-access-card">
      <h4>${t("dualAccessTitle")}</h4>
      <p>${t("dualAccessBody")}</p>
      <div class="dual-paths">
        <button type="button" onclick="state.staffLoggedIn=true; toast(t('staffIn')); go('adminDash')">
          <strong>${t("dualPathApp")}</strong>${t("dualPathAppDesc")}
        </button>
        <button type="button" onclick="setMode('adminWeb')">
          <strong>${t("dualPathWeb")}</strong>${t("dualPathWebDesc")}
        </button>
      </div>
    </div>
    ${authTabs()}${authIdentityFields("login")}
    <div><label>${t("staffPassword")}</label><input type="password" placeholder="••••••••" /></div>
    <div class="demo-hint">${t("demoPickRole")}</div>
    ${roleToggle()}
    <button class="btn btn-primary" onclick="state.staffLoggedIn=true; toast(t('staffIn')); go('adminDash')">${t("enterAdmin")}</button>
    <button class="btn btn-ghost" onclick="setMode('adminWeb')">${t("openAdminWeb")}</button>
  </div></div>`;
}

function adminAppNav() {
  return `
  <nav class="admin-tabbar">
    <button class="tab ${state.screen==="adminDash"?"active":""}" onclick="go('adminDash')"><span class="ti">${ico("grid")}</span>${t("staffNavHome")}</button>
    <button class="tab ${state.screen==="adminOrders"?"active":""}" onclick="go('adminOrders')"><span class="ti">${ico("orders")}</span>${t("staffNavOrders")}</button>
    <button class="tab ${state.screen==="adminOversight"?"active":""} ${!isSuper()?"locked":""}" onclick="${isSuper()?"go('adminOversight')":"toast(t('superOnly'))"}"><span class="ti">${ico("eye")}</span>${t("staffNavOversight")}</button>
    <button class="tab ${state.screen==="adminStaff"?"active":""} ${!isSuper()?"locked":""}" onclick="${isSuper()?"go('adminStaff')":"toast(t('superOnly'))"}"><span class="ti">${ico("hr")}</span>${t("staffNavStaff")}</button>
  </nav>`;
}

function renderAdminDash() {
  return `
  <div class="admin-app">
    <div class="admin-top">
      <div><div class="admin-brand">${t("adminApp")}</div><div class="admin-sub">${t("mobileStaff")}</div></div>
      ${roleChip()}
    </div>
    <div class="app-body">
      <div class="section">${roleToggle()}</div>
      <div class="section">
        <div class="admin-stats">
          <div><strong>18</strong><span>${t("openOrders")}</span></div>
          <div><strong>5</strong><span>${t("unreadChats")}</span></div>
          <div><strong>${isSuper() ? "12" : "3"}</strong><span>${isSuper() ? t("staffCount") : t("assigned")}</span></div>
        </div>
      </div>
      <div class="section">
        <div class="section-title">${t("quickActions")}</div>
        <div class="admin-actions">
          <button onclick="go('adminOrders')">${ico("orders")}<span>${t("orders")}</span></button>
          <button onclick="go('chat')">${ico("msg")}<span>${t("staffNavChat")}</span></button>
          <button class="${isSuper()?"":"is-disabled"}" onclick="${isSuper()?"go('adminOversight')":"toast(t('superOnly'))"}">${ico("eye")}<span>${t("oversight")}</span></button>
          <button class="${isSuper()?"":"is-disabled"}" onclick="${isSuper()?"go('adminStaff')":"toast(t('restricted'))"}">${ico("hr")}<span>${t("staff")}</span></button>
        </div>
      </div>
      <div class="section">
        <div class="section-title">${t("modules")}</div>
        <div class="menu-list">
          <div class="menu-item" onclick="go('adminOrders')">${t("assignedOrders")} <span>›</span></div>
          <div class="menu-item" onclick="go('messages')">${t("customerChats")} <span>›</span></div>
          <div class="menu-item ${isSuper()?"":"dimmed"}" onclick="${isSuper()?"go('adminOversight')":"toast(t('superOnly'))"}">${t("chatOversight")} ${isSuper()?"<span>›</span>":`<span class='lock'>${t("locked")}</span>`}</div>
          <div class="menu-item ${isSuper()?"":"dimmed"}" onclick="tryAdminAddContact()">${t("addContact")} ${isSuper()?"<span>›</span>":`<span class='lock'>${t("locked")}</span>`}</div>
          <div class="menu-item ${isSuper()?"":"dimmed"}" onclick="${isSuper()?"go('adminStaff')":"toast(t('superOnly'))"}">${t("staffPriv")} ${isSuper()?"<span>›</span>":`<span class='lock'>${t("locked")}</span>`}</div>
          <div class="menu-item" onclick="go('moments')">${t("moments")} <span>›</span></div>
          <div class="menu-item" onclick="setMode('adminWeb')">${t("openWeb")} <span>›</span></div>
          <div class="menu-item" onclick="state.staffLoggedIn=false; go('home')">${t("exitCustomer")} <span>›</span></div>
        </div>
      </div>
      ${!isSuper() ? `<div class="rule-box warn-box"><p>${t("empBlockAdd")}</p><p>${t("empBlockHint")}</p><p>${t("noOtherEmpChats")}</p></div>` : ""}
    </div>
    ${adminAppNav()}
  </div>`;
}

function renderAdminStaff() {
  if (!isSuper()) {
    return `
    <div class="page-header"><button class="back" onclick="go('adminDash')">←</button><h2>${t("staff")}</h2></div>
    <div class="app-body"><div class="empty"><div class="big" style="font-size:28px;font-weight:800;color:var(--muted)">${t("locked").toUpperCase()}</div>
    <h3>${t("superOnly")}</h3><p>${t("empCannotPromote")}</p>
    <button class="btn btn-primary" onclick="go('adminDash')">${t("backDash")}</button></div></div>`;
  }
  return `
  <div class="page-header"><button class="back" onclick="go('adminDash')">←</button><h2>${t("staffPriv")}</h2></div>
  <div class="app-body">
    <div class="section">
      <div class="sign-banner">${t("signedBy")} <strong>${t("superAdmin")}</strong></div>
      <div class="section-title">${t("permMatrix")}</div>
      <div class="perm-table">
        <div class="perm-row head"><span>${t("capability")}</span><span>${t("superAdmin")}</span><span>${t("employee")}</span></div>
        <div class="perm-row"><span>${t("ordersChat")}</span><span class="ok">✓</span><span class="ok">✓</span></div>
        <div class="perm-row"><span>${t("assignedCust")}</span><span class="ok">✓</span><span class="ok">✓</span></div>
        <div class="perm-row"><span>${t("chatOversight")}</span><span class="ok">✓</span><span class="no">—</span></div>
        <div class="perm-row"><span>${t("addContact")}</span><span class="ok">✓</span><span class="no">—</span></div>
        <div class="perm-row"><span>${t("promoteStaff")}</span><span class="ok">✓</span><span class="no">—</span></div>
        <div class="perm-row"><span>${t("systemSettings")}</span><span class="ok">✓</span><span class="no">—</span></div>
      </div>
    </div>
    <div class="section">
      <div class="section-title">${t("team")}</div>
      <div class="staff-card"><div class="av-sm">L</div><div><h4>Lily Chen</h4><p>Visa · Yiwu</p></div><span class="role-chip emp">${t("employee")}</span><button class="mini-btn" onclick="toast(t('promoted'))">${t("promote")}</button></div>
      <div class="staff-card"><div class="av-sm">A</div><div><h4>Ahmed R.</h4><p>VIP · Guangzhou</p></div><span class="role-chip emp">${t("employee")}</span><button class="mini-btn" onclick="toast(t('privUpdated'))">${t("grant")}</button></div>
      <div class="staff-card"><div class="av-sm gold">S</div><div><h4>Sara O.</h4><p>HQ</p></div><span class="role-chip super">${t("superAdmin")}</span></div>
      <button class="btn btn-primary" style="margin-top:10px" onclick="toast(t('inviteSent'))">${t("inviteStaff")}</button>
    </div>
  </div>
  ${adminAppNav()}`;
}

function renderAdminOrders() {
  const svcs = SERVICES();
  return `
  <div class="page-header"><h2>${t("adminOrders")}</h2>${roleChip()}</div>
  <div class="app-body"><div class="section">
    <p class="admin-subline">${isSuper() ? t("allBranches") : t("assignedYou")}</p>
    <div class="list-card" onclick="go('orderDetail')">${thumb(svcs[2])}<div><h4>${svcs[2].name} · #OB-1042</h4><p>Omar · ${t("inProgress")}</p></div></div>
    <div class="list-card" onclick="go('orderDetail')">${thumb(svcs[3])}<div><h4>${svcs[3].name} · #OB-1031</h4><p>Nora · ${t("submitted")}</p></div></div>
    ${isSuper() ? `<div class="list-card">${thumb(svcs[4])}<div><h4>${svcs[4].name} · #OB-1099</h4><p>${isAr() ? "غير مسند" : "Unassigned"}</p></div></div>` : ""}
  </div></div>
  ${adminAppNav()}`;
}

function renderAdminOversight() {
  if (!isSuper()) {
    return `
    <div class="page-header"><button class="back" onclick="go('adminDash')">←</button><h2>${t("oversight")}</h2></div>
    <div class="app-body"><div class="empty"><h3>${t("superOnly")}</h3><p>${t("empPrivate")}</p>
    <button class="btn btn-primary" onclick="go('adminDash')">${t("backDash")}</button></div></div>`;
  }
  return `
  <div class="page-header"><button class="back" onclick="go('adminDash')">←</button><h2>${t("oversightTitle")}</h2></div>
  <div class="app-body">
    <div class="sign-banner">${t("supervision")} · ${t("superAdmin")}</div>
    <p class="rule-hint">${t("oversightDesc")}</p>
    ${state.employeeChats.map(c => `
      <div class="oversight-card" onclick="go('adminTranscript',{oversightId:'${c.id}'})">
        <div class="avatar">${c.employee[0]}</div>
        <div>
          <h4>${c.employee} → ${c.customer}</h4>
          <p>${c.service} · ${isAr() ? c.previewAr : c.previewEn}</p>
        </div>
        <span class="mini-btn">${t("openTranscript")}</span>
      </div>`).join("")}
  </div>
  ${adminAppNav()}`;
}

function renderAdminTranscript() {
  if (!isSuper()) {
    toast(t("superOnly"));
    return renderAdminDash();
  }
  const chat = state.employeeChats.find(c => c.id === state.oversightId) || state.employeeChats[0];
  return `
  <div class="page-header"><button class="back" onclick="go('adminOversight')">←</button><h2>${t("transcript")}</h2></div>
  <div class="app-body">
    <div class="list-card"><div class="avatar">${chat.employee[0]}</div>
      <div><h4>${chat.employee} · ${chat.customer}</h4><p>${chat.service} · ${t("supervision")}</p></div>
    </div>
    <div class="chat-box oversight-thread">
      ${chat.messages.map(m => `
        <div class="chat-bubble ${m.side === "emp" ? "them" : "me"}">${isAr() ? m.textAr : m.textEn}
          <div class="msg-meta">${m.side === "emp" ? chat.employee : chat.customer}</div>
        </div>`).join("")}
    </div>
  </div>
  ${adminAppNav()}`;
}

function renderAdminAddContact() {
  if (!isSuper()) {
    return `
    <div class="page-header"><button class="back" onclick="go('adminDash')">←</button><h2>${t("addContact")}</h2></div>
    <div class="app-body"><div class="empty rule-box warn-box">
      <h3>${t("empBlockAdd")}</h3><p>${t("empBlockHint")}</p>
      <button class="btn btn-primary" onclick="go('adminDash')">${t("backDash")}</button>
    </div></div>`;
  }
  return `
  <div class="page-header"><button class="back" onclick="go('adminDash')">←</button><h2>${t("addContact")}</h2></div>
  <div class="app-body">
    <p class="rule-hint ok">${t("superCanAdd")}</p>
    <div class="auth-tabs">
      <button type="button" class="${state.addFriendTab === "phone" ? "on" : ""}" onclick="setAddFriendTab('phone')">${t("byPhone")}</button>
      <button type="button" class="${state.addFriendTab === "id" ? "on" : ""}" onclick="setAddFriendTab('id')">${t("byId")}</button>
    </div>
    <div class="form">
      ${state.addFriendTab === "phone"
        ? `<div><label>${t("mobile")}</label><input placeholder="${t("phonePh")}" /></div>`
        : `<div><label>${t("demoId")}</label><input placeholder="${t("idPh")}" /></div>`}
      <button class="btn btn-primary" onclick="sendFriendRequest()">${t("addContact")}</button>
    </div>
  </div>
  ${adminAppNav()}`;
}

function renderAdminWebDash() {
  return `
  <div class="web-shell">
    <aside class="web-side">
      <div class="web-logo"><span>O</span> OBIC Admin</div>
      <button class="on">${t("opsDash")}</button>
      <button onclick="go('adminWebStaff')">${t("staffPriv")}</button>
      <button onclick="${isSuper()?"go('adminWebOversight')":"toast(t('superOnly'))"}">${t("chatOversight")}</button>
      <button class="${isSuper()?"":"dim"}">${t("systemSettings")}</button>
      <button onclick="setMode('app'); go('staffLogin')">← ${t("staffLogin")} (${t("dualPathApp")})</button>
      <button onclick="setMode('app')">← ${t("home")}</button>
      <div class="web-side-foot">${roleChip()}<p class="credit-mini">${t("designedBy")}</p></div>
    </aside>
    <main class="web-main">
      <div class="web-access-banner">${t("webAccessNote")}</div>
      <header class="web-head">
        <div><h2>${t("opsDash")}</h2><p>${t("desktopAdmin")} · ${isAr() ? "العربية" : "English"}</p></div>
        <div class="web-head-right">${roleToggle()}
          <button class="chip" onclick="setLang(state.lang==='ar'?'en':'ar')">${isAr()?"AR":"EN"}</button>
        </div>
      </header>
      <section class="web-kpis">
        <div><strong>128</strong><span>${t("customers")}</span></div>
        <div><strong>34</strong><span>${t("openOrders")}</span></div>
        <div><strong>9</strong><span>${t("activeChats")}</span></div>
        <div><strong>${isSuper() ? "12" : "—"}</strong><span>${t("staffSeats")}</span></div>
      </section>
      <section class="web-grid">
        <div class="web-card">
          <h3>${t("liveOrders")}</h3>
          <table class="web-table">
            <tr><th>ID</th><th>${t("service")}</th><th>${t("branch")}</th><th>${isAr()?"الحالة":"Status"}</th><th>${isAr()?"المسؤول":"Assignee"}</th></tr>
            <tr><td>#OB-1042</td><td>${SERVICES()[2].name}</td><td>Yiwu</td><td><span class="badge warn">${t("inProgress")}</span></td><td>Lily</td></tr>
            <tr><td>#OB-1031</td><td>${SERVICES()[3].name}</td><td>Guangzhou</td><td><span class="badge">${t("submitted")}</span></td><td>Ahmed</td></tr>
          </table>
        </div>
        <div class="web-card">
          <h3>${t("privileges")}</h3>
          <p class="web-note">${isSuper() ? t("canPromote") : t("empLocked")}</p>
          <div class="perm-table web">
            <div class="perm-row"><span>${t("chatOversight")}</span><span class="${isSuper()?"ok":"no"}">${isSuper()?"✓":t("locked")}</span></div>
            <div class="perm-row"><span>${t("addContact")}</span><span class="${isSuper()?"ok":"no"}">${isSuper()?"✓":t("locked")}</span></div>
            <div class="perm-row"><span>${t("promoteStaff")}</span><span class="${isSuper()?"ok":"no"}">${isSuper()?"✓":t("locked")}</span></div>
          </div>
          <button class="btn btn-primary" style="margin-top:12px" onclick="go('adminWebStaff')">${isSuper() ? t("manageStaff") : t("viewRoster")}</button>
        </div>
      </section>
    </main>
  </div>`;
}

function renderAdminWebStaff() {
  return `
  <div class="web-shell">
    <aside class="web-side">
      <div class="web-logo"><span>O</span> OBIC Admin</div>
      <button onclick="go('adminWebDash')">${t("opsDash")}</button>
      <button class="on">${t("staffPriv")}</button>
      <button onclick="${isSuper()?"go('adminWebOversight')":"toast(t('superOnly'))"}">${t("chatOversight")}</button>
      <button onclick="setMode('app')">← ${t("home")}</button>
      <div class="web-side-foot">${roleChip()}</div>
    </aside>
    <main class="web-main">
      <header class="web-head"><div><h2>${t("staffMgmt")}</h2><p>${t("designate")}</p></div>${roleToggle()}</header>
      ${!isSuper() ? `<div class="web-lock">${t("empCannot")}</div>` : `
      <div class="sign-banner web">${t("signBanner")}</div>
      <div class="web-card">
        <table class="web-table">
          <tr><th>${isAr()?"الاسم":"Name"}</th><th>${t("branch")}</th><th>${isAr()?"الدور":"Role"}</th><th>${isAr()?"إجراءات":"Actions"}</th></tr>
          <tr><td>Lily Chen</td><td>Yiwu</td><td><span class="role-chip emp">${t("employee")}</span></td><td><button class="mini-btn" onclick="toast(t('promotedAdmin'))">${t("promote")}</button></td></tr>
          <tr><td>Ahmed R.</td><td>Guangzhou</td><td><span class="role-chip emp">${t("employee")}</span></td><td><button class="mini-btn" onclick="toast(t('privGranted'))">${t("grant")}</button></td></tr>
        </table>
        <button class="btn btn-primary" style="margin-top:14px;max-width:280px" onclick="toast(t('staffApproved'))">${t("approveSign")}</button>
      </div>`}
    </main>
  </div>`;
}

function renderAdminWebOversight() {
  if (!isSuper()) {
    return renderAdminWebDash();
  }
  return `
  <div class="web-shell">
    <aside class="web-side">
      <div class="web-logo"><span>O</span> OBIC Admin</div>
      <button onclick="go('adminWebDash')">${t("opsDash")}</button>
      <button onclick="go('adminWebStaff')">${t("staffPriv")}</button>
      <button class="on">${t("chatOversight")}</button>
      <button onclick="setMode('app')">← ${t("home")}</button>
      <div class="web-side-foot">${roleChip()}</div>
    </aside>
    <main class="web-main">
      <header class="web-head"><div><h2>${t("oversightTitle")}</h2><p>${t("oversightDesc")}</p></div>${roleToggle()}</header>
      <div class="web-card">
        <table class="web-table">
          <tr><th>${t("employee")}</th><th>${isAr()?"العميل":"Customer"}</th><th>${t("service")}</th><th></th></tr>
          ${state.employeeChats.map(c => `
            <tr>
              <td>${c.employee}</td><td>${c.customer}</td><td>${c.service}</td>
              <td><button class="mini-btn" onclick="go('adminTranscript',{oversightId:'${c.id}',mode:'app'})">${t("openTranscript")}</button></td>
            </tr>`).join("")}
        </table>
      </div>
    </main>
  </div>`;
}

const RENDERERS = {
  home: renderHome, services: renderServices, detail: renderDetail, request: renderRequest,
  orders: renderOrders, orderDetail: renderOrderDetail, messages: renderMessages, chat: renderChat,
  voiceCall: renderVoiceCall, videoCall: renderVideoCall, incomingCall: renderIncomingCall,
  moments: renderMoments, notifications: renderNotifications, addFriend: renderAddFriend, friends: renderFriends,
  me: renderMe, login: renderLogin, register: renderRegister, search: renderSearch, about: renderAbout,
  aiChat: renderAiChatScreen, staffLogin: renderStaffLogin, adminDash: renderAdminDash,
  adminStaff: renderAdminStaff, adminOrders: renderAdminOrders, adminOversight: renderAdminOversight,
  adminTranscript: renderAdminTranscript, adminAddContact: renderAdminAddContact,
  adminWebDash: renderAdminWebDash, adminWebStaff: renderAdminWebStaff, adminWebOversight: renderAdminWebOversight,
};

function render() {
  applyDir();
  const labels = screenLabels();
  const list = state.mode === "adminWeb" ? labels.web : labels.app;
  nav.innerHTML = list.map(s =>
    `<button class="${state.screen === s.id ? "active" : ""}" onclick="go('${s.id}')">${s.label}</button>`
  ).join("");

  document.querySelectorAll(".mode-btn").forEach(btn => {
    btn.classList.toggle("active", btn.dataset.mode === state.mode);
  });

  if (state.mode === "adminWeb") {
    phoneWrap.classList.add("hidden");
    desktopWrap.classList.remove("hidden");
    const html = (RENDERERS[state.screen] || renderAdminWebDash)();
    adminWeb.innerHTML = html + (state.toast ? `<div class="toast web-toast">${state.toast}</div>` : "");
    app.innerHTML = "";
  } else {
    desktopWrap.classList.add("hidden");
    phoneWrap.classList.remove("hidden");
    if (state.screen === "aiChat") state.aiOpen = true;
    const html = (RENDERERS[state.screen] || renderHome)();
    const aiLayer = state.aiOpen && state.screen !== "aiChat" ? renderAiPanel() : "";
    app.innerHTML = html + renderAiFab() + aiLayer + (state.toast ? `<div class="toast">${state.toast}</div>` : "");
    adminWeb.innerHTML = "";
  }
}

document.getElementById("modeToggle").addEventListener("click", (e) => {
  const btn = e.target.closest(".mode-btn");
  if (btn) setMode(btn.dataset.mode);
});
document.getElementById("langToggle").addEventListener("click", (e) => {
  const btn = e.target.closest(".lang-btn");
  if (btn) setLang(btn.dataset.lang);
});

window.go = go;
window.toast = toast;
window.setMode = setMode;
window.setLang = setLang;
window.setAuthTab = setAuthTab;
window.setAddFriendTab = setAddFriendTab;
window.setStaffRole = setStaffRole;
window.attachImage = attachImage;
window.attachFile = attachFile;
window.sendChatText = sendChatText;
window.toggleMute = toggleMute;
window.toggleSpeaker = toggleSpeaker;
window.openAi = openAi;
window.closeAi = closeAi;
window.sendAiMessage = sendAiMessage;
window.postMoment = postMoment;
window.markNotifsRead = markNotifsRead;
window.sendFriendRequest = sendFriendRequest;
window.acceptFriend = acceptFriend;
window.rejectFriend = rejectFriend;
window.tryAdminAddContact = tryAdminAddContact;
window.state = state;
window.t = t;

applyDir();
render();

/* Deep-link for screenshots / demos: ?lang=ar&screen=moments&role=super */
(function bootFromQuery() {
  try {
    const params = new URLSearchParams(location.search);
    if (params.get("lang") === "en" || params.get("lang") === "ar") setLang(params.get("lang"));
    if (params.get("role") === "employee" || params.get("role") === "super") {
      state.staffRole = params.get("role");
    }
    const screen = params.get("screen");
    if (screen) {
      if (["adminDash","adminStaff","adminOrders","adminOversight","adminTranscript","adminAddContact","adminWebDash","adminWebStaff","adminWebOversight"].includes(screen)) {
        state.staffLoggedIn = true;
      }
      if (["adminWebDash","adminWebStaff","adminWebOversight"].includes(screen)) state.mode = "adminWeb";
      go(screen);
    }
  } catch (e) { /* ignore */ }
})();
