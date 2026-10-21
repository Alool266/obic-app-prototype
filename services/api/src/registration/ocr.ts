// Made by Dr Ali
// Passport OCR parsing + three-way comparison (boss M04, TST-006).
// Pure logic: OCR output vs customer-typed vs saved profile. A mismatch
// never edits customer data — it routes to a human reviewer.

export const PASSPORT_FIELDS = [
  'fullName',
  'passportNumber',
  'nationality',
  'dateOfBirth',
  'sex',
  'issueDate',
  'expiryDate',
] as const;
export type PassportField = (typeof PASSPORT_FIELDS)[number];

export type PassportFields = Record<PassportField, string | null>;
export type PassportConfidences = Record<PassportField, number | null>;

export function emptyPassportFields(): PassportFields {
  return {
    fullName: null,
    passportNumber: null,
    nationality: null,
    dateOfBirth: null,
    sex: null,
    issueDate: null,
    expiryDate: null,
  };
}

/** Parse the vision model's JSON reply tolerantly (fences, prose around it). */
export function parsePassportExtraction(raw: string): {
  fields: PassportFields;
  confidence: PassportConfidences;
} {
  const fields = emptyPassportFields();
  const confidence: PassportConfidences = {
    fullName: null,
    passportNumber: null,
    nationality: null,
    dateOfBirth: null,
    sex: null,
    issueDate: null,
    expiryDate: null,
  };
  const start = raw.indexOf('{');
  const end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) return { fields, confidence };
  try {
    const parsed = JSON.parse(raw.slice(start, end + 1)) as {
      fields?: Record<string, unknown>;
      confidence?: Record<string, unknown>;
    };
    for (const field of PASSPORT_FIELDS) {
      const value = parsed.fields?.[field];
      if (typeof value === 'string' && value.trim()) {
        fields[field] = value.trim().slice(0, 160);
      }
      const conf = Number(parsed.confidence?.[field]);
      if (Number.isFinite(conf)) {
        confidence[field] = Math.min(1, Math.max(0, conf));
      }
    }
  } catch {
    // Unreadable model reply = all fields null; the human queue handles it.
  }
  return { fields, confidence };
}

/** Normalise for comparison: case, spaces, punctuation, date separators. */
export function normalizeForCompare(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[-/.]/g, ' ')
    .replace(/[^\p{L}\p{N} ]/gu, '')
    .replace(/\s+/g, ' ');
}

export type ComparisonStatus =
  | 'match'
  | 'mismatch'
  | 'missing_extracted'
  | 'missing_typed';

export type FieldComparison = {
  field: PassportField;
  extracted: string | null;
  typed: string | null;
  saved: string | null;
  confidence: number | null;
  status: ComparisonStatus;
  /** Saved profile disagrees with the document — shown, never auto-fixed. */
  savedMismatch: boolean;
};

export function buildComparisons(input: {
  extracted: PassportFields;
  confidence: PassportConfidences;
  typed: Partial<Record<PassportField, string | null>>;
  saved: Partial<Record<PassportField, string | null>>;
}): FieldComparison[] {
  return PASSPORT_FIELDS.map((field) => {
    const extracted = input.extracted[field];
    const typed = input.typed[field]?.trim() ? input.typed[field] : null;
    const saved = input.saved[field]?.trim() ? input.saved[field] : null;
    let status: ComparisonStatus;
    if (!extracted) {
      status = 'missing_extracted';
    } else if (!typed) {
      status = 'missing_typed';
    } else {
      status =
        normalizeForCompare(extracted) === normalizeForCompare(typed)
          ? 'match'
          : 'mismatch';
    }
    return {
      field,
      extracted,
      typed,
      saved,
      confidence: input.confidence[field],
      status,
      savedMismatch:
        extracted !== null &&
        saved !== null &&
        normalizeForCompare(extracted) !== normalizeForCompare(saved),
    };
  });
}

export function hasMismatch(comparisons: readonly FieldComparison[]): boolean {
  return comparisons.some(
    (row) => row.status === 'mismatch' || row.savedMismatch,
  );
}
