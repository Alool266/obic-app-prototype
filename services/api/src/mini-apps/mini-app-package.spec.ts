// Made by Dr Ali

import { BadRequestException } from '@nestjs/common';
import { strToU8, zipSync } from 'fflate';
import {
  packageFilePathFromUrl,
  safePackagePath,
  unpackMiniAppZip,
  validatePackageFiles,
} from './mini-app-package';

describe('safePackagePath', () => {
  it('keeps root and nested files', () => {
    expect(safePackagePath('index.html')).toBe('index.html');
    expect(safePackagePath('css/app.css')).toBe('css/app.css');
    expect(safePackagePath('./js/game.js')).toBe('js/game.js');
  });

  it('rejects zip-slip, absolute paths, and empty names', () => {
    expect(safePackagePath('../etc/passwd')).toBeNull();
    expect(safePackagePath('css/../../etc/passwd')).toBeNull();
    expect(safePackagePath('/etc/passwd')).toBeNull();
    expect(safePackagePath('C:/Windows/notepad.exe')).toBeNull();
    expect(safePackagePath('foo\\..\\bar.html')).toBeNull();
    expect(safePackagePath('')).toBeNull();
  });
});

describe('unpackMiniAppZip', () => {
  it('accepts index.html plus an allowed asset', () => {
    const zip = Buffer.from(
      zipSync({
        'index.html': strToU8('<html></html>'),
        'js/app.js': strToU8('console.log(1)'),
        'css/app.css': strToU8('body{}'),
      }),
    );
    const files = unpackMiniAppZip(zip);
    expect(files.map((file) => file.path).sort()).toEqual([
      'css/app.css',
      'index.html',
      'js/app.js',
    ]);
    expect(files.find((file) => file.path === 'index.html')?.mime).toContain('text/html');
  });

  it('rejects a missing index, server-side files, and zip-slip names', () => {
    const noIndex = Buffer.from(zipSync({ 'app.js': strToU8('1') }));
    expect(() => unpackMiniAppZip(noIndex)).toThrow(BadRequestException);

    const php = Buffer.from(
      zipSync({
        'index.html': strToU8('<html></html>'),
        'api.php': strToU8('<?php'),
      }),
    );
    expect(() => unpackMiniAppZip(php)).toThrow(BadRequestException);

    const slip = Buffer.from(
      zipSync({
        'index.html': strToU8('<html></html>'),
        '../secret.txt': strToU8('nope'),
      }),
    );
    expect(() => unpackMiniAppZip(slip)).toThrow(BadRequestException);
  });

  it('rejects an uncompressed package over the cap', () => {
    expect(() =>
      validatePackageFiles(
        [{ path: 'index.html', data: new Uint8Array(20) }],
        8,
      ),
    ).toThrow(BadRequestException);
  });
});

describe('packageFilePathFromUrl', () => {
  const id = '11111111-1111-4111-8111-111111111111';

  it('reads a nested file and blocks traversal in the URL', () => {
    const marker = `/v1/mini-apps/${id}/files/`;
    expect(
      packageFilePathFromUrl(
        `/v1/mini-apps/${id}/files/css/app.css`,
        marker,
      ),
    ).toBe('css/app.css');
    expect(
      packageFilePathFromUrl(
        `/v1/mini-apps/${id}/files/../users/me`,
        marker,
      ),
    ).toBeNull();
  });
});
