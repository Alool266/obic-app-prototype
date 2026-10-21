'use client';
// Made by Dr Ali — Non-VIP company-registration review queue (boss W1).
// Staff approve / request correction / block documents (Green-Yellow-Red),
// assign the responsible employee, and move the 10-state workflow.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';

type RegStatus =
  | 'DRAFT'
  | 'SUBMITTED'
  | 'PENDING_DOCUMENTS'
  | 'UNDER_REVIEW'
  | 'NEEDS_CUSTOMER_ACTION'
  | 'APPROVED'
  | 'REJECTED'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'CANCELLED';

type AppSummary = {
  id: string;
  trackingId: string;
  contractId: string | null;
  city: string;
  nationality: string | null;
  activity: string;
  eligibilityOutcome: string;
  status: RegStatus;
  assignedEmployeeId: string | null;
  updatedAt: string;
};

type RegDoc = {
  id: string;
  docType: string;
  label: string;
  required: boolean;
  status: string;
  color: string;
  fileUrl: string | null;
  version: number;
  reviewNote: string | null;
};

type RegEvent = {
  id: string;
  action: string;
  actorType: string;
  fromStatus: string | null;
  toStatus: string | null;
  field: string | null;
  note: string | null;
  delayParty: string | null;
  createdAt: string;
};

type Comparison = {
  field: string;
  extracted: string | null;
  typed: string | null;
  saved: string | null;
  confidence: number | null;
  status: string;
  savedMismatch: boolean;
};

type Extraction = {
  id: string;
  applicationId: string;
  trackingId: string | null;
  city: string | null;
  docType: string;
  docVersion: number;
  modelVersion: string;
  hasMismatch: boolean;
  status: string;
  comparisons: Comparison[];
  createdAt: string;
};

type AppDetail = AppSummary & {
  accountantTier: string | null;
  priceSnapshot: {
    currency: string;
    lines: Array<{ priceId: string; itemName: string; obicFeeCents: number }>;
    totals: { totalCents: number };
  } | null;
  documents: RegDoc[];
  events: RegEvent[];
};

