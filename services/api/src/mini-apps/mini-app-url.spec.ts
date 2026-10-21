// Made by Dr Ali

import { BadRequestException } from '@nestjs/common';
import { assertHttpsPageUrl, normalizeIconUrl } from './mini-app-url';

describe('assertHttpsPageUrl', () => {
  it('accepts a normal HTTPS page', () => {
    expect(assertHttpsPageUrl('https://games.example.com/play')).toBe(
      'https://games.example.com/play',
    );
  });

  it('rejects http, javascript, and credential URLs', () => {
    expect(() => assertHttpsPageUrl('http://games.example.com')).toThrow(
      BadRequestException,
    );
    expect(() => assertHttpsPageUrl('javascript:alert(1)')).toThrow(
      BadRequestException,
    );
    expect(() =>
      assertHttpsPageUrl('https://user:secret@games.example.com/'),
    ).toThrow(BadRequestException);
  });
});

describe('normalizeIconUrl', () => {
  it('keeps HTTPS icons and uploaded paths', () => {
    expect(normalizeIconUrl('')).toBeNull();
    expect(normalizeIconUrl(' https://cdn.example.com/a.png ')).toBe(
      'https://cdn.example.com/a.png',
    );
    expect(normalizeIconUrl('/uploads/icon.png')).toBe('/uploads/icon.png');
    expect(
      normalizeIconUrl('http://127.0.0.1:3001/uploads/icon.png'),
    ).toBe('http://127.0.0.1:3001/uploads/icon.png');
  });

  it('rejects non-HTTPS icons that are not uploads', () => {
    expect(() => normalizeIconUrl('http://cdn.example.com/a.png')).toThrow(
      BadRequestException,
    );
    expect(() => normalizeIconUrl('/etc/passwd')).toThrow(BadRequestException);
  });
});
