// Made by Dr Ali
// In-chat search over messages already loaded and the on-device thread cache.

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_cached_image.dart';
import 'chat_attach_helpers.dart';
import 'chat_media_bubbles.dart';
import 'group_avatar_collage.dart';
import 'message_search.dart';

enum ChatSearchFilter { all, photos, videos, files, links }

class ChatSearchHit {
  const ChatSearchHit({required this.id, required this.message});

  final String id;
  final Map<String, dynamic> message;
}

class VisibleQuote {
  const VisibleQuote({required this.quote, required this.rest});

  final String quote;
  final String rest;
}

/// Body prefix used when the send API has no quote field: 「quoted」\nreply.
VisibleQuote? splitVisibleQuote(String body) {
  if (!body.startsWith('「')) return null;
  final end = body.indexOf('」');
  if (end <= 1) return null;
  final quote = body.substring(1, end).trim();
  if (quote.isEmpty) return null;
  var rest = body.substring(end + 1);
  if (rest.startsWith('\n')) rest = rest.substring(1);
  return VisibleQuote(quote: quote, rest: rest);
}

final RegExp _httpUrl = RegExp(r'https?://[^\s<>\]]+', caseSensitive: false);

String? firstHttpUrl(String text) {
  final match = _httpUrl.firstMatch(text);
  if (match == null) return null;
  var url = match.group(0) ?? '';
  while (url.isNotEmpty && '.,);]'.contains(url[url.length - 1])) {
    url = url.substring(0, url.length - 1);
  }
  return url.isEmpty ? null : url;
}

bool messageHasHttpLink(Map<String, dynamic> message) {
  final body = asSearchText(message['body']);
  return firstHttpUrl(body) != null;
}

bool messageMatchesFilter(
  Map<String, dynamic> message,
  ChatSearchFilter filter,
) {
  final kind = (message['attachmentKind'] as String?) ?? 'none';
  switch (filter) {
    case ChatSearchFilter.all:
      return true;
    case ChatSearchFilter.photos:
      return kind == 'image';
    case ChatSearchFilter.videos:
      return kind == 'video';
    case ChatSearchFilter.files:
      return kind == 'file';
    case ChatSearchFilter.links:
      return messageHasHttpLink(message);
  }
}

int _createdMillis(Map<String, dynamic> message) {
  return parseSearchTime(message['createdAt'])?.millisecondsSinceEpoch ?? 0;
}

/// Loaded rows win over cache copies of the same id. Hidden ids are dropped.
List<Map<String, dynamic>> mergeThreadCorpus({
  required List<Map<String, dynamic>> loaded,
  required List<Map<String, dynamic>> cached,
  required Set<String> hiddenIds,
}) {
  final byId = <String, Map<String, dynamic>>{};
  for (final message in cached) {
    final id = message['id']?.toString();
    if (id == null || id.isEmpty || hiddenIds.contains(id)) continue;
    byId[id] = message;
  }
  for (final message in loaded) {
    final id = message['id']?.toString();
    if (id == null || id.isEmpty || hiddenIds.contains(id)) continue;
    byId[id] = message;
  }
  final rows = byId.values.toList();
  rows.sort((a, b) => _createdMillis(a).compareTo(_createdMillis(b)));
  return rows;
}

List<ChatSearchHit> searchThreadMessages({
  required List<Map<String, dynamic>> loaded,
  required List<Map<String, dynamic>> cached,
  required String query,
  required ChatSearchFilter filter,
  required Set<String> hiddenIds,
}) {
  final folded = foldSearchText(query.trim());
  final textMode = filter == ChatSearchFilter.all;
  if (textMode && folded.isEmpty) return const [];

  final hits = <ChatSearchHit>[];
  for (final message in mergeThreadCorpus(
    loaded: loaded,
    cached: cached,
    hiddenIds: hiddenIds,
  )) {
    if (message['recalled'] == true) continue;
    if (!messageMatchesFilter(message, filter)) continue;
    if (textMode || folded.isNotEmpty) {
      final text = searchableMessageBody(message);
      if (text == null || !searchTextContains(text, folded)) continue;
    }
    final id = message['id']?.toString();
    if (id == null || id.isEmpty) continue;
    hits.add(ChatSearchHit(id: id, message: message));
  }
  return hits;
}

/// Oldest peer message inside the trailing [unreadCount] peer messages.
/// Returns null when that message is outside the rows we have.
String? firstUnreadMessageId(
  List<Map<String, dynamic>> chronological,
  int unreadCount,
  String myUserId,
) {
  if (unreadCount <= 0 || myUserId.isEmpty) return null;
  var remaining = unreadCount;
  String? found;
  for (var i = chronological.length - 1; i >= 0 && remaining > 0; i--) {
    final message = chronological[i];
    if (message['recalled'] == true) continue;
    final id = message['id']?.toString() ?? '';
    if (id.isEmpty || id.startsWith('pending_') || message['pending'] == true) {
      continue;
    }
    final sender = message['senderId']?.toString() ?? '';
    if (sender.isEmpty || sender == myUserId) continue;
    remaining--;
    found = id;
  }
  if (remaining > 0) return null;
  return found;
}