const COPY = {
  ar: {
    hint: 'قائمة مراجعة تسجيل الشركات (غير VIP) — راجع المستندات: أخضر مقبول، أصفر بانتظار/ناقص، أحمر محظور. طلب التصحيح يتطلب تحديد الحقل والسبب.',
    denied: 'للموظفين فقط.',
    status: 'الحالة',
    all: 'كل الحالات',
    none: 'لا طلبات بعد',
    saved: 'تم الحفظ',
    tracking: 'رقم التتبع',
    city: 'المدينة',
    activity: 'النشاط',
    eligibility: 'الأهلية',
    documents: 'المستندات',
    timeline: 'الخط الزمني',
    assign: 'تعيين الموظف المسؤول',
    assignPrompt: 'معرف الموظف (UUID)',
    nextStep: 'الخطوة التالية',
    approve: 'قبول',
    correction: 'طلب تصحيح',
    block: 'حظر',
    correctionPrompt: 'ما الذي يجب تصحيحه بالضبط؟ (الحقل + السبب)',
    view: 'فتح',
    total: 'الإجمالي',
    required: 'إلزامي',
    open: 'فتح الملف',
    ocrQueue: 'قراءات الجواز بانتظار قرار موظف',
    ocrHint: 'الذكاء الاصطناعي يقرأ فقط ولا يعدّل بيانات العميل أبداً. قارن: المستند مقابل ما كتبه العميل مقابل المحفوظ، ثم أكّد أو ارفض بسبب واضح.',
    ocrEmpty: 'لا قراءات بانتظار القرار',
    extracted: 'من المستند',
    typed: 'كتبه العميل',
    savedCol: 'المحفوظ',
    confirm: 'تأكيد القراءة',
    reject: 'رفض وطلب تصحيح',
    rejectPrompt: 'ما الذي يجب على العميل تصحيحه بالضبط؟ (الحقل + السبب)',
    mismatch: 'يوجد اختلاف',
  },
  en: {
    hint: 'Company-registration review queue (Non-VIP) — Green approved, Yellow pending/missing, Red blocked. A correction request must name the field and the reason.',
    denied: 'Staff only.',
    status: 'Status',
    all: 'All statuses',
    none: 'No applications yet',
    saved: 'Saved',
    tracking: 'Tracking ID',
    city: 'City',
    activity: 'Activity',
    eligibility: 'Eligibility',
    documents: 'Documents',
    timeline: 'Timeline',
    assign: 'Assign responsible employee',
    assignPrompt: 'Employee user ID (UUID)',
    nextStep: 'Next step',
    approve: 'Approve',
    correction: 'Request correction',
    block: 'Block',
    correctionPrompt: 'Exactly what must be fixed? (field + reason)',
    view: 'Open',
    total: 'Total',
    required: 'required',
    open: 'Open file',
    ocrQueue: 'Passport readings awaiting a staff decision',
    ocrHint: 'AI only reads — it never edits customer data. Compare document vs typed vs saved, then confirm or reject with an exact reason.',
    ocrEmpty: 'No readings waiting',
    extracted: 'Document',
    typed: 'Customer typed',
    savedCol: 'Saved',
    confirm: 'Confirm reading',
    reject: 'Reject & request correction',
    rejectPrompt: 'Exactly what must the customer fix? (field + reason)',
    mismatch: 'Difference found',
  },
  zh: {
    hint: '公司注册审核队列（非VIP）— 绿色已通过，黄色待处理/缺失，红色已阻止。要求更正必须注明字段和原因。',
    denied: '仅限员工。',
    status: '状态',
    all: '全部状态',
    none: '暂无申请',
    saved: '已保存',
    tracking: '跟踪编号',
    city: '城市',
    activity: '业务活动',
    eligibility: '资格',
    documents: '文件',
    timeline: '时间线',
    assign: '指派负责员工',
    assignPrompt: '员工用户ID (UUID)',
    nextStep: '下一步',
    approve: '通过',
    correction: '要求更正',
    block: '阻止',
    correctionPrompt: '具体需要修改什么？（字段+原因）',
    view: '打开',
    total: '总计',
    required: '必填',
    open: '打开文件',
    ocrQueue: '等待员工决定的护照读取',
    ocrHint: 'AI只读取，绝不修改客户数据。对比文件、客户填写和已保存信息，然后确认或注明原因拒绝。',
    ocrEmpty: '暂无待处理读取',
    extracted: '文件',
    typed: '客户填写',
    savedCol: '已保存',
    confirm: '确认读取',
    reject: '拒绝并要求更正',
    rejectPrompt: '客户具体需要修改什么？（字段+原因）',
    mismatch: '发现差异',
  },
  fr: {
    hint: "File de revue des enregistrements d'entreprises (non-VIP) — Vert approuvé, Jaune en attente/manquant, Rouge bloqué. Une demande de correction doit nommer le champ et la raison.",
    denied: 'Personnel uniquement.',
    status: 'Statut',
    all: 'Tous les statuts',
    none: 'Aucune demande pour le moment',
    saved: 'Enregistré',
    tracking: 'N° de suivi',
    city: 'Ville',
    activity: 'Activité',
    eligibility: 'Éligibilité',
    documents: 'Documents',
    timeline: 'Chronologie',
    assign: 'Attribuer l’employé responsable',
    assignPrompt: 'ID utilisateur de l’employé (UUID)',
    nextStep: 'Étape suivante',
    approve: 'Approuver',
    correction: 'Demander une correction',
    block: 'Bloquer',
    correctionPrompt: 'Que faut-il corriger exactement ? (champ + raison)',
    view: 'Ouvrir',
    total: 'Total',
    required: 'obligatoire',
    open: 'Ouvrir le fichier',
    ocrQueue: 'Lectures de passeport en attente de décision',
    ocrHint: 'L’IA lit uniquement — elle ne modifie jamais les données client. Comparez document / saisi / enregistré, puis confirmez ou rejetez avec une raison précise.',
    ocrEmpty: 'Aucune lecture en attente',
    extracted: 'Document',
    typed: 'Saisi par le client',
    savedCol: 'Enregistré',
    confirm: 'Confirmer la lecture',
    reject: 'Rejeter et demander une correction',
    rejectPrompt: 'Que doit corriger le client exactement ? (champ + raison)',
    mismatch: 'Différence détectée',
  },
} as const;

