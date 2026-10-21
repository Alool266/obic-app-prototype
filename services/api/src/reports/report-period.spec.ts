// Made by Dr Ali

import { isoWeekKey, reportPeriodKey } from './report-period';

describe('report period', () => {
  it('keeps the first Thursday of 2026 in week 1', () => {
    expect(isoWeekKey('2026-01-01')).toBe('2026-W01');
    expect(isoWeekKey('2025-12-29')).toBe('2026-W01');
  });

  it('puts Sunday 4 October 2026 in week 40', () => {
    expect(isoWeekKey('2026-10-04')).toBe('2026-W40');
  });

  it('keeps 31 December 2026 in week 53', () => {
    expect(isoWeekKey('2026-12-31')).toBe('2026-W53');
  });

  it('builds a day, week, and month key from the company date', () => {
    expect(reportPeriodKey('daily', '2026-10-04')).toBe('2026-10-04');
    expect(reportPeriodKey('weekly', '2026-10-04')).toBe('2026-W40');
    expect(reportPeriodKey('monthly', '2026-10-04')).toBe('2026-10');
  });
});
