# Android trial staging — install & try all three roles

**Made by Dr Ali**

One release APK + one public HTTPS API. Works on **cellular or any Wi‑Fi** with the Mac **off**. Not Phase 5 (no live calls / Bike / partner APIs yet).

| Item | Value |
|------|--------|
| Health | https://obic-trial-api.onrender.com/v1/health |
| API base (baked into APK) | `https://obic-trial-api.onrender.com` (Flutter adds `/v1`) |
| APK | `~/Desktop/obic/deliverables/OBIC-trial-staging.apk` (~77 MB) |
| Host | Render free (Singapore) — sleeps when idle (~15 min) |
| Keep-alive | GitHub Actions cron every 5 min → `GET /v1/health` (see below) |

## Keep-alive (wake so demos don’t cold-start)

Render **free** spins down after ~15 minutes idle. Cold start is often **30–60s** and breaks phone demos.

**In-repo keep-alive (no paid Render upgrade):**

| Piece | Path |
|-------|------|
| Script | `scripts/wake-trial-api.sh` — retries, long timeouts, exit 0 only on `"status":"ok"` (`ai` optional) |
| GitHub Actions | `.github/workflows/wake-trial-api.yml` — cron `*/5 * * * *` + manual **Run workflow** |

```bash
# Manual wake (Mac / CI / phone demo prep)
./scripts/wake-trial-api.sh
```

After merge to the default branch, Actions runs ~every 5 minutes and keeps the trial API warm. If Actions is disabled or delayed, run the script locally before a demo.

### Optional: macOS launchd (local backup)

If you want the Mac to ping even when GitHub cron is late, create
`~/Library/LaunchAgents/com.obic.wake-trial-api.plist` (StartInterval 300 = 5 min):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.obic.wake-trial-api</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-lc</string>
    <string>/Users/mac/Projects/obic-app/scripts/wake-trial-api.sh</string>
  </array>
  <key>StartInterval</key><integer>480</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>/tmp/obic-wake-trial-api.log</string>
  <key>StandardErrorPath</key><string>/tmp/obic-wake-trial-api.err</string>
</dict>
</plist>
```

```bash
launchctl load ~/Library/LaunchAgents/com.obic.wake-trial-api.plist
# unload: launchctl unload ~/Library/LaunchAgents/com.obic.wake-trial-api.plist
```

### Phone tip

If the app feels slow after idle, open https://obic-trial-api.onrender.com/v1/health in the phone browser first and wait for `"status":"ok"` (and `"ai":"on"` if testing AI).

**Client stays responsive during cold start:** the app must not block navigation or clear the session while Render wakes (often 30–60s). Session tokens persist on network errors; show skeletons / “waking server…” instead of killing the session. Free Render cold start is the main *server* lag — keep HTTP polls paused in background and prefer realtime WS when connected (`MessageSyncGate`).

## Install (Android)

1. Copy `OBIC-trial-staging.apk` to the phone (AirDrop / Drive / USB / cable).
2. Open the file → Install. If blocked: **Settings → Security → Install unknown apps** → allow your Files/Drive app.
3. Open **OBIC**.

### First open after idle (Render sleep)

Free Render sleeps when unused (~15 min). Keep-alive (Actions cron / `scripts/wake-trial-api.sh`) usually prevents this; if login still hangs after a long idle:

1. On the phone browser, open https://obic-trial-api.onrender.com/v1/health  
2. Wait until you see `"status":"ok"` and `"database":"up"` (cold start can take **30–60 seconds**)  
3. Return to the app and try again  

## Trial accounts (same APK — log out between roles)

| Role | Email | Password | What to try |
|------|--------|----------|-------------|
| Customer | `ali@obic.local` | `AliObic2026!` | Home · Services · Messages · Orders · Me; open a service chat. Or **Register** a new account. |
| Employee | `staff@obic.local` | `StaffObic2026!` | Employee desk — orders / offers / ops (flags set in seed). |
| Super Admin | `admin@obic.local` | `AdminObic2026!` | Full admin desk — staff, moderation, oversight, org, offers, orders. |

Passwords are for this **trial DB only**. Change before any real launch.

## 3-role walkthrough

### A) Customer

1. Log in as `ali@obic.local` / `AliObic2026!` (or Register).
2. Browse Services, open a sub-service, start/use chat if available.
3. **Messages** tab → tap the right-side **OBIC AI** chip → ask a question (needs AI env on the trial API).
4. Open **OBIC Support** (or an order chat) → tap **Talk to staff** (pauses AI, notifies desk).
5. Check Orders and Me (profile).
6. **Log out**.

### B) Employee

1. Log in as `staff@obic.local` / `StaffObic2026!`.
2. Open Admin / Employee surfaces (desk).
3. Try orders, offers, and ops as allowed.
4. **Log out**.

### C) Super Admin

1. Log in as `admin@obic.local` / `AdminObic2026!`.
2. Open the full admin desk (`/v1/admin/me` gates SuperAdmin UI).
3. Try staff list, moderation, offers, orders, org oversight.
4. Done — tell us what breaks; then Phase 5.

## Mac-off confirmation

- API is on **Render**, not your Mac LAN (`192.168.0.215`).
- APK is built with `--dart-define=API_BASE_URL=https://obic-trial-api.onrender.com` (no trailing `/v1` — Flutter prefixes `/v1`).
- Phone needs only internet (cellular OK). Mac can be powered off.

