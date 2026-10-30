// Made by Dr Ali

import { appNameKey, assertAppNote, assertAppUrl, normalizeAppName } from './company-app';

describe('company apps', () => {
  it('collapses a name and keeps the lowercase key', () => {
    expect(normalizeAppName('  Leave   desk ')).toBe('Leave desk');
    expect(appNameKey('Leave Desk')).toBe('leave desk');
    expect(() => normalizeAppName('  ')).toThrow('APP_NAME');
  });

  it('keeps an https address and drops a blank note', () => {
    expect(assertAppUrl('https://www.obicgp.com/tools')).toBe('https://www.obicgp.com/tools');
    expect(assertAppNote('  ')).toBeNull();
    expect(() => assertAppUrl('http://www.obicgp.com')).toThrow('APP_URL');
    expect(() => assertAppUrl('https://user:secret@www.obicgp.com')).toThrow('APP_URL');
  });
});
