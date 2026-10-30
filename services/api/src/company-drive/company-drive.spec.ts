// Made by Dr Ali

import {
  assertDriveBytes,
  driveContentDisposition,
  driveFileParts,
  driveFolderKey,
  driveMime,
  normalizeDriveFolderName,
} from './company-drive';

describe('company drive', () => {
  it('collapses a folder name and treats case as the same folder', () => {
    expect(normalizeDriveFolderName('  Sales   kit ')).toBe('Sales kit');
    expect(driveFolderKey('Sales kit')).toBe(driveFolderKey('sales kit'));
    expect(() => normalizeDriveFolderName('  ')).toThrow('DRIVE_FOLDER_NAME');
  });

  it('keeps the file name, strips a path, and rejects other types', () => {
    const pdf = driveFileParts('C:\\desk\\Price List.PDF');
    expect(pdf.name).toBe('Price List.PDF');
    expect(pdf.ext).toBe('pdf');
    expect(pdf.key).toBe(driveFileParts('price list.pdf').key);
    expect(driveMime(pdf.ext)).toBe('application/pdf');
    expect(() => driveFileParts('notes.exe')).toThrow('DRIVE_TYPE');
    expect(() => driveFileParts('no-extension')).toThrow('DRIVE_TYPE');
  });

  it('accepts a small file and rejects an empty or oversized one', () => {
    expect(() => assertDriveBytes(1)).not.toThrow();
    expect(() => assertDriveBytes(0)).toThrow('DRIVE_SIZE');
    expect(() => assertDriveBytes(8 * 1024 * 1024 + 1)).toThrow('DRIVE_SIZE');
  });

  it('builds a download name without a quote', () => {
    expect(driveContentDisposition('a"b.pdf')).toContain('filename="ab.pdf"');
  });
});
