#!/usr/bin/env bash
set -euo pipefail

CONFIG="${CODEX_BRIDGE_ENV:-$HOME/.config/codex-bridge/env}"
if [[ -f "$CONFIG" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$CONFIG"
  set +a
fi

CAMPUS_SOCKS_HOST="${CAMPUS_SOCKS_HOST:-127.0.0.1}"
CAMPUS_SOCKS_PORT="${CAMPUS_SOCKS_PORT:-11080}"
MAC_PROXY_HOST="${MAC_PROXY_HOST:-127.0.0.1}"
MAC_PROXY_PORT="${MAC_PROXY_PORT:-7897}"

echo "Mac bridge diagnosis"
echo "===================="
echo
echo "-- Local ports"
nc -zv "$CAMPUS_SOCKS_HOST" "$CAMPUS_SOCKS_PORT" || true
nc -zv "$MAC_PROXY_HOST" "$MAC_PROXY_PORT" || true
echo
echo "-- Commands"
command -v win-ssh || true
command -v win-codex || true
command -v ez4-vpn || true
echo
echo "-- LaunchAgent"
launchctl list | grep -E 'com\.(codex-bridge|win-codex|t1)\.wsl-macproxy' || true
echo
echo "-- EZ4Connect"
if command -v ez4-vpn >/dev/null 2>&1; then
  ez4-vpn status || true
else
  bash "$(dirname "$0")/ez4-vpn" status || true
fi
echo
echo "-- Remote status"
win-codex status || true
