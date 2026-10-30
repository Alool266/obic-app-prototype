# Office editor always-on (OnlyOffice / Collabora)

## Current production

- API + Admin + Postgres + Redis + LiveKit run on Aliyun ECS `115.29.160.92` (`api.obicgp.com`).
- **Do not** host editors or the API on sleep-capable free hosts (Render free, etc.).
- Personal Docs/Sheets/Notes are served by the Nest API (`/v1/user-office`) — already always-on with the API.

## Why OnlyOffice is not on this box yet

| Resource | ECS today | OnlyOffice Document Server typical |
| --- | --- | --- |
| RAM | 3.7 GiB (≈2 GiB free with stack) | ≥4 GiB recommended alone |
| Disk | 40 G (~12 G free) | Needs headroom for fonts/cache |

Installing OnlyOffice beside LiveKit + API risks OOM kills. **Upgrade the instance (or add a second always-on VM) before `docker compose up` for Document Server.**

## Target setup (when hardware allows)

1. Domain: `office.obicgp.com` → same ECS or dedicated editor host (A record).
2. Compose under `/opt/obic/office/` using official `onlyoffice/documentserver` (or Collabora `collabora/code`).
3. Caddy reverse-proxy HTTPS to Document Server; JWT secret in `~/.config/obic/onlyoffice.env` (never git).
4. Nest: mint editor config + signed download URLs for `user_office_items` / company drive files.
5. Flutter: open editor URL in existing `MiniAppEngineScreen` / WebView.
6. Keep Nest API wake-proof: same ECS compose `restart: unless-stopped` (already used for `obic-api-1`).

## Until then

Ship native Notes + text Documents + Spreadsheets + PDF viewer. Slides and full Office stay **قريباً**.
