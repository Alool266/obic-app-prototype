// Made by Dr Ali
// Staff see the company contacts assigned to them. These are not personal friends.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyContactsScreen extends StatefulWidget {
  const CompanyContactsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyContactsScreen> createState() => _CompanyContactsScreenState();
}

class _CompanyContactsScreenState extends State<CompanyContactsScreen> {
  final _api = SocialApi();
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _org = TextEditingController();
  final _note = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _tags = [];
  Map<String, List<String>> _tagIds = {};
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
    _search.dispose();
    _name.dispose();
    _phone.dispose();
    _org.dispose();
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
      final home = await _api.companyContactsHome(token, query: _search.text);
      final tagsHome = await _api.companyContactTagsHome(token);
      if (!mounted) return;
      final assignments = _maps(tagsHome['assignments']);
      final tagIds = <String, List<String>>{};
      for (final row in assignments) {
        final id = row['contactId']?.toString() ?? '';
        if (id.isEmpty) continue;
        tagIds[id] = _strings(row['tagIds']);
      }
      setState(() {
        _rows = _maps(home['rows']);
        _tags = _maps(tagsHome['tags']);
        _tagIds = tagIds;
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

  List<String> _strings(Object? value) {
    if (value is! List) return [];
    return value.map((item) => item.toString()).toList();
  }

  void _clear() {
    setState(() {
      _editingId = null;
      _active = true;
      _selected = [];
    });
    _name.clear();
    _phone.clear();
    _org.clear();
    _note.clear();
  }

  void _edit(Map<String, dynamic> row) {
    final id = row['id']?.toString();
    setState(() {
      _editingId = id;
      _active = row['active'] == true;
      _selected = List<String>.from(_tagIds[id] ?? const []);
    });
    _name.text = row['name']?.toString() ?? '';
    _phone.text = row['phone']?.toString() ?? '';
    _org.text = row['orgName']?.toString() ?? '';
    _note.text = row['note']?.toString() ?? '';
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) return;
      final editingId = _editingId;
      final selected = List<String>.from(_selected);
      String? contactId = editingId;
      if (editingId == null) {
        final saved = await _api.createCompanyContact(
          accessToken: token,
          name: name,
          phone: _phone.text,
          orgName: _org.text,
          note: _note.text,
        );
        contactId = saved['id']?.toString();
      } else {
        await _api.updateCompanyContact(
          accessToken: token,
          contactId: editingId,
          name: name,
          phone: _phone.text,
          orgName: _org.text,
          note: _note.text,
          active: _active,
        );
      }
      if (contactId != null && contactId.isNotEmpty) {
        await _api.setCompanyContactTags(
          accessToken: token,
          contactId: contactId,
          tagIds: selected,
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

  String _tagLabel(String? contactId) {
    final ids = _tagIds[contactId] ?? const <String>[];
    final names = <String>[];
    for (final id in ids) {
      for (final tag in _tags) {
        if (tag['id']?.toString() != id) continue;
        final name = tag['name']?.toString() ?? '';
        if (name.isNotEmpty) names.add(name);
      }
    }
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.companyContactsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyContactsHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    labelText: l10n.companyContactsSearch,
                    suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.search)),
                  ),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l10n.companyContactsName),
                ),
                TextField(
                  controller: _phone,
                  maxLength: 32,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(labelText: l10n.companyContactsPhone),
                ),
                TextField(
                  controller: _org,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l10n.companyContactsOrg),
                ),
                TextField(
                  controller: _note,
                  maxLength: 500,
                  decoration: InputDecoration(labelText: l10n.companyContactsNote),
                ),
                if (_tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final tag in _tags)
                          if (tag['active'] == true || _selected.contains(tag['id']?.toString()))
                            FilterChip(
                              label: Text(tag['name']?.toString() ?? ''),
                              selected: _selected.contains(tag['id']?.toString()),
                              onSelected: (_) {
                                final id = tag['id']?.toString() ?? '';
                                if (id.isEmpty) return;
                                setState(() {
                                  if (_selected.contains(id)) {
                                    _selected = _selected.where((item) => item != id).toList();
                                  } else if (_selected.length < 8) {
                                    _selected = [..._selected, id];
                                  }
                                });
                              },
                            ),
                      ],
                    ),
                  ),
                if (_editingId != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_active ? l10n.companyContactsActive : l10n.companyContactsPaused),
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                  ),
                FilledButton(
                  onPressed: _sending ? null : _save,
                  child: Text(l10n.companyContactsSave),
                ),
                if (_editingId != null)
                  TextButton(onPressed: _clear, child: Text(l10n.companyContactsNew)),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyContactsLoadFailed),
                  ),
                if (_rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyContactsNone),
                  ),
                for (final row in _rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row['name']?.toString() ?? ''),
                    subtitle: Text(
                      [
                        row['phone']?.toString() ?? '',
                        row['orgName']?.toString() ?? '',
                        _tagLabel(row['id']?.toString()),
                        row['active'] == true ? l10n.companyContactsActive : l10n.companyContactsPaused,
                      ].where((part) => part.isNotEmpty).join(' · '),
                    ),
                    onTap: () => _edit(row),
                  ),
              ],
            ),
    );
  }
}
