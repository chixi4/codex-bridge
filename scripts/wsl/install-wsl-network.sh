#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo bash scripts/wsl/install-wsl-network.sh"
  exit 1
fi

install -m 0755 "$ROOT/scripts/wsl/codex" /usr/local/bin/codex
install -m 0755 "$ROOT/scripts/wsl/win-net-check" /usr/local/bin/win-net-check

if [[ -x /opt/node-current/bin/codex ]]; then
  ln -sf /opt/node-current/bin/codex /usr/local/bin/codex-raw
fi

install -m 0644 "$ROOT/config/wsl/wsl.conf" /etc/wsl.conf
install -m 0644 "$ROOT/config/wsl/resolv.conf.example" /etc/resolv.conf

echo "Installed WSL proxy wrapper and DNS config."
echo "Restart WSL from Windows if /etc/wsl.conf changed: wsl --shutdown"
