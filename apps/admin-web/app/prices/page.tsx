'use client';
// Made by Dr Ali — Versioned prices (boss M02/M15). Draft → Review → Approved
// → Active → Retired. Only Active prices can be quoted in the app.

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type PriceStatus = 'Draft' | 'Review' | 'Approved' | 'Active' | 'Retired';

type PriceRow = {
  id: string;
  priceId: string;
  version: string;
  serviceKey: string;
  itemName: string;
  city: string | null;
  obicFeeCents: number;
  externalFeeCents: number;
  currency: string;
  pricingBasis: string;
  status: PriceStatus;
  effectiveFrom: string | null;
  note: string | null;
};

type Board = { rows: PriceRow[] };

const COPY = {
  ar: {
    hint: 'المشرف الأعلى فقط — الأسعار تمر: مسودة ← مراجعة ← اعتماد ← تفعيل ← إيقاف. لا يظهر للعميل إلا السعر المفعّل.',
    denied: 'المشرف الأعلى فقط.',
    newPrice: 'سعر جديد (مسودة)',
    priceId: 'معرف السعر',
    version: 'الإصدار',
    service: 'الخدمة',
    item: 'البند',
    city: 'المدينة',
    obicFee: 'رسوم OBIC (يوان)',
    externalFee: 'رسوم خارجية (يوان)',
    basis: 'أساس التسعير',
    effective: 'يسري من',
    create: 'إنشاء مسودة',
    status: 'الحالة',
    fee: 'رسوم OBIC',
    external: 'خارجي',
    action: 'الإجراء التالي',
    none: 'لا أسعار بعد',
    saved: 'تم الحفظ',
    filter: 'بحث برقم السعر أو المدينة أو البند',
    all: 'كل الحالات',
  },
  en: {
    hint: 'SuperAdmin only — prices move Draft → Review → Approved → Active → Retired. Customers only see Active prices.',
    denied: 'SuperAdmin only.',
    newPrice: 'New price (Draft)',
    priceId: 'Price ID',
    version: 'Version',
    service: 'Service',
    item: 'Item',
    city: 'City',
    obicFee: 'OBIC fee (yuan)',
    externalFee: 'External fee (yuan)',
    basis: 'Pricing basis',
    effective: 'Effective from',
    create: 'Create draft',
    status: 'Status',
    fee: 'OBIC fee',
    external: 'External',
    action: 'Next step',
    none: 'No prices yet',
    saved: 'Saved',
    filter: 'Search Price ID, city, or item',
    all: 'All statuses',
  },
  zh: {
    hint: '仅超级管理员 — 价格流程：草稿 → 审核 → 批准 → 生效 → 停用。客户只能看到生效价格。',
    denied: '仅超级管理员。',
    newPrice: '新价格（草稿）',
    priceId: '价格编号',
    version: '版本',
    service: '服务',
    item: '项目',
    city: '城市',
    obicFee: 'OBIC费用（元）',
    externalFee: '外部费用（元）',
    basis: '计价方式',
    effective: '生效日期',
    create: '创建草稿',
    status: '状态',
    fee: 'OBIC费用',
    external: '外部',
    action: '下一步',
    none: '暂无价格',
    saved: '已保存',
    filter: '搜索价格编号、城市或项目',
    all: '全部状态',
  },
  fr: {
    hint: 'Super-admin uniquement — les prix passent Brouillon → Révision → Approuvé → Actif → Retiré. Les clients ne voient que les prix Actifs.',
    denied: 'Super-admin uniquement.',
    newPrice: 'Nouveau prix (Brouillon)',
    priceId: 'ID du prix',
    version: 'Version',
    service: 'Service',
    item: 'Élément',
    city: 'Ville',
    obicFee: 'Frais OBIC (yuan)',
    externalFee: 'Frais externes (yuan)',
    basis: 'Base de tarification',
    effective: 'En vigueur dès le',
    create: 'Créer le brouillon',
    status: 'Statut',
    fee: 'Frais OBIC',
    external: 'Externe',
    action: 'Étape suivante',
    none: 'Aucun prix pour le moment',
    saved: 'Enregistré',
    filter: "Rechercher l'ID, la ville ou l'élément",
    all: 'Tous les statuts',
  },
} as const;

