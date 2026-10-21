// Made by Dr Ali
// Copy for the music mini app. It stays separate from OBIC settings.

import 'package:flutter/widgets.dart';

String musicText(BuildContext context, String en, String ar, String zh, String fr) {
  final code = Localizations.localeOf(context).languageCode;
  if (code.startsWith('ar')) return ar;
  if (code.startsWith('zh')) return zh;
  if (code.startsWith('fr')) return fr;
  return en;
}
