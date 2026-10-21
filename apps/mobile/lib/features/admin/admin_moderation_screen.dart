// Made by Dr Ali — SuperAdmin moderation desk (reports + banned words).

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import 'admin_api.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  final _api = AdminApi();
  final _phraseCtrl = TextEditingController();
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _words = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phraseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      final reports = await _api.listModerationReports(token);
      final words = await _api.listBannedWords(token);
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _words = words;
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

  Future<void> _review(String id, String status) async {
    final token = await widget.authController.ensureAccessToken();
    if (token == null) return;
    await _api.reviewModerationReport(
      accessToken: token,
      reportId: id,
      status: status,
    );
    await _load();
  }

  Future<void> _addWord() async {
    final phrase = _phraseCtrl.text.trim();
    if (phrase.isEmpty) return;
    final token = await widget.authController.ensureAccessToken();
    if (token == null) return;
    await _api.addBannedWord(accessToken: token, phrase: phrase);
    _phraseCtrl.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(ar ? 'إشراف المحتوى' : 'Content moderation'),
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    ar ? 'بلاغات المحتوى' : 'Content reports',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ObicColors.titleOf(context),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_reports.isEmpty)
                    Text(
                      ar ? 'لا بلاغات مفتوحة' : 'No open reports',
                      style: TextStyle(color: ObicColors.mutedOf(context)),
                    )
                  else
                    ..._reports.map((r) {
                      final id = r['id'] as String? ?? '';
                      final snippet = r['snippet'] as String? ?? '—';
                      final reason = r['reason'] as String? ?? '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            snippet,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(reason),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: ar ? 'تمت المراجعة' : 'Reviewed',
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: id.isEmpty
                                    ? null
                                    : () => _review(id, 'reviewed'),
                              ),
                              IconButton(
                                tooltip: ar ? 'تجاهل' : 'Dismiss',
                                icon: const Icon(Icons.close),
                                onPressed: id.isEmpty
                                    ? null
                                    : () => _review(id, 'dismissed'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  Text(
                    ar ? 'كلمات محظورة' : 'Banned phrases',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ObicColors.titleOf(context),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phraseCtrl,
                          decoration: InputDecoration(
                            hintText: ar ? 'عبارة جديدة…' : 'New phrase…',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _addWord,
                        child: Text(ar ? 'إضافة' : 'Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._words.map(
                    (w) => ListTile(
                      dense: true,
                      title: Text('${w['phrase'] ?? ''}'),
                      subtitle: Text('${w['category'] ?? ''}'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
