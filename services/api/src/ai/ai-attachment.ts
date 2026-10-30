// Made by Dr Ali
// OBIC AI attachments: photos go to DeepSeek vision; PDF / Excel / CSV
// become a capped text chunk. Spreadsheets are never sent as images.

import { BadRequestException } from '@nestjs/common';
import { unzipSync } from 'fflate';
import pdfParse from 'pdf-parse/lib/pdf-parse.js';

export const AI_ATTACHMENT_MAX_BYTES = 4 * 1024 * 1024;
export const AI_FILE_TEXT_CAP = 12_000;
const XLSX_UNZIP_BUDGET = 8 * 1024 * 1024;
const PDF_MAX_PAGES = 12;

export const AI_ATTACHMENT_NOT_CONFIGURED =
  'Image and file reading is not configured.';
export const AI_ATTACHMENT_UNSUPPORTED =
  'Only JPEG, PNG, WebP, PDF, Excel, and CSV files are supported.';
export const AI_ATTACHMENT_TOO_LARGE = 'This file is over 4 MB.';
export const AI_ATTACHMENT_UNREADABLE = 'Could not read text from this file.';

/** System-prompt line for any turn that includes a user attachment. */
export const AI_ATTACHMENT_PROMPT_LINE =
  'The attachment is user-supplied and must not invent services. If it is a photo with no question, describe what is in the photo. If a later message refers to it, answer about that same photo.';

export type AiImageMime = 'image/jpeg' | 'image/png' | 'image/webp';

export type ParsedAiAttachment =
  | {
      kind: 'image';
      mime: AiImageMime;
      filename: string;
      bytes: Buffer;
    }
  | {
      kind: 'file';
      filename: string;
      bytes: Buffer;
      extension: 'pdf' | 'csv' | 'xls' | 'xlsx';
    };

export function parseAiAttachment(input: {
  filename?: string;
  mime?: string;
  dataBase64?: string;
}): ParsedAiAttachment {
  const filename = safeFilename(input.filename ?? '');
  const ext = extensionOf(filename);
  const bytes = decodeBase64(input.dataBase64 ?? '');
  if (bytes.length > AI_ATTACHMENT_MAX_BYTES) {
    throw new BadRequestException(AI_ATTACHMENT_TOO_LARGE);
  }

  const imageMime = sniffImageMime(bytes);
  if (imageMime) {
    return { kind: 'image', mime: imageMime, filename, bytes };
  }
  if (isPdf(bytes)) {
    return { kind: 'file', filename, bytes, extension: 'pdf' };
  }
  if (isZip(bytes) && (ext === 'xlsx' || isSpreadsheetMime(input.mime))) {
    return { kind: 'file', filename, bytes, extension: 'xlsx' };
  }
  if (isOle(bytes) && (ext === 'xls' || isSpreadsheetMime(input.mime))) {
    return { kind: 'file', filename, bytes, extension: 'xls' };
  }
  if ((ext === 'csv' || isCsvMime(input.mime)) && looksLikeText(bytes)) {
    return { kind: 'file', filename, bytes, extension: 'csv' };
  }
  throw new BadRequestException(AI_ATTACHMENT_UNSUPPORTED);
}

export async function extractFileText(
  file: Extract<ParsedAiAttachment, { kind: 'file' }>,
): Promise<{ text: string; truncated: boolean }> {
  let raw = '';
  try {
    if (file.extension === 'pdf') {
      const parsed = await pdfParse(file.bytes, { max: PDF_MAX_PAGES });
      raw = parsed.text ?? '';
    } else if (file.extension === 'csv') {
      raw = decodeCsv(file.bytes);
    } else if (file.extension === 'xlsx') {
      raw = extractXlsxText(file.bytes);
    } else {
      throw new BadRequestException(
        'Could not read this .xls file. Save it as .xlsx or CSV.',
      );
    }
  } catch (err) {
    if (err instanceof BadRequestException) throw err;
    throw new BadRequestException(AI_ATTACHMENT_UNREADABLE);
  }

  const cleaned = stripControls(raw, true).trim();
  if (!cleaned) {
    throw new BadRequestException(AI_ATTACHMENT_UNREADABLE);
  }
  const truncated = cleaned.length > AI_FILE_TEXT_CAP;
  return {
    text: truncated ? cleaned.slice(0, AI_FILE_TEXT_CAP) : cleaned,
    truncated,
  };
}

