// Made by Dr Ali
// Staff approvals: send a request, then the approvers answer in order.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final _api = SocialApi();
  final _title = TextEditingController();
  final _body = TextEditingController();
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _requests = [];
  String? _templateId;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  bool _composing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final results = await Future.wait([
        _api.listApprovalTemplates(token),
        _api.listApprovals(token),
      ]);
      if (!mounted) return;
      final templates = results[0].where((row) => row['active'] == true).toList();
      setState(() {
        _templates = templates;
        _requests = results[1];
        _templateId ??= templates.isEmpty ? null : templates.first['id']?.toString();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'failed';
      });
    }
  }

  String _templateName(Map<String, dynamic> row, String lang) {
    String? pick(String key) {
      final value = row[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return null;
    }

    if (lang == 'ar') return pick('nameAr') ?? pick('templateNameAr') ?? pick('nameEn') ?? '';
    if (lang == 'zh') return pick('nameZh') ?? pick('templateNameZh') ?? pick('nameEn') ?? '';
    return pick('nameEn') ?? pick('templateNameEn') ?? '';
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'approved':
        return l10n.approvalApproved;
      case 'rejected':
        return l10n.approvalRejected;
      case 'cancelled':
        return l10n.approvalCancelled;
      case 'pending':
      case 'waiting':
        return l10n.approvalPending;
      default:
        return status;
    }
  }

  Future<void> _send() async {
    final templateId = _templateId;
    final title = _title.text.trim();
    if (templateId == null || title.length < 2 || _sending) return;
    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await _api.openApproval(
        accessToken: token,
        templateId: templateId,
        title: title,
        body: _body.text.trim(),
      );
      _title.clear();
      _body.clear();
      if (mounted) setState(() => _composing = false);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _decide(String id, String decision) async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await _api.decideApproval(
        accessToken: token,
        requestId: id,
        decision: decision,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _cancel(String id) async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await _api.cancelApproval(accessToken: token, requestId: id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final waiting = _requests.where((row) => row['canDecide'] == true).toList();
    final rest = _requests.where((row) => row['canDecide'] != true).toList();
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.approvalsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _templates.isEmpty ? null : () => setState(() => _composing = !_composing),
        icon: const Icon(Icons.add),
        label: Text(l10n.approvalsNew),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.approvalsLoadFailed),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: Text(l10n.approvalsTitle)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    Text(l10n.approvalsHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                    if (_composing) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _templateId,
                        decoration: InputDecoration(labelText: l10n.approvalsTemplate),
                        items: [
                          for (final row in _templates)
                            DropdownMenuItem(
                              value: row['id']?.toString(),
                              child: Text(_templateName(row, lang)),
                            ),
                        ],
                        onChanged: (value) => setState(() => _templateId = value),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _title,
                        decoration: InputDecoration(labelText: l10n.approvalsTitleField),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _body,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(labelText: l10n.approvalsDetails),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _sending ? null : _send,
                        child: Text(l10n.approvalsSend),
                      ),
                    ],
                    _section(l10n, l10n.approvalsWaiting, waiting, lang),
                    _section(l10n, l10n.approvalsTitle, rest, lang),
                    if (waiting.isEmpty && rest.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(l10n.approvalsEmpty),
                      ),
                  ],
                ),
    );
  }

  Widget _section(
    AppLocalizations l10n,
    String title,
    List<Map<String, dynamic>> rows,
    String lang,
  ) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        for (final row in rows) _card(l10n, row, lang),
      ],
    );
  }

  Widget _card(AppLocalizations l10n, Map<String, dynamic> row, String lang) {
    final steps = (row['steps'] as List?) ?? const [];
    final id = row['id']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((row['title'] as String?) ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '${_templateName(row, lang)} · ${_statusLabel(l10n, (row['status'] as String?) ?? '')}',
              style: TextStyle(color: ObicColors.mutedOf(context)),
            ),
            if ((row['body'] as String?)?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(row['body'] as String),
              ),
            const SizedBox(height: 6),
            for (final step in steps)
              if (step is Map)
                Text(
                  '${step['approverName'] ?? ''} · ${_statusLabel(l10n, (step['status'] as String?) ?? '')}',
                ),
            if (row['canDecide'] == true)
              Row(
                children: [
                  TextButton(
                    onPressed: () => _decide(id, 'approved'),
                    child: Text(l10n.approvalsApprove),
                  ),
                  TextButton(
                    onPressed: () => _decide(id, 'rejected'),
                    child: Text(l10n.approvalsReject),
                  ),
                ],
              ),
            if (row['canCancel'] == true)
              TextButton(
                onPressed: () => _cancel(id),
                child: Text(l10n.approvalsCancel),
              ),
          ],
        ),
      ),
    );
  }
}
