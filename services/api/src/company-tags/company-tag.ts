// Made by Dr Ali
// A company tag is a short label. A contact can carry up to eight.

export const TAG_NAME_MAX = 24;
export const TAG_LIMIT = 40;
export const TAGS_PER_CONTACT = 8;

export function normalizeTagName(value: string): string {
  const name = value.trim().replace(/\s+/g, ' ');
  if (!name || name.length > TAG_NAME_MAX) throw new Error('TAG_NAME');
  return name;
}

export function tagNameKey(name: string): string {
  const key = name.toLocaleLowerCase();
  if (!key || key.length > TAG_NAME_MAX) throw new Error('TAG_NAME');
  return key;
}

/** Unique ids that are on the allowed set. Allowed includes active tags and tags already on the contact. */
export function assertTagSelection(tagIds: readonly string[], allowed: ReadonlySet<string>): string[] {
  const unique: string[] = [];
  const seen = new Set<string>();
  for (const id of tagIds) {
    if (seen.has(id)) continue;
    if (!allowed.has(id)) throw new Error('TAG_UNKNOWN');
    seen.add(id);
    unique.push(id);
  }
  if (unique.length > TAGS_PER_CONTACT) throw new Error('TAG_COUNT');
  return unique;
}
