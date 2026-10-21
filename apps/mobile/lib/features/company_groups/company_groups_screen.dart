// Made by Dr Ali
// A named set of company contacts assigned to this employee. Not a chat group.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyGroupsScreen extends StatefulWidget {
  const CompanyGroupsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyGroupsScreen> createState() => _CompanyGroupsScreenState();
}

class _CompanyGroupsScreenState extends State<CompanyGroupsScreen> {
  final _api = SocialApi();
  final _name = TextEditingController();
  final _note = TextEditingController();
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _contacts = [];
  List<String> _selected = [];
  String? _editingId;
  bool _active = true;
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
    _name.dispose();
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
      final home = await _api.companyContactGroupsHome(token);
      if (!mounted) return;
      setState(() {
        _groups = _maps(home['groups']);
        _contacts = _maps(home['contacts']);
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

  List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  void _clear() {
    setState(() {
      _editingId = null;
      _active = true;
      _selected = [];
    });
    _name.clear();
    _note.clear();
  }

  void _edit(Map<String, dynamic> group) {
    final members = _maps(group['members']);
    setState(() {
      _editingId = group['id']?.toString();
      _active = group['active'] == true;
      _selected = members.map((member) => member['contactId']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    });
    _name.text = group['name']?.toString() ?? '';
    _note.text = group['note']?.toString() ?? '';
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) return;
      final editingId = _editingId;
      if (editingId == null) {
        await _api.createCompanyContactGroup(
          accessToken: token,
          name: name,
          note: _note.text,
          contactIds: _selected,
        );
      } else {
        await _api.updateCompanyContactGroup(
          accessToken: token,
          groupId: editingId,
          name: name,
          note: _note.text,
          active: _active,
          contactIds: _selected,
        );
      }
      _clear();
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
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.companyGroupsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyGroupsHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  maxLength: 40,
                  decoration: InputDecoration(labelText: l10n.companyGroupsName),
                ),
                TextField(
                  controller: _note,
                  maxLength: 200,
                  decoration: InputDecoration(labelText: l10n.companyGroupsNote),
                ),
                for (final contact in _contacts)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(contact['name']?.toString() ?? ''),
                    value: _selected.contains(contact['id']?.toString()),
                    onChanged: (checked) {
                      final id = contact['id']?.toString() ?? '';
                      if (id.isEmpty) return;
                      setState(() {
                        if (checked == true) {
                          if (!_selected.contains(id) && _selected.length < 80) {
                            _selected = [..._selected, id];
                          }
                        } else {
                          _selected = _selected.where((item) => item != id).toList();
                        }
                      });
                    },
                  ),
                if (_editingId != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_active ? l10n.companyGroupsActive : l10n.companyGroupsPaused),
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                  ),
                FilledButton(
                  onPressed: _sending ? null : _save,
                  child: Text(l10n.companyGroupsSave),
                ),
                if (_editingId != null)
                  TextButton(onPressed: _clear, child: Text(l10n.companyGroupsNew)),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyGroupsLoadFailed),
                  ),
                if (_groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyGroupsNone),
                  ),
                for (final group in _groups)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(group['name']?.toString() ?? ''),
                    subtitle: Text(
                      _maps(group['members']).map((member) => member['name']?.toString() ?? '').where((name) => name.isNotEmpty).join(', '),
                    ),
                    onTap: () => _edit(group),
                  ),
              ],
            ),
    );
  }
}
