'use client';
// Made by Dr Ali — restore soft-deleted accounts (SuperAdmin / Ops staff).

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { LANG_KEY, TOKEN_KEY } from '@/lib/session';

type DeactivatedUser = {
  id: string;
  name?: string;
  email?: string | null;
  phone?: string | null;
  role?: string;
  obicId?: string | null;
  deletedAt?: string | null;
};

function canRestore(me: Record<string, unknown>): boolean {
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

function fmtWhen(iso?: string | null, lang?: Lang): string {
  if (!iso) return '';
  try {
    return new Date(iso).toLocaleString(
      lang === 'ar' ? 'ar' : lang === 'zh' ? 'zh-CN' : 'en',
    );
  } catch {
    return iso;
  }
}

export default function AccountsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [rows, setRows] = useState<DeactivatedUser[]>([]);
  const [q, setQ] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const onLang = useCallback((l: Lang) => setLang(l), []);

  const load = useCallback(async (token: string, query: string) => {
    const path = query.trim()
      ? `/v1/admin/users/deactivated?q=${encodeURIComponent(query.trim())}`
      : '/v1/admin/users/deactivated';
    const list = await adminFetch(path, token);
    setRows(Array.isArray(list) ? (list as DeactivatedUser[]) : []);
  }, []);

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    const saved = sessionStorage.getItem(LANG_KEY) as Lang | null;
    if (saved === 'ar' || saved === 'en' || saved === 'zh') setLang(saved);

    (async () => {
      try {
        const profile = (await adminFetch('/v1/admin/me', token)) as Record<
          string,
          unknown
        >;
        setMe(profile);
        if (!canRestore(profile)) {
          setError(t(lang, 'accountsDenied'));
          return;
        }
        await load(token, '');
      } catch (e) {
        setError(e instanceof Error ? e.message : String(e));
      }
    })();
  }, [router, load, lang]);

  async function search() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setError(null);
    try {
      await load(token, q);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  }

  async function restore(id: string) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setBusyId(id);
    setError(null);
    try {
      await adminFetch(`/v1/admin/users/${id}/restore`, token, {
        method: 'POST',
        body: '{}',
      });
      await load(token, q);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusyId(null);
    }
  }

  if (!me) {
    return (
      <div className="web-shell">
        <p className="muted">{t(lang, 'loading')}</p>
      </div>
    );
  }

  return (
    <AdminShell active="accounts" me={me} onLangChange={onLang}>
      <header className="web-head">
        <div>
          <h2>{t(lang, 'accountsTitle')}</h2>
          <p className="muted">{t(lang, 'accountsHint')}</p>
        </div>
      </header>

      {!canRestore(me) ? (
        <p className="error">{t(lang, 'accountsDenied')}</p>
      ) : (
        <>
          <div className="staff-toolbar" style={{ marginBottom: 16 }}>
            <label className="staff-filter grow">
              <span>{t(lang, 'search')}</span>
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') void search();
                }}
                placeholder={t(lang, 'accountsSearchPh')}
              />
            </label>
            <button type="button" className="btn" onClick={() => void search()}>
              {t(lang, 'search')}
            </button>
          </div>

          {error ? <p className="error">{error}</p> : null}

          <div className="web-card">
            {rows.length === 0 ? (
              <p className="muted">{t(lang, 'accountsEmpty')}</p>
            ) : (
              <table className="web-table">
                <thead>
                  <tr>
                    <th>{t(lang, 'staff')}</th>
                    <th>{t(lang, 'role')}</th>
                    <th>{t(lang, 'accountsDeletedAt')}</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {rows.map((u) => (
                    <tr key={u.id}>
                      <td>
                        <div className="staff-name">{u.name || '—'}</div>
                        <div className="staff-sub muted">
                          {[u.email, u.phone, u.obicId]
                            .filter(Boolean)
                            .join(' · ')}
                        </div>
                      </td>
                      <td>{u.role || '—'}</td>
                      <td>{fmtWhen(u.deletedAt, lang)}</td>
                      <td>
                        <button
                          type="button"
                          className="btn"
                          disabled={busyId === u.id}
                          onClick={() => void restore(u.id)}
                        >
                          {busyId === u.id
                            ? '…'
                            : t(lang, 'accountsRestore')}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </>
      )}
    </AdminShell>
  );
}
