# OBIC V1 — Interactive UX Prototype

Premium Ctrip-inspired mobile UX for OBIC China business/travel services.  
**English UI · Stakeholder demo · No backend · Confidential**

> This repo is the **interactive prototype + plan PDF only**.  
> It is **not** a marketing website rewrite of www.obicgp.com.

## Open locally

Open in Chrome:

```bash
open -a "Google Chrome" prototype/index.html
```

Or from repo root (GitHub Pages-style entry):

```bash
open -a "Google Chrome" index.html
```

## Share remotely (GitHub Pages)

Static hosting — stakeholder opens a URL. Relative paths only; no server required.

### One-time publish (recommended)

```bash
cd /Users/mac/Projects/obic-app

# 1) Create repo (private first — ask before making public)
# Install GitHub CLI if needed: brew install gh && gh auth login
gh repo create obic-app-prototype --private --source=. --remote=origin --push

# 2) Enable Pages: Settings → Pages → Deploy from branch `main` / folder `/ (root)`
# Or via CLI:
gh api -X POST repos/$(gh api user --jq .login)/obic-app-prototype/pages \
  -f build_type=legacy -f source='{"branch":"main","path":"/"}'

# 3) Share URL (after ~1 min):
# https://<your-username>.github.io/obic-app-prototype/
```

Public Pages on a repo **without secrets** is OK for UX sharing. Prefer **private** until you confirm.

Without `gh`:

```bash
# Create empty repo named obic-app-prototype on GitHub (web UI), then:
git remote add origin https://github.com/<YOU>/obic-app-prototype.git
git push -u origin main
# Then enable Pages: Settings → Pages → Branch: main → Folder: / (root)
```

## Screens

Home · Services · Detail · Request · Orders · Timeline · Messages · **Chat (images/files)** · **Voice call** · **Video call** · **Incoming call** · Me · Login · Register · Search · About

## Deliverables

- Interactive prototype: `prototype/`
- PDF plan: `docs/OBIC-V1-Plan-and-UX.pdf`
- Desktop copy: `~/Desktop/obic/deliverables/`

Do **not** commit Desktop deal/PRD/staff files or `.env` secrets.
