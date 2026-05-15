#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== bash syntax =="
bash -n scripts/mac/* scripts/wsl/* scripts/check.sh

echo "== launchagent plist =="
if command -v plutil >/dev/null 2>&1; then
  plutil -lint config/launchagents/com.codex-bridge.wsl-macproxy.plist
else
  echo "plutil not available; skipping"
fi

echo "== sensitive string scan =="
if command -v rg >/dev/null 2>&1; then
  pattern='1{6}|B[o]rlorful|2[0]25040394|sk-[A-Za-z0-9]{20,}|OPENAI_API_KEY[=]|"[r]efresh_token"|"[a]ccess_token"'
  hits="$(rg -n --hidden --glob '!.git' "$pattern" . || true)"
  if [[ -n "$hits" ]]; then
    echo "$hits"
    echo "Sensitive-looking strings found; review before publishing." >&2
    exit 1
  fi
else
  echo "rg not available; skipping"
fi

echo "== done =="
