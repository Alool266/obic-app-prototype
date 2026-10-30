// Made by Dr Ali

import {
  assertSheetGrid,
  emptySheetGrid,
  normalizeSheetTitle,
  SHEET_COLS,
  SHEET_ROWS,
  sheetTitleKey,
} from './company-spreadsheet';

describe('company spreadsheet', () => {
  it('collapses a title and treats case as the same sheet', () => {
    expect(normalizeSheetTitle('  Sales   grid ')).toBe('Sales grid');
    expect(sheetTitleKey('Sales grid')).toBe(sheetTitleKey('sales grid'));
    expect(() => normalizeSheetTitle('  ')).toThrow('SHEET_TITLE');
  });

  it('builds an empty grid and keeps cell text on one line', () => {
    const grid = emptySheetGrid();
    expect(grid).toHaveLength(SHEET_ROWS);
    expect(grid[0]).toHaveLength(SHEET_COLS);
    const next = grid.map((row) => [...row]);
    next[0][0] = '  Price\nlist  ';
    expect(assertSheetGrid(next)[0][0]).toBe('Price list');
  });

  it('rejects the wrong shape and a cell that is too long', () => {
    expect(() => assertSheetGrid([['a']])).toThrow('SHEET_GRID');
    const grid = emptySheetGrid();
    grid[1][1] = 'x'.repeat(81);
    expect(() => assertSheetGrid(grid)).toThrow('SHEET_CELL');
  });
});
