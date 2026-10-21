// Made by Dr Ali
// Staff reports for the current day, week, and month.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = SocialApi();
  final _done = TextEditingController();
  final _plan = TextEditingController();
  final _blockers = TextEditingController();
  Map<String, dynamic>? _home;
  String? _kind;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _done.dispose();
    _plan.dispose();
    _blockers.dispose();
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
      final home = await _api.reportsHome(token);
      if (!mounted) return;
      setState(() {
        _home = home;
        _loading = false;
      });
      _fill(_kind);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'failed';
      });
    }
  }

  List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Map<String, dynamic>? _period(String kind) {
    for (final row in _maps(_home?['periods'])) {
      if (row['kind'] == kind) return row;
    }
    return null;
  }

  void _fill(String? kind) {
    final period = kind == null ? null : _period(kind);
    final report = period?['report'];
    final row = report is Map ? Map<String, dynamic>.from(report) : null;
    _done.text = row?['done']?.toString() ?? '';
    _plan.text = row?['plan']?.toString() ?? '';
    _blockers.text = row?['blockers']?.toString() ?? '';
  }

  Future<void> _send() async {
    final kind = _kind;
    if (kind == null || _sending) return;
    final done = _done.text.trim();
    final plan = _plan.text.trim();
    if (done.isEmpty || plan.isEmpty) return;
    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      await _api.submitReport(
        accessToken: token,
        kind: kind,
        done: done,
        plan: plan,
        blockers: _blockers.text.trim(),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final periods = _maps(_home?['periods']);
    final inbox = _maps(_home?['inbox']);
    final mine = _maps(_home?['mine']);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.reportsLoadFailed),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: Text(l10n.reportsTitle)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(l10n.reportsHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                    const SizedBox(height: 12),
                    for (final row in periods)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_kindLabel(l10n, row['kind']?.toString())),
                        subtitle: Text(row['periodKey']?.toString() ?? ''),
                        trailing: Text(
                          row['report'] == null ? l10n.reportsMissing : l10n.reportsSent,
                        ),
                        onTap: () {
                          final kind = row['kind']?.toString();
                          setState(() => _kind = kind);
                          _fill(kind);
                        },
                      ),
                    if (_kind != null) ...[
                      const SizedBox(height: 8),
                      Text(_kindLabel(l10n, _kind), style: Theme.of(context).textTheme.titleMedium),
                      TextField(
                        controller: _done,
                        maxLength: 2000,
                        minLines: 2,
                        maxLines: 6,
                        decoration: InputDecoration(labelText: l10n.reportsDone),
                      ),
                      TextField(
                        controller: _plan,
                        maxLength: 2000,
                        minLines: 2,
                        maxLines: 6,
                        decoration: InputDecoration(labelText: l10n.reportsPlan),
                      ),
                      TextField(
                        controller: _blockers,
                        maxLength: 1000,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(labelText: l10n.reportsBlockers),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _sending ? null : _send,
                        child: Text(l10n.reportsSend),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(l10n.reportsInbox, style: Theme.of(context).textTheme.titleMedium),
                    if (inbox.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(l10n.reportsNone, style: TextStyle(color: ObicColors.mutedOf(context))),
                      ),
                    for (final row in inbox) _card(l10n, row, showAuthor: true),
                    const SizedBox(height: 16),
                    Text(l10n.reportsMine, style: Theme.of(context).textTheme.titleMedium),
                    if (mine.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(l10n.reportsNone, style: TextStyle(color: ObicColors.mutedOf(context))),
                      ),
                    for (final row in mine) _card(l10n, row, showAuthor: false),
                  ],
                ),
    );
  }

  Widget _card(AppLocalizations l10n, Map<String, dynamic> row, {required bool showAuthor}) {
    final title = showAuthor
        ? '${row['authorName'] ?? ''} · ${_kindLabel(l10n, row['kind']?.toString())}'
        : _kindLabel(l10n, row['kind']?.toString());
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$title · ${row['periodKey'] ?? ''}'),
      subtitle: Text(row['done']?.toString() ?? ''),
    );
  }

  String _kindLabel(AppLocalizations l10n, String? kind) {
    switch (kind) {
      case 'daily':
        return l10n.reportsDaily;
      case 'weekly':
        return l10n.reportsWeekly;
      case 'monthly':
        return l10n.reportsMonthly;
      default:
        return kind ?? '';
    }
  }
}