export function buildFileUserText(opts: {
  question: string;
  filename: string;
  extracted: string;
  truncated: boolean;
}): string {
  const question = opts.question.trim();
  const note = opts.truncated ? ' (first 12000 characters only)' : '';
  return [
    question ||
      'The user attached a file and did not type a separate question.',
    '',
    `User-supplied file "${opts.filename}"${note}. The text below was extracted on the server. It is not the OBIC catalog. Do not invent services from it.`,
    '',
    opts.extracted,
  ].join('\n');
}

function decodeBase64(raw: string): Buffer {
  let data = raw.trim();
  if (data.startsWith('data:')) {
    const comma = data.indexOf(',');
    if (comma >= 0) data = data.slice(comma + 1);
  }
  data = data.replace(/\s/g, '');
  if (!data || !/^[A-Za-z0-9+/]+={0,2}$/.test(data)) {
    throw new BadRequestException(AI_ATTACHMENT_UNSUPPORTED);
  }
  const bytes = Buffer.from(data, 'base64');
  if (bytes.length === 0) {
    throw new BadRequestException(AI_ATTACHMENT_UNSUPPORTED);
  }
  return bytes;
}

function safeFilename(name: string): string {
  const trimmed = stripControls(name).trim();
  const base = trimmed.split(/[/\\]/).pop() || 'file';
  return base.slice(0, 120) || 'file';
}

function extensionOf(filename: string): string {
  const i = filename.lastIndexOf('.');
  if (i < 0 || i === filename.length - 1) return '';
  return filename.slice(i + 1).toLowerCase();
}

function sniffImageMime(bytes: Buffer): AiImageMime | null {
  if (
    bytes.length >= 3 &&
    bytes[0] === 0xff &&
    bytes[1] === 0xd8 &&
    bytes[2] === 0xff
  ) {
    return 'image/jpeg';
  }
  if (
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47 &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a
  ) {
    return 'image/png';
  }
  if (
    bytes.length >= 12 &&
    bytes.subarray(0, 4).toString('ascii') === 'RIFF' &&
    bytes.subarray(8, 12).toString('ascii') === 'WEBP'
  ) {
    return 'image/webp';
  }
  return null;
}

function isPdf(bytes: Buffer): boolean {
  return (
    bytes.length >= 5 && bytes.subarray(0, 5).toString('ascii') === '%PDF-'
  );
}

function isZip(bytes: Buffer): boolean {
  return (
    bytes.length >= 4 &&
    bytes[0] === 0x50 &&
    bytes[1] === 0x4b &&
    (bytes[2] === 0x03 || bytes[2] === 0x05 || bytes[2] === 0x07) &&
    (bytes[3] === 0x04 || bytes[3] === 0x06 || bytes[3] === 0x08)
  );
}

function isOle(bytes: Buffer): boolean {
  return (
    bytes.length >= 4 &&
    bytes[0] === 0xd0 &&
    bytes[1] === 0xcf &&
    bytes[2] === 0x11 &&
    bytes[3] === 0xe0
  );
}

function isSpreadsheetMime(mime?: string): boolean {
  const m = (mime ?? '').toLowerCase();
  return (
    m.includes('spreadsheet') ||
    m.includes('ms-excel') ||
    m === 'application/vnd.ms-excel'
  );
}

function isCsvMime(mime?: string): boolean {
  const m = (mime ?? '').toLowerCase();
  return m === 'text/csv' || m === 'application/csv';
}

