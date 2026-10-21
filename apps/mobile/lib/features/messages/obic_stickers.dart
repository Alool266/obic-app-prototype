// Made by Dr Ali
// OBIC sticker pack. Sent as a chat body so the API needs no new field.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';

const String kObicStickerPrefix = '[[obic:sticker:v1]]';

class ObicSticker {
  const ObicSticker({
    required this.id,
    required this.emoji,
    required this.en,
    required this.ar,
  });

  final String id;
  final String emoji;
  final String en;
  final String ar;

  String label(bool arabic) => arabic ? ar : en;
}

const List<ObicSticker> kObicStickers = [
  ObicSticker(id: 'hi', emoji: '👋', en: 'Hi', ar: 'أهلاً'),
  ObicSticker(id: 'ok', emoji: '👍', en: 'OK', ar: 'تمام'),
  ObicSticker(id: 'thanks', emoji: '🙏', en: 'Thanks', ar: 'شكراً'),
  ObicSticker(id: 'love', emoji: '❤️', en: 'Love', ar: 'أحب'),
  ObicSticker(id: 'haha', emoji: '😂', en: 'Haha', ar: 'ههه'),
  ObicSticker(id: 'wow', emoji: '😮', en: 'Wow', ar: 'واو'),
  ObicSticker(id: 'sad', emoji: '😢', en: 'Sad', ar: 'حزين'),
  ObicSticker(id: 'call', emoji: '📞', en: 'Call me', ar: 'اتصل'),
  ObicSticker(id: 'party', emoji: '🎉', en: 'Congrats', ar: 'مبروك'),
  ObicSticker(id: 'obic', emoji: '🔵', en: 'OBIC', ar: 'أوبيك'),
  ObicSticker(id: 'yes', emoji: '✅', en: 'Yes', ar: 'نعم'),
  ObicSticker(id: 'no', emoji: '❌', en: 'No', ar: 'لا'),
];

String obicStickerBody(String id) => '$kObicStickerPrefix\nid=$id';

ObicSticker? parseObicSticker(String body) {
  if (!body.contains(kObicStickerPrefix) && !body.contains('[[obic:sticker:')) {
    return null;
  }
  final match = RegExp(r'id=([a-z0-9_-]+)').firstMatch(body);
  final id = match?.group(1);
  if (id == null) return kObicStickers.first;
  for (final sticker in kObicStickers) {
    if (sticker.id == id) return sticker;
  }
  return kObicStickers.last;
}

class ObicStickerFace extends StatelessWidget {
  const ObicStickerFace({super.key, required this.sticker, this.size = 72});

  final ObicSticker sticker;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: ObicColors.blue, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(sticker.emoji, style: TextStyle(fontSize: size * 0.42)),
          Text(
            'OBIC',
            style: TextStyle(
              color: ObicColors.blue,
              fontSize: size * 0.14,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> showObicStickerSheet(BuildContext context) {
  final arabic = Localizations.localeOf(context).languageCode == 'ar';
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: ObicColors.surfaceOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
                child: Text(
                  arabic ? 'ملصقات أوبيك' : 'OBIC stickers',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kObicStickers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (_, i) {
                  final sticker = kObicStickers[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(ctx).pop(sticker.id),
                    child: Column(
                      children: [
                        ObicStickerFace(sticker: sticker, size: 64),
                        const SizedBox(height: 4),
                        Text(
                          sticker.label(arabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: ObicColors.mutedOf(ctx),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
