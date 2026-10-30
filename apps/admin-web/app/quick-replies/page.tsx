'use client';
// Made by Dr Ali — Quick replies. Staff copy the text. The app does not send it.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Reply = {
  id: string;
  title: string;
  body: string;
  active: boolean;
  ownerUserId: string | null;
  ownerName: string | null;
};

type Board = { rows: Reply[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function QuickRepliesPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [active, setActive] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/quick-replies', token)) as Board);
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
  }

  async function saveReply() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !title.trim() || !body.trim()) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(editingId ? `/v1/admin/quick-replies/${editingId}` : '/v1/admin/quick-replies', token, {
        method: editingId ? 'PATCH' : 'POST',
        body: JSON.stringify({ title: title.trim(), body: body.trim(), active }),
        totpCode: code,
      });
      setNotice(t(lang, 'quickRepliesSaved'));
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
        <p className="muted">{error || '…'}</p>
      </div>
    );
  }

  const rows = board?.rows ?? [];

  return (
    <AdminShell active="quickReplies" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'quickRepliesTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'quickRepliesHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'quickRepliesDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{editingId ? t(lang, 'quickRepliesSave') : t(lang, 'quickRepliesNew')}</h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'quickRepliesName')}
              <input value={title} maxLength={24} onChange={(event) => setTitle(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'quickRepliesActive')}
              <input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} />
            </label>
          </div>
          <label className="staff-filter grow" style={{ marginTop: 12 }}>
            {t(lang, 'quickRepliesBody')}
            <textarea value={body} maxLength={300} rows={3} onChange={(event) => setBody(event.target.value)} />
          </label>
          <div style={{ marginTop: 12 }}>
            <button type="button" className="btn-primary sm" disabled={saving} onClick={saveReply}>
              {saving ? t(lang, 'saving') : t(lang, 'quickRepliesSave')}
            </button>{' '}
            {editingId ? (
              <button type="button" onClick={clearForm}>
                {t(lang, 'quickRepliesNew')}
              </button>
            ) : null}
          </div>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {rows.length === 0 ? <p className="muted">{t(lang, 'quickRepliesNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'quickRepliesName')}</th>
                <th>{t(lang, 'quickRepliesBody')}</th>
                <th>{t(lang, 'name')}</th>
                <th />
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>{row.title}</td>
                  <td>{row.body}</td>
                  <td>{row.ownerUserId ? (row.ownerName ?? '—') : t(lang, 'quickRepliesCompany')}</td>
                  <td>{row.active ? t(lang, 'quickRepliesActive') : t(lang, 'quickRepliesPaused')}</td>
                  <td>
                    {isSuper ? (
                      <button
                        type="button"
                        onClick={() => {
                          setEditingId(row.id);
                          setTitle(row.title);
                          setBody(row.body);
                          setActive(row.active);
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
