// Made by Dr Ali
// A shared spreadsheet is a fixed grid of text. Cells are not formulas.

export const SHEET_LIMIT = 20;
export const SHEET_COLS = 6;
export const SHEET_ROWS = 12;
export const SHEET_CELL_MAX = 80;
export const SHEET_TITLE_MAX = 40;

export function normalizeSheetTitle(value: string): string {
  const title = value.trim().replace(/\s+/g, ' ');
  if (!title || title.length > SHEET_TITLE_MAX) throw new Error('SHEET_TITLE');
  return title;
}

export function sheetTitleKey(title: string): string {
  const key = title.toLocaleLowerCase();
  if (!key || key.length > SHEET_TITLE_MAX) throw new Error('SHEET_TITLE');
  return key;
}

export function emptySheetGrid(): string[][] {
  return Array.from({ length: SHEET_ROWS }, () => Array.from({ length: SHEET_COLS }, () => ''));
}

export function assertSheetGrid(value: unknown): string[][] {
  if (!Array.isArray(value) || value.length !== SHEET_ROWS) throw new Error('SHEET_GRID');
  return value.map((row) => {
    if (!Array.isArray(row) || row.length !== SHEET_COLS) throw new Error('SHEET_GRID');
    return row.map((cell) => {
      if (typeof cell !== 'string') throw new Error('SHEET_GRID');
      const text = cell.replace(/[\r\n]+/g, ' ').trim();
      if (text.length > SHEET_CELL_MAX) throw new Error('SHEET_CELL');
      return text;
    });
  });
}
