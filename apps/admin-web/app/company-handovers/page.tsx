'use client';
// Made by Dr Ali — Customer handover. SuperAdmin moves company contacts. The app does not message the customer.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Person = { userId: string; name: string };
type HandoverContact = { id: string; name: string; active: boolean };
type HandoverSnap = { id: string; name: string };
type HandoverRow = {
  id: string;
  fromName: string | null;
  toName: string | null;
  contactCount: number;
  contacts: HandoverSnap[];
  createdAt: string;
};
type Board = { people: Person[]; handovers: HandoverRow[]; contacts: HandoverContact[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanyHandoversPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [fromUserId, setFromUserId] = useState('');
  const [toUserId, setToUserId] = useState('');
  const [selected, setSelected] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string, fromId?: string) => {
    const query = fromId ? `?fromUserId=${encodeURIComponent(fromId)}` : '';
    setBoard((await adminFetch(`/v1/admin/company-handovers${query}`, token)) as Board);
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

  function chooseFrom(id: string) {
    setFromUserId(id);
    setSelected([]);
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    load(token, id).catch((err) => setError(err instanceof Error ? err.message : 'Failed'));
  }

  function toggle(id: string) {
    setSelected((current) =>
      current.includes(id) ? current.filter((item) => item !== id) : [...current, id],
    );
  }

  function selectShown() {
    const ids = (board?.contacts ?? []).map((contact) => contact.id);
    const allOn = ids.length > 0 && ids.every((id) => selected.includes(id));
    setSelected(allOn ? [] : ids);
  }

  async function move() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !fromUserId || !toUserId || fromUserId === toUserId || selected.length === 0) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/company-handovers', token, {
        method: 'POST',
        body: JSON.stringify({
          fromUserId,
          toUserId,
          contactIds: selected,
        }),
        totpCode: code,
      });
      setNotice(t(lang, 'companyHandoverMoved'));
      setSelected([]);
      await load(token, fromUserId);
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

  const contacts = board?.contacts ?? [];
  const handovers = board?.handovers ?? [];
  const people = board?.people ?? [];

  return (
    <AdminShell active="companyHandovers" me={me} onLangChange={onLang}>
      <div className="web-head">
        <div>
          <h1>{t(lang, 'companyHandoverTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyHandoverHint')}</p>
        </div>
      </div>
      {error ? <p className="err">{error}</p> : null}
      {notice ? <p className="muted staff-note">{notice}</p> : null}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyHandoverDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'companyHandoverFrom')}
              <select value={fromUserId} onChange={(event) => chooseFrom(event.target.value)}>
                <option value="">—</option>
                {people.map((person) => (
                  <option key={person.userId} value={person.userId}>
                    {person.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="staff-filter grow">
              {t(lang, 'companyHandoverTo')}
              <select value={toUserId} onChange={(event) => setToUserId(event.target.value)}>
                <option value="">—</option>
                {people
                  .filter((person) => person.userId !== fromUserId)
                  .map((person) => (
                    <option key={person.userId} value={person.userId}>
                      {person.name}
                    </option>
                  ))}
              </select>
            </label>
          </div>
          {fromUserId && contacts.length === 0 ? (
            <p className="muted" style={{ marginTop: 12 }}>
              {t(lang, 'companyHandoverEmpty')}
            </p>
          ) : null}
          {contacts.length > 0 ? (
            <div style={{ marginTop: 12 }}>
              <button type="button" onClick={selectShown}>
                {t(lang, 'companyHandoverAll')}
              </button>
              <ul style={{ listStyle: 'none', padding: 0, marginTop: 12 }}>
                {contacts.map((contact) => (
                  <li key={contact.id}>
                    <label>
                      <input
                        type="checkbox"
                        checked={selected.includes(contact.id)}
                        onChange={() => toggle(contact.id)}
                      />{' '}
                      {contact.name}
                      {contact.active ? '' : ` (${t(lang, 'companyHandoverPaused')})`}
                    </label>
                  </li>
                ))}
              </ul>
            </div>
          ) : null}
          <button
            type="button"
            className="btn-primary sm"
            disabled={saving || !fromUserId || !toUserId || selected.length === 0}
            onClick={move}
            style={{ marginTop: 12 }}
          >
            {saving ? t(lang, 'saving') : t(lang, 'companyHandoverMove')}
          </button>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {handovers.length === 0 ? <p className="muted">{t(lang, 'companyHandoverNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyHandoverFrom')}</th>
                <th>{t(lang, 'companyHandoverTo')}</th>
                <th>{t(lang, 'companyHandoverCount')}</th>
                <th>{t(lang, 'companyHandoverContacts')}</th>
                <th>{t(lang, 'companyHandoverWhen')}</th>
              </tr>
            </thead>
            <tbody>
              {handovers.map((row) => (
                <tr key={row.id}>
                  <td>{row.fromName ?? '—'}</td>
                  <td>{row.toName ?? '—'}</td>
                  <td>{row.contactCount}</td>
                  <td>{row.contacts.map((contact) => contact.name).join(', ')}</td>
                  <td>{row.createdAt ? new Date(row.createdAt).toLocaleString() : ''}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </AdminShell>
  );
}
