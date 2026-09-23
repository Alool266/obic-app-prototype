#!/usr/bin/env bash
# Wake / keep-alive for the Render free trial API.
# Retries through cold starts (often 30–90s). Exit 0 only when status is ok.
#
# Usage:
#   ./scripts/wake-trial-api.sh
#   HEALTH_URL=https://obic-trial-api.onrender.com/v1/health ./scripts/wake-trial-api.sh
#
# Optional macOS launchd (every 5 min): see docs/ANDROID-TRIAL-STAGING.md

set -euo pipefail

HEALTH_URL="${HEALTH_URL:-https://obic-trial-api.onrender.com/v1/health}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-16}"
CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-30}"
MAX_TIME="${MAX_TIME:-90}"
SLEEP_BETWEEN="${SLEEP_BETWEEN:-6}"

# Prefer a quick warm ping first; fall back to full retry loop on failure.
quick_ping() {
  local tmp http_code curl_rc body
  tmp="$(mktemp)"
  set +e
  http_code="$(
    curl -sS -L \
      --connect-timeout 10 \
      --max-time 20 \
      -o "$tmp" \
      -w "%{http_code}" \
      "$HEALTH_URL" 2>/dev/null
  )"
  curl_rc=$?
  set -e
  body="$(cat "$tmp" 2>/dev/null || true)"
  rm -f "$tmp"
  if [ "$curl_rc" -eq 0 ] && [ "$http_code" = "200" ]; then
    if echo "$body" | grep -qE '"status"[[:space:]]*:[[:space:]]*"ok"'; then
      echo "HTTP 200 (quick)"
      echo "$body"
      return 0
    fi
  fi
  return 1
}

echo "Wake trial API: $HEALTH_URL"
echo "Attempts: $MAX_ATTEMPTS  (connect ${CONNECT_TIMEOUT}s / total ${MAX_TIME}s each)"

if quick_ping; then
  ai_note=""
  body="$(curl -sS -L --connect-timeout 10 --max-time 20 "$HEALTH_URL" 2>/dev/null || true)"
  if echo "$body" | grep -qE '"ai"[[:space:]]*:[[:space:]]*"on"'; then
    ai_note=" (ai:on)"
  fi
  echo ""
  echo "OK — trial API awake${ai_note}"
  exit 0
fi

echo "Quick ping missed — full cold-start retry loop…"

attempt=1
body=""
http_code=""
while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
  echo ""
  echo "── attempt $attempt/$MAX_ATTEMPTS ──"
  tmp="$(mktemp)"
  set +e
  http_code="$(
    curl -sS -L \
      --connect-timeout "$CONNECT_TIMEOUT" \
      --max-time "$MAX_TIME" \
      -o "$tmp" \
      -w "%{http_code}" \
      "$HEALTH_URL" 2>"${tmp}.err"
  )"
  curl_rc=$?
  set -e
  body="$(cat "$tmp" 2>/dev/null || true)"
  err="$(cat "${tmp}.err" 2>/dev/null || true)"
  rm -f "$tmp" "${tmp}.err"

  if [ "$curl_rc" -ne 0 ]; then
    echo "curl failed (rc=$curl_rc)${err:+: $err}"
  elif [ "$http_code" != "200" ]; then
    echo "HTTP $http_code"
    [ -n "$body" ] && echo "$body"
  else
    echo "HTTP 200"
    echo "$body"
    status_ok=0
    if command -v jq >/dev/null 2>&1; then
      if echo "$body" | jq -e '.status == "ok"' >/dev/null 2>&1; then
        status_ok=1
      fi
    elif echo "$body" | grep -qE '"status"[[:space:]]*:[[:space:]]*"ok"'; then
      status_ok=1
    fi

    if [ "$status_ok" -eq 1 ]; then
      ai_note=""
      if echo "$body" | grep -qE '"ai"[[:space:]]*:[[:space:]]*"on"'; then
        ai_note=" (ai:on)"
      elif echo "$body" | grep -qE '"ai"[[:space:]]*:'; then
        ai_note=" (ai field present; optional for wake)"
      fi
      echo ""
      echo "OK — trial API awake${ai_note}"
      exit 0
    fi
    echo "JSON missing status:ok — retrying"
  fi

  if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
    echo "Waiting ${SLEEP_BETWEEN}s for cold start…"
    sleep "$SLEEP_BETWEEN"
  fi
  attempt=$((attempt + 1))
done

echo ""
echo "FAIL — trial API did not return status:ok after $MAX_ATTEMPTS attempts"
[ -n "${body:-}" ] && echo "Last body: $body"
exit 1
