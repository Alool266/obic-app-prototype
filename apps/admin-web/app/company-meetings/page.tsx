'use client';
// Made by Dr Ali — Richer meetings. The desk does not start a call.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Person = { userId: string; name: string };
type MeetingRow = {
  id: string;
  title: string;
  date: string;
  start: string;
  end: string;
  agenda: string | null;
  notes: string | null;
  active: boolean;
  organizerName: string | null;
  attendeeNames: string[];
  userIds: string[];
};
type Board = { today: string; people: Person[]; rows: MeetingRow[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanyMeetingsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [date, setDate] = useState('');
  const [start, setStart] = useState('09:00');
  const [end, setEnd] = useState('10:00');
  const [agenda, setAgenda] = useState('');
  const [notes, setNotes] = useState('');
  const [active, setActive] = useState(true);
  const [selected, setSelected] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/company-meetings', token)) as Board);
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
    setAgenda('');
    setNotes('');
    setActive(true);
    setSelected([]);
  }

  function openMeeting(row: MeetingRow) {
    setEditingId(row.id);
    setTitle(row.title);
    setDate(row.date);
    setStart(row.start);
    setEnd(row.end);
    setAgenda(row.agenda ?? '');
    setNotes(row.notes ?? '');
    setActive(row.active);
    setSelected(row.userIds);
  }

  function toggle(id: string) {
    setSelected((current) => {
      if (current.includes(id)) return current.filter((item) => item !== id);
      if (current.length >= 12) return current;
      return [...current, id];
    });
  }

  async function save() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !title.trim() || !date || !start || !end || selected.length === 0) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(
        editingId ? `/v1/admin/company-meetings/${editingId}` : '/v1/admin/company-meetings',
        token,
        {
          method: editingId ? 'PATCH' : 'POST',
          body: JSON.stringify({
            title: title.trim(),
            date,
            start,
            end,
            agenda: agenda.trim(),
            notes: notes.trim(),
            active,
            userIds: selected,
          }),
          totpCode: code,
        },
      );
      setNotice(t(lang, 'companyMeetingsSaved'));
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
  const people = board?.people ?? [];
  const showForm = canReview(me) && (isSuper || editingId);

  return (
    <AdminShell active="companyMeetings" me={me} onLangChange={onLang}>
      <div className="web-head">
        <div>
          <h1>{t(lang, 'companyMeetingsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyMeetingsHint')}</p>
        </div>
      </div>
      {error ? <p className="err">{error}</p> : null}
      {notice ? <p className="muted staff-note">{notice}</p> : null}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyMeetingsDenied')}</p> : null}

      {showForm ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>
            {editingId ? t(lang, 'companyMeetingsSave') : t(lang, 'companyMeetingsNew')}
          </h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'companyMeetingsName')}
              <input value={title} maxLength={80} disabled={!isSuper} onChange={(event) => setTitle(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyMeetingsDate')}
              <input type="date" value={date} disabled={!isSuper} onChange={(event) => setDate(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyMeetingsStart')}
              <input type="time" value={start} disabled={!isSuper} onChange={(event) => setStart(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyMeetingsEnd')}
              <input type="time" value={end} disabled={!isSuper} onChange={(event) => setEnd(event.target.value)} />
            </label>
          </div>
          <label className="staff-filter grow" style={{ display: 'block', marginTop: 12 }}>
            {t(lang, 'companyMeetingsAgenda')}
            <textarea
              value={agenda}
              maxLength={1000}
              rows={3}
              disabled={!isSuper}
              onChange={(event) => setAgenda(event.target.value)}
              style={{ width: '100%', marginTop: 6 }}
            />
          </label>
          <label className="staff-filter grow" style={{ display: 'block', marginTop: 12 }}>
            {t(lang, 'companyMeetingsNotes')}
            <textarea
              value={notes}
              maxLength={2000}
              rows={4}
              disabled={!isSuper}
              onChange={(event) => setNotes(event.target.value)}
              style={{ width: '100%', marginTop: 6 }}
            />
          </label>
          <p style={{ marginTop: 12 }}>{t(lang, 'companyMeetingsTo')}</p>
          <ul style={{ listStyle: 'none', padding: 0 }}>
            {people.map((person) => (
              <li key={person.userId}>
                <label>
                  <input
                    type="checkbox"
                    checked={selected.includes(person.userId)}
                    disabled={!isSuper}
                    onChange={() => toggle(person.userId)}
                  />{' '}
                  {person.name}
                </label>
              </li>
            ))}
          </ul>
          <label style={{ display: 'block', marginTop: 12 }}>
            <input
              type="checkbox"
              checked={active}
              disabled={!isSuper}
              onChange={(event) => setActive(event.target.checked)}
            />{' '}
            {t(lang, 'companyMeetingsActive')}
          </label>
          {isSuper ? (
            <div style={{ marginTop: 12 }}>
              <button type="button" className="btn-primary sm" disabled={saving || selected.length === 0} onClick={save}>
                {saving ? t(lang, 'saving') : t(lang, 'companyMeetingsSave')}
              </button>{' '}
              {editingId ? (
                <button type="button" onClick={clearForm}>
                  {t(lang, 'companyMeetingsNew')}
                </button>
              ) : null}
            </div>
          ) : null}
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {rows.length === 0 ? <p className="muted">{t(lang, 'companyMeetingsNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyMeetingsDate')}</th>
                <th>{t(lang, 'companyMeetingsName')}</th>
                <th>{t(lang, 'companyMeetingsTo')}</th>
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
                    {row.organizerName ? ` · ${row.organizerName}` : ''}
                  </td>
                  <td>{row.attendeeNames.join(', ')}</td>
                  <td>{row.active ? t(lang, 'companyMeetingsActive') : t(lang, 'companyMeetingsPaused')}</td>
                  <td>
                    <button type="button" onClick={() => openMeeting(row)}>
                      {t(lang, 'companyMeetingsSave')}
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
