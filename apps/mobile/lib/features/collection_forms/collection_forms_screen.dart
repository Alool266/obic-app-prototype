// Made by Dr Ali
// A collection sent to this staff member. One answer row, updated while it is open.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CollectionFormsScreen extends StatefulWidget {
  const CollectionFormsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CollectionFormsScreen> createState() => _CollectionFormsScreenState();
}

class _CollectionFormsScreenState extends State<CollectionFormsScreen> {
  final _api = SocialApi();
  Map<String, dynamic>? _home;
  String? _collectionId;
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
      final home = await _api.collectionFormsHome(token);
      if (!mounted) return;
      final collections = _maps(home['collections']);
      final id = _collectionId ?? (collections.isEmpty ? null : collections.first['id']?.toString());
      setState(() {
        _home = home;
        _loading = false;
        _apply(id, collections);
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

  void _apply(String? id, List<Map<String, dynamic>> collections) {
    _collectionId = id;
    _answers.clear();
    Map<String, dynamic>? collection;
    for (final row in collections) {
      if (row['id']?.toString() == id) collection = row;
    }
    final response = collection?['response'];
    if (response is Map) {
      final answers = response['answers'];
      if (answers is Map) {
        for (final entry in answers.entries) {
          _answers[entry.key.toString()] = entry.value?.toString() ?? '';
        }
      }
    }
    _edit += 1;
  }

  Map<String, dynamic>? get _collection {
    for (final row in _maps(_home?['collections'])) {
      if (row['id']?.toString() == _collectionId) return row;
    }
    return null;
  }

  Future<void> _send() async {
    final collection = _collection;
    final id = _collectionId;
    if (collection == null || id == null || _sending || collection['active'] != true) return;
    final fields = _maps(collection['fields']);
    final answers = <String, String>{};
    for (final field in fields) {
      final key = field['key']?.toString() ?? '';
      final text = (_answers[key] ?? '').trim();
      if (field['required'] == true && text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).collectionFillRequired)),
        );
        return;
      }
      answers[key] = text;
    }
    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      await _api.submitCollectionForm(
        accessToken: token,
        collectionId: id,
        answers: answers,
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
    final lang = Localizations.localeOf(context).languageCode;
    final collections = _maps(_home?['collections']);
    final collection = _collection;
    final fields = _maps(collection?['fields']);
    final open = collection?['active'] == true;
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.collectionTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.collectionLoadFailed),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: Text(l10n.collectionTitle)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(l10n.collectionHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                    const SizedBox(height: 12),
                    if (collections.isEmpty)
                      Text(l10n.collectionNone, style: TextStyle(color: ObicColors.mutedOf(context)))
                    else ...[
                      DropdownButtonFormField<String>(
                        initialValue: _collectionId,
                        decoration: InputDecoration(labelText: l10n.collectionTitle),
                        items: [
                          for (final row in collections)
                            DropdownMenuItem(
                              value: row['id']?.toString(),
                              child: Text(_name(row, lang)),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() => _apply(value, collections));
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        open ? l10n.collectionOpen : l10n.collectionClosed,
                        style: TextStyle(color: ObicColors.mutedOf(context)),
                      ),
                      const SizedBox(height: 12),
                      for (final field in fields) _field(lang, field, enabled: open),
                      if (open) ...[
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _sending ? null : _send,
                          child: Text(l10n.collectionSend),
                        ),
                      ],
                    ],
                  ],
                ),
    );
  }

  Widget _field(String lang, Map<String, dynamic> field, {required bool enabled}) {
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
            for (final option in choices) DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: enabled ? (value) => setState(() => _answers[key] = value ?? '') : null,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        key: widgetKey,
        initialValue: _answers[key] ?? '',
        readOnly: !enabled,
        keyboardType: field['type'] == 'number' ? TextInputType.number : TextInputType.text,
        textDirection: field['type'] == 'number' ? TextDirection.ltr : null,
        textAlign: field['type'] == 'number' ? TextAlign.left : TextAlign.start,
        minLines: field['type'] == 'long_text' ? 3 : 1,
        maxLines: field['type'] == 'long_text' ? 6 : 1,
        decoration: InputDecoration(labelText: title),
        onChanged: enabled ? (value) => _answers[key] = value : null,
      ),
    );
  }

  String _name(Map<String, dynamic> row, String lang) {
    if (lang == 'ar') return row['nameAr']?.toString() ?? '';
    if (lang == 'zh') return row['nameZh']?.toString() ?? '';
    return row['nameEn']?.toString() ?? '';
  }

  String _label(Map<String, dynamic> field, String lang) {
    if (lang == 'ar') return field['labelAr']?.toString() ?? '';
    if (lang == 'zh') return field['labelZh']?.toString() ?? '';
    return field['labelEn']?.toString() ?? '';
  }
}
