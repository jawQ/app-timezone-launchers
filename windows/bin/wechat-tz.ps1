# Launch WeChat on Windows with a chosen IANA TZ (child process only).
# Usage:
#   wechat-tz.ps1
#   $env:WECHAT_TZ = 'Asia/Singapore'; .\wechat-tz.ps1
#   $env:APP_PATH = 'C:\path\to\WeChat.exe'; .\wechat-tz.ps1
#   .\wechat-tz.ps1 -Force

param(
  [switch] $Force
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir '_lib.ps1')

$WeChatTz = if ($env:WECHAT_TZ) { $env:WECHAT_TZ } else { 'Asia/Shanghai' }
$AppPath = $env:APP_PATH

$pf = ${env:ProgramFiles}
$pf86 = ${env:ProgramFiles(x86)}
$local = $env:LOCALAPPDATA

$roots = @()
if ($pf) { $roots += $pf }
if ($pf86) { $roots += $pf86 }
if ($local) { $roots += $local }

# Prefer WeChat paths, then Weixin (same order as before; one block per product).
$defaults = @()
foreach ($root in $roots) {
  $defaults += Join-Path $root 'Tencent\WeChat\WeChat.exe'
}
foreach ($root in $roots) {
  $defaults += Join-Path $root 'Tencent\Weixin\Weixin.exe'
}

$exe = Resolve-AppExecutable -AppPath $AppPath -DefaultCandidates $defaults -RelativeExeNames @('WeChat.exe', 'Weixin.exe')

if (-not $exe) {
  Write-Host 'Executable not found for WeChat.' -ForegroundColor Red
  Write-Host 'Set APP_PATH to the full path of WeChat.exe (or Weixin.exe).' -ForegroundColor Yellow
  exit 1
}

Invoke-TimezoneLauncher `
  -DisplayName 'WeChat' `
  -Timezone $WeChatTz `
  -ExecutablePath $exe `
  -RunningProcessNames @('WeChat', 'Weixin', 'WeChatAppEx') `
  -AppPathHint 'APP_PATH' `
  -Force:$Force
