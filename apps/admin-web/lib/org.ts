// Made by Dr Ali — Form2 / boss restructure 2026-09 (workflow locked 19 Sep 2026).

export type OrgBranch = {
  id: string;
  nameEn: string;
  nameAr: string;
  nameZh: string;
  managerAr: string;
  managerEn: string;
  isPrimary?: boolean;
};

export type OrgStaff = {
  name: string;
  titleAr: string;
  titleEn: string;
  branchId: string;
  sectionAr?: string;
};

export type OrgServiceOwner = {
  serviceKey: string;
  labelAr: string;
  labelEn: string;
  primaryStaff: string;
  branchId: string;
  notesAr?: string;
};

/** Form2 desk titles (display only — AuthZ stays on role). */
export const FORM2_DESK_TITLES = [
  'General Manager / Owner',
  'Branch Manager',
  'Secretary (GM)',
  'HR Manager',
  'Local Accountant',
  'Marketing Manager — All Services',
  'General Marketing Manager',
  'Foreign Marketing Manager',
  'Visa Marketing — China',
  'Visa Marketing — Foreign',
  'Visa Department Manager',
  'Visa Group Assistant',
  'Passports / Client Data',
  'Foreign Company Registration',
  'Trademarks & Operations',
  'China Company Registration',
  'External Accounts',
  'Purchasing Manager',
  'Purchasing — AC & Furniture',
  'Purchasing — Beauty',
  'Purchasing — Auto Parts',
  'Purchasing — Phones',
  'Media / Photography',
  'Property Manager',
  'Software Manager',
  'Software Deputy',
  'AC Marketing',
  'Scholarships Marketing',
  'Scholarships Group Lead',
  'Scholarships Operations',
  'Shipping & Logistics Manager',
  'Banks / Visa Escort',
  'Trade Department Manager',
  'Guangzhou Marketing',
  'Visa (temp)',
  'Visa Manager',
  'Accounts Manager',
  'External Manager',
  'Property',
  'Foreign Trade Marketing',
  'Marketing Manager',
  'Marketer',
  'Data Entry',
  'Finance',
  'Secretary',
  'Cashier',
  'Scholarships Desk',
  'General Employee',
  'Head of Administration',
] as const;

export const ORG_BRANCHES: OrgBranch[] = [
  {
    id: 'Yiwu',
    nameEn: 'Yiwu',
    nameAr: 'إيوو',
    nameZh: '义乌',
    managerAr: 'الأستاذ ياسر',
    managerEn: 'Mr. Yasser',
    isPrimary: true,
  },
  {
    id: 'Guangzhou',
    nameEn: 'Guangzhou',
    nameAr: 'قوانغتشو',
    nameZh: '广州',
    managerAr: 'الأستاذ أمين',
    managerEn: 'Mr. Amin',
  },
  {
    id: 'Foshan',
    nameEn: 'Foshan',
    nameAr: 'فوشان',
    nameZh: '佛山',
    managerAr: 'الأستاذ وجيه',
    managerEn: 'Mr. Wajih',
  },
  {
    id: 'Hangzhou',
    nameEn: 'Hangzhou',
    nameAr: 'هانغتشو',
    nameZh: '杭州',
    managerAr: 'الأستاذ محمد',
    managerEn: 'Mr. Mohammed',
  },
  {
    id: 'Hainan',
    nameEn: 'Hainan',
    nameAr: 'هاينان',
    nameZh: '海南',
    managerAr: 'الأستاذ أحمد',
    managerEn: 'Mr. Ahmed',
  },
  {
    id: 'Yemen',
    nameEn: 'Yemen',
    nameAr: 'اليمن',
    nameZh: '也门',
    managerAr: 'باهي',
    managerEn: 'Bahi',
  },
  {
    id: 'Shanghai',
    nameEn: 'Shanghai',
    nameAr: 'شنغهاي',
    nameZh: '上海',
    managerAr: 'الأستاذ خالد',
    managerEn: 'Mr. Khaled',
  },
];

