#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BIN="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/codex-bridge"
LAUNCHAGENTS="${HOME}/Library/LaunchAgents"
START=0

if [[ "${1:-}" == "--start" ]]; then
  START=1
fi

mkdir -p "$BIN" "$CONFIG_DIR" "$LAUNCHAGENTS"

install -m 0755 "$ROOT/scripts/mac/win-ssh" "$BIN/win-ssh"
install -m 0755 "$ROOT/scripts/mac/win-codex" "$BIN/win-codex"
install -m 0755 "$ROOT/scripts/mac/win-codex-login" "$BIN/win-codex-login"
install -m 0755 "$ROOT/scripts/mac/win-codex-logout" "$BIN/win-codex-logout"
install -m 0755 "$ROOT/scripts/mac/wsl-mac-proxy-tunnel.sh" "$BIN/wsl-mac-proxy-tunnel.sh"
install -m 0755 "$ROOT/scripts/mac/diagnose.sh" "$BIN/win-codex-diagnose"

if [[ ! -f "$CONFIG_DIR/env" ]]; then
  install -m 0600 "$ROOT/config.example.env" "$CONFIG_DIR/env"
fi

sed "s#__CODEX_BRIDGE_TUNNEL__#${BIN}/wsl-mac-proxy-tunnel.sh#g" \
  "$ROOT/config/launchagents/com.codex-bridge.wsl-macproxy.plist" \
  > "$LAUNCHAGENTS/com.codex-bridge.wsl-macproxy.plist"

if [[ "$START" == "1" ]]; then
  launchctl unload "$LAUNCHAGENTS/com.codex-bridge.wsl-macproxy.plist" >/dev/null 2>&1 || true
  launchctl load "$LAUNCHAGENTS/com.codex-bridge.wsl-macproxy.plist"
fi

echo "Installed Mac tools:"
echo "  $BIN/win-ssh"
echo "  $BIN/win-codex"
echo "  $BIN/wsl-mac-proxy-tunnel.sh"
echo "  $BIN/win-codex-diagnose"
echo "Config:"
echo "  $CONFIG_DIR/env"
if [[ "$START" == "1" ]]; then
  echo "LaunchAgent started."
else
  echo "LaunchAgent file installed but not started. Run again with --start when no old tunnel is using the same remote port."
fi
