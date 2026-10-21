// Made by Dr Ali
// Company calendar. Times are China time. The app does not send an invitation.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyCalendarScreen extends StatefulWidget {
  const CompanyCalendarScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyCalendarScreen> createState() => _CompanyCalendarScreenState();
}

class _CompanyCalendarScreenState extends State<CompanyCalendarScreen> {
  final _api = SocialApi();
  final _title = TextEditingController();
  final _date = TextEditingController();
  final _start = TextEditingController(text: '09:00');
  final _end = TextEditingController(text: '10:00');
  final _note = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  String? _editingId;
  bool _active = true;
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
    _title.dispose();
    _date.dispose();
    _start.dispose();
    _end.dispose();
    _note.dispose();
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
      final home = await _api.companyCalendarHome(token);
      if (!mounted) return;
      setState(() {
        _rows = _maps(home['rows']);
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

  void _clear() {
    setState(() {
      _editingId = null;
      _active = true;
    });
    _title.clear();
    _date.clear();
    _start.text = '09:00';
    _end.text = '10:00';
    _note.clear();
  }

  void _edit(Map<String, dynamic> row) {
    setState(() {
      _editingId = row['id']?.toString();
      _active = row['active'] != false;
    });
    _title.text = row['title']?.toString() ?? '';
    _date.text = row['date']?.toString() ?? '';
    _start.text = row['start']?.toString() ?? '09:00';
    _end.text = row['end']?.toString() ?? '10:00';
    _note.text = row['note']?.toString() ?? '';
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final date = _date.text.trim();
    final start = _start.text.trim();
    final end = _end.text.trim();
    if (title.isEmpty || date.isEmpty || start.isEmpty || end.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final editingId = _editingId;
      if (editingId == null) {
        await _api.createCompanyCalendarEvent(
          accessToken: token,
          title: title,
          date: date,
          start: start,
          end: end,
          note: _note.text.trim(),
        );
      } else {
        await _api.updateCompanyCalendarEvent(
          accessToken: token,
          eventId: editingId,
          title: title,
          date: date,
          start: start,
          end: end,
          note: _note.text.trim(),
          active: _active,
        );
      }
      if (!mounted) return;
      _clear();
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'failed';
      });
    }
  }

  List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.companyCalendarTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyCalendarHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyCalendarLoadFailed),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _title,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l10n.companyCalendarName),
                ),
                TextField(
                  controller: _date,
                  decoration: InputDecoration(labelText: l10n.companyCalendarDate, hintText: '2026-10-05'),
                ),
                TextField(
                  controller: _start,
                  decoration: InputDecoration(labelText: l10n.companyCalendarStart, hintText: '09:00'),
                ),
                TextField(
                  controller: _end,
                  decoration: InputDecoration(labelText: l10n.companyCalendarEnd, hintText: '10:00'),
                ),
                TextField(
                  controller: _note,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l10n.companyCalendarNote),
                ),
                if (_editingId != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_active ? l10n.companyCalendarActive : l10n.companyCalendarPaused),
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.companyCalendarSave),
                ),
                if (_editingId != null)
                  TextButton(onPressed: _clear, child: Text(l10n.companyCalendarNew)),
                if (_rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyCalendarNone),
                  ),
                for (final row in _rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row['title']?.toString() ?? ''),
                    subtitle: Text(
                      '${row['date'] ?? ''}  ${row['start'] ?? ''}–${row['end'] ?? ''}'
                      '${row['creatorName'] != null ? '\n${row['creatorName']}' : ''}'
                      '${row['active'] == false ? '\n${l10n.companyCalendarPaused}' : ''}',
                    ),
                    onTap: row['mine'] == true ? () => _edit(row) : null,
                  ),
              ],
            ),
    );
  }
}
