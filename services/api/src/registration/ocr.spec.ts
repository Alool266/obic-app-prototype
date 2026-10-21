// Made by Dr Ali

import {
  buildComparisons,
  emptyPassportFields,
  hasMismatch,
  normalizeForCompare,
  parsePassportExtraction,
} from './ocr';

describe('passport extraction parsing', () => {
  it('parses model JSON even with prose around it', () => {
    const raw =
      'Here is the result: {"fields":{"fullName":"ALI AHMED","passportNumber":"P123456","nationality":"Yemen","dateOfBirth":"1990-01-02","sex":"M","issueDate":null,"expiryDate":"2030-01-02"},"confidence":{"fullName":0.98}} done';
    const { fields, confidence } = parsePassportExtraction(raw);
    expect(fields.fullName).toBe('ALI AHMED');
    expect(fields.passportNumber).toBe('P123456');
    expect(fields.issueDate).toBeNull();
    expect(confidence.fullName).toBe(0.98);
  });

  it('returns all-null fields for garbage output (human queue handles it)', () => {
    const { fields } = parsePassportExtraction('not json at all');
    expect(fields).toEqual(emptyPassportFields());
  });

  it('clamps confidence into 0..1', () => {
    const { confidence } = parsePassportExtraction(
      '{"fields":{},"confidence":{"fullName":7}}',
    );
    expect(confidence.fullName).toBe(1);
  });
});

describe('three-way comparison (TST-006)', () => {
  const extracted = {
    ...emptyPassportFields(),
    fullName: 'ALI AHMED',
    passportNumber: 'P123456',
    dateOfBirth: '1990-01-02',
  };
  const confidence = {
    fullName: 0.9,
    passportNumber: 0.9,
    nationality: null,
    dateOfBirth: 0.9,
    sex: null,
    issueDate: null,
    expiryDate: null,
  };

  it('matches ignoring case, spacing, and date separators', () => {
    expect(normalizeForCompare(' Ali  Ahmed ')).toBe(
      normalizeForCompare('ALI AHMED'),
    );
    expect(normalizeForCompare('1990-01-02')).toBe(
      normalizeForCompare('1990/01/02'),
    );
    const rows = buildComparisons({
      extracted,
      confidence,
      typed: { fullName: 'ali ahmed', passportNumber: 'p123456', dateOfBirth: '1990/01/02' },
      saved: {},
    });
    expect(rows.every((r) => r.status !== 'mismatch')).toBe(true);
    expect(hasMismatch(rows)).toBe(false);
  });

  it('flags a typo as mismatch — and never fixes it silently', () => {
    const rows = buildComparisons({
      extracted,
      confidence,
      typed: { fullName: 'ALI AHMAD' },
      saved: {},
    });
    const name = rows.find((r) => r.field === 'fullName');
    expect(name?.status).toBe('mismatch');
    expect(name?.typed).toBe('ALI AHMAD');
    expect(hasMismatch(rows)).toBe(true);
  });

  it('marks unreadable fields and missing typed values distinctly', () => {
    const rows = buildComparisons({
      extracted: emptyPassportFields(),
      confidence,
      typed: {},
      saved: {},
    });
    expect(rows[0].status).toBe('missing_extracted');
    const rows2 = buildComparisons({
      extracted,
      confidence,
      typed: {},
      saved: {},
    });
    expect(rows2.find((r) => r.field === 'fullName')?.status).toBe('missing_typed');
  });

  it('shows a saved-profile disagreement without counting it as typed mismatch', () => {
    const rows = buildComparisons({
      extracted,
      confidence,
      typed: { fullName: 'ALI AHMED' },
      saved: { fullName: 'Ali A. Ahmed' },
    });
    const name = rows.find((r) => r.field === 'fullName');
    expect(name?.status).toBe('match');
    expect(name?.savedMismatch).toBe(true);
    expect(hasMismatch(rows)).toBe(true);
  });
});
