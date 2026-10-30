// Made by Dr Ali
// Phase 4 lockdown: IP allowlist + security headers for Admin Web.

import { NextRequest, NextResponse } from 'next/server';

function normalizeIp(ip: string): string {
  let s = ip.trim();
  if (s.startsWith('::ffff:')) s = s.slice(7);
  if (s === '::1') return '127.0.0.1';
  return s;
}

function ipv4ToInt(ip: string): number | null {
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

function ipAllowed(clientIp: string, allowlist: string[]): boolean {
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

function clientIp(req: NextRequest): string {
  const xff = req.headers.get('x-forwarded-for');
  if (xff) return normalizeIp(xff.split(',')[0] || '');
  const real = req.headers.get('x-real-ip');
  if (real) return normalizeIp(real);
  return '';
}

export function middleware(req: NextRequest) {
  const raw = process.env.ADMIN_IP_ALLOWLIST?.trim() ?? '';
  const allowlist = raw
    ? raw.split(',').map((s) => s.trim()).filter(Boolean)
    : [];

  if (allowlist.length > 0) {
    const ip = clientIp(req);
    // Local Next without proxy may have empty IP — deny only when we can see an IP.
    if (ip && !ipAllowed(ip, allowlist)) {
      return new NextResponse('Admin access denied from this network', {
        status: 403,
      });
    }
  }

  const res = NextResponse.next();
  res.headers.set('X-Frame-Options', 'DENY');
  res.headers.set('X-Content-Type-Options', 'nosniff');
  res.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.headers.set(
    'Permissions-Policy',
    'camera=(), microphone=(), geolocation=()',
  );
  // Next dev compiles with eval. Without this, the login form never runs and the
  // browser just reloads the page.
  const scriptSrc =
    process.env.NODE_ENV === 'production'
      ? "script-src 'self' 'unsafe-inline'"
      : "script-src 'self' 'unsafe-inline' 'unsafe-eval'";
  res.headers.set(
    'Content-Security-Policy',
    `default-src 'self'; img-src 'self' data: blob: https:; style-src 'self' 'unsafe-inline'; ${scriptSrc}; connect-src 'self' https: http://127.0.0.1:* http://localhost:*; frame-ancestors 'none'`,
  );
  if (process.env.NODE_ENV === 'production') {
    res.headers.set(
      'Strict-Transport-Security',
      'max-age=31536000; includeSubDomains',
    );
  }
  return res;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
