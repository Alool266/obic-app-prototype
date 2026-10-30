// Made by Dr Ali
// List + create/open/save for personal Notes / Documents / Spreadsheets / PDF.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/script_text_field.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';
import 'office_strings.dart';
import 'user_office_api.dart';

class OfficeHomeScreen extends StatefulWidget {
  const OfficeHomeScreen({
    super.key,
    required this.authController,
    required this.kind,
  });

  final AuthController authController;
  final String kind; // note | document | spreadsheet | pdf

  @override
  State<OfficeHomeScreen> createState() => _OfficeHomeScreenState();
}

class _OfficeHomeScreenState extends State<OfficeHomeScreen> {
  final _api = UserOfficeApi();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  OfficeStrings get _s =>
      OfficeStrings(Localizations.localeOf(context).languageCode);

  String get _title {
    switch (widget.kind) {
      case 'note':
        return _s.notes;
      case 'document':
        return _s.documents;
      case 'spreadsheet':
        return _s.spreadsheets;
      case 'pdf':
        return _s.pdf;
      default:
        return widget.kind;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _token() => widget.authController.accessToken();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _token();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final rows = await _api.list(accessToken: token, kind: widget.kind);
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  Future<void> _create() async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.signInRequired)),
      );
      return;
    }
    try {
      if (widget.kind == 'pdf') {
        final url = await _askPdfUrl();
        if (url == null || url.isEmpty) return;
        final row = await _api.create(
          accessToken: token,
          kind: 'pdf',
          title: url.split('/').last,
          fileUrl: url,
        );
        if (!mounted) return;
        await _open(row);
        await _load();
        return;
      }
      final row = await _api.create(accessToken: token, kind: widget.kind);
      if (!mounted) return;
      await _open(row);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.loadFailed)),
      );
    }
  }

  Future<String?> _askPdfUrl() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_s.pdf),
        content: ObicScriptTextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: _s.pdfUrlHint),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_s.openPdf),
          ),
        ],
      ),
    );
    final url = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true) return null;
    return url;
  }

  Future<void> _open(Map<String, dynamic> row) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OfficeEditorScreen(
          authController: widget.authController,
          kind: widget.kind,
          itemId: id,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final title = ObicColors.titleOf(context);
    final muted = ObicColors.mutedOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: _s.newItem,
            onPressed: _loading ? null : () => _create(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_s.loadFailed, style: TextStyle(color: muted)),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _rows.isEmpty
                  ? Center(child: Text(_s.empty, style: TextStyle(color: muted)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final row = _rows[i];
                          final name = row['title']?.toString() ?? '';
                          final shared = row['shared'] == true;
                          return ListTile(
                            title: Text(name, style: TextStyle(color: title)),
                            subtitle: shared
                                ? Text('Shared', style: TextStyle(color: muted))
                                : null,
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _open(row),
                          );
                        },
                      ),
                    ),
    );
  }
}

class OfficeEditorScreen extends StatefulWidget {
  const OfficeEditorScreen({
    super.key,
    required this.authController,
    required this.kind,
    required this.itemId,
  });

  final AuthController authController;
  final String kind;
  final String itemId;

  @override
  State<OfficeEditorScreen> createState() => _OfficeEditorScreenState();
}

class _OfficeEditorScreenState extends State<OfficeEditorScreen> {
  final _api = UserOfficeApi();
  final _title = TextEditingController();
  final _body = TextEditingController();
  List<List<TextEditingController>> _cells = [];
  String? _fileUrl;
  bool _loading = true;
  bool _saving = false;
  bool _owner = true;
  WebViewController? _pdf;

  static const _cols = ['A', 'B', 'C', 'D', 'E', 'F'];

