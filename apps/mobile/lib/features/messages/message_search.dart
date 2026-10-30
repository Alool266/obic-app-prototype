// Made by Dr Ali
// Messages search over the chat list and message text already on the device.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import 'group_avatar_collage.dart';

/// Unicode case-fold. Latin letters (English, French) fold; Arabic and
/// Chinese have no case, so they compare unchanged.
String foldSearchText(String value) => value.toLowerCase();

bool searchTextContains(String haystack, String foldedQuery) {
  if (foldedQuery.isEmpty || haystack.isEmpty) return false;
  return foldSearchText(haystack).contains(foldedQuery);
}

String asSearchText(Object? value) => value is String ? value : '';

class SearchRange {
  const SearchRange(this.start, this.end);

  final int start;
  final int end;
}

/// Match [foldedNeedle] inside [text]. Indices are into [text], even when
/// [String.toLowerCase] changes length (some Latin letters).
SearchRange? findFoldedRange(String text, String foldedNeedle) {
  if (foldedNeedle.isEmpty || text.isEmpty) return null;
  final lower = foldSearchText(text);
  if (lower.length == text.length) {
    final index = lower.indexOf(foldedNeedle);
    if (index < 0) return null;
    return SearchRange(index, index + foldedNeedle.length);
  }
  final maxWindow = foldedNeedle.length + 8;
  for (var start = 0; start < text.length; start++) {
    final windowEnd = start + maxWindow < text.length
        ? start + maxWindow
        : text.length;
    for (var end = start + 1; end <= windowEnd; end++) {
      final folded = foldSearchText(text.substring(start, end));
      if (folded == foldedNeedle) return SearchRange(start, end);
      if (folded.length > foldedNeedle.length) break;
    }
  }
  return null;
}

String snippetAroundMatch(String text, String foldedQuery, {int radius = 42}) {
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (foldedQuery.isEmpty) return flat;
  final range = findFoldedRange(flat, foldedQuery);
  if (range == null) return flat;
  final start = range.start - radius < 0 ? 0 : range.start - radius;
  final end = range.end + radius > flat.length ? flat.length : range.end + radius;
  final prefix = start > 0 ? '…' : '';
  final suffix = end < flat.length ? '…' : '';
  return '$prefix${flat.substring(start, end)}$suffix';
}

DateTime? parseSearchTime(Object? raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

/// Text we can honestly match on device. Recalled rows and status tokens are
/// skipped. Call-record machine lines are dropped; the human line stays.
String? searchableMessageBody(Map<String, dynamic> message) {
  if (message['recalled'] == true) return null;
  var body = asSearchText(message['body']).trim();
  if (body.startsWith('[[status]]')) return null;
  if (body.contains('[[obic:call:')) {
    final human = <String>[];
    for (final raw in body.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('[[') || line.contains('=')) {
        continue;
      }
      human.add(line);
    }
    body = human.join(' ');
  }
  final attachmentName = asSearchText(message['attachmentName']).trim();
  if (body.isEmpty) return attachmentName.isEmpty ? null : attachmentName;
  if (attachmentName.isEmpty) return body;
  return '$body $attachmentName';
}

class CachedMessageHit {
  const CachedMessageHit({
    required this.messageId,
    required this.snippet,
    required this.at,
  });

  final String? messageId;
  final String snippet;
  final DateTime? at;
}

class ThreadHistoryMatch {
  const ThreadHistoryMatch({
    required this.thread,
    required this.hits,
  });

  final Map<String, dynamic> thread;
  final List<CachedMessageHit> hits;
}

