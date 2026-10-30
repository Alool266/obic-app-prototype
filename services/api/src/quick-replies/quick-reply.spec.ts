// Made by Dr Ali

import { assertQuickBody, assertQuickTitle, quickTitleKey } from './quick-reply';

describe('quick reply', () => {
  it('collapses a title and treats case as the same reply', () => {
    expect(assertQuickTitle('  Price   list ')).toBe('Price list');
    expect(quickTitleKey('Hours')).toBe(quickTitleKey('hours'));
    expect(() => assertQuickTitle('  ')).toThrow('QUICK_TITLE');
  });

  it('keeps a short body and rejects an empty one', () => {
    expect(assertQuickBody('  We are open.  ')).toBe('We are open.');
    expect(() => assertQuickBody('   ')).toThrow('QUICK_BODY');
  });
});
