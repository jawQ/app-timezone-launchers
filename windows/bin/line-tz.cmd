@echo off
setlocal
REM CMD / double-click entry for LINE timezone launcher.
REM Env: LINE_TZ, APP_PATH
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0line-tz.ps1" %*
exit /b %ERRORLEVEL%
