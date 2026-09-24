#!/usr/bin/env bash
# Made by Dr Ali — start local OBIC API on :3001 (Moments guests need this up).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PATH"
if curl -sf http://127.0.0.1:3001/v1/health >/dev/null 2>&1; then
  echo "API already up on :3001"
  curl -sf http://127.0.0.1:3001/v1/health
  echo
  exit 0
fi
if [[ ! -f dist/main.js ]]; then
  echo "Building…"
  npm run build
fi
# Free port if a dead listener remains
lsof -tiTCP:3001 | xargs kill 2>/dev/null || true
sleep 1
nohup env PORT=3001 node dist/main.js >> /tmp/obic-api.log 2>&1 &
echo "Started PID $!"
sleep 2
curl -sf http://127.0.0.1:3001/v1/health
echo
echo "Logs: /tmp/obic-api.log"
