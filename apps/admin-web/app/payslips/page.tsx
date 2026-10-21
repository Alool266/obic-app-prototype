'use client';
// Made by Dr Ali — Monthly payslips. A record the employee can confirm. No money is sent.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type LineKind = 'earning' | 'deduction';

type Line = {
  key: string;
  label: string;
  kind: LineKind;
  cents: number;
};

type PayslipRow = {
  id: string;
  userId: string;
  name: string;
  period: string;
  note: string | null;
  lines: Line[];
  netCents: number;
  acknowledgedAt: string | null;
};

type Person = { userId: string; name: string };

type Board = { today: string; people: Person[]; rows: PayslipRow[] };

type DraftLine = { key: string; label: string; kind: LineKind; yuan: string };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

function money(cents: number): string {
  const sign = cents < 0 ? '-' : '';
  const abs = Math.abs(cents);
  return `${sign}${Math.floor(abs / 100)}.${String(abs % 100).padStart(2, '0')}`;
}

function yuanToCents(raw: string): number | null {
  const match = /^(\d+)(?:\.(\d{1,2}))?$/.exec(raw.trim());
  if (!match) return null;
  const whole = Number(match[1]);
  if (!Number.isSafeInteger(whole)) return null;
  const cents = whole * 100 + Number((match[2] ?? '').padEnd(2, '0'));
  if (cents > 100_000_000) return null;
  return cents;
}

function blankLine(index: number): DraftLine {
  return { key: `pay_${index}`, label: '', kind: 'earning', yuan: '' };
}

function nextLine(rows: DraftLine[]): DraftLine {
  const used = new Set(rows.map((row) => row.key));
  let index = rows.length + 1;
  while (used.has(`pay_${index}`)) index += 1;
  return blankLine(index);
}

