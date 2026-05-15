#!/usr/bin/env bash
set -euo pipefail

NODE_PREFIX="${NODE_PREFIX:-/opt/node-current}"
HOST_IP=$(ip route | awk '/default/ {print $3; exit}')
PROXY_PORT="${WSL_HOST_PROXY_PORT:-17898}"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo -E bash scripts/wsl/install-codex-cli.sh"
  exit 1
fi

if [[ ! -x "${NODE_PREFIX}/bin/npm" ]]; then
  echo "Node/npm not found at ${NODE_PREFIX}. Install Node first."
  exit 1
fi

export HTTP_PROXY="http://${HOST_IP}:${PROXY_PORT}"
export HTTPS_PROXY="http://${HOST_IP}:${PROXY_PORT}"
export ALL_PROXY="socks5h://${HOST_IP}:${PROXY_PORT}"

"${NODE_PREFIX}/bin/npm" install -g @openai/codex
ln -sf "${NODE_PREFIX}/bin/codex" /usr/local/bin/codex-raw
install -m 0755 "$(dirname "$0")/codex" /usr/local/bin/codex
install -m 0755 "$(dirname "$0")/win-net-check" /usr/local/bin/win-net-check

codex --version
