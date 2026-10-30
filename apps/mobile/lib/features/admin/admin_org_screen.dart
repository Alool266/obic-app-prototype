// Made by Dr Ali
// Form2 org chart for Admin — branches, owners, roster, locked workflow rules.

import 'package:flutter/material.dart';

import '../../core/obic_org.dart';
import '../../theme/obic_colors.dart';

class AdminOrgScreen extends StatefulWidget {
  const AdminOrgScreen({super.key});

  @override
  State<AdminOrgScreen> createState() => _AdminOrgScreenState();
}

class _AdminOrgScreenState extends State<AdminOrgScreen> {
  String _branchFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final ar = Directionality.of(context) == TextDirection.rtl;
    final lang = Localizations.localeOf(context).languageCode;
    final staff = _branchFilter == 'all'
        ? kObicOrgStaff
        : kObicOrgStaff.where((s) => s.branchId == _branchFilter).toList();

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(ar ? 'هيكل OBIC (Form2)' : 'OBIC org (Form2)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: ObicColors.blueSoft,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                ar
                    ? 'الأسماء والمسميات من Form2 جاهزة للعرض · الحسابات الحقيقية بعد وصول الموبايل والبريد من البوس.'
                    : 'Form2 names & titles ready to display · live accounts after mobiles and emails from the boss.',
                style: TextStyle(
                  color: ObicColors.titleOf(context),
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            ar ? 'الفروع (7)' : 'Branches (7)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: ObicColors.titleOf(context),
            ),
          ),
          const SizedBox(height: 10),
          ...kObicOrgBranches.map((b) {
            final name = lang.startsWith('ar')
                ? b.nameAr
                : lang.startsWith('zh')
                ? b.nameZh
                : b.nameEn;
            return Card(
              elevation: 0,
              color: b.isPrimary ? ObicColors.blueSoft : ObicColors.card,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: b.isPrimary ? ObicColors.blue : ObicColors.line,
                ),
              ),
              child: ListTile(
                title: Text(
                  b.isPrimary
                      ? (ar ? '$name · رئيسي' : '$name · Primary')
                      : name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(b.managerAr),
                trailing: Text(
                  b.id,
                  style: TextStyle(
                    fontSize: 12,
                    color: ObicColors.mutedOf(context),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            ar ? 'مسؤولو الخدمات' : 'Service owners',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: ObicColors.titleOf(context),
            ),
          ),
          const SizedBox(height: 10),
          ...kObicServiceOwners
              .where((o) => o.serviceKey != 'travel_flights')
              .map((o) {
                final label = ar
                    ? o.labelAr
                    : (o.labelEn.isEmpty ? o.serviceKey : o.labelEn);
                final branch = branchDisplayName(o.branchId, lang);
                final notes = o.notesAr.isEmpty ? '' : '\n${o.notesAr}';
                return Card(
                  elevation: 0,
                  color: ObicColors.card,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: ObicColors.line),
                  ),
                  child: ListTile(
                    title: Text(label),
                    subtitle: Text(
                      '${o.primaryStaff} · $branch$notes',
                      style: const TextStyle(height: 1.35),
                    ),
                  ),
                );
              }),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  ar
                      ? 'قائمة الموظفين (${staff.length})'
                      : 'Staff roster (${staff.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ObicColors.titleOf(context),
                  ),
                ),
              ),
              DropdownButton<String>(
                value: _branchFilter,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(ar ? 'كل الفروع' : 'All branches'),
                  ),
                  ...kObicOrgBranches.map(
                    (b) => DropdownMenuItem(
                      value: b.id,
                      child: Text(ar ? b.nameAr : b.nameEn),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _branchFilter = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...staff.map((s) {
            final title = ar ? s.titleAr : s.titleEn;
            final branch = branchDisplayName(s.branchId, lang);
            final section = s.sectionAr.isEmpty ? '' : ' · ${s.sectionAr}';
            return Card(
              elevation: 0,
              color: ObicColors.card,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: ObicColors.line),
              ),
              child: ListTile(
                title: Text(s.name),
                subtitle: Text('$title · $branch$section'),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            ar
                ? 'قواعد سير العمل (مقفلة · $kForm2WorkflowLockedAt)'
                : 'Workflow rules (locked · $kForm2WorkflowLockedAt)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: ObicColors.titleOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ar
                ? 'إجابات الإدارة 19 سبتمبر 2026 — مفعّلة في النظام. الجوالات والبريد الحقيقيان يُدخلان لاحقاً من Admin.'
                : 'Management answers 19 Sep 2026 — live in the system. Production mobiles/emails come later via Admin.',
            style: TextStyle(color: ObicColors.mutedOf(context), fontSize: 13),
          ),
          const SizedBox(height: 10),
          ...kObicWorkflowRules.map((q) {
            return Card(
              elevation: 0,
              color: ObicColors.card,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: ObicColors.line),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFDCFCE7),
                  foregroundColor: const Color(0xFF166534),
                  child: Text('${q.id}'),
                ),
                title: Text(ar ? q.questionAr : q.questionEn),
                subtitle: Text(
                  ar ? q.answerAr : q.answerEn,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
