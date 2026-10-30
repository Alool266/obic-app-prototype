'use client';
// Made by Dr Ali — Chat oversight: list + WeChat dates + Join (Support/order/group).

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';

type Participant = {
  userId?: string;
  name?: string | null;
  role?: string | null;
};

type Thread = {
  id: string;
  kind?: string;
  title?: string | null;
  participants?: Participant[];
  lastMessage?: { body?: string; senderId?: string; createdAt?: string } | null;
  aiAutoReplyEnabled?: boolean;
  iAmMember?: boolean;
  joinable?: boolean;
  friendDm?: boolean;
  updatedAt?: string;
};

type Msg = {
  id?: string;
  body?: string;
  senderId?: string;
  senderName?: string | null;
  createdAt?: string;
  isAi?: boolean;
};

function staffNames(parts: Participant[] | undefined) {
  return (parts || [])
    .filter((p) => p.role === 'Employee' || p.role === 'SuperAdmin')
    .map((p) => p.name || '—')
    .join(' · ');
}

function customerNames(parts: Participant[] | undefined) {
  return (parts || [])
    .filter((p) => p.role === 'Customer')
    .map((p) => p.name || '—')
    .join(' · ');
}

function kindLabel(lang: Lang, kind?: string) {
  if (kind === 'order') return lang === 'ar' ? 'طلب' : lang === 'zh' ? '订单' : 'Order';
  if (kind === 'group') return lang === 'ar' ? 'مجموعة' : lang === 'zh' ? '群聊' : 'Group';
  if (kind === 'support') return lang === 'ar' ? 'دعم' : lang === 'zh' ? '客服' : 'Support';
  return lang === 'ar' ? 'خاص' : lang === 'zh' ? '私聊' : 'Direct';
}

function calendarDay(d: Date) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
}

