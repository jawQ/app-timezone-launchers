# Launch Slack on Windows with a chosen IANA TZ (child process only).
# Usage:
#   slack-tz.ps1
#   $env:SLACK_TZ = 'America/Los_Angeles'; .\slack-tz.ps1
#   .\slack-tz.ps1 -Force

param(
  [switch] $Force
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir '_lib.ps1')

$SlackTz = if ($env:SLACK_TZ) { $env:SLACK_TZ } else { 'Asia/Shanghai' }
$AppPath = $env:APP_PATH

$local = $env:LOCALAPPDATA
$defaults = @()
if ($local) {
  $defaults += Join-Path $local 'slack\slack.exe'
  $defaults += Join-Path $local 'slack\app-*\slack.exe'
}

# Expand versioned Slack installs; newest by mtime (matches Go firstExisting).
$resolvedDefaults = Expand-CandidatePaths -Candidates $defaults

$exe = Resolve-AppExecutable -AppPath $AppPath -DefaultCandidates $resolvedDefaults -RelativeExeNames @('slack.exe')

if (-not $exe) {
  Write-Host 'Executable not found for Slack.' -ForegroundColor Red
  Write-Host 'Set APP_PATH to the full path of slack.exe.' -ForegroundColor Yellow
  exit 1
}

Invoke-TimezoneLauncher `
  -DisplayName 'Slack' `
  -Timezone $SlackTz `
  -ExecutablePath $exe `
  -RunningProcessNames @('slack') `
  -AppPathHint 'APP_PATH' `
  -Force:$Force
