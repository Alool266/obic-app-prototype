# infra

Local and cloud infrastructure for OBIC.

**Status:** Homebrew PostgreSQL is still the daily driver on this Mac for DB. **Redis** is Phase C and runs in Docker. Staging compose = Postgres + Redis + API image.

```bash
# Local Redis (API via npm on host)
docker compose -f infra/docker-compose.yml up -d redis

# Full staging stack
docker compose -f infra/docker-compose.staging.yml up -d --build
# See infra/STAGING.md

# Build the API image only
# docker compose --profile prep -f infra/docker-compose.yml build api
```

Env: set `REDIS_URL=redis://localhost:6379` in `.env` (see `.env.example`). If unset, API starts and health reports `redis:"skipped"`.

Do not put production secrets in this folder.

## Production always-on (api.obicgp.com)

Production API + Admin + Redis/workers run on **Aliyun ECS** (`https://api.obicgp.com`). They must **never spin down**.

| Piece | Expectation |
| --- | --- |
| API container | `restart: always` (or Docker Compose equivalent) on ECS — no idle scale-to-zero |
| Admin Web | Same host / companion container — always reachable for Desk login |
| Redis / workers | Always-up; health reports `"redis":"up"` |
| Health | `GET https://api.obicgp.com/v1/health` → `"status":"ok"` (DB + redis + livekit) |
| Keep-alive ping | GitHub Actions `.github/workflows/wake-prod-api.yml` every **≤5 min** + manual **Run workflow** |
| Manual ping | `HEALTH_URL=https://api.obicgp.com/v1/health ./scripts/wake-trial-api.sh` |

Cold start must not break the first customer order or Desk login. If health is slow after a host reboot, wait for `"status":"ok"` before demos.

Optional uptime alert: point any external monitor (UptimeRobot / Cloudflare / Aliyun) at `/v1/health` and alert on non-200 or missing `"status":"ok"`.

**Do not** point phone release builds at Render (`obic-trial-api.onrender.com`). Release defaults to `https://api.obicgp.com` (`apps/mobile/lib/core/api_config.dart`).

Made by Dr Ali
