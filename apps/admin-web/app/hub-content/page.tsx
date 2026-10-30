'use client';
// Made by Dr Ali — Publish guides / places / deals for China · Daily · Travel hubs.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';

type Me = {
  name?: string;
  role?: string;
  isSuperAdmin?: boolean;
};

type Row = {
  id: string;
  hub?: string;
  titleAr?: string;
  titleEn?: string;
  nameAr?: string;
  nameEn?: string;
  city?: string;
  published?: boolean;
};

type Bundle = {
  guides: Row[];
  places: Row[];
  deals: Row[];
};

function labelOf(lang: Lang, r: Row): string {
  if (lang === 'ar') {
    return r.titleAr || r.nameAr || r.titleEn || r.nameEn || r.id;
  }
  return r.titleEn || r.nameEn || r.titleAr || r.nameAr || r.id;
}

export default function HubContentAdminPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Me | null>(null);
  const [bundle, setBundle] = useState<Bundle | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<'guides' | 'places' | 'deals'>('guides');
  const onLang = useCallback((l: Lang) => setLang(l), []);

  const load = useCallback(async (token: string) => {
    setLoading(true);
    setError(null);
    try {
      const json = (await adminFetch('/v1/admin/hub-content', token)) as Bundle;
      setBundle(json);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const token =
      sessionStorage.getItem(TOKEN_KEY) || localStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    (async () => {
      try {
        const m = (await adminFetch('/v1/admin/me', token)) as Me;
        setMe(m);
        await load(token);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed');
        setLoading(false);
      }
    })();
  }, [router, load]);

  async function toggle(kind: 'guides' | 'places' | 'deals', id: string, published: boolean) {
    const token =
      sessionStorage.getItem(TOKEN_KEY) || localStorage.getItem(TOKEN_KEY);
    if (!token) return;
    try {
      await adminFetch('/v1/admin/hub-content/publish', token, {
        method: 'PATCH',
        body: JSON.stringify({ kind, id, published }),
      });
      await load(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
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

  const rows = bundle?.[tab] ?? [];
  const title =
    lang === 'ar' ? 'محتوى المراكز (صين / يومي / سفر)' : 'Hub content (China / Daily / Travel)';
  const hint =
    lang === 'ar'
      ? 'نشر أدلة وأماكن وعروض — الطلبات تُنفَّذ من مكتب الطلبات.'
      : 'Publish guides, places, deals — fulfill orders from the Orders desk.';

  return (
    <AdminShell active="hub-content" me={me} onLangChange={onLang}>
      <div className="web-access-banner">{t(lang, 'webAccessNote')}</div>
      <header className="web-head">
        <div>
          <h2>{title}</h2>
          <p>{hint}</p>
        </div>
      </header>

      {error && <p className="err">{error}</p>}

      <div className="staff-toolbar" style={{ gap: 8 }}>
        {(['guides', 'places', 'deals'] as const).map((k) => (
          <button
            key={k}
            type="button"
            className={tab === k ? 'btn primary' : 'btn'}
            onClick={() => setTab(k)}
          >
            {k === 'guides'
              ? lang === 'ar'
                ? 'أدلة'
                : 'Guides'
              : k === 'places'
                ? lang === 'ar'
                  ? 'أماكن'
                  : 'Places'
                : lang === 'ar'
                  ? 'عروض'
                  : 'Deals'}
          </button>
        ))}
      </div>

      {loading ? (
        <p className="muted">{t(lang, 'loading')}</p>
      ) : rows.length === 0 ? (
        <p className="muted">{lang === 'ar' ? 'لا عناصر' : 'No items'}</p>
      ) : (
        <div className="staff-table-wrap">
          <table className="staff-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>{lang === 'ar' ? 'المركز' : 'Hub'}</th>
                <th>{lang === 'ar' ? 'العنوان' : 'Title'}</th>
                <th>{lang === 'ar' ? 'مدينة' : 'City'}</th>
                <th>{lang === 'ar' ? 'منشور' : 'Published'}</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id}>
                  <td>
                    <code>{r.id}</code>
                  </td>
                  <td>{r.hub || '—'}</td>
                  <td>{labelOf(lang, r)}</td>
                  <td>{r.city || '—'}</td>
                  <td>
                    <button
                      type="button"
                      className="btn"
                      onClick={() => toggle(tab, r.id, !r.published)}
                    >
                      {r.published
                        ? lang === 'ar'
                          ? 'إخفاء'
                          : 'Unpublish'
                        : lang === 'ar'
                          ? 'نشر'
                          : 'Publish'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </AdminShell>
  );
}
