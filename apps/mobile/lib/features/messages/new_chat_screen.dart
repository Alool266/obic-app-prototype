// Made by Dr Ali
// WeChat “New Chat” — pick a friend and open the thread.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/api_errors.dart';
import '../../core/connectivity_service.dart';
import '../../core/offline_cache_store.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../moments/moment_avatar.dart';
import '../social/social_api.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _api = SocialApi();
  final _query = TextEditingController();
  List<Map<String, dynamic>> _friends = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = widget.authController.user?.id ?? '';
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw StateError('signed out');
      final rows = await _api.listFriends(token);
      if (uid.isNotEmpty) {
        await OfflineCacheStore.instance.saveFriends(uid, rows);
      }
      if (!mounted) return;
      setState(() {
        _friends = rows;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      final cached = uid.isEmpty
          ? null
          : await OfflineCacheStore.instance.loadFriends(uid);
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _friends = cached;
          _loading = false;
          _error = null;
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = friendlyApiError(
          classifyTransportError(e),
          l10n: AppLocalizations.of(context),
          langCode: Localizations.localeOf(context).languageCode,
        );
      });
    }
  }

  Future<void> _open(Map<String, dynamic> friend) async {
    final l10n = AppLocalizations.of(context);
    if (ConnectivityService.instance.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.offlineNeedsNetwork)),
      );
      return;
    }
    final user = friend['user'];
    final peerId = user is Map ? user['id'] as String? : null;
    final name = user is Map ? (user['name'] as String?) ?? '—' : '—';
    if (peerId == null) return;
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      final thread = await _api.openDirectThread(
        accessToken: token,
        peerUserId: peerId,
      );
      final id = thread['id'] as String?;
      if (id == null || !mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            authController: widget.authController,
            threadId: id,
            title: name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyApiError(
              classifyTransportError(e),
              l10n: AppLocalizations.of(context),
              langCode: Localizations.localeOf(context).languageCode,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = _query.text.trim().toLowerCase();
    final rows = _friends.where((f) {
      if (q.isEmpty) return true;
      final user = f['user'];
      final name = user is Map ? (user['name'] as String?) ?? '' : '';
      return name.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(l10n.chatNewChat),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.friendsSearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: ObicColors.surfaceOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final user = rows[i]['user'];
                          final name = user is Map
                              ? (user['name'] as String?) ?? '—'
                              : '—';
                          final avatar =
                              user is Map ? user['avatarUrl'] as String? : null;
                          return ListTile(
                            leading: MomentAvatar(
                              name: name,
                              avatarUrl: avatar,
                              size: 44,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onTap: () => _open(rows[i]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