function daySeparatorLabel(iso: string | undefined, lang: Lang): string | null {
  if (!iso) return null;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  const now = new Date();
  const today = calendarDay(now);
  const day = calendarDay(d);
  const yesterday = today - 86400000;
  if (day === today) {
    return lang === 'ar' ? 'اليوم' : lang === 'zh' ? '今天' : 'Today';
  }
  if (day === yesterday) {
    return lang === 'ar' ? 'أمس' : lang === 'zh' ? '昨天' : 'Yesterday';
  }
  try {
    return new Intl.DateTimeFormat(
      lang === 'ar' ? 'ar' : lang === 'zh' ? 'zh-CN' : 'en',
      { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' },
    ).format(d);
  } catch {
    return d.toLocaleDateString();
  }
}

function timeLabel(iso?: string) {
  if (!iso) return '';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '';
  return d.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
}

export default function OversightPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [threads, setThreads] = useState<Thread[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [active, setActive] = useState<Thread | null>(null);
  const [messages, setMessages] = useState<Msg[]>([]);
  const [threadAi, setThreadAi] = useState(true);
  const [aiBusy, setAiBusy] = useState(false);
  const [joinBusy, setJoinBusy] = useState(false);
  const [kind, setKind] = useState('');
  const [q, setQ] = useState('');
  const [includeFriends, setIncludeFriends] = useState(false);
  const [meta, setMeta] = useState<{
    joinable?: boolean;
    friendDm?: boolean;
    iAmMember?: boolean;
    participants?: Participant[];
  }>({});
  const onLang = useCallback((l: Lang) => setLang(l), []);

  async function loadThreads(token: string) {
    const params = new URLSearchParams();
    if (kind) params.set('kind', kind);
    if (q.trim()) params.set('q', q.trim());
    if (includeFriends) params.set('includeFriends', '1');
    const qs = params.toString();
    const rows = await adminFetch(
      `/v1/admin/oversight/chats${qs ? `?${qs}` : ''}`,
      token,
    );
    setThreads(Array.isArray(rows) ? rows : []);
  }

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    (async () => {
      try {
        const m = await adminFetch('/v1/admin/me', token);
        setMe(m);
        if (m.isSuperAdmin !== true) {
          setError('SuperAdmin only');
          return;
        }
        await loadThreads(token);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed');
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [router]);

  async function refreshList() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setError(null);
    try {
      await loadThreads(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  async function openTranscript(thread: Thread) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    try {
      const data = await adminFetch(
        `/v1/admin/oversight/chats/${thread.id}/messages`,
        token,
      );
      setActive(thread);
      const msgs = Array.isArray(data.messages) ? data.messages : [];
      setMessages(msgs as Msg[]);
      setThreadAi(data.aiAutoReplyEnabled !== false);
      setMeta({
        joinable: data.joinable === true,
        friendDm: data.friendDm === true,
        iAmMember: data.iAmMember === true,
        participants: Array.isArray(data.participants)
          ? data.participants
          : thread.participants,
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  async function joinConversation() {
    if (!active) return;
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setJoinBusy(true);
    setError(null);
    try {
      const res = await adminFetch(
        `/v1/admin/oversight/chats/${active.id}/join`,
        token,
        { method: 'POST', body: '{}' },
      );
      setMeta((m) => ({
        ...m,
        iAmMember: true,
        joinable: true,
        participants: Array.isArray(res.participants)
          ? res.participants
          : m.participants,
      }));
      setActive((a) =>
        a
          ? {
              ...a,
              iAmMember: true,
              participants: Array.isArray(res.participants)
                ? res.participants
                : a.participants,
            }
          : a,
      );
      await loadThreads(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : t(lang, 'requestFailed'));
    } finally {
      setJoinBusy(false);
    }
  }

  async function toggleThreadAi() {
    if (!active) return;
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setAiBusy(true);
    setError(null);
    try {
      const next = !threadAi;
      const res = await adminFetch(
        `/v1/chat/threads/${active.id}/ai-auto-reply`,
        token,
        {
          method: 'PATCH',
          body: JSON.stringify({ enabled: next }),
        },
      );
      setThreadAi(res.aiAutoReplyEnabled === true);
    } catch (e) {
      setError(e instanceof Error ? e.message : t(lang, 'requestFailed'));
    } finally {
      setAiBusy(false);
    }
  }

  const timeline = useMemo(() => {
    const items: Array<{ type: 'day'; label: string } | { type: 'msg'; m: Msg }> =
      [];
    let prevDay: number | null = null;
    for (const m of messages) {
      const label = daySeparatorLabel(m.createdAt, lang);
      if (m.createdAt) {
        const day = calendarDay(new Date(m.createdAt));
        if (label && prevDay !== day) {
          items.push({ type: 'day', label });
          prevDay = day;
        }
      }
      items.push({ type: 'msg', m });
    }
    return items;
  }, [messages, lang]);

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted" style={{ color: '#e2e8f0' }}>
          {t(lang, 'loading')}
        </p>
      </div>
    );
  }

  const parts = meta.participants || active?.participants;
  const canJoin =
    active &&
    meta.joinable !== false &&
    (active.joinable !== false) &&
    !meta.friendDm &&
    !meta.iAmMember &&
    (active.kind === 'support' ||
      active.kind === 'order' ||
      active.kind === 'group');

  return (
    <AdminShell active="oversight" me={me} onLangChange={onLang}>
      <header className="web-head">
        <div>
          <h2>{t(lang, 'oversightTitle')}</h2>
          <p>{t(lang, 'oversightDesc')}</p>
        </div>
      </header>
      <p className="web-note">{t(lang, 'auditNote')}</p>
      {error && <p className="err">{error}</p>}

      <div className="web-card" style={{ marginBottom: 12 }}>
        <div
          style={{
            display: 'flex',
            flexWrap: 'wrap',
            gap: 8,
            alignItems: 'center',
          }}
        >
          <select
            className="web-input"
            style={{ maxWidth: 140 }}
            value={kind}
            onChange={(e) => setKind(e.target.value)}
          >
            <option value="">{lang === 'ar' ? 'كل الأنواع' : 'All kinds'}</option>
            <option value="support">Support</option>
            <option value="order">Order</option>
            <option value="group">Group</option>
            <option value="direct">Direct</option>
          </select>
          <input
            className="web-input"
            style={{ flex: 1, minWidth: 160 }}
            placeholder={t(lang, 'searchStaffHint')}
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
          <label
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 6,
              fontSize: 13,
              color: 'var(--muted)',
            }}
          >
            <input
              type="checkbox"
              checked={includeFriends}
              onChange={(e) => setIncludeFriends(e.target.checked)}
            />
            {lang === 'ar'
              ? 'محادثات الأصدقاء (قراءة فقط)'
              : lang === 'zh'
                ? '好友私聊（只读）'
                : 'Friend DMs (read-only)'}
          </label>
          <button
            type="button"
            className="mini-btn primary"
            onClick={() => void refreshList()}
          >
            {t(lang, 'search')}
          </button>
        </div>
      </div>

      <div className="oversight-layout">
        <div className="web-card oversight-list">
          {threads.length === 0 ? (
            <p className="web-note">{t(lang, 'noThreads')}</p>
          ) : (
            <ul className="oversight-thread-list">
              {threads.map((c) => (
                <li key={c.id}>
                  <button
                    type="button"
                    className={
                      active?.id === c.id
                        ? 'oversight-thread on'
                        : 'oversight-thread'
                    }
                    onClick={() => void openTranscript(c)}
                  >
                    <div className="oversight-thread-top">
                      <span className="branch-pill">
                        {kindLabel(lang, c.kind)}
                      </span>
                      {c.friendDm && (
                        <span className="muted" style={{ fontSize: 11 }}>
                          RO
                        </span>
                      )}
                      {c.iAmMember && (
                        <span className="muted" style={{ fontSize: 11 }}>
                          ✓
                        </span>
                      )}
                    </div>
                    <div className="oversight-thread-title">
                      {c.title || kindLabel(lang, c.kind)}
                    </div>
                    <div className="muted" style={{ fontSize: 12 }}>
                      {customerNames(c.participants) || t(lang, 'none')}
                      {staffNames(c.participants)
                        ? ` · ${staffNames(c.participants)}`
                        : ''}
                    </div>
                    <div className="muted" style={{ fontSize: 12 }}>
                      {c.lastMessage?.body || t(lang, 'none')}
                    </div>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="web-card oversight-detail">
          {!active ? (
            <p className="web-note">
              {lang === 'ar'
                ? 'اختر محادثة لعرض السجل'
                : lang === 'zh'
                  ? '选择会话查看记录'
                  : 'Select a thread to open the transcript'}
            </p>
          ) : (
            <>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  gap: 12,
                  alignItems: 'flex-start',
                  marginBottom: 12,
                  flexWrap: 'wrap',
                }}
              >
                <div>
                  <h3 style={{ margin: 0 }}>
                    {active.title || kindLabel(lang, active.kind)}
                  </h3>
                  <p className="muted" style={{ margin: '4px 0 0' }}>
                    {staffNames(parts)} · {customerNames(parts)}
                  </p>
                  {meta.friendDm && (
                    <p className="web-note" style={{ marginTop: 6 }}>
                      {lang === 'ar'
                        ? 'محادثة أصدقاء — قراءة فقط (لا انضمام)'
                        : lang === 'zh'
                          ? '好友私聊 — 只读（不可加入）'
                          : 'Friend DM — read-only (cannot join)'}
                    </p>
                  )}
                </div>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  {canJoin && (
                    <button
                      type="button"
                      className="mini-btn primary"
                      disabled={joinBusy}
                      onClick={() => void joinConversation()}
                    >
                      {lang === 'ar'
                        ? 'انضم للمحادثة'
                        : lang === 'zh'
                          ? '加入会话'
                          : 'Join conversation'}
                    </button>
                  )}
                  {meta.iAmMember && (
                    <span className="branch-pill">
                      {lang === 'ar'
                        ? 'مشارك'
                        : lang === 'zh'
                          ? '已加入'
                          : 'Member'}
                    </span>
                  )}
                  {(active.kind === 'support' || active.kind === 'order') && (
                    <button
                      type="button"
                      className={`mini-btn ${threadAi ? 'primary' : ''}`}
                      disabled={aiBusy}
                      onClick={() => void toggleThreadAi()}
                    >
                      {t(lang, 'aiThreadToggle')}:{' '}
                      {threadAi
                        ? t(lang, 'aiThreadOn')
                        : t(lang, 'aiThreadOff')}
                    </button>
                  )}
                  <button
                    type="button"
                    className="mini-btn"
                    onClick={() => {
                      setActive(null);
                      setMessages([]);
                      setMeta({});
                    }}
                  >
                    {t(lang, 'cancel')}
                  </button>
                </div>
              </div>
              <div className="oversight-transcript">
                {timeline.map((item, idx) =>
                  item.type === 'day' ? (
                    <div key={`d-${idx}`} className="oversight-day">
                      {item.label}
                    </div>
                  ) : (
                    <div
                      key={item.m.id || item.m.createdAt || idx}
                      className={`oversight-bubble${item.m.isAi ? ' ai' : ''}`}
                    >
                      <div className="oversight-who">
                        {item.m.isAi
                          ? 'OBIC AI'
                          : item.m.senderName ||
                            item.m.senderId?.slice(0, 8) ||
                            '—'}
                        {item.m.createdAt && (
                          <span className="oversight-time">
                            {timeLabel(item.m.createdAt)}
                          </span>
                        )}
                      </div>
                      <div className="oversight-body">{item.m.body || '—'}</div>
                    </div>
                  ),
                )}
                {messages.length === 0 && (
                  <p className="muted">{t(lang, 'none')}</p>
                )}
              </div>
            </>
          )}
        </div>
      </div>
    </AdminShell>
  );
}
