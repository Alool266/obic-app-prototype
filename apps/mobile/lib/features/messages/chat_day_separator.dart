// Made by Dr Ali
// WeChat-style day chips between message groups (Today / Yesterday / full date).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';

/// Local calendar day for [dt] (strips time).
DateTime chatCalendarDay(DateTime dt) =>
    DateTime(dt.year, dt.month, dt.day);

/// Parse API / cache `createdAt` (ISO string or DateTime).
DateTime? parseChatCreatedAt(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw.toLocal();
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw)?.toLocal();
  }
  return null;
}

/// WeChat-style label: Today / Yesterday / localized full date.
String chatDaySeparatorLabel(
  DateTime when, {
  required AppLocalizations l10n,
  required String localeName,
  DateTime? now,
}) {
  final local = when.toLocal();
  final day = chatCalendarDay(local);
  final n = now ?? DateTime.now();
  final today = chatCalendarDay(n);
  final yesterday = today.subtract(const Duration(days: 1));

  if (day == today) return l10n.chatDayToday;
  if (day == yesterday) return l10n.chatDayYesterday;

  // Full date in app locale (AR / EN / ZH).
  try {
    return DateFormat.yMMMEd(localeName).format(local);
  } catch (_) {
    return DateFormat.yMMMd().format(local);
  }
}

/// True when [current] is on a different calendar day than [previous].
bool chatNeedsDaySeparator(DateTime? previous, DateTime current) {
  if (previous == null) return true;
  return chatCalendarDay(previous) != chatCalendarDay(current);
}

/// Centered grey pill — matches status notes / WeChat date chips.
class ChatDaySeparatorChip extends StatelessWidget {
  const ChatDaySeparatorChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: ObicColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ObicColors.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: ObicColors.mutedOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
