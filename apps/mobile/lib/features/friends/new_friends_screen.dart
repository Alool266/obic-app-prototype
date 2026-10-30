// Made by Dr Ali
// WeChat-style New Friends inbox — incoming Accept/Reject + outgoing Waiting.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../moments/moment_avatar.dart';
import '../shell/tab_badge.dart';
import '../social/social_api.dart';
import 'add_friend_screen.dart';

class NewFriendsScreen extends StatefulWidget {
  const NewFriendsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<NewFriendsScreen> createState() => _NewFriendsScreenState();
}

class _NewFriendsScreenState extends State<NewFriendsScreen> {
  final _api = SocialApi();
  List<Map<String, dynamic>> _incoming = [];
  List<Map<String, dynamic>> _outgoing = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted) return;
    if (!ok) {
      Navigator.of(context).maybePop();
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw AuthApiException('Not signed in');
      final reqs = await _api.listFriendRequests(token);
      final incoming = _dedupeFriendRequests(
        (reqs['incoming'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        peerKey: 'fromUserId',
      );
      final outgoing = _dedupeFriendRequests(
        (reqs['outgoing'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        peerKey: 'toUserId',
      );
      if (!mounted) return;
      setState(() {
        _incoming = incoming;
        _outgoing = outgoing;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _accept(String id) async {
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await _api.acceptFriendRequest(accessToken: token, id: id);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.friendsAcceptedToast)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _reject(String id) async {
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      await _api.rejectFriendRequest(accessToken: token, id: id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = !_loading &&
        _error == null &&
        _incoming.isEmpty &&
        _outgoing.isEmpty;

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(l10n.friendsNewFriends),
        actions: [
          IconButton(
            tooltip: l10n.friendsAdd,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddFriendScreen(
                    authController: widget.authController,
                  ),
                ),
              );
              if (mounted) await _load();
            },
            icon: const Icon(Icons.person_add_alt_1_outlined),
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
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: ObicColors.inkOf(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (empty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                      child: Text(
                        l10n.friendsNewFriendsEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ObicColors.mutedOf(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (_incoming.isNotEmpty) ...[
                    _SectionHeader(
                      label: l10n.friendsIncoming,
                      count: _incoming.length,
                    ),
                    ..._incoming.map(
                      (r) => _IncomingRow(
                        request: r,
                        busy: _busyIds.contains(r['id'] as String? ?? ''),
                        acceptLabel: l10n.friendsAccept,
                        rejectLabel: l10n.friendsReject,
                        onAccept: () {
                          final id = r['id'] as String?;
                          if (id != null) _accept(id);
                        },
                        onReject: () {
                          final id = r['id'] as String?;
                          if (id != null) _reject(id);
                        },
                      ),
                    ),
                  ],
                  if (_outgoing.isNotEmpty) ...[
                    _SectionHeader(label: l10n.friendsOutgoing),
                    ..._outgoing.map(
                      (r) => _OutgoingRow(
                        request: r,
                        waitingLabel: l10n.friendsWaiting,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ObicColors.mutedOf(context),
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 8),
            ObicCountBadge(count: count!, compact: true),
          ],
        ],
      ),
    );
  }
}

class _IncomingRow extends StatelessWidget {
  const _IncomingRow({
    required this.request,
    required this.busy,
    required this.acceptLabel,
    required this.rejectLabel,
    required this.onAccept,
    required this.onReject,
  });

  final Map<String, dynamic> request;
  final bool busy;
  final String acceptLabel;
  final String rejectLabel;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final from = request['from'];
    final name = from is Map
        ? (from['name'] as String?)?.trim().isNotEmpty == true
            ? from['name'] as String
            : '—'
        : '—';
    final avatarUrl = from is Map ? from['avatarUrl'] as String? : null;
    final note = (request['message'] as String?)?.trim();

    return Material(
      color: ObicColors.surfaceOf(context),
      child: InkWell(
        onTap: busy ? null : onAccept,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MomentAvatar(name: name, avatarUrl: avatarUrl, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: ObicColors.titleOf(context),
                      ),
                    ),
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: ObicColors.mutedOf(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                TextButton(
                  onPressed: onReject,
                  style: TextButton.styleFrom(
                    foregroundColor: ObicColors.mutedOf(context),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(rejectLabel),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: ObicColors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(acceptLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OutgoingRow extends StatelessWidget {
  const _OutgoingRow({
    required this.request,
    required this.waitingLabel,
  });

  final Map<String, dynamic> request;
  final String waitingLabel;

  @override
  Widget build(BuildContext context) {
    final to = request['to'];
    final name = to is Map
        ? (to['name'] as String?)?.trim().isNotEmpty == true
            ? to['name'] as String
            : '—'
        : '—';
    final avatarUrl = to is Map ? to['avatarUrl'] as String? : null;
    final note = (request['message'] as String?)?.trim();

    return Container(
      color: ObicColors.surfaceOf(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          MomentAvatar(name: name, avatarUrl: avatarUrl, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: ObicColors.titleOf(context),
                  ),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: ObicColors.mutedOf(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            waitingLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ObicColors.mutedOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// WeChat: one New Friends row per peer (list may already be DESC).
List<Map<String, dynamic>> _dedupeFriendRequests(
  List<Map<String, dynamic>> rows, {
  required String peerKey,
}) {
  final seen = <String>{};
  final out = <Map<String, dynamic>>[];
  for (final r in rows) {
    final id = (r[peerKey] as String?) ?? '';
    if (id.isEmpty || seen.contains(id)) continue;
    seen.add(id);
    out.add(r);
  }
  return out;
}