/// History hits from the last-message preview and cached message bodies.
/// Does not read the server. A thread with no cache still matches its preview.
List<CachedMessageHit> historyHitsForThread({
  required String foldedQuery,
  required String preview,
  required Map<String, dynamic>? lastMessage,
  required List<Map<String, dynamic>>? cachedMessages,
}) {
  final hits = <CachedMessageHit>[];
  final seenIds = <String>{};
  final seenSnippets = <String>{};

  void add(String? id, String text, DateTime? at) {
    if (!searchTextContains(text, foldedQuery)) return;
    if (id != null && id.isNotEmpty) {
      if (!seenIds.add(id)) return;
    }
    final snippet = snippetAroundMatch(text, foldedQuery);
    if (id == null || id.isEmpty) {
      if (!seenSnippets.add(snippet)) return;
    }
    hits.add(
      CachedMessageHit(messageId: id, snippet: snippet, at: at),
    );
  }

  if (cachedMessages != null) {
    for (final message in cachedMessages) {
      final text = searchableMessageBody(message);
      if (text == null) continue;
      add(
        message['id']?.toString(),
        text,
        parseSearchTime(message['createdAt']),
      );
    }
  }

  final lastId = lastMessage?['id']?.toString();
  final lastAt = parseSearchTime(lastMessage?['createdAt']);
  if (lastMessage != null) {
    final body = searchableMessageBody(lastMessage);
    if (body != null) add(lastId, body, lastAt);
  }
  if (lastMessage != null && preview.trim().isNotEmpty) {
    add(lastId, preview, lastAt);
  }

  hits.sort((a, b) {
    final ta = a.at?.millisecondsSinceEpoch ?? 0;
    final tb = b.at?.millisecondsSinceEpoch ?? 0;
    return tb.compareTo(ta);
  });
  return hits;
}

bool threadNameMatches({
  required String foldedQuery,
  required String displayName,
  required String? title,
  required Iterable<String> otherNames,
}) {
  if (searchTextContains(displayName, foldedQuery)) return true;
  if (title != null && searchTextContains(title, foldedQuery)) return true;
  for (final name in otherNames) {
    if (searchTextContains(name, foldedQuery)) return true;
  }
  return false;
}

/// First other name that contains the query, when the row title itself does not.
String? matchingOtherName({
  required String foldedQuery,
  required String displayName,
  required Iterable<String> otherNames,
}) {
  if (searchTextContains(displayName, foldedQuery)) return null;
  for (final name in otherNames) {
    if (searchTextContains(name, foldedQuery)) return name;
  }
  return null;
}

List<InlineSpan> searchHighlightSpans({
  required String text,
  required String query,
  required TextStyle base,
  required TextStyle emphasis,
}) {
  final folded = foldSearchText(query.trim());
  if (folded.isEmpty || text.isEmpty) {
    return [TextSpan(text: text, style: base)];
  }
  final spans = <InlineSpan>[];
  var cursor = 0;
  while (cursor < text.length) {
    final range = findFoldedRange(text.substring(cursor), folded);
    if (range == null || range.end <= range.start) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
      break;
    }
    final start = cursor + range.start;
    final end = cursor + range.end;
    if (start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, start), style: base));
    }
    spans.add(TextSpan(text: text.substring(start, end), style: emphasis));
    cursor = end;
  }
  return spans;
}

class SearchHighlightText extends StatelessWidget {
  const SearchHighlightText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    this.maxLines = 2,
  });

  final String text;
  final String query;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final emphasis = style.copyWith(
      color: ObicColors.blue,
      fontWeight: FontWeight.w700,
      backgroundColor: ObicColors.blue.withValues(alpha: 0.16),
    );
    return Text.rich(
      TextSpan(
        children: searchHighlightSpans(
          text: text,
          query: query,
          base: style,
          emphasis: emphasis,
        ),
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textDirection: chatTextDirection(text),
    );
  }
}

class MessageSearchSectionLabel extends StatelessWidget {
  const MessageSearchSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ObicColors.scaffoldOf(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ObicColors.mutedOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

class MessageSearchResultRow extends StatelessWidget {
  const MessageSearchResultRow({
    super.key,
    required this.avatar,
    required this.title,
    required this.preview,
    required this.timeLabel,
    required this.muted,
    required this.onTap,
  });

  final Widget avatar;
  final Widget title;
  final Widget preview;
  final String timeLabel;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ObicColors.surfaceOf(context),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 14, 10),
              child: Row(
                children: [
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 4),
                        preview,
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: ObicColors.mutedOf(context),
                        ),
                      ),
                      if (muted) ...[
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
                color: ObicColors.lineOf(context).withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
