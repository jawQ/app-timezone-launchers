# Launch Feishu/Lark on Windows with a chosen IANA TZ (child process only).
# Usage:
#   feishu-tz.ps1
#   $env:LARK_TZ = 'America/Los_Angeles'; .\feishu-tz.ps1
#   $env:APP_PATH = 'C:\path\to\Feishu.exe'; .\feishu-tz.ps1
#   .\feishu-tz.ps1 -Force
#
# Also works from CMD via feishu-tz.cmd (same environment variables).

param(
  [switch] $Force
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir '_lib.ps1')

$LarkTz = if ($env:LARK_TZ) { $env:LARK_TZ } else { 'Asia/Shanghai' }
$AppPath = $env:APP_PATH

$local = $env:LOCALAPPDATA
$pf = ${env:ProgramFiles}
$pf86 = ${env:ProgramFiles(x86)}

$defaults = @()
if ($local) {
  $defaults += Join-Path $local 'Feishu\Feishu.exe'
  $defaults += Join-Path $local 'Lark\Lark.exe'
  $defaults += Join-Path $local 'Bytedance\Feishu\Feishu.exe'
  $defaults += Join-Path $local 'LarkShell\Lark.exe'
}
if ($pf) {
  $defaults += Join-Path $pf 'Feishu\Feishu.exe'
  $defaults += Join-Path $pf 'Lark\Lark.exe'
}
if ($pf86) {
  $defaults += Join-Path $pf86 'Feishu\Feishu.exe'
  $defaults += Join-Path $pf86 'Lark\Lark.exe'
}

$exe = Resolve-AppExecutable -AppPath $AppPath -DefaultCandidates $defaults -RelativeExeNames @('Feishu.exe', 'Lark.exe')

if (-not $exe) {
  Write-Host 'Executable not found for Feishu/Lark.' -ForegroundColor Red
  Write-Host 'Set APP_PATH to the full path of Feishu.exe or Lark.exe.' -ForegroundColor Yellow
  Write-Host 'Example (CMD): set APP_PATH=%LOCALAPPDATA%\Feishu\Feishu.exe' -ForegroundColor Yellow
  exit 1
}

Invoke-TimezoneLauncher `
  -DisplayName 'Feishu/Lark' `
  -Timezone $LarkTz `
  -ExecutablePath $exe `
  -RunningProcessNames @('Feishu', 'Lark', 'LarkShell') `
  -AppPathHint 'APP_PATH' `
  -Force:$Force
