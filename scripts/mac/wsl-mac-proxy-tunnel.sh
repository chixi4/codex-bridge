#!/usr/bin/env bash
set -euo pipefail

CONFIG="${CODEX_BRIDGE_ENV:-$HOME/.config/codex-bridge/env}"
if [[ -f "$CONFIG" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$CONFIG"
  set +a
fi

REMOTE_USER="${REMOTE_USER:-administrator}"
REMOTE_HOST="${REMOTE_HOST:-10.251.1.15}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/nvidia_garlic_node05_vllm}"
CAMPUS_SOCKS_HOST="${CAMPUS_SOCKS_HOST:-127.0.0.1}"
CAMPUS_SOCKS_PORT="${CAMPUS_SOCKS_PORT:-11080}"
MAC_PROXY_HOST="${MAC_PROXY_HOST:-127.0.0.1}"
MAC_PROXY_PORT="${MAC_PROXY_PORT:-7897}"
REMOTE_FORWARD_PORT="${REMOTE_FORWARD_PORT:-17897}"

exec /usr/bin/ssh \
  -i "$SSH_KEY" \
  -N \
  -R "${REMOTE_FORWARD_PORT}:${MAC_PROXY_HOST}:${MAC_PROXY_PORT}" \
  -o ExitOnForwardFailure=yes \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/tmp/codex_bridge_known_hosts \
  -o IdentitiesOnly=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -o TCPKeepAlive=yes \
  -o ProxyCommand="/usr/bin/nc -X 5 -x ${CAMPUS_SOCKS_HOST}:${CAMPUS_SOCKS_PORT} %h %p" \
  "${REMOTE_USER}@${REMOTE_HOST}"
