// Made by Dr Ali
import { isChinaMobile, normalizeChinaMobile } from './china-phone.util';

describe('China mobile normalize', () => {
  it('accepts +86 / 86 / bare 11-digit', () => {
    expect(normalizeChinaMobile('+8613812345678')).toBe('+8613812345678');
    expect(normalizeChinaMobile('8613812345678')).toBe('+8613812345678');
    expect(normalizeChinaMobile('13812345678')).toBe('+8613812345678');
    expect(normalizeChinaMobile('138-1234-5678')).toBe('+8613812345678');
  });

  it('rejects non-CN', () => {
    expect(isChinaMobile('+966501234567')).toBe(false);
    expect(isChinaMobile('+12025550123')).toBe(false);
    expect(isChinaMobile('12345')).toBe(false);
  });
});
