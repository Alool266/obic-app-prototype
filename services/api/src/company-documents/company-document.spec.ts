// Made by Dr Ali

import { assertDocBody, docTitleKey, normalizeDocTitle } from './company-document';

describe('company document', () => {
  it('collapses a title and treats case as the same document', () => {
    expect(normalizeDocTitle('  Price   list ')).toBe('Price list');
    expect(docTitleKey('Price list')).toBe(docTitleKey('price list'));
    expect(() => normalizeDocTitle('  ')).toThrow('DOC_TITLE');
  });

  it('keeps the text and rejects an empty document', () => {
    expect(assertDocBody('  Hello team.  ')).toBe('Hello team.');
    expect(() => assertDocBody('   ')).toThrow('DOC_BODY');
  });
});
