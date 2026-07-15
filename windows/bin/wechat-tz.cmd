@echo off
setlocal
REM CMD / double-click entry for WeChat timezone launcher.
REM Env: WECHAT_TZ, APP_PATH
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0wechat-tz.ps1" %*
exit /b %ERRORLEVEL%
