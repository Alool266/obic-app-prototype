'use client';
// Made by Dr Ali — SuperAdmin service catalog + inner services CRUD.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';

type Me = { name?: string; role?: string; isSuperAdmin?: boolean };

type ServiceRow = {
  id: string;
  slug?: string;
  icon?: string;
  sortOrder?: number;
  nameAr?: string;
  nameEn?: string;
  nameZh?: string;
  descAr?: string;
  descEn?: string;
  descZh?: string;
  priceAr?: string;
  priceEn?: string;
  priceZh?: string;
  isActive?: boolean;
  countries?: string[] | string;
};

type SubRow = {
  uuid: string;
  id: string;
  serviceId?: string;
  icon?: string;
  sortOrder?: number;
  nameAr?: string;
  nameEn?: string;
  nameZh?: string;
  descAr?: string;
  descEn?: string;
  descZh?: string;
  priceAr?: string;
  priceEn?: string;
  priceZh?: string;
  isActive?: boolean;
  countries?: string[] | string;
};

function countriesToInput(raw?: string[] | string): string {
  if (Array.isArray(raw)) return raw.join(', ');
  return raw ?? '';
}

const emptyForm = (): ServiceRow => ({
  id: '',
  slug: '',
  icon: 'biz',
  sortOrder: 99,
  nameAr: '',
  nameEn: '',
  nameZh: '',
  descAr: '',
  descEn: '',
  descZh: '',
  priceAr: '',
  priceEn: '',
  priceZh: '',
  isActive: true,
  countries: '',
});

const emptySubForm = (serviceId: string): SubRow => ({
  uuid: '',
  id: '',
  serviceId,
  icon: 'biz',
  sortOrder: 0,
  nameAr: '',
  nameEn: '',
  nameZh: '',
  descAr: '',
  descEn: '',
  descZh: '',
  priceAr: '',
  priceEn: '',
  priceZh: '',
  isActive: true,
  countries: '',
});

