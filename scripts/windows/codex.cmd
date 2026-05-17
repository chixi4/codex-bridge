@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%CODEX_BRIDGE_WSL_DISTRO%"=="" (
  set "DISTRO=Ubuntu-20.04"
) else (
  set "DISTRO=%CODEX_BRIDGE_WSL_DISTRO%"
)
set "MODE=yolo"
set "WORK=%CD%"
set "USE_TMUX=1"

if /I "%~1"=="--tmux-list" goto tmux_list
if /I "%~1"=="--tmux-kill" goto tmux_kill
if /I "%~1"=="--tmux-kill-current" goto tmux_kill_current
if /I "%~1"=="--tmux-kill-all" goto tmux_kill_all
if /I "%~1"=="--tmux-help" goto tmux_help
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
if /I "%~1"=="--tmux" set "USE_TMUX=1" & shift & goto parse
if /I "%~1"=="--no-tmux" set "USE_TMUX=0" & shift & goto parse
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
  set "WSLWORK="
  for /f "usebackq delims=" %%I in (`wsl -d %DISTRO% -- wslpath -a "!P!"`) do set "WSLWORK=%%I"
  if "!WSLWORK!"=="" (
    echo Failed to convert Windows path to WSL path: !P!
    exit /b 2
  )
)

wsl -d %DISTRO% -- bash -lc "test -d ""$1""" check "!WSLWORK!"
if errorlevel 1 (
  echo Workspace does not exist in WSL: !WSLWORK!
  exit /b 2
)

echo Starting Codex in !WSLWORK!
wsl -d %DISTRO% -- bash -lc "if command -v codex-bridge-launch >/dev/null 2>&1; then exec codex-bridge-launch ""$1"" ""$2"" ""$3""; fi; cd ""$2"" && if [ ""$1"" = yolo ]; then exec codex --dangerously-bypass-approvals-and-sandbox; elif [ ""$1"" = safe ]; then exec codex; else exec codex -a never -s danger-full-access; fi" codex "!MODE!" "!WSLWORK!" "!USE_TMUX!"
exit /b !ERRORLEVEL!

:direct
wsl -d %DISTRO% -- bash -lc "exec codex %*"
exit /b %ERRORLEVEL%

:tmux_list
wsl -d %DISTRO% -- bash -lc "exec codex-bridge-tmux list"
exit /b %ERRORLEVEL%

:tmux_kill
if "%~2"=="" (
  echo Usage: codex --tmux-kill codex_^^^^id
  exit /b 2
)
wsl -d %DISTRO% -- bash -lc "exec codex-bridge-tmux kill ""$1""" tmux "%~2"
exit /b %ERRORLEVEL%

:tmux_kill_all
wsl -d %DISTRO% -- bash -lc "exec codex-bridge-tmux kill-all"
exit /b %ERRORLEVEL%

:tmux_help
wsl -d %DISTRO% -- bash -lc "exec codex-bridge-tmux help"
exit /b %ERRORLEVEL%

:tmux_kill_current
set "P=%CD%"
if "!P:~0,1!"=="/" (
  set "WSLWORK=!P!"
) else (
  set "WSLWORK="
  for /f "usebackq delims=" %%I in (`wsl -d %DISTRO% -- wslpath -a "!P!"`) do set "WSLWORK=%%I"
  if "!WSLWORK!"=="" (
    echo Failed to convert Windows path to WSL path: !P!
    exit /b 2
  )
)
wsl -d %DISTRO% -- bash -lc "exec codex-bridge-tmux kill-current ""$1""" tmux "!WSLWORK!"
exit /b %ERRORLEVEL%
