'use client';
// Made by Dr Ali — Company clock desk. Staff punch from the employee app.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Rule = {
  timezone: string;
  startMinute: number;
  endMinute: number;
  graceMinutes: number;
  weekdays: number[];
};

type Punch = {
  clock: string;
  mark: string;
  note: string | null;
};

type BoardRow = {
  userId: string;
  name: string;
  staffTitle: string | null;
  branchLabel: string | null;
  clockIn: Punch | null;
  clockOut: Punch | null;
};

type Board = { date: string; rule: Rule; rows: BoardRow[] };

const WEEKDAYS: { day: number; key: 'attendanceMon' | 'attendanceTue' | 'attendanceWed' | 'attendanceThu' | 'attendanceFri' | 'attendanceSat' | 'attendanceSun' }[] = [
  { day: 1, key: 'attendanceMon' },
  { day: 2, key: 'attendanceTue' },
  { day: 3, key: 'attendanceWed' },
  { day: 4, key: 'attendanceThu' },
  { day: 5, key: 'attendanceFri' },
  { day: 6, key: 'attendanceSat' },
  { day: 7, key: 'attendanceSun' },
];

function minuteToTime(minute: number): string {
  const hour = Math.floor(minute / 60);
  const rest = minute % 60;
  return `${String(hour).padStart(2, '0')}:${String(rest).padStart(2, '0')}`;
}

function timeToMinute(value: string): number | null {
  const match = /^(\d{2}):(\d{2})/.exec(value);
  if (!match) return null;
  const hour = Number(match[1]);
  const minute = Number(match[2]);
  if (hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

function markLabel(lang: Lang, mark: string): string {
  switch (mark) {
    case 'on_time':
      return t(lang, 'attendanceOnTime');
    case 'late':
      return t(lang, 'attendanceLate');
    case 'early':
      return t(lang, 'attendanceEarly');
    case 'off_day':
      return t(lang, 'attendanceOffDay');
    default:
      return mark;
  }
}

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function AttendancePage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [date, setDate] = useState('');
  const [start, setStart] = useState('09:00');
  const [end, setEnd] = useState('18:00');
  const [grace, setGrace] = useState('0');
  const [timezone, setTimezone] = useState('Asia/Shanghai');
  const [weekdays, setWeekdays] = useState<number[]>([1, 2, 3, 4, 5]);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string, day?: string) => {
    const query = day ? `?date=${encodeURIComponent(day)}` : '';
    const next = (await adminFetch(`/v1/admin/attendance${query}`, token)) as Board;
    setBoard(next);
    setDate(next.date);
    setStart(minuteToTime(next.rule.startMinute));
    setEnd(minuteToTime(next.rule.endMinute));
    setGrace(String(next.rule.graceMinutes));
    setTimezone(next.rule.timezone);
    setWeekdays(next.rule.weekdays);
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

  function toggleDay(day: number) {
    setWeekdays((current) =>
      current.includes(day)
        ? current.filter((item) => item !== day)
        : [...current, day].sort((a, b) => a - b),
    );
  }

  async function saveRule() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    const startMinute = timeToMinute(start);
    const endMinute = timeToMinute(end);
    const graceMinutes = Number(grace);
    if (!token || startMinute == null || endMinute == null || !Number.isInteger(graceMinutes)) {
      return;
    }
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/attendance/rule', token, {
        method: 'PATCH',
        body: JSON.stringify({
          timezone: timezone.trim(),
          startMinute,
          endMinute,
          graceMinutes,
          weekdays,
        }),
        totpCode: code,
      });
      setNotice(t(lang, 'attendanceSaved'));
      await load(token, date || undefined);
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

  return (
    <AdminShell active="attendance" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'attendanceTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'attendanceHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'attendanceDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{t(lang, 'attendanceRule')}</h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter">
              {t(lang, 'attendanceStart')}
              <input type="time" value={start} onChange={(e) => setStart(e.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'attendanceEnd')}
              <input type="time" value={end} onChange={(e) => setEnd(e.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'attendanceGrace')}
              <input
                type="number"
                min={0}
                max={180}
                value={grace}
                onChange={(e) => setGrace(e.target.value)}
              />
            </label>
            <label className="staff-filter grow">
              {t(lang, 'attendanceTimezone')}
              <input value={timezone} onChange={(e) => setTimezone(e.target.value)} />
            </label>
          </div>
          <p className="muted" style={{ marginTop: 12 }}>{t(lang, 'attendanceWeekdays')}</p>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 8 }}>
            {WEEKDAYS.map((item) => (
              <label key={item.day} className="staff-filter">
                <input
                  type="checkbox"
                  checked={weekdays.includes(item.day)}
                  onChange={() => toggleDay(item.day)}
                />{' '}
                {t(lang, item.key)}
              </label>
            ))}
          </div>
          <button type="button" className="btn-primary sm" disabled={saving} onClick={saveRule} style={{ marginTop: 12 }}>
            {saving ? t(lang, 'saving') : t(lang, 'attendanceSave')}
          </button>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          <label className="staff-filter">
            {t(lang, 'attendanceDate')}
            <input
              type="date"
              value={date}
              onChange={(e) => {
                const next = e.target.value;
                setDate(next);
                const token = sessionStorage.getItem(TOKEN_KEY);
                if (token && next) {
                  load(token, next).catch((err) =>
                    setError(err instanceof Error ? err.message : 'Failed'),
                  );
                }
              }}
            />
          </label>
          <table className="web-table" style={{ marginTop: 12 }}>
            <thead>
              <tr>
                <th>{t(lang, 'name')}</th>
                <th>{t(lang, 'branch')}</th>
                <th>{t(lang, 'attendanceIn')}</th>
                <th>{t(lang, 'attendanceOut')}</th>
              </tr>
            </thead>
            <tbody>
              {(board?.rows ?? []).map((row) => (
                <tr key={row.userId}>
                  <td>
                    {row.name}
                    {row.staffTitle ? <div className="muted">{row.staffTitle}</div> : null}
                  </td>
                  <td>{row.branchLabel || t(lang, 'none')}</td>
                  <td>
                    {row.clockIn
                      ? `${row.clockIn.clock} · ${markLabel(lang, row.clockIn.mark)}`
                      : t(lang, 'attendanceMissing')}
                  </td>
                  <td>
                    {row.clockOut
                      ? `${row.clockOut.clock} · ${markLabel(lang, row.clockOut.mark)}`
                      : t(lang, 'attendanceMissing')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </AdminShell>
  );
}
