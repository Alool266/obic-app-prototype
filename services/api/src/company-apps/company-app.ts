// Made by Dr Ali
// A company web tool. The page stays outside OBIC.

export const APP_LIMIT = 20;
export const APP_NAME_MAX = 40;
export const APP_NOTE_MAX = 300;
export const APP_URL_MAX = 200;

export function normalizeAppName(value: string): string {
  const name = value.trim().replace(/\s+/g, ' ');
  if (!name || name.length > APP_NAME_MAX) throw new Error('APP_NAME');
  return name;
}

export function appNameKey(name: string): string {
  const key = name.toLocaleLowerCase();
  if (!key || key.length > APP_NAME_MAX) throw new Error('APP_NAME');
  return key;
}

export function assertAppNote(value: string | null | undefined): string | null {
  const note = (value ?? '').trim();
  if (!note) return null;
  if (note.length > APP_NOTE_MAX) throw new Error('APP_NOTE');
  return note;
}

export function assertAppUrl(value: string): string {
  const url = value.trim();
  if (!url || url.length > APP_URL_MAX) throw new Error('APP_URL');
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    throw new Error('APP_URL');
  }
  if (parsed.protocol !== 'https:' || parsed.username || parsed.password || !parsed.hostname) {
    throw new Error('APP_URL');
  }
  return url;
}
