// Made by Dr Ali
// Internal Ops — modular registry (frontend prototype, no backend).

import 'package:flutter/material.dart';

/// Build helper only: optional demo tooling for Ops screens themselves.
/// Does NOT grant Me-tab visibility — that requires server opsAccess / SuperAdmin.
const bool kOpsPrototype =
    bool.fromEnvironment('OPS_PROTOTYPE', defaultValue: false);

enum OpsModuleId {
  dashboard,
  crm,
  inquiries,
  sales,
  operations,
  suppliers,
  logistics,
  finance,
  hr,
  tasks,
  documents,
  reports,
  kpi,
  permissions,
  notifications,
}

class OpsModuleDef {
  const OpsModuleDef({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.icon,
    required this.color,
  });

  final OpsModuleId id;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final IconData icon;
  final Color color;

  String title(bool ar) => ar ? titleAr : titleEn;
}

/// Independent modules — add a new module here without rewriting the hub.
abstract final class OpsRegistry {
  static const List<OpsModuleDef> modules = [
    OpsModuleDef(
      id: OpsModuleId.dashboard,
      titleAr: 'لوحة التحكم',
      titleEn: 'Dashboard',
      subtitleAr: 'نظرة شاملة على الشركة',
      icon: Icons.dashboard_customize_outlined,
      color: Color(0xFF1A6DFF),
    ),
    OpsModuleDef(
      id: OpsModuleId.crm,
      titleAr: 'إدارة العملاء CRM',
      titleEn: 'CRM',
      subtitleAr: 'ملفات العملاء · المصادر · المتابعة',
      icon: Icons.people_alt_outlined,
      color: Color(0xFF0EA5E9),
    ),
    OpsModuleDef(
      id: OpsModuleId.inquiries,
      titleAr: 'الاستفسارات والطلبات',
      titleEn: 'Inquiries',
      subtitleAr: 'رقم مرجعي · مراحل · Workflow',
      icon: Icons.confirmation_number_outlined,
      color: Color(0xFF8B5CF6),
    ),
    OpsModuleDef(
      id: OpsModuleId.sales,
      titleAr: 'المبيعات',
      titleEn: 'Sales',
      subtitleAr: 'Leads · عروض · عقود · صفقات',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF10B981),
    ),
    OpsModuleDef(
      id: OpsModuleId.operations,
      titleAr: 'الخدمات والعمليات',
      titleEn: 'Operations',
      subtitleAr: 'Workflow لكل خدمة',
      icon: Icons.account_tree_outlined,
      color: Color(0xFFF59E0B),
    ),
    OpsModuleDef(
      id: OpsModuleId.suppliers,
      titleAr: 'المصانع والموردين',
      titleEn: 'Suppliers',
      subtitleAr: 'مصانع · ماركات · تقييم',
      icon: Icons.factory_outlined,
      color: Color(0xFF64748B),
    ),
    OpsModuleDef(
      id: OpsModuleId.logistics,
      titleAr: 'الشحن واللوجستيات',
      titleEn: 'Logistics',
      subtitleAr: 'شحنات · تتبع · مستندات',
      icon: Icons.local_shipping_outlined,
      color: Color(0xFF0284C7),
    ),
    OpsModuleDef(
      id: OpsModuleId.finance,
      titleAr: 'المالية والمحاسبة',
      titleEn: 'Finance',
      subtitleAr: 'إيرادات · مصروفات · فواتير',
      icon: Icons.account_balance_outlined,
      color: Color(0xFF059669),
    ),
    OpsModuleDef(
      id: OpsModuleId.hr,
      titleAr: 'الموارد البشرية',
      titleEn: 'HR',
      subtitleAr: 'موظفون · أقسام · إجازات',
      icon: Icons.badge_outlined,
      color: Color(0xFFDB2777),
    ),
    OpsModuleDef(
      id: OpsModuleId.tasks,
      titleAr: 'المهام وسير العمل',
      titleEn: 'Tasks',
      subtitleAr: 'مهام · أولويات · تأخيرات',
      icon: Icons.task_alt_outlined,
      color: Color(0xFFEA580C),
    ),
    OpsModuleDef(
      id: OpsModuleId.documents,
      titleAr: 'المستندات والأرشفة',
      titleEn: 'Documents',
      subtitleAr: 'ملفات مربوطة بالجهة',
      icon: Icons.folder_open_outlined,
      color: Color(0xFF475569),
    ),
    OpsModuleDef(
      id: OpsModuleId.reports,
      titleAr: 'التقارير',
      titleEn: 'Reports',
      subtitleAr: 'يومي · شهري · سنوي · تصدير',
      icon: Icons.bar_chart_rounded,
      color: Color(0xFF4F46E5),
    ),
    OpsModuleDef(
      id: OpsModuleId.kpi,
      titleAr: 'مؤشرات الأداء KPI',
      titleEn: 'KPI',
      subtitleAr: 'أداء الموظفين والأقسام',
      icon: Icons.speed_outlined,
      color: Color(0xFFDC2626),
    ),
    OpsModuleDef(
      id: OpsModuleId.permissions,
      titleAr: 'الصلاحيات والأمان',
      titleEn: 'Permissions',
      subtitleAr: 'أدوار متدرجة · سجل تدقيق',
      icon: Icons.security_outlined,
      color: Color(0xFF0B1F3A),
    ),
    OpsModuleDef(
      id: OpsModuleId.notifications,
      titleAr: 'التنبيهات',
      titleEn: 'Notifications',
      subtitleAr: 'مهام · مواعيد · متابعات',
      icon: Icons.notifications_active_outlined,
      color: Color(0xFF7C3AED),
    ),
  ];

  static OpsModuleDef byId(OpsModuleId id) =>
      modules.firstWhere((m) => m.id == id);
}
