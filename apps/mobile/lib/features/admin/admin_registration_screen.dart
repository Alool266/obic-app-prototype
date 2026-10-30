// Made by Dr Ali
// In-app staff desk for company registrations (boss W1 + M04): queue,
// document Green/Yellow/Red review with correction/block reasons, state
// moves, assignment, and the passport-reading (OCR) decision queue.
// The AI only reads; every decision here is a human's.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import 'admin_boss_api.dart';
import 'admin_boss_strings.dart';

class AdminRegistrationScreen extends StatefulWidget {
  const AdminRegistrationScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AdminRegistrationScreen> createState() =>
      _AdminRegistrationScreenState();
}

class _AdminRegistrationScreenState extends State<AdminRegistrationScreen> {
  final _api = AdminBossApi();
  List<Map<String, dynamic>> _apps = [];
  List<Map<String, dynamic>> _ocr = [];
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  AdminBossStrings get s =>
      AdminBossStrings(Localizations.localeOf(context).languageCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _token() async {
    final token = await widget.authController.ensureAccessToken();
    if (token == null) throw Exception('session_expired');
    return token;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _token();
      final apps = await _api.registrationApps(token);
      final ocr = await _api.ocrQueue(token);
      Map<String, dynamic>? detail = _detail;
      if (detail != null) {
        detail = await _api.registrationDetail(token, detail['id'] as String);
      }
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _ocr = ocr;
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<String?> _prompt(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _guard(Future<void> Function(String token) fn) async {
    try {
      final token = await _token();
      await fn(token);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Color _colorOf(String color) {
    switch (color) {
      case 'Green':
        return Colors.green;
      case 'Red':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  List<String> _nextAppStatuses(String status) {
    switch (status) {
      case 'SUBMITTED':
        return ['PENDING_DOCUMENTS', 'UNDER_REVIEW', 'CANCELLED'];
      case 'PENDING_DOCUMENTS':
        return ['UNDER_REVIEW', 'NEEDS_CUSTOMER_ACTION', 'CANCELLED'];
      case 'UNDER_REVIEW':
        return ['APPROVED', 'REJECTED', 'NEEDS_CUSTOMER_ACTION', 'CANCELLED'];
      case 'NEEDS_CUSTOMER_ACTION':
        return ['UNDER_REVIEW', 'PENDING_DOCUMENTS', 'CANCELLED'];
      case 'APPROVED':
        return ['IN_PROGRESS', 'CANCELLED'];
      case 'IN_PROGRESS':
        return ['COMPLETED', 'CANCELLED'];
      default:
        return [];
    }
  }

  Widget _detailCard(Map<String, dynamic> app) {
    final docs = app['documents'];
    final events = app['events'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${app['trackingId']} · ${app['city']} · ${app['status']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: Text(s.assign),
                  onPressed: () async {
                    final id = await _prompt(s.assignPrompt);
                    if (id == null || id.isEmpty) return;
                    await _guard(
                      (token) => _api.assignRegistration(
                        token: token,
                        appId: app['id'] as String,
                        employeeId: id,
                      ),
                    );
                  },
                ),
                for (final to in _nextAppStatuses(app['status'] as String))
                  ActionChip(
                    label: Text('→ $to'),
                    onPressed: () => _guard(
                      (token) => _api.transitionRegistration(
                        token: token,
                        appId: app['id'] as String,
                        status: to,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.documents,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (docs is List)
              for (final doc in docs)
                if (doc is Map<String, dynamic>)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 14,
                              color: _colorOf(doc['color'] as String? ?? ''),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${doc['label']} · v${doc['version']} · ${doc['status']}',
                              ),
                            ),
                          ],
                        ),
                        if (doc['reviewNote'] != null)
                          Text('${doc['reviewNote']}'),
                        if (doc['status'] != 'missing')
                          Wrap(
                            spacing: 6,
                            children: [
                              ActionChip(
                                label: Text(s.approve),
                                onPressed: () => _guard(
                                  (token) => _api.reviewDocument(
                                    token: token,
                                    appId: app['id'] as String,
                                    docId: doc['id'] as String,
                                    decision: 'approve',
                                  ),
                                ),
                              ),
                              ActionChip(
                                label: Text(s.correction),
                                onPressed: () async {
                                  final note = await _prompt(s.notePrompt);
                                  if (note == null || note.isEmpty) return;
                                  await _guard(
                                    (token) => _api.reviewDocument(
                                      token: token,
                                      appId: app['id'] as String,
                                      docId: doc['id'] as String,
                                      decision: 'request_correction',
                                      note: note,
                                    ),
                                  );
                                },
                              ),
                              ActionChip(
                                label: Text(s.block),
                                onPressed: () async {
                                  final note = await _prompt(s.notePrompt);
                                  if (note == null || note.isEmpty) return;
                                  await _guard(
                                    (token) => _api.reviewDocument(
                                      token: token,
                                      appId: app['id'] as String,
                                      docId: doc['id'] as String,
                                      decision: 'block',
                                      note: note,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
            const SizedBox(height: 12),
            Text(
              s.timeline,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (events is List)
              for (final e in events.reversed.take(12))
                if (e is Map<String, dynamic>)
                  Text(
                    '• ${e['action']} ${e['fromStatus'] ?? ''}→${e['toStatus'] ?? ''} ${e['note'] ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(s.registrationTitle),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Text(
                  s.ocrQueue,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_ocr.isEmpty) Text(s.none),
                for (final row in _ocr)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row['trackingId'] ?? ''} · ${row['docType']} v${row['docVersion']} · ${row['modelVersion']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (row['comparisons'] is List)
                            for (final cmp in row['comparisons'] as List)
                              if (cmp is Map<String, dynamic>)
                                Text(
                                  '${cmp['field']}: ${cmp['extracted'] ?? '—'} | ${cmp['typed'] ?? '—'} | ${cmp['saved'] ?? '—'} → ${cmp['status']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              ActionChip(
                                label: Text(s.confirmReading),
                                onPressed: () => _guard(
                                  (token) => _api.reviewExtraction(
                                    token: token,
                                    extractionId: row['id'] as String,
                                    decision: 'confirm',
                                  ),
                                ),
                              ),
                              ActionChip(
                                label: Text(s.rejectReading),
                                onPressed: () async {
                                  final note = await _prompt(s.notePrompt);
                                  if (note == null || note.isEmpty) return;
                                  await _guard(
                                    (token) => _api.reviewExtraction(
                                      token: token,
                                      extractionId: row['id'] as String,
                                      decision: 'reject',
                                      note: note,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  s.registrationTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_apps.isEmpty) Text(s.none),
                for (final app in _apps)
                  Card(
                    child: ListTile(
                      title: Text('${app['trackingId']} · ${app['city']}'),
                      subtitle: Text('${app['activity']} — ${app['status']}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        try {
                          final token = await _token();
                          final detail = await _api.registrationDetail(
                            token,
                            app['id'] as String,
                          );
                          if (mounted) setState(() => _detail = detail);
                        } catch (e) {
                          if (mounted) setState(() => _error = e.toString());
                        }
                      },
                    ),
                  ),
                if (_detail != null) ...[
                  const SizedBox(height: 12),
                  _detailCard(_detail!),
                ],
              ],
            ),
    );
  }
}
