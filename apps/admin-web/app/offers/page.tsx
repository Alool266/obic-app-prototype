'use client';
// Made by Dr Ali — Staff offers desk: search + filter via GET /v1/admin/offers.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch, mediaUrl } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';

type Me = {
  name?: string;
  role?: string;
  isSuperAdmin?: boolean;
  offersAccess?: boolean;
  canManageOffers?: boolean;
};

type OfferRow = {
  id: string;
  kind?: string;
  titleAr?: string;
  titleEn?: string;
  locationLabel?: string | null;
  priceLabelAr?: string | null;
  priceLabelEn?: string | null;
  isPublished?: boolean;
  isSoldOut?: boolean;
  isExpired?: boolean;
  createdByName?: string | null;
  media?: { kind?: string; url?: string }[];
};

function meCanManageOffers(me: Me | null): boolean {
  if (!me) return false;
  if (me.canManageOffers === true) return true;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  return me.role === 'Employee' && me.offersAccess === true;
}

function coverUrl(o: OfferRow): string {
  const media = o.media;
  if (!Array.isArray(media)) return '';
  for (const m of media) {
    if (m?.kind === 'image' && m.url) return mediaUrl(m.url);
  }
  return '';
}

function statusKey(o: OfferRow): 'offerPublished' | 'offerDraft' | 'offerSoldOut' | 'offerExpired' {
  if (o.isSoldOut) return 'offerSoldOut';
  if (o.isExpired) return 'offerExpired';
  if (o.isPublished) return 'offerPublished';
  return 'offerDraft';
}

export default function OffersPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Me | null>(null);
  const [rows, setRows] = useState<OfferRow[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [kind, setKind] = useState('');
  const [q, setQ] = useState('');
  const [city, setCity] = useState('');
  const onLang = useCallback((l: Lang) => setLang(l), []);

  const load = useCallback(
    async (token: string) => {
      setLoading(true);
      setError(null);
      try {
        const params = new URLSearchParams();
        if (kind) params.set('kind', kind);
        if (q.trim()) params.set('q', q.trim());
        if (city.trim()) params.set('city', city.trim());
        const qs = params.toString();
        const json = await adminFetch(
          `/v1/admin/offers${qs ? `?${qs}` : ''}`,
          token,
        );
        const items = (json.items as OfferRow[] | undefined) ?? [];
        setRows(items);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed');
      } finally {
        setLoading(false);
      }
    },
    [kind, q, city],
  );

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
        if (!meCanManageOffers(m)) {
          setError('offers_denied');
          setLoading(false);
        }
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed');
        setLoading(false);
      }
    })();
  }, [router]);

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !me || !meCanManageOffers(me)) return;
    setLoading(true);
    const tmr = setTimeout(() => load(token), 420);
    return () => clearTimeout(tmr);
  }, [kind, q, city, me, load]);

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted" style={{ color: '#e2e8f0' }}>
          {t(lang, 'loading')}
        </p>
      </div>
    );
  }

  const allowed = meCanManageOffers(me);
  const titleOf = (o: OfferRow) =>
    lang === 'ar' ? o.titleAr || o.titleEn || '—' : o.titleEn || o.titleAr || '—';
  const priceOf = (o: OfferRow) =>
    lang === 'ar' ? o.priceLabelAr || o.priceLabelEn : o.priceLabelEn || o.priceLabelAr;

  return (
    <AdminShell active="offers" me={me} onLangChange={onLang}>
      <div className="web-access-banner">{t(lang, 'webAccessNote')}</div>
      <header className="web-head">
        <div>
          <h2>{t(lang, 'offersTitle')}</h2>
          <p>{t(lang, 'offersHint')}</p>
        </div>
      </header>

      {!allowed ? (
        <div className="web-lock">
          {error === 'offers_denied' || !error
            ? t(lang, 'offersDenied')
            : error}
        </div>
      ) : (
        <>
          {error && error !== 'offers_denied' && <p className="err">{error}</p>}

          <div className="staff-toolbar">
            <label className="staff-filter">
              <span>{t(lang, 'service')}</span>
              <select value={kind} onChange={(e) => setKind(e.target.value)}>
                <option value="">{t(lang, 'offersAllKinds')}</option>
                <option value="hotels">{t(lang, 'offersHotels')}</option>
                <option value="flights">{t(lang, 'offersFlights')}</option>
                <option value="restaurants">{t(lang, 'offersRestaurants')}</option>
              </select>
            </label>
            <label className="staff-filter grow">
              <span>{t(lang, 'search')}</span>
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder={t(lang, 'offersSearchHint')}
              />
            </label>
            <label className="staff-filter grow">
              <span>{t(lang, 'offerLocation')}</span>
              <input
                value={city}
                onChange={(e) => setCity(e.target.value)}
                placeholder={t(lang, 'offersCityHint')}
              />
            </label>
            {(q || city || kind) && (
              <button
                type="button"
                className="btn-ghost"
                onClick={() => {
                  setKind('');
                  setQ('');
                  setCity('');
                }}
              >
                {t(lang, 'clearFilters')}
              </button>
            )}
          </div>

          <div className="web-card staff-card">
            {loading ? (
              <p className="web-note">{t(lang, 'loading')}</p>
            ) : rows.length === 0 ? (
              <p className="web-note">
                {q || city || kind ? t(lang, 'offersNoMatch') : t(lang, 'offersEmpty')}
              </p>
            ) : (
              <>
                <p className="muted" style={{ marginBottom: 12 }}>
                  {rows.length}{' '}
                  {lang === 'ar'
                    ? rows.length === 1
                      ? 'نتيجة'
                      : 'نتائج'
                    : `${rows.length} ${t(lang, 'resultsCount')}`}
                </p>
                <table className="web-table staff-table">
                  <thead>
                    <tr>
                      <th>{t(lang, 'offers')}</th>
                      <th>{t(lang, 'service')}</th>
                      <th>{t(lang, 'offerLocation')}</th>
                      <th>{t(lang, 'status')}</th>
                      <th>{t(lang, 'assignee')}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((o) => {
                      const cover = coverUrl(o);
                      const kindLabel =
                        o.kind === 'flights'
                          ? t(lang, 'offersFlights')
                          : o.kind === 'restaurants'
                            ? t(lang, 'offersRestaurants')
                            : t(lang, 'offersHotels');
                      return (
                        <tr key={o.id}>
                          <td>
                            <div className="offer-row-title">
                              {cover ? (
                                // eslint-disable-next-line @next/next/no-img-element
                                <img
                                  src={cover}
                                  alt=""
                                  className="offer-thumb"
                                  width={48}
                                  height={48}
                                />
                              ) : (
                                <div className="offer-thumb placeholder">
                                  {o.kind === 'flights'
                                    ? '✈'
                                    : o.kind === 'restaurants'
                                      ? '🍽'
                                      : '🏨'}
                                </div>
                              )}
                              <div>
                                <strong>{titleOf(o)}</strong>
                                {priceOf(o) && (
                                  <span className="muted block">{priceOf(o)}</span>
                                )}
                              </div>
                            </div>
                          </td>
                          <td>{kindLabel}</td>
                          <td>{o.locationLabel || t(lang, 'none')}</td>
                          <td>
                            <span className={`role-chip ${o.isPublished ? 'super' : 'emp'}`}>
                              {t(lang, statusKey(o))}
                            </span>
                          </td>
                          <td>{o.createdByName || t(lang, 'none')}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </>
            )}
          </div>
        </>
      )}
    </AdminShell>
  );
}
