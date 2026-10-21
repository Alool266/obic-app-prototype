// Made by Dr Ali
// WeChat-style chat row: avatar, preview, time, mute, swipe actions.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';

enum ChatListFilter { all, unread, groups, services }

String chatListFilterLabel(ChatListFilter filter, AppLocalizations l10n) {
  switch (filter) {
    case ChatListFilter.all:
      return l10n.messagesFilterAll;
    case ChatListFilter.unread:
      return l10n.messagesFilterUnread;
    case ChatListFilter.groups:
      return l10n.messagesFilterGroups;
    case ChatListFilter.services:
      return l10n.messagesFilterServices;
  }
}

/// Last activity: last message time, then thread `updatedAt`.
DateTime? threadActivityAt(Map<String, dynamic> thread) {
  final last = thread['lastMessage'];
  if (last is Map) {
    final raw = last['createdAt']?.toString();
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    if (parsed != null) return parsed;
  }
  final updated = thread['updatedAt']?.toString();
  if (updated == null) return null;
  return DateTime.tryParse(updated);
}

/// Pinned threads stay above the rest; both groups sort by last activity.
int compareChatThreads(Map<String, dynamic> a, Map<String, dynamic> b) {
  final pin = (b['pinned'] == true ? 1 : 0) - (a['pinned'] == true ? 1 : 0);
  if (pin != 0) return pin;
  final ta = threadActivityAt(a)?.millisecondsSinceEpoch ?? 0;
  final tb = threadActivityAt(b)?.millisecondsSinceEpoch ?? 0;
  return tb.compareTo(ta);
}

/// Today = clock, yesterday, weekday within a week, otherwise a short date.
String formatChatListTime(
  BuildContext context,
  DateTime instant,
  AppLocalizations l10n,
) {
  final local = instant.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }
  if (diff == 1) return l10n.chatTimeYesterday;
  if (diff < 7) {
    switch (local.weekday) {
      case DateTime.monday:
        return l10n.chatWeekdayMon;
      case DateTime.tuesday:
        return l10n.chatWeekdayTue;
      case DateTime.wednesday:
        return l10n.chatWeekdayWed;
      case DateTime.thursday:
        return l10n.chatWeekdayThu;
      case DateTime.friday:
        return l10n.chatWeekdayFri;
      case DateTime.saturday:
        return l10n.chatWeekdaySat;
      case DateTime.sunday:
        return l10n.chatWeekdaySun;
      default:
        final int unexpected = local.weekday;
        return '$unexpected';
    }
  }
  if (local.year == now.year) {
    return '${local.month}/${local.day}';
  }
  return '${local.year}/${local.month}/${local.day}';
}

class ChatSwipeAction {
  const ChatSwipeAction({
    required this.label,
    required this.background,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final VoidCallback onPressed;
}

class ChatListFilterBar extends StatelessWidget {
  const ChatListFilterBar({
    super.key,
    required this.selected,
    required this.showGroups,
    required this.showServices,
    required this.onChanged,
  });

  final ChatListFilter selected;
  final bool showGroups;
  final bool showServices;
  final ValueChanged<ChatListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = <ChatListFilter>[
      ChatListFilter.all,
      ChatListFilter.unread,
      if (showGroups) ChatListFilter.groups,
      if (showServices) ChatListFilter.services,
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ObicColors.surfaceOf(context),
        border: Border(
          bottom: BorderSide(
            color: ObicColors.lineOf(context).withValues(alpha: 0.85),
          ),
        ),
      ),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final filter = filters[i];
            final on = filter == selected;
            return ChoiceChip(
              label: Text(chatListFilterLabel(filter, l10n)),
              selected: on,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : ObicColors.inkOf(context),
              ),
              selectedColor: ObicColors.isDark(context)
                  ? ObicColors.blue
                  : ObicColors.navy,
              backgroundColor: ObicColors.surfaceOf(context),
              side: BorderSide(
                color: on
                    ? Colors.transparent
                    : ObicColors.lineOf(context),
              ),
              onSelected: (_) => onChanged(filter),
            );
          },
        ),
      ),
    );
  }
}

