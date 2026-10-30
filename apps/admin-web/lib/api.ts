// Made by Dr Ali
// Browser Admin API helper — tokens in memory/sessionStorage only (never localStorage secrets).
// Default: same-origin /obic-api proxy (see next.config.ts) so Clash cannot break login.

const API =
  process.env.NEXT_PUBLIC_API_BASE_URL?.replace(/\/$/, '') || '/obic-api';

/** Same origin the admin proxy uses, for opening a hosted package in a new tab. */
export function adminAssetUrl(path: string): string {
  const suffix = path.startsWith('/') ? path : `/${path}`;
  return `${API}${suffix}`;
}

export type Tokens = { accessToken: string; refreshToken: string };

export type LoginResponse =
  | (Tokens & { user: { role: string; name: string } })
  | { requiresTotp: true; totpSession: string; expiresIn: string };

export async function login(email: string, password: string): Promise<LoginResponse> {
  let res: Response;
  try {
    res = await fetch(`${API}/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({ email, password }),
    });
  } catch {
    throw new Error(
      'Cannot reach API (Failed to fetch). Keep API on :3001 and open http://127.0.0.1:3010 — then hard-refresh (Cmd+Shift+R).',
    );
  }
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json.message || `Login failed (${res.status})`);
  return json;
}

export async function verifyTotp(
  totpSession: string,
  code: string,
): Promise<Tokens & { user: { role: string; name: string } }> {
  const res = await fetch(`${API}/v1/auth/totp/verify`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ totpSession, code }),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json.message || `TOTP failed (${res.status})`);
  return json;
}

export async function adminFetch(
  path: string,
  accessToken: string,
  init?: RequestInit & { totpCode?: string },
) {
  const { totpCode, ...rest } = init || {};
  const headers: Record<string, string> = {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    Authorization: `Bearer ${accessToken}`,
    ...(rest.headers as Record<string, string> | undefined),
  };
  if (totpCode) headers['X-OBIC-TOTP'] = totpCode;
  const res = await fetch(`${API}${path}`, {
    ...rest,
    headers,
  });
  const text = await res.text();
  const json = text ? JSON.parse(text) : {};
  if (!res.ok) {
    const msg = json.message || `Request failed (${res.status})`;
    const err = new Error(typeof msg === 'string' ? msg : JSON.stringify(msg)) as Error & {
      code?: string;
      status?: number;
    };
    err.code = json.code || (typeof json.message === 'object' ? json.message?.code : undefined);
    err.status = res.status;
    throw err;
  }
  return json;
}

/** Multipart upload — returns first item url. */
export async function adminUploadFile(
  accessToken: string,
  file: File,
): Promise<string> {
  const form = new FormData();
  form.append('files', file);
  const res = await fetch(`${API}/v1/uploads`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
    body: form,
  });
  const json = await res.json();
  if (!res.ok) {
    throw new Error(json.message || `Upload failed (${res.status})`);
  }
  const items = json.items as { url?: string }[] | undefined;
  const url = items?.[0]?.url;
  if (!url) throw new Error('Upload returned no URL');
  return url.startsWith('http') ? url : `${API}${url.startsWith('/') ? '' : '/'}${url}`;
}

export async function adminPostForm(
  path: string,
  accessToken: string,
  form: FormData,
  totpCode?: string,
) {
  const headers: Record<string, string> = {
    Accept: 'application/json',
    Authorization: `Bearer ${accessToken}`,
  };
  if (totpCode) headers['X-OBIC-TOTP'] = totpCode;
  const res = await fetch(`${API}${path}`, { method: 'POST', headers, body: form });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json.message || `Upload failed (${res.status})`);
  return json;
}

export async function adminDownload(path: string, accessToken: string): Promise<Blob> {
  const res = await fetch(`${API}${path}`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    const json = await res.json().catch(() => ({}));
    throw new Error(json.message || `Download failed (${res.status})`);
  }
  return res.blob();
}

export function mediaUrl(pathOrUrl: string | null | undefined): string {
  if (!pathOrUrl) return '';
  if (pathOrUrl.startsWith('http')) return pathOrUrl;
  return `${API}${pathOrUrl.startsWith('/') ? '' : '/'}${pathOrUrl}`;
}

export { API as apiBaseUrl };