/** Boss Form2 roster — names/titles/branches. Phones/emails pending. */
export const ORG_STAFF: OrgStaff[] = [
  // Yiwu leadership
  { name: 'المهندس أنور', titleAr: 'مدير عام / صاحب الشركة', titleEn: 'General Manager / Owner', branchId: 'Yiwu', sectionAr: 'الإدارة العليا' },
  { name: 'الأستاذ ياسر', titleAr: 'مدير فرع إيوو', titleEn: 'Yiwu Branch Manager', branchId: 'Yiwu', sectionAr: 'الإدارة العليا' },
  { name: 'Lucky', titleAr: 'سكرتاري المدير العام', titleEn: 'Secretary (GM)', branchId: 'Yiwu', sectionAr: 'الإدارة العليا' },
  { name: 'Cici', titleAr: 'مدير قسم HR', titleEn: 'HR Manager', branchId: 'Yiwu', sectionAr: 'الإدارة العليا' },
  { name: 'Jolly', titleAr: 'محاسب محلي داخلي', titleEn: 'Local Accountant', branchId: 'Yiwu', sectionAr: 'الإدارة العليا' },
  // Marketing
  { name: 'Elin', titleAr: 'مدير تسويق — جميع الخدمات', titleEn: 'Marketing Manager — All Services', branchId: 'Yiwu', sectionAr: 'التسويق' },
  { name: 'Wadi', titleAr: 'مدير تسويق — جميع الخدمات', titleEn: 'Marketing Manager — All Services', branchId: 'Yiwu', sectionAr: 'التسويق' },
  { name: 'Susan', titleAr: 'مدير تسويق عام', titleEn: 'General Marketing Manager', branchId: 'Yiwu', sectionAr: 'التسويق' },
  { name: 'Jasen', titleAr: 'مدير تسويق عام', titleEn: 'General Marketing Manager', branchId: 'Yiwu', sectionAr: 'التسويق' },
  { name: 'Marathon', titleAr: 'مدير قسم التسويق الأجنبي', titleEn: 'Foreign Marketing Manager', branchId: 'Yiwu', sectionAr: 'التسويق' },
  // Visas
  { name: 'Musab', titleAr: 'مدير تسويق — فيز صينية', titleEn: 'Visa Marketing — China', branchId: 'Yiwu', sectionAr: 'الفيز' },
  { name: 'Lily', titleAr: 'مدير تسويق — فيز أجنبية', titleEn: 'Visa Marketing — Foreign', branchId: 'Yiwu', sectionAr: 'الفيز' },
  { name: 'Salima', titleAr: 'مدير قسم الفيز الصينية', titleEn: 'Visa Department Manager', branchId: 'Yiwu', sectionAr: 'الفيز' },
  { name: 'Souki', titleAr: 'مساعد مجموعة الفيز (بيانات)', titleEn: 'Visa Group Assistant', branchId: 'Yiwu', sectionAr: 'الفيز' },
  { name: 'Sara', titleAr: 'جوازات / تحقق بيانات العملاء', titleEn: 'Passports / Client Data', branchId: 'Yiwu', sectionAr: 'الفيز' },
  // Companies
  { name: 'Milly', titleAr: 'تسجيل شركات أجنبية — تسويق وعمليات', titleEn: 'Foreign Company Registration', branchId: 'Yiwu', sectionAr: 'الشركات' },
  { name: 'Nancy', titleAr: 'علامات تجارية وعمليات', titleEn: 'Trademarks & Operations', branchId: 'Yiwu', sectionAr: 'الشركات' },
  { name: 'Ana', titleAr: 'تسجيل شركات صينية', titleEn: 'China Company Registration', branchId: 'Yiwu', sectionAr: 'الشركات' },
  { name: 'Aliya', titleAr: 'حسابات خارجية للشركات', titleEn: 'External Accounts', branchId: 'Yiwu', sectionAr: 'الشركات' },
  // Purchasing
  { name: 'Tina', titleAr: 'مشتريات — مكيفات وأثاث', titleEn: 'Purchasing — AC & Furniture', branchId: 'Yiwu', sectionAr: 'المشتريات' },
  { name: 'Lina', titleAr: 'مشتريات — مكياج', titleEn: 'Purchasing — Beauty', branchId: 'Yiwu', sectionAr: 'المشتريات' },
  { name: 'Mikey', titleAr: 'مشتريات — قطع غيار سيارات', titleEn: 'Purchasing — Auto Parts', branchId: 'Yiwu', sectionAr: 'المشتريات' },
  { name: 'Yagube', titleAr: 'مشتريات — هواتف وإكسسوارات', titleEn: 'Purchasing — Phones', branchId: 'Yiwu', sectionAr: 'المشتريات' },
  // Other Yiwu
  { name: 'Kiki', titleAr: 'تصوير وإعلام', titleEn: 'Media / Photography', branchId: 'Yiwu', sectionAr: 'أخرى' },
  { name: 'Cathy', titleAr: 'مدير قسم العقارات', titleEn: 'Property Manager', branchId: 'Yiwu', sectionAr: 'أخرى' },
  { name: 'Ali', titleAr: 'مدير قسم البرمجيات', titleEn: 'Software Manager', branchId: 'Yiwu', sectionAr: 'أخرى' },
  { name: 'Wajdi', titleAr: 'نائب مدير البرمجيات', titleEn: 'Software Deputy', branchId: 'Yiwu', sectionAr: 'أخرى' },
  { name: 'Jack', titleAr: 'تسويق المكيفات', titleEn: 'AC Marketing', branchId: 'Yiwu', sectionAr: 'أخرى' },
  { name: 'Max', titleAr: 'تسويق المنح', titleEn: 'Scholarships Marketing', branchId: 'Yiwu', sectionAr: 'المنح' },
  { name: 'Khadijah', titleAr: 'رئيس مجموعة المنح', titleEn: 'Scholarships Group Lead', branchId: 'Yiwu', sectionAr: 'المنح' },
  { name: 'Nadia', titleAr: 'عمليات المنح', titleEn: 'Scholarships Operations', branchId: 'Yiwu', sectionAr: 'المنح' },
  { name: 'Nally', titleAr: 'عمليات المنح', titleEn: 'Scholarships Operations', branchId: 'Yiwu', sectionAr: 'المنح' },
  { name: 'Sally', titleAr: 'مديرة الشحن والعمليات', titleEn: 'Shipping & Logistics Manager', branchId: 'Yiwu', sectionAr: 'الشحن' },
  // Guangzhou
  { name: 'الأستاذ أمين', titleAr: 'مدير فرع قوانغتشو', titleEn: 'Guangzhou Branch Manager', branchId: 'Guangzhou' },
  { name: 'Kimi', titleAr: 'حسابات خارجية', titleEn: 'External Accounts', branchId: 'Guangzhou' },
  { name: 'Mia', titleAr: 'بنوك ومرافقة فيزا', titleEn: 'Banks / Visa Escort', branchId: 'Guangzhou' },
  { name: 'Wajeeh', titleAr: 'تسويق قوانغتشو', titleEn: 'Guangzhou Marketing', branchId: 'Guangzhou' },
  { name: 'Jinney', titleAr: 'فيز صينية وأجنبية (مؤقت)', titleEn: 'Visa (temp)', branchId: 'Guangzhou' },
  { name: 'Jinefer', titleAr: 'عقارات', titleEn: 'Property', branchId: 'Guangzhou' },
  // Foshan
  { name: 'الأستاذ وجيه', titleAr: 'مدير فرع فوشان', titleEn: 'Foshan Branch Manager', branchId: 'Foshan' },
  { name: 'Lily (Foshan)', titleAr: 'مدير الفيزا', titleEn: 'Visa Manager', branchId: 'Foshan' },
  // Hangzhou
  { name: 'الأستاذ محمد', titleAr: 'مدير فرع هانغتشو', titleEn: 'Hangzhou Branch Manager', branchId: 'Hangzhou' },
  // Hainan
  { name: 'الأستاذ أحمد', titleAr: 'مدير فرع هاينان', titleEn: 'Hainan Branch Manager', branchId: 'Hainan' },
  { name: 'سوسان', titleAr: 'مدير حسابات', titleEn: 'Accounts Manager', branchId: 'Hainan' },
  { name: 'كارلس', titleAr: 'مدير فيزا', titleEn: 'Visa Manager', branchId: 'Hainan' },
  { name: 'جاك', titleAr: 'مدير خارجي', titleEn: 'External Manager', branchId: 'Hainan' },
  // Shanghai
  { name: 'الأستاذ خالد', titleAr: 'مدير فرع شنغهاي', titleEn: 'Shanghai Branch Manager', branchId: 'Shanghai' },
  // Yemen
  { name: 'باهي', titleAr: 'مدير فرع اليمن', titleEn: 'Yemen Branch Manager', branchId: 'Yemen' },
  { name: 'سمر', titleAr: 'تسويق المنح', titleEn: 'Scholarships Marketing', branchId: 'Yemen' },
  { name: 'سماح', titleAr: 'تسويق التجارة الخارجية', titleEn: 'Foreign Trade Marketing', branchId: 'Yemen' },
  // Trade
  { name: 'الأستاذ سامي', titleAr: 'مدير قسم التجارة', titleEn: 'Trade Department Manager', branchId: 'Yiwu', sectionAr: 'التجارة' },
];

