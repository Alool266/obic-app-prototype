// Made by Dr Ali
// SuperAdmin chat oversight — list / transcript / Join (audited).

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../messages/chat_day_separator.dart';
import '../messages/chat_screen.dart';
import 'admin_api.dart';

class AdminOversightScreen extends StatefulWidget {
  const AdminOversightScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AdminOversightScreen> createState() => _AdminOversightScreenState();
}

class _AdminOversightScreenState extends State<AdminOversightScreen> {
  final _api = AdminApi();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _threads = [];
  bool _loading = true;
  String? _error;
  String _kind = '';
  bool _includeFriends = false;

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

  bool get _ar => Directionality.of(context) == TextDirection.rtl;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      final rows = await _api.listOversightChats(
        token,
        kind: _kind.isEmpty ? null : _kind,
        q: _search.text.trim().isEmpty ? null : _search.text.trim(),
        includeFriends: _includeFriends,
      );
      if (!mounted) return;
      setState(() {
        _threads = rows;
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

  String _kindLabel(String? kind) {
    switch (kind) {
      case 'support':
        return _ar ? 'دعم' : 'Support';
      case 'order':
        return _ar ? 'طلب' : 'Order';
      case 'group':
        return _ar ? 'مجموعة' : 'Group';
      default:
        return _ar ? 'خاص' : 'Direct';
    }
  }

  String _threadTitle(Map<String, dynamic> t) {
    final title = (t['title'] as String?)?.trim();
    if (title != null && title.isNotEmpty) return title;
    return _kindLabel(t['kind'] as String?);
  }

  String _participantLine(Map<String, dynamic> t) {
    final parts = t['participants'];
    if (parts is! List) return '—';
    final names = <String>[];
    for (final p in parts) {
      if (p is Map) {
        final n = (p['name'] as String?)?.trim();
        if (n != null && n.isNotEmpty) names.add(n);
      }
    }
    return names.isEmpty ? '—' : names.join(' · ');
  }

  Future<void> _open(Map<String, dynamic> thread) async {
    final id = thread['id'] as String?;
    if (id == null) return;
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      final data = await _api.oversightTranscript(
        accessToken: token,
        conversationId: id,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _OversightTranscriptScreen(
            authController: widget.authController,
            thread: thread,
            data: data,
            onJoined: _load,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(_ar ? 'رقابة الدردشة' : 'Chat oversight'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _ar
                      ? 'دعم / طلبات / مجموعات — انضم كمشارك. محادثات الأصدقاء قراءة فقط.'
                      : 'Support / order / groups — Join as participant. Friend DMs read-only.',
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: _ar
                        ? 'بحث عن عميل / موظف…'
                        : 'Search customer / staff…',
                    filled: true,
                    fillColor: ObicColors.surfaceOf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ObicColors.line),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _load,
                    ),
                  ),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final e in [
                        ('', _ar ? 'الكل' : 'All'),
                        ('support', 'Support'),
                        ('order', 'Order'),
                        ('group', 'Group'),
                        ('direct', 'Direct'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(e.$2),
                            selected: _kind == e.$1,
                            onSelected: (_) {
                              setState(() => _kind = e.$1);
                              _load();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _ar
                        ? 'إظهار محادثات الأصدقاء (قراءة فقط)'
                        : 'Show friend DMs (read-only)',
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: _includeFriends,
                  onChanged: (v) {
                    setState(() => _includeFriends = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: _threads.isEmpty ? 1 : _threads.length,
                      itemBuilder: (_, i) {
                        if (_threads.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _ar
                                  ? 'لا محادثات للرقابة بعد'
                                  : 'No oversight threads yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ObicColors.mutedOf(context),
                              ),
                            ),
                          );
                        }
                        final t = _threads[i];
                        final last = t['lastMessage'] as Map?;
                        final friend = t['friendDm'] == true;
                        final member = t['iAmMember'] == true;
                        return Card(
                          elevation: 0,
                          color: ObicColors.card,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ObicColors.blueSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _kindLabel(t['kind'] as String?),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: ObicColors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _threadTitle(t),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (friend)
                                  Text(
                                    _ar ? 'قراءة' : 'RO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ObicColors.mutedOf(context),
                                    ),
                                  ),
                                if (member)
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: ObicColors.blue,
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '${_participantLine(t)}\n'
                              '${(last?['body'] as String?) ?? (_ar ? 'لا رسائل' : 'No messages')}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            onTap: () => _open(t),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OversightTranscriptScreen extends StatefulWidget {
  const _OversightTranscriptScreen({
    required this.authController,
    required this.thread,
    required this.data,
    required this.onJoined,
  });

  final AuthController authController;
  final Map<String, dynamic> thread;
  final Map<String, dynamic> data;
  final VoidCallback onJoined;

  @override
  State<_OversightTranscriptScreen> createState() =>
      _OversightTranscriptScreenState();
}

class _OversightTranscriptScreenState
    extends State<_OversightTranscriptScreen> {
  final _api = AdminApi();
  late Map<String, dynamic> _data;
  bool _joinBusy = false;
  bool _aiBusy = false;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.data);
  }

  bool get _ar => Directionality.of(context) == TextDirection.rtl;

  List<Map<String, dynamic>> get _messages {
    final raw = _data['messages'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  bool get _joinable =>
      _data['joinable'] == true &&
      _data['friendDm'] != true &&
      _data['iAmMember'] != true;

  bool get _iAmMember => _data['iAmMember'] == true;

  String get _kind =>
      (_data['kind'] as String?) ?? (widget.thread['kind'] as String?) ?? '';

  Future<void> _join() async {
    final id = widget.thread['id'] as String?;
    if (id == null) return;
    setState(() => _joinBusy = true);
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      final res = await _api.joinOversightChat(
        accessToken: token,
        conversationId: id,
      );
      if (!mounted) return;
      setState(() {
        _data = {
          ..._data,
          'iAmMember': true,
          'joinable': true,
          if (res['participants'] != null) 'participants': res['participants'],
        };
        _joinBusy = false;
      });
      widget.onJoined();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ar ? 'انضممت إلى المحادثة' : 'Joined conversation'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _joinBusy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openAsParticipant() async {
    final id = widget.thread['id'] as String?;
    if (id == null) return;
    if (!_iAmMember) {
      await _join();
      if (!_iAmMember) return;
    }
    if (!mounted) return;
    final title = (widget.thread['title'] as String?)?.trim().isNotEmpty == true
        ? widget.thread['title'] as String
        : (_ar ? 'محادثة' : 'Chat');
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          authController: widget.authController,
          threadId: id,
          title: title,
        ),
      ),
    );
  }

  Future<void> _toggleAi() async {
    final id = widget.thread['id'] as String?;
    if (id == null) return;
    if (_kind != 'support' && _kind != 'order') return;
    setState(() => _aiBusy = true);
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      final next = _data['aiAutoReplyEnabled'] != true;
      final res = await _api.setThreadAiAutoReply(
        accessToken: token,
        conversationId: id,
        enabled: next,
      );
      if (!mounted) return;
      setState(() {
        _data = {
          ..._data,
          'aiAutoReplyEnabled': res['aiAutoReplyEnabled'] == true,
        };
        _aiBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiBusy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final msgs = _messages;
    final timeline = <Object>[];
    DateTime? prevAt;
    for (final m in msgs) {
      final at = parseChatCreatedAt(m['createdAt']);
      if (at != null && chatNeedsDaySeparator(prevAt, at)) {
        timeline.add(
          chatDaySeparatorLabel(at, l10n: l10n, localeName: localeName),
        );
      }
      if (at != null) prevAt = at;
      timeline.add(m);
    }

    final parts = _data['participants'];
    final partLine = () {
      if (parts is! List) return '—';
      return parts
          .whereType<Map>()
          .map((p) => (p['name'] as String?) ?? '')
          .where((n) => n.isNotEmpty)
          .join(' · ');
    }();

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(_ar ? 'سجل المحادثة' : 'Transcript'),
        actions: [
          if (_kind == 'support' || _kind == 'order')
            TextButton(
              onPressed: _aiBusy ? null : _toggleAi,
              child: Text(
                _data['aiAutoReplyEnabled'] == true
                    ? (_ar ? 'AI: تشغيل' : 'AI: on')
                    : (_ar ? 'AI: إيقاف' : 'AI: off'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  partLine,
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 13,
                  ),
                ),
                if (_data['friendDm'] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _ar
                          ? 'محادثة أصدقاء — قراءة فقط'
                          : 'Friend DM — read-only',
                      style: TextStyle(
                        color: ObicColors.mutedOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_joinable)
                      FilledButton(
                        onPressed: _joinBusy ? null : _join,
                        child: Text(_ar ? 'انضم' : 'Join'),
                      ),
                    if (_iAmMember || _joinable)
                      OutlinedButton(
                        onPressed: _joinBusy ? null : _openAsParticipant,
                        child: Text(_ar ? 'فتح كمشارك' : 'Open as participant'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: timeline.isEmpty ? 1 : timeline.length,
              itemBuilder: (_, i) {
                if (timeline.isEmpty) {
                  return Text(
                    _ar ? 'لا رسائل' : 'No messages',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ObicColors.mutedOf(context)),
                  );
                }
                final item = timeline[i];
                if (item is String) {
                  return ChatDaySeparatorChip(label: item);
                }
                final m = item as Map<String, dynamic>;
                final isAi = m['isAi'] == true;
                final name = isAi
                    ? 'OBIC AI'
                    : ((m['senderName'] as String?) ??
                          (m['senderId'] as String?)?.substring(0, 8) ??
                          '—');
                final at = parseChatCreatedAt(m['createdAt']);
                final time = at == null
                    ? ''
                    : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ObicColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ObicColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ObicColors.mutedOf(context),
                              ),
                            ),
                          ),
                          if (time.isNotEmpty)
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: ObicColors.mutedOf(context),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (m['body'] as String?) ?? '—',
                        style: TextStyle(
                          color: ObicColors.titleOf(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
