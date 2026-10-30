// Made by Dr Ali
// Rich Arabic mock data for Internal Ops prototype (no API).

abstract final class OpsMock {
  static const banner =
      'نموذج تجريبي للعرض — الواجهة فقط · الخادم والربط لاحقاً · تصميم وتطوير: د. علي';

  static const Map<String, dynamic> dashboard = {
    'customersToday': 12,
    'inquiries': 28,
    'openOrders': 41,
    'closedOrders': 19,
    'deals': 7,
    'salesTotal': '¥ 186,400',
    'revenue': '¥ 142,200',
    'expenses': '¥ 38,750',
    'profit': '¥ 103,450',
    'lateOrders': 4,
    'lateTasks': 6,
    'topService': 'ترخيص الأعمال · ييوو',
    'topMarket': 'السعودية / الخليج',
  };

  static const List<Map<String, String>> sources = [
    {'name': 'واتساب', 'count': '34'},
    {'name': 'WeChat', 'count': '22'},
    {'name': 'التطبيق', 'count': '18'},
    {'name': 'الموقع', 'count': '11'},
    {'name': 'Instagram', 'count': '9'},
    {'name': 'TikTok', 'count': '5'},
  ];

  static const List<Map<String, dynamic>> customers = [
    {
      'id': 'CRM-10021',
      'name': 'أحمد الغامدي',
      'phone': '+966501234567',
      'email': 'ahmed.g@example.com',
      'country': 'السعودية',
      'city': 'الرياض',
      'source': 'واتساب',
      'owner': 'مدير التسويق — ييوو',
      'status': 'عميل فعلي',
      'lastContact': 'اليوم 10:20 · مدير التسويق',
      'notes': 'مهتم بترخيص أعمال + شحن عينات.',
      'orders': ['REQ-8841', 'REQ-8790'],
      'files': ['جواز.pdf', 'سجل تجاري.pdf'],
    },
    {
      'id': 'CRM-10018',
      'name': 'سارة الحربي',
      'phone': '+966559876543',
      'email': 'sara.h@example.com',
      'country': 'السعودية',
      'city': 'جدة',
      'source': 'Instagram',
      'owner': 'مسوّق — قوانغتشو',
      'status': 'قيد المتابعة',
      'lastContact': 'أمس · مسوّق قوانغتشو',
      'notes': 'طلب عرض سعر فنادق لمعرض كانتون.',
      'orders': ['REQ-8822'],
      'files': ['بطاقة هوية.pdf'],
    },
    {
      'id': 'CRM-10012',
      'name': 'شركة نوركو للتجارة',
      'phone': '+967770112233',
      'email': 'ops@norko.example',
      'country': 'اليمن',
      'city': 'صنعاء',
      'source': 'WeChat',
      'owner': 'مدير الفرع — ييوو',
      'status': 'جديد',
      'lastContact': 'اليوم 08:05 · إدخال البيانات',
      'notes': 'استفسار مصانع أثاث + شحن حاوية.',
      'orders': ['REQ-8855'],
      'files': [],
    },
    {
      'id': 'CRM-10005',
      'name': 'خالد العتيبي',
      'phone': '+966531112222',
      'email': 'khaled@example.com',
      'country': 'السعودية',
      'city': 'الدمام',
      'source': 'التطبيق',
      'owner': 'خدمة العملاء — HQ',
      'status': 'غير مهتم',
      'lastContact': 'قبل 5 أيام · خدمة العملاء',
      'notes': 'أُغلق مؤقتاً — طلب إعادة تواصل بعد رمضان.',
      'orders': [],
      'files': [],
    },
  ];

  static const List<Map<String, dynamic>> inquiries = [
    {
      'ref': 'REQ-8855',
      'customer': 'شركة نوركو للتجارة',
      'what': 'مصانع أثاث + حاوية 40 قدم',
      'when': 'اليوم 08:01',
      'owner': 'مدير الفرع — ييوو',
      'stage': 'جمع المتطلبات',
      'next': 'إرسال قائمة مصانع مقترحة',
      'replied': true,
      'followUp': true,
      'open': true,
    },
    {
      'ref': 'REQ-8841',
      'customer': 'أحمد الغامدي',
      'what': 'ترخيص أعمال — ييوو',
      'when': 'أمس 16:40',
      'owner': 'مدير التسويق — ييوو',
      'stage': 'إدخال المستندات',
      'next': 'مراجعة جواز + سجل تجاري',
      'replied': true,
      'followUp': true,
      'open': true,
    },
    {
      'ref': 'REQ-8822',
      'customer': 'سارة الحربي',
      'what': 'حجز فنادق — معرض كانتون',
      'when': 'قبل يومين',
      'owner': 'مسوّق — قوانغتشو',
      'stage': 'عرض سعر',
      'next': 'انتظار موافقة العميل',
      'replied': true,
      'followUp': false,
      'open': true,
    },
    {
      'ref': 'REQ-8701',
      'customer': 'عميل سابق',
      'what': 'شحن عينات ملابس',
      'when': 'الأسبوع الماضي',
      'owner': 'اللوجستيات',
      'stage': 'مغلق',
      'next': '—',
      'replied': true,
      'followUp': false,
      'open': false,
    },
  ];

