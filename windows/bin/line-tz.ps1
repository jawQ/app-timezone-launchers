# Launch LINE on Windows with a chosen IANA TZ (child process only).
# Usage:
#   line-tz.ps1
#   $env:LINE_TZ = 'Asia/Tokyo'; .\line-tz.ps1
#   .\line-tz.ps1 -Force

param(
  [switch] $Force
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir '_lib.ps1')

$LineTz = if ($env:LINE_TZ) { $env:LINE_TZ } else { 'Asia/Shanghai' }
$AppPath = $env:APP_PATH

$local = $env:LOCALAPPDATA
$pf = ${env:ProgramFiles}
$pf86 = ${env:ProgramFiles(x86)}

$defaults = @()
if ($local) {
  $defaults += Join-Path $local 'LINE\bin\LineLauncher.exe'
  $defaults += Join-Path $local 'LINE\bin\LINE.exe'
}
if ($pf) {
  $defaults += Join-Path $pf 'LINE\bin\LineLauncher.exe'
}
if ($pf86) {
  $defaults += Join-Path $pf86 'LINE\bin\LineLauncher.exe'
}

$exe = Resolve-AppExecutable -AppPath $AppPath -DefaultCandidates $defaults -RelativeExeNames @('LineLauncher.exe', 'LINE.exe')

if (-not $exe) {
  Write-Host 'Executable not found for LINE.' -ForegroundColor Red
  Write-Host 'Set APP_PATH to the full path of LineLauncher.exe or LINE.exe.' -ForegroundColor Yellow
  exit 1
}

Invoke-TimezoneLauncher `
  -DisplayName 'LINE' `
  -Timezone $LineTz `
  -ExecutablePath $exe `
  -RunningProcessNames @('LINE', 'LineLauncher') `
  -AppPathHint 'APP_PATH' `
  -Force:$Force
