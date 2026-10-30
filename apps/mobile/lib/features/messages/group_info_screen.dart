// Made by Dr Ali
// WeChat-style group card: members, and add a friend who is not in yet.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/api_errors.dart';
import '../../core/obic_phrases.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../friends/contact_profile_screen.dart';
import '../moments/moment_avatar.dart';
import '../social/social_api.dart';
import 'group_avatar_collage.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({
    super.key,
    required this.authController,
    required this.threadId,
    required this.title,
    required this.participants,
  });

  final AuthController authController;
  final String threadId;
  final String title;
  final List<Map<String, dynamic>> participants;

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final _api = SocialApi();
  late List<Map<String, dynamic>> _members;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _members = widget.participants
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _add() async {
    final token = await widget.authController.accessToken();
    if (token == null || !mounted) return;
    final present = _members
        .map((row) => row['userId']?.toString() ?? row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    List<Map<String, dynamic>> friends = [];
    try {
      final rows = await _api.listFriends(token);
      for (final row in rows) {
        final user = row['user'];
        if (user is Map) {
          final id = user['id']?.toString() ?? '';
          if (id.isEmpty || present.contains(id)) continue;
          friends.add(Map<String, dynamic>.from(user));
        }
      }
    } catch (e) {
      if (!mounted) return;
      _toast(_err(e));
      return;
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ObicColors.surfaceOf(context),
      builder: (ctx) => _PickFriends(friends: friends),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() => _saving = true);
    try {
      final thread = await _api.addGroupMembers(
        accessToken: token,
        threadId: widget.threadId,
        userIds: picked,
      );
      final parts = thread['participants'];
      if (!mounted) return;
      if (parts is List) {
        setState(() {
          _members = parts.whereType<Map>().map((row) {
            return Map<String, dynamic>.from(row);
          }).toList();
          _saving = false;
        });
      } else {
        setState(() => _saving = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(_err(e));
    }
  }

  String _err(Object e) {
    return friendlyApiError(
      classifyTransportError(e),
      l10n: AppLocalizations.of(context),
      langCode: Localizations.localeOf(context).languageCode,
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.authController.user?.id;
    final faces = _members
        .map(
          (row) => (
            name: (row['name'] as String?) ?? '?',
            avatarUrl: row['avatarUrl'] as String?,
          ),
        )
        .toList();
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(
          obicPhrase(context, ar: 'معلومات المجموعة', en: 'Group info', zh: '群聊信息'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Center(
                  child: GroupAvatarCollage(size: 72, members: faces),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ObicColors.titleOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  obicPhrase(
                    context,
                    ar: '${_members.length} أعضاء',
                    en: '${_members.length} members',
                    zh: '${_members.length} 名成员',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ObicColors.mutedOf(context)),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _members.length + 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _AddTile(
                        label: obicPhrase(context, ar: 'إضافة', en: 'Add', zh: '添加'),
                        onTap: _add,
                      );
                    }
                    final row = _members[i - 1];
                    final id = row['userId']?.toString() ?? '';
                    final name = (row['name'] as String?) ?? '?';
                    return InkWell(
                      onTap: id.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ContactProfileScreen(
                                    authController: widget.authController,
                                    userId: id,
                                    seedUser: {
                                      'id': id,
                                      'name': name,
                                      'avatarUrl': row['avatarUrl'],
                                    },
                                  ),
                                ),
                              );
                            },
                      child: Column(
                        children: [
                          MomentAvatar(
                            name: name,
                            avatarUrl: row['avatarUrl'] as String?,
                            size: 48,
                            borderRadius: 8,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            id == me
                                ? obicPhrase(context, ar: 'أنا', en: 'Me', zh: '我')
                                : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ObicColors.blue, width: 1.4),
            ),
            child: const Icon(Icons.add, color: ObicColors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: ObicColors.blue),
          ),
        ],
      ),
    );
  }
}

class _PickFriends extends StatefulWidget {
  const _PickFriends({required this.friends});

  final List<Map<String, dynamic>> friends;

  @override
  State<_PickFriends> createState() => _PickFriendsState();
}

class _PickFriendsState extends State<_PickFriends> {
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      obicPhrase(
                        context,
                        ar: 'إضافة أعضاء',
                        en: 'Add members',
                        zh: '添加成员',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _picked.isEmpty
                        ? null
                        : () => Navigator.pop(context, _picked.toList()),
                    style: FilledButton.styleFrom(backgroundColor: ObicColors.blue),
                    child: Text(
                      obicPhrase(context, ar: 'تم', en: 'Done', zh: '完成'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.friends.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          obicPhrase(
                            context,
                            ar: 'كل أصدقائك موجودون في المجموعة',
                            en: 'All your friends are already in the group',
                            zh: '好友都已在群里',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ObicColors.mutedOf(context)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: bottom),
                      itemCount: widget.friends.length,
                      itemBuilder: (_, i) {
                        final user = widget.friends[i];
                        final id = user['id']?.toString() ?? '';
                        final on = _picked.contains(id);
                        final name = (user['name'] as String?) ?? '—';
                        return ListTile(
                          leading: MomentAvatar(
                            name: name,
                            avatarUrl: user['avatarUrl'] as String?,
                            size: 40,
                            borderRadius: 8,
                          ),
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            on ? Icons.check_circle : Icons.circle_outlined,
                            color: on ? ObicColors.blue : ObicColors.mutedOf(context),
                          ),
                          onTap: () => setState(() {
                            if (on) {
                              _picked.remove(id);
                            } else {
                              _picked.add(id);
                            }
                          }),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