## Rebuild (if needed)

```bash
cd apps/mobile
flutter build apk --release \
  --dart-define=API_BASE_URL=https://obic-trial-api.onrender.com
cp build/app/outputs/flutter-apk/app-release.apk \
  ~/Desktop/obic/deliverables/OBIC-trial-staging.apk
```

## Phone OTP / SMS (trial vs production)

- **Trial (now):** Phone binding verified with an **email code** (Resend). UI says so honestly — no “SMS sent” claims, no on-screen trial OTP clutter.
- Free +86 SMS is rare; mainland SMS later costs about **¥0.05/message** (Aliyun/Tencent). Leave SMS env unset on trial.
- **Production:** Set Aliyun or Tencent SMS env vars (see root `.env.example`). Twilio needs paid + geo permissions for China.
- Env keys: `~/.config/obic/mail.env` locally; Render → `obic-trial-api` → Environment.

## Chat GPS + file attach (M5.3)

- **Location share:** Messages → thread → **+** → Location. Allows GPS → text pin with **Amap (高德)** first when China (zh locale / CN region / CN placemark), then Apple Maps, then Google. Amap `position=` is **lng,lat** + `coordinate=wgs84`. Deny permission → toast, no send.
- **Image / PDF:** **+** → Album / File → pick → Send. Uploads via `POST /v1/uploads`, then `sendMessage` with real `attachmentUrl` (no `stub://`).
- **Voice (required):** Mic icon beside composer (or **+** → Voice) → hold-to-talk → release to send (slide up to cancel). Uploads as `attachmentKind: audio`, tap bubble to play.
- **Video (required):** **+** → Video → gallery or record (≤60s). Soft warn if >12MB (trial durability); hard reject >80MB. Playable inline bubble.
- **Trial media durability:** files ≤ ~12MB stored in Postgres (`uploaded_files`) so they survive Render redeploy; larger files are disk-only (ephemeral on free trial) until S3/GCS.

## Ops notes (developers)

- Blueprint: repo-root `render.yaml` → service `obic-trial-api`, DB `obic-trial-db`.
- Redis unset on purpose (`redis: skipped` on health).
- `ADMIN_REQUIRE_TOTP=false` on this trial only.
- Seed: `services/api/scripts/seed-staff-db.js` against the Render Postgres external URL (SSL).

### Phase 5 OBIC AI on trial API

Render CLI cannot set env vars (no `env` command; use Dashboard API / `~/.render/cli.yaml` key). In **Render → obic-trial-api → Environment**, set (values from `~/.config/obic/ai.env` — never commit):

```
AI_ENABLED=true
AI_PROVIDER=groq
AI_API_KEY=<from ~/.config/obic/ai.env>
AI_MODEL=qwen/qwen3.8-27b
```

Then redeploy. Confirm: `curl -sS https://obic-trial-api.onrender.com/v1/health` → `"ai":"on"`.

### Phase 5 Agora on trial API

Same service (from `~/.config/obic/agora.env` — never commit certificate):

```
AGORA_APP_ID=<from ~/.config/obic/agora.env>
AGORA_APP_CERTIFICATE=<from ~/.config/obic/agora.env>
```

Confirm health `"agora":"on"`. Mobile (Android + iOS) uses trial HTTPS; mic/camera prompts are system dialogs (Info.plist / AndroidManifest already wired).

## Form2 workflow (locked 19 Sep 2026)

Management answers are **final** and enforced in API + shown on Admin Org (web + Flutter):

1. Assigned Employee may change order status alone.
2. Waiting for customer = staff needs a customer reply (text / docs / confirmation).
3. Close order from **mobile Admin + Admin web** (both).
4. Off-duty reassign: client’s sales rep **or** branch manager (branch-scoped via `staffTitle` / `branchLabel`).
5. SuperAdmin may **add staff from Admin**; production mobiles/emails are entered later via that Staff UI (do not block on roster contact data now).

Source of truth: `apps/admin-web/lib/org.ts` · `apps/mobile/lib/core/obic_org.dart` · `services/api/src/org/form2-workflow.ts`.
