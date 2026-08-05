# OBIC V1 — Interactive UX Prototype

Premium Ctrip-inspired **customer app** + **staff admin** (mobile & desktop web).  
English UI · Stakeholder demo · Static HTML · Confidential

> Prototype + plan only — **not** a rewrite of www.obicgp.com.

## Open locally

```bash
open -a "Google Chrome" /Users/mac/Projects/obic-app/prototype/index.html
```

Left panel: jump screens. Top toggle: **Customer App** vs **Admin Web**.

### Demo paths for stakeholder
1. **Customer Home** — premium travel-super-app look  
2. **Chat** — Photo / File attach · Voice · Video · Incoming call  
3. **Register / Login** — **Email | Phone** tabs  
4. **Me or About** — tiny **O Staff** mark → Staff Login  
5. Toggle role **Super Admin / Employee** → Admin App dashboard  
6. Toggle **Admin Web** — desktop operations panel  

## Share remotely (GitHub Pages)

```bash
cd /Users/mac/Projects/obic-app

# Install CLI once if needed:
# brew install gh && gh auth login

# Prefer private first; ask before public
gh repo create obic-app-prototype --private --source=. --remote=origin --push

# Enable Pages from branch main, folder / (root)
# GitHub → Settings → Pages → Deploy from branch → main → / (root)
#
# Live URL after ~1 minute:
# https://<your-username>.github.io/obic-app-prototype/
```

Without `gh`:

```bash
git remote add origin https://github.com/<YOU>/obic-app-prototype.git
git push -u origin main
# Then enable Pages on the repo (main / root)
```

Root `index.html` redirects to `prototype/`. Relative paths only.

## Deliverables

| Item | Path |
|------|------|
| Prototype | `prototype/index.html` |
| PDF plan | `docs/OBIC-V1-Plan-and-UX.pdf` |
| Desktop sync | `~/Desktop/obic/deliverables/` |

Do **not** commit Desktop deal/PRD/staff secrets or `.env` files.
