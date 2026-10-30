// Made by Dr Ali
// Shared company documents. The latest save stays. This is not a drive file.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyDocumentsScreen extends StatefulWidget {
  const CompanyDocumentsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyDocumentsScreen> createState() => _CompanyDocumentsScreenState();
}

class _CompanyDocumentsScreenState extends State<CompanyDocumentsScreen> {
  final _api = SocialApi();
  final _body = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic>? _doc;
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
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _doc = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final home = await _api.companyDocumentsHome(token);
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

  Future<void> _open(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final row = await _api.companyDocument(token, id);
      if (!mounted) return;
      _body.text = row['body']?.toString() ?? '';
      setState(() {
        _doc = row;
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

  Future<void> _save() async {
    final id = _doc?['id']?.toString() ?? '';
    final text = _body.text.trim();
    if (id.isEmpty || text.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final row = await _api.updateCompanyDocument(accessToken: token, documentId: id, body: text);
      if (!mounted) return;
      _body.text = row['body']?.toString() ?? text;
      setState(() {
        _doc = row;
        _saving = false;
      });
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

  String _when(Object? value) {
    final raw = value?.toString() ?? '';
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final doc = _doc;
    final editor = doc?['editorName']?.toString() ?? '';
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(doc?['title']?.toString() ?? l10n.companyDocumentsTitle),
        leading: doc == null
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _load),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyDocumentsHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyDocumentsLoadFailed),
                  ),
                if (doc == null && _rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyDocumentsNone),
                  ),
                if (doc == null)
                  for (final row in _rows)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(row['title']?.toString() ?? ''),
                      subtitle: Text(_when(row['updatedAt'])),
                      onTap: () => _open(row['id']?.toString() ?? ''),
                    ),
                if (doc != null) ...[
                  if (editor.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(l10n.companyDocumentsSavedBy(editor)),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _body,
                    minLines: 8,
                    maxLines: 16,
                    maxLength: 8000,
                    decoration: InputDecoration(labelText: l10n.companyDocumentsBody),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.companyDocumentsSave),
                  ),
                ],
              ],
            ),
    );
  }
}
