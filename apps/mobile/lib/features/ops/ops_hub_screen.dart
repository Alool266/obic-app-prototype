// Made by Dr Ali
// Internal Ops hub — modular company system prototype (UI only).

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import 'ops_mock_data.dart';
import 'ops_module_screen.dart';
import 'ops_registry.dart';
import 'ops_widgets.dart';

class OpsHubScreen extends StatelessWidget {
  const OpsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = OpsMock.dashboard;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: const Text('النظام الإداري الداخلي'),
        actions: [
          IconButton(
            tooltip: 'البحث (نموذج)',
            onPressed: () {
              showSearch(
                context: context,
                delegate: _OpsSearchDelegate(),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: ListView(
        children: [
          const OpsBanner(text: OpsMock.banner),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B1F3A), Color(0xFF1A6DFF)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OBIC Internal',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'نظام الشركة الداخلي',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'وحدات مستقلة (Modular) · صلاحيات متدرجة · جاهز للنمو والتكاملات',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'تصميم وتطوير: د. علي',
                    style: TextStyle(
                      color: Color(0xFF7DD3FC),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const OpsSectionTitle('ملخص سريع'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OpsStatCard(
                    label: 'استفسارات',
                    value: '${d['inquiries']}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OpsStatCard(
                    label: 'مفتوحة',
                    value: '${d['openOrders']}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OpsStatCard(
                    label: 'أرباح',
                    value: '${d['profit']}'.toString().replaceAll('¥ ', ''),
                    accent: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
          const OpsSectionTitle('الوحدات'),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: OpsRegistry.modules.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, i) {
                final m = OpsRegistry.modules[i];
                return Material(
                  color: ObicColors.card,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => openOpsModule(context, m.id),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ObicColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: m.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(m.icon, color: m.color),
                          ),
                          const Spacer(),
                          Text(
                            m.titleAr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              height: 1.25,
                              color: ObicColors.titleOf(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.subtitleAr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ObicColors.mutedOf(context),
                              fontSize: 11,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const OpsSectionTitle('تكاملات مستقبلية'),
          ...OpsMock.integrations.map(
            (x) => OpsListCard(
              title: x,
              leading: const Icon(Icons.link, color: ObicColors.blue),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OpsSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'ابحث: عميل · طلب · شحنة · مصنع…';

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, ''),
        icon: const Icon(Icons.arrow_back),
      );

  @override
  Widget buildResults(BuildContext context) => _results();

  @override
  Widget buildSuggestions(BuildContext context) => _results();

  Widget _results() {
    final q = query.trim();
    final hits = <Map<String, String>>[];
    for (final c in OpsMock.customers) {
      final hay = '${c['name']} ${c['id']} ${c['phone']}';
      if (q.isEmpty || hay.contains(q)) {
        hits.add({
          'type': 'عميل',
          'title': c['name'] as String,
          'sub': c['id'] as String,
        });
      }
    }
    for (final r in OpsMock.inquiries) {
      final hay = '${r['ref']} ${r['customer']} ${r['what']}';
      if (q.isEmpty || hay.contains(q)) {
        hits.add({
          'type': 'طلب',
          'title': r['ref'] as String,
          'sub': r['customer'] as String,
        });
      }
    }
    for (final s in OpsMock.shipments) {
      final hay = '${s['id']} ${s['tracking']} ${s['customer']}';
      if (q.isEmpty || hay.contains(q)) {
        hits.add({
          'type': 'شحنة',
          'title': s['id']!,
          'sub': s['tracking']!,
        });
      }
    }
    for (final s in OpsMock.suppliers) {
      final hay = '${s['name']} ${s['brands']}';
      if (q.isEmpty || hay.contains(q)) {
        hits.add({
          'type': 'مورد',
          'title': s['name'] as String,
          'sub': s['brands'] as String,
        });
      }
    }
    if (hits.isEmpty) {
      return const Center(child: Text('لا نتائج في النموذج التجريبي'));
    }
    return ListView.builder(
      itemCount: hits.length,
      itemBuilder: (_, i) {
        final h = hits[i];
        return ListTile(
          leading: OpsPill(h['type']!),
          title: Text(h['title']!),
          subtitle: Text(h['sub']!),
        );
      },
    );
  }
}
