// Made by Dr Ali
// Internal company mail. A message stays inside OBIC.

export const MAIL_SUBJECT_MAX = 80;
export const MAIL_BODY_MAX = 2000;
export const MAIL_RECIPIENT_LIMIT = 12;

export function normalizeMailSubject(value: string): string {
  const subject = value.trim().replace(/\s+/g, ' ');
  if (!subject || subject.length > MAIL_SUBJECT_MAX) throw new Error('MAIL_SUBJECT');
  return subject;
}

export function assertMailBody(value: string): string {
  const body = value.trim();
  if (!body || body.length > MAIL_BODY_MAX) throw new Error('MAIL_BODY');
  return body;
}

export function assertMailRecipients(
  ids: readonly string[],
  senderId: string,
  allowed: ReadonlySet<string>,
): string[] {
  const unique: string[] = [];
  const seen = new Set<string>();
  for (const id of ids) {
    if (id === senderId || seen.has(id)) continue;
    if (!allowed.has(id)) throw new Error('MAIL_RECIPIENT');
    seen.add(id);
    unique.push(id);
  }
  if (unique.length === 0) throw new Error('MAIL_RECIPIENT');
  if (unique.length > MAIL_RECIPIENT_LIMIT) throw new Error('MAIL_COUNT');
  return unique;
}