function nextStatuses(status: RegStatus): RegStatus[] {
  switch (status) {
    case 'SUBMITTED':
      return ['PENDING_DOCUMENTS', 'UNDER_REVIEW', 'CANCELLED'];
    case 'PENDING_DOCUMENTS':
      return ['UNDER_REVIEW', 'NEEDS_CUSTOMER_ACTION', 'CANCELLED'];
    case 'UNDER_REVIEW':
      return ['APPROVED', 'REJECTED', 'NEEDS_CUSTOMER_ACTION', 'CANCELLED'];
    case 'NEEDS_CUSTOMER_ACTION':
      return ['UNDER_REVIEW', 'PENDING_DOCUMENTS', 'CANCELLED'];
    case 'APPROVED':
      return ['IN_PROGRESS', 'CANCELLED'];
    case 'IN_PROGRESS':
      return ['COMPLETED', 'CANCELLED'];
    case 'DRAFT':
    case 'REJECTED':
    case 'COMPLETED':
    case 'CANCELLED':
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

function colorStyle(color: string): React.CSSProperties {
  switch (color) {
    case 'Green':
      return { background: '#e3f4e5', color: '#14632a' };
    case 'Red':
      return { background: '#fbe3e3', color: '#8f1d1d' };
    default:
      return { background: '#fdf3d7', color: '#7a5b00' };
  }
}

export default function RegistrationPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [rows, setRows] = useState<AppSummary[]>([]);
  const [ocrRows, setOcrRows] = useState<Extraction[]>([]);
  const [detail, setDetail] = useState<AppDetail | null>(null);
  const [statusFilter, setStatusFilter] = useState('all');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const c = COPY[lang];
  const isStaff =
    me?.role === 'Employee' || me?.role === 'SuperAdmin' || me?.isSuperAdmin === true;

  const load = useCallback(async (token: string, status: string) => {
    const qs = status === 'all' ? '' : `?status=${encodeURIComponent(status)}`;
    const board = (await adminFetch(`/v1/admin/registration/applications${qs}`, token)) as {
      rows: AppSummary[];
    };
    setRows(board.rows);
    const queue = (await adminFetch('/v1/admin/registration/ocr-queue', token)) as {
      rows: Extraction[];
    };
    setOcrRows(queue.rows);
  }, []);

  const loadDetail = useCallback(async (token: string, id: string) => {
    setDetail(
      (await adminFetch(`/v1/admin/registration/applications/${id}`, token)) as AppDetail,
    );
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
        return load(token, 'all');
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed'));
  }, [load, router]);

  async function refresh(id?: string) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    await load(token, statusFilter);
    if (id) await loadDetail(token, id);
  }

  async function run(fn: () => Promise<void>) {
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await fn();
      setNotice(c.saved);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function transition(status: RegStatus) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !detail) return;
    await run(async () => {
      await adminFetch(`/v1/admin/registration/applications/${detail.id}/transition`, token, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      });
      await refresh(detail.id);
    });
  }

  async function review(doc: RegDoc, decision: 'approve' | 'request_correction' | 'block') {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !detail) return;
    let note: string | undefined;
    if (decision !== 'approve') {
      const entered = window.prompt(c.correctionPrompt);
      if (!entered?.trim()) return;
      note = entered.trim();
    }
    await run(async () => {
      await adminFetch(
        `/v1/admin/registration/applications/${detail.id}/documents/${doc.id}/review`,
        token,
        { method: 'POST', body: JSON.stringify({ decision, note }) },
      );
      await refresh(detail.id);
    });
  }

  async function reviewExtraction(row: Extraction, decision: 'confirm' | 'reject') {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    let note: string | undefined;
    if (decision === 'reject') {
      const entered = window.prompt(c.rejectPrompt);
      if (!entered?.trim()) return;
      note = entered.trim();
    }
    await run(async () => {
      await adminFetch(`/v1/admin/registration/extractions/${row.id}/review`, token, {
        method: 'POST',
        body: JSON.stringify({ decision, note }),
      });
      await refresh(detail?.id);
    });
  }

  async function assign() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !detail) return;
    const entered = window.prompt(c.assignPrompt, detail.assignedEmployeeId ?? '');
    if (!entered?.trim()) return;
    await run(async () => {
      await adminFetch(`/v1/admin/registration/applications/${detail.id}/assign`, token, {
        method: 'POST',
        body: JSON.stringify({ employeeId: entered.trim() }),
      });
      await refresh(detail.id);
    });
  }

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted">{error || '…'}</p>
      </div>
    );
  }

  return (
    <AdminShell active="registration" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h1>{t(lang, 'registrationNav')}</h1>
          <p className="muted staff-note">{c.hint}</p>
        </div>
      </header>
      {error && <p className="err">{error}</p>}
      {notice && <p className="muted staff-note">{notice}</p>}
      {!isStaff ? <p className="muted">{c.denied}</p> : null}

      {isStaff ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12, marginBottom: 12 }}>
            <label className="staff-filter">
              {c.status}
              <select
                value={statusFilter}
                onChange={(e) => {
                  setStatusFilter(e.target.value);
                  const token = sessionStorage.getItem(TOKEN_KEY);
                  if (token) void load(token, e.target.value);
                }}
              >
                <option value="all">{c.all}</option>
                {(
                  [
                    'DRAFT',
                    'SUBMITTED',
                    'PENDING_DOCUMENTS',
                    'UNDER_REVIEW',
                    'NEEDS_CUSTOMER_ACTION',
                    'APPROVED',
                    'REJECTED',
                    'IN_PROGRESS',
                    'COMPLETED',
                    'CANCELLED',
                  ] as RegStatus[]
                ).map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </label>
          </div>
          {rows.length === 0 ? <p className="muted">{c.none}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{c.tracking}</th>
                <th>{c.city}</th>
                <th>{c.activity}</th>
                <th>{c.eligibility}</th>
                <th>{c.status}</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>{row.trackingId}</td>
                  <td>{row.city}</td>
                  <td>{row.activity}</td>
                  <td>{row.eligibilityOutcome}</td>
                  <td>{row.status}</td>
                  <td>
                    <button
                      type="button"
                      disabled={saving}
                      onClick={() => {
                        const token = sessionStorage.getItem(TOKEN_KEY);
                        if (token) void loadDetail(token, row.id);
                      }}
                    >
                      {c.view}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}

      {isStaff ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 4 }}>{c.ocrQueue}</h2>
          <p className="muted staff-note" style={{ marginBottom: 12 }}>{c.ocrHint}</p>
          {ocrRows.length === 0 ? <p className="muted">{c.ocrEmpty}</p> : null}
          {ocrRows.map((row) => (
            <div key={row.id} style={{ marginBottom: 16 }}>
              <p className="staff-note">
                {row.trackingId ?? row.applicationId} · {row.city ?? ''} · {row.docType} v{row.docVersion} · {row.modelVersion}
                {row.hasMismatch ? ` · ${c.mismatch}` : ''}
              </p>
              <table className="web-table">
                <thead>
                  <tr>
                    <th />
                    <th>{c.extracted}</th>
                    <th>{c.typed}</th>
                    <th>{c.savedCol}</th>
                    <th>{c.status}</th>
                  </tr>
                </thead>
                <tbody>
                  {row.comparisons.map((cmp) => (
                    <tr key={cmp.field}>
                      <td>{cmp.field}</td>
                      <td>{cmp.extracted ?? '—'}{cmp.confidence != null ? ` (${Math.round(cmp.confidence * 100)}%)` : ''}</td>
                      <td>{cmp.typed ?? '—'}</td>
                      <td>{cmp.saved ?? '—'}</td>
                      <td>{cmp.status}{cmp.savedMismatch ? ' · saved ≠ document' : ''}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div style={{ marginTop: 8 }}>
                <button type="button" disabled={saving} onClick={() => reviewExtraction(row, 'confirm')} style={{ marginInlineEnd: 6 }}>
                  {c.confirm}
                </button>
                <button type="button" disabled={saving} onClick={() => reviewExtraction(row, 'reject')}>
                  {c.reject}
                </button>
              </div>
            </div>
          ))}
        </div>
      ) : null}

      {isStaff && detail ? (
        <div className="web-card">
          <h2 style={{ marginBottom: 8 }}>
            {detail.trackingId} · {detail.city} · {detail.status}
          </h2>
          <p className="muted staff-note">
            {c.eligibility}: {detail.eligibilityOutcome}
            {detail.contractId ? ` · ${detail.contractId}` : ''}
            {detail.priceSnapshot
              ? ` · ${c.total}: ${yuan(detail.priceSnapshot.totals.totalCents)}`
              : ''}
          </p>
          <div style={{ marginBottom: 12 }}>
            <button type="button" disabled={saving} onClick={assign} style={{ marginInlineEnd: 6 }}>
              {c.assign}
            </button>
            {nextStatuses(detail.status).map((next) => (
              <button
                key={next}
                type="button"
                disabled={saving}
                onClick={() => transition(next)}
                style={{ marginInlineEnd: 6 }}
              >
                → {next}
              </button>
            ))}
          </div>

          <h3 style={{ marginBottom: 8 }}>{c.documents}</h3>
          <table className="web-table">
            <tbody>
              {detail.documents.map((doc) => (
                <tr key={doc.id}>
                  <td>
                    {doc.label}
                    {doc.required ? ` (${c.required})` : ''} · v{doc.version}
                  </td>
                  <td>
                    <span style={{ padding: '2px 8px', borderRadius: 10, ...colorStyle(doc.color) }}>
                      {doc.color} — {doc.status}
                    </span>
                  </td>
                  <td>
                    {doc.fileUrl ? (
                      <a href={doc.fileUrl} target="_blank" rel="noreferrer">
                        {c.open}
                      </a>
                    ) : (
                      '—'
                    )}
                  </td>
                  <td>{doc.reviewNote ?? ''}</td>
                  <td>
                    {doc.status !== 'missing' ? (
                      <>
                        <button type="button" disabled={saving} onClick={() => review(doc, 'approve')} style={{ marginInlineEnd: 6 }}>
                          {c.approve}
                        </button>
                        <button type="button" disabled={saving} onClick={() => review(doc, 'request_correction')} style={{ marginInlineEnd: 6 }}>
                          {c.correction}
                        </button>
                        <button type="button" disabled={saving} onClick={() => review(doc, 'block')}>
                          {c.block}
                        </button>
                      </>
                    ) : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <h3 style={{ margin: '16px 0 8px' }}>{c.timeline}</h3>
          <table className="web-table">
            <tbody>
              {detail.events.map((ev) => (
                <tr key={ev.id}>
                  <td>{new Date(ev.createdAt).toLocaleString()}</td>
                  <td>{ev.action}</td>
                  <td>{ev.actorType}</td>
                  <td>
                    {ev.fromStatus ?? ''} → {ev.toStatus ?? ''}
                  </td>
                  <td>{ev.note ?? ''}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </AdminShell>
  );
}
