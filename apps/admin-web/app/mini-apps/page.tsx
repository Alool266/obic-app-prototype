'use client';
// Made by Dr Ali — SuperAdmin mini-app review (approve, reject, disable).

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminAssetUrl, adminFetch } from '@/lib/api';
import { Lang, miniAppStatusLabel, t } from '@/lib/i18n';
import { LANG_KEY, TOKEN_KEY } from '@/lib/session';

type MiniStatus = 'pending' | 'approved' | 'rejected' | 'disabled';

type MiniAppRow = {
  id: string;
  name: string;
  description: string;
  iconUrl?: string | null;
  startUrl: string;
  status: MiniStatus;
  reviewNote?: string | null;
  ownerUserId: string;
  ownerName?: string | null;
  createdAt?: string;
  reviewedAt?: string | null;
};

function isSuperAdmin(me: Record<string, unknown>): boolean {
  return me.isSuperAdmin === true || me.role === 'SuperAdmin';
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

export default function MiniAppsReviewPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [rows, setRows] = useState<MiniAppRow[]>([]);
  const [selected, setSelected] = useState<MiniAppRow | null>(null);
  const [reason, setReason] = useState('');
  const [error, setError] = useState<string | null>(null);
  const onLang = useCallback((l: Lang) => setLang(l), []);

  const loadList = useCallback(async (token: string) => {
    const list = await adminFetch('/v1/admin/mini-apps', token);
    setRows(Array.isArray(list) ? (list as MiniAppRow[]) : []);
  }, []);

  const load = useCallback(
    async (token: string) => {
      const m = await adminFetch('/v1/admin/me', token);
      if (!isSuperAdmin(m)) {
        throw new Error('Insufficient role');
      }
      setMe(m);
      await loadList(token);
    },
    [loadList],
  );

  useEffect(() => {
    const saved = sessionStorage.getItem(LANG_KEY) as Lang | null;
    if (saved === 'ar' || saved === 'en' || saved === 'zh') setLang(saved);
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    (async () => {
      try {
        await load(token);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed');
      }
    })();
  }, [router, load]);

  async function openDetail(id: string) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    try {
      const detail = (await adminFetch(
        `/v1/admin/mini-apps/${id}`,
        token,
      )) as MiniAppRow;
      setSelected(detail);
      setReason('');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  async function openHosted(row: MiniAppRow) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    try {
      switch (row.status) {
        case 'approved':
          window.open(
            adminAssetUrl(`/v1/mini-apps/${row.id}/files/index.html`),
            '_blank',
            'noopener,noreferrer',
          );
          return;
        case 'pending': {
          const preview = (await adminFetch(
            `/v1/admin/mini-apps/${row.id}/preview`,
            token,
            { method: 'POST', body: JSON.stringify({}) },
          )) as { previewPath?: string };
          const path = preview.previewPath ?? '';
          if (!path.startsWith('/v1/mini-apps/')) {
            setError(t(lang, 'miniAppsOpenPage'));
            return;
          }
          window.open(adminAssetUrl(path), '_blank', 'noopener,noreferrer');
          return;
        }
        case 'rejected':
        case 'disabled':
          return;
        default: {
          const _exhaustive: never = row.status;
          return _exhaustive;
        }
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  async function act(id: string, action: 'approve' | 'reject' | 'disable') {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    if (action === 'reject' && reason.trim().length < 2) {
      setError(t(lang, 'miniAppsReasonPh'));
      return;
    }
    const path =
      action === 'approve'
        ? `/v1/admin/mini-apps/${id}/approve`
        : action === 'reject'
          ? `/v1/admin/mini-apps/${id}/reject`
          : `/v1/admin/mini-apps/${id}/disable`;
    try {
      const updated = (await adminFetch(path, token, {
        method: 'POST',
        body: JSON.stringify(
          action === 'reject' ? { reason: reason.trim() } : {},
        ),
      })) as MiniAppRow;
      setSelected(updated);
      setError(null);
      await loadList(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  if (!me && !error) {
    return (
      <div className="login-stage">
        <p className="muted" style={{ color: '#e2e8f0' }}>
          {t(lang, 'loading')}
        </p>
      </div>
    );
  }

  if (!me) {
    return (
      <div className="login-stage">
        <div className="login-card">
          <p className="err">{error || t(lang, 'miniAppsAdminDenied')}</p>
          <button type="button" className="btn-primary" onClick={() => router.replace('/')}>
            {t(lang, 'backLogin')}
          </button>
        </div>
      </div>
    );
  }

  const canOpenPackage =
    selected?.status === 'pending' || selected?.status === 'approved';

  return (
    <AdminShell active="mini-apps" me={me} onLangChange={onLang}>
      <header className="web-head">
        <div>
          <h2>{t(lang, 'miniAppsAdminTitle')}</h2>
          <p>{t(lang, 'miniAppsAdminHint')}</p>
        </div>
      </header>
      {error ? <p className="err">{error}</p> : null}
      <div className="web-card">
        {rows.length === 0 ? (
          <p className="web-note">{t(lang, 'miniAppsAdminEmpty')}</p>
        ) : (
          <ul className="inbox-list">
            {rows.map((row) => {
              const active = selected?.id === row.id;
              const open = row.status === 'pending';
              return (
                <li
                  key={row.id}
                  className={[open ? 'unread' : undefined, active ? 'on' : undefined]
                    .filter(Boolean)
                    .join(' ') || undefined}
                >
                  <button type="button" onClick={() => openDetail(row.id)}>
                    <strong>
                      {row.name} · {miniAppStatusLabel(lang, row.status)}
                    </strong>
                    <span>{row.ownerName || row.ownerUserId}</span>
                    <small dir="ltr">{row.startUrl}</small>
                  </button>
                </li>
              );
            })}
          </ul>
        )}
      </div>
      {selected ? (
        <div className="web-card" style={{ marginTop: 16 }}>
          <h3>{selected.name}</h3>
          <p className="web-note">{selected.description}</p>
          <p className="web-note">
            <strong>{t(lang, 'miniAppsOwner')}:</strong>{' '}
            {selected.ownerName || selected.ownerUserId}
          </p>
          <p className="web-note" dir="ltr">
            {selected.startUrl}
          </p>
          <p className="web-note" dir="ltr">
            {selected.id}
          </p>
          <p className="web-note">
            {miniAppStatusLabel(lang, selected.status)}
            {selected.reviewedAt ? ` · ${fmtWhen(selected.reviewedAt, lang)}` : ''}
            {selected.createdAt ? ` · ${fmtWhen(selected.createdAt, lang)}` : ''}
          </p>
          {selected.reviewNote ? (
            <p className="web-note">
              {t(lang, 'miniAppsReason')}: {selected.reviewNote}
            </p>
          ) : null}
          {canOpenPackage && selected ? (
            <p className="mod-actions">
              <button type="button" onClick={() => openHosted(selected)}>
                {t(lang, 'miniAppsOpenPage')}
              </button>
            </p>
          ) : null}
          {selected.status === 'pending' ? (
            <>
              <p className="mod-actions">
                <button type="button" onClick={() => act(selected.id, 'approve')}>
                  {t(lang, 'miniAppsApprove')}
                </button>
              </p>
              <p>
                <input
                  className="web-input"
                  dir="auto"
                  value={reason}
                  placeholder={t(lang, 'miniAppsReasonPh')}
                  onChange={(e) => setReason(e.target.value)}
                />
              </p>
              <p className="mod-actions">
                <button type="button" onClick={() => act(selected.id, 'reject')}>
                  {t(lang, 'miniAppsReject')}
                </button>
              </p>
            </>
          ) : null}
          {selected.status === 'approved' ? (
            <p className="mod-actions">
              <button type="button" onClick={() => act(selected.id, 'disable')}>
                {t(lang, 'miniAppsDisable')}
              </button>
            </p>
          ) : null}
        </div>
      ) : null}
    </AdminShell>
  );
}
