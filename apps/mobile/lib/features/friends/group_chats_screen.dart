// Made by Dr Ali
// Contacts → Group Chats. Group threads from the existing chat list.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/offline_cache_store.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../messages/chat_list_row.dart';
import '../messages/chat_screen.dart';
import '../messages/create_group_screen.dart';
import '../messages/obic_stickers.dart';
import '../messages/group_avatar_collage.dart';
import '../social/social_api.dart';

class GroupChatsScreen extends StatefulWidget {
  const GroupChatsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<GroupChatsScreen> createState() => _GroupChatsScreenState();
}

class _GroupChatsScreenState extends State<GroupChatsScreen> {
  final _api = SocialApi();
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _groups.isEmpty;
      _error = null;
    });
    final uid = widget.authController.user?.id;
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw AuthApiException('Not signed in');
      final threads = await _api.listThreads(token);
      if (uid != null && uid.isNotEmpty) {
        await OfflineCacheStore.instance.saveThreads(uid, threads);
      }
      if (!mounted) return;
      setState(() {
        _groups = _groupThreads(threads);
        _loading = false;
      });
    } catch (e) {
      final cached = uid == null || uid.isEmpty
          ? null
          : await OfflineCacheStore.instance.loadThreads(uid);
      if (!mounted) return;
      if (cached != null) {
        setState(() {
          _groups = _groupThreads(cached);
          _loading = false;
          _error = null;
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> _groupThreads(List<Map<String, dynamic>> threads) {
    final rows = threads.where((thread) {
      if (thread['hidden'] == true) return false;
      final kind = (thread['kind'] as String? ?? '').trim().toLowerCase();
      return kind == 'group';
    }).toList();
    rows.sort(compareChatThreads);
    return rows;
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateGroupScreen(authController: widget.authController),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _open(Map<String, dynamic> thread) async {
    final id = thread['id']?.toString();
    if (id == null || id.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          authController: widget.authController,
          threadId: id,
          title: _title(thread, l10n),
          initialKind: 'group',
        ),
      ),
    );
  }

  String _title(Map<String, dynamic> thread, AppLocalizations l10n) {
    final title = (thread['title'] as String?)?.trim();
    if (title != null && title.isNotEmpty) return title;
    return l10n.chatGroup;
  }

  String _preview(Map<String, dynamic> thread) {
    final last = thread['lastMessage'];
    if (last is! Map) return '';
    final body = (last['body'] as String?)?.trim() ?? '';
    final sticker = parseObicSticker(body);
    if (sticker != null) {
      final arabic = Localizations.localeOf(context).languageCode == 'ar';
      return arabic ? 'ملصق ${sticker.ar}' : 'Sticker ${sticker.en}';
    }
    if (body.isEmpty || body.startsWith('[[')) return '';
    return body;
  }

  List<({String name, String? avatarUrl})> _faces(Map<String, dynamic> thread) {
    final parts = thread['participants'];
    if (parts is! List) return const [];
    final myId = widget.authController.user?.id;
    final faces = <({String name, String? avatarUrl})>[];
    for (final raw in parts) {
      if (raw is! Map) continue;
      final id = raw['userId']?.toString();
      if (myId != null && id == myId) continue;
      faces.add((
        name: (raw['name'] as String?) ?? '',
        avatarUrl: raw['avatarUrl'] as String?,
      ));
    }
    return faces;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final staff = widget.authController.isStaffRole;
    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(l10n.friendsGroupChats),
        actions: [
          if (staff)
            IconButton(
              tooltip: l10n.friendsNewGroup,
              onPressed: _openCreate,
              icon: const Icon(Icons.group_add_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: ObicColors.inkOf(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (_groups.isEmpty && _error == null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                      child: Column(
                        children: [
                          Text(
                            l10n.friendsGroupsEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ObicColors.mutedOf(context)),
                          ),
                          if (staff) ...[
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _openCreate,
                              child: Text(l10n.friendsNewGroup),
                            ),
                          ],
                        ],
                      ),
                    ),
                  for (final thread in _groups) _row(thread, l10n),
                ],
              ),
      ),
    );
  }

  Widget _row(Map<String, dynamic> thread, AppLocalizations l10n) {
    final title = _title(thread, l10n);
    final preview = _preview(thread);
    final line = ObicColors.lineOf(context);
    return Material(
      color: ObicColors.surfaceOf(context),
      child: InkWell(
        onTap: () => _open(thread),
        child: SizedBox(
          height: 64,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 12, 0),
                  child: Row(
                    children: [
                      GroupAvatarCollage(members: _faces(thread), size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: ObicColors.titleOf(context),
                              ),
                            ),
                            if (preview.isNotEmpty)
                              Text(
                                preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ObicColors.mutedOf(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 72),
                child: Divider(height: 1, thickness: 1, color: line),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
