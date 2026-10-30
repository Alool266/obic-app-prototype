'use client';
// Made by Dr Ali — Welcome messages. The desk writes the greeting. The app shows it and does not send it.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Welcome = { id: string; title: string; body: string; active: boolean; isDefault: boolean };
type Person = { userId: string; name: string };
type Assignment = { userId: string; welcomeId: string };
type Board = { welcomes: Welcome[]; people: Person[]; assignments: Assignment[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanyWelcomesPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [active, setActive] = useState(true);
  const [isDefault, setIsDefault] = useState(false);
  const [assignUserId, setAssignUserId] = useState('');
  const [assignWelcomeId, setAssignWelcomeId] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/company-welcomes', token)) as Board);
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

  function clearForm() {
    setEditingId(null);
    setTitle('');
    setBody('');
    setActive(true);
    setIsDefault(false);
  }

  async function saveWelcome() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !title.trim() || !body.trim()) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(
        editingId ? `/v1/admin/company-welcomes/${editingId}` : '/v1/admin/company-welcomes',
        token,
        {
          method: editingId ? 'PATCH' : 'POST',
          body: JSON.stringify({ title: title.trim(), body: body.trim(), active, isDefault }),
          totpCode: code,
        },
      );
      setNotice(t(lang, 'companyWelcomesSaved'));
      clearForm();
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function assign() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !assignUserId) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/company-welcomes/assignments', token, {
        method: 'PUT',
        body: JSON.stringify({ userId: assignUserId, welcomeId: assignWelcomeId || null }),
        totpCode: code,
      });
      setNotice(t(lang, 'companyWelcomesSaved'));
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

  const welcomes = board?.welcomes ?? [];

  return (
    <AdminShell active="companyWelcomes" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'companyWelcomesTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyWelcomesHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyWelcomesDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>
            {editingId ? t(lang, 'companyWelcomesSave') : t(lang, 'companyWelcomesNew')}
          </h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'companyWelcomesName')}
              <input value={title} maxLength={40} onChange={(event) => setTitle(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyWelcomesActive')}
              <input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyWelcomesDefault')}
              <input type="checkbox" checked={isDefault} onChange={(event) => setIsDefault(event.target.checked)} />
            </label>
          </div>
          <label className="staff-filter grow" style={{ marginTop: 12 }}>
            {t(lang, 'companyWelcomesBody')}
            <textarea value={body} maxLength={500} rows={4} onChange={(event) => setBody(event.target.value)} />
          </label>
          <div style={{ marginTop: 12 }}>
            <button type="button" className="btn-primary sm" disabled={saving} onClick={saveWelcome}>
              {saving ? t(lang, 'saving') : t(lang, 'companyWelcomesSave')}
            </button>{' '}
            {editingId ? (
              <button type="button" onClick={clearForm}>
                {t(lang, 'companyWelcomesNew')}
              </button>
            ) : null}
          </div>
        </div>
      ) : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{t(lang, 'companyWelcomesAssign')}</h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'name')}
              <select
                value={assignUserId}
                onChange={(event) => {
                  const userId = event.target.value;
                  setAssignUserId(userId);
                  setAssignWelcomeId(board?.assignments.find((row) => row.userId === userId)?.welcomeId ?? '');
                }}
              >
                <option value="">—</option>
                {(board?.people ?? []).map((person) => (
                  <option key={person.userId} value={person.userId}>
                    {person.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="staff-filter grow">
              {t(lang, 'companyWelcomesTitle')}
              <select value={assignWelcomeId} onChange={(event) => setAssignWelcomeId(event.target.value)}>
                <option value="">{t(lang, 'companyWelcomesDefault')}</option>
                {welcomes.map((welcome) => (
                  <option key={welcome.id} value={welcome.id}>
                    {welcome.title}
                  </option>
                ))}
              </select>
            </label>
          </div>
          <button type="button" className="btn-primary sm" disabled={saving} onClick={assign} style={{ marginTop: 12 }}>
            {t(lang, 'companyWelcomesAssign')}
          </button>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {welcomes.length === 0 ? <p className="muted">{t(lang, 'companyWelcomesNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyWelcomesName')}</th>
                <th>{t(lang, 'companyWelcomesBody')}</th>
                <th />
                <th />
              </tr>
            </thead>
            <tbody>
              {welcomes.map((welcome) => (
                <tr key={welcome.id}>
                  <td>{welcome.title}</td>
                  <td>{welcome.body}</td>
                  <td>
                    {welcome.isDefault ? t(lang, 'companyWelcomesDefault') : ''}{' '}
                    {welcome.active ? t(lang, 'companyWelcomesActive') : t(lang, 'companyWelcomesPaused')}
                  </td>
                  <td>
                    {isSuper ? (
                      <button
                        type="button"
                        onClick={() => {
                          setEditingId(welcome.id);
                          setTitle(welcome.title);
                          setBody(welcome.body);
                          setActive(welcome.active);
                          setIsDefault(welcome.isDefault);
                        }}
                      >
                        {t(lang, 'companyContactsEdit')}
                      </button>
                    ) : null}
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
