# China / Daily / Travel hubs — live vs قريباً

Product pass: shared hub chrome + China complete + Daily/Travel upgrades + Nest hub-content seed + Admin Desk.

Production API: `https://api.obicgp.com`

## Live now

| Area | Status |
| --- | --- |
| Shared chrome: settings gear, language follows app, km/mi, default city, hub notifies, clear cache, OS location privacy deep-link, reset hub favorites | Live |
| Profile strip: addresses, favorites, recent searches, order history | Live |
| Live search filter (categories / merchants / services) | Live |
| Empty / error / offline illustrated + retry | Live (shared `hub_states`) |
| Share hub / share place; open exact pin in native maps (Amap / Apple / Google) | Live |
| Onboarding first open (1–2 screens) then never nag | Live |
| China: full city switcher AR/CN/Pinyin + GPS → nearest city | Live (`china_city_picker`, `china_visit_banner`) |
| China: categories Visit / Business / Visas / Education+CSC / Trade+logistics / Stay·tours + guides + staff CTA | Live |
| China: nearby places + place detail map | Live (seed + GPS distance) |
| Daily: category grid → browse → shop → order path | Live (marketplace API) |
| Daily: deliver-to address book + GPS one-tap set current | Live |
| Daily / Travel flash deals | Live **only when** `/v1/hub-content` returns published deals (section hidden if empty) |
| Travel: hotels / flights / trains / sights / tours / airport / rental — no Hotels+Stay dup | Live |
| Travel: city search → marketplace offers / Desk request | Live |
| Travel: Trips tab upcoming / past | Live |
| Travel settings: default traveler, currency display, order alerts | Live |
| Nest `GET /v1/hub-content` + Admin `/hub-content` publish toggles | Live (in-memory seed until DB migration) |
| Staff fulfill Daily/Travel/China orders | Live via existing Orders desk |

## قريباً

| Area | Note |
| --- | --- |
| Persistent CMS DB for hub guides/places (survive API restart) | In-memory publish toggles today |
| Live POI beyond Overpass/OSM food+hotels budget | Extend `marketplace-live` |
| Price-drop alerts when booking API allows | UI toggle reserved; no vendor webhook yet |
| In-app wallet / pay screen | Blocked until Airwallex mainland confirmation |
| Richer Daily beauty/clinic catalogs from partners | Uses marketplace seed + forms |
| Home favorites language / AI CS dedupe | Parallel agent — do not overwrite |

## GPS proof notes

| Hub | Behavior | How to verify in Yiwu |
| --- | --- | --- |
| **China** | `Geolocator` high accuracy → nearest city from `china_cities.json` → Visit banner lists places with km; city chip + refresh; denied → app settings deep-link | Open الصين بين يديك → allow location → chip shows ييوو / Yiwu → Nearby places update |
| **Daily** | GPS button on deliver-to card → reverse geocode → save default address via `/v1` addresses | Open يومي → tap my-location → city line updates → merchants load for city |
| **Travel** | Default city in hub settings; destination search filters hotels API `?city=`; GPS shared via address book used by search card | Set default city Yiwu in settings → search city → hotels from `api.obicgp.com/v1/marketplace/hotels` |

Secrets stay in `~/.config/obic/` only. Never commit.
