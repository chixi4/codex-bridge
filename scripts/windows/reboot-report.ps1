$ErrorActionPreference = "Continue"

$SinceHours = 72
if ($env:CODEX_BRIDGE_REPORT_HOURS) {
  [int]::TryParse($env:CODEX_BRIDGE_REPORT_HOURS, [ref]$SinceHours) | Out-Null
} elseif ($args.Count -ge 1) {
  [int]::TryParse($args[0], [ref]$SinceHours) | Out-Null
}
$StartTime = (Get-Date).AddHours(-1 * $SinceHours)

function Section($Name) {
  Write-Host ""
  Write-Host "== $Name =="
}

function Show-Events($Title, $Filter, $Max = 30) {
  Section $Title
  try {
    Get-WinEvent -FilterHashtable $Filter -MaxEvents $Max -ErrorAction Stop |
      Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message |
      Format-List
  } catch {
    Write-Host "No events or query failed: $($_.Exception.Message)"
  }
}

Write-Host "Windows reboot report"
Write-Host "====================="
Write-Host "Now:        $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
Write-Host "Window:     last $SinceHours hours, since $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host "Computer:   $env:COMPUTERNAME"
Write-Host "User:       $env:USERNAME"

Section "OS uptime"
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $boot = $os.LastBootUpTime
  $uptime = New-TimeSpan -Start $boot -End (Get-Date)
  [PSCustomObject]@{
    LastBootUpTime = $boot
    UptimeHours = [math]::Round($uptime.TotalHours, 2)
    Caption = $os.Caption
    Version = $os.Version
  } | Format-List
} catch {
  Write-Host "Failed: $($_.Exception.Message)"
}

Show-Events "Restart and shutdown markers" @{
  LogName = "System"
  Id = 12,41,1074,6005,6006,6008
  StartTime = $StartTime
} 60

Show-Events "BugCheck and crash markers" @{
  LogName = "System"
  Id = 1001
  StartTime = $StartTime
} 20

Show-Events "Windows Update markers" @{
  LogName = "System"
  ProviderName = "Microsoft-Windows-WindowsUpdateClient"
  Id = 19,20,21,22,25,43,44
  StartTime = $StartTime
} 40

Show-Events "NVIDIA display driver markers" @{
  LogName = "System"
  ProviderName = "nvlddmkm"
  StartTime = $StartTime
} 80

Section "Crash dumps"
try {
  Get-ChildItem "C:\Windows\Minidump" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 10 LastWriteTime, Length, Name |
    Format-Table -AutoSize
} catch {
  Write-Host "Failed: $($_.Exception.Message)"
}

Section "Live kernel reports"
try {
  Get-ChildItem "C:\Windows\LiveKernelReports" -Force -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 20 LastWriteTime, Mode, Length, Name |
    Format-Table -AutoSize
} catch {
  Write-Host "Failed: $($_.Exception.Message)"
}

Section "UpdateOrchestrator tasks"
try {
  Get-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" |
    Where-Object { $_.TaskName -match "Reboot|Schedule|Update|Maintenance|USO" } |
    Select-Object TaskName, State, TaskPath |
    Format-Table -AutoSize
} catch {
  Write-Host "Failed: $($_.Exception.Message)"
}

Section "Power wake timers"
powercfg /waketimers 2>&1

Section "Last wake"
powercfg /lastwake 2>&1

Section "Active power requests"
powercfg /requests 2>&1
