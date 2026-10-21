// Made by Dr Ali
// A customer group is a named set of company contacts followed by one staff member.

export const GROUP_NAME_MAX = 40;
export const GROUPS_PER_OWNER = 40;
export const MEMBERS_PER_GROUP = 80;

export function normalizeGroupName(value: string): string {
  const name = value.trim().replace(/\s+/g, ' ');
  if (!name || name.length > GROUP_NAME_MAX) throw new Error('GROUP_NAME');
  return name;
}

export function groupNameKey(name: string): string {
  const key = name.toLocaleLowerCase();
  if (!key || key.length > GROUP_NAME_MAX) throw new Error('GROUP_NAME');
  return key;
}

export function assertGroupNote(value: string | null | undefined): string | null {
  const text = (value ?? '').trim();
  if (!text) return null;
  if (text.length > 200) throw new Error('GROUP_NOTE');
  return text;
}

/** Unique contact ids that belong to the group's owner. */
export function assertGroupMembers(contactIds: readonly string[], allowed: ReadonlySet<string>): string[] {
  const unique: string[] = [];
  const seen = new Set<string>();
  for (const id of contactIds) {
    if (seen.has(id)) continue;
    if (!allowed.has(id)) throw new Error('GROUP_MEMBER');
    seen.add(id);
    unique.push(id);
  }
  if (unique.length > MEMBERS_PER_GROUP) throw new Error('GROUP_COUNT');
  return unique;
}