  OfficeStrings get _s =>
      OfficeStrings(Localizations.localeOf(context).languageCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    for (final row in _cells) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final row = await _api.get(accessToken: token, id: widget.itemId);
      if (!mounted) return;
      _title.text = row['title']?.toString() ?? '';
      _owner = row['owner'] != false;
      if (widget.kind == 'note' || widget.kind == 'document') {
        _body.text = row['body']?.toString() ?? '';
      } else if (widget.kind == 'spreadsheet') {
        _bindGrid(row['grid']);
      } else if (widget.kind == 'pdf') {
        _fileUrl = row['fileUrl']?.toString();
        final url = _fileUrl;
        if (url != null && url.isNotEmpty) {
          _pdf = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(url));
        }
      }
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.loadFailed)),
      );
    }
  }

  void _bindGrid(Object? value) {
    for (final row in _cells) {
      for (final c in row) {
        c.dispose();
      }
    }
    final rows = value is List ? value : const [];
    _cells = [
      for (var r = 0; r < 12; r++)
        [
          for (var c = 0; c < _cols.length; c++)
            TextEditingController(
              text: rows.length > r &&
                      rows[r] is List &&
                      (rows[r] as List).length > c
                  ? (rows[r] as List)[c]?.toString() ?? ''
                  : '',
            ),
        ],
    ];
  }

  Future<void> _save() async {
    if (!_owner || _saving) return;
    setState(() => _saving = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      await _api.update(
        accessToken: token,
        id: widget.itemId,
        title: _title.text.trim(),
        body: widget.kind == 'note' || widget.kind == 'document'
            ? _body.text
            : null,
        grid: widget.kind == 'spreadsheet'
            ? [
                for (final row in _cells) [for (final c in row) c.text],
              ]
            : null,
        fileUrl: widget.kind == 'pdf' ? _fileUrl : null,
      );
      if (!mounted) return;
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.save)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.loadFailed)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    if (!_owner) return;
    final token = await widget.authController.accessToken();
    if (token == null || token.isEmpty) return;
    List<Map<String, dynamic>> friends = const [];
    try {
      friends = await SocialApi().listFriends(token);
    } catch (_) {}
    if (!mounted) return;
    final selected = <String>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(_s.share),
          content: SizedBox(
            width: 320,
            height: 280,
            child: friends.isEmpty
                ? Text(_s.empty)
                : ListView(
                    children: [
                      for (final f in friends)
                        CheckboxListTile(
                          value: selected.contains(
                            (f['id'] ?? f['userId'])?.toString(),
                          ),
                          title: Text(
                            f['name']?.toString() ??
                                f['id']?.toString() ??
                                '',
                          ),
                          onChanged: (v) {
                            final id =
                                (f['id'] ?? f['userId'])?.toString() ?? '';
                            if (id.isEmpty) return;
                            setLocal(() {
                              if (v == true) {
                                selected.add(id);
                              } else {
                                selected.remove(id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_s.share),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _api.share(
        accessToken: token,
        id: widget.itemId,
        shareUserIds: selected.toList(),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleLabel()),
        actions: [
          if (_owner)
            IconButton(
              tooltip: _s.share,
              onPressed: _share,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          if (_owner)
            IconButton(
              tooltip: _s.save,
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ObicScriptTextField(
                    controller: _title,
                    decoration: InputDecoration(hintText: _s.titleHint),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _editorBody(rtl)),
                ],
              ),
            ),
    );
  }

  String _titleLabel() {
    switch (widget.kind) {
      case 'note':
        return _s.notes;
      case 'document':
        return _s.documents;
      case 'spreadsheet':
        return _s.spreadsheets;
      case 'pdf':
        return _s.pdf;
      default:
        return widget.kind;
    }
  }

  Widget _editorBody(bool rtl) {
    if (widget.kind == 'pdf') {
      final ctrl = _pdf;
      if (ctrl == null) {
        return Center(child: Text(_s.empty));
      }
      return WebViewWidget(controller: ctrl);
    }
    if (widget.kind == 'spreadsheet') {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: [
              for (final c in _cols)
                DataColumn(label: Text(c, textDirection: TextDirection.ltr)),
            ],
            rows: [
              for (var r = 0; r < _cells.length; r++)
                DataRow(
                  cells: [
                    for (var c = 0; c < _cols.length; c++)
                      DataCell(
                        SizedBox(
                          width: 88,
                          child: TextField(
                            controller: _cells[r][c],
                            enabled: _owner,
                            textDirection:
                                rtl ? TextDirection.rtl : TextDirection.ltr,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      );
    }
    return ObicScriptTextField(
      controller: _body,
      decoration: InputDecoration(hintText: _s.bodyHint),
      maxLines: null,
      minLines: 12,
    );
  }
}

class OfficeComingSoonScreen extends StatelessWidget {
  const OfficeComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = OfficeStrings(Localizations.localeOf(context).languageCode);
    return Scaffold(
      appBar: AppBar(title: Text(s.slides)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.comingSoon,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ObicColors.titleOf(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.onlyOfficeSoon,
              style: TextStyle(
                height: 1.45,
                color: ObicColors.mutedOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
