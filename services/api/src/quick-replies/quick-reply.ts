// Made by Dr Ali
// A short reply the employee can copy. Company replies and personal replies stay separate.

export const COMPANY_QUICK_LIMIT = 40;
export const PERSONAL_QUICK_LIMIT = 20;

export function assertQuickTitle(value: string): string {
  const title = value.trim().replace(/\s+/g, ' ');
  if (!title || title.length > 24) throw new Error('QUICK_TITLE');
  return title;
}

export function quickTitleKey(title: string): string {
  const key = title.toLocaleLowerCase();
  if (!key || key.length > 24) throw new Error('QUICK_TITLE');
  return key;
}

export function assertQuickBody(value: string): string {
  const body = value.trim();
  if (!body || body.length > 300) throw new Error('QUICK_BODY');
  return body;
}
