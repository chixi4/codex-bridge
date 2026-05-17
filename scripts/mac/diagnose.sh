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
REMOTE_HOST="${REMOTE_HOST:-10.251.1.15}"
SSH_PROXY_MODE="${SSH_PROXY_MODE:-socks}"
MAC_PROXY_HOST="${MAC_PROXY_HOST:-127.0.0.1}"
MAC_PROXY_PORT="${MAC_PROXY_PORT:-7897}"

echo "Mac bridge diagnosis"
echo "===================="
echo
echo "-- Local ports"
echo "SSH proxy mode: ${SSH_PROXY_MODE}"
case "$SSH_PROXY_MODE" in
  direct|none|off)
    nc -zv "$REMOTE_HOST" 22 || true
    ;;
  socks|ez4|proxy)
    nc -zv "$CAMPUS_SOCKS_HOST" "$CAMPUS_SOCKS_PORT" || true
    ;;
  *)
    echo "Unknown SSH_PROXY_MODE: ${SSH_PROXY_MODE}"
    ;;
esac
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
if [[ "$SSH_PROXY_MODE" == "direct" || "$SSH_PROXY_MODE" == "none" || "$SSH_PROXY_MODE" == "off" ]]; then
  echo "Skipped for direct SSH mode."
else
  if command -v ez4-vpn >/dev/null 2>&1; then
    ez4-vpn status || true
  else
    bash "$(dirname "$0")/ez4-vpn" status || true
  fi
fi
echo
echo "-- Remote status"
win-codex status || true