export const ORG_SERVICE_OWNERS: OrgServiceOwner[] = [
  { serviceKey: 'visas', labelAr: 'تأشيرات', labelEn: 'Visas', primaryStaff: 'Salima / Musab / Lily', branchId: 'Yiwu', notesAr: 'Jinney قوانغتشو · Lily فوشان · كارلس هاينان' },
  { serviceKey: 'travel', labelAr: 'فنادق وطيران / سياحة', labelEn: 'Hotels · Flights · Travel', primaryStaff: 'Elin / Wadi', branchId: 'Yiwu' },
  { serviceKey: 'property', labelAr: 'عقارات', labelEn: 'Property', primaryStaff: 'Cathy', branchId: 'Yiwu', notesAr: 'Jinefer قوانغتشو' },
  { serviceKey: 'logistics', labelAr: 'شحن ولوجستيات', labelEn: 'Logistics', primaryStaff: 'Sally', branchId: 'Yiwu' },
  { serviceKey: 'business', labelAr: 'أعمال وتقنية', labelEn: 'Business & Tech', primaryStaff: 'Ali / Milly / Nancy / Ana', branchId: 'Yiwu' },
  { serviceKey: 'food', labelAr: 'طعام ومشروبات', labelEn: 'Food', primaryStaff: '—', branchId: 'Yiwu', notesAr: 'لاحقاً' },
  { serviceKey: 'education', labelAr: 'تعليم ومنح', labelEn: 'Education & Scholarships', primaryStaff: 'Max / Khadijah', branchId: 'Yiwu', notesAr: 'سمر اليمن للمنح' },
  { serviceKey: 'government', labelAr: 'خدمات حكومية', labelEn: 'Government', primaryStaff: 'Salima / Sara', branchId: 'Yiwu' },
  { serviceKey: 'healthcare', labelAr: 'رعاية صحية', labelEn: 'Healthcare', primaryStaff: '—', branchId: 'Yiwu', notesAr: 'لاحقاً' },
  { serviceKey: 'shopping', labelAr: 'تسوق / مشتريات', labelEn: 'Shopping / Purchasing', primaryStaff: 'Tina / Lina / Mikey / Yagube', branchId: 'Yiwu' },
];

