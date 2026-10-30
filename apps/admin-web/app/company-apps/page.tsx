'use client';
// Made by Dr Ali — Company web tools. The page stays on its own site.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type AppRow = {
  id: string;
  name: string;
  note: string | null;
  url: string;
  active: boolean;
};
type Board = { rows: AppRow[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanyAppsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [note, setNote] = useState('');
  const [url, setUrl] = useState('');
  const [active, setActive] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/company-apps', token)) as Board);
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
    setName('');
    setNote('');
    setUrl('');
    setActive(true);
  }

  function openApp(row: AppRow) {
    setEditingId(row.id);
    setName(row.name);
    setNote(row.note ?? '');
    setUrl(row.url);
    setActive(row.active);
  }

  async function save() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !name.trim() || !url.trim()) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(editingId ? `/v1/admin/company-apps/${editingId}` : '/v1/admin/company-apps', token, {
        method: editingId ? 'PATCH' : 'POST',
        body: JSON.stringify({
          name: name.trim(),
          note: note.trim(),
          url: url.trim(),
          active,
        }),
        totpCode: code,
      });
      setNotice(t(lang, 'companyAppsSaved'));
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
    <AdminShell active="companyApps" me={me} onLangChange={onLang}>
      <div className="web-head">
        <div>
          <h1>{t(lang, 'companyAppsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyAppsHint')}</p>
        </div>
      </div>
      {error ? <p className="err">{error}</p> : null}
      {notice ? <p className="muted staff-note">{notice}</p> : null}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyAppsDenied')}</p> : null}

      {showForm ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{editingId ? t(lang, 'companyAppsSave') : t(lang, 'companyAppsNew')}</h2>
          <label className="staff-filter grow">
            {t(lang, 'companyAppsName')}
            <input value={name} maxLength={40} disabled={!isSuper} onChange={(event) => setName(event.target.value)} />
          </label>
          <label className="staff-filter grow" style={{ display: 'block', marginTop: 12 }}>
            {t(lang, 'companyAppsUrl')}
            <input value={url} maxLength={200} disabled={!isSuper} onChange={(event) => setUrl(event.target.value)} />
          </label>
          <label className="staff-filter grow" style={{ display: 'block', marginTop: 12 }}>
            {t(lang, 'companyAppsNote')}
            <textarea
              value={note}
              maxLength={300}
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
            {t(lang, 'companyAppsActive')}
          </label>
          {isSuper ? (
            <div style={{ marginTop: 12 }}>
              <button type="button" className="btn-primary sm" disabled={saving} onClick={save}>
                {saving ? t(lang, 'saving') : t(lang, 'companyAppsSave')}
              </button>{' '}
              {editingId ? (
                <button type="button" onClick={clearForm}>
                  {t(lang, 'companyAppsNew')}
                </button>
              ) : null}
            </div>
          ) : null}
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {rows.length === 0 ? <p className="muted">{t(lang, 'companyAppsNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyAppsName')}</th>
                <th>{t(lang, 'companyAppsUrl')}</th>
                <th />
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>{row.name}</td>
                  <td>{row.url}</td>
                  <td>{row.active ? t(lang, 'companyAppsActive') : t(lang, 'companyAppsPaused')}</td>
                  <td>
                    <button type="button" onClick={() => openApp(row)}>
                      {t(lang, 'companyAppsSave')}
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
