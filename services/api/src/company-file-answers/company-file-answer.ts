// Made by Dr Ali
// Match a staff question to active shared documents. This does not search the customer catalog.

export const FILE_QUESTION_MAX = 300;
export const FILE_EXCERPT_MAX = 240;
export const FILE_SOURCE_LIMIT = 3;
export const FILE_ANSWER_MAX = 2000;

export type CompanyFileDoc = {
  id: string;
  title: string;
  body: string;
};

export type CompanyFileHit = {
  id: string;
  title: string;
  excerpt: string;
};

export function normalizeFileQuestion(value: string): string {
  const question = value.trim().replace(/\s+/g, ' ');
  if (!question || question.length > FILE_QUESTION_MAX) throw new Error('FILE_QUESTION');
  return question;
}

export function rankCompanyDocuments(question: string, docs: readonly CompanyFileDoc[]): CompanyFileHit[] {
  const needles = tokens(question);
  if (!needles.length) return [];
  const ranked = docs
    .map((doc) => {
      const titleTokens = new Set(tokens(doc.title));
      const bodyTokens = new Set(tokens(doc.body));
      let score = 0;
      const matched: string[] = [];
      for (const needle of needles) {
        const inTitle = titleTokens.has(needle);
        const inBody = bodyTokens.has(needle);
        if (!inTitle && !inBody) continue;
        score += inTitle ? 3 : 1;
        matched.push(needle);
      }
      return { doc, score, matched };
    })
    .filter((row) => row.score > 0)
    .sort((a, b) => b.score - a.score || a.doc.title.localeCompare(b.doc.title))
    .slice(0, FILE_SOURCE_LIMIT);
  return ranked.map((row) => ({
    id: row.doc.id,
    title: row.doc.title,
    excerpt: excerptAround(row.doc.body, row.matched),
  }));
}

export function draftFromHits(hits: readonly CompanyFileHit[]): string | null {
  if (!hits.length) return null;
  const text = hits.map((hit) => `${hit.title}: ${hit.excerpt}`).join('\n\n');
  return text.length > FILE_ANSWER_MAX ? text.slice(0, FILE_ANSWER_MAX) : text;
}

function tokens(value: string): string[] {
  const lower = value.toLocaleLowerCase();
  const words = lower.split(/[^\p{L}\p{N}]+/u).filter((word) => word.length >= 2 && word.length <= 24);
  const runs = lower.match(/[\u4e00-\u9fff]{2,}/g) ?? [];
  const bigrams: string[] = [];
  for (const run of runs) {
    for (let index = 0; index < run.length - 1; index += 1) bigrams.push(run.slice(index, index + 2));
  }
  return [...new Set([...words, ...bigrams])];
}

function excerptAround(body: string, needles: readonly string[]): string {
  const lower = body.toLocaleLowerCase();
  let at = -1;
  for (const needle of needles) {
    const found = lower.indexOf(needle);
    if (found >= 0 && (at < 0 || found < at)) at = found;
  }
  if (at < 0) return body.trim().slice(0, FILE_EXCERPT_MAX);
  const start = Math.max(0, at - 40);
  return body.slice(start, start + FILE_EXCERPT_MAX).trim();
}