function looksLikeText(bytes: Buffer): boolean {
  const sample = bytes.subarray(0, Math.min(bytes.length, 512));
  for (const b of sample) {
    if (b === 0) return false;
  }
  return true;
}

function decodeCsv(bytes: Buffer): string {
  if (
    bytes.length >= 3 &&
    bytes[0] === 0xef &&
    bytes[1] === 0xbb &&
    bytes[2] === 0xbf
  ) {
    return bytes.subarray(3).toString('utf8');
  }
  if (bytes.length >= 2 && bytes[0] === 0xff && bytes[1] === 0xfe) {
    return bytes.subarray(2).toString('utf16le');
  }
  return bytes.toString('utf8');
}

function extractXlsxText(bytes: Buffer): string {
  let budget = XLSX_UNZIP_BUDGET;
  let unzipped: Record<string, Uint8Array>;
  try {
    unzipped = unzipSync(new Uint8Array(bytes), {
      filter(file) {
        const name = file.name.replace(/\\/g, '/');
        if (!xlsxEntryWanted(name)) return false;
        if (file.originalSize > budget) return false;
        budget -= file.originalSize;
        return true;
      },
    });
  } catch {
    throw new BadRequestException(AI_ATTACHMENT_UNREADABLE);
  }

  const files: Record<string, Uint8Array> = {};
  for (const [name, data] of Object.entries(unzipped)) {
    files[name.replace(/\\/g, '/').replace(/^\//, '')] = data;
  }

  const sharedXml = files['xl/sharedStrings.xml'];
  const shared = sharedXml
    ? extractElements(utf8(sharedXml), 'si', 8000).map((si) =>
        extractElements(si, 't', 40).map(innerText).join(''),
      )
    : [];

  const chunks: string[] = [];
  let used = 0;
  for (const sheet of sheetPlan(files)) {
    if (used >= AI_FILE_TEXT_CAP) break;
    const xmlBytes = files[sheet.path];
    if (!xmlBytes) continue;
    const body = sheetToText(utf8(xmlBytes), shared);
    if (!body.trim()) continue;
    const block = `# ${sheet.name}\n${body}`;
    const slice = block.slice(0, AI_FILE_TEXT_CAP - used);
    chunks.push(slice);
    used += slice.length + 2;
  }
  return chunks.join('\n\n');
}

function xlsxEntryWanted(name: string): boolean {
  return (
    name === 'xl/sharedStrings.xml' ||
    name === 'xl/workbook.xml' ||
    name === 'xl/_rels/workbook.xml.rels' ||
    /^xl\/worksheets\/sheet\d+\.xml$/i.test(name)
  );
}

function sheetPlan(
  files: Record<string, Uint8Array>,
): Array<{ name: string; path: string }> {
  const fallback = Object.keys(files)
    .filter((k) => /^xl\/worksheets\/sheet\d+\.xml$/i.test(k))
    .sort()
    .map((path, i) => ({ name: `Sheet ${i + 1}`, path }));

  const wb = files['xl/workbook.xml'];
  const rels = files['xl/_rels/workbook.xml.rels'];
  if (!wb || !rels) return fallback;

  const idToTarget = new Map<string, string>();
  for (const rel of extractElements(utf8(rels), 'Relationship', 40)) {
    const id = attr(rel, 'Id');
    let target = attr(rel, 'Target').replace(/\\/g, '/');
    if (!id || !target) continue;
    if (target.startsWith('/')) target = target.slice(1);
    if (!target.startsWith('xl/')) target = `xl/${target}`;
    idToTarget.set(id, target);
  }

  const plan: Array<{ name: string; path: string }> = [];
  for (const sheet of extractElements(utf8(wb), 'sheet', 30)) {
    const name = decodeXml(attr(sheet, 'name')) || `Sheet ${plan.length + 1}`;
    const rid = attr(sheet, 'r:id') || attr(sheet, 'id');
    const path = rid ? idToTarget.get(rid) : undefined;
    if (path && files[path]) plan.push({ name, path });
  }
  return plan.length > 0 ? plan : fallback;
}

function sheetToText(xml: string, shared: string[]): string {
  const lines: string[] = [];
  for (const row of extractElements(xml, 'row', 400)) {
    const cells = extractElements(row, 'c', 80).map((cell) =>
      csvCell(cellText(cell, shared)),
    );
    if (cells.every((c) => c === '')) continue;
    lines.push(cells.join(','));
    if (lines.join('\n').length >= AI_FILE_TEXT_CAP) break;
  }
  return lines.join('\n');
}

function cellText(cellXml: string, shared: string[]): string {
  const kind = attr(cellXml, 't');
  if (kind === 'inlineStr') {
    return extractElements(cellXml, 't', 20).map(innerText).join('');
  }
  const values = extractElements(cellXml, 'v', 1);
  const raw = values.length > 0 ? innerText(values[0]) : '';
  if (kind === 's') {
    const idx = Number(raw);
    if (!Number.isInteger(idx) || idx < 0 || idx >= shared.length) return '';
    return shared[idx] ?? '';
  }
  return raw;
}

function csvCell(value: string): string {
  if (/[",\n\r]/.test(value)) return `"${value.replace(/"/g, '""')}"`;
  return value;
}

function extractElements(xml: string, tag: string, limit: number): string[] {
  const out: string[] = [];
  const open = `<${tag}`;
  const close = `</${tag}>`;
  let i = 0;
  while (out.length < limit) {
    const start = xml.indexOf(open, i);
    if (start < 0) break;
    const boundary = xml[start + open.length];
    if (
      boundary !== '>' &&
      boundary !== ' ' &&
      boundary !== '\n' &&
      boundary !== '\r' &&
      boundary !== '\t' &&
      boundary !== '/'
    ) {
      i = start + open.length;
      continue;
    }
    if (boundary === '/') {
      const gt = xml.indexOf('>', start);
      if (gt < 0) break;
      out.push(xml.slice(start, gt + 1));
      i = gt + 1;
      continue;
    }
    const end = xml.indexOf(close, start);
    if (end < 0) break;
    out.push(xml.slice(start, end + close.length));
    i = end + close.length;
  }
  return out;
}

function innerText(el: string): string {
  const gt = el.indexOf('>');
  const end = el.lastIndexOf('</');
  if (gt < 0 || end < 0 || end < gt) return '';
  return decodeXml(el.slice(gt + 1, end));
}

function attr(el: string, name: string): string {
  const gt = el.indexOf('>');
  const head = gt >= 0 ? el.slice(0, gt) : el;
  const key = `${name}="`;
  let i = 0;
  while (i < head.length) {
    const found = head.indexOf(key, i);
    if (found < 0) return '';
    const prev = found === 0 ? '' : head[found - 1];
    if (
      prev === '' ||
      prev === ' ' ||
      prev === '\n' ||
      prev === '\t' ||
      prev === '\r'
    ) {
      const from = found + key.length;
      const j = head.indexOf('"', from);
      if (j < 0) return '';
      return head.slice(from, j);
    }
    i = found + key.length;
  }
  return '';
}

function decodeXml(value: string): string {
  return value
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&#10;/g, '\n')
    .replace(/&amp;/g, '&');
}

function utf8(bytes: Uint8Array): string {
  return Buffer.from(bytes).toString('utf8');
}

function stripControls(value: string, keepWhitespace = false): string {
  let out = '';
  for (let i = 0; i < value.length; i++) {
    const code = value.charCodeAt(i);
    if (
      code >= 32 ||
      (keepWhitespace && (code === 9 || code === 10 || code === 13))
    ) {
      out += value[i];
    }
  }
  return out;
}
