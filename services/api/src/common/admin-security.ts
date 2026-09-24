// Made by Dr Ali
// Phase 4 admin security helpers — TOTP policy + IP allowlist parsing.

import { ConfigService } from '@nestjs/config';

/** True when SuperAdmin must enroll/use TOTP (prod default). */
export function adminRequireTotp(config: ConfigService): boolean {
  const raw = config.get<string>('ADMIN_REQUIRE_TOTP')?.trim().toLowerCase();
  if (raw === 'true' || raw === '1' || raw === 'yes') return true;
  if (raw === 'false' || raw === '0' || raw === 'no') return false;
  return config.get<string>('NODE_ENV') === 'production';
}

/** Comma-separated IPs / CIDRs. Empty = allow all (local/dev). */
export function parseAdminIpAllowlist(config: ConfigService): string[] {
  const raw = config.get<string>('ADMIN_IP_ALLOWLIST')?.trim() ?? '';
  if (!raw) return [];
  return raw
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

export function ipv4ToInt(ip: string): number | null {
  const parts = ip.split('.');
  if (parts.length !== 4) return null;
  let n = 0;
  for (const p of parts) {
    const o = Number(p);
    if (!Number.isInteger(o) || o < 0 || o > 255) return null;
    n = (n << 8) + o;
  }
  return n >>> 0;
}

/** Exact IPv4/IPv6 match, or IPv4 CIDR (e.g. 10.0.0.0/8). */
export function ipMatchesAllowlist(clientIp: string, allowlist: string[]): boolean {
  if (allowlist.length === 0) return true;
  const ip = normalizeIp(clientIp);
  for (const entry of allowlist) {
    const rule = entry.trim();
    if (!rule) continue;
    if (rule.includes('/')) {
      const [range, bitsStr] = rule.split('/');
      const bits = Number(bitsStr);
      const a = ipv4ToInt(normalizeIp(range));
      const b = ipv4ToInt(ip);
      if (a == null || b == null || !Number.isInteger(bits) || bits < 0 || bits > 32) {
        continue;
      }
      const mask = bits === 0 ? 0 : (~0 << (32 - bits)) >>> 0;
      if ((a & mask) === (b & mask)) return true;
    } else if (normalizeIp(rule) === ip) {
      return true;
    }
  }
  return false;
}

export function normalizeIp(ip: string): string {
  let s = ip.trim();
  if (s.startsWith('::ffff:')) s = s.slice(7);
  if (s === '::1') return '127.0.0.1';
  return s;
}

/** Best-effort client IP (honors X-Forwarded-For when TRUST_PROXY=true). */
export function clientIpFromRequest(
  req: {
    headers: Record<string, string | string[] | undefined>;
    ip?: string;
    socket?: { remoteAddress?: string };
  },
  trustProxy: boolean,
): string {
  if (trustProxy) {
    const xff = req.headers['x-forwarded-for'];
    const first = Array.isArray(xff) ? xff[0] : xff?.split(',')[0];
    if (first?.trim()) return normalizeIp(first);
    const real = req.headers['x-real-ip'];
    const realOne = Array.isArray(real) ? real[0] : real;
    if (realOne?.trim()) return normalizeIp(realOne);
  }
  return normalizeIp(req.ip || req.socket?.remoteAddress || '');
}

/** Comma-separated CORS origins. Empty in non-prod = reflect request (dev). */
export function parseCorsOrigins(config: ConfigService): true | string[] {
  const raw = config.get<string>('CORS_ORIGINS')?.trim() ?? '';
  if (!raw) {
    if (config.get<string>('NODE_ENV') === 'production') {
      return [];
    }
    return true;
  }
  return raw
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}
