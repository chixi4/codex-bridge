$ErrorActionPreference = "Stop"

$Bin = "$env:USERPROFILE\bin"
New-Item -ItemType Directory -Force -Path $Bin | Out-Null

$Source = Join-Path $PSScriptRoot "codex.cmd"
$Target = Join-Path $Bin "codex.cmd"
$LegacyTarget = Join-Path $env:USERPROFILE "codex.cmd"
Copy-Item -Force $Source $Target
Copy-Item -Force $Source (Join-Path $Bin "cx.cmd")
Copy-Item -Force $Source $LegacyTarget

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (($UserPath -split ";") -notcontains $Bin) {
  [Environment]::SetEnvironmentVariable("Path", ($UserPath.TrimEnd(";") + ";" + $Bin), "User")
}

Write-Host "Installed $Target"
Write-Host "Updated legacy shim $LegacyTarget"
Write-Host "Open a new cmd, cd to a project, then run: codex"