final _chatUrlPattern = RegExp(
  r'(https?:\/\/[^\s]+|www\.[^\s]+)',
  caseSensitive: false,
);

class ChatHighlightText extends StatefulWidget {
  const ChatHighlightText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    this.onDark = false,
    this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle style;
  final bool onDark;
  final int? maxLines;

  @override
  State<ChatHighlightText> createState() => _ChatHighlightTextState();
}

class _ChatHighlightTextState extends State<ChatHighlightText> {
  final List<TapGestureRecognizer> _links = [];

  @override
  void dispose() {
    for (final link in _links) {
      link.dispose();
    }
    super.dispose();
  }

  List<InlineSpan> _withLinks(List<InlineSpan> spans, TextStyle linkStyle) {
    for (final link in _links) {
      link.dispose();
    }
    _links.clear();
    final out = <InlineSpan>[];
    for (final span in spans) {
      if (span is! TextSpan || span.text == null) {
        out.add(span);
        continue;
      }
      out.addAll(_splitLinks(span.text!, span.style ?? linkStyle, linkStyle));
    }
    return out;
  }

  List<InlineSpan> _splitLinks(String text, TextStyle base, TextStyle linkStyle) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _chatUrlPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start), style: base));
      }
      var raw = text.substring(match.start, match.end);
      var trailer = '';
      while (raw.isNotEmpty && '.,;:!?)]'.contains(raw[raw.length - 1])) {
        trailer = raw[raw.length - 1] + trailer;
        raw = raw.substring(0, raw.length - 1);
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _openChatLink(raw);
      _links.add(recognizer);
      spans.add(
        TextSpan(
          text: raw,
          style: linkStyle,
          recognizer: recognizer,
        ),
      );
      if (trailer.isNotEmpty) {
        spans.add(TextSpan(text: trailer, style: base));
      }
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final emphasis = widget.onDark
        ? widget.style.copyWith(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            backgroundColor: const Color(0xFFFFF3A0),
          )
        : widget.style.copyWith(
            color: ObicColors.blue,
            fontWeight: FontWeight.w700,
            backgroundColor: ObicColors.blue.withValues(alpha: 0.18),
          );
    final linkStyle = widget.style.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: widget.style.color,
    );
    return Text.rich(
      TextSpan(
        children: _withLinks(
          searchHighlightSpans(
            text: widget.text,
            query: widget.query,
            base: widget.style,
            emphasis: emphasis,
          ),
          linkStyle,
        ),
      ),
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
      textDirection: chatTextDirection(widget.text),
    );
  }
}

Future<void> _openChatLink(String raw) async {
  final withScheme = raw.startsWith(RegExp(r'https?://', caseSensitive: false))
      ? raw
      : 'https://$raw';
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class ChatMessageBodyText extends StatelessWidget {
  const ChatMessageBodyText({
    super.key,
    required this.body,
    required this.mine,
    required this.highlightQuery,
  });

  final String body;
  final bool mine;
  final String highlightQuery;

  @override
  Widget build(BuildContext context) {
    final quote = splitVisibleQuote(body);
    final base = TextStyle(
      color: mine ? Colors.white : ObicColors.inkOf(context),
      height: 1.35,
    );
    if (quote == null) {
      return ChatHighlightText(
        text: body,
        query: highlightQuery,
        style: base,
        onDark: mine,
      );
    }
    final quoteStyle = TextStyle(
      color: mine
          ? Colors.white.withValues(alpha: 0.92)
          : ObicColors.inkOf(context),
      fontSize: 13,
      height: 1.3,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          decoration: BoxDecoration(
            color: mine
                ? Colors.white.withValues(alpha: 0.14)
                : ObicColors.lineOf(context).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(6),
            border: BorderDirectional(
              start: BorderSide(
                color: mine ? Colors.white70 : ObicColors.blue,
                width: 3,
              ),
            ),
          ),
          child: ChatHighlightText(
            text: quote.quote,
            query: highlightQuery,
            style: quoteStyle,
            onDark: mine,
            maxLines: 4,
          ),
        ),
        if (quote.rest.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          ChatHighlightText(
            text: quote.rest,
            query: highlightQuery,
            style: base,
            onDark: mine,
          ),
        ],
      ],
    );
  }
}

class ChatInSearchFilterBar extends StatelessWidget {
  const ChatInSearchFilterBar({
    super.key,
    required this.filter,
    required this.l10n,
    required this.onChanged,
  });

