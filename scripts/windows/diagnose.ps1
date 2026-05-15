$ErrorActionPreference = "Continue"
$Distro = $env:CODEX_BRIDGE_WSL_DISTRO
if (-not $Distro) {
  $Distro = "Ubuntu-20.04"
}

Write-Host "Windows bridge diagnosis"
Write-Host "========================"
Write-Host ""

Write-Host "-- codex"
where.exe codex
Write-Host ""

Write-Host "-- WSL"
wsl -l -v
Write-Host ""

Write-Host "-- portproxy"
netsh interface portproxy show all
Write-Host ""

Write-Host "-- WSL proxy check"
wsl -d $Distro -- bash -lc "win-net-check"
