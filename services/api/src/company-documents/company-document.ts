// Made by Dr Ali
// A shared company document. The latest save is the copy that stays.

export const DOC_LIMIT = 40;
export const DOC_TITLE_MAX = 80;
export const DOC_BODY_MAX = 8000;

export function normalizeDocTitle(value: string): string {
  const title = value.trim().replace(/\s+/g, ' ');
  if (!title || title.length > DOC_TITLE_MAX) throw new Error('DOC_TITLE');
  return title;
}

export function docTitleKey(title: string): string {
  const key = title.toLocaleLowerCase();
  if (!key || key.length > DOC_TITLE_MAX) throw new Error('DOC_TITLE');
  return key;
}

export function assertDocBody(value: string): string {
  const body = value.trim();
  if (!body || body.length > DOC_BODY_MAX) throw new Error('DOC_BODY');
  return body;
}