export default function PayslipsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [userId, setUserId] = useState('');
  const [period, setPeriod] = useState('');
  const [note, setNote] = useState('');
  const [lines, setLines] = useState<DraftLine[]>([blankLine(1)]);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';
  const current = board?.rows.find((row) => row.userId === userId && row.period === period) ?? null;
  const locked = current?.acknowledgedAt != null;

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/payslips', token)) as Board);
  }, []);

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    adminFetch('/v1/admin/me', token)
      .then((row) => {
        setMe(row);
        if (row.role !== 'Employee' && row.role !== 'SuperAdmin' && row.isSuperAdmin !== true) {
          router.replace('/dashboard');
          return;
        }
        if (!canReview(row)) return;
        return load(token);
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed'));
  }, [load, router]);

  useEffect(() => {
    if (board?.today && !period) setPeriod(board.today);
  }, [board, period]);

  useEffect(() => {
    const match = board?.rows.find((row) => row.userId === userId && row.period === period);
    if (!match) {
      setLines([blankLine(1)]);
      setNote('');
      return;
    }
    setNote(match.note ?? '');
    setLines(
      match.lines.map((line) => ({
        key: line.key,
        label: line.label,
        kind: line.kind,
        yuan: money(line.cents).replace(/^-/, ''),
      })),
    );
  }, [board, userId, period]);

  function totpCode(): string | undefined | null {
    if (me?.totpStepUpRequired !== true) return undefined;
    const code = promptTotpStepUp(t(lang, 'totpStepUpHint'));
    if (code == null) return null;
    if (!code) {
      setError(t(lang, 'totpStepUpInvalid'));
      return null;
    }
    return code;
  }

  function updateLine(index: number, patch: Partial<DraftLine>) {
    setLines((currentLines) =>
      currentLines.map((line, lineIndex) => (lineIndex === index ? { ...line, ...patch } : line)),
    );
  }

  async function savePayslip() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !userId || !period || locked) return;
    const payload = lines.map((line) => ({
      key: line.key,
      label: line.label.trim(),
      kind: line.kind,
      cents: yuanToCents(line.yuan),
    }));
    if (payload.some((line) => !line.label || line.cents == null)) {
      setError(t(lang, 'payslipsInvalid'));
      return;
    }
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/payslips', token, {
        method: 'POST',
        body: JSON.stringify({
          userId,
          period,
          note: note.trim() || undefined,
          lines: payload,
        }),
        totpCode: code,
      });
      setNotice(t(lang, 'payslipsSaved'));
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted">{error || '…'}</p>
      </div>
    );
  }

  const rows = board?.rows ?? [];

  return (
    <AdminShell active="payslips" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'payslipsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'payslipsHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'payslipsDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{t(lang, 'payslipsSave')}</h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'name')}
              <select value={userId} onChange={(event) => setUserId(event.target.value)}>
                <option value="">—</option>
                {(board?.people ?? []).map((person) => (
                  <option key={person.userId} value={person.userId}>
                    {person.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="staff-filter">
              {t(lang, 'payslipsMonth')}
              <input type="month" value={period} onChange={(event) => setPeriod(event.target.value)} />
            </label>
          </div>
          {lines.map((line, index) => (
            <div key={line.key} className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12, marginTop: 12 }}>
              <label className="staff-filter grow">
                {t(lang, 'payslipsLabel')}
                <input
                  value={line.label}
                  disabled={locked}
                  onChange={(event) => updateLine(index, { label: event.target.value })}
                />
              </label>
              <label className="staff-filter">
                {t(lang, 'payslipsEarning')}
                <select
                  value={line.kind}
                  disabled={locked}
                  onChange={(event) => updateLine(index, { kind: event.target.value as LineKind })}
                >
                  <option value="earning">{t(lang, 'payslipsEarning')}</option>
                  <option value="deduction">{t(lang, 'payslipsDeduction')}</option>
                </select>
              </label>
              <label className="staff-filter">
                {t(lang, 'payslipsAmount')}
                <input
                  inputMode="decimal"
                  value={line.yuan}
                  disabled={locked}
                  placeholder="0.00"
                  onChange={(event) => updateLine(index, { yuan: event.target.value })}
                />
              </label>
              {lines.length > 1 && !locked ? (
                <button
                  type="button"
                  onClick={() => setLines((currentLines) => currentLines.filter((_, lineIndex) => lineIndex !== index))}
                >
                  {t(lang, 'payslipsRemove')}
                </button>
              ) : null}
            </div>
          ))}
          <label className="staff-filter grow" style={{ marginTop: 12 }}>
            {t(lang, 'payslipsNote')}
            <input value={note} disabled={locked} maxLength={500} onChange={(event) => setNote(event.target.value)} />
          </label>
          {!locked ? (
            <div style={{ marginTop: 12 }}>
              <button
                type="button"
                onClick={() => setLines((currentLines) => [...currentLines, nextLine(currentLines)])}
                disabled={lines.length >= 12}
              >
                {t(lang, 'payslipsAddLine')}
              </button>{' '}
              <button type="button" className="btn-primary sm" disabled={saving} onClick={savePayslip}>
                {saving ? t(lang, 'saving') : t(lang, 'payslipsSave')}
              </button>
            </div>
          ) : (
            <p className="muted" style={{ marginTop: 12 }}>{t(lang, 'payslipsConfirmed')}</p>
          )}
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {rows.length === 0 ? <p className="muted">{t(lang, 'payslipsNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'name')}</th>
                <th>{t(lang, 'payslipsMonth')}</th>
                <th>{t(lang, 'payslipsNet')}</th>
                <th>{t(lang, 'payslipsNote')}</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>{row.name}</td>
                  <td>{row.period}</td>
                  <td>CNY {money(row.netCents)}</td>
                  <td>{row.note ?? '—'}</td>
                  <td>{row.acknowledgedAt ? t(lang, 'payslipsConfirmed') : t(lang, 'payslipsOpen')}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </AdminShell>
  );
}
