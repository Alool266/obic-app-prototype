// Made by Dr Ali
// WeChat Contacts (通讯录): search, shortcut rows, one A–Z row per person, letter index.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/connectivity_service.dart';
import '../../core/offline_cache_store.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../me/friend_permissions_screen.dart';
import '../messages/chat_screen.dart';
import '../moments/moment_avatar.dart';
import '../shell/tab_badge.dart';
import '../social/social_api.dart';
import 'add_friend_screen.dart';
import '../approvals/approvals_screen.dart';
import '../attendance/attendance_screen.dart';
import '../directory/directory_screen.dart';
import '../reports/reports_screen.dart';
import '../office_forms/office_forms_screen.dart';
import '../collection_forms/collection_forms_screen.dart';
import '../meeting_rooms/meeting_rooms_screen.dart';
import '../roster/roster_screen.dart';
import '../payslips/payslips_screen.dart';
import '../company_contacts/company_contacts_screen.dart';
import '../company_tags/company_tags_screen.dart';
import '../company_groups/company_groups_screen.dart';
import '../company_welcomes/company_welcomes_screen.dart';
import '../quick_replies/quick_replies_screen.dart';
import '../company_handovers/company_handovers_screen.dart';
import '../company_drive/company_drive_screen.dart';
import '../company_documents/company_documents_screen.dart';
import '../company_spreadsheets/company_spreadsheets_screen.dart';
import '../company_calendar/company_calendar_screen.dart';
import '../company_mail/company_mail_screen.dart';
import '../company_meetings/company_meetings_screen.dart';
import '../company_file_answers/company_file_answers_screen.dart';
import '../company_apps/company_apps_screen.dart';
import 'contact_profile_screen.dart';
import 'friend_remark_store.dart';
import 'group_chats_screen.dart';
import 'new_friends_screen.dart';
import 'starred_friends_store.dart';

const double _kTopRowHeight = 56;
const double _kTopGap = 8;
const double _kSectionHeaderHeight = 28;
const double _kFriendRowHeight = 56;
const int _kTopRowCount = 3;
const String _kStarJump = '\u0000star';

/// A–Z rail on the trailing edge of the names list. It does not cover search.
const double _kIndexRailWidth = 28;

/// Room under the contact count: above the 68px tab bar and the AI bubble
/// (bubble bottom inset is system + 68 + 72, bubble is 52px tall).
const double _kBottomClearance = 148;

/// First character of [name]. Latin letters fold to A–Z.
/// Digits, punctuation, and emoji use `#`. Arabic, Chinese, and other
/// letters keep that character (no pinyin / characters package).
String friendSectionKey(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '#';
  final first = trimmed.runes.first;
  if (first < 0x20 || first == 0x7F) return '#';
  var ch = String.fromCharCode(first);
  final upper = ch.toUpperCase();
  if (upper.runes.length == 1) ch = upper;
  final unit = ch.runes.first;
  if (unit >= 0x30 && unit <= 0x39) return '#';
  if (unit < 0x80 && (unit < 0x41 || unit > 0x5A)) return '#';
  if (unit >= 0x1F000) return '#';
  return ch;
}

int compareFriendSectionKeys(String a, String b) {
  int rank(String key) {
    if (key == '#') return 2;
    if (key.length == 1) {
      final unit = key.codeUnitAt(0);
      if (unit >= 0x41 && unit <= 0x5A) return 0;
    }
    return 1;
  }

  final byRank = rank(a).compareTo(rank(b));
  if (byRank != 0) return byRank;
  return a.compareTo(b);
}

String friendDisplayName(Map<String, dynamic> friend) {
  final user = friend['user'];
  if (user is! Map) return '';
  return (user['name'] as String?)?.trim() ?? '';
}

String? friendUserId(Map<String, dynamic> friend) {
  final user = friend['user'];
  if (user is! Map) return null;
  final id = user['id']?.toString();
  if (id == null || id.isEmpty) return null;
  return id;
}

