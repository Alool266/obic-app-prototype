'use client';
// Made by Dr Ali — Internal Ops hub (web prototype). SuperAdmin + opsAccess employees.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { OPS_MODULES } from '@/lib/ops-modules';
import { TOKEN_KEY } from '@/lib/session';

type Me = {
  name?: string;
  role?: string;
  isSuperAdmin?: boolean;
  opsAccess?: boolean;
  canOpenOps?: boolean;
};

function meCanOpenOps(me: Me | null): boolean {
  if (!me) return false;
  if (me.canOpenOps === true) return true;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

export default function InternalOpsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Me | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [activeId, setActiveId] = useState<string | null>(null);
  const onLang = useCallback((l: Lang) => setLang(l), []);

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    (async () => {
      try {
        const m = (await adminFetch('/v1/admin/me', token)) as Me;
        setMe(m);
        if (!meCanOpenOps(m)) {
          setError('ops_denied');
        }
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed');
      }
    })();
  }, [router]);

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted" style={{ color: '#e2e8f0' }}>
          {t(lang, 'loading')}
        </p>
      </div>
    );
  }

  const allowed = meCanOpenOps(me);
  const active = OPS_MODULES.find((m) => m.id === activeId) ?? null;

  return (
    <AdminShell active="ops" me={me} onLangChange={onLang}>
      <div className="ops-hero">
        <p className="ops-hero-kicker">OBIC Internal</p>
        <h2>{t(lang, 'internalOpsHero')}</h2>
        <p>{t(lang, 'internalOpsHeroSub')}</p>
      </div>

      {!allowed ? (
        <div className="web-lock">
          {error === 'ops_denied' || !error
            ? t(lang, 'opsDenied')
            : error}
        </div>
      ) : (
        <>
          <div className="sign-banner">{t(lang, 'opsProtoBanner')}</div>
          <p className="muted staff-note">{t(lang, 'internalOpsDesc')}</p>

          <div className="ops-grid">
            {OPS_MODULES.map((m) => (
              <button
                key={m.id}
                type="button"
                className={`ops-tile${activeId === m.id ? ' on' : ''}`}
                style={{ ['--ops-accent' as string]: m.accent }}
                onClick={() => setActiveId(m.id)}
              >
                <span className="ops-tile-dot" aria-hidden />
                <strong>{lang === 'ar' ? m.titleAr : m.titleEn}</strong>
                <span>{lang === 'ar' ? m.subtitleAr : m.subtitleEn}</span>
              </button>
            ))}
          </div>

          {active && (
            <div className="web-card ops-detail">
              <div className="ops-detail-head">
                <h3>{lang === 'ar' ? active.titleAr : active.titleEn}</h3>
                <button
                  type="button"
                  className="mini-btn"
                  onClick={() => setActiveId(null)}
                >
                  ✕
                </button>
              </div>
              <p className="muted">
                {lang === 'ar' ? active.subtitleAr : active.subtitleEn}
              </p>
              <div className="ops-detail-body">
                <p>{t(lang, 'opsModuleStub')}</p>
              </div>
            </div>
          )}
        </>
      )}
    </AdminShell>
  );
}