/** Management answers locked 19 Sep 2026 — FINAL. Mirror: Flutter obic_org.dart + API form2-workflow.ts. */
export type OrgWorkflowRule = {
  id: number;
  questionAr: string;
  questionEn: string;
  answerAr: string;
  answerEn: string;
};

export const FORM2_WORKFLOW_LOCKED_AT = '2026-09-19';

export const ORG_WORKFLOW_RULES: OrgWorkflowRule[] = [
  {
    id: 1,
    questionAr: 'هل الموظف يغيّر حالة الطلب بنفسه؟',
    questionEn: 'Can the employee change order status alone?',
    answerAr:
      'إيوو: سكرتير الفرع فقط (والمشرف الأعلى يستثنى). الفروع الأخرى: الموظف المعيّن على الطلب.',
    answerEn:
      'Yiwu: only the branch Secretary (SuperAdmin override). Other branches: assigned employee.',
  },
  {
    id: 2,
    questionAr: 'متى نضع «بانتظار العميل»؟',
    questionEn: 'When do we set Waiting for customer?',
    answerAr: 'عندما يحتاج الموظف رداً من العميل (نص / مستندات / تأكيد).',
    answerEn:
      'When staff needs a reply from the customer (text, documents, or confirmation).',
  },
  {
    id: 3,
    questionAr: 'هل يُغلق الطلب من التطبيق فقط؟',
    questionEn: 'Is the order closed from the app only?',
    answerAr: 'لا — الإغلاق من تطبيق الموبايل ولوحة الإدارة (كلاهما).',
    answerEn: 'No — close from mobile app and Admin web (both).',
  },
  {
    id: 4,
    questionAr: 'من يحوّل الطلب إذا كان الموظف خارج الدوام؟',
    questionEn: 'Who reassigns when staff is off-duty?',
    answerAr: 'مندوب مبيعات العميل أو مدير الفرع (ضمن نطاق الفرع).',
    answerEn: 'Client’s sales rep or branch manager (same branch scope).',
  },
  {
    id: 5,
    questionAr: 'هل يمكن إضافة موظفين جدد من لوحة الإدارة؟',
    questionEn: 'Can new staff be added from Admin?',
    answerAr:
      'نعم — المشرف الأعلى يضيف من Admin. الجوالات والبريد الحقيقيان يُدخلان لاحقاً من نفس الواجهة في الإنتاج.',
    answerEn:
      'Yes — SuperAdmin adds staff from Admin. Production mobiles/emails are entered later via that UI.',
  },
];