function nextStatuses(status: PriceStatus): PriceStatus[] {
  switch (status) {
    case 'Draft':
      return ['Review', 'Retired'];
    case 'Review':
      return ['Approved', 'Draft', 'Retired'];
    case 'Approved':
      return ['Active', 'Retired'];
    case 'Active':
      return ['Retired'];
    case 'Retired':
      return [];
    default: {
      const neverStatus: never = status;
      throw new Error(neverStatus);
    }
  }
}

function yuan(cents: number): string {
  return `¥${(cents / 100).toLocaleString('en-US', { maximumFractionDigits: 2 })}`;
}

function yuanToCents(raw: string): number | null {
  const match = /^(\d+)(?:\.(\d{1,2}))?$/.exec(raw.trim());
  if (!match) return null;
  const cents = Number(match[1]) * 100 + Number((match[2] ?? '').padEnd(2, '0'));
  return Number.isSafeInteger(cents) && cents <= 2_000_000_000 ? cents : null;
}

export default function PricesPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [filter, setFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [priceId, setPriceId] = useState('');
  const [version, setVersion] = useState('boss-2026-10-v2');
  const [serviceKey, setServiceKey] = useState('company-registration');
  const [itemName, setItemName] = useState('');
  const [city, setCity] = useState('');
  const [obicFee, setObicFee] = useState('');
  const [externalFee, setExternalFee] = useState('0');
  const [basis, setBasis] = useState('per_order');
  const [effectiveFrom, setEffectiveFrom] = useState('');
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const c = COPY[lang];
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/prices', token)) as Board);
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
        if (row.isSuperAdmin === true || row.role === 'SuperAdmin') return load(token);
        return undefined;
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

  async function createPrice() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    const obicFeeCents = yuanToCents(obicFee);
    const externalFeeCents = yuanToCents(externalFee);
    if (!token || !priceId.trim() || !itemName.trim() || obicFeeCents == null || externalFeeCents == null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch('/v1/admin/prices', token, {
        method: 'POST',
        body: JSON.stringify({
          priceId: priceId.trim().toUpperCase(),
          version: version.trim(),
          serviceKey: serviceKey.trim(),
          itemName: itemName.trim(),
          city: city.trim() || undefined,
          obicFeeCents,
          externalFeeCents,
          currency: 'CNY',
          pricingBasis: basis,
          effectiveFrom: effectiveFrom || undefined,
          sourceRef: 'Admin Web — manual entry',
        }),
      });
      setNotice(c.saved);
      setPriceId('');
      setItemName('');
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function transition(row: PriceRow, status: PriceStatus) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    const code = totpCode();
    if (code === null) return;
    let from = row.effectiveFrom ?? undefined;
    if (status === 'Active' && !from) {
      const entered = window.prompt(c.effective, new Date().toISOString().slice(0, 10));
      if (!entered) return;
      from = entered.trim();
    }
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(`/v1/admin/prices/${row.id}/transition`, token, {
        method: 'PATCH',
        body: JSON.stringify({ status, effectiveFrom: from }),
        totpCode: code,
      });
      setNotice(c.saved);
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  const rows = useMemo(() => {
    const needle = filter.trim().toLowerCase();
    return (board?.rows ?? []).filter((row) => {
      if (statusFilter !== 'all' && row.status !== statusFilter) return false;
      if (!needle) return true;
      return [row.priceId, row.city ?? '', row.itemName, row.serviceKey]
        .join(' ')
        .toLowerCase()
        .includes(needle);
    });
  }, [board, filter, statusFilter]);

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted">{error || '…'}</p>
      </div>
    );
  }

  return (
    <AdminShell active="prices" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'pricesNav')}</h1>
          <p className="muted staff-note">{c.hint}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!isSuper ? <p className="muted">{c.denied}</p> : null}

      {isSuper ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{c.newPrice}</h2>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
            <label className="staff-filter">
              {c.priceId}
              <input value={priceId} maxLength={64} placeholder="PRICE-YIW-REG" onChange={(e) => setPriceId(e.target.value)} />
            </label>
            <label className="staff-filter">
              {c.version}
              <input value={version} maxLength={32} onChange={(e) => setVersion(e.target.value)} />
            </label>
            <label className="staff-filter">
              {c.service}
              <input value={serviceKey} maxLength={80} onChange={(e) => setServiceKey(e.target.value)} />
            </label>
            <label className="staff-filter grow">
              {c.item}
              <input value={itemName} maxLength={160} onChange={(e) => setItemName(e.target.value)} />
            </label>
            <label className="staff-filter">
              {c.city}
              <input value={city} maxLength={60} onChange={(e) => setCity(e.target.value)} />
            </label>
            <label className="staff-filter">
              {c.obicFee}
              <input value={obicFee} inputMode="decimal" placeholder="500" onChange={(e) => setObicFee(e.target.value)} />
            </label>
            <label className="staff-filter">
              {c.externalFee}
              <input value={externalFee} inputMode="decimal" onChange={(e) => setExternalFee(e.target.value)} />
            </label>
            <label className="staff-filter">
              {c.basis}
              <select value={basis} onChange={(e) => setBasis(e.target.value)}>
                <option value="per_order">per_order</option>
                <option value="per_year">per_year</option>
                <option value="per_document">per_document</option>
                <option value="per_job">per_job</option>
                <option value="percentage_of_annual_rent">percentage_of_annual_rent</option>
              </select>
            </label>
            <label className="staff-filter">
              {c.effective}
              <input type="date" value={effectiveFrom} onChange={(e) => setEffectiveFrom(e.target.value)} />
            </label>
          </div>
          <div style={{ marginTop: 12 }}>
            <button type="button" className="btn-primary sm" disabled={saving} onClick={createPrice}>
              {saving ? t(lang, 'saving') : c.create}
            </button>
          </div>
        </div>
      ) : null}

      {isSuper ? (
        <div className="web-card">
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12, marginBottom: 12 }}>
            <label className="staff-filter grow">
              {c.filter}
              <input value={filter} onChange={(e) => setFilter(e.target.value)} />
            </label>
            <label className="staff-filter">
              {c.status}
              <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
                <option value="all">{c.all}</option>
                <option value="Draft">Draft</option>
                <option value="Review">Review</option>
                <option value="Approved">Approved</option>
                <option value="Active">Active</option>
                <option value="Retired">Retired</option>
              </select>
            </label>
          </div>
          {rows.length === 0 ? <p className="muted">{c.none}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{c.priceId}</th>
                <th>{c.item}</th>
                <th>{c.city}</th>
                <th>{c.fee}</th>
                <th>{c.external}</th>
                <th>{c.version}</th>
                <th>{c.status}</th>
                <th>{c.action}</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>{row.priceId}</td>
                  <td>{row.itemName}</td>
                  <td>{row.city ?? '—'}</td>
                  <td>{yuan(row.obicFeeCents)}</td>
                  <td>{yuan(row.externalFeeCents)}</td>
                  <td>{row.version}</td>
                  <td>{row.status}</td>
                  <td>
                    {nextStatuses(row.status).map((next) => (
                      <button
                        key={next}
                        type="button"
                        disabled={saving}
                        onClick={() => transition(row, next)}
                        style={{ marginInlineEnd: 6 }}
                      >
                        → {next}
                      </button>
                    ))}
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
