// Made by Dr Ali
// Internal Ops module screens — frontend prototype with mock data.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import 'ops_mock_data.dart';
import 'ops_registry.dart';
import 'ops_widgets.dart';

void openOpsModule(BuildContext context, OpsModuleId id) {
  final def = OpsRegistry.byId(id);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OpsModuleScreen(module: def),
    ),
  );
}

class OpsModuleScreen extends StatelessWidget {
  const OpsModuleScreen({super.key, required this.module});
  final OpsModuleDef module;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(module.titleAr),
        backgroundColor: module.color,
      ),
      body: ListView(
        children: [
          const OpsBanner(text: OpsMock.banner),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              module.subtitleAr,
              style: TextStyle(color: ObicColors.mutedOf(context), height: 1.4),
            ),
          ),
          ..._bodyFor(module.id, context),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'تصميم وتطوير: د. علي · وحدة مستقلة (Modular) — جاهزة للربط بالخادم لاحقاً',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: ObicColors.mutedOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _bodyFor(OpsModuleId id, BuildContext context) {
    switch (id) {
      case OpsModuleId.dashboard:
        return _dashboard();
      case OpsModuleId.crm:
        return _crm(context);
      case OpsModuleId.inquiries:
        return _inquiries();
      case OpsModuleId.sales:
        return _sales();
      case OpsModuleId.operations:
        return _operations(context);
      case OpsModuleId.suppliers:
        return _suppliers();
      case OpsModuleId.logistics:
        return _logistics();
      case OpsModuleId.finance:
        return _finance();
      case OpsModuleId.hr:
        return _hr();
      case OpsModuleId.tasks:
        return _tasks();
      case OpsModuleId.documents:
        return _documents();
      case OpsModuleId.reports:
        return _reports();
      case OpsModuleId.kpi:
        return _kpi();
      case OpsModuleId.permissions:
        return _permissions();
      case OpsModuleId.notifications:
        return _notifications();
    }
  }

  List<Widget> _dashboard() {
    final d = OpsMock.dashboard;
    return [
      const OpsSectionTitle('اليوم · نظرة سريعة'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            OpsStatCard(label: 'عملاء جدد اليوم', value: '${d['customersToday']}'),
            OpsStatCard(label: 'استفسارات', value: '${d['inquiries']}'),
            OpsStatCard(label: 'طلبات مفتوحة', value: '${d['openOrders']}'),
            OpsStatCard(label: 'طلبات مكتملة', value: '${d['closedOrders']}'),
            OpsStatCard(label: 'صفقات', value: '${d['deals']}'),
            OpsStatCard(label: 'المبيعات', value: '${d['salesTotal']}'),
            OpsStatCard(label: 'الإيرادات', value: '${d['revenue']}', accent: const Color(0xFF059669)),
            OpsStatCard(label: 'المصروفات', value: '${d['expenses']}', accent: const Color(0xFFDC2626)),
            OpsStatCard(label: 'الأرباح', value: '${d['profit']}', accent: const Color(0xFF0B1F3A)),
            OpsStatCard(label: 'طلبات متأخرة', value: '${d['lateOrders']}', accent: const Color(0xFFEA580C)),
            OpsStatCard(label: 'مهام متأخرة', value: '${d['lateTasks']}', accent: const Color(0xFFEA580C)),
            OpsStatCard(label: 'أكثر خدمة طلباً', value: '${d['topService']}'.split(' · ').first),
          ],
        ),
      ),
      const OpsSectionTitle('العملاء حسب المصدر'),
      ...OpsMock.sources.map(
        (s) => OpsListCard(
          title: s['name']!,
          trailing: OpsPill('${s['count']}'),
        ),
      ),
      OpsListCard(
        title: 'أكثر الأسواق نشاطاً',
        subtitle: '${d['topMarket']}',
      ),
    ];
  }

  List<Widget> _crm(BuildContext context) {
    return [
      const OpsSectionTitle('ملفات العملاء'),
      ...OpsMock.customers.map((c) {
        return OpsListCard(
          title: '${c['name']} · ${c['id']}',
          subtitle:
              '${c['country']} / ${c['city']} · المصدر: ${c['source']}\nالمسؤول: ${c['owner']} · ${c['status']}',
          leading: CircleAvatar(
            backgroundColor: ObicColors.blueSoft,
              child: Text(
              (c['name'] as String).substring(0, 1),
              style: const TextStyle(
                color: ObicColors.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _CrmDetailScreen(customer: c),
              ),
            );
          },
        );
      }),
    ];
  }

  List<Widget> _inquiries() {
    return [
      const OpsSectionTitle('طلبات برقم مرجعي'),
      ...OpsMock.inquiries.map((q) {
        return OpsListCard(
          title: '${q['ref']} · ${q['customer']}',
          subtitle:
              '${q['what']}\nدخل: ${q['when']} · المسؤول: ${q['owner']}\nالمرحلة: ${q['stage']} · التالي: ${q['next']}',
          trailing: OpsPill(
            q['open'] == true ? 'مفتوح' : 'مغلق',
            color: q['open'] == true
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFE2E8F0),
          ),
        );
      }),
    ];
  }

  List<Widget> _sales() {
    return [
      const OpsSectionTitle('مسار المبيعات'),
      ...OpsMock.salesPipeline.map(
        (s) => OpsListCard(
          title: s['stage']!,
          subtitle: 'العدد: ${s['count']} · القيمة: ${s['value']}',
        ),
      ),
      const OpsSectionTitle('المبيعات حسب الموظف'),
      ...OpsMock.salesByStaff.map(
        (s) => OpsListCard(
          title: s['name']!,
          subtitle: 'صفقات: ${s['deals']}',
          trailing: Text(
            s['value']!,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF059669),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _operations(BuildContext context) {
    return [
      const OpsSectionTitle('Workflow الخدمات'),
      ...OpsMock.operations.map((o) {
        final stages = (o['stages'] as List).cast<String>();
        final cur = o['current'] as int;
        return Card(
          elevation: 0,
          color: ObicColors.surfaceOf(context),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: ObicColors.lineOf(context)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${o['service']} · ${o['ref']}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'العميل: ${o['customer']} · المسؤول: ${o['owner']}',
                  style: TextStyle(color: ObicColors.mutedOf(context), fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < stages.length; i++)
                      OpsPill(
                        stages[i],
                        color: i <= cur
                            ? ObicColors.blueSoft
                            : const Color(0xFFF1F5F9),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }

  List<Widget> _suppliers() {
    return [
      const OpsSectionTitle('المصانع والموردون'),
      ...OpsMock.suppliers.map(
        (s) => OpsListCard(
          title: '${s['name']} · ${s['type']}',
          subtitle:
              '${s['products']}\nالتواصل: ${s['contact']}\nالماركة: ${s['brands']} · التقييم: ${s['rating']}\nالمسؤول: ${s['owner']}',
        ),
      ),
    ];
  }

  List<Widget> _logistics() {
    return [
      const OpsSectionTitle('الشحنات'),
      ...OpsMock.shipments.map(
        (s) => OpsListCard(
          title: '${s['id']} · ${s['status']}',
          subtitle:
              'العميل: ${s['customer']} · المورد: ${s['supplier']}\n${s['goods']} · ${s['qty']}\n${s['carrier']} · ${s['tracking']}\nالشحن: ${s['date']} · الوصول المتوقع: ${s['eta']}',
        ),
      ),
    ];
  }

  List<Widget> _finance() {
    final f = OpsMock.finance;
    return [
      const OpsSectionTitle('ملخص مالي'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            OpsStatCard(label: 'الإيرادات', value: f['revenue']!),
            OpsStatCard(label: 'المصروفات', value: f['expenses']!, accent: const Color(0xFFDC2626)),
            OpsStatCard(label: 'فواتير', value: f['invoices']!),
            OpsStatCard(label: 'مستحقات عملاء', value: f['receivables']!),
            OpsStatCard(label: 'مستحقات موردين', value: f['payables']!),
            OpsStatCard(label: 'تشغيلية', value: f['opsCosts']!),
            OpsStatCard(label: 'أرباح / خسائر', value: f['pl']!, accent: const Color(0xFF059669)),
          ],
        ),
      ),
      const OpsListCard(
        title: 'جاهز للتوسع المحاسبي',
        subtitle: 'الوحدة مستقلة — يمكن لاحقاً إضافة قيود يومية ودفاتر كاملة دون إعادة بناء النظام.',
      ),
    ];
  }

  List<Widget> _hr() {
    return [
      const OpsSectionTitle('الموظفون'),
      ...OpsMock.staff.map(
        (s) => OpsListCard(
          title: s['name']!,
          subtitle:
              'القسم: ${s['dept']} · الوظيفة: ${s['title']}\nالمدير المباشر: ${s['manager']} · الصلاحية: ${s['role']}',
        ),
      ),
      const OpsListCard(
        title: 'لاحقاً في نفس الوحدة',
        subtitle: 'حضور وانصراف · إجازات · رواتب ومزايا · تقييم أداء',
      ),
    ];
  }

  List<Widget> _tasks() {
    return [
      const OpsSectionTitle('المهام'),
      ...OpsMock.tasks.map((t) {
        final late = t['late'] == true;
        return OpsListCard(
          title: t['title'] as String,
          subtitle:
              'المسؤول: ${t['owner']} · التسليم: ${t['due']}\nالأولوية: ${t['priority']} · الحالة: ${t['status']}',
          trailing: OpsPill(
            late ? 'متأخرة' : (t['status'] as String),
            color: late
                ? const Color(0xFFFEE2E2)
                : ObicColors.blueSoft,
          ),
        );
      }),
    ];
  }

  List<Widget> _documents() {
    return [
      const OpsSectionTitle('بحث وأرشفة (نموذج)'),
      const OpsListCard(
        title: 'ابحث عن: عميل · طلب · فاتورة · عقد · شحنة · مصنع',
        subtitle: 'البحث الشامل سيُربط بالخادم لاحقاً. المستندات مربوطة بالجهة المناسبة.',
      ),
      ...OpsMock.customers.expand((c) {
        final files = (c['files'] as List).cast<String>();
        return files.map(
          (f) => OpsListCard(
            title: f,
            subtitle: 'مرتبط بـ ${c['name']} · ${c['id']}',
            leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFDC2626)),
          ),
        );
      }),
    ];
  }

  List<Widget> _reports() {
    return [
      const OpsSectionTitle('أنواع التقارير'),
      ...['يومي', 'أسبوعي', 'شهري', 'ربع سنوي', 'سنوي'].map(
        (p) => OpsListCard(
          title: 'تقرير $p',
          subtitle: 'فلترة حسب الموظف · القسم · الخدمة · الدولة · مقارنة الفترات · تصدير',
        ),
      ),
    ];
  }

  List<Widget> _kpi() {
    return [
      const OpsSectionTitle('مؤشرات الأداء KPI'),
      ...OpsMock.kpis.map(
        (k) => OpsListCard(
          title: k['name']!,
          subtitle: 'الهدف: ${k['target']}',
          trailing: Text(
            k['value']!,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: ObicColors.blue,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _permissions() {
    return [
      const OpsSectionTitle('أدوار متدرجة'),
      ...OpsMock.roles.map(
        (r) => OpsListCard(
          title: r['role']!,
          subtitle: r['sees'],
        ),
      ),
      const OpsListCard(
        title: 'سجل التدقيق',
        subtitle: 'من عدّل؟ متى؟ ماذا تغيّر؟ — كل عملية حساسة تُسجَّل على الخادم لاحقاً.',
      ),
    ];
  }

  List<Widget> _notifications() {
    return [
      const OpsSectionTitle('تنبيهات تلقائية (نموذج)'),
      const OpsListCard(
        title: 'مهمة متأخرة: مراجعة مستندات ترخيص أحمد',
        subtitle: 'إدخال البيانات — ييوو',
      ),
      const OpsListCard(
        title: 'موعد متابعة: سارة الحربي — عرض فنادق',
        subtitle: 'اليوم 17:00',
      ),
      const OpsListCard(
        title: 'شحنة DHL998877 — تحديث حالة: في الطريق',
        subtitle: 'اللوجستيات',
      ),
    ];
  }
}

class _CrmDetailScreen extends StatelessWidget {
  const _CrmDetailScreen({required this.customer});
  final Map<String, dynamic> customer;

  @override
  Widget build(BuildContext context) {
    final orders = (customer['orders'] as List).cast<String>();
    final files = (customer['files'] as List).cast<String>();
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(title: Text(customer['name'] as String)),
      body: ListView(
        children: [
          const OpsBanner(text: OpsMock.banner),
          OpsListCard(title: 'المعرّف', subtitle: customer['id'] as String),
          OpsListCard(
            title: 'التواصل',
            subtitle: '${customer['phone']}\n${customer['email']}',
          ),
          OpsListCard(
            title: 'الموقع',
            subtitle: '${customer['country']} · ${customer['city']}',
          ),
          OpsListCard(title: 'المصدر', subtitle: customer['source'] as String),
          OpsListCard(
            title: 'الموظف المسؤول',
            subtitle: customer['owner'] as String,
          ),
          OpsListCard(title: 'الحالة', subtitle: customer['status'] as String),
          OpsListCard(
            title: 'آخر تواصل',
            subtitle: customer['lastContact'] as String,
          ),
          OpsListCard(title: 'ملاحظات', subtitle: customer['notes'] as String),
          OpsListCard(
            title: 'الطلبات السابقة',
            subtitle: orders.isEmpty ? 'لا يوجد' : orders.join(' · '),
          ),
          OpsListCard(
            title: 'المستندات',
            subtitle: files.isEmpty ? 'لا يوجد' : files.join(' · '),
          ),
          OpsListCard(
            title: 'نقل العميل / التاريخ',
            subtitle:
                'يمكن نقل العميل لموظف آخر مع حفظ كامل سجل المتابعات (سيُفعَّل مع الخادم).',
          ),
          OpsListCard(
            title: 'مهام ومواعيد',
            subtitle: 'إضافة متابعة · تذكير · ربط بقناة واتساب / WeChat لاحقاً.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
