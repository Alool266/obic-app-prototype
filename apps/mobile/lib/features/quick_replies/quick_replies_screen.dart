// Made by Dr Ali
// Company replies and the employee's own short replies. Copy the text. The app does not send it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class QuickRepliesScreen extends StatefulWidget {
  const QuickRepliesScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<QuickRepliesScreen> createState() => _QuickRepliesScreenState();
}

class _QuickRepliesScreenState extends State<QuickRepliesScreen> {
  final _api = SocialApi();
  final _title = TextEditingController();
  final _body = TextEditingController();
  List<Map<String, dynamic>> _company = [];
  List<Map<String, dynamic>> _mine = [];
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
    _title.dispose();
    _body.dispose();
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
      final home = await _api.quickRepliesHome(token);
      if (!mounted) return;
      setState(() {
        _company = _maps(home['company']);
        _mine = _maps(home['mine']);
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
    });
    _title.clear();
    _body.clear();
  }

  void _edit(Map<String, dynamic> row) {
    setState(() {
      _editingId = row['id']?.toString();
      _active = row['active'] == true;
    });
    _title.text = row['title']?.toString() ?? '';
    _body.text = row['body']?.toString() ?? '';
  }

  Future<void> _copy(String body) async {
    if (body.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: body));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).quickRepliesCopied)));
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) return;
      final editingId = _editingId;
      if (editingId == null) {
        await _api.createQuickReply(accessToken: token, title: title, body: body);
      } else {
        await _api.updateQuickReply(
          accessToken: token,
          replyId: editingId,
          title: title,
          body: body,
          active: _active,
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
      appBar: AppBar(title: Text(l10n.quickRepliesTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.quickRepliesHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                const SizedBox(height: 12),
                Text(l10n.quickRepliesMine, style: Theme.of(context).textTheme.titleMedium),
                TextField(
                  controller: _title,
                  maxLength: 24,
                  decoration: InputDecoration(labelText: l10n.quickRepliesName),
                ),
                TextField(
                  controller: _body,
                  maxLength: 300,
                  decoration: InputDecoration(labelText: l10n.quickRepliesBody),
                ),
                if (_editingId != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_active ? l10n.quickRepliesActive : l10n.quickRepliesPaused),
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                  ),
                FilledButton(onPressed: _sending ? null : _save, child: Text(l10n.quickRepliesSave)),
                if (_editingId != null) TextButton(onPressed: _clear, child: Text(l10n.quickRepliesNew)),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.quickRepliesLoadFailed),
                  ),
                for (final row in _mine) _tile(l10n, row, onEdit: () => _edit(row)),
                const SizedBox(height: 16),
                Text(l10n.quickRepliesCompany, style: Theme.of(context).textTheme.titleMedium),
                if (_company.isEmpty && _mine.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l10n.quickRepliesNone),
                  ),
                for (final row in _company) _tile(l10n, row),
              ],
            ),
    );
  }

  Widget _tile(AppLocalizations l10n, Map<String, dynamic> row, {VoidCallback? onEdit}) {
    final body = row['body']?.toString() ?? '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(row['title']?.toString() ?? ''),
      subtitle: Text(body),
      onTap: onEdit,
      trailing: IconButton(
        onPressed: () => _copy(body),
        icon: const Icon(Icons.copy_outlined),
        tooltip: l10n.quickRepliesCopy,
      ),
    );
  }
}
