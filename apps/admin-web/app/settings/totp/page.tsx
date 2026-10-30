'use client';
// Made by Dr Ali — SuperAdmin TOTP enrollment (Authenticator app).

import { FormEvent, useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import QRCode from 'react-qr-code';
import { AdminShell } from '@/components/AdminShell';
import { adminFetch } from '@/lib/api';
import { Lang, t } from '@/lib/i18n';
import { TOKEN_KEY } from '@/lib/session';

type TotpStatus = { enabled: boolean; pendingEnroll: boolean; required?: boolean };
type EnrollResult = { otpauthUrl: string; secret: string };

export default function TotpSettingsPage() {
  const router = useRouter();
  const [lang, setLang] = useState<Lang>('ar');
  const [me, setMe] = useState<{
    name?: string;
    isSuperAdmin?: boolean;
    totpEnrollRequired?: boolean;
  } | null>(null);
  const [status, setStatus] = useState<TotpStatus | null>(null);
  const [enroll, setEnroll] = useState<EnrollResult | null>(null);
  const [code, setCode] = useState('');
  const [disablePassword, setDisablePassword] = useState('');
  const [disableCode, setDisableCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const onLang = useCallback((l: Lang) => setLang(l), []);

  const load = useCallback(async (token: string) => {
    const m = await adminFetch('/v1/admin/me', token);
    if (m.isSuperAdmin !== true) {
      setMe(m);
      setStatus(null);
      return;
    }
    const st = await adminFetch('/v1/admin/totp/status', token);
    setMe(m);
    setStatus(st);
  }, []);

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) {
      router.replace('/');
      return;
    }
    load(token).catch(() => router.replace('/'));
  }, [router, load]);

  async function startEnroll() {
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setBusy(true);
    setError(null);
    try {
      const res = await adminFetch('/v1/admin/totp/enroll', token, {
        method: 'POST',
        body: '{}',
      });
      setEnroll(res);
      setCode('');
    } catch (e) {
      setError(e instanceof Error ? e.message : t(lang, 'requestFailed'));
    } finally {
      setBusy(false);
    }
  }

  async function confirmEnroll(e: FormEvent) {
    e.preventDefault();
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setBusy(true);
    setError(null);
    try {
      await adminFetch('/v1/admin/totp/confirm', token, {
        method: 'POST',
        body: JSON.stringify({ code }),
      });
      setEnroll(null);
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : t(lang, 'requestFailed'));
    } finally {
      setBusy(false);
    }
  }

  async function disableTotp(e: FormEvent) {
    e.preventDefault();
    const token = sessionStorage.getItem(TOKEN_KEY);
    if (!token) return;
    setBusy(true);
    setError(null);
    try {
      await adminFetch('/v1/admin/totp/disable', token, {
        method: 'POST',
        body: JSON.stringify({ password: disablePassword, code: disableCode }),
      });
      setDisablePassword('');
      setDisableCode('');
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : t(lang, 'requestFailed'));
    } finally {
      setBusy(false);
    }
  }

  if (!me) {
    return (
      <div className="web-note" style={{ padding: 24 }}>
        {t(lang, 'loading')}
      </div>
    );
  }

  return (
    <AdminShell active="settings" me={me} onLangChange={onLang}>
      <div className="web-head">
        <div>
          <h1>{t(lang, 'totpSettingsTitle')}</h1>
          <p className="muted">{t(lang, 'totpSettingsHint')}</p>
        </div>
      </div>

      {me.isSuperAdmin !== true ? (
        <div className="web-note warn">{t(lang, 'totpDenied')}</div>
      ) : null}
      {status && !status.enabled && (status.required || me.totpEnrollRequired) ? (
        <div className="sign-banner">{t(lang, 'totpRequiredBanner')}</div>
      ) : null}
      {error ? <div className="web-note warn">{error}</div> : null}

      {status && me.isSuperAdmin ? (
        <div className="detail-panel">
          <p>
            <strong>{t(lang, 'status')}:</strong>{' '}
            {status.enabled ? t(lang, 'totpOn') : t(lang, 'totpOff')}
          </p>

          {!status.enabled && !enroll ? (
            <button type="button" className="btn primary" disabled={busy} onClick={startEnroll}>
              {t(lang, 'totpStartEnroll')}
            </button>
          ) : null}

          {enroll ? (
            <form onSubmit={confirmEnroll} className="form-grid" style={{ marginTop: 16 }}>
              <p className="muted">{t(lang, 'totpScanHint')}</p>
              <div
                style={{
                  background: '#fff',
                  padding: 16,
                  borderRadius: 12,
                  width: 'fit-content',
                  border: '1px solid #e2e8f0',
                }}
              >
                <QRCode value={enroll.otpauthUrl} size={200} />
              </div>
              <label className="field">
                <span>{t(lang, 'totpOtpauth')}</span>
                <input readOnly value={enroll.otpauthUrl} />
              </label>
              <label className="field">
                <span>{t(lang, 'totpSecret')}</span>
                <input readOnly value={enroll.secret} />
              </label>
              <label className="field">
                <span>{t(lang, 'totpCode')}</span>
                <input
                  value={code}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  inputMode="numeric"
                />
              </label>
              <button type="submit" className="btn primary" disabled={busy}>
                {t(lang, 'totpConfirmEnroll')}
              </button>
            </form>
          ) : null}

          {status.enabled && status.required !== true ? (
            <form onSubmit={disableTotp} className="form-grid" style={{ marginTop: 24 }}>
              <h3>{t(lang, 'totpDisableTitle')}</h3>
              <label className="field">
                <span>{t(lang, 'password')}</span>
                <input
                  type="password"
                  value={disablePassword}
                  onChange={(e) => setDisablePassword(e.target.value)}
                />
              </label>
              <label className="field">
                <span>{t(lang, 'totpCode')}</span>
                <input
                  value={disableCode}
                  onChange={(e) =>
                    setDisableCode(e.target.value.replace(/\D/g, '').slice(0, 6))
                  }
                  inputMode="numeric"
                />
              </label>
              <button type="submit" className="btn" disabled={busy}>
                {t(lang, 'totpDisableBtn')}
              </button>
            </form>
          ) : null}
          {status.enabled && status.required === true ? (
            <p className="muted" style={{ marginTop: 16 }}>
              {t(lang, 'totpCannotDisable')}
            </p>
          ) : null}
        </div>
      ) : null}
    </AdminShell>
  );
}
