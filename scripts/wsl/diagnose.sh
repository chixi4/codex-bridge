#!/usr/bin/env bash
set -euo pipefail

echo "WSL diagnosis"
echo "============="
echo
echo "-- System"
uname -a
echo
echo "-- Default gateway"
ip route | sed -n '1,5p'
echo
echo "-- DNS"
cat /etc/resolv.conf
echo
echo "-- Codex"
command -v codex || true
codex --version || true
echo
echo "-- Network"
win-net-check || true
