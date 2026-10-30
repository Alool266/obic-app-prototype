// Made by Dr Ali
// Add friend — search, show My QR, or scan QR (WeChat-style).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/obic_bidi.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

/// QR payload format: obic:user:<uuid>
String obicUserQrPayload(String userId) => 'obic:user:$userId';

String? parseObicUserQr(String raw) {
  final s = raw.trim();
  final m = RegExp(
    r'obic:user:([0-9a-fA-F-]{36})',
    caseSensitive: false,
  ).firstMatch(s);
  if (m != null) return m.group(1);
  // Bare UUID also accepted (paste / demo).
  if (RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(s)) {
    return s;
  }
  return null;
}

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({
    super.key,
    required this.authController,
    this.demoInitialTab = 0,
    this.demoSearchQuery,
  });

  final AuthController authController;

  /// Capture-only: 0=search, 1=My QR, 2=scan.
  final int demoInitialTab;
  final String? demoSearchQuery;

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen>
    with SingleTickerProviderStateMixin {
  final _api = SocialApi();
  final _query = TextEditingController();
  final _paste = TextEditingController();
  late final TabController _tabs;
  List<Map<String, dynamic>> _results = [];

  /// userId → pending outgoing (Waiting).
  final Set<String> _outgoingPendingIds = {};

  /// userId → already friends.
  final Set<String> _friendIds = {};
  bool _searching = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final tab = widget.demoInitialTab.clamp(0, 2);
    _tabs = TabController(length: 3, vsync: this, initialIndex: tab);
    unawaited(_warmRelationSets());
    if (widget.demoSearchQuery != null && widget.demoSearchQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _query.text = widget.demoSearchQuery!;
        await _search();
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _query.dispose();
    _paste.dispose();
    super.dispose();
  }

  Future<void> _warmRelationSets() async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      final friends = await _api.listFriends(token);
      final reqs = await _api.listFriendRequests(token);
      final friendIds = <String>{};
      for (final f in friends) {
        final user = f['user'];
        final id = user is Map ? user['id'] as String? : null;
        if (id != null) friendIds.add(id);
      }
      final outgoing = <String>{};
      final outList = reqs['outgoing'];
      if (outList is List) {
        for (final r in outList) {
          if (r is! Map) continue;
          final to = r['to'];
          final id = to is Map ? to['id'] as String? : r['toUserId'] as String?;
          if (id != null) outgoing.add(id);
        }
      }
      if (!mounted) return;
      setState(() {
        _friendIds
          ..clear()
          ..addAll(friendIds);
        _outgoingPendingIds
          ..clear()
          ..addAll(outgoing);
      });
    } catch (_) {}
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.length < 2) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw AuthApiException('Not signed in');
      final rows = await _api.searchUsers(accessToken: token, q: q);
      if (!mounted) return;
      setState(() {
        _results = rows;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.toString();
      });
    }
  }

  /// WeChat: optional verification note before send.
  Future<String?> _promptVerificationMessage() async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.friendsSendRequestTitle),
          content: TextField(
            controller: ctrl,
            maxLength: 120,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.friendsVerificationHint),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.friendsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: Text(l10n.friendsSend),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _addUserId(String userId) async {
    final l10n = AppLocalizations.of(context);
    if (_busy) return;
    if (_friendIds.contains(userId)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.friendsAlreadyFriends)));
      return;
    }
    if (_outgoingPendingIds.contains(userId)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.friendsWaiting)));
      return;
    }

    final note = await _promptVerificationMessage();
    if (note == null || !mounted) return; // cancelled

    setState(() => _busy = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw AuthApiException('Not signed in');
      final res = await _api.sendFriendRequest(
        accessToken: token,
        userId: userId,
        message: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      final status = res['status'] as String?;
      // Reciprocal auto-accept returns Accepted.
      if (status == 'Accepted') {
        setState(() {
          _friendIds.add(userId);
          _outgoingPendingIds.remove(userId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsAcceptedToast)));
      } else {
        setState(() => _outgoingPendingIds.add(userId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsRequestSent)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(Map<String, dynamic> user) async {
    final id = user['id'] as String?;
    if (id == null) return;
    await _addUserId(id);
  }

  Future<void> _handleQrRaw(String raw) async {
    final l10n = AppLocalizations.of(context);
    final id = parseObicUserQr(raw);
    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.friendsQrInvalid)));
      return;
    }
    final me = widget.authController.user?.id;
    if (me != null && me == id) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.friendsQrInvalid)));
      return;
    }
    await _addUserId(id);
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const _QrScanPage()));
    if (result == null || !mounted) return;
    await _handleQrRaw(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = widget.authController.user;
    final myId = me?.id ?? '';
    final qrData = myId.isEmpty ? '' : obicUserQrPayload(myId);

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(l10n.friendsAdd),
        backgroundColor: ObicColors.isDark(context)
            ? ObicColors.surfaceOf(context)
            : ObicColors.navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: l10n.friendsByPhone),
            Tab(text: l10n.friendsMyQr),
            Tab(text: l10n.friendsScanQr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _query,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    style: TextStyle(color: ObicColors.inkOf(context)),
                    decoration: InputDecoration(
                      hintText: l10n.friendsSearchHint,
                      hintStyle: TextStyle(color: ObicColors.mutedOf(context)),
                      filled: true,
                      fillColor: ObicColors.surfaceOf(context),
                      suffixIcon: IconButton(
                        onPressed: _searching ? null : _search,
                        icon: Icon(
                          Icons.search,
                          color: ObicColors.mutedOf(context),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: ObicColors.lineOf(context),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: ObicColors.lineOf(context),
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  l10n.friendsEmployeeNote,
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 16),
                if (_searching)
                  const CircularProgressIndicator()
                else if (_error != null)
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ObicColors.inkOf(context),
                      height: 1.4,
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final u = _results[i];
                        final id = u['id'] as String?;
                        final isFriend = id != null && _friendIds.contains(id);
                        final isWaiting =
                            id != null && _outgoingPendingIds.contains(id);
                        Widget trailing;
                        if (isFriend) {
                          trailing = Text(
                            l10n.friendsAlreadyFriends,
                            style: TextStyle(
                              color: ObicColors.mutedOf(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          );
                        } else if (isWaiting) {
                          trailing = Text(
                            l10n.friendsWaiting,
                            style: TextStyle(
                              color: ObicColors.mutedOf(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          );
                        } else {
                          trailing = FilledButton(
                            onPressed: _busy ? null : () => _add(u),
                            child: Text(l10n.friendsAdd),
                          );
                        }
                        return Card(
                          elevation: 0,
                          color: ObicColors.surfaceOf(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: ObicColors.lineOf(context)),
                          ),
                          child: ListTile(
                            title: Text(
                              (u['name'] as String?) ?? '—',
                              style: TextStyle(
                                color: ObicColors.inkOf(context),
                              ),
                            ),
                            subtitle: _FriendMatchLine(
                              obicId: u['obicId'] as String?,
                              phone: u['phone'] as String?,
                              role: u['role'] as String?,
                            ),
                            trailing: trailing,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // My QR
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            children: [
              Text(
                l10n.friendsQrHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ObicColors.mutedOf(context),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ObicColors.lineOf(context)),
                    boxShadow: ObicColors.isDark(context)
                        ? const <BoxShadow>[]
                        : [
                            BoxShadow(
                              color: ObicColors.navy.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: qrData.isEmpty
                      ? SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 240,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: ObicColors.navy,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: ObicColors.navy,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                me?.name ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: ObicColors.titleOf(context),
                ),
              ),
              if ((me?.obicId ?? '').isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  '${l10n.profileObicId}: ${me!.obicId}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: ObicColors.inkOf(context),
                  ),
                ),
                SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: me.obicId!));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.profileObicIdCopied)),
                      );
                    },
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: ObicColors.blue,
                    ),
                    label: Text(
                      l10n.momentsCopyText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ObicColors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Scan / paste
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.friendsQrHint,
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _openScanner,
                  style: FilledButton.styleFrom(
                    backgroundColor: ObicColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(Icons.qr_code_scanner),
                  label: Text(l10n.friendsScanQr),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _paste,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: TextStyle(color: ObicColors.inkOf(context)),
                  decoration: InputDecoration(
                    hintText: l10n.friendsQrPayloadHint,
                    hintStyle: TextStyle(color: ObicColors.mutedOf(context)),
                    filled: true,
                    fillColor: ObicColors.surfaceOf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ObicColors.lineOf(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ObicColors.lineOf(context)),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : () => _handleQrRaw(_paste.text),
                  child: Text(l10n.friendsAdd),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.friendsScanQr),
        backgroundColor: Colors.black,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          final bars = capture.barcodes;
          if (bars.isEmpty) return;
          final raw = bars.first.rawValue;
          if (raw == null || raw.isEmpty) return;
          _done = true;
          Navigator.of(context).pop(raw);
        },
      ),
    );
  }
}

/// ID and phone stay left-to-right; a role label still follows the locale.
class _FriendMatchLine extends StatelessWidget {
  const _FriendMatchLine({this.obicId, this.phone, this.role});

  final String? obicId;
  final String? phone;
  final String? role;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: ObicColors.mutedOf(context));
    final id = obicId?.trim() ?? '';
    final mobile = phone?.trim() ?? '';
    final roleText = role?.trim() ?? '';
    final children = <Widget>[
      if (id.isNotEmpty) ObicIdentifierText('ID: $id', style: style),
      if (mobile.isNotEmpty) ObicIdentifierText(mobile, style: style),
      if (roleText.isNotEmpty) Text(roleText, style: style),
    ];
    if (children.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Text('·', style: style),
          children[i],
        ],
      ],
    );
  }
}
