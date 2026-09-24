// Made by Dr Ali
// Phrase match for the thin content filter. Keep this free of I/O so tests stay simple.

export function normalizeForFilter(text: string): string {
  return text
    .normalize('NFKC')
    .toLowerCase()
    .replace(/[\u200b-\u200d\ufeff]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

/** First matching phrase, or null. Phrases must already be normalized. Skip very short tokens. */
export function firstBannedHit(
  text: string,
  phrases: string[],
): string | null {
  const hay = normalizeForFilter(text);
  if (!hay) return null;
  for (const raw of phrases) {
    const needle = normalizeForFilter(raw);
    if (needle.length < 3) continue;
    if (hay.includes(needle)) return needle;
  }
  return null;
}
