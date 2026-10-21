// Made by Dr Ali
// Staff company directory. The server decides who appears and hides phone numbers.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../messages/chat_screen.dart';
import '../social/social_api.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _api = SocialApi();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _people = [];
  bool _loading = true;
  String? _error;
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) {
        throw StateError('sign-in');
      }
      final rows = await _api.listDirectory(token);
      if (!mounted) return;
      setState(() {
        _people = rows;
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

  String _departmentName(Map<String, dynamic> person, String lang) {
    String? pick(String key) {
      final value = person[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return null;
    }

    if (lang == 'ar') {
      return pick('departmentNameAr') ?? pick('departmentNameEn') ?? '';
    }
    if (lang == 'zh') {
      return pick('departmentNameZh') ?? pick('departmentNameEn') ?? '';
    }
    return pick('departmentNameEn') ?? '';
  }

  Future<void> _message(Map<String, dynamic> person) async {
    final id = person['id']?.toString();
    final name = (person['name'] as String?)?.trim() ?? '';
    if (id == null || id.isEmpty || _openingId != null) return;
    setState(() => _openingId = id);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) return;
      final thread = await _api.openDirectThread(
        accessToken: token,
        peerUserId: id,
      );
      final threadId = thread['id'] as String?;
      if (threadId == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            authController: widget.authController,
            threadId: threadId,
            title: name,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final query = _search.text.trim().toLowerCase();
    final visible = _people.where((person) {
      if (query.isEmpty) return true;
      final name = (person['name'] as String? ?? '').toLowerCase();
      final title = (person['staffTitle'] as String? ?? '').toLowerCase();
      final branch = (person['branchLabel'] as String? ?? '').toLowerCase();
      final department = _departmentName(person, lang).toLowerCase();
      return name.contains(query) ||
          title.contains(query) ||
          branch.contains(query) ||
          department.contains(query);
    }).toList();

    final groups = <String, List<Map<String, dynamic>>>{};
    for (final person in visible) {
      final label = _departmentName(person, lang);
      final key = label.isEmpty ? l10n.directoryUnassigned : label;
      groups.putIfAbsent(key, () => []).add(person);
    }
    final keys = groups.keys.toList()..sort();

    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.directoryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.directoryHint,
              style: TextStyle(color: ObicColors.mutedOf(context)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.directorySearch,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(child: _body(l10n, groups, keys)),
        ],
      ),
    );
  }

  Widget _body(
    AppLocalizations l10n,
    Map<String, List<Map<String, dynamic>>> groups,
    List<String> keys,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.directoryLoadFailed),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: Text(l10n.directoryTitle)),
          ],
        ),
      );
    }
    if (keys.isEmpty) {
      return Center(child: Text(l10n.directoryEmpty));
    }
    final me = widget.authController.user?.id;
    return ListView(
      children: [
        for (final key in keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              key,
              style: TextStyle(
                color: ObicColors.mutedOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final person in groups[key]!)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: ObicColors.blue.withValues(alpha: 0.15),
                child: Text(
                  ((person['name'] as String?)?.trim().isNotEmpty ?? false)
                      ? (person['name'] as String).trim().characters.first
                      : '?',
                ),
              ),
              title: Text((person['name'] as String?) ?? ''),
              subtitle: Text(
                [
                  person['staffTitle'],
                  person['branchLabel'],
                  person['phone'],
                ].whereType<String>().where((item) => item.trim().isNotEmpty).join(' · '),
              ),
              trailing: person['id'] == me
                  ? null
                  : IconButton(
                      tooltip: l10n.directoryMessage,
                      onPressed: _openingId == person['id']
                          ? null
                          : () => _message(person),
                      icon: _openingId == person['id']
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_bubble_outline),
                    ),
            ),
        ],
      ],
    );
  }
}
