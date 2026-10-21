// Made by Dr Ali — Staff bug report queue (Employee + SuperAdmin).

import 'package:flutter/material.dart';

import '../../core/media_url.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import 'admin_api.dart';

class AdminBugReportsScreen extends StatefulWidget {
  const AdminBugReportsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AdminBugReportsScreen> createState() => _AdminBugReportsScreenState();
}

class _AdminBugReportsScreenState extends State<AdminBugReportsScreen> {
  final _api = AdminApi();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      final rows = await _api.listBugReports(token);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _setStatus(String id, String status) async {
    final token = await widget.authController.ensureAccessToken();
    if (token == null) return;
    await _api.updateBugReportStatus(
      accessToken: token,
      reportId: id,
      status: status,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(ar ? 'بلاغات الأعطال' : 'Bug reports'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, textAlign: TextAlign.center))
          : RefreshIndicator(
              onRefresh: _load,
              child: _rows.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.4,
                          child: Center(
                            child: Text(
                              ar ? 'لا توجد بلاغات' : 'No reports yet',
                              style: TextStyle(
                                color: ObicColors.mutedOf(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _rows.length,
                      itemBuilder: (context, i) {
                        final r = _rows[i];
                        final id = r['id'] as String? ?? '';
                        final status = (r['status'] as String?) ?? 'open';
                        final desc = (r['description'] as String?) ?? '';
                        final photos = r['photoUrls'];
                        final urls = photos is List
                            ? photos.whereType<String>().toList()
                            : <String>[];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  desc,
                                  style: TextStyle(
                                    color: ObicColors.inkOf(context),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${ar ? 'الحالة' : 'Status'}: $status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ObicColors.mutedOf(context),
                                  ),
                                ),
                                if (urls.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 72,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: urls.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 6),
                                      itemBuilder: (_, j) {
                                        final url = resolveMediaUrl(urls[j]);
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.network(
                                            url,
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final s in [
                                      'open',
                                      'in_progress',
                                      'resolved',
                                      'dismissed',
                                    ])
                                      ActionChip(
                                        label: Text(s),
                                        backgroundColor: status == s
                                            ? ObicColors.blueSoft
                                            : null,
                                        onPressed: id.isEmpty
                                            ? null
                                            : () => _setStatus(id, s),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
