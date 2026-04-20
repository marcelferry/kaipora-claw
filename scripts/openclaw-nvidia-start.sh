#!/usr/bin/env bash
set -euo pipefail

# Minimal custom adaptation of NVIDIA's openclaw-nvidia-start behavior.
# Keeps the upstream invocation pattern:
#   1. optionally use CHAT_UI_URL
#   2. run openclaw onboard
#   3. run openclaw gateway
#
# This script intentionally stays narrow and preserves user customizations.

export CHAT_UI_URL="${CHAT_UI_URL:-http://127.0.0.1:18789}"

echo "[openclaw-nvidia-start] CHAT_UI_URL=${CHAT_UI_URL}"

if [ ! -d "/sandbox/.openclaw" ]; then
  mkdir -p /sandbox/.openclaw
fi

openclaw onboard || true
exec openclaw gateway run
