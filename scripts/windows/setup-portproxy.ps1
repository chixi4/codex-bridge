param(
  [string]$Distro = "",
  [string]$ListenAddress = "",
  [int]$ListenPort = 17898,
  [string]$ConnectAddress = "127.0.0.1",
  [int]$ConnectPort = 17897
)

$ErrorActionPreference = "Stop"

if (-not $Distro) {
  $Distro = $env:CODEX_BRIDGE_WSL_DISTRO
}
if (-not $Distro) {
  $Distro = "Ubuntu-20.04"
}

if (-not $ListenAddress) {
  $ListenAddress = (wsl -d $Distro -- bash -lc "ip route | awk '/default/ {print `$3; exit}'").Trim()
}

netsh interface portproxy delete v4tov4 listenaddress=$ListenAddress listenport=$ListenPort 2>$null | Out-Null
netsh interface portproxy add v4tov4 listenaddress=$ListenAddress listenport=$ListenPort connectaddress=$ConnectAddress connectport=$ConnectPort
netsh interface portproxy show all