  final ChatSearchFilter filter;
  final AppLocalizations l10n;
  final ValueChanged<ChatSearchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <({ChatSearchFilter id, String label})>[
      (id: ChatSearchFilter.all, label: l10n.chatSearchAll),
      (id: ChatSearchFilter.photos, label: l10n.chatSearchPhotos),
      (id: ChatSearchFilter.videos, label: l10n.chatSearchVideos),
      (id: ChatSearchFilter.files, label: l10n.chatSearchFiles),
      (id: ChatSearchFilter.links, label: l10n.chatSearchLinks),
    ];
    return Material(
      color: ObicColors.surfaceOf(context),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final chip = chips[i];
            final selected = chip.id == filter;
            return ChoiceChip(
              label: Text(chip.label),
              selected: selected,
              onSelected: (_) {
                if (selected && chip.id != ChatSearchFilter.all) {
                  onChanged(ChatSearchFilter.all);
                } else {
                  onChanged(chip.id);
                }
              },
              visualDensity: VisualDensity.compact,
              labelStyle: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : ObicColors.inkOf(context),
              ),
              selectedColor: ObicColors.blue,
              backgroundColor: ObicColors.scaffoldOf(context),
              side: BorderSide(
                color: selected ? ObicColors.blue : ObicColors.lineOf(context),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChatSearchPositionBar extends StatelessWidget {
  const ChatSearchPositionBar({
    super.key,
    required this.current,
    required this.total,
    required this.label,
    required this.olderTooltip,
    required this.newerTooltip,
    required this.onOlder,
    required this.onNewer,
  });

  final int current;
  final int total;
  final String label;
  final String olderTooltip;
  final String newerTooltip;
  final VoidCallback? onOlder;
  final VoidCallback? onNewer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ObicColors.surfaceOf(context),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: olderTooltip,
              onPressed: onOlder,
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ObicColors.titleOf(context),
              ),
            ),
            IconButton(
              tooltip: newerTooltip,
              onPressed: onNewer,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatSearchResultPane extends StatelessWidget {
  const ChatSearchResultPane({
    super.key,
    required this.hits,
    required this.filter,
    required this.onOpen,
  });

  final List<ChatSearchHit> hits;
  final ChatSearchFilter filter;
  final ValueChanged<ChatSearchHit> onOpen;

  @override
  Widget build(BuildContext context) {
    if (filter == ChatSearchFilter.photos ||
        filter == ChatSearchFilter.videos) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: hits.length,
        itemBuilder: (context, i) {
          final hit = hits[i];
          final url = hit.message['attachmentUrl'] as String?;
          return Material(
            color: ObicColors.surfaceOf(context),
            child: InkWell(
              onTap: () => onOpen(hit),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SearchThumb(
                    url: url,
                    video: filter == ChatSearchFilter.videos,
                  ),
                  if (filter == ChatSearchFilter.videos)
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: hits.length,
      separatorBuilder: (_, _) => Divider(
        height: 0.5,
        thickness: 0.5,
        color: ObicColors.lineOf(context),
      ),
      itemBuilder: (context, i) {
        final hit = hits[i];
        final message = hit.message;
        final kind = (message['attachmentKind'] as String?) ?? 'none';
        final name = (message['attachmentName'] as String?)?.trim();
        final body = ((message['body'] as String?) ?? '').trim();
        final link = firstHttpUrl(body);
        final title = filter == ChatSearchFilter.links
            ? (link ?? body)
            : (name?.isNotEmpty == true
                  ? name!
                  : (body.isNotEmpty ? body : kind));
        final at = parseSearchTime(message['createdAt'])?.toLocal();
        final when = at == null
            ? ''
            : '${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')} '
                  '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
        return ListTile(
          leading: Icon(
            filter == ChatSearchFilter.links
                ? Icons.link_rounded
                : Icons.insert_drive_file_outlined,
            color: ObicColors.blue,
          ),
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: ObicColors.inkOf(context), fontSize: 14),
          ),
          subtitle: when.isEmpty
              ? null
              : Text(
                  when,
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 12,
                  ),
                ),
          onTap: () => onOpen(hit),
        );
      },
    );
  }
}

class _SearchThumb extends StatelessWidget {
  const _SearchThumb({required this.url, required this.video});

  final String? url;
  final bool video;

  @override
  Widget build(BuildContext context) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) {
      return ColoredBox(
        color: ObicColors.scaffoldOf(context),
        child: Icon(
          video ? Icons.videocam_outlined : Icons.image_outlined,
          color: ObicColors.mutedOf(context),
        ),
      );
    }
    if (isLocalAttachmentPath(raw)) {
      return Image.file(
        File(resolvedChatMediaUrl(raw)),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(
          color: ObicColors.scaffoldOf(context),
          child: Icon(
            Icons.broken_image_outlined,
            color: ObicColors.mutedOf(context),
          ),
        ),
      );
    }
    return ObicCachedImage(
      raw,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => ColoredBox(
        color: ObicColors.scaffoldOf(context),
        child: Icon(
          Icons.broken_image_outlined,
          color: ObicColors.mutedOf(context),
        ),
      ),
    );
  }
}