  static const List<Map<String, String>> salesPipeline = [
    {'stage': 'عملاء محتملون', 'count': '46', 'value': '¥ 520k'},
    {'stage': 'عروض أسعار', 'count': '18', 'value': '¥ 310k'},
    {'stage': 'مفاوضات', 'count': '9', 'value': '¥ 188k'},
    {'stage': 'عقود', 'count': '5', 'value': '¥ 142k'},
    {'stage': 'مكتمل', 'count': '7', 'value': '¥ 186k'},
    {'stage': 'ملغى', 'count': '3', 'value': '¥ 41k'},
  ];

  static const List<Map<String, String>> salesByStaff = [
    {'name': 'مدير التسويق — ييوو', 'value': '¥ 62,400', 'deals': '3'},
    {'name': 'مسوّق — قوانغتشو', 'value': '¥ 48,200', 'deals': '2'},
    {'name': 'مدير الفرع — ييوو', 'value': '¥ 41,000', 'deals': '1'},
    {'name': 'مسوّق — فوشان', 'value': '¥ 34,800', 'deals': '1'},
  ];

  static const List<Map<String, dynamic>> operations = [
    {
      'service': 'ترخيص الأعمال',
      'ref': 'OPS-441',
      'customer': 'أحمد الغامدي',
      'stages': ['استلام', 'مستندات', 'تقديم', 'متابعة', 'إغلاق'],
      'current': 2,
      'owner': 'إدخال البيانات — ييوو',
    },
    {
      'service': 'فنادق ومعارض',
      'ref': 'OPS-438',
      'customer': 'سارة الحربي',
      'stages': ['طلب', 'عرض', 'حجز', 'تأكيد', 'إغلاق'],
      'current': 1,
      'owner': 'مسوّق — قوانغتشو',
    },
    {
      'service': 'شراء من المصنع',
      'ref': 'OPS-430',
      'customer': 'شركة نوركو',
      'stages': ['بحث', 'عينة', 'عقد', 'إنتاج', 'شحن'],
      'current': 0,
      'owner': 'منسق مصانع — ييوو',
    },
  ];

  static const List<Map<String, dynamic>> suppliers = [
    {
      'name': 'Yiwu Bright Furniture Co.',
      'type': 'مصنع',
      'contact': 'Mr. Li · WeChat li_bright',
      'products': 'أثاث منزلي · مكاتب',
      'rating': '4.6',
      'owner': 'منسق مصانع — ييوو',
      'brands': 'OBIC Home',
    },
    {
      'name': 'Guangzhou SoftTex',
      'type': 'مورد',
      'contact': 'Ms. Chen · +86…',
      'products': 'أقمشة · عينات أزياء',
      'rating': '4.2',
      'owner': 'منسق — قوانغتشو',
      'brands': 'OBIC Wear',
    },
    {
      'name': 'Foshan MetalWorks',
      'type': 'مصنع',
      'contact': 'Mr. Wang',
      'products': 'هياكل معدنية',
      'rating': '4.8',
      'owner': 'منسق — فوشان',
      'brands': 'OBIC Industrial',
    },
  ];

  static const List<Map<String, String>> shipments = [
    {
      'id': 'SHP-9021',
      'customer': 'أحمد الغامدي',
      'supplier': 'Yiwu Bright',
      'goods': 'عينات أثاث',
      'qty': '12 قطعة',
      'date': '2026-08-08',
      'carrier': 'DHL',
      'tracking': 'DHL998877',
      'status': 'في الطريق',
      'eta': '2026-08-14',
    },
    {
      'id': 'SHP-9004',
      'customer': 'نوركو',
      'supplier': 'Foshan MetalWorks',
      'goods': 'هياكل معدنية',
      'qty': '1×40HQ',
      'date': '2026-08-01',
      'carrier': 'COSCO',
      'tracking': 'COSU123456',
      'status': 'تحميل في الميناء',
      'eta': '2026-09-02',
    },
  ];

