// Made by Dr Ali
// Pick who to ring in a group call. Video holds 9 people, voice holds 16.

import 'package:flutter/material.dart';

import '../../core/obic_phrases.dart';
import '../../theme/obic_colors.dart';
import '../moments/moment_avatar.dart';

/// Returns the other members to invite, or null if cancelled.
Future<List<String>?> pickGroupCallMembers(
  BuildContext context, {
  required List<Map<String, dynamic>> members,
  required String? myUserId,
  required bool video,
  Set<String> alreadyIn = const {},
}) {
  final others = <Map<String, dynamic>>[];
  for (final row in members) {
    final id = row['userId']?.toString() ?? row['id']?.toString() ?? '';
    if (id.isEmpty || id == myUserId || alreadyIn.contains(id)) continue;
    others.add(row);
  }
  final cap = (video ? 8 : 15) - alreadyIn.length;
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ObicColors.surfaceOf(context),
    builder: (ctx) => _Picker(others: others, cap: cap < 0 ? 0 : cap, video: video),
  );
}

class _Picker extends StatefulWidget {
  const _Picker({
    required this.others,
    required this.cap,
    required this.video,
  });

  final List<Map<String, dynamic>> others;
  final int cap;
  final bool video;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  final Set<String> _picked = {};

  void _toggle(String id) {
    setState(() {
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else if (_picked.length < widget.cap) {
        _picked.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxPeople = widget.video ? 9 : 16;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      obicPhrase(
                        context,
                        ar: widget.video ? 'مكالمة فيديو' : 'مكالمة صوتية',
                        en: widget.video ? 'Video call' : 'Voice call',
                        zh: widget.video ? '视频通话' : '语音通话',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ObicColors.titleOf(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.others.isEmpty || widget.cap == 0
                        ? null
                        : () {
                            setState(() {
                              _picked
                                ..clear()
                                ..addAll(
                                  widget.others
                                      .take(widget.cap)
                                      .map(
                                        (row) =>
                                            row['userId']?.toString() ??
                                            row['id']?.toString() ??
                                            '',
                                      )
                                      .where((id) => id.isNotEmpty),
                                );
                            });
                          },
                    child: Text(
                      obicPhrase(context, ar: 'تحديد الكل', en: 'Select all', zh: '全选'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                obicPhrase(
                  context,
                  ar: 'حتى $maxPeople أشخاص',
                  en: 'Up to $maxPeople people',
                  zh: '最多 $maxPeople 人',
                ),
                style: TextStyle(color: ObicColors.mutedOf(context), fontSize: 13),
              ),
            ),
            Expanded(
              child: widget.others.isEmpty
                  ? Center(
                      child: Text(
                        obicPhrase(
                          context,
                          ar: 'لا يوجد أعضاء لإضافتهم',
                          en: 'No members to add',
                          zh: '没有可添加的成员',
                        ),
                        style: TextStyle(color: ObicColors.mutedOf(context)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.others.length,
                      itemBuilder: (context, i) {
                        final row = widget.others[i];
                        final id =
                            row['userId']?.toString() ?? row['id']?.toString() ?? '';
                        final name = (row['name'] as String?)?.trim().isNotEmpty == true
                            ? row['name'] as String
                            : 'OBIC';
                        final on = _picked.contains(id);
                        return CheckboxListTile(
                          value: on,
                          onChanged: widget.cap == 0 ? null : (_) => _toggle(id),
                          activeColor: ObicColors.blue,
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ObicColors.inkOf(context)),
                          ),
                          secondary: MomentAvatar(
                            name: name,
                            avatarUrl: row['avatarUrl'] as String?,
                            size: 40,
                            borderRadius: 8,
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        obicPhrase(context, ar: 'إلغاء', en: 'Cancel', zh: '取消'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _picked.isEmpty
                          ? null
                          : () => Navigator.pop(context, _picked.toList()),
                      style: FilledButton.styleFrom(backgroundColor: ObicColors.blue),
                      child: Text(
                        obicPhrase(context, ar: 'اتصال', en: 'Call', zh: '呼叫'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