String? friendAvatarUrl(Map<String, dynamic> friend) {
  final user = friend['user'];
  if (user is! Map) return null;
  final url = user['avatarUrl'] as String?;
  if (url == null || url.isEmpty) return null;
  return url;
}

/// Friendship time (`since` / accepted / created). Ignores the user account date.
DateTime? friendAddedAt(Map<String, dynamic> friend) {
  for (final key in const ['since', 'acceptedAt', 'createdAt']) {
    final raw = friend[key];
    if (raw == null) continue;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

bool friendListHasAddedAt(Iterable<Map<String, dynamic>> friends) {
  for (final friend in friends) {
    if (friendAddedAt(friend) != null) return true;
  }
  return false;
}

List<(String, List<Map<String, dynamic>>)> friendAlphaSections(
  List<Map<String, dynamic>> friends, {
  String Function(Map<String, dynamic> friend)? nameOf,
}) {
  final labelOf = nameOf ?? friendDisplayName;
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final friend in friends) {
    final key = friendSectionKey(labelOf(friend));
    grouped.putIfAbsent(key, () => []).add(friend);
  }
  for (final rows in grouped.values) {
    rows.sort(
      (a, b) => labelOf(a).toLowerCase().compareTo(labelOf(b).toLowerCase()),
    );
  }
  final keys = grouped.keys.toList()..sort(compareFriendSectionKeys);
  return [for (final key in keys) (key, grouped[key]!)];
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({
    super.key,
    required this.authController,
    this.openNewFriends = false,
    this.embedded = false,
    this.isActive = true,
  });

  final AuthController authController;

  /// When true (e.g. notification tap), open New Friends after load.
  final bool openNewFriends;

  /// Bottom-tab host. Do not pop the shell if the guest dismisses sign-in.
  final bool embedded;

  /// When [embedded], load only after this tab is selected.
  final bool isActive;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _api = SocialApi();
  final _scroll = ScrollController();
  final _search = TextEditingController();

  /// Space above the letter index while the shortcut rows are still on screen.
  final _railTop = ValueNotifier<double>(0);

  int get _topRowCount => widget.authController.isStaffRole ? 26 : _kTopRowCount;

  double get _shortcutBlockHeight =>
      _kTopRowHeight * _topRowCount + _kTopGap;
  List<Map<String, dynamic>> _friends = [];
  int _pendingIncoming = 0;
  bool _loading = true;
  String? _error;
  bool _openedNewFriends = false;
  String _query = '';
  String? _bubble;
  Timer? _bubbleTimer;
  bool _bootstrapping = false;
  bool? _wasAuthed;

  @override
  void initState() {
    super.initState();
    _railTop.value = _shortcutBlockHeight;
    _scroll.addListener(_onContactsScroll);
    StarredFriendsStore.instance.addListener(_onStars);
    FriendRemarkStore.instance.addListener(_onStars);
    if (widget.embedded) {
      _wasAuthed = widget.authController.isAuthenticated;
      widget.authController.addListener(_onAuth);
      if (widget.isActive) unawaited(_bootstrap());
    } else {
      unawaited(_bootstrap());
    }
  }

  @override
  void didUpdateWidget(FriendsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.embedded && widget.isActive && !oldWidget.isActive) {
      unawaited(_bootstrap());
    }
  }

  @override
  void dispose() {
    if (widget.embedded) {
      widget.authController.removeListener(_onAuth);
    }
    StarredFriendsStore.instance.removeListener(_onStars);
    FriendRemarkStore.instance.removeListener(_onStars);
    _bubbleTimer?.cancel();
    _scroll.removeListener(_onContactsScroll);
    _scroll.dispose();
    _search.dispose();
    _railTop.dispose();
    super.dispose();
  }

  void _onAuth() {
    if (!mounted || !widget.embedded || !widget.isActive) return;
    final authed = widget.authController.isAuthenticated;
    if (_wasAuthed == authed) return;
    _wasAuthed = authed;
    if (authed) {
      if (!_bootstrapping) unawaited(_load());
      return;
    }
    setState(() {
      _friends = [];
      _pendingIncoming = 0;
      _loading = false;
      _error = null;
    });
  }

  void _onStars() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    if (_bootstrapping) return;
    _bootstrapping = true;
    try {
      await _bootstrapInner();
    } finally {
      _bootstrapping = false;
    }
  }

  Future<void> _bootstrapInner() async {
    final ok = await requireAuth(context, widget.authController);
    if (!mounted) return;
    if (!ok) {
      if (widget.embedded) {
        setState(() => _loading = false);
        return;
      }
      Navigator.of(context).maybePop();
      return;
    }
    final uid = widget.authController.user?.id;
    if (uid != null && uid.isNotEmpty) {
      await StarredFriendsStore.instance.loadFor(uid);
      await FriendRemarkStore.instance.loadFor(uid);
    }
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    if (widget.openNewFriends && !_openedNewFriends) {
      _openedNewFriends = true;
      await _openNewFriends();
    }
  }

  Future<void> _load() async {
    final uid = widget.authController.user?.id;
    if (uid != null && uid.isNotEmpty && _friends.isEmpty) {
      final cached = await OfflineCacheStore.instance.loadFriends(uid);
      if (!mounted) return;
      if (cached != null) {
    setState(() {
          _friends = cached;
          _loading = false;
          _error = null;
        });
      }
    }
    if (ConnectivityService.instance.isOffline) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = _friends.isEmpty;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null) throw AuthApiException('Not signed in');
      final friends = await _api.listFriends(token);
      final pending = await _api.pendingFriendRequestCount(token);
      final uid = widget.authController.user?.id;
      if (uid != null && uid.isNotEmpty) {
        await OfflineCacheStore.instance.saveFriends(uid, friends);
      }
      if (!mounted) return;
      setState(() {
        _friends = friends;
        _pendingIncoming = pending;
        _loading = false;
      });
    } catch (e) {
      final uid = widget.authController.user?.id;
      final cached = uid == null || uid.isEmpty
          ? null
          : await OfflineCacheStore.instance.loadFriends(uid);
      if (!mounted) return;
      if (cached != null) {
        setState(() {
          _friends = cached;
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

  Future<void> _openNewFriends() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NewFriendsScreen(authController: widget.authController),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openGroups() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupChatsScreen(authController: widget.authController),
      ),
    );
  }

  Future<void> _chatWith(String peerUserId, String name) async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      final thread = await _api.openDirectThread(
        accessToken: token,
        peerUserId: peerUserId,
      );
      final id = thread['id'] as String?;
      if (id == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            authController: widget.authController,
            threadId: id,
            title: name,
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

  String _labelOf(Map<String, dynamic> friend) {
    final id = friendUserId(friend);
    final remark = id == null ? null : FriendRemarkStore.instance.remarkFor(id);
    if (remark != null && remark.isNotEmpty) return remark;
    return friendDisplayName(friend);
  }

  /// One row per person even if the API returns the same friend twice.
  List<Map<String, dynamic>> _uniqueFriends(
    List<Map<String, dynamic>> friends,
  ) {
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final friend in friends) {
      final id = friendUserId(friend);
      if (id != null && !seen.add(id)) continue;
      unique.add(friend);
    }
    return unique;
  }

  List<(String, List<Map<String, dynamic>>)> _sectionsOf(
    List<Map<String, dynamic>> friends,
  ) {
    final sections = friendAlphaSections(friends, nameOf: _labelOf);
    return [
      for (final section in sections)
        if (section.$2.isNotEmpty) section,
    ];
  }

  List<Map<String, dynamic>> get _visibleFriends {
    final unique = _uniqueFriends(_friends);
    if (_query.isEmpty) return unique;
    final q = _query.toLowerCase();
    return unique.where((friend) {
      final legal = friendDisplayName(friend).toLowerCase();
      final shown = _labelOf(friend).toLowerCase();
      return legal.contains(q) || shown.contains(q);
    }).toList();
  }

  bool _isRecent(Map<String, dynamic> friend) {
    if (!friendListHasAddedAt(_friends)) return false;
    final at = friendAddedAt(friend);
    if (at == null) return false;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return !at.isBefore(cutoff);
  }

  /// Letter of the first starred friend in A–Z order. Null when nobody is starred.
  String? _firstStarredSection() {
    for (final section in _sectionsOf(_friends)) {
      for (final friend in section.$2) {
        final id = friendUserId(friend);
        if (id != null && StarredFriendsStore.instance.isStarred(id)) {
          return section.$1;
        }
      }
    }
    return null;
  }

  /// Shortcut block still visible above the names. The index starts under it.
  double get _railTopInset {
    if (_query.isNotEmpty) return 0;
    final block = _shortcutBlockHeight;
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final remain = block - offset;
    if (remain <= 0) return 0;
    return remain;
  }

  void _onContactsScroll() {
    _syncRailTop();
  }

  void _syncRailTop() {
    final next = _railTopInset;
    if (_railTop.value == next) return;
    _railTop.value = next;
  }

  double _offsetFor(String jumpId) {
    final browsing = _query.isEmpty;
    var y = browsing ? _shortcutBlockHeight : 0.0;
    if (jumpId == _kStarJump) {
      final section = _firstStarredSection();
      if (section == null) return y;
      jumpId = section;
    }
    for (final section in _sectionsOf(_visibleFriends)) {
      if (section.$1 == jumpId) return y;
      y += _kSectionHeaderHeight + section.$2.length * _kFriendRowHeight;
    }
    return y;
  }

  void _jumpTo(String jumpId) {
    if (!_scroll.hasClients) return;
    final target = _offsetFor(jumpId);
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(target.clamp(0, max));
  }

  void _onIndex(String token) {
    _bubbleTimer?.cancel();
    final jumpId = token == '★' ? _kStarJump : token;
    if (_bubble != token) {
      setState(() => _bubble = token);
    }
    _jumpTo(jumpId);
  }

  void _onIndexRelease() {
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() => _bubble = null);
    });
  }

  List<String> _indexLetters(
    List<(String, List<Map<String, dynamic>>)> sections,
  ) {
    final showStar = _query.isEmpty && _firstStarredSection() != null;
    return [if (showStar) '★', for (final section in sections) section.$1];
  }

  Future<void> _openProfile(Map<String, dynamic> friend) async {
    final id = friendUserId(friend);
    if (id == null) return;
    final user = friend['user'];
    final seed = user is Map ? Map<String, dynamic>.from(user) : null;
    final me = widget.authController.user?.id;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContactProfileScreen(
          authController: widget.authController,
          userId: id,
          seedUser: seed,
          allowCall: id != me,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _friendActions(Map<String, dynamic> friend) async {
    final id = friendUserId(friend);
    if (id == null) return;
    final name = _labelOf(friend);
    final shown = name.isEmpty ? '—' : name;
    final l10n = AppLocalizations.of(context);
    final starred = StarredFriendsStore.instance.isStarred(id);
    HapticFeedback.mediumImpact();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: ObicColors.surfaceOf(context),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.chat_bubble_outline,
                  color: ObicColors.blue,
                ),
                title: Text(l10n.friendsMessage),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _chatWith(id, shown);
                },
              ),
              ListTile(
                leading: Icon(
                  starred ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: ObicColors.blue,
                ),
                title: Text(starred ? l10n.friendsUnstar : l10n.friendsStar),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(StarredFriendsStore.instance.toggle(id));
                },
              ),
              ListTile(
                leading: Icon(Icons.tune_rounded, color: ObicColors.blue),
                title: Text(l10n.settingsFriendsPermissions),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FriendPermissionsScreen(
                        authController: widget.authController,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.embedded && !widget.authController.isAuthenticated) {
    return Scaffold(
        backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.friendsContactsTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.authRequiredBody, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => unawaited(_bootstrap()),
                  child: Text(l10n.authLogin),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final browsing = _query.isEmpty;
    final visible = _visibleFriends;
    final sections = _sectionsOf(visible);
    final letters = _indexLetters(sections);
    final footerCount = visible.length;

    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(l10n.friendsContactsTitle),
        actions: [
          IconButton(
            tooltip: l10n.friendsAdd,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AddFriendScreen(authController: widget.authController),
                ),
              );
              if (mounted) await _load();
            },
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _searchField(l10n),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
        onRefresh: _load,
                  child: _loading && _friends.isEmpty
            ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
                      : CustomScrollView(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            if (browsing)
                              SliverToBoxAdapter(child: _shortcutRows(l10n)),
                            for (final section in sections) ...[
                              _headerSliver(section.$1),
                              _friendSliver(section.$2),
                            ],
                  if (_error != null)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    4,
                                  ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: ObicColors.inkOf(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                              ),
                            if (visible.isEmpty)
                              SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 32,
                                  ),
                                  child: Text(
                                    browsing
                                        ? l10n.friendsEmpty
                                        : l10n.friendsPickerEmpty,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: ObicColors.mutedOf(context),
                                    ),
                                  ),
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  28,
                                  24,
                                  _kBottomClearance,
                                ),
                                child: Text(
                                  l10n.friendsContactsCount(footerCount),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ObicColors.mutedOf(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                if ((!_loading || _friends.isNotEmpty) && letters.isNotEmpty)
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    bottom: 0,
                    width: _kIndexRailWidth,
                    child: _indexRail(letters),
                  ),
                if (_bubble != null)
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ObicColors.navy.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _bubble!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _indexRail(List<String> letters) {
    return SizedBox(
      width: _kIndexRailWidth,
      child: ValueListenableBuilder<double>(
        valueListenable: _railTop,
        builder: (context, top, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight;
              final inset = top.clamp(0.0, maxH);
              final room = maxH - inset;
              final bottom = room <= 0
                  ? 0.0
                  : _kBottomClearance.clamp(0.0, room);
              return ClipRect(
                child: Padding(
                  padding: EdgeInsets.only(top: inset, bottom: bottom),
                  child: _LetterRail(
                    letters: letters,
                    active: _bubble,
                    onSelect: _onIndex,
                    onRelease: _onIndexRelease,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _searchField(AppLocalizations l10n) {
    final muted = ObicColors.mutedOf(context);
    final radius = BorderRadius.circular(20);
    OutlineInputBorder outline(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final idle = ObicColors.lineOf(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
      child: TextField(
        controller: _search,
        onChanged: (value) {
          setState(() => _query = value.trim());
          _syncRailTop();
        },
        textInputAction: TextInputAction.search,
        textAlign: TextAlign.start,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: ObicColors.blue,
        style: TextStyle(
          fontSize: 15,
          height: 1.2,
          color: ObicColors.inkOf(context),
        ),
        decoration: InputDecoration(
          isDense: true,
          constraints: const BoxConstraints(minHeight: 44),
          filled: true,
          fillColor: ObicColors.surfaceOf(context),
          hintText: l10n.friendsPickerSearch,
          hintStyle: TextStyle(color: muted, fontSize: 15, height: 1.2),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: muted),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.friendsCancel,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                    _syncRailTop();
                  },
                  icon: Icon(Icons.close_rounded, size: 18, color: muted),
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 44,
          ),
          contentPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 12, 0),
          border: outline(idle),
          enabledBorder: outline(idle),
          focusedBorder: outline(ObicColors.blue, 1.4),
          disabledBorder: outline(idle),
          errorBorder: outline(idle),
          focusedErrorBorder: outline(ObicColors.blue, 1.4),
        ),
      ),
    );
  }

  Widget _shortcutRows(AppLocalizations l10n) {
    return Column(
      children: [
        _shortcutRow(
          icon: Icons.person_add_alt_1,
          color: ObicColors.blue,
          title: l10n.friendsNewFriends,
          onTap: _openNewFriends,
          trailing: _pendingIncoming > 0
              ? ObicCountBadge(count: _pendingIncoming, compact: true)
              : null,
          divider: true,
        ),
        _shortcutRow(
          icon: Icons.groups_rounded,
          color: ObicColors.navy,
          title: l10n.friendsGroupChats,
          onTap: _openGroups,
          divider: true,
        ),
        _shortcutRow(
          icon: Icons.star_rounded,
          color: ObicColors.blueDeep,
          title: l10n.friendsStarred,
          onTap: () => _jumpTo(_kStarJump),
          divider: widget.authController.isStaffRole,
        ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.apartment_rounded,
            color: ObicColors.navy,
            title: l10n.directoryTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DirectoryScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.fact_check_outlined,
            color: ObicColors.blue,
            title: l10n.approvalsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ApprovalsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.schedule_rounded,
            color: ObicColors.blueDeep,
            title: l10n.attendanceTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AttendanceScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.assignment_outlined,
            color: ObicColors.navy,
            title: l10n.reportsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReportsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.article_outlined,
            color: ObicColors.blue,
            title: l10n.formsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OfficeFormsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.playlist_add_check_outlined,
            color: ObicColors.blueDeep,
            title: l10n.collectionTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CollectionFormsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.meeting_room_outlined,
            color: ObicColors.navy,
            title: l10n.roomsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MeetingRoomsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.badge_outlined,
            color: ObicColors.navy,
            title: l10n.rosterTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RosterScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.receipt_long_outlined,
            color: ObicColors.blueDeep,
            title: l10n.payslipsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PayslipsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.contact_page_outlined,
            color: ObicColors.navy,
            title: l10n.companyContactsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyContactsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.label_outline,
            color: ObicColors.blueDeep,
            title: l10n.companyTagsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyTagsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.folder_shared_outlined,
            color: ObicColors.navy,
            title: l10n.companyGroupsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyGroupsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.campaign_outlined,
            color: ObicColors.blueDeep,
            title: l10n.companyWelcomesTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyWelcomesScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.reply_outlined,
            color: ObicColors.navy,
            title: l10n.quickRepliesTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => QuickRepliesScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.swap_horiz,
            color: ObicColors.blueDeep,
            title: l10n.companyHandoverTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyHandoversScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.cloud_outlined,
            color: ObicColors.navy,
            title: l10n.companyDriveTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyDriveScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.description_outlined,
            color: ObicColors.blueDeep,
            title: l10n.companyDocumentsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyDocumentsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.table_chart_outlined,
            color: ObicColors.navy,
            title: l10n.companySpreadsheetsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanySpreadsheetsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.calendar_month_outlined,
            color: ObicColors.blueDeep,
            title: l10n.companyCalendarTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyCalendarScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.mail_outlined,
            color: ObicColors.navy,
            title: l10n.companyMailTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyMailScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.groups_outlined,
            color: ObicColors.blueDeep,
            title: l10n.companyMeetingsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyMeetingsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.auto_awesome,
            color: ObicColors.navy,
            title: l10n.companyFileAnswersTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyFileAnswersScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: true,
          ),
        if (widget.authController.isStaffRole)
          _shortcutRow(
            icon: Icons.apps_outlined,
            color: ObicColors.blueDeep,
            title: l10n.companyAppsTitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyAppsScreen(
                    authController: widget.authController,
                  ),
                ),
              );
            },
            divider: false,
          ),
        const SizedBox(height: _kTopGap),
      ],
    );
  }

  Widget _shortcutRow({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    required bool divider,
  }) {
    final line = ObicColors.lineOf(context);
    return Material(
      color: ObicColors.surfaceOf(context),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: _kTopRowHeight,
          decoration: BoxDecoration(
            border: divider
                ? Border(bottom: BorderSide(color: line, width: 0.5))
                : null,
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                alignment: Alignment.center,
                              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    color: ObicColors.inkOf(context),
                                ),
                              ),
                            ),
              ?trailing,
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _headerSliver(String label) {
    return SliverPersistentHeader(
      pinned: false,
      delegate: _PinnedHeader(
        label: label,
        background: ObicColors.canvasOf(context),
                      style: TextStyle(
                        fontSize: 13,
          fontWeight: FontWeight.w800,
                        color: ObicColors.mutedOf(context),
                      ),
                    ),
    );
  }

  Widget _friendSliver(List<Map<String, dynamic>> friends) {
    return SliverFixedExtentList(
      itemExtent: _kFriendRowHeight,
      delegate: SliverChildBuilderDelegate(
        (context, index) => _friendRow(friends[index]),
        childCount: friends.length,
      ),
    );
  }

  Widget _friendRow(Map<String, dynamic> friend) {
    final l10n = AppLocalizations.of(context);
    final name = _labelOf(friend);
    final shown = name.isEmpty ? '—' : name;
    final peerId = friendUserId(friend);
    final line = ObicColors.lineOf(context);
    final starred =
        peerId != null && StarredFriendsStore.instance.isStarred(peerId);
    final recent = _isRecent(friend);
                      return Material(
                        color: ObicColors.surfaceOf(context),
                        child: InkWell(
        onTap: peerId == null ? null : () => _openProfile(friend),
        onLongPress: peerId == null ? null : () => _friendActions(friend),
        child: SizedBox(
          height: _kFriendRowHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: line, width: 0.5)),
            ),
                          child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                16,
                0,
                16 + _kIndexRailWidth,
                0,
                            ),
                            child: Row(
                              children: [
                                MomentAvatar(
                    name: shown,
                    avatarUrl: friendAvatarUrl(friend),
                    size: 40,
                    borderRadius: 4,
                                ),
                                const SizedBox(width: 12),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                                    children: [
                        Flexible(
                          child: Text(
                            shown,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              color: ObicColors.inkOf(context),
                            ),
                          ),
                        ),
                        if (recent) ...[
                          const SizedBox(width: 8),
                                        Text(
                            l10n.friendsNewMark,
                                          style: TextStyle(
                                            fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ObicColors.blue,
                                          ),
                                        ),
                                    ],
                        if (starred) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFE6A817),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
                            ),
                          ),
                        ),
                      );
  }
}

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  _PinnedHeader({
    required this.label,
    required this.background,
    required this.style,
  });

  final String label;
  final Color background;
  final TextStyle style;

  @override
  double get minExtent => _kSectionHeaderHeight;

  @override
  double get maxExtent => _kSectionHeaderHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(
      height: _kSectionHeaderHeight,
      child: ColoredBox(
        color: background,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            16,
            0,
            16 + _kIndexRailWidth,
            0,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(label, style: style),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeader oldDelegate) {
    return oldDelegate.label != label ||
        oldDelegate.background != background ||
        oldDelegate.style != style;
  }
}

