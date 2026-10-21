'use client';
// Made by Dr Ali — VIP desk (boss M06): timed consultations + trip requests.
// Staff record external payment references (no in-app payment yet), assign
// the responsible employee, and create the official group after payment.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';

type Trip = {
  id: string;
  trackingId: string;
  userId: string;
  purpose: string;
  cities: string[];
  days: number;
  people: number;
  status: string;
  quotation: { totals?: { totalCents: number }; version?: number } | null;
  paidReference: string | null;
  groupConversationId: string | null;
  assignedEmployeeId: string | null;
};

type Session = {
  id: string;
  userId: string;
  minutes: number;
  status: string;
  paidReference: string | null;
  remainingSeconds: number;
};

const COPY = {
  ar: {
    hint: 'مكتب VIP — الاستشارات المؤقتة بالدولار (١٠/٢٠/٣٠/٦٠ دقيقة، توقف تلقائي)، ورحلات VIP برسوم تنسيق حسب الأيام. سجّل مرجع الدفع الخارجي، ثم أنشئ المجموعة الرسمية بعد قبول العميل والدفع.',
    denied: 'للموظفين فقط.',
    trips: 'رحلات VIP',
    sessions: 'الاستشارات المؤقتة',
    none: 'لا شيء بعد',
    saved: 'تم الحفظ',
    markPaid: 'تسجيل دفع',
    paidPrompt: 'مرجع الدفع الخارجي (رقم التحويل/الإيصال)',
    assign: 'تعيين موظف',
    assignPrompt: 'معرف الموظف المسؤول (UUID)',
    createGroup: 'إنشاء المجموعة الرسمية',
    groupPrompt: 'معرفات أعضاء الطاقم مفصولة بفواصل (UUID) — العميل يُضاف تلقائياً',
    next: 'التالي',
    tracking: 'التتبع',
    purpose: 'الغرض',
    days: 'أيام',
    total: 'الإجمالي',
    minutes: 'دقيقة',
    remaining: 'المتبقي',
  },
  en: {
    hint: 'VIP desk — timed consultations in USD (10/20/30/60 min, hard stop) and VIP trips with per-day coordination fees. Record the external payment reference, then create the official group after acceptance + payment.',
    denied: 'Staff only.',
    trips: 'VIP trips',
    sessions: 'Timed consultations',
    none: 'Nothing yet',
    saved: 'Saved',
    markPaid: 'Mark paid',
    paidPrompt: 'External payment reference (transfer/receipt no.)',
    assign: 'Assign employee',
    assignPrompt: 'Responsible employee user ID (UUID)',
    createGroup: 'Create official group',
    groupPrompt: 'Staff member UUIDs, comma-separated — the customer is added automatically',
    next: 'Next',
    tracking: 'Tracking',
    purpose: 'Purpose',
    days: 'days',
    total: 'Total',
    minutes: 'min',
    remaining: 'left',
  },
  zh: {
    hint: 'VIP工作台——美元计时咨询（10/20/30/60分钟，到时自动结束）和按天数收费的VIP行程。记录外部付款凭证后，在客户接受并付款后创建官方群组。',
    denied: '仅限员工。',
    trips: 'VIP行程',
    sessions: '计时咨询',
    none: '暂无',
    saved: '已保存',
    markPaid: '记录付款',
    paidPrompt: '外部付款凭证（转账/收据编号）',
    assign: '指派员工',
    assignPrompt: '负责员工的用户ID (UUID)',
    createGroup: '创建官方群组',
    groupPrompt: '员工UUID，逗号分隔——客户自动加入',
    next: '下一步',
    tracking: '跟踪编号',
    purpose: '目的',
    days: '天',
    total: '总计',
    minutes: '分钟',
    remaining: '剩余',
  },
  fr: {
    hint: "Bureau VIP — consultations limitées en USD (10/20/30/60 min, arrêt strict) et voyages VIP avec frais de coordination par durée. Enregistrez la référence de paiement externe, puis créez le groupe officiel après acceptation + paiement.",
    denied: 'Personnel uniquement.',
    trips: 'Voyages VIP',
    sessions: 'Consultations limitées',
    none: 'Rien pour le moment',
    saved: 'Enregistré',
    markPaid: 'Marquer payé',
    paidPrompt: 'Référence du paiement externe (n° de transfert/reçu)',
    assign: 'Attribuer un employé',
    assignPrompt: 'ID utilisateur de l’employé responsable (UUID)',
    createGroup: 'Créer le groupe officiel',
    groupPrompt: 'UUID du personnel, séparés par des virgules — le client est ajouté automatiquement',
    next: 'Suivant',
    tracking: 'Suivi',
    purpose: 'Objet',
    days: 'jours',
    total: 'Total',
    minutes: 'min',
    remaining: 'restant',
  },
} as const;

function nextTripStatuses(status: string): string[] {
  switch (status) {
    case 'GROUP_CREATED':
      return ['IN_PROGRESS', 'CANCELLED'];
    case 'IN_PROGRESS':
      return ['COMPLETED', 'CANCELLED'];
    case 'DRAFT':
    case 'QUOTED':
    case 'ACCEPTED':
      return ['CANCELLED'];
    default:
      return [];
  }
}

