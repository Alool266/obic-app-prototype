(function () {
  const ICONS = {
    legal: '<svg viewBox="0 0 24 24"><path d="m14 4-4 4M9.5 6.5 18 15M8 16l-4 4M16 8l4-4M3 21h7M14 21h7"/></svg>',
    flight: '<svg viewBox="0 0 24 24"><path d="M17.8 19.2 16 11l3.5-3.5C20 7 20.5 5.5 19 4s-3 0-3.5 1.5L12 9 3.8 6.2 2.5 7.8 10 12l-2.2 6.2 1.8 1.2 3.2-4.5 4.5 2.5z"/></svg>',
    bank: '<svg viewBox="0 0 24 24"><path d="M3 21h18M3 10h18M12 3l9 7H3l9-7zM6 10v11M10 10v11M14 10v11M18 10v11"/></svg>',
    hotel: '<svg viewBox="0 0 24 24"><path d="M3 21h18"/><path d="M5 21V7l7-4 7 4v14"/><path d="M9 21v-6h6v6"/><path d="M9 10h.01M15 10h.01"/></svg>',
    visa: '<svg viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 10h18M7 15h2"/></svg>',
    company: '<svg viewBox="0 0 24 24"><path d="M3 21h18M5 21V8l7-4 7 4v13M9 21v-6h6v6"/></svg>',
    vip: '<svg viewBox="0 0 24 24"><path d="m12 3 2.5 6.5L21 10l-5 4.2L17.5 21 12 17.5 6.5 21 8 14.2 3 10l6.5-.5L12 3z"/></svg>',
    payments: '<svg viewBox="0 0 24 24"><rect x="2" y="6" width="20" height="12" rx="2"/><path d="M2 10h20"/></svg>',
    school: '<svg viewBox="0 0 24 24"><path d="m12 3 10 5-10 5L2 8l10-5z"/><path d="M6 10.5V16c0 1.5 2.5 3 6 3s6-1.5 6-3v-5.5"/></svg>',
    ads: '<svg viewBox="0 0 24 24"><path d="M3 11v2a4 4 0 0 0 4 4h1l4 4V7L8 11H7a4 4 0 0 0-4 0z"/><path d="M16 9a4 4 0 0 1 0 6M18.5 7a7 7 0 0 1 0 10"/></svg>',
    business: '<svg viewBox="0 0 24 24"><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/><rect x="3" y="7" width="18" height="14" rx="2"/></svg>',
    hr: '<svg viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></svg>',
    shield: '<svg viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>',
    globe: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15 15 0 0 1 0 20M12 2a15 15 0 0 0 0 20"/></svg>',
    tech: '<svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/></svg>',
    plan: '<svg viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6M8 13h8M8 17h6"/></svg>',
  };

  const COPY = {
    en: {
      navHome: "Home",
      navServices: "Services",
      navAbout: "About",
      navContact: "Contact",
      navAi: "OBIC AI",
      botHello: "Ask about visas, hotels, flights, or any OBIC service.",
      botHint: "Write a message…",
      botSend: "Send",
      botOpen: "Full chat",
      botClose: "Close",
      botNew: "New",
      botChats: "Chats",
      botSaved: "This chat stays on this browser, so you can come back to it.",
      botBusy: "OBIC AI is busy right now. Send that again in a moment.",
      botYou: "You",
      botAttach: "Attach",
      botPhoto: "Photo",
      botPdf: "PDF",
      botSheet: "Spreadsheet",
      botRemove: "Remove",
      botTooBig: "This file is over 4 MB. Choose a smaller one.",
      botUnsupported: "Only JPEG, PNG, or WebP photos, PDF, and Excel or CSV spreadsheets are supported.",
      botUnreadable: "Could not read this file.",
      navLogin: "Login",
      navRegister: "Register",
      navAccount: "Account",
      navLogout: "Logout",
      accountTitle: "Your account",
      accountSub: "Manage orders, profile, and messages with OBIC.",
      accountHello: "Welcome,",
      accountOrders: "My orders",
      accountOrdersSub: "Track service requests and bookings",
      accountProfile: "Profile settings",
      accountProfileSub: "Name, photo, and password",
      accountChat: "Messages",
      accountChatSub: "Chat with your OBIC advisor",
      accountBrowse: "Browse services",
      accountBrowseSub: "Visa, hotels, banking, and more",
      accountGuestTitle: "Sign in to continue",
      accountGuestBody: "Log in to see your orders and talk with our team.",
      accountDetails: "Account details",
      accountLabelName: "Name",
      accountLabelEmail: "Email",
      accountLabelPhone: "Phone",
      profileEyebrow: "Profile",
      profileTabInfo: "Profile info",
      profileTabPassword: "Password",
      profileTabSettings: "Account",
      profilePassport: "Passport number",
      profileAddress: "Address",
      profileCountry: "Country",
      profileCountryPick: "Select country",
      profileSave: "Save profile",
      profileCurrentPassword: "Current password",
      profileNewPassword: "New password",
      profileConfirmPassword: "Confirm new password",
      profileSavePassword: "Update password",
      profileStatusTitle: "Account status",
      profileStatusNow: "Your account is",
      profileDeleteTitle: "Delete account",
      profileDeleteBody: "Once deleted, your account cannot be restored.",
      profileDeleteConfirm: "Delete my account",
      profileDeleteConfirmAsk: "Delete your account permanently?",
      profileRemovePhoto: "Remove photo",
      profileRemovePhotoAsk: "Remove profile photo?",
      profileChangePhoto: "Change photo",
      profileSaved: "Profile updated.",
      profilePasswordSaved: "Password updated.",
      profilePhotoSaved: "Photo updated.",
      profilePhotoRemoved: "Photo removed.",
      profileError: "Something went wrong.",
      ordersEyebrow: "Orders",
      ordersAll: "All",
      ordersPending: "Pending",
      ordersConfirmed: "Confirmed",
      ordersCompleted: "Completed",
      ordersCancelled: "Cancelled",
      ordersEmpty: "No orders yet. Browse services to get started.",
      ordersView: "View",
      ordersPay: "Pay",
      ordersCancel: "Cancel",
      ordersCancelAsk: "Cancel this order?",
      ordersPrice: "Total",
      ordersPayment: "Payment",
      chatEyebrow: "Support",
      chatPlaceholder: "Write a message…",
      chatSend: "Send",
      chatEmpty: "Say hello — our team will reply here.",
      chatYou: "You",
      chatAdvisor: "OBIC advisor",
      chatUnavailable: "Chat is temporarily unavailable. Please try again later.",
      chatGeneral: "General support",
      chatThreads: "Your chats",
      chatServiceSub: "Chat about this service with your OBIC advisor",
      chatEmptyShort: "No messages yet",
      heroLine: "Your bridge to China — services, travel, and business in one place.",
      heroSub: "Visa, hotels, flights, banking, VIP, and business support — on the web and in the OBIC app.",
      ctaServices: "Browse services",
      ctaContact: "Talk to us",
      ctaWhatsApp: "WhatsApp",
      slideEyebrow: "Most used",
      slideTitle: "What people open first",
      slideSub: "Food, hotels, visas, flights, health, and shopping — a normal day in China, in one place.",
      slidePrev: "Previous",
      slideNext: "Next",
      slideFoodTag: "Every day",
      slideFood: "Food",
      slideFoodLine: "Meals, coffee, and delivery",
      slideHotelTag: "Stay",
      slideHotel: "Hotels",
      slideHotelLine: "A place to stay in China",
      slideVisaTag: "Travel",
      slideVisa: "Visa",
      slideVisaLine: "China visa, handled with you",
      slideFlightTag: "Trips",
      slideFlight: "Flights",
      slideFlightLine: "Tickets and travel plans",
      slideHealthTag: "Care",
      slideHealth: "Health",
      slideHealthLine: "Clinics, pharmacies, and care",
      slideShopTag: "Daily",
      slideShop: "Shopping",
      slideShopLine: "Stores and what you need today",
      servicesEyebrow: "Services",
      servicesTitle: "Professional services across China",
      servicesSub: "From visa and travel to banking, VIP support, and business setup — choose the service you need.",
      aboutEyebrow: "Company",
      aboutTitle: "Built for people and businesses entering China",
      aboutBody:
        "OBIC supports travelers, students, and companies with visa, banking, VIP hosting, and business operations — with guidance in Arabic, English, and Chinese.",
      aboutCta: "About OBIC",
      panelTitle: "Local team. Clear process.",
      panelBody: "From first inquiry to delivery — one partner for travel and business needs.",
      depthTitle: "Ready when you are",
      depthBody: "Create an account, or speak with our team about your next step in China.",
      appEyebrow: "Try the app",
      appTitle: "Enough for everything you need in life",
      appBody: "OBIC is enough for everything you need in your life. Chat, food, hotels, health, travel, visas, and the rest of your day in China — one account on the website and in the app.",
      appBadge: "Coming soon",
      appPoint1: "Ten service areas in one app",
      appPoint2: "Follow every order with your advisor",
      appPoint3: "Arabic, English, and Chinese",
      appCta: "Explore services now",
      appSoonStore: "Store listing soon",
      appHint: "Move your cursor · tap a screen above",
      appTabHome: "Home",
      appTabOrders: "Orders",
      appTabChat: "Chat",
      appUiHello: "Your bridge to China",
      appUiProp: "Property",
      appUiTravel: "Travel",
      appUiVisa: "Visa",
      appUiFood: "Food",
      appUiShop: "Shop",
      appUiHealth: "Health",
      appUiEdu: "Study",
      appUiBiz: "Business",
      appBrandTag: "Chat · Food · Hotels · Health & more",
      appSearch: "Search food, hotels, health, visas…",
      appGreet: "Social life & daily China",
      appHintShort: "Chat, Moments, friends and calls — plus food, hotels, health, travel and more.",
      appNavHome: "Home",
      appNavServices: "Services",
      appNavMessages: "Messages",
      appNavContacts: "Contacts",
      appNavDiscover: "Discover",
      appNavMe: "Me",
      appSvcProperty: "Property",
      appSvcTransport: "Transport",
      appSvcTravel: "Travel",
      appSvcHealth: "Health",
      appSvcFood: "Food",
      appSvcShop: "Shop",
      appSvcStudy: "Study",
      appSvcLogistics: "Logistics",
      appSvcGovernment: "Government",
      appSvcBusiness: "Business",
      appUiBanner: "Visa · Hotels · VIP",
      appUiStatus: "In progress",
      appUiDone: "Completed",
      appUiWait: "Waiting for you",
      appUiOrder1: "China visa support",
      appUiOrder2: "Hotel booking",
      appUiOrder3: "Bank account",
      appUiBranch: "Yiwu branch",
      appUiDocs: "Upload documents",
      appUiMsg1: "Your visa file is under review.",
      appUiMsg2: "Thanks — I sent the passport photo.",
      appUiMsg3: "Received. We will update you today.",
      appUiType: "Message…",
      loginTitle: "Sign in to your account",
      loginSub: "Use your email or phone number.",
      authAside: "Your bridge to China — services, travel, and business.",
      tabEmail: "Email",
      tabPhone: "Phone",
      labelEmail: "Email address",
      labelPassword: "Password",
      labelPhone: "Phone number",
      labelName: "Full name",
      labelConfirm: "Confirm password",
      remember: "Remember me",
      forgot: "Forgot password?",
      noAccount: "Don't have an account?",
      haveAccount: "Already have an account?",
      registerTitle: "Create your account",
      registerSub: "Join OBIC to request services across China.",
      trust1: "7 branches · Yiwu HQ",
      trust2: "Arabic · English · 中文",
      trust3: "Website & mobile app",
      trust4: "10 service areas",
      pathwaysEyebrow: "Start here",
      pathwaysTitle: "Two clear pathways",
      pathwaysSub:
        "Scholarships and company setup — full forms with the same documents OBIC staff review in the desk.",
      pathStudyEyebrow: "Study in China",
      pathStudyTitle: "Scholarships & university pathways",
      pathStudyBody:
        "CSC / university routes, study plan, transcripts, and WeChat contact — submitted to the scholarships desk.",
      pathStudyCta: "Open scholarship form →",
      pathCompanyEyebrow: "Business in China",
      pathCompanyTitle: "Open a company",
      pathCompanyBody:
        "WFOE, trading, and local structures — passport, photo, qualification, and criminal record like the app checklist.",
      pathCompanyCta: "Open company form →",
      quotesEyebrow: "Clients",
      quotesTitle: "How people use OBIC",
      quote1: "Visa papers and the hotel were handled together, so I arrived in Yiwu with a plan instead of a pile of questions.",
      quote1By: "Traveler · Yiwu",
      quote2: "One desk for the bank visit, the factory meetings, and the Arabic-speaking advisor on the phone.",
      quote2By: "Trading company",
      quote3: "We asked in Arabic and got the next step in the same day — pickup, documents, and who to meet.",
      quote3By: "Business visitor",
      storeApple: "App Store",
      storeGoogle: "Google Play",
      storeSoon: "Coming soon",
      finalTitle: "Start with one conversation",
      finalBody: "Register on the site, or message the team on WhatsApp. The app is on the way to the App Store and Google Play.",
      footerServices: "Services",
      footerApp: "The app",
      stepsEyebrow: "How it works",
      stepsTitle: "From one message to a finished order",
      step1Title: "Tell us",
      step1Body: "WhatsApp or the form. Visa, hotel, flight, bank visit, or VIP.",
      step2Title: "Your branch",
      step2Body: "A local advisor replies in Arabic, English, or Chinese.",
      step3Title: "Follow it",
      step3Body: "Orders and chat in the app, on the same account as this site.",
      branchesEyebrow: "Branches",
      branchesTitle: "Seven OBIC branches",
      branchesSub: "Yiwu is the primary hub. Local teams across China and Yemen — pick the closest branch when you request a service.",
      brYiwu: "Yiwu",
      brYiwuRole: "Primary hub · Mr. Yasser",
      brGuangzhou: "Guangzhou",
      brGuangzhouRole: "Mr. Amin",
      brFoshan: "Foshan",
      brFoshanRole: "Mr. Wajih",
      brHangzhou: "Hangzhou",
      brHangzhouRole: "Mr. Mohammed",
      brHainan: "Hainan",
      brHainanRole: "Mr. Ahmed",
      brYemen: "Yemen",
      brYemenRole: "Bahi",
      brShanghai: "Shanghai",
      brShanghaiRole: "Mr. Khaled",
      footerAbout: "Professional services for international clients operating and traveling in China.",
      footerLinks: "Links",
      footerContact: "Contact",
      contactLead: "Tell us what you need in China. Our team will follow up with clear next steps.",
      send: "Send message",
      open: "Open",
      legalTerms: "Terms",
      legalPrivacy: "Privacy",
      legalAgree: "By creating an account you agree to the",
      legalAnd: "and",
      copy: "© 2026 OBIC. All rights reserved.",
      comingListings: "Request this service — our team will guide you.",
      catSearch: "Search",
      catSearchPh: "Search services",
      catSearchBtn: "Search",
      catMin: "Min price",
      catMax: "Max price",
      catAll: "All categories",
      catView: "View details",
      catUntitled: "Service",
      catLoading: "Loading services…",
      catCount: "{n} listings",
      catEmptyCount: "No listings yet",
      catEmptyTitle: "Nothing listed here yet",
      catEmptyBody: "Contact our team and we will set up this service for you.",
      catErrorTitle: "Could not load listings",
      catErrorBody: "Please try again, or contact us for help.",
      phone: "15257977914",
      email: "obicproject117@gmail.com",
      address: "Road of Safety",
    },
    ar: {
      navHome: "الرئيسية",
      navServices: "الخدمات",
      navAbout: "من نحن",
      navContact: "تواصل",
      navAi: "أوبك AI",
      botHello: "اسأل عن التأشيرة أو الفنادق أو الطيران أو أي خدمة في أوبك.",
      botHint: "اكتب رسالة…",
      botSend: "إرسال",
      botOpen: "المحادثة الكاملة",
      botClose: "إغلاق",
      botNew: "جديد",
      botChats: "المحادثات",
      botSaved: "تبقى هذه المحادثة في هذا المتصفح حتى تعود إليها.",
      botBusy: "أوبك AI مشغول الآن. أعد الإرسال بعد لحظة.",
      botYou: "أنت",
      botAttach: "إرفاق",
      botPhoto: "صورة",
      botPdf: "PDF",
      botSheet: "جدول",
      botRemove: "إزالة",
      botTooBig: "الملف أكبر من ٤ ميغابايت. اختر ملفاً أصغر.",
      botUnsupported: "يُقبل فقط صور JPEG أو PNG أو WebP، أو PDF، أو Excel أو CSV.",
      botUnreadable: "تعذّر قراءة هذا الملف.",
      navLogin: "دخول",
      navRegister: "تسجيل",
      navAccount: "حسابي",
      navLogout: "خروج",
      accountTitle: "حسابك",
      accountSub: "إدارة الطلبات والملف والرسائل مع OBIC.",
      accountHello: "مرحباً،",
      accountOrders: "طلباتي",
      accountOrdersSub: "تابع طلبات الخدمات والحجوزات",
      accountProfile: "إعدادات الملف",
      accountProfileSub: "الاسم والصورة وكلمة المرور",
      accountChat: "الرسائل",
      accountChatSub: "محادثة مع مستشار OBIC",
      accountBrowse: "استعرض الخدمات",
      accountBrowseSub: "تأشيرة، فنادق، بنوك، والمزيد",
      accountGuestTitle: "سجّل الدخول للمتابعة",
      accountGuestBody: "ادخل لرؤية طلباتك والتواصل مع فريقنا.",
      accountDetails: "بيانات الحساب",
      accountLabelName: "الاسم",
      accountLabelEmail: "البريد",
      accountLabelPhone: "الهاتف",
      profileEyebrow: "الملف",
      profileTabInfo: "معلومات الملف",
      profileTabPassword: "كلمة المرور",
      profileTabSettings: "الحساب",
      profilePassport: "رقم جواز السفر",
      profileAddress: "العنوان",
      profileCountry: "البلد",
      profileCountryPick: "اختر الدولة",
      profileSave: "حفظ الملف",
      profileCurrentPassword: "كلمة المرور الحالية",
      profileNewPassword: "كلمة المرور الجديدة",
      profileConfirmPassword: "تأكيد كلمة المرور الجديدة",
      profileSavePassword: "تحديث كلمة المرور",
      profileStatusTitle: "حالة الحساب",
      profileStatusNow: "حسابك حالياً",
      profileDeleteTitle: "حذف الحساب",
      profileDeleteBody: "بعد الحذف لا يمكن استرجاع الحساب.",
      profileDeleteConfirm: "احذف حسابي",
      profileDeleteConfirmAsk: "حذف الحساب نهائياً؟",
      profileRemovePhoto: "إزالة الصورة",
      profileRemovePhotoAsk: "إزالة صورة الملف؟",
      profileChangePhoto: "تغيير الصورة",
      profileSaved: "تم تحديث الملف.",
      profilePasswordSaved: "تم تحديث كلمة المرور.",
      profilePhotoSaved: "تم تحديث الصورة.",
      profilePhotoRemoved: "تم إزالة الصورة.",
      profileError: "حدث خطأ. حاول مرة أخرى.",
      ordersEyebrow: "الطلبات",
      ordersAll: "الكل",
      ordersPending: "معلق",
      ordersConfirmed: "مؤكد",
      ordersCompleted: "مكتمل",
      ordersCancelled: "ملغى",
      ordersEmpty: "لا طلبات بعد. استعرض الخدمات للبدء.",
      ordersView: "عرض",
      ordersPay: "ادفع",
      ordersCancel: "إلغاء",
      ordersCancelAsk: "إلغاء هذا الطلب؟",
      ordersPrice: "الإجمالي",
      ordersPayment: "الدفع",
      chatEyebrow: "الدعم",
      chatPlaceholder: "اكتب رسالة…",
      chatSend: "إرسال",
      chatEmpty: "ابدأ المحادثة — فريقنا يرد هنا.",
      chatYou: "أنت",
      chatAdvisor: "مستشار OBIC",
      chatUnavailable: "المحادثة غير متاحة مؤقتاً. حاول لاحقاً.",
      chatGeneral: "الدعم العام",
      chatThreads: "محادثاتك",
      chatServiceSub: "محادثة حول هذه الخدمة مع مستشار OBIC",
      chatEmptyShort: "لا رسائل بعد",
      heroLine: "جسرُك إلى الصين — خدمات وسفر وأعمال في مكان واحد.",
      heroSub: "تأشيرة، فنادق، طيران، بنوك، VIP، وأعمال — على الموقع وفي تطبيق OBIC.",
      ctaServices: "استعرض الخدمات",
      ctaContact: "تواصل معنا",
      ctaWhatsApp: "واتساب",
      slideEyebrow: "الأكثر استخداماً",
      slideTitle: "ما يفتحه الناس أولاً",
      slideSub: "طعام وفنادق وتأشيرات وطيران وصحة وتسوق — يوم عادي في الصين، في مكان واحد.",
      slidePrev: "السابق",
      slideNext: "التالي",
      slideFoodTag: "كل يوم",
      slideFood: "طعام",
      slideFoodLine: "وجبات وقهوة وتوصيل",
      slideHotelTag: "إقامة",
      slideHotel: "فنادق",
      slideHotelLine: "مكان للإقامة في الصين",
      slideVisaTag: "سفر",
      slideVisa: "تأشيرة",
      slideVisaLine: "تأشيرة الصين مع فريقك",
      slideFlightTag: "رحلات",
      slideFlight: "طيران",
      slideFlightLine: "تذاكر وخطط سفر",
      slideHealthTag: "رعاية",
      slideHealth: "صحة",
      slideHealthLine: "عيادات وصيدليات ورعاية",
      slideShopTag: "يومي",
      slideShop: "تسوق",
      slideShopLine: "متاجر وما تحتاجه اليوم",
      servicesEyebrow: "الخدمات",
      servicesTitle: "خدمات احترافية في الصين",
      servicesSub: "من التأشيرة والسفر إلى البنوك ودعم VIP وتأسيس الأعمال — اختر الخدمة التي تحتاجها.",
      aboutEyebrow: "الشركة",
      aboutTitle: "لمن يدخل الصين للأفراد والأعمال",
      aboutBody:
        "OBIC يدعم المسافرين والطلاب والشركات بالتأشيرة والبنوك واستقبال VIP وعمليات الأعمال — بالعربية والإنجليزية والصينية.",
      aboutCta: "عن OBIC",
      panelTitle: "فريق محلي. مسار واضح.",
      panelBody: "من أول استفسار حتى التسليم — شريك واحد لاحتياجات السفر والأعمال.",
      depthTitle: "جاهزون عندما تكون جاهزاً",
      depthBody: "أنشئ حساباً، أو تحدّث مع فريقنا عن خطوتك التالية في الصين.",
      appEyebrow: "جرّب التطبيق",
      appTitle: "يكفي لكل ما تحتاجه في حياتك",
      appBody: "أوبك يكفي لكل ما تحتاجه في حياتك. دردشة وطعام وفنادق وصحة وسفر وتأشيرات وباقي يومك في الصين — حساب واحد في الموقع وفي التطبيق.",
      appBadge: "قريباً",
      appPoint1: "عشرة مجالات خدمة في تطبيق واحد",
      appPoint2: "تابع كل طلب مع مستشارك",
      appPoint3: "العربية والإنجليزية والصينية",
      appCta: "استكشف الخدمات الآن",
      appSoonStore: "قريباً في المتاجر",
      appHint: "حرّك المؤشر · اختر شاشة من الأعلى",
      appTabHome: "الرئيسية",
      appTabOrders: "الطلبات",
      appTabChat: "محادثة",
      appUiHello: "جسرُك إلى الصين",
      appUiProp: "عقارات",
      appUiTravel: "سفر",
      appUiVisa: "تأشيرة",
      appUiFood: "طعام",
      appUiShop: "تسوق",
      appUiHealth: "صحة",
      appUiEdu: "تعليم",
      appUiBiz: "أعمال",
      appBrandTag: "دردشة · طعام · فنادق · صحة والمزيد",
      appSearch: "ابحث عن طعام، فنادق، صحة، تأشيرات…",
      appGreet: "حياتك الاجتماعية ويوميات الصين",
      appHintShort: "دردشة ولحظات وأصدقاء ومكالمات — مع طعام وفنادق وصحة وسفر والمزيد.",
      appNavHome: "الرئيسية",
      appNavServices: "الخدمات",
      appNavMessages: "الرسائل",
      appNavContacts: "جهات",
      appNavDiscover: "اكتشف",
      appNavMe: "حسابي",
      appSvcProperty: "عقارات",
      appSvcTransport: "نقل",
      appSvcTravel: "سياحة",
      appSvcHealth: "صحة",
      appSvcFood: "طعام",
      appSvcShop: "تسوق",
      appSvcStudy: "تعليم",
      appSvcLogistics: "شحن",
      appSvcGovernment: "حكومة",
      appSvcBusiness: "أعمال",
      appUiBanner: "تأشيرة · فنادق · VIP",
      appUiStatus: "قيد التنفيذ",
      appUiDone: "مكتمل",
      appUiWait: "بانتظارك",
      appUiOrder1: "دعم تأشيرة الصين",
      appUiOrder2: "حجز فندق",
      appUiOrder3: "حساب بنكي",
      appUiBranch: "فرع إيوو",
      appUiDocs: "ارفع المستندات",
      appUiMsg1: "ملف التأشيرة قيد المراجعة.",
      appUiMsg2: "شكراً — أرسلت صورة الجواز.",
      appUiMsg3: "وصلنا. نحدّثك اليوم.",
      appUiType: "اكتب رسالة…",
      loginTitle: "تسجيل الدخول إلى حسابك",
      loginSub: "استخدم البريد أو رقم الهاتف.",
      authAside: "جسرُك إلى الصين — خدمات وسفر وأعمال.",
      tabEmail: "بريد",
      tabPhone: "هاتف",
      labelEmail: "البريد الإلكتروني",
      labelPassword: "كلمة المرور",
      labelPhone: "رقم الهاتف",
      labelName: "الاسم الكامل",
      labelConfirm: "تأكيد كلمة المرور",
      remember: "تذكرني",
      forgot: "نسيت كلمة المرور؟",
      noAccount: "ليس لديك حساب؟",
      haveAccount: "لديك حساب بالفعل؟",
      registerTitle: "إنشاء حساب",
      registerSub: "انضم إلى OBIC لطلب الخدمات في الصين.",
      trust1: "7 فروع · المقر إيوو",
      trust2: "العربية والإنجليزية والصينية",
      trust3: "الموقع وتطبيق الجوال",
      trust4: "عشرة مجالات للخدمات",
      pathwaysEyebrow: "ابدأ من هنا",
      pathwaysTitle: "مساران واضحان",
      pathwaysSub:
        "المنح وتأسيس الشركات — نماذج كاملة بنفس المستندات التي يراجعها مكتب أوبك.",
      pathStudyEyebrow: "الدراسة في الصين",
      pathStudyTitle: "المنح والمسارات الجامعية",
      pathStudyBody:
        "مسارات CSC / جامعية وخطة دراسة وكشوفات وويتشات — تُرسل لمكتب المنح.",
      pathStudyCta: "افتح نموذج المنح ←",
      pathCompanyEyebrow: "الأعمال في الصين",
      pathCompanyTitle: "فتح شركة",
      pathCompanyBody:
        "WFOE وتجارة وهياكل محلية — جواز وصورة ومؤهل وسجل جنائي كما في التطبيق.",
      pathCompanyCta: "افتح نموذج الشركة ←",
      quotesEyebrow: "العملاء",
      quotesTitle: "كيف يستخدم الناس OBIC",
      quote1: "تجهّزت التأشيرة والفندق معاً، فوصلت إلى إيوو بخطة بدل كومة من الأسئلة.",
      quote1By: "مسافر · إيوو",
      quote2: "مكتب واحد لزيارة البنك واجتماعات المصنع ومستشار يتحدث العربية.",
      quote2By: "شركة تجارية",
      quote3: "سألنا بالعربية وجاءت الخطوة التالية في اليوم نفسه — الاستقبال والوثائق ومن نقابل.",
      quote3By: "زائر أعمال",
      storeApple: "App Store",
      storeGoogle: "Google Play",
      storeSoon: "قريباً",
      finalTitle: "ابدأ بمحادثة واحدة",
      finalBody: "سجّل في الموقع، أو راسل الفريق على واتساب. التطبيق في طريقه إلى آب ستور وجوجل بلاي.",
      footerServices: "الخدمات",
      footerApp: "التطبيق",
      stepsEyebrow: "كيف تعمل",
      stepsTitle: "من رسالة واحدة إلى طلب مكتمل",
      step1Title: "أخبرنا",
      step1Body: "واتساب أو النموذج. تأشيرة، فندق، طيران، بنك، أو استقبال VIP.",
      step2Title: "فرعك",
      step2Body: "مستشار محلي يرد بالعربية أو الإنجليزية أو الصينية.",
      step3Title: "تابع",
      step3Body: "الطلبات والمحادثة في التطبيق، بنفس حساب هذا الموقع.",
      branchesEyebrow: "الفروع",
      branchesTitle: "سبعة فروع لـ OBIC",
      branchesSub: "إيوو هو الفرع الرئيسي. فرق محلية في الصين واليمن — اختر أقرب فرع عند طلب الخدمة.",
      brYiwu: "إيوو",
      brYiwuRole: "الفرع الرئيسي · الأستاذ ياسر",
      brGuangzhou: "قوانغتشو",
      brGuangzhouRole: "الأستاذ أمين",
      brFoshan: "فوشان",
      brFoshanRole: "الأستاذ وجيه",
      brHangzhou: "هانغتشو",
      brHangzhouRole: "الأستاذ محمد",
      brHainan: "هاينان",
      brHainanRole: "الأستاذ أحمد",
      brYemen: "اليمن",
      brYemenRole: "باهي",
      brShanghai: "شنغهاي",
      brShanghaiRole: "الأستاذ خالد",
      footerAbout: "خدمات احترافية للعملاء الدوليين في العمل والسفر داخل الصين.",
      footerLinks: "روابط",
      footerContact: "تواصل",
      contactLead: "أخبرنا بما تحتاجه في الصين. يتابع فريقنا بخطوات واضحة.",
      send: "إرسال الرسالة",
      open: "فتح",
      legalTerms: "الشروط",
      legalPrivacy: "الخصوصية",
      legalAgree: "بإنشاء حساب فإنك توافق على",
      legalAnd: "و",
      copy: "© 2026 OBIC. جميع الحقوق محفوظة.",
      comingListings: "اطلب هذه الخدمة — فريقنا يرشدك خطوة بخطوة.",
      catSearch: "بحث",
      catSearchPh: "ابحث في الخدمات",
      catSearchBtn: "بحث",
      catMin: "أقل سعر",
      catMax: "أعلى سعر",
      catAll: "كل التصنيفات",
      catView: "عرض التفاصيل",
      catUntitled: "خدمة",
      catLoading: "جاري تحميل الخدمات…",
      catCount: "{n} عرض",
      catEmptyCount: "لا عروض بعد",
      catEmptyTitle: "لا توجد عروض هنا بعد",
      catEmptyBody: "تواصل مع فريقنا وسنجهّز هذه الخدمة لك.",
      catErrorTitle: "تعذر تحميل العروض",
      catErrorBody: "حاول مجدداً، أو تواصل معنا للمساعدة.",
      phone: "15257977914",
      email: "obicproject117@gmail.com",
      address: "Road of Safety",
    },
    zh: {
      navHome: "首页",
      navServices: "服务",
      navAbout: "关于",
      navContact: "联系",
      navAi: "OBIC AI",
      botHello: "可咨询签证、酒店、机票，或 OBIC 的任何服务。",
      botHint: "写一条消息…",
      botSend: "发送",
      botOpen: "完整对话",
      botClose: "关闭",
      botNew: "新对话",
      botChats: "历史",
      botSaved: "对话保存在这台浏览器里，下次打开还能继续。",
      botBusy: "OBIC AI 这会儿正忙。请稍后再发一次。",
      botYou: "你",
      botAttach: "添加附件",
      botPhoto: "照片",
      botPdf: "PDF",
      botSheet: "表格",
      botRemove: "移除",
      botTooBig: "文件超过 4 MB，请选择更小的文件。",
      botUnsupported: "仅支持 JPEG、PNG、WebP 图片，以及 PDF、Excel 或 CSV。",
      botUnreadable: "无法读取此文件。",
      navLogin: "登录",
      navRegister: "注册",
      navAccount: "账户",
      navLogout: "退出",
      accountTitle: "您的账户",
      accountSub: "管理订单、资料与 OBIC 消息。",
      accountHello: "欢迎，",
      accountOrders: "我的订单",
      accountOrdersSub: "跟踪服务申请与预订",
      accountProfile: "资料设置",
      accountProfileSub: "姓名、头像与密码",
      accountChat: "消息",
      accountChatSub: "与 OBIC 顾问聊天",
      accountBrowse: "浏览服务",
      accountBrowseSub: "签证、酒店、银行等",
      accountGuestTitle: "请先登录",
      accountGuestBody: "登录后可查看订单并联系团队。",
      accountDetails: "账户信息",
      accountLabelName: "姓名",
      accountLabelEmail: "邮箱",
      accountLabelPhone: "手机",
      profileEyebrow: "个人资料",
      profileTabInfo: "资料信息",
      profileTabPassword: "密码",
      profileTabSettings: "账户",
      profilePassport: "护照号码",
      profileAddress: "地址",
      profileCountry: "国家",
      profileCountryPick: "选择国家",
      profileSave: "保存资料",
      profileCurrentPassword: "当前密码",
      profileNewPassword: "新密码",
      profileConfirmPassword: "确认新密码",
      profileSavePassword: "更新密码",
      profileStatusTitle: "账户状态",
      profileStatusNow: "当前状态",
      profileDeleteTitle: "删除账户",
      profileDeleteBody: "删除后无法恢复。",
      profileDeleteConfirm: "删除我的账户",
      profileDeleteConfirmAsk: "确定永久删除账户？",
      profileRemovePhoto: "移除头像",
      profileRemovePhotoAsk: "移除头像？",
      profileChangePhoto: "更换头像",
      profileSaved: "资料已更新。",
      profilePasswordSaved: "密码已更新。",
      profilePhotoSaved: "头像已更新。",
      profilePhotoRemoved: "头像已移除。",
      profileError: "出错了，请重试。",
      ordersEyebrow: "订单",
      ordersAll: "全部",
      ordersPending: "待处理",
      ordersConfirmed: "已确认",
      ordersCompleted: "已完成",
      ordersCancelled: "已取消",
      ordersEmpty: "暂无订单。浏览服务开始申请。",
      ordersView: "查看",
      ordersPay: "支付",
      ordersCancel: "取消",
      ordersCancelAsk: "取消此订单？",
      ordersPrice: "合计",
      ordersPayment: "支付状态",
      chatEyebrow: "客服",
      chatPlaceholder: "输入消息…",
      chatSend: "发送",
      chatEmpty: "打个招呼吧 — 顾问会在这里回复。",
      chatYou: "我",
      chatAdvisor: "OBIC 顾问",
      chatUnavailable: "聊天暂时不可用，请稍后再试。",
      chatGeneral: "综合客服",
      chatThreads: "我的会话",
      chatServiceSub: "就此服务与 OBIC 顾问沟通",
      chatEmptyShort: "暂无消息",
      heroLine: "连接中国的桥梁 — 服务、出行与商务一站完成。",
      heroSub: "签证、酒店、机票、开户、VIP 与商务支持 — 网站与 OBIC App 同步可用。",
      ctaServices: "浏览服务",
      ctaContact: "联系我们",
      ctaWhatsApp: "WhatsApp",
      slideEyebrow: "最常用",
      slideTitle: "大家最先打开的",
      slideSub: "餐饮、酒店、签证、机票、健康与购物 — 在中国的普通一天，都在这里。",
      slidePrev: "上一张",
      slideNext: "下一张",
      slideFoodTag: "每天",
      slideFood: "餐饮",
      slideFoodLine: "用餐、咖啡与外卖",
      slideHotelTag: "住宿",
      slideHotel: "酒店",
      slideHotelLine: "在中国的落脚处",
      slideVisaTag: "出行",
      slideVisa: "签证",
      slideVisaLine: "中国签证，有人陪办",
      slideFlightTag: "行程",
      slideFlight: "机票",
      slideFlightLine: "机票与出行安排",
      slideHealthTag: "健康",
      slideHealth: "医疗",
      slideHealthLine: "诊所、药店与就医",
      slideShopTag: "日常",
      slideShop: "购物",
      slideShopLine: "商店与当天所需",
      servicesEyebrow: "服务",
      servicesTitle: "覆盖中国的专业服务",
      servicesSub: "从签证与出行，到开户、VIP 支持与商务落地 — 选择您所需的服务。",
      aboutEyebrow: "公司",
      aboutTitle: "为进入中国的个人与企业而建",
      aboutBody: "OBIC 为旅行者、学生与企业提供签证、开户、VIP 接待与商务运营支持 — 阿语 / 英语 / 中文。",
      aboutCta: "关于 OBIC",
      panelTitle: "本地团队。清晰流程。",
      panelBody: "从首次咨询到交付 — 出行与商务需求的一站式伙伴。",
      depthTitle: "随时为您准备就绪",
      depthBody: "创建账户，或与我们的团队讨论您在中国的下一步。",
      appEyebrow: "体验应用",
      appTitle: "生活所需，OBIC 就够了",
      appBody: "OBIC 足够应付你生活里需要的一切。聊天、餐饮、酒店、健康、出行、签证，以及在华的日常事务，网站和应用使用同一个账户。",
      appBadge: "即将推出",
      appPoint1: "十大服务领域，一站完成",
      appPoint2: "与顾问一起跟进每一笔订单",
      appPoint3: "支持阿语、英语与中文",
      appCta: "立即浏览服务",
      appSoonStore: "即将上架应用商店",
      appHint: "移动光标 · 点上方切换界面",
      appTabHome: "首页",
      appTabOrders: "订单",
      appTabChat: "聊天",
      appUiHello: "连接中国的桥梁",
      appUiProp: "房产",
      appUiTravel: "出行",
      appUiVisa: "签证",
      appUiFood: "餐饮",
      appUiShop: "购物",
      appUiHealth: "医疗",
      appUiEdu: "学习",
      appUiBiz: "商务",
      appBrandTag: "聊天 · 餐饮 · 酒店 · 健康等",
      appSearch: "搜索餐饮、酒店、健康、签证…",
      appGreet: "社交与在华日常",
      appHintShort: "聊天、动态、好友与通话——还可订餐、订酒店、问诊、出行等。",
      appNavHome: "首页",
      appNavServices: "服务",
      appNavMessages: "消息",
      appNavContacts: "通讯录",
      appNavDiscover: "发现",
      appNavMe: "我的",
      appSvcProperty: "房产",
      appSvcTransport: "交通",
      appSvcTravel: "旅游",
      appSvcHealth: "医疗",
      appSvcFood: "餐饮",
      appSvcShop: "购物",
      appSvcStudy: "教育",
      appSvcLogistics: "物流",
      appSvcGovernment: "政务",
      appSvcBusiness: "商务",
      appUiBanner: "签证 · 酒店 · VIP",
      appUiStatus: "处理中",
      appUiDone: "已完成",
      appUiWait: "等待您",
      appUiOrder1: "中国签证支持",
      appUiOrder2: "酒店预订",
      appUiOrder3: "银行开户",
      appUiBranch: "义乌分公司",
      appUiDocs: "上传材料",
      appUiMsg1: "您的签证材料正在审核。",
      appUiMsg2: "谢谢 — 护照照片已发送。",
      appUiMsg3: "已收到。今天会给您更新。",
      appUiType: "输入消息…",
      loginTitle: "登录您的账户",
      loginSub: "使用邮箱或手机号登录。",
      authAside: "连接中国的桥梁 — 服务、出行与商务。",
      tabEmail: "邮箱",
      tabPhone: "手机",
      labelEmail: "邮箱地址",
      labelPassword: "密码",
      labelPhone: "手机号",
      labelName: "姓名",
      labelConfirm: "确认密码",
      remember: "记住我",
      forgot: "忘记密码？",
      noAccount: "还没有账户？",
      haveAccount: "已有账户？",
      registerTitle: "创建账户",
      registerSub: "加入 OBIC，申请在华服务。",
      trust1: "7 家分支 · 义乌总部",
      trust2: "阿语 · 英语 · 中文",
      trust3: "网站与移动应用",
      trust4: "10 个服务领域",
      pathwaysEyebrow: "从这里开始",
      pathwaysTitle: "两条清晰路径",
      pathwaysSub: "奖学金与公司注册——完整表单，材料与后台审阅清单一致。",
      pathStudyEyebrow: "来华留学",
      pathStudyTitle: "奖学金与升学路径",
      pathStudyBody: "CSC/校奖、学习计划、成绩单与微信联系方式——提交至奖学金后台。",
      pathStudyCta: "打开奖学金表单 →",
      pathCompanyEyebrow: "在华经商",
      pathCompanyTitle: "注册公司",
      pathCompanyBody: "外商独资、贸易与本地结构——护照、证件照、学历与无犯罪证明（与 App 清单一致）。",
      pathCompanyCta: "打开公司表单 →",
      quotesEyebrow: "客户",
      quotesTitle: "人们如何使用 OBIC",
      quote1: "签证和酒店一起办妥，我到义乌时有计划，而不是一堆问题。",
      quote1By: "旅客 · 义乌",
      quote2: "一个窗口处理银行、工厂会面，以及会说阿拉伯语的顾问。",
      quote2By: "贸易公司",
      quote3: "我们用阿拉伯语询问，当天就知道下一步：接机、材料和要见的人。",
      quote3By: "商务访客",
      storeApple: "App Store",
      storeGoogle: "Google Play",
      storeSoon: "即将上线",
      finalTitle: "从一次对话开始",
      finalBody: "在网站注册，或通过 WhatsApp 联系团队。应用即将上架 App Store 和 Google Play。",
      footerServices: "服务",
      footerApp: "应用",
      stepsEyebrow: "办理流程",
      stepsTitle: "从一条消息到办完",
      step1Title: "告诉我们",
      step1Body: "WhatsApp 或表单。签证、酒店、机票、银行或 VIP。",
      step2Title: "你的分支",
      step2Body: "本地顾问用阿拉伯语、英语或中文回复。",
      step3Title: "跟进",
      step3Body: "应用里的订单和聊天，与本网站同一账户。",
      branchesEyebrow: "分支机构",
      branchesTitle: "OBIC 七家分支",
      branchesSub: "义乌为总部。中国与也门本地团队 — 申请服务时可选择最近的分支。",
      brYiwu: "义乌",
      brYiwuRole: "总部 · 亚西尔先生",
      brGuangzhou: "广州",
      brGuangzhouRole: "阿明先生",
      brFoshan: "佛山",
      brFoshanRole: "瓦吉赫先生",
      brHangzhou: "杭州",
      brHangzhouRole: "穆罕默德先生",
      brHainan: "海南",
      brHainanRole: "艾哈迈德先生",
      brYemen: "也门",
      brYemenRole: "巴希",
      brShanghai: "上海",
      brShanghaiRole: "哈立德先生",
      footerAbout: "为在华出行与经营的国际客户提供专业服务。",
      footerLinks: "链接",
      footerContact: "联系",
      contactLead: "告诉我们您在中国的需求。我们的团队会跟进明确的下一步。",
      send: "发送消息",
      open: "打开",
      legalTerms: "条款",
      legalPrivacy: "隐私",
      legalAgree: "创建账户即表示您同意",
      legalAnd: "与",
      copy: "© 2026 OBIC. 保留所有权利。",
      comingListings: "申请此服务 — 我们的团队将全程指导。",
      catSearch: "搜索",
      catSearchPh: "搜索服务",
      catSearchBtn: "搜索",
      catMin: "最低价",
      catMax: "最高价",
      catAll: "全部分类",
      catView: "查看详情",
      catUntitled: "服务",
      catLoading: "正在加载服务…",
      catCount: "{n} 个项目",
      catEmptyCount: "暂无项目",
      catEmptyTitle: "此分类暂无内容",
      catEmptyBody: "联系我们的团队，我们将为您安排此项服务。",
      catErrorTitle: "无法加载列表",
      catErrorBody: "请重试，或联系我们获取帮助。",
      phone: "15257977914",
      email: "obicproject117@gmail.com",
      address: "Road of Safety",
    },
  };

  let lang = localStorage.getItem("obic_lang") || "en";
  const langListeners = [];

  function t(key) {
    return (COPY[lang] && COPY[lang][key]) || COPY.en[key] || key;
  }

  function applyCopy() {
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (key) el.textContent = t(key);
    });
    document.querySelectorAll("[data-i18n-placeholder]").forEach((el) => {
      const key = el.getAttribute("data-i18n-placeholder");
      if (key) el.setAttribute("placeholder", t(key));
    });
    document.documentElement.lang = lang === "zh" ? "zh-CN" : lang;
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
    document.querySelectorAll(".lang button").forEach((btn) => {
      btn.classList.toggle("is-on", btn.dataset.lang === lang);
    });
    document.querySelectorAll("[data-lang-block]").forEach((el) => {
      el.hidden = el.getAttribute("data-lang-block") !== lang;
    });
  }

  function setLang(next, opts) {
    const silent = !!(opts && opts.silent);
    if (!COPY[next]) next = "en";
    if (lang === next && !silent) {
      applyCopy();
      return lang;
    }
    lang = next;
    try {
      localStorage.setItem("obic_lang", lang);
    } catch (_) {}
    applyCopy();
    const aiFab = document.querySelector(".obic-ai-fab");
    if (aiFab) aiFab.setAttribute("aria-label", t("navAi"));
    if (window.__obicAiDockRefresh) window.__obicAiDockRefresh();
    if (!silent) {
      langListeners.forEach((fn) => {
        try {
          fn(lang);
        } catch (_) {}
      });
    }
    return lang;
  }

  function iconSvg(name) {
    return ICONS[name] || ICONS.business;
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function renderHubs(result) {
    const grid = document.getElementById("service-grid");
    if (!grid) return;

    const items = result.items || [];
    grid.innerHTML = items
      .map((item) => {
        const title = window.ObicApi.hubLabel(item, lang);
        const desc = window.ObicApi.hubDesc(item, lang);
        const href = window.ObicApi.hubHref(item);
        const icon = item.icon || "business";
        const src = window.ObicPhotos
          ? window.ObicPhotos.photo(item.slug, icon)
          : "";
        return `<a class="service-card reveal" href="${escapeHtml(href)}">
          <span class="service-icon" aria-hidden="true">${iconSvg(icon)}</span>
          <img src="${escapeHtml(src)}" alt="" />
          <h3>${escapeHtml(title)}</h3>
          <p>${escapeHtml(desc)}</p>
          <span class="go">${escapeHtml(t("open"))}</span>
        </a>`;
      })
      .join("");

    observeReveals();
  }

  function observeReveals() {
    const nodes = document.querySelectorAll(".reveal:not(.is-in)");
    if (!nodes.length) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce || !("IntersectionObserver" in window)) {
      nodes.forEach((el) => el.classList.add("is-in"));
      return;
    }
    const watch = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("is-in");
          watch.unobserve(entry.target);
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -6% 0px" },
    );
    nodes.forEach((el) => watch.observe(el));
  }

  async function loadHubs() {
    const result = await window.ObicApi.listServices();
    renderHubs(result);
  }

  function mountAiDock() {
    const API = "https://api.obicgp.com";
    const STORE = "obicAiLocalThreads";
    let threads = [];
    let threadId = null;
    let turns = [];
    let sending = false;
    let showChats = false;
    let pending = null;
    const MAX_BYTES = 4 * 1024 * 1024;

    function loadStore() {
      try {
        const raw = JSON.parse(localStorage.getItem(STORE) || "[]");
        return Array.isArray(raw) ? raw : [];
      } catch (_) {
        return [];
      }
    }

    function saveStore() {
      const slim = threads.slice(0, 30).map((thread) => ({
        id: thread.id,
        title: thread.title || "",
        updatedAt: thread.updatedAt || null,
        turns: (thread.turns || []).map((turn) => ({
          role: turn.role === "assistant" ? "assistant" : "user",
          text: turn.text || "",
          createdAt: turn.createdAt || null,
          attachmentKind: turn.attachmentKind || null,
          attachmentName: turn.attachmentName || null,
        })),
      }));
      try {
        localStorage.setItem(STORE, JSON.stringify(slim));
      } catch (_) {}
    }

    function remember() {
      if (!turns.length) return;
      if (!threadId) threadId = "local-" + Date.now();
      let title = t("navAi");
      for (const turn of turns) {
        if (turn.role === "user" && (turn.text || "").trim()) {
          title = turn.text.trim().slice(0, 80);
          break;
        }
      }
      const record = {
        id: threadId,
        title,
        updatedAt: new Date().toISOString(),
        turns: turns.map((turn) => ({
          role: turn.role,
          text: turn.text || "",
          createdAt: turn.createdAt || null,
          attachmentKind: turn.attachmentKind || null,
          attachmentName: turn.attachmentName || null,
        })),
      };
      threads = [record, ...threads.filter((thread) => thread.id !== threadId)];
      saveStore();
    }

    const dock = document.createElement("div");
    dock.className = "obic-ai-dock";
    const panel = document.createElement("section");
    panel.className = "obic-ai-panel";
    panel.hidden = true;
    panel.setAttribute("aria-label", t("navAi"));
    panel.innerHTML =
      '<header>' +
      '<button type="button" class="obic-ai-close" data-bot="close" aria-label="Close">×</button>' +
      '<img src="/ai-mark.svg" alt="" width="36" height="36" />' +
      '<strong data-bot="title"></strong>' +
      '<div class="obic-ai-actions">' +
      '<button type="button" data-bot="chats"></button>' +
      '<button type="button" data-bot="new"></button>' +
      '<a href="/ai.html" data-bot="open"></a>' +
      "</div></header>" +
      '<div class="obic-ai-log" data-bot="log"></div>' +
      '<div class="obic-ai-pending" data-bot="pending" hidden></div>' +
      '<form class="obic-ai-form">' +
      '<button type="button" data-bot="attach"></button>' +
      '<div class="obic-ai-attach" data-bot="menu" hidden>' +
      '<button type="button" data-kind="photo"></button>' +
      '<button type="button" data-kind="pdf"></button>' +
      '<button type="button" data-kind="sheet"></button>' +
      "</div>" +
      '<input type="text" maxlength="4000" autocomplete="off" data-bot="input" />' +
      '<button type="submit" data-bot="send"></button>' +
      "</form>" +
      '<input data-bot="file-photo" type="file" accept="image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp" hidden />' +
      '<input data-bot="file-pdf" type="file" accept="application/pdf,.pdf" hidden />' +
      '<input data-bot="file-sheet" type="file" accept=".csv,.xls,.xlsx,text/csv,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" hidden />';
    const fab = document.createElement("button");
    fab.type = "button";
    fab.className = "obic-ai-fab";
    const mark = document.createElement("img");
    mark.src = "/ai-mark.svg";
    mark.alt = "";
    fab.appendChild(mark);
    dock.appendChild(panel);
    dock.appendChild(fab);
    document.body.appendChild(dock);

    const log = panel.querySelector("[data-bot=log]");
    const input = panel.querySelector("[data-bot=input]");

    function paintCopy() {
      panel.querySelector("[data-bot=title]").textContent = t("navAi");
      panel.querySelector("[data-bot=chats]").textContent = t("botChats");
      panel.querySelector("[data-bot=new]").textContent = t("botNew");
      panel.querySelector("[data-bot=open]").textContent = t("botOpen");
      var closeBtn = panel.querySelector("[data-bot=close]");
      closeBtn.textContent = "×";
      closeBtn.setAttribute("aria-label", t("botClose"));
      closeBtn.setAttribute("title", t("botClose"));
      panel.querySelector("[data-bot=send]").textContent = t("botSend");
      panel.querySelector("[data-bot=attach]").textContent = t("botAttach");
      panel.querySelector('[data-kind="photo"]').textContent = t("botPhoto");
      panel.querySelector('[data-kind="pdf"]').textContent = t("botPdf");
      panel.querySelector('[data-kind="sheet"]').textContent = t("botSheet");
      input.placeholder = t("botHint");
      fab.setAttribute("aria-label", t("navAi"));
      render();
    }

    function render() {
      log.replaceChildren();
      if (showChats) {
        const list = document.createElement("div");
        list.className = "obic-ai-chats";
        if (!threads.length) {
          const empty = document.createElement("p");
          empty.className = "obic-ai-note";
          empty.textContent = t("botSaved");
          list.appendChild(empty);
        }
        threads.forEach((thread) => {
          const btn = document.createElement("button");
          btn.type = "button";
          btn.textContent = thread.title || t("navAi");
          btn.addEventListener("click", () => openThread(thread.id));
          list.appendChild(btn);
        });
        log.appendChild(list);
        return;
      }
      const note = document.createElement("p");
      note.className = "obic-ai-note";
      note.textContent = t("botSaved");
      log.appendChild(note);
      if (!turns.length) {
        const hello = document.createElement("div");
        hello.className = "obic-ai-bubble is-ai";
        hello.textContent = t("botHello");
        hello.dir = "auto";
        log.appendChild(hello);
      }
      turns.forEach((turn) => {
        const bubble = document.createElement("div");
        bubble.className = "obic-ai-bubble " + (turn.role === "user" ? "is-me" : "is-ai");
        bubble.dir = "auto";
        if (turn.preview) {
          const shot = document.createElement("img");
          shot.alt = "";
          shot.src = turn.preview;
          shot.style.cssText = "width:120px;height:90px;object-fit:cover;border-radius:8px;display:block;margin-bottom:0.35rem";
          bubble.appendChild(shot);
        }
        if (turn.attachmentName && !turn.preview) {
          const name = document.createElement("div");
          name.textContent = turn.attachmentName;
          bubble.appendChild(name);
        }
        if ((turn.text || "").trim()) {
          const text = document.createElement("div");
          text.textContent = turn.text;
          bubble.appendChild(text);
        }
        log.appendChild(bubble);
      });
      if (sending) {
        const wait = document.createElement("div");
        wait.className = "obic-ai-bubble is-ai";
        wait.textContent = "…";
        log.appendChild(wait);
      }
      log.scrollTop = log.scrollHeight;
    }

    function openThread(id) {
      const thread = threads.find((item) => item.id === id);
      if (!thread) return;
      threadId = thread.id;
      turns = (thread.turns || []).map((turn) => ({
        role: turn.role === "assistant" ? "assistant" : "user",
        text: turn.text || "",
        createdAt: turn.createdAt || null,
        attachmentKind: turn.attachmentKind || null,
        attachmentName: turn.attachmentName || null,
      }));
      showChats = false;
      render();
    }

    function historyLine(turn) {
      const text = (turn.text || "").trim();
      const name = (turn.attachmentName || "").trim();
      if (turn.attachmentKind === "image") {
        if (!text) return name ? "User sent a photo (" + name + ")." : "User sent a photo.";
        return name ? "User sent a photo (" + name + ") and wrote: " + text : "User sent a photo and wrote: " + text;
      }
      if (turn.attachmentKind === "file") {
        if (!text) return name ? "User sent a file (" + name + ")." : "User sent a file.";
        return name ? "User sent a file (" + name + ") and wrote: " + text : "User sent a file and wrote: " + text;
      }
      return text;
    }

    function mimeForName(name) {
      const lower = String(name || "").toLowerCase();
      if (lower.endsWith(".png")) return "image/png";
      if (lower.endsWith(".webp")) return "image/webp";
      if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
      if (lower.endsWith(".pdf")) return "application/pdf";
      if (lower.endsWith(".csv")) return "text/csv";
      if (lower.endsWith(".xlsx")) return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      if (lower.endsWith(".xls")) return "application/vnd.ms-excel";
      return "";
    }

    function bytesToBase64(bytes) {
      let binary = "";
      const chunk = 0x8000;
      for (let i = 0; i < bytes.length; i += chunk) {
        binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
      }
      return btoa(binary);
    }

    function compressPhoto(file) {
      return new Promise((resolve, reject) => {
        const url = URL.createObjectURL(file);
        const img = new Image();
        img.onload = () => {
          const maxW = 1280;
          const scale = img.width > maxW ? maxW / img.width : 1;
          const canvas = document.createElement("canvas");
          canvas.width = Math.max(1, Math.round(img.width * scale));
          canvas.height = Math.max(1, Math.round(img.height * scale));
          canvas.getContext("2d").drawImage(img, 0, 0, canvas.width, canvas.height);
          canvas.toBlob((blob) => {
            URL.revokeObjectURL(url);
            if (!blob) reject(new Error("read"));
            else resolve(blob);
          }, "image/jpeg", 0.7);
        };
        img.onerror = () => {
          URL.revokeObjectURL(url);
          reject(new Error("read"));
        };
        img.src = url;
      });
    }

    function renderPending() {
      const box = panel.querySelector("[data-bot=pending]");
      box.replaceChildren();
      if (!pending) {
        box.hidden = true;
        return;
      }
      box.hidden = false;
      if (pending.preview) {
        const img = document.createElement("img");
        img.alt = "";
        img.src = pending.preview;
        box.appendChild(img);
      }
      const name = document.createElement("span");
      name.textContent = pending.filename;
      box.appendChild(name);
      const remove = document.createElement("button");
      remove.type = "button";
      remove.textContent = t("botRemove");
      remove.addEventListener("click", () => {
        if (pending && pending.preview) URL.revokeObjectURL(pending.preview);
        pending = null;
        renderPending();
      });
      box.appendChild(remove);
    }

    async function stageFile(file, expected) {
      if (!file) return;
      const mime = mimeForName(file.name);
      if (expected === "photo") {
        if (!mime || mime.indexOf("image/") !== 0) {
          window.alert(t("botUnsupported"));
          return;
        }
        let blob;
        try {
          blob = await compressPhoto(file);
        } catch (_) {
          window.alert(t("botUnreadable"));
          return;
        }
        if (blob.size > MAX_BYTES) {
          window.alert(t("botTooBig"));
          return;
        }
        const photoBytes = new Uint8Array(await blob.arrayBuffer());
        let name = file.name && /\.(jpe?g|png|webp)$/i.test(file.name) ? file.name : "photo.jpg";
        if (!/\.jpe?g$/i.test(name)) name = name.replace(/\.[^.]+$/, "") + ".jpg";
        if (pending && pending.preview) URL.revokeObjectURL(pending.preview);
        pending = {
          kind: "image",
          filename: name,
          mime: "image/jpeg",
          dataBase64: bytesToBase64(photoBytes),
          preview: URL.createObjectURL(blob),
        };
        renderPending();
        return;
      }
      if (!mime || mime.indexOf("image/") === 0) {
        window.alert(t("botUnsupported"));
        return;
      }
      if (expected === "pdf" && mime !== "application/pdf") {
        window.alert(t("botUnsupported"));
        return;
      }
      if (expected === "sheet" && mime !== "text/csv" && mime.indexOf("spreadsheet") === -1 && mime !== "application/vnd.ms-excel") {
        window.alert(t("botUnsupported"));
        return;
      }
      if (file.size > MAX_BYTES) {
        window.alert(t("botTooBig"));
        return;
      }
      const bytes = new Uint8Array(await file.arrayBuffer());
      if (!bytes.length) {
        window.alert(t("botUnreadable"));
        return;
      }
      if (pending && pending.preview) URL.revokeObjectURL(pending.preview);
      pending = {
        kind: "file",
        filename: file.name,
        mime,
        dataBase64: bytesToBase64(bytes),
        preview: "",
      };
      renderPending();
    }

    function recentImage() {
      const start = turns.length > 6 ? turns.length - 6 : 0;
      for (let i = turns.length - 1; i >= start; i -= 1) {
        const turn = turns[i];
        if (turn.role !== "user" || turn.attachmentKind !== "image") continue;
        if (!turn.dataBase64 || !turn.attachmentName || !turn.attachmentMime) continue;
        return {
          kind: "image",
          filename: turn.attachmentName,
          mime: turn.attachmentMime,
          dataBase64: turn.dataBase64,
        };
      }
      return null;
    }

    async function send(event) {
      event.preventDefault();
      const text = input.value.trim();
      const held = pending;
      if ((!text && !held) || sending) return;
      input.value = "";
      const attachment = held
        ? { kind: held.kind, filename: held.filename, mime: held.mime, dataBase64: held.dataBase64 }
        : recentImage();
      turns.push({
        role: "user",
        text,
        createdAt: new Date().toISOString(),
        attachmentKind: held ? held.kind : null,
        attachmentName: held ? held.filename : null,
        attachmentMime: held ? held.mime : null,
        dataBase64: held ? held.dataBase64 : null,
        preview: held ? held.preview : "",
      });
      pending = null;
      renderPending();
      sending = true;
      showChats = false;
      render();
      const history = turns
        .slice(0, -1)
        .slice(-6)
        .map((turn) => ({ role: turn.role, content: historyLine(turn) }))
        .filter((turn) => turn.content);
      const locale = lang === "ar" || lang === "zh" ? lang : "en";
      const body = { message: text, locale, history };
      if (attachment) body.attachment = attachment;
      try {
        const res = await fetch(API + "/v1/ai/public/assistant", {
          method: "POST",
          headers: { Accept: "application/json", "Content-Type": "application/json" },
          body: JSON.stringify(body),
          signal: AbortSignal.timeout(20000),
        });
        const json = await res.json().catch(() => ({}));
        const reply = res.ok && (json.reply || "").trim() ? json.reply.trim() : t("botBusy");
        turns.push({ role: "assistant", text: reply, createdAt: new Date().toISOString() });
      } catch (_) {
        turns.push({ role: "assistant", text: t("botBusy"), createdAt: new Date().toISOString() });
      }
      sending = false;
      remember();
      render();
    }

    fab.addEventListener("click", () => {
      panel.hidden = !panel.hidden;
      if (!panel.hidden) {
        threads = loadStore();
        if (!turns.length && threads[0]) openThread(threads[0].id);
        else render();
        input.focus();
      }
    });
    panel.querySelector("[data-bot=close]").addEventListener("click", () => {
      panel.hidden = true;
    });
    panel.querySelector("[data-bot=new]").addEventListener("click", () => {
      threadId = null;
      turns = [];
      showChats = false;
      render();
    });
    panel.querySelector("[data-bot=chats]").addEventListener("click", () => {
      threads = loadStore();
      showChats = !showChats;
      render();
    });
    panel.querySelector("form").addEventListener("submit", send);
    const menu = panel.querySelector("[data-bot=menu]");
    panel.querySelector("[data-bot=attach]").addEventListener("click", () => {
      menu.hidden = !menu.hidden;
    });
    menu.addEventListener("click", (event) => {
      const kind = event.target.getAttribute("data-kind");
      if (!kind) return;
      menu.hidden = true;
      panel.querySelector("[data-bot=file-" + kind + "]").click();
    });
    ["photo", "pdf", "sheet"].forEach((kind) => {
      panel.querySelector("[data-bot=file-" + kind + "]").addEventListener("change", async (event) => {
        const file = event.target.files && event.target.files[0];
        event.target.value = "";
        await stageFile(file, kind);
      });
    });
    threads = loadStore();
    paintCopy();
    window.__obicAiDockRefresh = paintCopy;
  }

  function bindNav() {
    const nav = document.querySelector(".nav");
    const toggle = document.querySelector(".menu-toggle");
    if (toggle && nav) {
      toggle.addEventListener("click", () => {
        const open = nav.classList.toggle("is-open");
        toggle.setAttribute("aria-expanded", open ? "true" : "false");
      });
      nav.querySelectorAll("a").forEach((link) => {
        link.addEventListener("click", () => {
          nav.classList.remove("is-open");
          toggle.setAttribute("aria-expanded", "false");
        });
      });
    }
    document.querySelectorAll(".nav-links").forEach((list) => {
      if (list.querySelector('a[href="/ai.html"]')) return;
      const li = document.createElement("li");
      const link = document.createElement("a");
      link.href = "/ai.html";
      link.setAttribute("data-i18n", "navAi");
      link.textContent = t("navAi");
      if (location.pathname.endsWith("/ai.html")) link.classList.add("is-active");
      li.appendChild(link);
      list.appendChild(li);
    });
    if (!location.pathname.endsWith("/ai.html") && !document.querySelector(".obic-ai-dock")) {
      try {
        mountAiDock();
      } catch (_) {}
    }
    if (nav) {
      const onScroll = () => nav.classList.toggle("is-scrolled", window.scrollY > 8);
      onScroll();
      window.addEventListener("scroll", onScroll, { passive: true });
    }
    document.documentElement.dataset.navBound = "1";
    document.documentElement.dataset.navBound = "1";
    document.querySelectorAll(".lang button").forEach((btn) => {
      btn.addEventListener("click", () => {
        setLang(btn.dataset.lang);
        loadHubs();
      });
    });
  }

  window.ObicI18n = {
    t,
    getLang: () => lang,
    setLang,
    applyCopy,
    iconSvg,
    observeReveals,
    onLangChange(fn) {
      if (typeof fn === "function") langListeners.push(fn);
    },
  };

  function bindShowcase() {
    const root = document.querySelector(".showcase");
    const viewport = document.querySelector(".showcase-viewport");
    const track = document.getElementById("showcase-track");
    const dotsWrap = document.getElementById("showcase-dots");
    if (!root || !viewport || !track || !dotsWrap) return;

    const real = Array.from(track.children);
    const count = real.length;
    if (!count) return;
    const clone = real[0].cloneNode(true);
    clone.setAttribute("aria-hidden", "true");
    clone.tabIndex = -1;
    track.appendChild(clone);

    const dots = real.map((_, idx) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "showcase-dot";
      button.addEventListener("click", () => go(idx, true));
      dotsWrap.appendChild(button);
      return button;
    });

    let index = 0;
    let step = 0;
    let timer = 0;
    let startX = 0;
    let moved = false;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const prev = root.querySelector(".showcase-prev");
    const next = root.querySelector(".showcase-next");

    function measure() {
      const slide = track.children[0];
      const styles = getComputedStyle(track);
      const gap = parseFloat(styles.columnGap || styles.gap) || 16;
      step = slide.getBoundingClientRect().width + gap;
    }

    function labelDots() {
      dots.forEach((button, idx) => {
        const name = real[idx].querySelector("strong");
        button.setAttribute("aria-label", name ? name.textContent.trim() : String(idx + 1));
      });
    }

    function paint(animate) {
      const sign = document.documentElement.dir === "rtl" ? 1 : -1;
      track.style.transition = animate && !reduce ? "" : "none";
      track.style.transform = "translate3d(" + sign * index * step + "px,0,0)";
      const active = index % count;
      dots.forEach((button, idx) => {
        const on = idx === active;
        button.classList.toggle("is-on", on);
        if (on) button.setAttribute("aria-current", "true");
        else button.removeAttribute("aria-current");
      });
      real.forEach((slide, idx) => {
        const on = idx === active;
        slide.classList.toggle("is-on", on);
        slide.setAttribute("aria-hidden", on ? "false" : "true");
      });
    }

    function go(nextIndex, fromUser) {
      if (nextIndex > count) nextIndex = 1;
      if (nextIndex < 0) nextIndex = count - 1;
      index = nextIndex;
      paint(true);
      if (fromUser) restart();
    }

    function restart() {
      window.clearInterval(timer);
      timer = 0;
      if (reduce || document.hidden || root.classList.contains("is-paused")) return;
      timer = window.setInterval(() => go(index + 1, false), 4200);
    }

    track.addEventListener("transitionend", (event) => {
      if (event.target !== track || event.propertyName !== "transform") return;
      if (index !== count) return;
      index = 0;
      paint(false);
    });

    if (prev) prev.addEventListener("click", () => go(index <= 0 || index === count ? count - 1 : index - 1, true));
    if (next) next.addEventListener("click", () => go(index >= count ? 1 : index + 1, true));

    viewport.addEventListener("pointerdown", (event) => {
      if (event.button && event.button !== 0) return;
      startX = event.clientX;
      moved = false;
    });
    viewport.addEventListener("pointermove", (event) => {
      if (!startX) return;
      if (Math.abs(event.clientX - startX) > 12) moved = true;
    });
    viewport.addEventListener("pointerup", (event) => {
      const dx = event.clientX - startX;
      startX = 0;
      if (Math.abs(dx) < 48) return;
      go(dx < 0 ? index + 1 : index - 1, true);
    });
    viewport.addEventListener("pointercancel", () => {
      startX = 0;
    });
    viewport.addEventListener(
      "click",
      (event) => {
        if (!moved) return;
        event.preventDefault();
        event.stopPropagation();
        moved = false;
      },
      true
    );

    function pause(on) {
      root.classList.toggle("is-paused", on);
      if (on) {
        window.clearInterval(timer);
        timer = 0;
        return;
      }
      restart();
    }
    viewport.addEventListener("mouseenter", () => pause(true));
    viewport.addEventListener("mouseleave", () => pause(false));
    viewport.addEventListener("focusin", () => pause(true));
    viewport.addEventListener("focusout", (event) => {
      if (viewport.contains(event.relatedTarget)) return;
      pause(false);
    });
    document.addEventListener("visibilitychange", () => {
      if (document.hidden) {
        window.clearInterval(timer);
        timer = 0;
        return;
      }
      restart();
    });
    window.addEventListener("resize", () => {
      measure();
      paint(false);
    });
    if (window.ResizeObserver) {
      const watcher = new ResizeObserver(() => {
        measure();
        paint(false);
      });
      watcher.observe(viewport);
    }
    window.ObicI18n.onLangChange(() => {
      labelDots();
      measure();
      paint(false);
    });

    labelDots();
    measure();
    paint(false);
    restart();
  }

  function bindAppStage() {
    const orbit = document.getElementById("phone-orbit");
    const front = document.getElementById("phone-front");
    const live = document.getElementById("phone-live");
    if (!orbit || !front || !live) return;

    const tabs = document.querySelectorAll(".app-screen-tabs button");
    const show = (name) => {
      const panel = live.querySelector(`[data-ui="${name}"]`);
      if (!panel) return;
      live.querySelectorAll("[data-ui]").forEach((el) => {
        el.classList.toggle("is-show", el.getAttribute("data-ui") === name);
      });
      tabs.forEach((btn) => {
        btn.classList.toggle("is-on", btn.getAttribute("data-screen") === name);
      });
    };

    tabs.forEach((btn) => {
      btn.addEventListener("click", () => show(btn.getAttribute("data-screen")));
    });

    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) return;

    let ticking = false;
    orbit.addEventListener(
      "pointermove",
      (event) => {
        if (ticking) return;
        ticking = true;
        requestAnimationFrame(() => {
          const box = orbit.getBoundingClientRect();
          const x = (event.clientX - box.left) / box.width - 0.5;
          const y = (event.clientY - box.top) / box.height - 0.5;
          front.style.transform =
            "translateY(" + (-8 + y * -10) + "px) rotateY(" + x * 18 + "deg) rotateX(" + y * -10 + "deg)";
          ticking = false;
        });
      },
      { passive: true }
    );
    orbit.addEventListener("pointerleave", () => {
      front.style.transform = "";
    });
  }

  function bindCounts() {
    const nodes = document.querySelectorAll("[data-count]");
    if (!nodes.length) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          const el = entry.target;
          const target = Number(el.getAttribute("data-count")) || 0;
          io.unobserve(el);
          if (reduce) {
            el.textContent = String(target);
            return;
          }
          const start = performance.now();
          const tick = (now) => {
            const p = Math.min(1, (now - start) / 900);
            el.textContent = String(Math.round(target * (1 - Math.pow(1 - p, 3))));
            if (p < 1) requestAnimationFrame(tick);
          };
          requestAnimationFrame(tick);
        });
      },
      { threshold: 0.4 }
    );
    nodes.forEach((node) => io.observe(node));
  }

  function ensureSiteFooter() {
    if (document.body && document.body.dataset.obicNoFooter === "1") return;
    const existing = document.querySelector("footer.footer");
    if (existing && existing.querySelector(".footer-grid")) return;
    if (existing) existing.remove();

    const footer = document.createElement("footer");
    footer.className = "footer";
    footer.innerHTML =
      '<div class="wrap footer-grid">' +
      "<div>" +
      '<a class="brand" href="/"><img src="/logo.png" alt="" width="36" height="36" /> OBIC</a>' +
      '<p data-i18n="footerAbout">Professional services for international clients operating and traveling in China.</p>' +
      "</div>" +
      "<div>" +
      '<h4 data-i18n="footerLinks">Links</h4>' +
      "<p>" +
      '<a href="/" data-i18n="navHome">Home</a><br />' +
      '<a href="/study-china.html" data-i18n="pathStudyTitle">Scholarships &amp; university pathways</a><br />' +
      '<a href="/open-company.html" data-i18n="pathCompanyTitle">Open a company</a><br />' +
      '<a href="/about.html" data-i18n="navAbout">About</a><br />' +
      '<a href="/contact.html" data-i18n="navContact">Contact</a><br />' +
      '<a href="/mini-apps.html">Mini apps</a><br />' +
      '<a href="/login" data-i18n="navLogin">Login</a><br />' +
      '<a href="/terms" data-i18n="legalTerms">Terms</a><br />' +
      '<a href="/privacy" data-i18n="legalPrivacy">Privacy</a>' +
      "</p>" +
      "</div>" +
      "<div>" +
      '<h4 data-i18n="footerContact">Contact</h4>' +
      "<p>" +
      '<a href="https://wa.me/8615257977914" target="_blank" rel="noopener noreferrer" data-i18n="ctaWhatsApp">WhatsApp</a><br />' +
      '<span dir="ltr" data-i18n="phone">15257977914</span><br />' +
      '<span dir="ltr" data-i18n="email">obicproject117@gmail.com</span><br />' +
      '<span data-i18n="address">Road of Safety</span>' +
      "</p>" +
      "</div>" +
      "</div>" +
      '<div class="wrap footer-bottom">' +
      '<span data-i18n="copy">© 2026 OBIC. All rights reserved.</span>' +
      "</div>";

    const scripts = document.body.querySelectorAll("script");
    const firstScript = scripts.length ? scripts[0] : null;
    if (firstScript) document.body.insertBefore(footer, firstScript);
    else document.body.appendChild(footer);
  }

  document.addEventListener("DOMContentLoaded", () => {
    ensureSiteFooter();
    applyCopy();
    bindNav();
    bindShowcase();
    bindAppStage();
    observeReveals();
    bindCounts();
    if (document.getElementById("service-grid")) loadHubs();
  });
})();