/// One open swipe row at a time (WeChat).
final ValueNotifier<Object?> chatListSwipeOpen = ValueNotifier<Object?>(null);

class ChatThreadTile extends StatefulWidget {
  const ChatThreadTile({
    super.key,
    required this.avatar,
    required this.title,
    required this.preview,
    required this.timeLabel,
    required this.muted,
    required this.pinned,
    required this.onTap,
    required this.onLongPressStart,
    required this.swipeActions,
  });

  final Widget avatar;
  final String title;
  final Widget preview;
  final String timeLabel;
  final bool muted;
  final bool pinned;
  final VoidCallback onTap;
  final GestureLongPressStartCallback onLongPressStart;
  final List<ChatSwipeAction> swipeActions;

  @override
  State<ChatThreadTile> createState() => _ChatThreadTileState();
}

class _ChatThreadTileState extends State<ChatThreadTile> {
  static const _actionWidth = 78.0;
  double _offset = 0;

  double get _max => widget.swipeActions.length * _actionWidth;

  @override
  void initState() {
    super.initState();
    chatListSwipeOpen.addListener(_onOtherOpened);
  }

  @override
  void dispose() {
    chatListSwipeOpen.removeListener(_onOtherOpened);
    if (identical(chatListSwipeOpen.value, this)) {
      chatListSwipeOpen.value = null;
    }
    super.dispose();
  }

  void _onOtherOpened() {
    if (!mounted) return;
    if (!identical(chatListSwipeOpen.value, this) && _offset != 0) {
      setState(() => _offset = 0);
    }
  }

  void _nudge(double delta) {
    final next = (_offset + delta).clamp(-_max, 0.0);
    if (next == _offset) return;
    setState(() => _offset = next);
  }

  void _settle(DragEndDetails details) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final vx = rtl
        ? -details.velocity.pixelsPerSecond.dx
        : details.velocity.pixelsPerSecond.dx;
    final open = vx < -280 || (vx <= 280 && _offset < -_max / 2);
    setState(() => _offset = open ? -_max : 0);
    if (open) {
      chatListSwipeOpen.value = this;
    } else if (identical(chatListSwipeOpen.value, this)) {
      chatListSwipeOpen.value = null;
    }
  }

  void _close() {
    if (_offset == 0) return;
    setState(() => _offset = 0);
    if (identical(chatListSwipeOpen.value, this)) {
      chatListSwipeOpen.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final visualDx = rtl ? -_offset : _offset;
    final pinnedBg = ObicColors.isDark(context)
        ? ObicColors.darkSurfaceRaised
        : ObicColors.listCanvas;
    final rowColor = widget.pinned ? pinnedBg : ObicColors.surfaceOf(context);

    return ClipRect(
      child: Stack(
        children: [
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            width: _max,
            child: Row(
              children: [
                for (final action in widget.swipeActions)
                  SizedBox(
                    width: _actionWidth,
                    child: Material(
                      color: action.background,
                      child: InkWell(
                        onTap: () {
                          _close();
                          action.onPressed();
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              action.label,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Transform.translate(
            offset: Offset(visualDx, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: (d) {
                final dx = rtl ? -d.delta.dx : d.delta.dx;
                _nudge(dx);
              },
              onHorizontalDragEnd: _settle,
              onLongPressStart: widget.onLongPressStart,
              child: Material(
                color: rowColor,
                child: InkWell(
                  onTap: () {
                    if (_offset != 0) {
                      _close();
                      return;
                    }
                    widget.onTap();
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          10,
                          14,
                          10,
                        ),
                        child: Row(
                          children: [
                            widget.avatar,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      height: 1.2,
                                      fontWeight: FontWeight.w600,
                                      color: ObicColors.titleOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  widget.preview,
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.timeLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ObicColors.mutedOf(context),
                                  ),
                                ),
                                if (widget.muted) ...[
                                  const SizedBox(height: 6),
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 15,
                                    color: ObicColors.mutedOf(context),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 76),
                        child: Divider(
                          height: 0.5,
                          thickness: 0.5,
                          color: ObicColors.lineOf(context).withValues(
                            alpha: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
