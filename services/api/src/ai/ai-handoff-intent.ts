// Made by Dr Ali
// Detect customer messages that should auto-invoke Talk-to-staff (visa/order status + ref).

/**
 * True when the customer asks about visa/order status and includes a
 * reference-like number (e.g. 1790244575128). Used by auto-reply to call
 * requestStaff so AI cannot merely *claim* a transfer.
 */
export function shouldAutoRequestStaff(body: string): boolean {
  const text = (body ?? '').trim();
  if (text.length < 6) return false;

  // Long numeric / alphanumeric case refs (visa, booking, order).
  const hasRef =
    /\d{8,}/.test(text) ||
    /(?:ref(?:erence)?|رقم|case|ticket|طلب)[^\dA-Za-z]{0,12}[\dA-Za-z]{6,}/i.test(
      text,
    );

  if (!hasRef) return false;

  const statusIntent =
    /status|track|follow\s*up|update|حالة|متابعة|تتبع|تأشير|visa|visas|طلب|order|passport|جواز/i.test(
      text,
    );

  return statusIntent;
}
