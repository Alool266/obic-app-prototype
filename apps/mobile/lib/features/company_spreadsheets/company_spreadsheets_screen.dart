// Made by Dr Ali
// Shared spreadsheets. Cells are text. The latest save stays.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

const _cols = ['A', 'B', 'C', 'D', 'E', 'F'];

class CompanySpreadsheetsScreen extends StatefulWidget {
  const CompanySpreadsheetsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanySpreadsheetsScreen> createState() => _CompanySpreadsheetsScreenState();
}

class _CompanySpreadsheetsScreenState extends State<CompanySpreadsheetsScreen> {
  final _api = SocialApi();
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic>? _sheet;
  List<List<TextEditingController>> _cells = [];
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
    _disposeCells(_cells);
    super.dispose();
  }

  void _disposeCells(List<List<TextEditingController>> cells) {
    for (final row in cells) {
      for (final cell in row) {
        cell.dispose();
      }
    }
  }

  void _bind(Object? value) {
    final previous = _cells;
    final grid = _grid(value);
    _cells = [
      for (final row in grid) [for (final cell in row) TextEditingController(text: cell)],
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _disposeCells(previous));
  }

  List<List<String>> _grid(Object? value) {
    final rows = value is List ? value : const [];
    return [
      for (var r = 0; r < 12; r++)
        [
          for (var c = 0; c < _cols.length; c++)
            rows.length > r && rows[r] is List && (rows[r] as List).length > c
                ? (rows[r] as List)[c]?.toString() ?? ''
                : '',
        ],
    ];
  }

  Future<void> _load() async {
    final previous = _cells;
    _cells = [];
    setState(() {
      _loading = true;
      _error = null;
      _sheet = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _disposeCells(previous));
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final home = await _api.companySpreadsheetsHome(token);
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
      final row = await _api.companySpreadsheet(token, id);
      if (!mounted) return;
      _bind(row['rows']);
      setState(() {
        _sheet = row;
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
    final id = _sheet?['id']?.toString() ?? '';
    if (id.isEmpty || _saving || _cells.length != 12) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final rows = [
        for (final row in _cells) [for (final cell in row) cell.text],
      ];
      final saved = await _api.updateCompanySpreadsheet(
        accessToken: token,
        sheetId: id,
        rows: rows,
      );
      if (!mounted) return;
      _bind(saved['rows']);
      setState(() {
        _sheet = saved;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sheet = _sheet;
    final editor = sheet?['editorName']?.toString() ?? '';
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(sheet?['title']?.toString() ?? l10n.companySpreadsheetsTitle),
        leading: sheet == null
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _load),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.companySpreadsheetsHint,
                  style: TextStyle(color: ObicColors.mutedOf(context)),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companySpreadsheetsLoadFailed),
                  ),
                if (sheet == null && _rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companySpreadsheetsNone),
                  ),
                if (sheet == null)
                  for (final row in _rows)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(row['title']?.toString() ?? ''),
                      onTap: () => _open(row['id']?.toString() ?? ''),
                    ),
                if (sheet != null) ...[
                  if (editor.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(l10n.companySpreadsheetsSavedBy(editor)),
                    ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 28),
                            for (final col in _cols)
                              SizedBox(width: 96, child: Text(col, textAlign: TextAlign.center)),
                          ],
                        ),
                        for (var r = 0; r < _cells.length; r++)
                          Row(
                            children: [
                              SizedBox(width: 28, child: Text('${r + 1}')),
                              for (var c = 0; c < _cells[r].length; c++)
                                SizedBox(
                                  width: 96,
                                  child: TextField(
                                    controller: _cells[r][c],
                                    maxLength: 80,
                                    decoration: const InputDecoration(counterText: ''),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.companySpreadsheetsSave),
                  ),
                ],
              ],
            ),
    );
  }
}
