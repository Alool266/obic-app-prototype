// Made by Dr Ali
// A staff form: a short list of fields, then the answers checked against that list.

export const OFFICE_FIELD_TYPES = [
  'short_text',
  'long_text',
  'number',
  'choice',
] as const;

export type OfficeFieldType = (typeof OFFICE_FIELD_TYPES)[number];

export type OfficeFieldDef = {
  key: string;
  labelEn: string;
  labelAr: string;
  labelZh: string;
  type: OfficeFieldType;
  required: boolean;
  options: string[];
};

const KEY_PATTERN = /^[a-z][a-z0-9_]{0,31}$/;

export function isOfficeFieldType(value: string): value is OfficeFieldType {
  return (OFFICE_FIELD_TYPES as readonly string[]).includes(value);
}

export function assertOfficeFields(fields: OfficeFieldDef[]): OfficeFieldDef[] {
  if (fields.length < 1 || fields.length > 12) {
    throw new Error('FIELD_COUNT');
  }
  const keys = new Set<string>();
  return fields.map((field) => {
    const key = field.key.trim();
    if (!KEY_PATTERN.test(key) || keys.has(key)) {
      throw new Error('FIELD_KEY');
    }
    keys.add(key);
    const labelEn = field.labelEn.trim();
    const labelAr = field.labelAr.trim();
    const labelZh = field.labelZh.trim();
    if (
      !labelEn ||
      !labelAr ||
      !labelZh ||
      labelEn.length > 80 ||
      labelAr.length > 80 ||
      labelZh.length > 80
    ) {
      throw new Error('FIELD_LABEL');
    }
    const options = uniqueOptions(field.options);
    if (field.type === 'choice') {
      if (options.length < 2 || options.length > 8) {
        throw new Error('FIELD_OPTIONS');
      }
    } else if (options.length > 0) {
      throw new Error('FIELD_OPTIONS');
    }
    return {
      key,
      labelEn,
      labelAr,
      labelZh,
      type: field.type,
      required: field.required,
      options,
    };
  });
}

export function validateOfficeAnswers(
  fields: OfficeFieldDef[],
  answers: Record<string, unknown>,
): Record<string, string> {
  const saved: Record<string, string> = {};
  for (const field of fields) {
    const raw = answers[field.key];
    const text = typeof raw === 'string' ? raw.trim() : '';
    if (!text) {
      if (field.required) throw new Error('FIELD_REQUIRED');
      saved[field.key] = '';
      continue;
    }
    saved[field.key] = checkAnswer(field, text);
  }
  return saved;
}

function checkAnswer(field: OfficeFieldDef, text: string): string {
  switch (field.type) {
    case 'short_text':
      if (text.length > 500) throw new Error('FIELD_TOO_LONG');
      return text;
    case 'long_text':
      if (text.length > 2000) throw new Error('FIELD_TOO_LONG');
      return text;
    case 'number':
      if (!/^-?\d+(\.\d+)?$/.test(text)) throw new Error('FIELD_NUMBER');
      return text;
    case 'choice':
      if (!field.options.includes(text)) throw new Error('FIELD_CHOICE');
      return text;
    default: {
      const neverType: never = field.type;
      throw new Error(neverType);
    }
  }
}

function uniqueOptions(options: string[]): string[] {
  const seen = new Set<string>();
  const next: string[] = [];
  for (const option of options) {
    const text = option.trim();
    if (!text || seen.has(text)) continue;
    if (text.length > 80) throw new Error('FIELD_OPTIONS');
    seen.add(text);
    next.push(text);
  }
  return next;
}
