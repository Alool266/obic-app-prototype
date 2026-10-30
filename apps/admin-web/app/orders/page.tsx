'use client';
// Made by Dr Ali — Service request queue with structured customer forms.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, statusLabel, t } from '@/lib/i18n';
import { canUpdateOrderStatus } from '@/lib/org';
import { TOKEN_KEY } from '@/lib/session';

type Me = {
  name?: string;
  role?: string;
  email?: string;
  staffTitle?: string | null;
  branchLabel?: string | null;
  isSuperAdmin?: boolean;
  canReassignOrders?: boolean;
};

type OrderRow = Record<string, unknown>;

type StaffRow = {
  id: string;
  name?: string;
  email?: string;
  staffTitle?: string | null;
  branchLabel?: string | null;
};

type Msg = {
  id?: string;
  body?: string;
  senderName?: string | null;
  createdAt?: string;
};

type OrderChat = {
  conversationId?: string;
  title?: string | null;
};

function serviceLabel(o: OrderRow, lang: Lang): string {
  const sub =
    lang === 'ar'
      ? (o.subServiceNameAr as string | undefined)
      : (o.subServiceNameEn as string | undefined);
  if (sub) return sub;
  return String(
    o.serviceTitleEn || o.serviceTitleAr || o.serviceSlug || t(lang, 'none'),
  );
}

function formLines(o: OrderRow): string[] {
  const form = o.formData;
  if (!form || typeof form !== 'object') return [];
  return Object.entries(form as Record<string, unknown>).map(
    ([k, v]) => `${k}: ${String(v ?? '')}`,
  );
}

