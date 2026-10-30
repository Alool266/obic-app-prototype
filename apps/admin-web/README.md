# OBIC Admin Web

Made by Dr Ali.

Next.js staff desk for OBIC. Uses the same NestJS API as mobile.

## Security rules

- **No secrets** in this app (no JWT signing keys, no DB URL).
- Login stores access token in `sessionStorage` only (cleared on tab close).
- Every screen calls `/v1/admin/*` — **Customers get 403** even with a valid customer JWT.
- Roles are re-checked from **Postgres** on the API (JWT role is a hint only).
- SuperAdmin chat oversight writes an **audit log** row on every list/transcript read.
- Oversight UI (`/oversight`): Support / order / group threads, WeChat-style day separators, **Join conversation** (`POST /v1/admin/oversight/chats/:id/join`). Friend DMs optional read-only (`includeFriends=1`); cannot join.
- Trial API: `https://obic-trial-api.onrender.com` — set `NEXT_PUBLIC_API_BASE_URL` to that for Admin Web against trial.
- Employees only see **assigned** orders; cannot assign peers or open oversight.
- SuperAdmin **TOTP** (Authenticator): required in production (`ADMIN_REQUIRE_TOTP`); step-up code (`X-OBIC-TOTP`) for staff promote / profile edits.
- Optional **IP allowlist** via `ADMIN_IP_ALLOWLIST` (API + this app middleware).
- Security headers set in `middleware.ts` (CSP, frame deny, HSTS in prod).

## Local run

```bash
# API must be running on :3001
cd apps/admin-web
npm install
NEXT_PUBLIC_API_BASE_URL=http://127.0.0.1:3001 npm run dev
```

Open http://127.0.0.1:3010

### Dev accounts (local only)

See `~/Desktop/obic/deliverables/ACCOUNT-DEV-STAFF.txt`

- SuperAdmin: `admin@obic.local`
- Employee: `staff@obic.local`
- Customer must **not** access admin (403)

Local tip: leave `ADMIN_REQUIRE_TOTP` unset (defaults off unless `NODE_ENV=production`) so you can enroll TOTP from Settings without locking yourself out.

## Production lockdown (Phase 4 DoD)

1. **Host** on `admin.` subdomain (HTTPS only).
2. **Cloudflare Access** (recommended edge gate):
   - Zero Trust → Access → Application → Self-hosted
   - Application domain: `admin.obicgp.com`
   - Policy: allow emails / IdP groups for OBIC staff only
   - Optional: require hardware key / OTP at the Access layer as well
3. **App IP allowlist** (defense in depth):
   ```bash
   ADMIN_IP_ALLOWLIST=203.0.113.10,10.0.0.0/8
   TRUST_PROXY=true
   ```
   Set the same var on **API** and **Admin Web**.
4. **CORS** on API:
   ```bash
   CORS_ORIGINS=https://admin.obicgp.com
   ADMIN_REQUIRE_TOTP=true
   ```
5. Enroll SuperAdmin TOTP in Admin → Settings → 2FA before granting production access.

Without Cloudflare Access, **do not** expose Admin Web on the open internet — use VPN or the IP allowlist above.
