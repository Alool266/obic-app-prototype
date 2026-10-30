'use client';
// Made by Dr Ali — Professional staff desk: avatars, known branches, editable profiles.

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch, adminUploadFile, mediaUrl } from '@/lib/api';
import { OBIC_BRANCH_OPTIONS, OBIC_BRANCHES, OBIC_DESK_TITLES } from '@/lib/branches';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type StaffRow = {
  id: string;
  name?: string;
  email?: string | null;
  phone?: string | null;
  role?: string;
  staffTitle?: string | null;
  branchLabel?: string | null;
  avatarUrl?: string | null;
  opsAccess?: boolean;
  offersAccess?: boolean;
};

function initials(name?: string) {
  const n = (name || '?').trim();
  return n ? n.charAt(0).toUpperCase() : '?';
}

function StaffAvatar({
  name,
  avatarUrl,
  size = 40,
}: {
  name?: string;
  avatarUrl?: string | null;
  size?: number;
}) {
  const src = mediaUrl(avatarUrl);
  return (
    <div
      className="staff-avatar"
      style={{ width: size, height: size, fontSize: size * 0.4 }}
    >
      {src ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={src} alt="" />
      ) : (
        <span>{initials(name)}</span>
      )}
    </div>
  );
}

export default function StaffPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [rows, setRows] = useState<StaffRow[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [branchFilter, setBranchFilter] = useState<string>('all');
  const [q, setQ] = useState('');
  const [edit, setEdit] = useState<StaffRow | null>(null);
  const [formName, setFormName] = useState('');
  const [formPhone, setFormPhone] = useState('');
  const [formTitle, setFormTitle] = useState('');
  const [formBranch, setFormBranch] = useState('');
  const [formAvatar, setFormAvatar] = useState('');
  const [formPassword, setFormPassword] = useState('');
  const [formOpsAccess, setFormOpsAccess] = useState(false);
  const [formOffersAccess, setFormOffersAccess] = useState(false);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [showAdd, setShowAdd] = useState(false);
  const [addName, setAddName] = useState('');
  const [addEmail, setAddEmail] = useState('');
  const [addPhone, setAddPhone] = useState('');
  const [addPassword, setAddPassword] = useState('');
  const [addTitle, setAddTitle] = useState('');
  const [addBranch, setAddBranch] = useState('');
  const [adding, setAdding] = useState(false);
  const onLang = useCallback((l: Lang) => setLang(l), []);

  async function load(token: string) {
    const m = await adminFetch('/v1/admin/me', token);
    setMe(m);
    if (m.isSuperAdmin === true) {
      const r = await adminFetch('/v1/admin/staff', token);
      setRows(Array.isArray(r) ? r : []);
      setError(null);
    } else {
      setRows([]);
      setError(null);
    }
  }

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    load(token).catch((e) => {
      setError(e instanceof Error ? e.message : 'Failed');
    });
  }, [router]);

  const filtered = useMemo(() => {
    const query = q.trim().toLowerCase();
    return rows.filter((u) => {
      if (branchFilter !== 'all' && (u.branchLabel || '') !== branchFilter) {
        return false;
      }
      if (!query) return true;
      const hay = [u.name, u.email, u.phone, u.staffTitle, u.branchLabel, u.role]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      return hay.includes(query);
    });
  }, [rows, branchFilter, q]);

  function openEdit(u: StaffRow) {
    setEdit(u);
    setFormName(u.name || '');
    setFormPhone(u.phone || '');
    setFormTitle(u.staffTitle || '');
    setFormBranch(u.branchLabel || '');
    setFormAvatar(u.avatarUrl || '');
    setFormPassword('');
    setFormOpsAccess(
      u.role === 'SuperAdmin' ? true : u.opsAccess === true,
    );
    setFormOffersAccess(
      u.role === 'SuperAdmin' ? true : u.offersAccess === true,
    );
  }

  async function onPickPhoto(file: File | null) {
    if (!file || !edit) return;
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setUploading(true);
    setError(null);
    try {
      const url = await adminUploadFile(token, file);
      setFormAvatar(url);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Upload failed');
    } finally {
      setUploading(false);
    }
  }

  async function saveEdit() {
    if (!edit) return;
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    let totpCode: string | undefined;
    if (me?.totpStepUpRequired === true) {
      const code = promptTotpStepUp(t(lang, 'totpStepUpHint'));
      if (code == null) return;
      if (!code) {
        setError(t(lang, 'totpStepUpInvalid'));
        return;
      }
      totpCode = code;
    }
    setSaving(true);
    setError(null);
    try {
      const body: Record<string, string | boolean> = {
        name: formName.trim(),
        phone: formPhone.trim(),
        staffTitle: formTitle.trim(),
        branchLabel: formBranch.trim(),
        avatarUrl: formAvatar.trim(),
      };
      if (edit.role === 'Employee') {
        body.opsAccess = formOpsAccess;
        body.offersAccess = formOffersAccess;
      }
      if (formPassword.trim().length >= 8) {
        body.newPassword = formPassword.trim();
      }
      await adminFetch(`/v1/admin/staff/${edit.id}`, token, {
        method: 'PATCH',
        body: JSON.stringify(body),
        totpCode,
      });
      setEdit(null);
      await load(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function changeRole(userId: string, role: 'Employee' | 'SuperAdmin') {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    let totpCode: string | undefined;
    if (me?.totpStepUpRequired === true) {
      const code = promptTotpStepUp(t(lang, 'totpStepUpHint'));
      if (code == null) return;
      if (!code) {
        setError(t(lang, 'totpStepUpInvalid'));
        return;
      }
      totpCode = code;
    }
    setBusyId(userId);
    try {
      await adminFetch(`/v1/admin/staff/${userId}/role`, token, {
        method: 'PATCH',
        body: JSON.stringify({ role }),
        totpCode,
      });
      await load(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    } finally {
      setBusyId(null);
    }
  }

  async function createStaff() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    if (!addName.trim() || addPassword.trim().length < 8) {
      setError(t(lang, 'addStaffPassword'));
      return;
    }
    if (!addEmail.trim() && !addPhone.trim()) {
      setError(t(lang, 'addStaffHint'));
      return;
    }
    let totpCode: string | undefined;
    if (me?.totpStepUpRequired === true) {
      const code = promptTotpStepUp(t(lang, 'totpStepUpHint'));
      if (code == null) return;
      if (!code) {
        setError(t(lang, 'totpStepUpInvalid'));
        return;
      }
      totpCode = code;
    }
    setAdding(true);
    setError(null);
    try {
      await adminFetch('/v1/admin/staff', token, {
        method: 'POST',
        body: JSON.stringify({
          name: addName.trim(),
          password: addPassword.trim(),
          email: addEmail.trim() || null,
          phone: addPhone.trim() || null,
          staffTitle: addTitle.trim() || null,
          branchLabel: addBranch.trim() || null,
        }),
        totpCode,
      });
      setShowAdd(false);
      setAddName('');
      setAddEmail('');
      setAddPhone('');
      setAddPassword('');
      setAddTitle('');
      setAddBranch('');
      await load(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    } finally {
      setAdding(false);
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

  const isSa = me.isSuperAdmin === true;

  return (
    <AdminShell active="staff" me={me} onLangChange={onLang}>
      <header className="web-head staff-head">
        <div>
          <h2>{t(lang, 'staffMgmt')}</h2>
          <p>{t(lang, 'designate')}</p>
        </div>
        {isSa && (
          <div className="staff-summary" style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
            <span>
              {filtered.length} / {rows.length}
            </span>
            <button
              type="button"
              className="btn-primary sm"
              onClick={() => setShowAdd((v) => !v)}
            >
              {t(lang, 'addStaff')}
            </button>
          </div>
        )}
      </header>

      {!isSa ? (
        <div className="web-lock">{t(lang, 'empCannot')}</div>
      ) : (
        <>
          <div className="sign-banner">{t(lang, 'signBanner')}</div>
          <p className="muted staff-note">{t(lang, 'tempDeskNote')}</p>
          <p className="muted staff-note">{t(lang, 'addStaffHint')}</p>
          {error && <p className="err">{error}</p>}

          {showAdd ? (
            <div className="web-card" style={{ marginBottom: 16 }}>
              <h3 style={{ marginTop: 0 }}>{t(lang, 'addStaff')}</h3>
              <div className="staff-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
                <label className="staff-filter grow">
                  <span>{t(lang, 'addStaffName')}</span>
                  <input
                    value={addName}
                    onChange={(e) => setAddName(e.target.value)}
                  />
                </label>
                <label className="staff-filter grow">
                  <span>{t(lang, 'addStaffEmail')}</span>
                  <input
                    value={addEmail}
                    onChange={(e) => setAddEmail(e.target.value)}
                  />
                </label>
                <label className="staff-filter grow">
                  <span>{t(lang, 'addStaffPhone')}</span>
                  <input
                    value={addPhone}
                    onChange={(e) => setAddPhone(e.target.value)}
                  />
                </label>
                <label className="staff-filter grow">
                  <span>{t(lang, 'addStaffPassword')}</span>
                  <input
                    type="password"
                    value={addPassword}
                    onChange={(e) => setAddPassword(e.target.value)}
                  />
                </label>
                <label className="staff-filter grow">
                  <span>{t(lang, 'deskTitle')}</span>
                  <select
                    value={addTitle}
                    onChange={(e) => setAddTitle(e.target.value)}
                  >
                    <option value="">{t(lang, 'none')}</option>
                    {OBIC_DESK_TITLES.map((title) => (
                      <option key={title} value={title}>
                        {title}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="staff-filter">
                  <span>{t(lang, 'branch')}</span>
                  <select
                    value={addBranch}
                    onChange={(e) => setAddBranch(e.target.value)}
                  >
                    <option value="">{t(lang, 'none')}</option>
                    {OBIC_BRANCH_OPTIONS.map((b) => (
                      <option key={b} value={b}>
                        {b}
                      </option>
                    ))}
                  </select>
                </label>
              </div>
              <div style={{ marginTop: 12, display: 'flex', gap: 8 }}>
                <button
                  type="button"
                  className="btn-primary sm"
                  disabled={adding}
                  onClick={() => void createStaff()}
                >
                  {adding ? t(lang, 'saving') : t(lang, 'addStaffCreate')}
                </button>
                <button
                  type="button"
                  className="btn-ghost sm"
                  onClick={() => setShowAdd(false)}
                >
                  {t(lang, 'cancel')}
                </button>
              </div>
            </div>
          ) : null}

          <div className="staff-toolbar">
            <label className="staff-filter">
              <span>{t(lang, 'branch')}</span>
              <select
                value={branchFilter}
                onChange={(e) => setBranchFilter(e.target.value)}
              >
                <option value="all">{t(lang, 'allBranches')}</option>
                {OBIC_BRANCHES.map((b) => (
                  <option key={b} value={b}>
                    {b}
                  </option>
                ))}
                <option value="All branches">All branches</option>
                <option value="HQ (temp)">HQ (temp)</option>
              </select>
            </label>
            <label className="staff-filter grow">
              <span>{t(lang, 'search')}</span>
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder={t(lang, 'searchStaffHint')}
              />
            </label>
          </div>

          <div className="web-card staff-card">
            <table className="web-table staff-table">
              <thead>
                <tr>
                  <th>{t(lang, 'staff')}</th>
                  <th>{t(lang, 'deskTitle')}</th>
                  <th>{t(lang, 'branch')}</th>
                  <th>{t(lang, 'email')}</th>
                  <th>{t(lang, 'role')}</th>
                  <th>{t(lang, 'ops')}</th>
                  <th>{t(lang, 'offers')}</th>
                  <th>{t(lang, 'actions')}</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((u) => {
                  const isSelf = u.id === me.id;
                  const isSuper = u.role === 'SuperAdmin';
                  const opsOn = isSuper || u.opsAccess === true;
                  const offersOn = isSuper || u.offersAccess === true;
                  return (
                    <tr key={u.id}>
                      <td>
                        <div className="staff-person">
                          <StaffAvatar name={u.name} avatarUrl={u.avatarUrl} />
                          <div>
                            <div className="staff-name">{u.name || t(lang, 'none')}</div>
                            <div className="staff-sub">
                              {u.phone || t(lang, 'none')}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td>{u.staffTitle || t(lang, 'none')}</td>
                      <td>
                        <span className="branch-pill">
                          {u.branchLabel || t(lang, 'none')}
                        </span>
                      </td>
                      <td className="mono">{u.email || t(lang, 'none')}</td>
                      <td>
                        <span className={`role-chip ${isSuper ? 'super' : 'emp'}`}>
                          {isSuper ? t(lang, 'superAdmin') : t(lang, 'employee')}
                        </span>
                      </td>
                      <td>
                        <span className={`role-chip ${opsOn ? 'super' : 'emp'}`}>
                          {opsOn ? 'ON' : 'OFF'}
                        </span>
                      </td>
                      <td>
                        <span className={`role-chip ${offersOn ? 'super' : 'emp'}`}>
                          {offersOn ? 'ON' : 'OFF'}
                        </span>
                      </td>
                      <td>
                        <div className="staff-actions">
                          <button
                            type="button"
                            className="mini-btn primary"
                            onClick={() => openEdit(u)}
                          >
                            {t(lang, 'editProfile')}
                          </button>
                          {!isSelf &&
                            (isSuper ? (
                              <button
                                type="button"
                                className="mini-btn"
                                disabled={busyId === u.id}
                                onClick={() => changeRole(u.id, 'Employee')}
                              >
                                {t(lang, 'demote')}
                              </button>
                            ) : (
                              <button
                                type="button"
                                className="mini-btn"
                                disabled={busyId === u.id}
                                onClick={() => changeRole(u.id, 'SuperAdmin')}
                              >
                                {t(lang, 'promote')}
                              </button>
                            ))}
                        </div>
                      </td>
                    </tr>
                  );
                })}
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan={8} className="muted" style={{ textAlign: 'center' }}>
                      {t(lang, 'noStaffMatch')}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {edit && (
            <div className="staff-modal-backdrop" onClick={() => setEdit(null)}>
              <div
                className="staff-modal"
                onClick={(e) => e.stopPropagation()}
                role="dialog"
                aria-modal="true"
              >
                <div className="staff-modal-head">
                  <StaffAvatar
                    name={formName || edit.name}
                    avatarUrl={formAvatar || edit.avatarUrl}
                    size={56}
                  />
                  <div>
                    <h3>{t(lang, 'editProfile')}</h3>
                    <p className="muted mono">{edit.email}</p>
                  </div>
                  <button
                    type="button"
                    className="mini-btn"
                    onClick={() => setEdit(null)}
                  >
                    ✕
                  </button>
                </div>

                <div className="staff-modal-grid">
                  <label className="field">
                    <span>{t(lang, 'photo')}</span>
                    <input
                      type="file"
                      accept="image/*"
                      disabled={uploading}
                      onChange={(e) =>
                        void onPickPhoto(e.target.files?.[0] ?? null)
                      }
                    />
                    {uploading && (
                      <span className="muted">{t(lang, 'uploading')}</span>
                    )}
                  </label>
                  <label className="field">
                    <span>{t(lang, 'name')}</span>
                    <input
                      value={formName}
                      onChange={(e) => setFormName(e.target.value)}
                    />
                  </label>
                  <label className="field">
                    <span>{t(lang, 'phone')}</span>
                    <input
                      value={formPhone}
                      onChange={(e) => setFormPhone(e.target.value)}
                    />
                  </label>
                  <label className="field">
                    <span>{t(lang, 'deskTitle')}</span>
                    <select
                      value={formTitle}
                      onChange={(e) => setFormTitle(e.target.value)}
                    >
                      <option value="">{t(lang, 'none')}</option>
                      {OBIC_DESK_TITLES.map((d) => (
                        <option key={d} value={d}>
                          {d}
                        </option>
                      ))}
                      {formTitle &&
                        !(OBIC_DESK_TITLES as readonly string[]).includes(
                          formTitle,
                        ) && (
                          <option value={formTitle}>{formTitle}</option>
                        )}
                    </select>
                  </label>
                  <label className="field">
                    <span>{t(lang, 'branch')}</span>
                    <select
                      value={formBranch}
                      onChange={(e) => setFormBranch(e.target.value)}
                    >
                      <option value="">{t(lang, 'none')}</option>
                      {OBIC_BRANCH_OPTIONS.map((b) => (
                        <option key={b} value={b}>
                          {b}
                        </option>
                      ))}
                      {formBranch &&
                        !(OBIC_BRANCH_OPTIONS as readonly string[]).includes(
                          formBranch as (typeof OBIC_BRANCH_OPTIONS)[number],
                        ) && (
                          <option value={formBranch}>{formBranch}</option>
                        )}
                    </select>
                  </label>
                  <label className="field">
                    <span>{t(lang, 'newPasswordOptional')}</span>
                    <input
                      type="password"
                      autoComplete="new-password"
                      value={formPassword}
                      onChange={(e) => setFormPassword(e.target.value)}
                      placeholder="••••••••"
                    />
                  </label>
                  {edit.role === 'Employee' ? (
                    <>
                      <label className="field field-check">
                        <input
                          type="checkbox"
                          checked={formOpsAccess}
                          onChange={(e) => setFormOpsAccess(e.target.checked)}
                        />
                        <div>
                          <span>{t(lang, 'allowInternalOps')}</span>
                          <small>{t(lang, 'allowInternalOpsHint')}</small>
                        </div>
                      </label>
                      <label className="field field-check">
                        <input
                          type="checkbox"
                          checked={formOffersAccess}
                          onChange={(e) =>
                            setFormOffersAccess(e.target.checked)
                          }
                        />
                        <div>
                          <span>{t(lang, 'allowOffers')}</span>
                          <small>{t(lang, 'allowOffersHint')}</small>
                        </div>
                      </label>
                    </>
                  ) : edit.role === 'SuperAdmin' ? (
                    <p className="muted" style={{ gridColumn: '1 / -1' }}>
                      {t(lang, 'opsAlwaysOn')} {t(lang, 'offersAlwaysOn')}
                    </p>
                  ) : null}
                </div>

                <div className="staff-modal-foot">
                  <button
                    type="button"
                    className="mini-btn primary"
                    disabled={saving}
                    onClick={() => void saveEdit()}
                  >
                    {saving ? t(lang, 'saving') : t(lang, 'save')}
                  </button>
                  <button
                    type="button"
                    className="mini-btn"
                    onClick={() => setEdit(null)}
                  >
                    {t(lang, 'cancel')}
                  </button>
                </div>
              </div>
            </div>
          )}
        </>
      )}
    </AdminShell>
  );
}
