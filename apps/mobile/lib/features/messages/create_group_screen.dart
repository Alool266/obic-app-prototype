// Made by Dr Ali
// Any signed-in user starts a group with accepted friends.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/api_errors.dart';
import '../../core/obic_phrases.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../moments/moment_avatar.dart';
import '../social/social_api.dart';
import 'chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({
    super.key,
    required this.authController,
    this.demoTitle,
    this.demoSearchQuery,
    this.demoAlsoSearch,
  });

  final AuthController authController;
  /// Capture-only: prefill title + search/select members.
  final String? demoTitle;
  final String? demoSearchQuery;
  final String? demoAlsoSearch;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _api = SocialApi();
  final _title = TextEditingController();
  final _query = TextEditingController();
  final Set<String> _selected = {};
  final Map<String, Map<String, dynamic>> _picked = {};
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _results = [];
  bool _searching = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _query.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _query.removeListener(_applyFilter);
    _title.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.demoTitle != null) _title.text = widget.demoTitle!;
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw AuthApiException('Not signed in');
      final rows = await _api.listFriends(token);
      if (!mounted) return;
      final friends = <Map<String, dynamic>>[];
      for (final row in rows) {
        final user = row['user'];
        if (user is Map) {
          friends.add(Map<String, dynamic>.from(user));
        }
      }
      setState(() {
        _friends = friends;
        _searching = false;
      });
      _applyFilter();
      _applyDemoPicks();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = friendlyApiError(
          classifyTransportError(e),
          l10n: AppLocalizations.of(context),
          langCode: Localizations.localeOf(context).languageCode,
        );
      });
    }
  }

  void _applyFilter() {
    final q = _query.text.trim().toLowerCase();
    final next = _friends.where((u) {
      if (q.isEmpty) return true;
      final name = (u['name'] as String? ?? '').toLowerCase();
      return name.contains(q);
    }).toList();
    if (!mounted) return;
    setState(() => _results = next);
  }

  void _applyDemoPicks() {
    final queries = [widget.demoSearchQuery, widget.demoAlsoSearch]
        .whereType<String>()
        .map((q) => q.trim().toLowerCase())
        .where((q) => q.isNotEmpty)
        .toList();
    if (queries.isEmpty) return;
    for (final u in _friends) {
      final name = (u['name'] as String? ?? '').toLowerCase();
      if (queries.any(name.contains)) _toggle(u);
    }
  }

  void _toggle(Map<String, dynamic> u) {
    final id = u['id'] as String?;
    if (id == null) return;
    final me = widget.authController.user?.id;
    if (id == me) return;
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        _picked.remove(id);
      } else {
        _selected.add(id);
        _picked[id] = u;
      }
    });
  }

  Future<void> _create() async {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    var title = _title.text.trim();
    if (_selected.isEmpty) {
      setState(
        () => _error = arabic
            ? 'اختر صديقاً واحداً على الأقل'
            : 'Pick at least one friend',
      );
      return;
    }
    if (title.isEmpty) {
      title = _picked.values
          .map((u) => (u['name'] as String?)?.trim() ?? '')
          .where((name) => name.isNotEmpty)
          .take(3)
          .join(arabic ? '، ' : ', ');
    }
    if (title.isEmpty) {
      title = arabic ? 'مجموعة' : 'Group';
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw AuthApiException('Not signed in');
      final thread = await _api.createGroupThread(
        accessToken: token,
        title: title,
        memberUserIds: _selected.toList(),
      );
      final id = thread['id'] as String?;
      if (id == null || !mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            authController: widget.authController,
            threadId: id,
            title: title,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyApiError(
          classifyTransportError(e),
          l10n: AppLocalizations.of(context),
          langCode: Localizations.localeOf(context).languageCode,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(
          obicPhrase(context, ar: 'مجموعة جديدة', en: 'New group', zh: '新建群聊'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  obicPhrase(
                    context,
                    ar: 'اختر أصدقاءك ثم ابدأ المجموعة. المكالمة من داخل المحادثة.',
                    en: 'Pick friends, then start the group. Call from inside the chat.',
                    zh: '选择好友后建群。通话在群聊里发起。',
                  ),
                  style: TextStyle(color: ObicColors.mutedOf(context), height: 1.4),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _title,
                  cursorColor: ObicColors.blue,
                  style: TextStyle(color: ObicColors.inkOf(context), fontSize: 16),
                  decoration: InputDecoration(
                    labelText: obicPhrase(
                      context,
                      ar: 'اسم المجموعة',
                      en: 'Group name',
                      zh: '群名称',
                    ),
                    hintText: obicPhrase(context, ar: 'اختياري', en: 'Optional', zh: '选填'),
                    labelStyle: TextStyle(color: ObicColors.mutedOf(context)),
                    hintStyle: TextStyle(color: ObicColors.mutedOf(context)),
                    filled: true,
                    fillColor: ObicColors.surfaceRaisedOf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _query,
                  cursorColor: ObicColors.blue,
                  style: TextStyle(color: ObicColors.inkOf(context), fontSize: 16),
                  decoration: InputDecoration(
                    hintText: l10n.friendsSearchHint,
                    hintStyle: TextStyle(color: ObicColors.mutedOf(context)),
                    filled: true,
                    fillColor: ObicColors.surfaceRaisedOf(context),
                    suffixIcon: Icon(Icons.search, color: ObicColors.mutedOf(context)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _applyFilter(),
                ),
              ],
            ),
          ),
          if (_picked.isNotEmpty)
            SizedBox(
              height: 86,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _picked.values.map((u) {
                  final id = u['id'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            MomentAvatar(
                              name: (u['name'] as String?) ?? '?',
                              avatarUrl: u['avatarUrl'] as String?,
                              size: 48,
                              borderRadius: 8,
                            ),
                            Positioned(
                              right: -2,
                              top: -2,
                              child: InkWell(
                                onTap: () => _toggle(u),
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.redAccent,
                                  child: Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        SizedBox(
                          width: 64,
                          child: Text(
                            (u['name'] as String?) ?? id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          Expanded(
            child: _searching
                ? Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _friends.isEmpty
                            ? (arabic
                                  ? 'أضف صديقاً أولاً، ثم ابدأ المجموعة'
                                  : 'Add a friend first, then start a group')
                            : (arabic ? 'لا يوجد أصدقاء بهذا الاسم' : 'No friends match'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ObicColors.mutedOf(context)),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final u = _results[i];
                      final id = u['id'] as String? ?? '';
                      final on = _selected.contains(id);
                      return Material(
                        color: ObicColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: MomentAvatar(
                            name: (u['name'] as String?) ?? '?',
                            avatarUrl: u['avatarUrl'] as String?,
                            size: 40,
                            borderRadius: 8,
                          ),
                          title: Text((u['name'] as String?) ?? '—'),
                          subtitle: Text(
                            arabic ? 'صديق' : 'Friend',
                            style: TextStyle(color: ObicColors.mutedOf(context)),
                          ),
                          trailing: Icon(
                            on ? Icons.check_circle : Icons.add_circle_outline,
                            color: on ? ObicColors.blue : ObicColors.muted,
                          ),
                          onTap: () => _toggle(u),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _saving ? null : _create,
            style: FilledButton.styleFrom(
              backgroundColor: ObicColors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              _saving
                  ? (arabic ? 'جاري الإنشاء…' : 'Creating…')
                  : (arabic
                        ? 'إنشاء المجموعة (${_selected.length})'
                        : 'Create group (${_selected.length})'),
            ),
          ),
        ),
      ),
    );
  }
}
