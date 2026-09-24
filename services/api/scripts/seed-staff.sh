#!/usr/bin/env bash
# Made by Dr Ali — seed SuperAdmin + per-branch temporary desk staff.
# Uses DB upsert (bcrypt) so HTTP rate limits do not block seeding.
# Passwords: ~/Desktop/obic/deliverables/ACCOUNT-DEV-STAFF.txt (not in git).
set -euo pipefail
cd "$(dirname "$0")/.."
node scripts/seed-staff-db.js
