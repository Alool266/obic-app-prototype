'use client';
// Made by Dr Ali — Shared documents. The latest save stays. This is not a drive file.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type DocRow = { id: string; title: string; active: boolean; editorName: string | null; updatedAt: string };
type DocDetail = DocRow & { body: string };
type Board = { rows: DocRow[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanyDocumentsPage() {
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
    setBoard((await adminFetch('/v1/admin/company-documents', token)) as Board);
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

  async function openDoc(id: string) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setError(null);
    try {
      const row = (await adminFetch(`/v1/admin/company-documents/${id}`, token)) as DocDetail;
      setEditingId(row.id);
      setTitle(row.title);
      setBody(row.body);
      setActive(row.active);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    }
  }

  async function save() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !title.trim() || !body.trim()) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(
        editingId ? `/v1/admin/company-documents/${editingId}` : '/v1/admin/company-documents',
        token,
        {
          method: editingId ? 'PATCH' : 'POST',
          body: JSON.stringify({ title: title.trim(), body: body.trim(), active }),
          totpCode: code,
        },
      );
      setNotice(t(lang, 'companyDocumentsSaved'));
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

  return (
    <AdminShell active="companyDocuments" me={me} onLangChange={onLang}>
      <div className="web-head">
        <div>
          <h1>{t(lang, 'companyDocumentsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyDocumentsHint')}</p>
        </div>
      </div>
      {error ? <p className="err">{error}</p> : null}
      {notice ? <p className="muted staff-note">{notice}</p> : null}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyDocumentsDenied')}</p> : null}

      {canReview(me) && (isSuper || editingId) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>
            {editingId ? t(lang, 'companyDocumentsSave') : t(lang, 'companyDocumentsNew')}
          </h2>
          <label className="staff-filter grow">
            {t(lang, 'companyDocumentsName')}
            <input
              value={title}
              maxLength={80}
              disabled={!isSuper}
              onChange={(event) => setTitle(event.target.value)}
            />
          </label>
          <label className="staff-filter grow" style={{ display: 'block', marginTop: 12 }}>
            {t(lang, 'companyDocumentsBody')}
            <textarea
              value={body}
              maxLength={8000}
              rows={8}
              disabled={!isSuper}
              onChange={(event) => setBody(event.target.value)}
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
            {t(lang, 'companyDocumentsActive')}
          </label>
          {isSuper ? (
            <div style={{ marginTop: 12 }}>
              <button type="button" className="btn-primary sm" disabled={saving} onClick={save}>
                {saving ? t(lang, 'saving') : t(lang, 'companyDocumentsSave')}
              </button>{' '}
              {editingId ? (
                <button type="button" onClick={clearForm}>
                  {t(lang, 'companyDocumentsNew')}
                </button>
              ) : null}
            </div>
          ) : null}
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {rows.length === 0 ? <p className="muted">{t(lang, 'companyDocumentsNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyDocumentsName')}</th>
                <th />
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>
                    {row.title}
                    {row.editorName ? ` · ${row.editorName}` : ''}
                  </td>
                  <td>{row.active ? t(lang, 'companyDocumentsActive') : t(lang, 'companyDocumentsPaused')}</td>
                  <td>
                    <button type="button" onClick={() => openDoc(row.id)}>
                      {t(lang, 'companyDocumentsSave')}
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
