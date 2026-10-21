// Made by Dr Ali
// OBIC org structure from management (Form 2 / restructure 2026-09).
// Display + routing hints — full accounts wait for mobile/email from boss.

class ObicOrgBranch {
  const ObicOrgBranch({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.nameZh,
    required this.managerAr,
    this.isPrimary = false,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final String nameZh;
  final String managerAr;
  final bool isPrimary;
}

class ObicServiceOwner {
  const ObicServiceOwner({
    required this.serviceKey,
    required this.labelAr,
    required this.primaryStaff,
    required this.branchId,
    this.labelEn = '',
    this.notesAr = '',
  });

  final String serviceKey;
  final String labelAr;
  final String labelEn;
  final String primaryStaff;
  final String branchId;
  final String notesAr;
}

class ObicOrgStaff {
  const ObicOrgStaff({
    required this.name,
    required this.titleAr,
    required this.titleEn,
    required this.branchId,
    this.sectionAr = '',
  });

  final String name;
  final String titleAr;
  final String titleEn;
  final String branchId;
  final String sectionAr;
}

/// Seven branches after management restructure (Shanghai added).
const kObicOrgBranches = <ObicOrgBranch>[
  ObicOrgBranch(
    id: 'Yiwu',
    nameEn: 'Yiwu',
    nameAr: 'إيوو',
    nameZh: '义乌',
    managerAr: 'الأستاذ ياسر',
    isPrimary: true,
  ),
  ObicOrgBranch(
    id: 'Guangzhou',
    nameEn: 'Guangzhou',
    nameAr: 'قوانغتشو',
    nameZh: '广州',
    managerAr: 'الأستاذ أمين',
  ),
  ObicOrgBranch(
    id: 'Foshan',
    nameEn: 'Foshan',
    nameAr: 'فوشان',
    nameZh: '佛山',
    managerAr: 'الأستاذ وجيه',
  ),
  ObicOrgBranch(
    id: 'Hangzhou',
    nameEn: 'Hangzhou',
    nameAr: 'هانغتشو',
    nameZh: '杭州',
    managerAr: 'الأستاذ محمد',
  ),
  ObicOrgBranch(
    id: 'Hainan',
    nameEn: 'Hainan',
    nameAr: 'هاينان',
    nameZh: '海南',
    managerAr: 'الأستاذ أحمد',
  ),
  ObicOrgBranch(
    id: 'Yemen',
    nameEn: 'Yemen',
    nameAr: 'اليمن',
    nameZh: '也门',
    managerAr: 'باهي',
  ),
  ObicOrgBranch(
    id: 'Shanghai',
    nameEn: 'Shanghai',
    nameAr: 'شنغهاي',
    nameZh: '上海',
    managerAr: 'الأستاذ خالد',
  ),
];

/// Boss Form2 roster — phones/emails pending.
const kObicOrgStaff = <ObicOrgStaff>[
  ObicOrgStaff(name: 'المهندس أنور', titleAr: 'مدير عام / صاحب الشركة', titleEn: 'General Manager / Owner', branchId: 'Yiwu', sectionAr: 'الإدارة العليا'),
  ObicOrgStaff(name: 'الأستاذ ياسر', titleAr: 'مدير فرع إيوو', titleEn: 'Yiwu Branch Manager', branchId: 'Yiwu', sectionAr: 'الإدارة العليا'),
  ObicOrgStaff(name: 'Lucky', titleAr: 'سكرتاري المدير العام', titleEn: 'Secretary (GM)', branchId: 'Yiwu', sectionAr: 'الإدارة العليا'),
  ObicOrgStaff(name: 'Cici', titleAr: 'مدير قسم HR', titleEn: 'HR Manager', branchId: 'Yiwu', sectionAr: 'الإدارة العليا'),
  ObicOrgStaff(name: 'Jolly', titleAr: 'محاسب محلي داخلي', titleEn: 'Local Accountant', branchId: 'Yiwu', sectionAr: 'الإدارة العليا'),
  ObicOrgStaff(name: 'Elin', titleAr: 'مدير تسويق — جميع الخدمات', titleEn: 'Marketing Manager — All Services', branchId: 'Yiwu', sectionAr: 'التسويق'),
  ObicOrgStaff(name: 'Wadi', titleAr: 'مدير تسويق — جميع الخدمات', titleEn: 'Marketing Manager — All Services', branchId: 'Yiwu', sectionAr: 'التسويق'),
  ObicOrgStaff(name: 'Susan', titleAr: 'مدير تسويق عام', titleEn: 'General Marketing Manager', branchId: 'Yiwu', sectionAr: 'التسويق'),
  ObicOrgStaff(name: 'Jasen', titleAr: 'مدير تسويق عام', titleEn: 'General Marketing Manager', branchId: 'Yiwu', sectionAr: 'التسويق'),
  ObicOrgStaff(name: 'Marathon', titleAr: 'مدير قسم التسويق الأجنبي', titleEn: 'Foreign Marketing Manager', branchId: 'Yiwu', sectionAr: 'التسويق'),
  ObicOrgStaff(name: 'Musab', titleAr: 'مدير تسويق — فيز صينية', titleEn: 'Visa Marketing — China', branchId: 'Yiwu', sectionAr: 'الفيز'),
  ObicOrgStaff(name: 'Lily', titleAr: 'مدير تسويق — فيز أجنبية', titleEn: 'Visa Marketing — Foreign', branchId: 'Yiwu', sectionAr: 'الفيز'),
  ObicOrgStaff(name: 'Salima', titleAr: 'مدير قسم الفيز الصينية', titleEn: 'Visa Department Manager', branchId: 'Yiwu', sectionAr: 'الفيز'),
  ObicOrgStaff(name: 'Souki', titleAr: 'مساعد مجموعة الفيز (بيانات)', titleEn: 'Visa Group Assistant', branchId: 'Yiwu', sectionAr: 'الفيز'),
  ObicOrgStaff(name: 'Sara', titleAr: 'جوازات / تحقق بيانات العملاء', titleEn: 'Passports / Client Data', branchId: 'Yiwu', sectionAr: 'الفيز'),
  ObicOrgStaff(name: 'Milly', titleAr: 'تسجيل شركات أجنبية — تسويق وعمليات', titleEn: 'Foreign Company Registration', branchId: 'Yiwu', sectionAr: 'الشركات'),
  ObicOrgStaff(name: 'Nancy', titleAr: 'علامات تجارية وعمليات', titleEn: 'Trademarks & Operations', branchId: 'Yiwu', sectionAr: 'الشركات'),
  ObicOrgStaff(name: 'Ana', titleAr: 'تسجيل شركات صينية', titleEn: 'China Company Registration', branchId: 'Yiwu', sectionAr: 'الشركات'),
  ObicOrgStaff(name: 'Aliya', titleAr: 'حسابات خارجية للشركات', titleEn: 'External Accounts', branchId: 'Yiwu', sectionAr: 'الشركات'),
  ObicOrgStaff(name: 'Tina', titleAr: 'مشتريات — مكيفات وأثاث', titleEn: 'Purchasing — AC & Furniture', branchId: 'Yiwu', sectionAr: 'المشتريات'),
  ObicOrgStaff(name: 'Lina', titleAr: 'مشتريات — مكياج', titleEn: 'Purchasing — Beauty', branchId: 'Yiwu', sectionAr: 'المشتريات'),
  ObicOrgStaff(name: 'Mikey', titleAr: 'مشتريات — قطع غيار سيارات', titleEn: 'Purchasing — Auto Parts', branchId: 'Yiwu', sectionAr: 'المشتريات'),
  ObicOrgStaff(name: 'Yagube', titleAr: 'مشتريات — هواتف وإكسسوارات', titleEn: 'Purchasing — Phones', branchId: 'Yiwu', sectionAr: 'المشتريات'),
  ObicOrgStaff(name: 'Kiki', titleAr: 'تصوير وإعلام', titleEn: 'Media / Photography', branchId: 'Yiwu', sectionAr: 'أخرى'),
  ObicOrgStaff(name: 'Cathy', titleAr: 'مدير قسم العقارات', titleEn: 'Property Manager', branchId: 'Yiwu', sectionAr: 'أخرى'),
  ObicOrgStaff(name: 'Ali', titleAr: 'مدير قسم البرمجيات', titleEn: 'Software Manager', branchId: 'Yiwu', sectionAr: 'أخرى'),
  ObicOrgStaff(name: 'Wajdi', titleAr: 'نائب مدير البرمجيات', titleEn: 'Software Deputy', branchId: 'Yiwu', sectionAr: 'أخرى'),
  ObicOrgStaff(name: 'Jack', titleAr: 'تسويق المكيفات', titleEn: 'AC Marketing', branchId: 'Yiwu', sectionAr: 'أخرى'),
  ObicOrgStaff(name: 'Max', titleAr: 'تسويق المنح', titleEn: 'Scholarships Marketing', branchId: 'Yiwu', sectionAr: 'المنح'),
  ObicOrgStaff(name: 'Khadijah', titleAr: 'رئيس مجموعة المنح', titleEn: 'Scholarships Group Lead', branchId: 'Yiwu', sectionAr: 'المنح'),
  ObicOrgStaff(name: 'Nadia', titleAr: 'عمليات المنح', titleEn: 'Scholarships Operations', branchId: 'Yiwu', sectionAr: 'المنح'),
  ObicOrgStaff(name: 'Nally', titleAr: 'عمليات المنح', titleEn: 'Scholarships Operations', branchId: 'Yiwu', sectionAr: 'المنح'),
  ObicOrgStaff(name: 'Sally', titleAr: 'مديرة الشحن والعمليات', titleEn: 'Shipping & Logistics Manager', branchId: 'Yiwu', sectionAr: 'الشحن'),
  ObicOrgStaff(name: 'الأستاذ أمين', titleAr: 'مدير فرع قوانغتشو', titleEn: 'Guangzhou Branch Manager', branchId: 'Guangzhou'),
  ObicOrgStaff(name: 'Kimi', titleAr: 'حسابات خارجية', titleEn: 'External Accounts', branchId: 'Guangzhou'),
  ObicOrgStaff(name: 'Mia', titleAr: 'بنوك ومرافقة فيزا', titleEn: 'Banks / Visa Escort', branchId: 'Guangzhou'),
  ObicOrgStaff(name: 'Wajeeh', titleAr: 'تسويق قوانغتشو', titleEn: 'Guangzhou Marketing', branchId: 'Guangzhou'),
  ObicOrgStaff(name: 'Jinney', titleAr: 'فيز صينية وأجنبية (مؤقت)', titleEn: 'Visa (temp)', branchId: 'Guangzhou'),
  ObicOrgStaff(name: 'Jinefer', titleAr: 'عقارات', titleEn: 'Property', branchId: 'Guangzhou'),
  ObicOrgStaff(name: 'الأستاذ وجيه', titleAr: 'مدير فرع فوشان', titleEn: 'Foshan Branch Manager', branchId: 'Foshan'),
  ObicOrgStaff(name: 'Lily (Foshan)', titleAr: 'مدير الفيزا', titleEn: 'Visa Manager', branchId: 'Foshan'),
  ObicOrgStaff(name: 'الأستاذ محمد', titleAr: 'مدير فرع هانغتشو', titleEn: 'Hangzhou Branch Manager', branchId: 'Hangzhou'),
  ObicOrgStaff(name: 'الأستاذ أحمد', titleAr: 'مدير فرع هاينان', titleEn: 'Hainan Branch Manager', branchId: 'Hainan'),
  ObicOrgStaff(name: 'سوسان', titleAr: 'مدير حسابات', titleEn: 'Accounts Manager', branchId: 'Hainan'),
  ObicOrgStaff(name: 'كارلس', titleAr: 'مدير فيزا', titleEn: 'Visa Manager', branchId: 'Hainan'),
  ObicOrgStaff(name: 'جاك', titleAr: 'مدير خارجي', titleEn: 'External Manager', branchId: 'Hainan'),
  ObicOrgStaff(name: 'الأستاذ خالد', titleAr: 'مدير فرع شنغهاي', titleEn: 'Shanghai Branch Manager', branchId: 'Shanghai'),
  ObicOrgStaff(name: 'باهي', titleAr: 'مدير فرع اليمن', titleEn: 'Yemen Branch Manager', branchId: 'Yemen'),
  ObicOrgStaff(name: 'سمر', titleAr: 'تسويق المنح', titleEn: 'Scholarships Marketing', branchId: 'Yemen'),
  ObicOrgStaff(name: 'سماح', titleAr: 'تسويق التجارة الخارجية', titleEn: 'Foreign Trade Marketing', branchId: 'Yemen'),
  ObicOrgStaff(name: 'الأستاذ سامي', titleAr: 'مدير قسم التجارة', titleEn: 'Trade Department Manager', branchId: 'Yiwu', sectionAr: 'التجارة'),
];

/// Temporary service owners — start with Yiwu (management proposal).
const kObicServiceOwners = <ObicServiceOwner>[
  ObicServiceOwner(
    serviceKey: 'visas',
    labelAr: 'تأشيرات',
    labelEn: 'Visas',
    primaryStaff: 'Salima / Musab / Lily',
    branchId: 'Yiwu',
    notesAr: 'Jinney قوانغتشو · Lily فوشان · كارلس هاينان',
  ),
  ObicServiceOwner(
    serviceKey: 'travel',
    labelAr: 'فنادق وطيران / سياحة',
    labelEn: 'Hotels · Flights · Travel',
    primaryStaff: 'Elin / Wadi',
    branchId: 'Yiwu',
  ),
  ObicServiceOwner(
    serviceKey: 'travel_flights',
    labelAr: 'فنادق وطيران',
    labelEn: 'Hotels & Flights',
    primaryStaff: 'Elin / Wadi',
    branchId: 'Yiwu',
  ),
  ObicServiceOwner(
    serviceKey: 'property',
    labelAr: 'عقارات',
    labelEn: 'Property',
    primaryStaff: 'Cathy',
    branchId: 'Yiwu',
    notesAr: 'Jinefer قوانغتشو',
  ),
  ObicServiceOwner(
    serviceKey: 'logistics',
    labelAr: 'شحن ولوجستيات',
    labelEn: 'Logistics',
    primaryStaff: 'Sally',
    branchId: 'Yiwu',
  ),
  ObicServiceOwner(
    serviceKey: 'business',
    labelAr: 'أعمال وتقنية',
    labelEn: 'Business & Tech',
    primaryStaff: 'Ali / Milly / Nancy / Ana',
    branchId: 'Yiwu',
  ),
  ObicServiceOwner(
    serviceKey: 'food',
    labelAr: 'طعام ومشروبات',
    labelEn: 'Food',
    primaryStaff: '—',
    branchId: 'Yiwu',
    notesAr: 'لاحقاً',
  ),
  ObicServiceOwner(
    serviceKey: 'education',
    labelAr: 'تعليم ومنح',
    labelEn: 'Education & Scholarships',
    primaryStaff: 'Max / Khadijah',
    branchId: 'Yiwu',
    notesAr: 'سمر اليمن للمنح',
  ),
  ObicServiceOwner(
    serviceKey: 'government',
    labelAr: 'خدمات حكومية',
    labelEn: 'Government',
    primaryStaff: 'Salima / Sara',
    branchId: 'Yiwu',
  ),
  ObicServiceOwner(
    serviceKey: 'healthcare',
    labelAr: 'رعاية صحية',
    labelEn: 'Healthcare',
    primaryStaff: '—',
    branchId: 'Yiwu',
    notesAr: 'لاحقاً',
  ),
  ObicServiceOwner(
    serviceKey: 'shopping',
    labelAr: 'تسوق / مشتريات',
    labelEn: 'Shopping / Purchasing',
    primaryStaff: 'Tina / Lina / Mikey / Yagube',
    branchId: 'Yiwu',
  ),
];

/// Management answers locked 19 Sep 2026 — FINAL.
/// Mirror: admin-web lib/org.ts + API form2-workflow.ts.
class ObicWorkflowRule {
  const ObicWorkflowRule({
    required this.id,
    required this.questionAr,
    required this.questionEn,
    required this.answerAr,
    required this.answerEn,
  });

  final int id;
  final String questionAr;
  final String questionEn;
  final String answerAr;
  final String answerEn;
}

const kForm2WorkflowLockedAt = '2026-09-19';

const kObicWorkflowRules = <ObicWorkflowRule>[
  ObicWorkflowRule(
    id: 1,
    questionAr: 'هل الموظف يغيّر حالة الطلب بنفسه؟',
    questionEn: 'Can the employee change order status alone?',
    answerAr:
        'إيوو: سكرتير الفرع فقط (والمشرف الأعلى يستثنى). الفروع الأخرى: الموظف المعيّن على الطلب.',
    answerEn:
        'Yiwu: only the branch Secretary (SuperAdmin override). Other branches: assigned employee.',
  ),
  ObicWorkflowRule(
    id: 2,
    questionAr: 'متى نضع «بانتظار العميل»؟',
    questionEn: 'When do we set Waiting for customer?',
    answerAr: 'عندما يحتاج الموظف رداً من العميل (نص / مستندات / تأكيد).',
    answerEn:
        'When staff needs a reply from the customer (text, documents, or confirmation).',
  ),
  ObicWorkflowRule(
    id: 3,
    questionAr: 'هل يُغلق الطلب من التطبيق فقط؟',
    questionEn: 'Is the order closed from the app only?',
    answerAr: 'لا — الإغلاق من تطبيق الموبايل ولوحة الإدارة (كلاهما).',
    answerEn: 'No — close from mobile app and Admin web (both).',
  ),
  ObicWorkflowRule(
    id: 4,
    questionAr: 'من يحوّل الطلب إذا كان الموظف خارج الدوام؟',
    questionEn: 'Who reassigns when staff is off-duty?',
    answerAr: 'مندوب مبيعات العميل أو مدير الفرع (ضمن نطاق الفرع).',
    answerEn: 'Client’s sales rep or branch manager (same branch scope).',
  ),
  ObicWorkflowRule(
    id: 5,
    questionAr: 'هل يمكن إضافة موظفين جدد من لوحة الإدارة؟',
    questionEn: 'Can new staff be added from Admin?',
    answerAr:
        'نعم — المشرف الأعلى يضيف من Admin. الجوالات والبريد الحقيقيان يُدخلان لاحقاً من نفس الواجهة في الإنتاج.',
    answerEn:
        'Yes — SuperAdmin adds staff from Admin. Production mobiles/emails are entered later via that UI.',
  ),
];

String branchDisplayName(String branchId, String langCode) {
  for (final b in kObicOrgBranches) {
    if (b.id == branchId) {
      switch (langCode) {
        case 'ar':
          return b.nameAr;
        case 'zh':
          return b.nameZh;
        default:
          return b.nameEn;
      }
    }
  }
  return branchId;
}

ObicServiceOwner? serviceOwnerForSlug(String slug) {
  final key = slug.trim().toLowerCase();
  for (final o in kObicServiceOwners) {
    if (o.serviceKey == key) return o;
  }
  return null;
}

String serviceOwnerHint(String slug, String langCode) {
  final o = serviceOwnerForSlug(slug);
  if (o == null) return '';
  final branch = branchDisplayName(o.branchId, langCode);
  if (langCode.startsWith('ar')) {
    final notes = o.notesAr.isEmpty ? '' : ' · ${o.notesAr}';
    return 'المتابعة: ${o.primaryStaff} · فرع $branch$notes';
  }
  if (langCode.startsWith('zh')) {
    return '对接：${o.primaryStaff} · $branch';
  }
  return 'Handled by ${o.primaryStaff} · $branch';
}

/// Mirror API form2-workflow — desk title matches Secretary (EN / AR).
bool isSecretaryTitle(String? staffTitle) {
  final raw = (staffTitle ?? '').trim();
  if (raw.isEmpty) return false;
  final t = raw.toLowerCase();
  if (t.contains('secretary')) return true;
  if (raw.contains('سكرتير') || raw.contains('سكرتاري')) return true;
  return false;
}

bool isSecretaryEmail(String? email) {
  final e = (email ?? '').trim().toLowerCase();
  if (e.isEmpty) return false;
  return e.contains('.secretary@') || RegExp(r'(^|\.)secretary@').hasMatch(e);
}

bool isYiwuRequestBranch(String? preferredBranch) {
  return (preferredBranch ?? '').trim().toLowerCase() == 'yiwu';
}

bool isYiwuSecretary({
  required String role,
  String? staffTitle,
  String? branchLabel,
  String? email,
}) {
  if (role != 'Employee' && role != 'SuperAdmin') return false;
  final desk = isSecretaryTitle(staffTitle) || isSecretaryEmail(email);
  if (!desk) return false;
  final branch = (branchLabel ?? '').trim().toLowerCase();
  if (branch == 'yiwu') return true;
  final em = (email ?? '').trim().toLowerCase();
  return em.contains('.yiwu.secretary@');
}

/// Who may change customer-visible order status (mirror API).
bool canUpdateOrderStatus({
  required String role,
  String? staffTitle,
  String? branchLabel,
  String? email,
  required String? preferredBranch,
  required bool assignedToSelf,
}) {
  if (role == 'SuperAdmin') return true;
  if (role != 'Employee') return false;
  if (isYiwuRequestBranch(preferredBranch)) {
    return isYiwuSecretary(
      role: role,
      staffTitle: staffTitle,
      branchLabel: branchLabel,
      email: email,
    );
  }
  return assignedToSelf;
}