/** @deprecated Use ORG_WORKFLOW_RULES — Form2 answers locked 19 Sep 2026. */
export const ORG_WORKFLOW_PENDING = ORG_WORKFLOW_RULES.map((r) => ({
  id: r.id,
  ar: r.questionAr,
  en: r.questionEn,
}));

/** Mirror API form2-workflow — Yiwu status ACL. */
export function isSecretaryTitle(staffTitle: string | null | undefined): boolean {
  const raw = (staffTitle ?? '').trim();
  if (!raw) return false;
  const t = raw.toLowerCase();
  if (t.includes('secretary')) return true;
  if (/سكرتير/.test(raw) || /سكرتاري/.test(raw)) return true;
  return false;
}

export function isSecretaryEmail(email: string | null | undefined): boolean {
  const e = (email ?? '').trim().toLowerCase();
  if (!e) return false;
  return /(^|\.)secretary@/.test(e) || e.includes('.secretary@');
}

export function isYiwuRequestBranch(
  preferredBranch: string | null | undefined,
): boolean {
  return (preferredBranch ?? '').trim().toLowerCase() === 'yiwu';
}

export function isYiwuSecretary(user: {
  role?: string;
  staffTitle?: string | null;
  branchLabel?: string | null;
  email?: string | null;
}): boolean {
  const role = user.role ?? '';
  if (role !== 'Employee' && role !== 'SuperAdmin') return false;
  const desk =
    isSecretaryTitle(user.staffTitle) || isSecretaryEmail(user.email);
  if (!desk) return false;
  const branch = (user.branchLabel ?? '').trim().toLowerCase();
  if (branch === 'yiwu') return true;
  const email = (user.email ?? '').trim().toLowerCase();
  return email.includes('.yiwu.secretary@');
}

export function canUpdateOrderStatus(
  user: {
    role?: string;
    staffTitle?: string | null;
    branchLabel?: string | null;
    email?: string | null;
    isSuperAdmin?: boolean;
  },
  order: { preferredBranch?: string | null },
  opts: { assignedToSelf: boolean },
): boolean {
  if (user.isSuperAdmin === true || user.role === 'SuperAdmin') return true;
  if (user.role !== 'Employee') return false;
  if (isYiwuRequestBranch(order.preferredBranch)) {
    return isYiwuSecretary(user);
  }
  return opts.assignedToSelf;
}

export function branchLabel(id: string, lang: 'ar' | 'en' | 'zh' | 'fr') {
  const b = ORG_BRANCHES.find((x) => x.id === id);
  if (!b) return id;
  if (lang === 'ar') return b.nameAr;
  if (lang === 'zh') return b.nameZh;
  return b.nameEn;
}
