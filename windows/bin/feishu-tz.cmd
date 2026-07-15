@echo off
setlocal
REM CMD / double-click entry for Feishu/Lark timezone launcher.
REM Env: LARK_TZ, APP_PATH (same as PowerShell script).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0feishu-tz.ps1" %*
exit /b %ERRORLEVEL%
