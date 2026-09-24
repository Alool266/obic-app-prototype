# Progress 21 — GPS share + M5.3 chat uploads (for report agent)

## Final location message link format

China-first (zh locale / CN|HK|MO region or placemark):

```
📍 <label>

高德地图: https://uri.amap.com/marker?position=<lng>,<lat>&coordinate=wgs84&callnative=1&name=<label>
Apple 地图: https://maps.apple.com/?ll=<lat>,<lng>&q=<label>
Google 地图: https://maps.google.com/?q=<lat>,<lng>
```

Outside China (order flips — Google first, then Apple, then Amap). EN/AR labels: `Amap` / `Apple Maps` / `Google Maps`.

**Amap coordinate order is longitude,latitude** (not lat,lng). GPS is WGS84 (`coordinate=wgs84`).

Permission deny → toast, abort (no Yiwu fallback).

## How to test

1. **GPS:** Messages → open thread → **+** → Location → allow GPS → message shows Amap/Apple/Google links; tap Amap in China.
2. **Image/PDF:** **+** → Album or File → pick → Send → bubble shows image (or file name); peer can open via `/uploads/…`.

## Files changed

### Mobile
- `apps/mobile/lib/features/messages/chat_location_body.dart` (new) — Amap/Apple/Google body builders
- `apps/mobile/lib/features/messages/chat_attach_helpers.dart` (new) — DTO kind + local/remote URL helpers
- `apps/mobile/lib/features/messages/chat_screen.dart` — real GPS share; upload then sendMessage; image via `media_url.dart`
- `apps/mobile/lib/features/messages/outbound_message_queue.dart` — upload local path on flush
- `apps/mobile/test/chat_location_attach_test.dart` (new)

### API
- `services/api/src/chat/chat.service.ts` — reject `stub://` / `file:` attachment URLs
- `services/api/src/chat/dto/chat.dto.ts` — comment
- `services/api/src/chat/message.entity.ts` — comment
- `services/api/src/chat/chat.service.attachment.spec.ts` (new)
- `services/api/src/uploads/uploads.service.ts` — ≤12MB Postgres vs larger disk ephemeral docs
- `services/api/README.md` — uploads durability table

### Docs
- `docs/ANDROID-TRIAL-STAGING.md` — GPS + M5.3 test notes

## Deliverables
- APK: `~/Desktop/obic/deliverables/OBIC-trial-staging.apk` (trial API base)
- API stub-reject only live after commit/push + Render deploy (uploads endpoint already on trial)

## Screenshots
(No new UI chrome — GPS/file are message text + existing attach panel. Add phone shots here if captured.)
