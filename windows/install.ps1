# Install Windows timezone launchers into a user prefix (default: %USERPROFILE%\.local\bin).
# Does not modify macOS install.sh. Does not change the system time zone.
#
# Usage:
#   .\install.ps1                 # Feishu only
#   .\install.ps1 -Feishu -WeChat
#   .\install.ps1 -All
#   .\install.ps1 -Prefix "$env:USERPROFILE\.local\bin"
#   .\install.ps1 -AddToPath      # append Prefix to user PATH if missing

[CmdletBinding()]
param(
  [switch] $Feishu,
  [switch] $WeChat,
  [switch] $Slack,
  [switch] $Line,
  [switch] $All,
  [string] $Prefix = (Join-Path $env:USERPROFILE '.local\bin'),
  [switch] $AddToPath,
  [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-Usage {
  @'
Windows native launchers (PowerShell + CMD). For WSL, see windows\wsl\install.sh.

Usage:
  .\install.ps1                 Install feishu-tz only
  .\install.ps1 -Feishu         Install feishu-tz only
  .\install.ps1 -WeChat         Install wechat-tz only
  .\install.ps1 -Slack          Install slack-tz only
  .\install.ps1 -Line           Install line-tz only
  .\install.ps1 -All            Install all launchers
  .\install.ps1 -Prefix DIR     Install into DIR (default: %USERPROFILE%\.local\bin)
  .\install.ps1 -AddToPath      Add Prefix to the user PATH if not already present

Examples:
  .\install.ps1
  .\install.ps1 -All -AddToPath
  .\install.ps1 -WeChat -Prefix "$env:LOCALAPPDATA\ZoneLaunch\bin"
'@ | Write-Host
}

if ($Help) {
  Show-Usage
  exit 0
}

if ($env:OS -ne 'Windows_NT') {
  Write-Error 'This installer is for Windows only. On macOS use ./install.sh from the repo root.'
  exit 1
}

$selected = $Feishu -or $WeChat -or $Slack -or $Line -or $All
if (-not $selected) {
  $Feishu = $true
}
if ($All) {
  $Feishu = $true
  $WeChat = $true
  $Slack = $true
  $Line = $true
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir = Join-Path $ScriptDir 'bin'

if (-not (Test-Path -LiteralPath $BinDir)) {
  Write-Error "Missing bin directory: $BinDir"
  exit 1
}

$Prefix = [Environment]::ExpandEnvironmentVariables($Prefix)
$Prefix = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Prefix)
$prefixRoot = [System.IO.Path]::GetPathRoot($Prefix)
if ($prefixRoot -and $Prefix.Length -gt $prefixRoot.Length) {
  $Prefix = $Prefix.TrimEnd([char[]]@('\', '/'))
}
New-Item -ItemType Directory -Force -Path $Prefix | Out-Null

function Install-Launcher {
  param([string] $Name)

  $pairs = @(
    @{ Src = Join-Path $BinDir "$Name.ps1"; Dst = Join-Path $Prefix "$Name.ps1" },
    @{ Src = Join-Path $BinDir "$Name.cmd"; Dst = Join-Path $Prefix "$Name.cmd" }
  )

  foreach ($pair in $pairs) {
    if (-not (Test-Path -LiteralPath $pair.Src)) {
      Write-Error "Missing source: $($pair.Src)"
      exit 1
    }
    Copy-Item -LiteralPath $pair.Src -Destination $pair.Dst -Force
    Write-Host "Installed $($pair.Dst)"
  }
}

# Shared library for all .ps1 launchers (single copy, always refreshed).
Copy-Item -LiteralPath (Join-Path $BinDir '_lib.ps1') -Destination (Join-Path $Prefix '_lib.ps1') -Force

$installedLaunchers = @()
if ($Feishu) {
  Install-Launcher 'feishu-tz'
  $installedLaunchers += 'feishu-tz'
}
if ($WeChat) {
  Install-Launcher 'wechat-tz'
  $installedLaunchers += 'wechat-tz'
}
if ($Slack) {
  Install-Launcher 'slack-tz'
  $installedLaunchers += 'slack-tz'
}
if ($Line) {
  Install-Launcher 'line-tz'
  $installedLaunchers += 'line-tz'
}

if ($AddToPath) {
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not $userPath) { $userPath = '' }
  $parts = $userPath -split ';' | Where-Object { $_ -ne '' }
  $normalizedPrefix = $Prefix
  $already = $parts | Where-Object {
    $part = [Environment]::ExpandEnvironmentVariables($_)
    try {
      $partRoot = [System.IO.Path]::GetPathRoot($part)
    }
    catch {
      $partRoot = $null
    }
    if ($partRoot -and $part.Length -gt $partRoot.Length) {
      $part = $part.TrimEnd([char[]]@('\', '/'))
    }
    $part -ieq $normalizedPrefix
  }
  if (-not $already) {
    $newPath = if ($userPath.Trim() -eq '') { $normalizedPrefix } else { "$userPath;$normalizedPrefix" }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "Added to user PATH: $normalizedPrefix"
    Write-Host 'Open a new terminal for PATH changes to take effect.'
  }
  else {
    Write-Host "Prefix already on user PATH: $normalizedPrefix"
  }
}

Write-Host ''
Write-Host 'Done.'
Write-Host "Install prefix: $Prefix"
Write-Host ''
$exampleLauncher = $installedLaunchers[0]
Write-Host 'PowerShell:'
Write-Host "  & `"$(Join-Path $Prefix "$exampleLauncher.ps1")`""
Write-Host 'CMD / double-click:'
Write-Host "  `"$(Join-Path $Prefix "$exampleLauncher.cmd")`""
Write-Host ''
Write-Host 'WSL: from a clone run windows/wsl/install.sh; from the Windows release zip run bash ./wsl/install.sh (see docs/windows/wsl.md).'
Write-Host 'Uninstall: remove the installed *.ps1 / *.cmd / _lib.ps1 from the prefix.'
