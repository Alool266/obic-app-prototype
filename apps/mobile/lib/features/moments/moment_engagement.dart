// Made by Dr Ali
// WeChat Moments like-names and comment list, shown on the post itself.

import 'package:flutter/material.dart';

import '../../core/media_url.dart';
import '../../core/obic_bidi.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/obic_cached_image.dart';
import 'moment_media_viewer.dart';

const _kWeChatName = Color(0xFF576B95);
const _kLikeBar = Color(0xFFF7F7F7);

/// Nested moment JSON may arrive as `Map<dynamic, dynamic>`.
int momentInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return 0;
}

List<Map<String, dynamic>> momentMaps(dynamic raw) {
  if (raw is! List) return const [];
  final out = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is Map) out.add(Map<String, dynamic>.from(item));
  }
  return out;
}

class MomentEngagementBox extends StatelessWidget {
  const MomentEngagementBox({
    super.key,
    required this.likes,
    required this.likeCount,
    required this.comments,
    required this.emptyLikes,
    required this.repliedToLabel,
    required this.viewerId,
    required this.momentAuthorId,
    required this.onReply,
    required this.onDeleteComment,
    required this.onOpenProfile,
  });

  final List<Map<String, dynamic>> likes;
  final int likeCount;
  final List<Map<String, dynamic>> comments;
  final String emptyLikes;
  final String repliedToLabel;
  final String? viewerId;
  final String momentAuthorId;
  final void Function(Map<String, dynamic> comment) onReply;
  final void Function(Map<String, dynamic> comment) onDeleteComment;
  final void Function({
    required String userId,
    String? name,
    String? avatarUrl,
  }) onOpenProfile;

  bool _canDelete(Map<String, dynamic> c) {
    final me = viewerId;
    if (me == null || me.isEmpty) return false;
    final authorId = c['authorId'] as String? ?? '';
    return authorId == me || momentAuthorId == me;
  }

  @override
  Widget build(BuildContext context) {
    final dark = ObicColors.isDark(context);
    // Near-white on the dark bar. WeChat blue-gray (#576B95) is about 2.6:1
    // there, so names, the heart, and comment text share #F5F5F7.
    final ink = dark ? ObicColors.darkInk : const Color(0xFF191919);
    final nameColor = dark ? ObicColors.darkInk : _kWeChatName;
    final rule = dark ? const Color(0xFFC8C8D0) : const Color(0xFFE5E5E5);
    final namedLikes = likes
        .where((l) => ((l['name'] as String?) ?? '').trim().isNotEmpty)
        .toList();
    final shownCount = likeCount > likes.length ? likeCount : likes.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: ObicColors.isDark(context)
            ? ObicColors.darkSurfaceRaised
            : _kLikeBar,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (likes.isNotEmpty || shownCount > 0)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.favorite, size: 14, color: nameColor),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: namedLikes.isEmpty
                      ? shownCount > 0
                          ? ObicIdentifierText(
                              '$shownCount',
                              style: TextStyle(
                                color: nameColor,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            )
                          : Text(
                              emptyLikes,
                              style: TextStyle(
                                color: nameColor,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            )
                      : Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (var i = 0; i < namedLikes.length; i++) ...[
                              if (i > 0)
                                Text(
                                  ', ',
                                  style: TextStyle(
                                    color: nameColor,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              GestureDetector(
                                onTap: () {
                                  final id =
                                      namedLikes[i]['userId'] as String? ?? '';
                                  if (id.isEmpty) return;
                                  onOpenProfile(
                                    userId: id,
                                    name: namedLikes[i]['name'] as String?,
                                  );
                                },
                                child: Text(
                                  (namedLikes[i]['name'] as String?) ?? '',
                                  style: TextStyle(
                                    color: nameColor,
                                    fontSize: 13,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          if ((likes.isNotEmpty || shownCount > 0) && comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Divider(
                height: 1,
                thickness: dark ? 1 : null,
                color: rule,
              ),
            ),
          for (final c in comments)
            InkWell(
              onTap: () => onReply(c),
              onLongPress: _canDelete(c) ? () => onDeleteComment(c) : null,
              borderRadius: BorderRadius.circular(2),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4, top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: ink,
                        ),
                        children: [
                          TextSpan(
                            text: (c['authorName'] as String?) ?? '',
                            style: TextStyle(
                              color: nameColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if ((c['replyToAuthorName'] as String?)
                                  ?.trim()
                                  .isNotEmpty ==
                              true) ...[
                            TextSpan(text: ' $repliedToLabel '),
                            TextSpan(
                              text: (c['replyToAuthorName'] as String?) ?? '',
                              style: TextStyle(
                                color: nameColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          TextSpan(
                            text: ': ',
                            style: TextStyle(color: ink),
                          ),
                          if (((c['body'] as String?) ?? '').isNotEmpty)
                            TextSpan(
                              text: (c['body'] as String?) ?? '',
                              style: TextStyle(color: ink),
                            ),
                        ],
                      ),
                    ),
                    if (_commentImageUrls(c).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _CommentImageThumbs(urls: _commentImageUrls(c)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

List<String> _commentImageUrls(Map<String, dynamic> c) {
  return momentMaps(c['media'])
      .where((m) => (m['kind'] as String?) == 'image')
      .map((m) => resolveMediaUrl(m['url'] as String?))
      .where((u) => u.isNotEmpty)
      .toList();
}

class _CommentImageThumbs extends StatelessWidget {
  const _CommentImageThumbs({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < urls.length; i++)
          GestureDetector(
            onTap: () => openMomentPhotoViewer(
              context,
              urls: urls,
              initialIndex: i,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: ObicCachedImage(
                urls[i],
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: size,
                  height: size,
                  child: ColoredBox(
                    color: Color(0xFFE8E8E8),
                    child: Icon(Icons.broken_image_outlined, size: 18),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
