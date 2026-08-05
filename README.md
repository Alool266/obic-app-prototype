# OBIC V1 — Interactive UX Prototype

Premium **3D-depth** customer app + **staff admin** (mobile & desktop web) + **OBIC AI** + **Moments** + friends.  
**Arabic default (RTL)** · English switch · Designed & developed by **Ali** · Stakeholder demo · Static HTML · Confidential

> Prototype + guides only — **not** a rewrite of www.obicgp.com.

## Open locally

```bash
open -a "Google Chrome" /Users/mac/Projects/obic-app/prototype/index.html
```

Left panel: language (العربية / English) · jump screens · Customer App vs Admin Web.

### Demo paths for stakeholders
1. **Home (AR)** — 3D tiles, promos, notification bell, language chip  
2. **Moments** — Post as Admin (notifies all) vs User (silent)  
3. **Add friend** — phone / ID / QR · friend requests (customers)  
4. **Staff** — Me/About tiny **O Staff** → Super Admin · Chat oversight  
5. **Employee** — add-customer blocked · no peer chat visibility  
6. **Chat** — Photo / File · Voice / Video  
7. **Auth** — Email | Phone tabs  
8. **Admin Web** — desktop ops + oversight  

## Guides (PDF)

| File | Language |
|------|----------|
| `docs/OBIC-App-Guide-AR.pdf` | Arabic |
| `docs/OBIC-App-Guide-EN.pdf` | English |
| `docs/OBIC-V1-Plan-and-UX.pdf` | Plan + UX |

## Share remotely (GitHub Pages)

```bash
cd /Users/mac/Projects/obic-app
# brew install gh && gh auth login   # once
gh repo create obic-app-prototype --private --source=. --remote=origin --push
# Settings → Pages → Deploy from branch → main → / (root)
# https://<username>.github.io/obic-app-prototype/
```

Root `index.html` redirects to `prototype/`. Relative paths only.

## Deliverables

| Item | Path |
|------|------|
| Prototype | `prototype/index.html` |
| Guides | `docs/OBIC-App-Guide-AR.pdf` · `docs/OBIC-App-Guide-EN.pdf` |
| Plan PDF | `docs/OBIC-V1-Plan-and-UX.pdf` |
| Desktop sync | `~/Desktop/obic/deliverables/` |

Do **not** commit Desktop deal/PRD/staff secrets or `.env` files.

Designed & developed by **Ali**.
