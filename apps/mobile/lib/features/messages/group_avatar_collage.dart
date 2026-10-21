// Made by Dr Ali
// WeChat-style group / peer avatar collage (up to 4 faces).

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../moments/moment_avatar.dart';

/// WeChat: collage header only for real multi-party threads.
///
/// - `group` → always group UI
/// - `support` / `order` → group UI only when more than one *other* member
///   (e.g. customer + multiple staff)
/// - `direct` → always 1:1 (never collage of me + peer)
bool isWeChatGroupConversation({
  required String? kind,
  required int otherParticipantCount,
}) {
  final k = (kind ?? 'direct').trim().toLowerCase();
  if (k == 'group') return true;
  if (k == 'support' || k == 'order') {
    return otherParticipantCount > 1;
  }
  return false;
}

int countOtherParticipants({
  required List<dynamic>? participants,
  required String? myUserId,
}) {
  if (participants == null || participants.isEmpty) return 0;
  var n = 0;
  for (final p in participants) {
    if (p is! Map) continue;
    final id = p['userId']?.toString();
    if (myUserId != null && id == myUserId) continue;
    n++;
  }
  return n;
}

class GroupAvatarCollage extends StatelessWidget {
  const GroupAvatarCollage({
    super.key,
    required this.members,
    this.size = 48,
  });

  /// Each map: name, avatarUrl (optional).
  final List<({String name, String? avatarUrl})> members;
  final double size;

  @override
  Widget build(BuildContext context) {
    final list = members.take(4).toList();
    if (list.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ObicColors.blueSoftOf(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.groups_rounded, color: ObicColors.blue),
      );
    }
    if (list.length == 1) {
      return MomentAvatar(
        name: list.first.name,
        avatarUrl: list.first.avatarUrl,
        size: size,
        borderRadius: 8,
      );
    }

    final cell = (size - 2) / 2;
    Widget tile(({String name, String? avatarUrl}) m) => MomentAvatar(
          name: m.name,
          avatarUrl: m.avatarUrl,
          size: cell,
          borderRadius: 3,
        );

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: const Color(0xFFD8E0EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: list.length == 2
          ? Row(
              children: [
                Expanded(child: tile(list[0])),
                const SizedBox(width: 1),
                Expanded(child: tile(list[1])),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: tile(list[0])),
                      const SizedBox(width: 1),
                      Expanded(child: tile(list[1])),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: tile(list[2])),
                      const SizedBox(width: 1),
                      Expanded(
                        child: list.length > 3
                            ? tile(list[3])
                            : const ColoredBox(color: Color(0xFFE8F1FF)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Paragraph direction from the first strong letter.
/// Digits, emoji, and punctuation do not flip the line, so "hello مرحبا"
/// stays left-to-right and the Arabic word embeds inside it.
TextDirection chatTextDirection(String text) {
  for (final rune in text.runes) {
    if (_bidiRtl(rune)) return TextDirection.rtl;
    if (_bidiLtr(rune)) return TextDirection.ltr;
  }
  return TextDirection.ltr;
}

/// Empty fields follow the page. Typed fields follow [chatTextDirection].
TextDirection inputTextDirection(String text, TextDirection ambient) {
  if (text.trim().isEmpty) return ambient;
  return chatTextDirection(text);
}

bool _bidiRtl(int rune) {
  return (rune >= 0x0590 && rune <= 0x08FF) ||
      (rune >= 0xFB1D && rune <= 0xFDFF) ||
      (rune >= 0xFE70 && rune <= 0xFEFF);
}

bool _bidiLtr(int rune) {
  if (rune >= 0x0041 && rune <= 0x024F) return true;
  if (rune >= 0x0370 && rune <= 0x03FF) return true;
  if (rune >= 0x0400 && rune <= 0x052F) return true;
  if (rune >= 0x3040 && rune <= 0x30FF) return true;
  if (rune >= 0x3400 && rune <= 0x9FFF) return true;
  if (rune >= 0xAC00 && rune <= 0xD7AF) return true;
  if (rune >= 0xFF21 && rune <= 0xFF3A) return true;
  if (rune >= 0xFF41 && rune <= 0xFF5A) return true;
  return false;
}
