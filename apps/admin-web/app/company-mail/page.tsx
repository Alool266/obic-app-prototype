'use client';
// Made by Dr Ali — Company mail stays inside OBIC. It is not sent to an outside inbox.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Person = { userId: string; name: string };
type MailRow = {
  id: string;
  subject: string;
  body: string;
  senderName: string | null;
  recipientNames: string[];
  createdAt: string;
};
type Board = { people: Person[]; rows: MailRow[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanyMailPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [subject, setSubject] = useState('');
  const [body, setBody] = useState('');
  const [selected, setSelected] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/company-mail', token)) as Board);
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

  function toggle(id: string) {
    setSelected((current) => {
      if (current.includes(id)) return current.filter((item) => item !== id);
      if (current.length >= 12) return current;
      return [...current, id];
    });
  }

  async function send() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !subject.trim() || !body.trim() || selected.length === 0) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/company-mail', token, {
        method: 'POST',
        body: JSON.stringify({ subject: subject.trim(), body: body.trim(), userIds: selected }),
        totpCode: code,
      });
      setNotice(t(lang, 'companyMailSent'));
      setSubject('');
      setBody('');
      setSelected([]);
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

  return (
    <AdminShell active="companyMail" me={me} onLangChange={onLang}>
      <div className="web-head">
        <div>
          <h1>{t(lang, 'companyMailTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyMailHint')}</p>
        </div>
      </div>
      {error ? <p className="err">{error}</p> : null}
      {notice ? <p className="muted staff-note">{notice}</p> : null}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyMailDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <label className="staff-filter grow">
            {t(lang, 'companyMailSubject')}
            <input value={subject} maxLength={80} onChange={(event) => setSubject(event.target.value)} />
          </label>
          <label className="staff-filter grow" style={{ display: 'block', marginTop: 12 }}>
            {t(lang, 'companyMailBody')}
            <textarea
              value={body}
              maxLength={2000}
              rows={5}
              onChange={(event) => setBody(event.target.value)}
              style={{ width: '100%', marginTop: 6 }}
            />
          </label>
          <p style={{ marginTop: 12 }}>{t(lang, 'companyMailTo')}</p>
          <ul style={{ listStyle: 'none', padding: 0 }}>
            {people.map((person) => (
              <li key={person.userId}>
                <label>
                  <input
                    type="checkbox"
                    checked={selected.includes(person.userId)}
                    onChange={() => toggle(person.userId)}
                  />{' '}
                  {person.name}
                </label>
              </li>
            ))}
          </ul>
          <button
            type="button"
            className="btn-primary sm"
            disabled={saving || selected.length === 0}
            onClick={send}
          >
            {saving ? t(lang, 'saving') : t(lang, 'companyMailSend')}
          </button>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {rows.length === 0 ? <p className="muted">{t(lang, 'companyMailNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyMailSubject')}</th>
                <th>{t(lang, 'companyMailTo')}</th>
                <th>{t(lang, 'companyMailBody')}</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>
                    {row.subject}
                    {row.senderName ? ` · ${row.senderName}` : ''}
                  </td>
                  <td>{row.recipientNames.join(', ')}</td>
                  <td>{row.body}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </AdminShell>
  );
}
