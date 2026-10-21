// Made by Dr Ali

import { assertMailBody, assertMailRecipients, normalizeMailSubject } from './company-mail';

const ALI = '6f0e2a10-0005-4000-8000-000000000001';
const SARA = '6f0e2a10-0005-4000-8000-000000000002';

describe('company mail', () => {
  it('collapses a subject and rejects an empty message', () => {
    expect(normalizeMailSubject('  Weekly   note ')).toBe('Weekly note');
    expect(() => normalizeMailSubject('  ')).toThrow('MAIL_SUBJECT');
    expect(assertMailBody('  Hello.  ')).toBe('Hello.');
    expect(() => assertMailBody('   ')).toThrow('MAIL_BODY');
  });

  it('drops the sender and keeps other staff once', () => {
    const allowed = new Set([ALI, SARA]);
    expect(assertMailRecipients([ALI, SARA, SARA], ALI, allowed)).toEqual([SARA]);
    expect(() => assertMailRecipients([ALI], ALI, allowed)).toThrow('MAIL_RECIPIENT');
    expect(() => assertMailRecipients(['6f0e2a10-0005-4000-8000-000000000099'], ALI, allowed)).toThrow(
      'MAIL_RECIPIENT',
    );
  });
});
