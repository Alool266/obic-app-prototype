// Made by Dr Ali
// Short copy for new screens. Follows the language picked in the app.

import 'package:flutter/widgets.dart';

String obicPhrase(
  BuildContext context, {
  required String ar,
  required String en,
  required String zh,
}) {
  final code = Localizations.localeOf(context).languageCode;
  if (code == 'ar') return ar;
  if (code == 'zh') return zh;
  return en;
}
