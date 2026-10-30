// Made by Dr Ali

import {
  assertPayslipLines,
  assertPayslipPeriod,
  assertPayslipWritable,
  payslipNetCents,
  shiftMonth,
  type PayslipLine,
} from './payslip';

const lines: PayslipLine[] = [
  { key: 'base', label: 'Base', kind: 'earning', cents: 1000000 },
  { key: 'tax', label: 'Tax', kind: 'deduction', cents: 150000 },
];

describe('payslip', () => {
  it('subtracts deductions from earnings in cents', () => {
    expect(payslipNetCents(lines)).toBe(850000);
  });

  it('keeps a month from 2020 through next month', () => {
    expect(shiftMonth('2026-12', 1)).toBe('2027-01');
    expect(() => assertPayslipPeriod('2026-11', '2026-10')).not.toThrow();
    expect(() => assertPayslipPeriod('2026-12', '2026-10')).toThrow('PAYSLIP_PERIOD');
    expect(() => assertPayslipPeriod('2019-12', '2026-10')).toThrow('PAYSLIP_PERIOD');
  });

  it('rejects a duplicate line and a confirmed payslip', () => {
    expect(assertPayslipLines(lines)).toHaveLength(2);
    expect(() =>
      assertPayslipLines([
        lines[0],
        { key: 'base', label: 'Again', kind: 'earning', cents: 1 },
      ]),
    ).toThrow('PAYSLIP_LINE_KEY');
    expect(() => assertPayslipWritable(true)).toThrow('PAYSLIP_LOCKED');
    expect(() => assertPayslipWritable(false)).not.toThrow();
  });
});
