@echo off
setlocal
set "WorkshopFilterPowerShell=pwsh.exe"
where pwsh.exe >nul 2>nul
if not errorlevel 1 goto run
set "WorkshopFilterPowerShell=%ProgramFiles%\PowerShell\7\pwsh.exe"
if exist "%WorkshopFilterPowerShell%" goto run
set "WorkshopFilterPowerShell=%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\powershell\pwsh.exe"
if exist "%WorkshopFilterPowerShell%" goto run
echo PowerShell 7 is required. Install it, then run deploy.cmd again. 1>&2
exit /b 1

:run
"%WorkshopFilterPowerShell%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" %*
exit /b %errorlevel%
