// Made by Dr Ali
// WeChat-style long-press popup — white panel, plain text, no icons.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';

/// Shows a compact WeChat-like context menu near [globalPosition].
Future<String?> showWeChatContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required List<({String id, String label})> items,
}) {
  assert(items.isNotEmpty);
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final size = overlay.size;
  final menuWidth = _menuWidth(context, items, size.width);
  final itemHeight = 48.0;
  final menuHeight = items.length * itemHeight;
  final pad = 12.0;

  var left = globalPosition.dx;
  // Prefer to the right of the finger; flip if near the trailing edge.
  if (left + menuWidth + pad > size.width) {
    left = globalPosition.dx - menuWidth;
  }
  left = left.clamp(pad, size.width - menuWidth - pad);

  var top = globalPosition.dy - menuHeight / 2;
  if (top < pad) top = pad;
  if (top + menuHeight + pad > size.height) {
    top = size.height - menuHeight - pad;
  }

  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (ctx, anim, secondary) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: menuWidth,
            child: Material(
              color: ObicColors.surfaceOf(ctx),
              elevation: 8,
              shadowColor: Colors.black38,
              borderRadius: BorderRadius.circular(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: ObicColors.lineOf(ctx).withValues(alpha: 0.5),
                      ),
                    InkWell(
                      onTap: () => Navigator.of(ctx).pop(items[i].id),
                      child: SizedBox(
                        height: itemHeight,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              items[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                color: ObicColors.inkOf(ctx),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (ctx, anim, secondary, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

double _menuWidth(
  BuildContext context,
  List<({String id, String label})> items,
  double overlayWidth,
) {
  const style = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  var widest = 180.0;
  for (final item in items) {
    final painter = TextPainter(
      text: TextSpan(text: item.label, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final w = painter.width + 40;
    if (w > widest) widest = w;
  }
  final cap = overlayWidth - 24;
  if (widest > cap) return cap;
  return widest;
}
