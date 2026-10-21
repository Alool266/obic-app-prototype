// Made by Dr Ali
// Searchable friend list with checkmarks — shared by Moments privacy on Android and iOS.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/offline_cache_store.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';
import 'moment_avatar.dart';

const _kCheckGreen = Color(0xFF07C160);

/// Batch friend pick for Moments privacy (partial / exclude).
/// Returns the chosen ids, or null if the route is dismissed without a result.
Future<List<String>?> pickMomentFriends({
  required BuildContext context,
  required AuthController authController,
  required String title,
  required List<String> initiallySelected,
}) {
  return Navigator.of(context).push<List<String>>(
    MaterialPageRoute(
      builder: (_) => MomentFriendPickerScreen(
        authController: authController,
        title: title,
        selectedIds: initiallySelected.toSet(),
        popWithSelection: true,
        onToggle: (friendId, next) async => true,
      ),
    ),
  );
}

class MomentFriendPickerScreen extends StatefulWidget {
  const MomentFriendPickerScreen({
    super.key,
    required this.authController,
    required this.title,
    required this.selectedIds,
    required this.onToggle,
    this.popWithSelection = false,
  });

  final AuthController authController;
  final String title;
  final Set<String> selectedIds;

  /// When true, leaving the screen returns the current selection.
  final bool popWithSelection;

  /// [next] is the desired checked state. Return false to revert the mark.
  final Future<bool> Function(String friendId, bool next) onToggle;

  @override
  State<MomentFriendPickerScreen> createState() =>
      _MomentFriendPickerScreenState();
}

class _MomentFriendPickerScreenState extends State<MomentFriendPickerScreen> {
  final _api = SocialApi();
  List<_Person> _people = [];
  late Set<String> _selected;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selectedIds};
    _load();
  }

  Future<void> _load() async {
    final uid = widget.authController.user?.id ?? '';
    if (uid.isNotEmpty) {
      final cached = await OfflineCacheStore.instance.loadFriends(uid);
      if (!mounted) return;
      if (cached != null) {
        setState(() {
          _people = _peopleFrom(cached);
          _loading = false;
        });
      }
    }
    try {
      final token = await widget.authController.accessToken();
      if (token == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final rows = await _api.listFriends(token);
      if (uid.isNotEmpty) {
        await OfflineCacheStore.instance.saveFriends(uid, rows);
      }
      if (!mounted) return;
      setState(() {
        _people = _peopleFrom(rows);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _tap(_Person person) async {
    final next = !_selected.contains(person.id);
    setState(() {
      if (next) {
        _selected.add(person.id);
      } else {
        _selected.remove(person.id);
      }
    });
    var ok = false;
    try {
      ok = await widget.onToggle(person.id, next);
    } catch (_) {
      ok = false;
    }
    if (!mounted || ok) return;
    setState(() {
      if (next) {
        _selected.remove(person.id);
      } else {
        _selected.add(person.id);
      }
    });
  }

  List<(String, List<_Person>)> _sections() {
    final q = _query.toLowerCase();
    final people = <_Person>[];
    for (final person in _people) {
      if (q.isNotEmpty &&
          !person.name.toLowerCase().contains(q) &&
          !person.phone.contains(q)) {
        continue;
      }
      people.add(person);
    }
    people.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    final grouped = <String, List<_Person>>{};
    for (final person in people) {
      grouped.putIfAbsent(_sectionKey(person.name), () => []).add(person);
    }
    final keys = grouped.keys.toList()..sort();
    return [for (final k in keys) (k, grouped[k]!)];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = _sections();
    final scaffold = Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading && _people.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.friendsPickerSearch,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: ObicColors.surfaceOf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (_people.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Text(
                      l10n.friendsNoFriends,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ObicColors.mutedOf(context)),
                    ),
                  )
                else if (sections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Text(
                      l10n.friendsPickerEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ObicColors.mutedOf(context)),
                    ),
                  )
                else
                  for (final section in sections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Text(
                        section.$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ObicColors.mutedOf(context),
                        ),
                      ),
                    ),
                    Material(
                      color: ObicColors.surfaceOf(context),
                      child: Column(
                        children: [
                          for (var i = 0; i < section.$2.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 108,
                                color: ObicColors.lineOf(context),
                              ),
                            _CheckRow(
                              person: section.$2[i],
                              checked: _selected.contains(section.$2[i].id),
                              onTap: () => _tap(section.$2[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
              ],
            ),
    );
    if (!widget.popWithSelection) return scaffold;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_selected.toList());
      },
      child: scaffold,
    );
  }
}

class _Person {
  const _Person({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String phone;
  final String? avatarUrl;
}

List<_Person> _peopleFrom(List<Map<String, dynamic>> rows) {
  final people = <_Person>[];
  for (final row in rows) {
    final user = row['user'];
    final map =
        user is Map ? Map<String, dynamic>.from(user) : <String, dynamic>{};
    final id = (map['id'] as String?) ?? '';
    if (id.isEmpty) continue;
    final name = (map['name'] as String?)?.trim();
    people.add(
      _Person(
        id: id,
        name: (name == null || name.isEmpty) ? '—' : name,
        phone: (map['phone'] as String?) ?? '',
        avatarUrl: map['avatarUrl'] as String?,
      ),
    );
  }
  return people;
}

String _sectionKey(String name) {
  if (name.isEmpty || name == '—') return '#';
  final ch = name.substring(0, 1);
  if (RegExp(r'^[A-Za-z]$').hasMatch(ch)) return ch.toUpperCase();
  return ch;
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.person,
    required this.checked,
    required this.onTap,
  });

  final _Person person;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_circle : Icons.circle_outlined,
              color: checked ? _kCheckGreen : ObicColors.mutedOf(context),
              size: 24,
            ),
            const SizedBox(width: 12),
            MomentAvatar(
              name: person.name,
              avatarUrl: person.avatarUrl,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                person.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: ObicColors.titleOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