  static const Map<String, String> finance = {
    'revenue': '¥ 142,200',
    'expenses': '¥ 38,750',
    'invoices': '24',
    'receivables': '¥ 51,300',
    'payables': '¥ 22,100',
    'opsCosts': '¥ 12,400',
    'pl': '¥ 103,450',
  };

  static const List<Map<String, String>> staff = [
    {
      'name': 'مدير التسويق — ييوو',
      'dept': 'المبيعات',
      'title': 'مدير تسويق',
      'manager': 'مدير الفرع',
      'role': 'مبيعات',
    },
    {
      'name': 'إدخال البيانات — ييوو',
      'dept': 'العمليات',
      'title': 'إدخال بيانات',
      'manager': 'مدير التسويق',
      'role': 'عمليات',
    },
    {
      'name': 'محاسب — HQ',
      'dept': 'المالية',
      'title': 'محاسب',
      'manager': 'المدير العام',
      'role': 'محاسب',
    },
    {
      'name': 'منسق مصانع — ييوو',
      'dept': 'المصانع',
      'title': 'منسق',
      'manager': 'مدير الفرع',
      'role': 'منسق مصانع',
    },
  ];

  static const List<Map<String, dynamic>> tasks = [
    {
      'title': 'إرسال عرض سعر فنادق لسارة',
      'owner': 'مسوّق — قوانغتشو',
      'due': 'اليوم 17:00',
      'priority': 'عالية',
      'status': 'قيد التنفيذ',
      'late': false,
    },
    {
      'title': 'مراجعة مستندات ترخيص أحمد',
      'owner': 'إدخال البيانات — ييوو',
      'due': 'أمس',
      'priority': 'عالية',
      'status': 'متأخرة',
      'late': true,
    },
    {
      'title': 'زيارة مصنع Bright Furniture',
      'owner': 'منسق مصانع — ييوو',
      'due': 'غداً',
      'priority': 'متوسطة',
      'status': 'مجدولة',
      'late': false,
    },
    {
      'title': 'إصدار فاتورة صفقة #7',
      'owner': 'محاسب — HQ',
      'due': 'اليوم',
      'priority': 'عادية',
      'status': 'مكتملة',
      'late': false,
    },
  ];

  static const List<Map<String, String>> kpis = [
    {'name': 'متوسط سرعة الرد', 'value': '14 دقيقة', 'target': '< 30 د'},
    {'name': 'عملاء تمت متابعتهم', 'value': '86', 'target': '80 / أسبوع'},
    {'name': 'تحويل استفسار → صفقة', 'value': '18%', 'target': '20%'},
    {'name': 'إغلاق الصفقات', 'value': '72%', 'target': '70%'},
    {'name': 'متوسط إنجاز الخدمة', 'value': '4.2 يوم', 'target': '< 5 أيام'},
    {'name': 'طلبات متأخرة', 'value': '9%', 'target': '< 8%'},
    {'name': 'رضا العملاء', 'value': '4.7 / 5', 'target': '≥ 4.5'},
  ];

  static const List<Map<String, String>> roles = [
    {'role': 'المدير العام', 'sees': 'كل الوحدات والتقارير'},
    {'role': 'الإدارة العليا', 'sees': 'Dashboard · KPI · تقارير · مالية ملخصة'},
    {'role': 'مدير القسم', 'sees': 'قسمه + موظفيه + الطلبات'},
    {'role': 'المبيعات', 'sees': 'CRM · استفسارات · مبيعات (عملاؤه)'},
    {'role': 'خدمة العملاء', 'sees': 'CRM محدود · استفسارات · مهام'},
    {'role': 'العمليات', 'sees': 'عمليات الخدمات · مهام · مستندات'},
    {'role': 'منسقو المصانع', 'sees': 'مصانع · عينات · لوجستيات مرتبطة'},
    {'role': 'المحاسب', 'sees': 'مالية · فواتير · مدفوعات'},
    {'role': 'الموارد البشرية', 'sees': 'HR · إجازات · تقييم'},
    {'role': 'الموظف', 'sees': 'مهامه وعملاؤه المعيّنون فقط'},
  ];

  static const List<String> integrations = [
    'WhatsApp Business',
    'WeChat',
    'الموقع الإلكتروني',
    'Instagram / Facebook / TikTok',
    'بوابات الدفع',
    'أنظمة الشحن والتتبع',
    'البريد الإلكتروني',
    'واجهات API خارجية لاحقاً',
  ];
}
