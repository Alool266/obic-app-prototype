# Production pass — live vs قريباً

Date: 2026-10-31 · API: `https://api.obicgp.com` only (never Render).

HubContentModule already deployed on ECS. PR #1 `feat/hubs-china-daily-travel-pro`.

## Live now

| Area | Status |
| --- | --- |
| **Settings** — Profile, Account security, Switch account, Language (instant), Dark mode, Notifications, Moments notify/Mute (persist), Friends’ permissions, Storage clear, Contact support → AI CS/Desk, Report bug, Restore (opens support), Delete account (password), Mini apps / Sounds / Chats / Voice-video | Live — no dead chevrons on Settings rows |
| **Messages** — pin / mute / hide / delete / mark read·unread / search / long-press / badge; All · Unread · Services **counts**; pull-to-refresh | Live |
| **Messages dedupe** — one row per conversation id + order id; same-title order/support collapse (e.g. شانغهاي بيزنس إن) | Live (client + `listThreads` server) |
| **Order chats + Support** — AI CS path; order thread per `orderId` (DB unique index) | Live |
| **Voice / image / LiveKit calls** | Live (do not regress) |
| **Discover Channels** — Follow · Nearby · Friends · Hot from `/v1/channels/feed`; upload (+) → `/v1/uploads` + channel video create + Desk moderation routes | Live API; feeds empty until users upload / staff approve |
| **Nearby** — GPS city (`lat`/`lng`/`city` query) → user city persist → city peers + official | Live wiring |
| **Daily** — categories/merchants from marketplace API; GPS deliver-to; deals only when `/v1/hub-content` or promos return rows | Live |
| **Daily → Desk → customer** | **Verified 2026-10-31:** create marketplace order → `Assigned` + `marketplace:true` + `conversationId`; customer Orders + Messages; Yiwu Secretary assignee |
| **Travel / service orders** | Live via existing Orders desk when offers/orders exist |
| **China / ME / Africa hubs** | Live chrome + GPS where wired (see `HUBS-LIVE-VS-QARIBAN.md`) |
| **Home favorites / EN labels / AI CS Noor dedupe** | Live on prod — do not wipe |
| **Always-on** | ECS production + GitHub cron `wake-prod-api.yml` ≤5 min → `/v1/health` · notes in `infra/README.md` |

## قريباً (honest gaps)

| Area | Note |
| --- | --- |
| Channel Hot/Follow/Friends with rich catalog | API live; **no fake videos** — empty until real uploads pass moderation |
| Channel pagination beyond first page (~40) | Pull-to-refresh live; cursor pages not shipped |
| Persistent hub CMS DB | Publish toggles in-memory until migration |
| staff@obic.local seeing all Daily queue | Desk routes by **assignee** (Yiwu Secretary). Use secretary / SuperAdmin Desk filters — not a fake global inbox |
| In-app wallet / pay | Blocked until Airwallex mainland confirmation |
| `/ops` prototype tiles | Out of scope this pass |
| New `@obic.local` register without OTP | Email OTP required; use existing demo customer for Pixel trial |

## Daily → Desk path (prod proof)

1. Customer `POST /v1/orders` with `formData.source=marketplace`, food service UUID.
2. Response: `status: Assigned`, `marketplace: true`, `conversationId` set.
3. Customer `GET /v1/orders` + `GET /v1/chat/threads` show the order chat.
4. Assignee = Yiwu Secretary desk (`assignedEmployeeId` set). Staff updates status → customer thread status notes.

## Device / account

| Item | Value |
| --- | --- |
| Pixel trial login | `ali@obic.local` / `AliObic2026!` (Customer, prod) |
| Staff Desk | `staff@obic.local` / `StaffObic2026!` (assigned slice) · Secretary `temp.yiwu.secretary@obic.local` / `TempObic2026!Yiwu-Sec` |
| Smoke | iPhone dark EN+AR · Desk login after install |

Secrets stay in `~/.config/obic/`. Never commit `.p8` / ECS passwords.

Made by Dr Ali
