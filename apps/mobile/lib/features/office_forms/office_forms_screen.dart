// Made by Dr Ali
// Staff fill a company form. Customers never open this screen.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class OfficeFormsScreen extends StatefulWidget {
  const OfficeFormsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<OfficeFormsScreen> createState() => _OfficeFormsScreenState();
}

class _OfficeFormsScreenState extends State<OfficeFormsScreen> {
  final _api = SocialApi();
  Map<String, dynamic>? _home;
  String? _formId;
  final Map<String, String> _answers = {};
  bool _loading = true;
  bool _sending = false;
  int _edit = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final home = await _api.officeFormsHome(token);
      if (!mounted) return;
      setState(() {
        _home = home;
        _loading = false;
        final forms = _maps(home['forms']);
        _formId ??= forms.isEmpty ? null : forms.first['id']?.toString();
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

  Map<String, dynamic>? get _form {
    for (final row in _maps(_home?['forms'])) {
      if (row['id']?.toString() == _formId) return row;
    }
    return null;
  }

  Future<void> _send() async {
    final form = _form;
    final formId = _formId;
    if (form == null || formId == null || _sending) return;
    final fields = _maps(form['fields']);
    final answers = <String, String>{};
    for (final field in fields) {
      final key = field['key']?.toString() ?? '';
      final text = (_answers[key] ?? '').trim();
      if (field['required'] == true && text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).formsFillRequired)),
        );
        return;
      }
      answers[key] = text;
    }
    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      await _api.submitOfficeForm(accessToken: token, formId: formId, answers: answers);
      _answers.clear();
      if (mounted) setState(() => _edit += 1);
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
    final lang = Localizations.localeOf(context).languageCode;
    final forms = _maps(_home?['forms']);
    final mine = _maps(_home?['submissions']);
    final form = _form;
    final fields = _maps(form?['fields']);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.formsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.formsLoadFailed),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: Text(l10n.formsTitle)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(l10n.formsHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                    const SizedBox(height: 12),
                    if (forms.isEmpty)
                      Text(l10n.formsNone, style: TextStyle(color: ObicColors.mutedOf(context)))
                    else ...[
                      DropdownButtonFormField<String>(
                        initialValue: _formId,
                        decoration: InputDecoration(labelText: l10n.formsTitle),
                        items: [
                          for (final row in forms)
                            DropdownMenuItem(
                              value: row['id']?.toString(),
                              child: Text(_name(row, lang)),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _formId = value;
                            _answers.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      for (final field in fields) _field(lang, field),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _sending ? null : _send,
                        child: Text(l10n.formsSend),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(l10n.formsMine, style: Theme.of(context).textTheme.titleMedium),
                    if (mine.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(l10n.formsNone, style: TextStyle(color: ObicColors.mutedOf(context))),
                      ),
                    for (final row in mine)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_name(row, lang, submission: true)),
                        subtitle: Text(_summary(row, lang)),
                      ),
                  ],
                ),
    );
  }

  Widget _field(String lang, Map<String, dynamic> field) {
    final key = field['key']?.toString() ?? '';
    final label = _label(field, lang);
    final required = field['required'] == true;
    final title = required ? '$label *' : label;
    final widgetKey = ValueKey('$_edit-$key');
    if (field['type'] == 'choice') {
      final raw = field['options'];
      final choices = raw is List ? raw.map((item) => item.toString()).toList() : <String>[];
      final current = _answers[key];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DropdownButtonFormField<String>(
          key: widgetKey,
          initialValue: choices.contains(current) ? current : null,
          decoration: InputDecoration(labelText: title),
          items: [
            for (final option in choices)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (value) => setState(() => _answers[key] = value ?? ''),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        key: widgetKey,
        initialValue: _answers[key] ?? '',
        keyboardType: field['type'] == 'number' ? TextInputType.number : TextInputType.text,
        textDirection: field['type'] == 'number' ? TextDirection.ltr : null,
        textAlign: field['type'] == 'number' ? TextAlign.left : TextAlign.start,
        minLines: field['type'] == 'long_text' ? 3 : 1,
        maxLines: field['type'] == 'long_text' ? 6 : 1,
        decoration: InputDecoration(labelText: title),
        onChanged: (value) => _answers[key] = value,
      ),
    );
  }

  String _name(Map<String, dynamic> row, String lang, {bool submission = false}) {
    final en = submission ? row['formNameEn'] : row['nameEn'];
    final ar = submission ? row['formNameAr'] : row['nameAr'];
    final zh = submission ? row['formNameZh'] : row['nameZh'];
    if (lang == 'ar') return ar?.toString() ?? '';
    if (lang == 'zh') return zh?.toString() ?? '';
    return en?.toString() ?? '';
  }

  String _label(Map<String, dynamic> field, String lang) {
    if (lang == 'ar') return field['labelAr']?.toString() ?? '';
    if (lang == 'zh') return field['labelZh']?.toString() ?? '';
    return field['labelEn']?.toString() ?? '';
  }

  String _summary(Map<String, dynamic> row, String lang) {
    final fields = _maps(row['fields']);
    final answers = row['answers'];
    final map = answers is Map ? Map<String, dynamic>.from(answers) : <String, dynamic>{};
    return fields
        .map((field) {
          final key = field['key']?.toString() ?? '';
          final value = map[key]?.toString() ?? '';
          if (value.isEmpty) return '';
          return '${_label(field, lang)}: $value';
        })
        .where((line) => line.isNotEmpty)
        .join(' · ');
  }
}
