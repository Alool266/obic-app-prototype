// Made by Dr Ali
// A work report belongs to the current company day, ISO week, or month.

export const REPORT_KINDS = ['daily', 'weekly', 'monthly'] as const;
export type ReportKind = (typeof REPORT_KINDS)[number];

export function isReportKind(value: string): value is ReportKind {
  return (REPORT_KINDS as readonly string[]).includes(value);
}

/** Monday-based ISO week, for example 2026-W40. */
export function isoWeekKey(workDate: string): string {
  const [year, month, day] = workDate.split('-').map((part) => Number(part));
  const date = new Date(Date.UTC(year, month - 1, day));
  const weekday = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - weekday);
  const isoYear = date.getUTCFullYear();
  const yearStart = new Date(Date.UTC(isoYear, 0, 1));
  const diffDays = (date.getTime() - yearStart.getTime()) / 86_400_000;
  const week = Math.ceil((diffDays + 1) / 7);
  return `${isoYear}-W${String(week).padStart(2, '0')}`;
}

export function reportPeriodKey(kind: ReportKind, workDate: string): string {
  switch (kind) {
    case 'daily':
      return workDate;
    case 'weekly':
      return isoWeekKey(workDate);
    case 'monthly':
      return workDate.slice(0, 7);
    default: {
      const neverKind: never = kind;
      throw new Error(neverKind);
    }
  }
}
