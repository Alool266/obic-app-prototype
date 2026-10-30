# Mini-apps shelf + productivity — live vs قريباً

Production API: `https://api.obicgp.com` (always-on ECS — do not use sleep hosts for editor/API).

## Live now

| Area | Status |
| --- | --- |
| Home mini-app shelf edit: add / remove / reorder (drag) / favorite (pin) | Live — local + `GET/PUT /v1/users/me/home-layout` → `miniApps` |
| All mini-apps catalog (first-party + approved partners) | Live — no duplicate ids/URLs |
| Geo soft-filter by device locale/country | Live — hubs prefer matching region; “All” still reachable via search |
| Dark / light + AR/EN/ZH/FR labels on shelf + office | Live |
| Notes create / open / save / share with Obic contacts | Live — `POST/PATCH /v1/user-office` kind=`note` |
| Documents (Word-like text) open / save / share | Live — kind=`document` |
| Spreadsheets (Excel-like text grid) open / save / share | Live — kind=`spreadsheet` |
| PDF viewer (https URL → WebView) | Live — kind=`pdf` |
| Hubs as mini-apps (China / Mideast / Africa / Daily / Travel / Yemen) | Live — same add/move/favorite rules |
| Desk SuperAdmin enable/disable first-party mini-apps | Live — `GET/PUT /v1/admin/mini-apps/desk-flags` |
| Partner mini-app review (approve / reject / disable) | Live — existing Admin `/mini-apps` |
| API always-on (ECS Hangzhou, no Render sleep) | Live — `api.obicgp.com` |

## قريباً

| Area | Note |
| --- | --- |
| Full OnlyOffice / Collabora Document Server | ECS is 3.7 GiB RAM — Document Server needs ~4 GiB+ alone. Ship after larger box + `office.obicgp.com` Caddy route. See `docs/OFFICE-EDITOR-ALWAYS-ON.md`. |
| Slides (PowerPoint-like) | Flag `obic-slides` disabled by default; opens قريباً screen |
| Rich DOCX/XLSX binary round-trip | Text Docs/Sheets today; binary via OnlyOffice later |
| Per-org multi-tenant flags | Single-tenant Desk flags today |

## Grid API

```http
GET /v1/users/me/home-layout
PUT /v1/users/me/home-layout
```

Body (services + mini-apps):

```json
{
  "order": ["china-in-hand", "..."],
  "favorites": ["..."],
  "hidden": ["..."],
  "miniApps": {
    "order": ["obic-notes", "obic-documents"],
    "favorites": ["obic-notes"],
    "hidden": []
  }
}
```

Omitting `miniApps` on PUT leaves the shelf unchanged.

## Office API

- `GET /v1/user-office?kind=note|document|spreadsheet|pdf`
- `POST /v1/user-office` · `GET/PATCH/DELETE /v1/user-office/:id` · `PUT /v1/user-office/:id/share`

## First-party flags

- Public: `GET /v1/mini-apps/first-party-flags`
- Desk: `GET /v1/admin/mini-apps/desk-flags` · `PUT /v1/admin/mini-apps/desk-flags/:appId` `{ "enabled": true }`

Secrets stay in `~/.config/obic/` only.
