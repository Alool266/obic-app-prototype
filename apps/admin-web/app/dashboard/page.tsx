'use client';
// Made by Dr Ali — W1 Operations dashboard (prototype-matched).

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, statusLabel, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';

function langName(lang: Lang): string {
  switch (lang) {
    case 'ar':
      return 'العربية';
    case 'en':
      return 'English';
    case 'zh':
      return '中文';
    case 'fr':
      return 'Français';
    default: {
      const neverLang: never = lang;
      return neverLang;
    }
  }
}

export default function DashboardPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [dash, setDash] = useState<Record<string, unknown> | null>(null);
  const [orders, setOrders] = useState<Record<string, unknown>[]>([]);
  const [error, setError] = useState<string | null>(null);
  const onLang = useCallback((l: Lang) => setLang(l), []);

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    (async () => {
      try {
        const m = await adminFetch('/v1/admin/me', token);
        if (m.totpEnrollRequired === true) {
          router.replace('/settings/totp');
          return;
        }
        const d = await adminFetch('/v1/admin/dashboard', token);
        const o = await adminFetch('/v1/admin/orders', token);
        setMe(m);
        setDash(d);
        setOrders(Array.isArray(o) ? o : []);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed');
        sessionStorage.removeItem(TOKEN_KEY);
      }
    })();
  }, [router]);

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

  if (!me || !dash) {
    return (
      <div className="login-stage">
        <p className="muted" style={{ color: '#e2e8f0' }}>
          {t(lang, 'loading')}
        </p>
      </div>
    );
  }

  const ordersMeta = (dash.orders || {}) as Record<string, number>;
  const isSa = me.isSuperAdmin === true;
  const openCount =
    (ordersMeta.submitted ?? 0) + (ordersMeta.inProgress ?? 0);

  return (
    <AdminShell active="dashboard" me={me} onLangChange={onLang}>
      <div className="web-access-banner">{t(lang, 'webAccessNote')}</div>
      <header className="web-head">
        <div>
          <h2>{t(lang, 'opsDash')}</h2>
          <p>
            {t(lang, 'desktopAdmin')} · {langName(lang)} ·{' '}
            {String(me.name || '')}
          </p>
        </div>
      </header>

      <section className="web-kpis">
        <div>
          <strong>{ordersMeta.total ?? 0}</strong>
          <span>{t(lang, 'ordersTotal')}</span>
        </div>
        <div>
          <strong>{openCount}</strong>
          <span>{t(lang, 'openOrders')}</span>
        </div>
        <div>
          <strong>—</strong>
          <span>{t(lang, 'activeChats')}</span>
        </div>
        <div>
          <strong>{isSa ? (ordersMeta.unassigned ?? 0) : '—'}</strong>
          <span>{isSa ? t(lang, 'unassigned') : t(lang, 'staffSeats')}</span>
        </div>
      </section>

      <section className="web-grid">
        <div className="web-card">
          <h3>{t(lang, 'liveOrders')}</h3>
          {orders.length === 0 ? (
            <p className="web-note">{t(lang, 'noOrders')}</p>
          ) : (
            <table className="web-table">
              <thead>
                <tr>
                  <th>{t(lang, 'id')}</th>
                  <th>{t(lang, 'service')}</th>
                  <th>{t(lang, 'branch')}</th>
                  <th>{t(lang, 'status')}</th>
                  <th>{t(lang, 'assignee')}</th>
                </tr>
              </thead>
              <tbody>
                {orders.slice(0, 12).map((o) => {
                  const status = String(o.status || '');
                  const warn = status === 'InProgress';
                  return (
                    <tr key={String(o.id)}>
                      <td>
                        #{String(o.id).slice(0, 8)}
                      </td>
                      <td>
                        {String(
                          lang === 'ar'
                            ? (o.subServiceNameAr as string) ||
                                (o.serviceTitleAr as string) ||
                                (o.serviceSlug as string) ||
                                t(lang, 'none')
                            : (o.subServiceNameEn as string) ||
                                (o.serviceTitleEn as string) ||
                                (o.serviceSlug as string) ||
                                t(lang, 'none'),
                        )}
                        <div className="muted-mini">
                          {String(o.serviceSlug || '')}
                        </div>
                      </td>
                      <td>{String(o.preferredBranch || t(lang, 'none'))}</td>
                      <td>
                        <span className={`badge ${warn ? 'warn' : ''}`}>
                          {statusLabel(lang, status)}
                        </span>
                      </td>
                      <td>
                        {String(
                          o.assignedEmployeeName ||
                            (o.assignedEmployeeId
                              ? String(o.assignedEmployeeId).slice(0, 8)
                              : t(lang, 'none')),
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
          <Link href="/orders" className="btn-primary" style={{ marginTop: 12 }}>
            {t(lang, 'openOrdersDesk')}
          </Link>
        </div>

        <div className="web-card">
          <h3>{t(lang, 'privileges')}</h3>
          <p className="web-note">
            {isSa ? t(lang, 'canPromote') : t(lang, 'empLocked')}
          </p>
          <div className="perm-table web">
            <div className="perm-row">
              <span>{t(lang, 'chatOversight')}</span>
              <span className={isSa ? 'ok' : 'no'}>
                {isSa ? '✓' : t(lang, 'locked')}
              </span>
            </div>
            <div className="perm-row">
              <span>{t(lang, 'addContact')}</span>
              <span className={isSa ? 'ok' : 'no'}>
                {isSa ? '✓' : t(lang, 'locked')}
              </span>
            </div>
            <div className="perm-row">
              <span>{t(lang, 'promoteStaff')}</span>
              <span className={isSa ? 'ok' : 'no'}>
                {isSa ? '✓' : t(lang, 'locked')}
              </span>
            </div>
          </div>
          <Link
            href="/staff"
            className="btn-primary"
            style={{ marginTop: 12 }}
          >
            {isSa ? t(lang, 'manageStaff') : t(lang, 'viewRoster')}
          </Link>
        </div>
      </section>
    </AdminShell>
  );
}
