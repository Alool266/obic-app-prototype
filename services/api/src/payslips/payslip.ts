// Made by Dr Ali
// A payslip is a record of earnings and deductions. It does not send money.

export const PAYSLIP_LINE_KINDS = ['earning', 'deduction'] as const;
export type PayslipLineKind = (typeof PAYSLIP_LINE_KINDS)[number];

export type PayslipLine = {
  key: string;
  label: string;
  kind: PayslipLineKind;
  cents: number;
};

const PERIOD = /^(\d{4})-(\d{2})$/;
const LINE_KEY = /^[a-z][a-z0-9_]{0,31}$/;
export const PAYSLIP_MAX_CENTS = 100_000_000;

export function isPayslipLineKind(value: string): value is PayslipLineKind {
  return (PAYSLIP_LINE_KINDS as readonly string[]).includes(value);
}

export function shiftMonth(period: string, months: number): string {
  const match = PERIOD.exec(period);
  if (!match) throw new Error('PAYSLIP_PERIOD');
  const month = Number(match[2]);
  if (month < 1 || month > 12) throw new Error('PAYSLIP_PERIOD');
  const index = Number(match[1]) * 12 + (month - 1) + months;
  const nextYear = Math.floor(index / 12);
  const nextMonth = (index % 12) + 1;
  return `${String(nextYear).padStart(4, '0')}-${String(nextMonth).padStart(2, '0')}`;
}

export function assertPayslipPeriod(period: string, today: string): void {
  const month = Number(period.slice(5, 7));
  if (!PERIOD.test(period) || !PERIOD.test(today) || month < 1 || month > 12) {
    throw new Error('PAYSLIP_PERIOD');
  }
  if (period < '2020-01' || period > shiftMonth(today, 1)) {
    throw new Error('PAYSLIP_PERIOD');
  }
}

export function assertPayslipLines(lines: PayslipLine[]): PayslipLine[] {
  if (lines.length < 1 || lines.length > 12) throw new Error('PAYSLIP_LINES');
  const keys = new Set<string>();
  const clean: PayslipLine[] = [];
  for (const line of lines) {
    const label = line.label.trim();
    if (!LINE_KEY.test(line.key) || keys.has(line.key)) throw new Error('PAYSLIP_LINE_KEY');
    if (!label || label.length > 80) throw new Error('PAYSLIP_LINE_LABEL');
    if (!isPayslipLineKind(line.kind)) throw new Error('PAYSLIP_LINE_KIND');
    if (!Number.isInteger(line.cents) || line.cents < 0 || line.cents > PAYSLIP_MAX_CENTS) {
      throw new Error('PAYSLIP_AMOUNT');
    }
    keys.add(line.key);
    clean.push({ key: line.key, label, kind: line.kind, cents: line.cents });
  }
  return clean;
}

export function payslipNetCents(lines: readonly PayslipLine[]): number {
  let net = 0;
  for (const line of lines) {
    switch (line.kind) {
      case 'earning':
        net += line.cents;
        break;
      case 'deduction':
        net -= line.cents;
        break;
      default: {
        const neverKind: never = line.kind;
        throw new Error(neverKind);
      }
    }
  }
  return net;
}

export function assertPayslipWritable(acknowledged: boolean): void {
  if (acknowledged) throw new Error('PAYSLIP_LOCKED');
}
