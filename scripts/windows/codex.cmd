@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%CODEX_BRIDGE_WSL_DISTRO%"=="" (
  set "DISTRO=Ubuntu-20.04"
) else (
  set "DISTRO=%CODEX_BRIDGE_WSL_DISTRO%"
)
set "MODE=yolo"
set "WORK=%CD%"

if /I "%~1"=="--version" goto direct
if /I "%~1"=="-V" goto direct
if /I "%~1"=="login" goto direct
if /I "%~1"=="logout" goto direct
if /I "%~1"=="features" goto direct
if /I "%~1"=="mcp" goto direct
if /I "%~1"=="plugin" goto direct

:parse
if "%~1"=="" goto launch
if /I "%~1"=="win" shift & goto parse
if /I "%~1"=="--yolo" set "MODE=yolo" & shift & goto parse
if /I "%~1"=="yolo" set "MODE=yolo" & shift & goto parse
if /I "%~1"=="--auto" set "MODE=auto" & shift & goto parse
if /I "%~1"=="--safe" set "MODE=safe" & shift & goto parse
if /I "%~1"=="--workspace" set "WORK=%~2" & shift & shift & goto parse
if /I "%~1"=="-C" set "WORK=%~2" & shift & shift & goto parse

set "ARG=%~1"
if "!ARG!"=="." set "WORK=%CD%" & shift & goto parse
if "!ARG:~0,1!"=="/" set "WORK=%~1" & shift & goto parse
if /I "!ARG:~1,2!"==":\" set "WORK=%~1" & shift & goto parse
shift
goto parse

:launch
set "P=!WORK!"
if "!P!"=="." set "P=%CD%"
if "!P:~0,1!"=="/" (
  set "WSLWORK=!P!"
) else (
  if not "!P:~1,2!"==":\" (
    for %%I in ("!P!") do set "P=%%~fI"
  )
  set "DRIVE=!P:~0,1!"
  if /I "!DRIVE!"=="C" set "DRIVE=c"
  if /I "!DRIVE!"=="D" set "DRIVE=d"
  set "REST=!P:~3!"
  set "REST=!REST:\=/!"
  if "!REST!"=="" (
    set "WSLWORK=/mnt/!DRIVE!"
  ) else (
    set "WSLWORK=/mnt/!DRIVE!/!REST!"
  )
)

wsl -d %DISTRO% -- bash -lc "test -d ""$1""" check "!WSLWORK!"
if errorlevel 1 (
  echo Workspace does not exist in WSL: !WSLWORK!
  exit /b 2
)

echo Starting Codex in !WSLWORK!
if /I "!MODE!"=="yolo" (
  wsl -d %DISTRO% -- bash -lc "cd ""$1"" && exec codex --dangerously-bypass-approvals-and-sandbox" codex "!WSLWORK!"
  exit /b !ERRORLEVEL!
)
if /I "!MODE!"=="safe" (
  wsl -d %DISTRO% -- bash -lc "cd ""$1"" && exec codex" codex "!WSLWORK!"
  exit /b !ERRORLEVEL!
)
wsl -d %DISTRO% -- bash -lc "cd ""$1"" && exec codex -a never -s danger-full-access" codex "!WSLWORK!"
exit /b !ERRORLEVEL!

:direct
wsl -d %DISTRO% -- bash -lc "exec codex %*"
exit /b %ERRORLEVEL%
