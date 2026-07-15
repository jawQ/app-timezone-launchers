@echo off
setlocal
REM CMD / double-click entry for Slack timezone launcher.
REM Env: SLACK_TZ, APP_PATH
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0slack-tz.ps1" %*
exit /b %ERRORLEVEL%
