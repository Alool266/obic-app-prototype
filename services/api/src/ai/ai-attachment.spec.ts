// Made by Dr Ali
import { strToU8, zipSync } from 'fflate';
import {
  AI_ATTACHMENT_MAX_BYTES,
  AI_FILE_TEXT_CAP,
  extractFileText,
  parseAiAttachment,
} from './ai-attachment';

describe('parseAiAttachment', () => {
  it('accepts a jpeg photo and rejects other types', () => {
    const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0x00, 0xd9]);
    const parsed = parseAiAttachment({
      filename: 'photo.jpg',
      mime: 'image/jpeg',
      dataBase64: jpeg.toString('base64'),
    });
    expect(parsed.kind).toBe('image');
    if (parsed.kind === 'image') expect(parsed.mime).toBe('image/jpeg');

    const gif = Buffer.from('GIF89a', 'ascii');
    expect(() =>
      parseAiAttachment({
        filename: 'anim.gif',
        mime: 'image/gif',
        dataBase64: gif.toString('base64'),
      }),
    ).toThrow(/supported/i);
  });

  it('rejects files over 4 MB', () => {
    const big = Buffer.alloc(AI_ATTACHMENT_MAX_BYTES + 1);
    big[0] = 0xff;
    big[1] = 0xd8;
    big[2] = 0xff;
    expect(() =>
      parseAiAttachment({
        filename: 'big.jpg',
        mime: 'image/jpeg',
        dataBase64: big.toString('base64'),
      }),
    ).toThrow(/4 MB/);
  });

  it('extracts csv text and caps the chunk', async () => {
    const csv = `name,note\n${'x'.repeat(AI_FILE_TEXT_CAP + 50)}`;
    const parsed = parseAiAttachment({
      filename: 'notes.csv',
      mime: 'text/csv',
      dataBase64: Buffer.from(csv, 'utf8').toString('base64'),
    });
    expect(parsed.kind).toBe('file');
    if (parsed.kind !== 'file') return;
    const extracted = await extractFileText(parsed);
    expect(extracted.truncated).toBe(true);
    expect(extracted.text.length).toBe(AI_FILE_TEXT_CAP);
    expect(extracted.text.startsWith('name,note')).toBe(true);
  });

  it('extracts xlsx cell text and does not treat it as an image', async () => {
    const shared = strToU8(
      '<?xml version="1.0"?><sst><si><t>Visa fee</t></si></sst>',
    );
    const sheet = strToU8(
      '<?xml version="1.0"?><worksheet><sheetData><row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1"><v>100</v></c></row></sheetData></worksheet>',
    );
    const workbook = strToU8(
      '<workbook><sheets><sheet name="Fees" sheetId="1" r:id="rId1"/></sheets></workbook>',
    );
    const rels = strToU8(
      '<Relationships><Relationship Id="rId1" Type="worksheet" Target="worksheets/sheet1.xml"/></Relationships>',
    );
    const zipped = Buffer.from(
      zipSync({
        'xl/sharedStrings.xml': shared,
        'xl/worksheets/sheet1.xml': sheet,
        'xl/workbook.xml': workbook,
        'xl/_rels/workbook.xml.rels': rels,
      }),
    );
    const parsed = parseAiAttachment({
      filename: 'fees.xlsx',
      mime: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      dataBase64: zipped.toString('base64'),
    });
    expect(parsed.kind).toBe('file');
    if (parsed.kind !== 'file') return;
    expect(parsed.extension).toBe('xlsx');
    const extracted = await extractFileText(parsed);
    expect(extracted.text).toContain('Visa fee');
    expect(extracted.text).toContain('100');
    expect(extracted.text).not.toContain('image_url');
  });

  it('asks for xlsx or csv when the file is legacy xls', async () => {
    const ole = Buffer.from([0xd0, 0xcf, 0x11, 0xe0, 0x00]);
    const parsed = parseAiAttachment({
      filename: 'old.xls',
      mime: 'application/vnd.ms-excel',
      dataBase64: ole.toString('base64'),
    });
    expect(parsed.kind).toBe('file');
    if (parsed.kind !== 'file') return;
    await expect(extractFileText(parsed)).rejects.toThrow(/xlsx or CSV/i);
  });
});
