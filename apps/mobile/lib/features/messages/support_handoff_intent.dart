// Made by Dr Ali
// Mirror API ai-handoff-intent — visa/order status + ref → open handoff form.

/// True when the customer asks about visa/order status and includes a
/// reference-like number. Used client-side so support auto-intent opens the
/// handoff form (branch confirm) instead of silent Yiwu default.
bool shouldAutoRequestStaff(String body) {
  final text = body.trim();
  if (text.length < 6) return false;

  final hasRef = RegExp(r'\d{8,}').hasMatch(text) ||
      RegExp(
        r'(?:ref(?:erence)?|رقم|case|ticket|طلب)[^\dA-Za-z]{0,12}[\dA-Za-z]{6,}',
        caseSensitive: false,
      ).hasMatch(text);

  if (!hasRef) return false;

  final statusIntent = RegExp(
    r'status|track|follow\s*up|update|حالة|متابعة|تتبع|تأشير|visa|visas|طلب|order|passport|جواز',
    caseSensitive: false,
  ).hasMatch(text);

  return statusIntent;
}

/// Extract a likely case / order / visa reference from free text.
String? extractHandoffOrderRef(String body) {
  final digit = RegExp(r'\d{8,}').firstMatch(body);
  if (digit != null) return digit.group(0);
  final labeled = RegExp(
    r'(?:ref(?:erence)?|رقم|case|ticket|طلب)[^\dA-Za-z]{0,12}([\dA-Za-z]{6,})',
    caseSensitive: false,
  ).firstMatch(body);
  return labeled?.group(1);
}
