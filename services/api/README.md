# services/api

NestJS (TypeScript) REST API for OBIC — sole authority for AuthZ and writes.

**Made by Dr Ali.**

PostgreSQL is the system of record. The Flutter app is a thin client: every private
call must pass **AuthGuard → RolesGuard → ownership / assignment** on the server.

## Run locally

```bash
# From repo root — copy env placeholders (never commit real secrets)
cp .env.example .env

cd services/api
npm install
npm run start:dev
```

Health: `GET http://localhost:3000/v1/health`

## Uploads (Moments + chat M5.3)

`POST /v1/uploads` (JWT, multipart `files`). Public URLs under `/uploads/…`.

| Size | Storage on trial |
|------|------------------|
| ≤ ~12MB | Postgres `uploaded_files` (bytea) + disk cache — **survives redeploy** |
| > 12MB | Disk only — **ephemeral** on Render free; use object storage for production video |

Chat `sendMessage` rejects `stub://` / local `file:` URLs; clients must upload first.

## Phase 1 modules

| Module | Path | Notes |
|--------|------|-------|
| Health | `/v1/health` | DB ping + env sanity |
| Auth | `/v1/auth/*` | JWT skeleton, login stub |
| Users | `/v1/users/me` | JWT-protected; scoped to token `sub` |

Roles enum: `Customer` · `Employee` · `SuperAdmin`.

Ownership helpers live in `src/common/guards/ownership.guard.ts` — use them
from day one on any private resource query.
