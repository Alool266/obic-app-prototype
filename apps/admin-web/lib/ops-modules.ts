// Made by Dr Ali — Internal Ops module registry (web prototype, mirrors mobile).

export type OpsModule = {
  id: string;
  titleAr: string;
  titleEn: string;
  subtitleAr: string;
  subtitleEn: string;
  accent: string;
};

/** Independent modules — add here without rewriting the hub page. */
export const OPS_MODULES: OpsModule[] = [
  {
    id: 'dashboard',
    titleAr: 'لوحة التحكم',
    titleEn: 'Dashboard',
    subtitleAr: 'نظرة شاملة على الشركة',
    subtitleEn: 'Company-wide overview',
    accent: '#1A6DFF',
  },
  {
    id: 'crm',
    titleAr: 'إدارة العملاء CRM',
    titleEn: 'CRM',
    subtitleAr: 'ملفات العملاء · المصادر · المتابعة',
    subtitleEn: 'Profiles · sources · follow-ups',
    accent: '#0EA5E9',
  },
  {
    id: 'inquiries',
    titleAr: 'الاستفسارات والطلبات',
    titleEn: 'Inquiries',
    subtitleAr: 'رقم مرجعي · مراحل · Workflow',
    subtitleEn: 'Reference · stages · workflow',
    accent: '#8B5CF6',
  },
  {
    id: 'sales',
    titleAr: 'المبيعات',
    titleEn: 'Sales',
    subtitleAr: 'Leads · عروض · عقود · صفقات',
    subtitleEn: 'Leads · quotes · contracts · deals',
    accent: '#10B981',
  },
  {
    id: 'operations',
    titleAr: 'الخدمات والعمليات',
    titleEn: 'Operations',
    subtitleAr: 'Workflow لكل خدمة',
    subtitleEn: 'Per-service workflow',
    accent: '#F59E0B',
  },
  {
    id: 'suppliers',
    titleAr: 'المصانع والموردين',
    titleEn: 'Suppliers',
    subtitleAr: 'مصانع · ماركات · تقييم',
    subtitleEn: 'Factories · brands · ratings',
    accent: '#64748B',
  },
  {
    id: 'logistics',
    titleAr: 'الشحن واللوجستيات',
    titleEn: 'Logistics',
    subtitleAr: 'شحنات · تتبع · مستندات',
    subtitleEn: 'Shipments · tracking · docs',
    accent: '#0284C7',
  },
  {
    id: 'finance',
    titleAr: 'المالية والمحاسبة',
    titleEn: 'Finance',
    subtitleAr: 'إيرادات · مصروفات · فواتير',
    subtitleEn: 'Revenue · expenses · invoices',
    accent: '#059669',
  },
  {
    id: 'hr',
    titleAr: 'الموارد البشرية',
    titleEn: 'HR',
    subtitleAr: 'موظفون · أقسام · إجازات',
    subtitleEn: 'Staff · departments · leave',
    accent: '#DB2777',
  },
  {
    id: 'tasks',
    titleAr: 'المهام وسير العمل',
    titleEn: 'Tasks',
    subtitleAr: 'مهام · أولويات · تأخيرات',
    subtitleEn: 'Tasks · priorities · delays',
    accent: '#EA580C',
  },
  {
    id: 'documents',
    titleAr: 'المستندات والأرشفة',
    titleEn: 'Documents',
    subtitleAr: 'ملفات مربوطة بالجهة',
    subtitleEn: 'Entity-linked files',
    accent: '#475569',
  },
  {
    id: 'reports',
    titleAr: 'التقارير',
    titleEn: 'Reports',
    subtitleAr: 'يومي · شهري · سنوي · تصدير',
    subtitleEn: 'Daily · monthly · yearly · export',
    accent: '#4F46E5',
  },
  {
    id: 'kpi',
    titleAr: 'مؤشرات الأداء KPI',
    titleEn: 'KPI',
    subtitleAr: 'أداء الموظفين والأقسام',
    subtitleEn: 'Staff & department performance',
    accent: '#DC2626',
  },
  {
    id: 'permissions',
    titleAr: 'الصلاحيات والأمان',
    titleEn: 'Permissions',
    subtitleAr: 'أدوار متدرجة · سجل تدقيق',
    subtitleEn: 'Graded roles · audit log',
    accent: '#0B1F3A',
  },
  {
    id: 'notifications',
    titleAr: 'التنبيهات',
    titleEn: 'Notifications',
    subtitleAr: 'مهام · مواعيد · متابعات',
    subtitleEn: 'Tasks · deadlines · follow-ups',
    accent: '#7C3AED',
  },
];