export default function ServicesPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Me | null>(null);
  const [rows, setRows] = useState<ServiceRow[]>([]);
  const [selected, setSelected] = useState<ServiceRow | null>(null);
  const [form, setForm] = useState<ServiceRow>(emptyForm());
  const [subs, setSubs] = useState<SubRow[]>([]);
  const [selectedSub, setSelectedSub] = useState<SubRow | null>(null);
  const [subForm, setSubForm] = useState<SubRow | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [subsLoading, setSubsLoading] = useState(false);
  const [busy, setBusy] = useState(false);
  const [subBusy, setSubBusy] = useState(false);
  const onLang = useCallback((l: Lang) => setLang(l), []);

  const loadSubs = useCallback(async (token: string, serviceId: string) => {
    setSubsLoading(true);
    try {
      const list = await adminFetch(
        `/v1/admin/service-subs?serviceId=${serviceId}`,
        token,
      );
      setSubs(Array.isArray(list) ? list : []);
    } catch (e) {
      setSubs([]);
      setError(e instanceof Error ? e.message : 'Failed');
    } finally {
      setSubsLoading(false);
    }
  }, []);

  const load = useCallback(async (token: string) => {
    setLoading(true);
    setError(null);
    try {
      const m = await adminFetch('/v1/admin/me', token);
      if (m.isSuperAdmin !== true) {
        setError('services_denied');
        setMe(m);
        setRows([]);
        return;
      }
      const list = await adminFetch('/v1/admin/services', token);
      setMe(m);
      setRows(Array.isArray(list) ? list : []);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
      sessionStorage.removeItem(TOKEN_KEY);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    load(token);
  }, [router, load]);

  function pickTitle(row: ServiceRow | SubRow): string {
    if (lang === 'ar') return row.nameAr || ('slug' in row ? row.slug : row.id) || '';
    return row.nameEn || ('slug' in row ? row.slug : row.id) || '';
  }

  function openNew() {
    setSelected(null);
    setForm(emptyForm());
    setSubs([]);
    setSelectedSub(null);
    setSubForm(null);
  }

  function openEdit(row: ServiceRow) {
    setSelected(row);
    setForm({
      ...row,
      countries: countriesToInput(row.countries),
    });
    setSelectedSub(null);
    setSubForm(null);
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (token && row.id) loadSubs(token, row.id);
  }

  function openNewSub() {
    if (!selected?.id) return;
    setSelectedSub(null);
    setSubForm(emptySubForm(selected.id));
  }

  function openEditSub(row: SubRow) {
    setSelectedSub(row);
    setSubForm({
      ...row,
      countries: countriesToInput(row.countries),
    });
  }

  async function save() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setBusy(true);
    setError(null);
    try {
      const body = {
        slug: form.slug,
        icon: form.icon,
        sortOrder: form.sortOrder ?? 0,
        nameAr: form.nameAr,
        nameEn: form.nameEn,
        nameZh: form.nameZh,
        descAr: form.descAr,
        descEn: form.descEn,
        descZh: form.descZh,
        priceAr: form.priceAr,
        priceEn: form.priceEn,
        priceZh: form.priceZh,
        isActive: form.isActive !== false,
        countries: form.countries,
      };
      if (selected?.id) {
        await adminFetch(`/v1/admin/services/${selected.id}`, token, {
          method: 'PATCH',
          body: JSON.stringify(body),
        });
      } else {
        await adminFetch('/v1/admin/services', token, {
          method: 'POST',
          body: JSON.stringify(body),
        });
      }
      await load(token);
      setSelected(null);
      setForm(emptyForm());
      setSubs([]);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    } finally {
      setBusy(false);
    }
  }

  async function saveSub() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !subForm || !selected?.id) return;
    setSubBusy(true);
    setError(null);
    try {
      const body = {
        externalId: subForm.id,
        icon: subForm.icon,
        sortOrder: subForm.sortOrder ?? 0,
        nameAr: subForm.nameAr,
        nameEn: subForm.nameEn,
        nameZh: subForm.nameZh,
        descAr: subForm.descAr,
        descEn: subForm.descEn,
        descZh: subForm.descZh,
        priceAr: subForm.priceAr,
        priceEn: subForm.priceEn,
        priceZh: subForm.priceZh,
        isActive: subForm.isActive !== false,
        countries: subForm.countries,
      };
      if (selectedSub?.uuid) {
        await adminFetch(`/v1/admin/service-subs/${selectedSub.uuid}`, token, {
          method: 'PATCH',
          body: JSON.stringify(body),
        });
      } else {
        await adminFetch('/v1/admin/service-subs', token, {
          method: 'POST',
          body: JSON.stringify({ ...body, serviceId: selected.id }),
        });
      }
      await loadSubs(token, selected.id);
      setSelectedSub(null);
      setSubForm(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    } finally {
      setSubBusy(false);
    }
  }

  if (!me && loading) {
    return (
      <div className="web-note" style={{ padding: 24 }}>
        {t(lang, 'loading')}
      </div>
    );
  }

  return (
    <AdminShell active="services" me={me ?? {}} onLangChange={onLang}>
      <div className="web-head">
        <div>
          <h1>{t(lang, 'servicesTitle')}</h1>
          <p className="muted">{t(lang, 'servicesHint')}</p>
        </div>
        <button type="button" className="btn" onClick={openNew}>
          + {t(lang, 'servicesNew')}
        </button>
      </div>

      {error === 'services_denied' ? (
        <div className="web-note warn">{t(lang, 'servicesDenied')}</div>
      ) : null}
      {error && error !== 'services_denied' ? (
        <div className="web-note warn">{error}</div>
      ) : null}

      <div className="split-panels">
        <div className="inbox-list">
          {loading ? (
            <p className="muted">{t(lang, 'loading')}</p>
          ) : rows.length === 0 ? (
            <p className="muted">{t(lang, 'servicesEmpty')}</p>
          ) : (
            rows.map((row) => (
              <button
                key={row.id}
                type="button"
                className={`inbox-item${selected?.id === row.id ? ' on' : ''}`}
                onClick={() => openEdit(row)}
              >
                <strong>{pickTitle(row)}</strong>
                <span className="muted">
                  {row.slug} · {row.sortOrder ?? 0}
                  {row.nameZh ? ` · ${row.nameZh}` : ''}
                </span>
                <span className={`pill ${row.isActive === false ? 'dim' : 'ok'}`}>
                  {row.isActive === false ? t(lang, 'servicesInactive') : t(lang, 'servicesActive')}
                </span>
              </button>
            ))
          )}
        </div>

        <div className="detail-panel">
          <h3>{selected ? t(lang, 'servicesEdit') : t(lang, 'servicesNew')}</h3>
          <div className="form-grid">
            {(
              [
                ['slug', 'slug'],
                ['icon', 'icon'],
                ['sortOrder', 'sort'],
                ['nameAr', 'text'],
                ['nameEn', 'text'],
                ['nameZh', 'text'],
                ['descAr', 'area'],
                ['descEn', 'area'],
                ['descZh', 'area'],
                ['priceAr', 'text'],
                ['priceEn', 'text'],
                ['priceZh', 'text'],
                ['countries', 'text'],
              ] as const
            ).map(([key, kind]) => (
              <label key={key} className="field">
                <span>{key}</span>
                {kind === 'area' ? (
                  <textarea
                    rows={3}
                    value={String(form[key as keyof ServiceRow] ?? '')}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, [key]: e.target.value }))
                    }
                  />
                ) : (
                  <input
                    type={kind === 'sort' ? 'number' : 'text'}
                    value={String(form[key as keyof ServiceRow] ?? '')}
                    onChange={(e) =>
                      setForm((f) => ({
                        ...f,
                        [key]:
                          kind === 'sort'
                            ? Number(e.target.value)
                            : e.target.value,
                      }))
                    }
                  />
                )}
              </label>
            ))}
            <label className="field row">
              <input
                type="checkbox"
                checked={form.isActive !== false}
                onChange={(e) =>
                  setForm((f) => ({ ...f, isActive: e.target.checked }))
                }
              />
              <span>{t(lang, 'servicesActive')}</span>
            </label>
          </div>
          <button type="button" className="btn primary" disabled={busy} onClick={save}>
            {busy ? t(lang, 'loading') : t(lang, 'save')}
          </button>

          <hr style={{ margin: '20px 0', border: 'none', borderTop: '1px solid #e2e8f0' }} />

          <h3>{t(lang, 'subsTitle')}</h3>
          <p className="muted">{t(lang, 'subsHint')}</p>

          {!selected?.id ? (
            <p className="muted">{t(lang, 'subsPickParent')}</p>
          ) : (
            <>
              <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
                <button type="button" className="btn" onClick={openNewSub}>
                  + {t(lang, 'subsNew')}
                </button>
              </div>
              <div className="inbox-list" style={{ maxHeight: 220, marginBottom: 12 }}>
                {subsLoading ? (
                  <p className="muted">{t(lang, 'loading')}</p>
                ) : subs.length === 0 ? (
                  <p className="muted">{t(lang, 'subsEmpty')}</p>
                ) : (
                  subs.map((sub) => (
                    <button
                      key={sub.uuid}
                      type="button"
                      className={`inbox-item${selectedSub?.uuid === sub.uuid ? ' on' : ''}`}
                      onClick={() => openEditSub(sub)}
                    >
                      <strong>{pickTitle(sub)}</strong>
                      <span className="muted">
                        {sub.id} · {sub.sortOrder ?? 0}
                        {sub.nameZh ? ` · ${sub.nameZh}` : ''}
                      </span>
                    </button>
                  ))
                )}
              </div>

              {subForm ? (
                <>
                  <h4>{selectedSub ? t(lang, 'subsEdit') : t(lang, 'subsNew')}</h4>
                  <div className="form-grid">
                    {(
                      [
                        ['id', 'text'],
                        ['icon', 'text'],
                        ['sortOrder', 'sort'],
                        ['nameAr', 'text'],
                        ['nameEn', 'text'],
                        ['nameZh', 'text'],
                        ['descAr', 'area'],
                        ['descEn', 'area'],
                        ['descZh', 'area'],
                        ['priceAr', 'text'],
                        ['priceEn', 'text'],
                        ['priceZh', 'text'],
                        ['countries', 'text'],
                      ] as const
                    ).map(([key, kind]) => (
                      <label key={`sub-${key}`} className="field">
                        <span>{key}</span>
                        {kind === 'area' ? (
                          <textarea
                            rows={2}
                            value={String(subForm[key as keyof SubRow] ?? '')}
                            onChange={(e) =>
                              setSubForm((f) =>
                                f ? { ...f, [key]: e.target.value } : f,
                              )
                            }
                          />
                        ) : (
                          <input
                            type={kind === 'sort' ? 'number' : 'text'}
                            value={String(subForm[key as keyof SubRow] ?? '')}
                            onChange={(e) =>
                              setSubForm((f) =>
                                f
                                  ? {
                                      ...f,
                                      [key]:
                                        kind === 'sort'
                                          ? Number(e.target.value)
                                          : e.target.value,
                                    }
                                  : f,
                              )
                            }
                          />
                        )}
                      </label>
                    ))}
                    <label className="field row">
                      <input
                        type="checkbox"
                        checked={subForm.isActive !== false}
                        onChange={(e) =>
                          setSubForm((f) =>
                            f ? { ...f, isActive: e.target.checked } : f,
                          )
                        }
                      />
                      <span>{t(lang, 'servicesActive')}</span>
                    </label>
                  </div>
                  <button
                    type="button"
                    className="btn primary"
                    disabled={subBusy}
                    onClick={saveSub}
                  >
                    {subBusy ? t(lang, 'loading') : t(lang, 'save')}
                  </button>
                </>
              ) : null}
            </>
          )}
        </div>
      </div>
    </AdminShell>
  );
}
