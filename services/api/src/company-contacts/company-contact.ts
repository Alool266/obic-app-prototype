// Made by Dr Ali
// A company contact is an external person the company keeps, assigned to one staff member.

const PHONE = /^\+?[0-9]{6,20}$/;

export function assertContactName(value: string): string {
  const name = value.trim();
  if (!name || name.length > 80) throw new Error('CONTACT_NAME');
  return name;
}

export function normalizeContactPhone(value: string | null | undefined): string | null {
  const compact = (value ?? '').replace(/[\s-]/g, '');
  if (!compact) return null;
  if (!PHONE.test(compact)) throw new Error('CONTACT_PHONE');
  return compact;
}

export function assertContactText(
  value: string | null | undefined,
  max: number,
  code: 'CONTACT_ORG' | 'CONTACT_NOTE',
): string | null {
  const text = (value ?? '').trim();
  if (!text) return null;
  if (text.length > max) throw new Error(code);
  return text;
}