class _LetterRail extends StatelessWidget {
  const _LetterRail({
    required this.letters,
    required this.active,
    required this.onSelect,
    required this.onRelease,
  });

  final List<String> letters;
  final String? active;
  final ValueChanged<String> onSelect;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight * 0.82;
        final raw = letters.isEmpty ? 14.0 : available / letters.length;
        final slot = raw > 14 ? 14.0 : raw;
        final fontSize = (slot * 0.78).clamp(1.0, 11.0);
        return GestureDetector(
          onVerticalDragDown: (details) => _hit(details.localPosition.dy, slot),
          onVerticalDragUpdate: (details) =>
              _hit(details.localPosition.dy, slot),
          onVerticalDragEnd: (_) => onRelease(),
          onVerticalDragCancel: onRelease,
          onTapDown: (details) => _hit(details.localPosition.dy, slot),
          onTapUp: (_) => onRelease(),
          onTapCancel: onRelease,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final letter in letters)
                  SizedBox(
                    width: 22,
                    height: slot,
                    child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 1,
                          fontWeight: letter == active
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: letter == active
                              ? ObicColors.blue
                              : ObicColors.mutedOf(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
        );
      },
    );
  }

  void _hit(double dy, double slot) {
    if (letters.isEmpty || slot <= 0) return;
    final index = (dy / slot).floor().clamp(0, letters.length - 1);
    onSelect(letters[index]);
  }
}
