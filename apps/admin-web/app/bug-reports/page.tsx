'use client';
// Made by Dr Ali — in-app bug reports (Employee + SuperAdmin).

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch, mediaUrl } from '@/lib/api';
import { Lang, bugReportStatusLabel, t } from '@/lib/i18n';
import { LANG_KEY, TOKEN_KEY } from '@/lib/session';

type BugStatus = 'open' | 'in_progress' | 'resolved' | 'dismissed';

type BugReport = {
  id: string;
  userId: string;
  userName?: string;
  description: string;
  photoUrls: string[];
  status: BugStatus;
  createdAt: string;
  updatedAt: string;
  reviewedBy?: string;
  reviewedAt?: string;
};

function isStaff(me: Record<string, unknown>): boolean {
  if (me.isSuperAdmin === true) return true;
  const role = me.role;
  return role === 'SuperAdmin' || role === 'Employee';
}

function fmtWhen(iso?: string, lang?: Lang): string {
  if (!iso) return '';
  try {
    return new Date(iso).toLocaleString(lang === 'ar' ? 'ar' : lang === 'zh' ? 'zh-CN' : 'en');
  } catch {
    return iso;
  }
}

export default function BugReportsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [reports, setReports] = useState<BugReport[]>([]);
  const [selected, setSelected] = useState<BugReport | null>(null);
  const [loadingDetail, setLoadingDetail] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const onLang = useCallback((l: Lang) => setLang(l), []);

  const loadList = useCallback(async (token: string) => {
    const list = await adminFetch('/v1/admin/bug-reports', token);
    setReports(Array.isArray(list) ? (list as BugReport[]) : []);
  }, []);

  const load = useCallback(
    async (token: string) => {
      const m = await adminFetch('/v1/admin/me', token);
      if (!isStaff(m)) {
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
    setLoadingDetail(true);
    try {
      const detail = (await adminFetch(`/v1/admin/bug-reports/${id}`, token)) as BugReport;
      setSelected(detail);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    } finally {
      setLoadingDetail(false);
    }
  }

  async function setStatus(id: string, status: BugStatus) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    try {
      const updated = (await adminFetch(`/v1/admin/bug-reports/${id}`, token, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      })) as BugReport;
      setSelected(updated);
      await loadList(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  function statusActions(report: BugReport) {
    const id = report.id;
    const cur = report.status;
    const btn = (status: BugStatus, labelKey: Parameters<typeof t>[1]) =>
      cur !== status ? (
        <button key={status} type="button" onClick={() => setStatus(id, status)}>
          {t(lang, labelKey)}
        </button>
      ) : null;
    return (
      <p className="mod-actions">
        {btn('open', 'bugMarkOpen')}
        {btn('in_progress', 'bugMarkInProgress')}
        {btn('resolved', 'bugMarkResolved')}
        {btn('dismissed', 'markDismissed')}
      </p>
    );
  }

  if (error) {
    return (
      <div className="login-stage">
        <div className="login-card">
          <p className="err">{error}</p>
          <button type="button" className="btn-primary" onClick={() => router.replace('/')}>
            {t(lang, 'backLogin')}
          </button>
        </div>
      </div>
    );
  }

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted" style={{ color: '#e2e8f0' }}>
          {t(lang, 'loading')}
        </p>
      </div>
    );
  }

  return (
    <AdminShell active="bug-reports" me={me} onLangChange={onLang}>
      <header className="web-head">
        <div>
          <h2>{t(lang, 'bugReportsTitle')}</h2>
          <p>{t(lang, 'bugReportsHint')}</p>
        </div>
      </header>
      <div className="web-card">
        {reports.length === 0 ? (
          <p className="web-note">{t(lang, 'bugReportsEmpty')}</p>
        ) : (
          <ul className="inbox-list">
            {reports.map((r) => {
              const open = r.status === 'open' || r.status === 'in_progress';
              const active = selected?.id === r.id;
              return (
                <li
                  key={r.id}
                  className={[open ? 'unread' : undefined, active ? 'on' : undefined]
                    .filter(Boolean)
                    .join(' ') || undefined}
                >
                  <button type="button" onClick={() => openDetail(r.id)}>
                    <strong>
                      {r.userName || r.userId} · {bugReportStatusLabel(lang, r.status)}
                    </strong>
                    <span>{r.description}</span>
                    <small>{fmtWhen(r.createdAt, lang)}</small>
                  </button>
                </li>
              );
            })}
          </ul>
        )}
      </div>
      {loadingDetail ? (
        <p className="web-note" style={{ marginTop: 16 }}>
          {t(lang, 'loading')}
        </p>
      ) : selected ? (
        <div className="web-card" style={{ marginTop: 16 }}>
          <h3>{t(lang, 'bugReportDetail')}</h3>
          <p className="web-note">
            <strong>{t(lang, 'bugReportUser')}:</strong> {selected.userName || selected.userId}
            {' · '}
            <strong>{t(lang, 'status')}:</strong> {bugReportStatusLabel(lang, selected.status)}
          </p>
          <p className="web-note">
            {t(lang, 'id')}: {selected.id} · {fmtWhen(selected.createdAt, lang)}
          </p>
          {selected.reviewedBy || selected.reviewedAt ? (
            <p className="web-note">
              {selected.reviewedBy ? `${t(lang, 'bugReportReviewedBy')}: ${selected.reviewedBy}` : ''}
              {selected.reviewedAt ? ` · ${fmtWhen(selected.reviewedAt, lang)}` : ''}
            </p>
          ) : null}
          <p style={{ whiteSpace: 'pre-wrap', margin: '12px 0' }}>{selected.description}</p>
          {selected.photoUrls?.length ? (
            <div>
              <strong>{t(lang, 'bugReportPhotos')}</strong>
              <ul className="bug-photo-row">
                {selected.photoUrls.map((url) => {
                  const src = mediaUrl(url);
                  return (
                    <li key={url}>
                      <a href={src} target="_blank" rel="noreferrer">
                        <img src={src} alt="" />
                      </a>
                    </li>
                  );
                })}
              </ul>
            </div>
          ) : null}
          {statusActions(selected)}
        </div>
      ) : reports.length > 0 ? (
        <p className="web-note" style={{ marginTop: 16 }}>
          {t(lang, 'bugReportPick')}
        </p>
      ) : null}
    </AdminShell>
  );
}