export default function OrdersPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Me | null>(null);
  const [orders, setOrders] = useState<OrderRow[]>([]);
  const [staff, setStaff] = useState<StaffRow[]>([]);
  const [selected, setSelected] = useState<OrderRow | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [chatOrder, setChatOrder] = useState<OrderRow | null>(null);
  const [chatMeta, setChatMeta] = useState<OrderChat | null>(null);
  const [chatMessages, setChatMessages] = useState<Msg[]>([]);
  const [chatDraft, setChatDraft] = useState('');
  const onLang = useCallback((l: Lang) => setLang(l), []);

  const load = useCallback(async (token: string) => {
    setLoading(true);
    setError(null);
    try {
      const m = await adminFetch('/v1/admin/me', token);
      const o = await adminFetch('/v1/admin/orders', token);
      setMe(m);
      setOrders(Array.isArray(o) ? o : []);
      if (m.isSuperAdmin === true || m.canReassignOrders === true) {
        const s = await adminFetch('/v1/admin/staff', token);
        const list = Array.isArray(s) ? s : [];
        setStaff(
          list.filter(
            (u: StaffRow & { role?: string }) => u.role === 'Employee',
          ),
        );
      } else {
        setStaff([]);
      }
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

  const isSa = me?.isSuperAdmin === true;
  const canReassign = isSa || me?.canReassignOrders === true;

  function canPatchStatus(order: OrderRow): boolean {
    if (!me) return false;
    return canUpdateOrderStatus(
      {
        role: me.role,
        email: me.email,
        staffTitle: me.staffTitle,
        branchLabel: me.branchLabel,
        isSuperAdmin: me.isSuperAdmin,
      },
      { preferredBranch: (order.preferredBranch as string | null) ?? null },
      { assignedToSelf: true },
    );
  }

  async function openOrderChat(order: OrderRow) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    const orderId = String(order.id);
    setBusyId(orderId);
    setError(null);
    try {
      const chat = (await adminFetch(
        `/v1/admin/orders/${orderId}/chat`,
        token,
      )) as OrderChat;
      const cid = chat?.conversationId;
      if (!cid) throw new Error('No conversation');
      const data = await adminFetch(`/v1/chat/threads/${cid}/messages`, token);
      const msgs = Array.isArray(data.messages) ? data.messages : [];
      setChatOrder(order);
      setChatMeta(chat);
      setChatMessages(msgs as Msg[]);
      setChatDraft('');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Chat failed');
    } finally {
      setBusyId(null);
    }
  }

  async function sendChatMessage() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    const cid = chatMeta?.conversationId;
    const body = chatDraft.trim();
    if (!token || !cid || !body) return;
    setBusyId(cid);
    try {
      await adminFetch(`/v1/chat/threads/${cid}/messages`, token, {
        method: 'POST',
        body: JSON.stringify({ body }),
      });
      const data = await adminFetch(`/v1/chat/threads/${cid}/messages`, token);
      const msgs = Array.isArray(data.messages) ? data.messages : [];
      setChatMessages(msgs as Msg[]);
      setChatDraft('');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Send failed');
    } finally {
      setBusyId(null);
    }
  }

  async function patchOrder(
    orderId: string,
    body: Record<string, unknown>,
  ) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    const current =
      orders.find((x) => String(x.id) === orderId) ??
      (selected && String(selected.id) === orderId ? selected : null) ??
      (chatOrder && String(chatOrder.id) === orderId ? chatOrder : null);
    if (body.status !== undefined && current && !canPatchStatus(current)) {
      setError(t(lang, 'errorOnlySecretaryCanUpdateStatus'));
      return;
    }
    setBusyId(orderId);
    try {
      await adminFetch(`/v1/admin/orders/${orderId}`, token, {
        method: 'PATCH',
        body: JSON.stringify(body),
      });
      await load(token);
      if (selected && String(selected.id) === orderId) {
        const fresh = (await adminFetch('/v1/admin/orders', token)) as OrderRow[];
        const row = Array.isArray(fresh)
          ? fresh.find((x) => String(x.id) === orderId)
          : null;
        if (row) setSelected(row);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Update failed';
      setError(
        /only the secretary can update status/i.test(msg)
          ? t(lang, 'errorOnlySecretaryCanUpdateStatus')
          : msg,
      );
    } finally {
      setBusyId(null);
    }
  }

  if (error && !me) {
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
    <AdminShell active="orders" me={me} onLangChange={onLang}>
      <div className="web-access-banner">{t(lang, 'ordersHint')}</div>
      <header className="web-head">
        <div>
          <h2>{t(lang, 'ordersNav')}</h2>
          <p>
            {isSa ? t(lang, 'ordersSaScope') : t(lang, 'ordersEmpScope')} ·{' '}
            {String(me.name || '')}
          </p>
        </div>
      </header>

      <section className="web-card" style={{ marginBottom: 16 }}>
        {loading ? (
          <p className="web-note">{t(lang, 'loading')}</p>
        ) : orders.length === 0 ? (
          <p className="web-note">{t(lang, 'noOrders')}</p>
        ) : (
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'service')}</th>
                <th>{t(lang, 'customer')}</th>
                <th>{t(lang, 'branch')}</th>
                <th>{t(lang, 'status')}</th>
                <th>{t(lang, 'assignee')}</th>
                <th>{t(lang, 'actions')}</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((o) => {
                const id = String(o.id);
                const status = String(o.status || '');
                const busy = busyId === id;
                return (
                  <tr key={id}>
                    <td>
                      <strong>{serviceLabel(o, lang)}</strong>
                      <div className="muted-mini">
                        {String(o.serviceSlug || '')}
                      </div>
                    </td>
                    <td>
                      {String(o.customerName || t(lang, 'none'))}
                      <div className="muted-mini">
                        {String(o.customerPhone || o.customerEmail || '')}
                      </div>
                    </td>
                    <td>{String(o.preferredBranch || t(lang, 'none'))}</td>
                    <td>
                      <span
                        className={`badge ${status === 'InProgress' ? 'warn' : ''}`}
                      >
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
                    <td>
                      <div className="row-actions">
                        <button
                          type="button"
                          className="btn-ghost sm"
                          disabled={busy}
                          onClick={() => void openOrderChat(o)}
                        >
                          {t(lang, 'orderChat')}
                        </button>
                        <button
                          type="button"
                          className="btn-ghost sm"
                          onClick={() => setSelected(o)}
                        >
                          {t(lang, 'viewForm')}
                        </button>
                        {(status === 'Submitted' || status === 'Assigned') &&
                          canPatchStatus(o) && (
                          <button
                            type="button"
                            className="btn-ghost sm"
                            disabled={busy}
                            onClick={() =>
                              patchOrder(id, { status: 'InProgress' })
                            }
                          >
                            {t(lang, 'startWork')}
                          </button>
                        )}
                        {status === 'InProgress' && canPatchStatus(o) && (
                          <>
                            <button
                              type="button"
                              className="btn-ghost sm"
                              disabled={busy}
                              onClick={() =>
                                patchOrder(id, { status: 'WaitingCustomer' })
                              }
                            >
                              {t(lang, 'waitCustomer')}
                            </button>
                            <button
                              type="button"
                              className="btn-ghost sm"
                              disabled={busy}
                              onClick={() =>
                                patchOrder(id, { status: 'Completed' })
                              }
                            >
                              {t(lang, 'markDone')}
                            </button>
                          </>
                        )}
                        {status === 'WaitingCustomer' && canPatchStatus(o) && (
                          <button
                            type="button"
                            className="btn-ghost sm"
                            disabled={busy}
                            onClick={() =>
                              patchOrder(id, { status: 'InProgress' })
                            }
                          >
                            {t(lang, 'resumeWork')}
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </section>

      {selected ? (
        <div className="modal-backdrop" onClick={() => setSelected(null)}>
          <div
            className="modal-card wide"
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
          >
            <header className="modal-head">
              <h3>{serviceLabel(selected, lang)}</h3>
              <button
                type="button"
                className="btn-ghost sm"
                onClick={() => setSelected(null)}
              >
                {t(lang, 'cancel')}
              </button>
            </header>
            <div className="modal-body">
              <p className="web-note">
                <strong>{t(lang, 'customer')}:</strong>{' '}
                {String(selected.customerName || t(lang, 'none'))}
                <br />
                <strong>{t(lang, 'phone')}:</strong>{' '}
                {String(selected.customerPhone || t(lang, 'none'))}
                <br />
                <strong>{t(lang, 'email')}:</strong>{' '}
                {String(selected.customerEmail || t(lang, 'none'))}
                <br />
                <strong>{t(lang, 'branch')}:</strong>{' '}
                {String(selected.preferredBranch || t(lang, 'none'))}
                <br />
                <strong>{t(lang, 'status')}:</strong>{' '}
                {statusLabel(lang, String(selected.status || ''))}
                <br />
                <strong>{t(lang, 'assignee')}:</strong>{' '}
                {String(
                  selected.assignedEmployeeName ||
                    selected.assignedEmployeeId ||
                    t(lang, 'none'),
                )}
                {selected.assignedEmployeeTitle
                  ? ` (${String(selected.assignedEmployeeTitle)})`
                  : ''}
              </p>

              {formLines(selected).length > 0 ? (
                <>
                  <h4 style={{ marginTop: 16, marginBottom: 8 }}>
                    {t(lang, 'formAnswers')}
                  </h4>
                  <ul className="form-answers">
                    {formLines(selected).map((line) => (
                      <li key={line}>{line}</li>
                    ))}
                  </ul>
                </>
              ) : null}

              {selected.notes ? (
                <>
                  <h4 style={{ marginTop: 16, marginBottom: 8 }}>
                    {t(lang, 'notesLabel')}
                  </h4>
                  <pre className="notes-pre">{String(selected.notes)}</pre>
                </>
              ) : null}

              {canReassign && staff.length > 0 ? (
                <>
                  <h4 style={{ marginTop: 16, marginBottom: 8 }}>
                    {t(lang, 'reassign')}
                  </h4>
                  <div className="staff-pick-grid">
                    {staff.map((s) => (
                      <button
                        key={s.id}
                        type="button"
                        className="btn-ghost sm"
                        disabled={busyId === String(selected.id)}
                        onClick={() =>
                          patchOrder(String(selected.id), {
                            assignedEmployeeId: s.id,
                          })
                        }
                      >
                        {s.name}
                        {s.branchLabel ? ` · ${s.branchLabel}` : ''}
                      </button>
                    ))}
                    <button
                      type="button"
                      className="btn-ghost sm"
                      disabled={busyId === String(selected.id)}
                      onClick={() =>
                        patchOrder(String(selected.id), {
                          assignedEmployeeId: null,
                        })
                      }
                    >
                      {t(lang, 'clearAssignee')}
                    </button>
                  </div>
                </>
              ) : null}

              <div style={{ marginTop: 16, display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                <button
                  type="button"
                  className="btn-primary sm"
                  disabled={busyId === String(selected.id)}
                  onClick={() => void openOrderChat(selected)}
                >
                  {t(lang, 'orderChat')}
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : null}

      {chatOrder && chatMeta?.conversationId ? (
        <div className="modal-backdrop" onClick={() => setChatOrder(null)}>
          <div
            className="modal-card wide"
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
          >
            <header className="modal-head">
              <h3>
                {t(lang, 'orderChat')} — {serviceLabel(chatOrder, lang)}
              </h3>
              <button
                type="button"
                className="btn-ghost sm"
                onClick={() => setChatOrder(null)}
              >
                {t(lang, 'cancel')}
              </button>
            </header>
            <div className="modal-body">
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 12 }}>
                <span className="badge">
                  {statusLabel(lang, String(chatOrder.status || 'Submitted'))}
                </span>
                {canPatchStatus(chatOrder) &&
                String(chatOrder.status) === 'InProgress' ? (
                  <button
                    type="button"
                    className="btn-ghost sm"
                    onClick={() =>
                      patchOrder(String(chatOrder.id), {
                        status: 'WaitingCustomer',
                      }).then(() =>
                        setChatOrder({
                          ...chatOrder,
                          status: 'WaitingCustomer',
                        }),
                      )
                    }
                  >
                    {t(lang, 'waitCustomer')}
                  </button>
                ) : null}
                {canPatchStatus(chatOrder) &&
                String(chatOrder.status) !== 'InProgress' &&
                String(chatOrder.status) !== 'Completed' ? (
                  <button
                    type="button"
                    className="btn-ghost sm"
                    onClick={() =>
                      patchOrder(String(chatOrder.id), {
                        status: 'InProgress',
                      }).then(() =>
                        setChatOrder({ ...chatOrder, status: 'InProgress' }),
                      )
                    }
                  >
                    {t(lang, 'startWork')}
                  </button>
                ) : null}
              </div>
              <div className="oversight-transcript" style={{ maxHeight: 320 }}>
                {chatMessages.map((m) => (
                  <div key={m.id || m.createdAt} className="oversight-bubble">
                    <div className="oversight-who">
                      {m.senderName || t(lang, 'none')}
                    </div>
                    <div className="oversight-body">
                      {String(m.body || '').startsWith('[[status]]')
                        ? statusLabel(
                            lang,
                            String(m.body).slice('[[status]]'.length),
                          )
                        : m.body || '—'}
                    </div>
                  </div>
                ))}
                {chatMessages.length === 0 && (
                  <p className="muted">{t(lang, 'none')}</p>
                )}
              </div>
              <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
                <input
                  className="web-input"
                  style={{ flex: 1 }}
                  value={chatDraft}
                  placeholder={t(lang, 'chatPlaceholder')}
                  onChange={(e) => setChatDraft(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') void sendChatMessage();
                  }}
                />
                <button
                  type="button"
                  className="btn-primary sm"
                  disabled={!chatDraft.trim() || busyId === chatMeta.conversationId}
                  onClick={() => void sendChatMessage()}
                >
                  {t(lang, 'chatSend')}
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </AdminShell>
  );
}
