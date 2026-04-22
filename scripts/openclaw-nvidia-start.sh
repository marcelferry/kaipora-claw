#!/usr/bin/env bash
set -euo pipefail

export PATH="/sandbox/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export CHAT_UI_URL="${CHAT_UI_URL:-http://127.0.0.1:18789}"

echo "[openclaw-nvidia-start] CHAT_UI_URL=${CHAT_UI_URL}"

if [ ! -d "/sandbox/.openclaw" ]; then
  mkdir -p /sandbox/.openclaw
fi

openclaw onboard || true
exec openclaw gateway run