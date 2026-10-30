'use client';
// Made by Dr Ali — Company tags. Staff attach them on the customer contact.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Tag = { id: string; name: string; active: boolean; contactCount: number };

type Board = { tags: Tag[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function CompanyTagsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [active, setActive] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/company-contact-tags', token)) as Board);
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
    setActive(true);
  }

  async function saveTag() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !name.trim()) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(
        editingId ? `/v1/admin/company-contact-tags/${editingId}` : '/v1/admin/company-contact-tags',
        token,
        {
          method: editingId ? 'PATCH' : 'POST',
          body: JSON.stringify({ name: name.trim(), active }),
          totpCode: code,
        },
      );
      setNotice(t(lang, 'companyTagsSaved'));
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

  const tags = board?.tags ?? [];

  return (
    <AdminShell active="companyTags" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'companyTagsTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyTagsHint')}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyTagsDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>
            {editingId ? t(lang, 'companyTagsSave') : t(lang, 'companyTagsNew')}
          </h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter grow">
              {t(lang, 'companyTagsName')}
              <input value={name} maxLength={24} onChange={(event) => setName(event.target.value)} />
            </label>
            <label className="staff-filter">
              {t(lang, 'companyTagsActive')}
              <input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} />
            </label>
          </div>
          <div style={{ marginTop: 12 }}>
            <button type="button" className="btn-primary sm" disabled={saving} onClick={saveTag}>
              {saving ? t(lang, 'saving') : t(lang, 'companyTagsSave')}
            </button>{' '}
            {editingId ? (
              <button type="button" onClick={clearForm}>
                {t(lang, 'companyTagsNew')}
              </button>
            ) : null}
          </div>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card">
          {tags.length === 0 ? <p className="muted">{t(lang, 'companyTagsNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyTagsName')}</th>
                <th>{t(lang, 'companyTagsCount')}</th>
                <th />
                <th />
              </tr>
            </thead>
            <tbody>
              {tags.map((tag) => (
                <tr key={tag.id}>
                  <td>{tag.name}</td>
                  <td>{tag.contactCount}</td>
                  <td>{tag.active ? t(lang, 'companyTagsActive') : t(lang, 'companyTagsPaused')}</td>
                  <td>
                    {isSuper ? (
                      <button
                        type="button"
                        onClick={() => {
                          setEditingId(tag.id);
                          setName(tag.name);
                          setActive(tag.active);
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