export default function VipPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [trips, setTrips] = useState<Trip[]>([]);
  const [sessions, setSessions] = useState<Session[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const c = COPY[lang];
  const isStaff =
    me?.role === 'Employee' || me?.role === 'SuperAdmin' || me?.isSuperAdmin === true;

  const load = useCallback(async (token: string) => {
    const tripBoard = (await adminFetch('/v1/admin/vip/trips', token)) as { rows: Trip[] };
    setTrips(tripBoard.rows);
    const sessionBoard = (await adminFetch('/v1/admin/vip/consultations', token)) as {
      rows: Session[];
    };
    setSessions(sessionBoard.rows);
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
        return load(token);
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed'));
  }, [load, router]);

  async function run(fn: (token: string) => Promise<void>) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await fn(token);
      setNotice(c.saved);
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

  return (
    <AdminShell active="vip" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'vipNav')}</h1>
          <p className="muted staff-note">{c.hint}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!isStaff ? <p className="muted">{c.denied}</p> : null}

      {isStaff ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{c.trips}</h2>
          {trips.length === 0 ? <p className="muted">{c.none}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{c.tracking}</th>
                <th>{c.purpose}</th>
                <th>{c.days}</th>
                <th>{c.total}</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {trips.map((trip) => (
                <tr key={trip.id}>
                  <td>{trip.trackingId}</td>
                  <td>{trip.purpose} · {trip.cities.join(', ')}</td>
                  <td>{trip.days}</td>
                  <td>
                    {trip.quotation?.totals
                      ? `¥${(trip.quotation.totals.totalCents / 100).toLocaleString()}`
                      : '—'}
                  </td>
                  <td>{trip.status}{trip.paidReference ? ` · ${trip.paidReference}` : ''}</td>
                  <td>
                    {trip.status === 'ACCEPTED' && !trip.paidReference ? (
                      <button
                        type="button"
                        disabled={saving}
                        style={{ marginInlineEnd: 6 }}
                        onClick={() => {
                          const ref = window.prompt(c.paidPrompt);
                          if (!ref?.trim()) return;
                          void run((token) =>
                            adminFetch(`/v1/admin/vip/trips/${trip.id}/mark-paid`, token, {
                              method: 'POST',
                              body: JSON.stringify({ reference: ref.trim() }),
                            }).then(() => undefined),
                          );
                        }}
                      >
                        {c.markPaid}
                      </button>
                    ) : null}
                    <button
                      type="button"
                      disabled={saving}
                      style={{ marginInlineEnd: 6 }}
                      onClick={() => {
                        const id = window.prompt(c.assignPrompt, trip.assignedEmployeeId ?? '');
                        if (!id?.trim()) return;
                        void run((token) =>
                          adminFetch(`/v1/admin/vip/trips/${trip.id}/assign`, token, {
                            method: 'POST',
                            body: JSON.stringify({ employeeId: id.trim() }),
                          }).then(() => undefined),
                        );
                      }}
                    >
                      {c.assign}
                    </button>
                    {trip.status === 'ACCEPTED' && trip.paidReference && !trip.groupConversationId ? (
                      <button
                        type="button"
                        disabled={saving}
                        style={{ marginInlineEnd: 6 }}
                        onClick={() => {
                          const raw = window.prompt(c.groupPrompt);
                          if (!raw?.trim()) return;
                          const memberUserIds = raw.split(',').map((x) => x.trim()).filter(Boolean);
                          void run((token) =>
                            adminFetch(`/v1/admin/vip/trips/${trip.id}/create-group`, token, {
                              method: 'POST',
                              body: JSON.stringify({ memberUserIds }),
                            }).then(() => undefined),
                          );
                        }}
                      >
                        {c.createGroup}
                      </button>
                    ) : null}
                    {nextTripStatuses(trip.status).map((next) => (
                      <button
                        key={next}
                        type="button"
                        disabled={saving}
                        style={{ marginInlineEnd: 6 }}
                        onClick={() =>
                          run((token) =>
                            adminFetch(`/v1/admin/vip/trips/${trip.id}/transition`, token, {
                              method: 'PATCH',
                              body: JSON.stringify({ status: next }),
                            }).then(() => undefined),
                          )
                        }
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

      {isStaff ? (
        <div className="web-card">
          <h2 style={{ marginBottom: 12 }}>{c.sessions}</h2>
          {sessions.length === 0 ? <p className="muted">{c.none}</p> : null}
          <table className="web-table">
            <tbody>
              {sessions.map((session) => (
                <tr key={session.id}>
                  <td>{session.minutes} {c.minutes}</td>
                  <td>{session.status}</td>
                  <td>{session.remainingSeconds > 0 ? `${Math.ceil(session.remainingSeconds / 60)} ${c.minutes} ${c.remaining}` : '—'}</td>
                  <td>{session.paidReference ?? ''}</td>
                  <td>
                    {session.status === 'PENDING_PAYMENT' ? (
                      <button
                        type="button"
                        disabled={saving}
                        onClick={() => {
                          const ref = window.prompt(c.paidPrompt);
                          if (!ref?.trim()) return;
                          void run((token) =>
                            adminFetch(`/v1/admin/vip/consultations/${session.id}/mark-paid`, token, {
                              method: 'POST',
                              body: JSON.stringify({ reference: ref.trim() }),
                            }).then(() => undefined),
                          );
                        }}
                      >
                        {c.markPaid}
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
