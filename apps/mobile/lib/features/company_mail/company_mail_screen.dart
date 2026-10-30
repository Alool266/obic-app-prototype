// Made by Dr Ali
// Company mail between staff. A message stays inside OBIC.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyMailScreen extends StatefulWidget {
  const CompanyMailScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyMailScreen> createState() => _CompanyMailScreenState();
}

class _CompanyMailScreenState extends State<CompanyMailScreen> {
  final _api = SocialApi();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  List<Map<String, dynamic>> _people = [];
  List<Map<String, dynamic>> _inbox = [];
  List<Map<String, dynamic>> _sent = [];
  final Set<String> _selected = {};
  String? _openId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
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
      final home = await _api.companyMailHome(token);
      if (!mounted) return;
      setState(() {
        _people = _maps(home['people']);
        _inbox = _maps(home['inbox']);
        _sent = _maps(home['sent']);
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

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < 12) {
        _selected.add(id);
      }
    });
  }

  Future<void> _send() async {
    final subject = _subject.text.trim();
    final body = _body.text.trim();
    if (subject.isEmpty || body.isEmpty || _selected.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      await _api.sendCompanyMail(
        accessToken: token,
        subject: subject,
        body: body,
        userIds: _selected.toList(),
      );
      if (!mounted) return;
      _subject.clear();
      _body.clear();
      _selected.clear();
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'failed';
      });
    }
  }

  Future<void> _open(Map<String, dynamic> row) async {
    final id = row['id']?.toString() ?? '';
    setState(() => _openId = _openId == id ? null : id);
    if (row['read'] == true || id.isEmpty) return;
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) return;
      await _api.markCompanyMailRead(accessToken: token, messageId: id);
      if (!mounted) return;
      setState(() {
        row['read'] = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'failed');
    }
  }

  List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  String _names(Object? value) {
    if (value is! List) return '';
    return value.map((item) => item?.toString() ?? '').where((name) => name.isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.companyMailTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyMailHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyMailLoadFailed),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subject,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l10n.companyMailSubject),
                ),
                TextField(
                  controller: _body,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: InputDecoration(labelText: l10n.companyMailBody),
                ),
                Text(l10n.companyMailTo),
                for (final person in _people)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(person['name']?.toString() ?? ''),
                    value: _selected.contains(person['userId']?.toString() ?? ''),
                    onChanged: (_) => _toggle(person['userId']?.toString() ?? ''),
                  ),
                FilledButton(
                  onPressed: _saving ? null : _send,
                  child: Text(l10n.companyMailSend),
                ),
                const SizedBox(height: 16),
                Text(l10n.companyMailInbox, style: Theme.of(context).textTheme.titleMedium),
                if (_inbox.isEmpty) Text(l10n.companyMailNone),
                for (final row in _inbox)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row['subject']?.toString() ?? ''),
                    subtitle: Text(
                      '${row['senderName'] ?? ''}${_openId == row['id']?.toString() ? '\n${row['body'] ?? ''}' : ''}',
                    ),
                    trailing: row['read'] == true ? null : const Icon(Icons.mark_email_unread_outlined),
                    onTap: () => _open(row),
                  ),
                const SizedBox(height: 8),
                Text(l10n.companyMailOutbox, style: Theme.of(context).textTheme.titleMedium),
                if (_sent.isEmpty) Text(l10n.companyMailNone),
                for (final row in _sent)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row['subject']?.toString() ?? ''),
                    subtitle: Text(_names(row['recipientNames'])),
                  ),
              ],
            ),
    );
  }
}
