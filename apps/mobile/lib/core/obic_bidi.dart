// Made by Dr Ali
// Arabic (and any other RTL language) lays out right-to-left.
// Phone numbers, emails, OTP codes, and similar identifiers stay left-to-right
// so digits are not reversed inside an RTL screen.

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

/// True for Arabic and every other right-to-left language code.
bool obicIsRtlLanguage(String languageCode) {
  final code = languageCode.split(RegExp('[-_]')).first;
  return Bidi.isRtlLanguage(code);
}

/// Phone, email, OTP, OBIC id, and other identifiers.
///
/// [textDirection] is always LTR so `+86…` and masked digits keep their order.
/// Alignment stays beside the label: the right edge on an RTL screen, the left
/// edge on an LTR screen.
class ObicIdentifierText extends StatelessWidget {
  const ObicIdentifierText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: TextDirection.ltr,
      textAlign: rtl ? TextAlign.right : TextAlign.left,
      style: style,
    );
  }
}
