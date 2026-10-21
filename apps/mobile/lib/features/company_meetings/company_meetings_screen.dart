// Made by Dr Ali
// Richer meetings. Times are China time. The app does not start a call.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyMeetingsScreen extends StatefulWidget {
  const CompanyMeetingsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyMeetingsScreen> createState() => _CompanyMeetingsScreenState();
}

class _CompanyMeetingsScreenState extends State<CompanyMeetingsScreen> {
  final _api = SocialApi();
  final _title = TextEditingController();
  final _date = TextEditingController();
  final _start = TextEditingController(text: '09:00');
  final _end = TextEditingController(text: '10:00');
  final _agenda = TextEditingController();
  final _notes = TextEditingController();
  List<Map<String, dynamic>> _people = [];
  List<Map<String, dynamic>> _rows = [];
  final Set<String> _selected = {};
  String? _editingId;
  String? _openId;
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
    _agenda.dispose();
    _notes.dispose();
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
      final home = await _api.companyMeetingsHome(token);
      if (!mounted) return;
      setState(() {
        _people = _maps(home['people']);
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
      _selected.clear();
    });
    _title.clear();
    _date.clear();
    _start.text = '09:00';
    _end.text = '10:00';
    _agenda.clear();
    _notes.clear();
  }

  void _edit(Map<String, dynamic> row) {
    setState(() {
      _editingId = row['id']?.toString();
      _active = row['active'] != false;
      _selected
        ..clear()
        ..addAll(_strings(row['userIds']));
    });
    _title.text = row['title']?.toString() ?? '';
    _date.text = row['date']?.toString() ?? '';
    _start.text = row['start']?.toString() ?? '09:00';
    _end.text = row['end']?.toString() ?? '10:00';
    _agenda.text = row['agenda']?.toString() ?? '';
    _notes.text = row['notes']?.toString() ?? '';
  }

  void _toggle(String id) {
    if (id.isEmpty) return;
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < 12) {
        _selected.add(id);
      }
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final date = _date.text.trim();
    final start = _start.text.trim();
    final end = _end.text.trim();
    if (title.isEmpty || date.isEmpty || start.isEmpty || end.isEmpty || _selected.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final editingId = _editingId;
      if (editingId == null) {
        await _api.createCompanyMeeting(
          accessToken: token,
          title: title,
          date: date,
          start: start,
          end: end,
          agenda: _agenda.text.trim(),
          notes: _notes.text.trim(),
          userIds: _selected.toList(),
        );
      } else {
        await _api.updateCompanyMeeting(
          accessToken: token,
          meetingId: editingId,
          title: title,
          date: date,
          start: start,
          end: end,
          agenda: _agenda.text.trim(),
          notes: _notes.text.trim(),
          active: _active,
          userIds: _selected.toList(),
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

  List<String> _strings(Object? value) {
    if (value is! List) return [];
    return value.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
  }

  String _names(Object? value) {
    if (value is! List) return '';
    return value.map((item) => item.toString()).where((item) => item.isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.companyMeetingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyMeetingsHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyMeetingsLoadFailed),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _title,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l10n.companyMeetingsName),
                ),
                TextField(
                  controller: _date,
                  decoration: InputDecoration(labelText: l10n.companyMeetingsDate, hintText: '2026-10-05'),
                ),
                TextField(
                  controller: _start,
                  decoration: InputDecoration(labelText: l10n.companyMeetingsStart, hintText: '09:00'),
                ),
                TextField(
                  controller: _end,
                  decoration: InputDecoration(labelText: l10n.companyMeetingsEnd, hintText: '10:00'),
                ),
                TextField(
                  controller: _agenda,
                  maxLength: 1000,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l10n.companyMeetingsAgenda),
                ),
                TextField(
                  controller: _notes,
                  maxLength: 2000,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: l10n.companyMeetingsNotes),
                ),
                Text(l10n.companyMeetingsTo),
                for (final person in _people)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(person['name']?.toString() ?? ''),
                    value: _selected.contains(person['userId']?.toString() ?? ''),
                    onChanged: (_) => _toggle(person['userId']?.toString() ?? ''),
                  ),
                if (_editingId != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_active ? l10n.companyMeetingsActive : l10n.companyMeetingsPaused),
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.companyMeetingsSave),
                ),
                if (_editingId != null)
                  TextButton(onPressed: _clear, child: Text(l10n.companyMeetingsNew)),
                if (_rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyMeetingsNone),
                  ),
                for (final row in _rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row['title']?.toString() ?? ''),
                    subtitle: Text(
                      '${row['date'] ?? ''}  ${row['start'] ?? ''}–${row['end'] ?? ''}'
                      '\n${_names(row['attendeeNames'])}'
                      '${_openId == row['id']?.toString() ? '\n${row['agenda'] ?? ''}\n${row['notes'] ?? ''}' : ''}'
                      '${row['active'] == false ? '\n${l10n.companyMeetingsPaused}' : ''}',
                    ),
                    onTap: () {
                      if (row['mine'] == true) {
                        _edit(row);
                        return;
                      }
                      setState(() {
                        final id = row['id']?.toString();
                        _openId = _openId == id ? null : id;
                      });
                    },
                  ),
              ],
            ),
    );
  }
}
