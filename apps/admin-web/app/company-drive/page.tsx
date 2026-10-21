'use client';
// Made by Dr Ali — Company drive. Files stay behind staff login and are not a public link.

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/AdminShell';
import { adminDownload, adminFetch, adminPostForm } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';
import { promptTotpStepUp } from '@/lib/totp-stepup';

type Folder = { id: string; name: string; active: boolean; fileCount: number };
type DriveFile = {
  id: string;
  name: string;
  size: number;
  mime: string;
  active: boolean;
  uploaderName: string | null;
  createdAt: string;
};
type Board = { folders: Folder[] };
type Detail = { folder: { id: string; name: string; active: boolean }; files: DriveFile[] };

function canReview(me: Record<string, unknown> | null): boolean {
  if (!me) return false;
  if (me.isSuperAdmin === true || me.role === 'SuperAdmin') return true;
  if (me.canOpenOps === true) return true;
  return me.role === 'Employee' && me.opsAccess === true;
}

function formatSize(size: number): string {
  if (size >= 1024 * 1024) return `${(size / (1024 * 1024)).toFixed(1)} MB`;
  if (size >= 1024) return `${Math.max(1, Math.round(size / 1024))} KB`;
  return `${size} B`;
}

export default function CompanyDrivePage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<Record<string, unknown> | null>(null);
  const [board, setBoard] = useState<Board | null>(null);
  const [detail, setDetail] = useState<Detail | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [active, setActive] = useState(true);
  const [upload, setUpload] = useState<File | null>(null);
  const [uploadKey, setUploadKey] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const onLang = useCallback((next: Lang) => setLang(next), []);
  const isSuper = me?.isSuperAdmin === true || me?.role === 'SuperAdmin';

  const load = useCallback(async (token: string) => {
    setBoard((await adminFetch('/v1/admin/company-drive', token)) as Board);
  }, []);

  const openFolder = useCallback(async (token: string, folderId: string) => {
    setDetail((await adminFetch(`/v1/admin/company-drive/folders/${folderId}`, token)) as Detail);
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
        if (row.role !== 'Employee' && row.role !== 'SuperAdmin' && row.isSuperAdmin !== true) {
          router.replace('/dashboard');
          return;
        }
        if (!canReview(row)) return;
        return load(token);
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

  function clearForm() {
    setEditingId(null);
    setName('');
    setActive(true);
  }

  async function saveFolder() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !name.trim()) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(
        editingId ? `/v1/admin/company-drive/folders/${editingId}` : '/v1/admin/company-drive/folders',
        token,
        {
          method: editingId ? 'PATCH' : 'POST',
          body: JSON.stringify({ name: name.trim(), active }),
          totpCode: code,
        },
      );
      setNotice(t(lang, 'companyDriveSaved'));
      clearForm();
      await load(token);
      if (detail) await openFolder(token, detail.folder.id);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function uploadFile() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !detail || !upload) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      const form = new FormData();
      form.append('file', upload);
      await adminPostForm(`/v1/admin/company-drive/folders/${detail.folder.id}/files`, token, form, code);
      setNotice(t(lang, 'companyDriveUploaded'));
      setUpload(null);
      setUploadKey((value) => value + 1);
      await load(token);
      await openFolder(token, detail.folder.id);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function pauseFile(file: DriveFile) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token || !detail) return;
    const code = totpCode();
    if (code === null) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await adminFetch(`/v1/admin/company-drive/files/${file.id}`, token, {
        method: 'PATCH',
        body: JSON.stringify({ active: !file.active }),
        totpCode: code,
      });
      await openFolder(token, detail.folder.id);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setSaving(false);
    }
  }

  async function download(file: DriveFile) {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setError(null);
    try {
      const blob = await adminDownload(`/v1/admin/company-drive/files/${file.id}`, token);
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = file.name;
      link.click();
      URL.revokeObjectURL(url);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed');
    }
  }

  if (!me) {
    return (
      <div className="login-stage">
        <p className="muted">{t(lang, 'loading')}</p>
      </div>
    );
  }

  const folders = board?.folders ?? [];
  const files = detail?.files ?? [];

  return (
    <AdminShell active="companyDrive" me={me} onLangChange={onLang}>
      <div className="web-head">
        <div>
          <h1>{t(lang, 'companyDriveTitle')}</h1>
          <p className="muted staff-note">{t(lang, 'companyDriveHint')}</p>
        </div>
      </div>
      {error ? <p className="err">{error}</p> : null}
      {notice ? <p className="muted staff-note">{notice}</p> : null}
      {!canReview(me) ? <p className="muted">{t(lang, 'companyDriveDenied')}</p> : null}

      {isSuper && canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          <h2 style={{ marginBottom: 12 }}>{editingId ? t(lang, 'companyDriveSave') : t(lang, 'companyDriveNew')}</h2>
          <label className="staff-filter grow">
            {t(lang, 'companyDriveName')}
            <input value={name} maxLength={40} onChange={(event) => setName(event.target.value)} />
          </label>
          <label style={{ display: 'block', marginTop: 12 }}>
            <input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} />{' '}
            {t(lang, 'companyDriveActive')}
          </label>
          <div style={{ marginTop: 12 }}>
            <button type="button" className="btn-primary sm" disabled={saving} onClick={saveFolder}>
              {saving ? t(lang, 'saving') : t(lang, 'companyDriveSave')}
            </button>{' '}
            {editingId ? (
              <button type="button" onClick={clearForm}>
                {t(lang, 'companyDriveNew')}
              </button>
            ) : null}
          </div>
        </div>
      ) : null}

      {canReview(me) ? (
        <div className="web-card" style={{ marginBottom: 16 }}>
          {folders.length === 0 ? <p className="muted">{t(lang, 'companyDriveNone')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyDriveName')}</th>
                <th>{t(lang, 'companyDriveFiles')}</th>
                <th />
                <th />
              </tr>
            </thead>
            <tbody>
              {folders.map((folder) => (
                <tr key={folder.id}>
                  <td>{folder.name}</td>
                  <td>{folder.fileCount}</td>
                  <td>{folder.active ? t(lang, 'companyDriveActive') : t(lang, 'companyDrivePaused')}</td>
                  <td>
                    <button
                      type="button"
                      onClick={() => {
                        const token = sessionStorage.getItem(TOKEN_KEY);
                        if (!token) return;
                        openFolder(token, folder.id).catch((err) =>
                          setError(err instanceof Error ? err.message : 'Failed'),
                        );
                      }}
                    >
                      {t(lang, 'companyDriveFiles')}
                    </button>{' '}
                    {isSuper ? (
                      <button
                        type="button"
                        onClick={() => {
                          setEditingId(folder.id);
                          setName(folder.name);
                          setActive(folder.active);
                        }}
                      >
                        {t(lang, 'companyDriveSave')}
                      </button>
                    ) : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}

      {detail && canReview(me) ? (
        <div className="web-card">
          <h2 style={{ marginBottom: 12 }}>
            {detail.folder.name}{' '}
            {detail.folder.active ? '' : `(${t(lang, 'companyDrivePaused')})`}
          </h2>
          {isSuper ? (
            <div style={{ marginBottom: 12 }}>
              <input
                key={uploadKey}
                type="file"
                onChange={(event) => setUpload(event.target.files?.[0] ?? null)}
              />{' '}
              <button type="button" className="btn-primary sm" disabled={saving || !upload} onClick={uploadFile}>
                {t(lang, 'companyDriveUpload')}
              </button>
            </div>
          ) : null}
          {files.length === 0 ? <p className="muted">{t(lang, 'companyDriveEmpty')}</p> : null}
          <table className="web-table">
            <thead>
              <tr>
                <th>{t(lang, 'companyDriveFiles')}</th>
                <th>{t(lang, 'companyDriveSize')}</th>
                <th />
                <th />
              </tr>
            </thead>
            <tbody>
              {files.map((file) => (
                <tr key={file.id}>
                  <td>
                    {file.name}
                    {file.uploaderName ? ` · ${file.uploaderName}` : ''}
                  </td>
                  <td>{formatSize(file.size)}</td>
                  <td>{file.active ? t(lang, 'companyDriveActive') : t(lang, 'companyDrivePaused')}</td>
                  <td>
                    <button type="button" onClick={() => download(file)}>
                      {t(lang, 'companyDriveDownload')}
                    </button>{' '}
                    {isSuper ? (
                      <button type="button" disabled={saving} onClick={() => pauseFile(file)}>
                        {file.active ? t(lang, 'companyDrivePaused') : t(lang, 'companyDriveActive')}
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
