// Made by Dr Ali
// Ask a question about shared company documents. The customer catalog is not searched.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyFileAnswersScreen extends StatefulWidget {
  const CompanyFileAnswersScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyFileAnswersScreen> createState() => _CompanyFileAnswersScreenState();
}

class _CompanyFileAnswersScreenState extends State<CompanyFileAnswersScreen> {
  final _api = SocialApi();
  final _question = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
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
    _question.dispose();
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
      final home = await _api.companyFileAnswersHome(token);
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

  Future<void> _ask() async {
    final question = _question.text.trim();
    if (question.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      await _api.askCompanyFiles(accessToken: token, question: question);
      if (!mounted) return;
      _question.clear();
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

  String _sources(Object? value) {
    if (value is! List) return '';
    return value.map((item) => item.toString()).where((item) => item.isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.companyFileAnswersTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyFileAnswersHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyFileAnswersLoadFailed),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _question,
                  maxLength: 300,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l10n.companyFileAnswersQuestion),
                ),
                FilledButton(
                  onPressed: _saving ? null : _ask,
                  child: Text(l10n.companyFileAnswersAsk),
                ),
                if (_rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyFileAnswersNone),
                  ),
                for (final row in _rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row['question']?.toString() ?? ''),
                    subtitle: Text(
                      '${row['answer'] ?? ''}'
                      '\n${row['answeredBy'] == 'ai' ? l10n.companyFileAnswersFromAi : l10n.companyFileAnswersFromDocuments}'
                      '${_sources(row['sources']).isEmpty ? '' : '\n${_sources(row['sources'])}'}',
                    ),
                  ),
              ],
            ),
    );
  }
}
