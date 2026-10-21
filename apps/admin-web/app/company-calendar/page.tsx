'use client';
// Made by Dr Ali — Company calendar. Times are China time. The app does not send an invitation.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type EventRow = {
  id: string;
  title: string;
  date: string;
  start: string;
  end: string;
  note: string | null;
  active: boolean;
  creatorName: string | null;
};
type Board = { today: string; rows: EventRow[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanyCalendarPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [date, setDate] = useState('');
  const [start, setStart] = useState('09:00');
  const [end, setEnd] = useState('10:00');
  const [note, setNote] = useState('');
  const [active, setActive] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/company-calendar', token)) as Board);
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
    if (!editingId && !date && board?.today) setDate(board.today);
  }, [board, date, editingId]);

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

  function clearForm() {
    setEditingId(null);
    setTitle('');
    setDate(board?.today ?? '');
    setStart('09:00');
    setEnd('10:00');
    setNote('');
    setActive(true);
  }

  function openEvent(row: EventRow) {
    setEditingId(row.id);
    setTitle(row.title);
    setDate(row.date);
    setStart(row.start);
    setEnd(row.end);
    setNote(row.note ?? '');
    setActive(row.active);
  }

  async function save() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !title.trim() || !date || !start || !end) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(
        editingId ? `/v1/admin/company-calendar/${editingId}` : '/v1/admin/company-calendar',
        token,
        {
          method: editingId ? 'PATCH' : 'POST',
          body: JSON.stringify({
            title: title.trim(),
            date,
            start,
            end,
            note: note.trim(),
            active,
          }),
          totpCode: code,
        },
      );
      setNotice(t(lang, 'companyCalendarSaved'));
      clearForm();
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
        <p className="muted">{t(lang, 'loading')}</p>
      </div>
    );
  }

  const rows = board?.rows ?? [];
  const showForm = canReview(me) && (isSuper || editingId);

  return (
    <AdminShell active="companyCalendar" me={me} onLangChange={onLang}>
      <div className="web-head">
        <div>
          <h1>{t(lang, 'companyCalendarTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyCalendarHint')}</p>
        </div>
      </div>
      {error ? <p className="err">{error}</p> : null}
      {notice ? <p className="muted staff-note">{notice}</p> : null}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyCalendarDenied')}</p> : null}

      {showForm ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>
            {editingId ? t(lang, 'companyCalendarSave') : t(lang, 'companyCalendarNew')}
          </h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'companyCalendarName')}
              <input value={title} maxLength={80} disabled={!isSuper} onChange={(event) => setTitle(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyCalendarDate')}
              <input type="date" value={date} disabled={!isSuper} onChange={(event) => setDate(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyCalendarStart')}
              <input type="time" value={start} disabled={!isSuper} onChange={(event) => setStart(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyCalendarEnd')}
              <input type="time" value={end} disabled={!isSuper} onChange={(event) => setEnd(event.target.value)} />
            </label>
          </div>
          <label className="staff-filter grow" style={{ display: 'block', marginTop: 12 }}>
            {t(lang, 'companyCalendarNote')}
            <textarea
              value={note}
              maxLength={500}
              rows={3}
              disabled={!isSuper}
              onChange={(event) => setNote(event.target.value)}
              style={{ width: '100%', marginTop: 6 }}
            />
          </label>
          <label style={{ display: 'block', marginTop: 12 }}>
            <input
              type="checkbox"
              checked={active}
              disabled={!isSuper}
              onChange={(event) => setActive(event.target.checked)}
            />{' '}
            {t(lang, 'companyCalendarActive')}
          </label>
          {isSuper ? (
            <div style={{ marginTop: 12 }}>
              <button type="button" className="btn-primary sm" disabled={saving} onClick={save}>
                {saving ? t(lang, 'saving') : t(lang, 'companyCalendarSave')}
              </button>{' '}
              {editingId ? (
                <button type="button" onClick={clearForm}>
                  {t(lang, 'companyCalendarNew')}
                </button>
              ) : null}
            </div>
          ) : null}
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {rows.length === 0 ? <p className="muted">{t(lang, 'companyCalendarNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyCalendarDate')}</th>
                <th>{t(lang, 'companyCalendarName')}</th>
                <th>{t(lang, 'companyCalendarStart')}</th>
                <th />
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>{row.date}</td>
                  <td>
                    {row.title}
                    {row.creatorName ? ` · ${row.creatorName}` : ''}
                  </td>
                  <td>
                    {row.start}–{row.end}
                  </td>
                  <td>{row.active ? t(lang, 'companyCalendarActive') : t(lang, 'companyCalendarPaused')}</td>
                  <td>
                    <button type="button" onClick={() => openEvent(row)}>
                      {t(lang, 'companyCalendarSave')}
                    </button>
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
