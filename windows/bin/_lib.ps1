# Shared helpers for Windows timezone launchers.
# Dot-sourced by feishu-tz.ps1, wechat-tz.ps1, etc.
# Requires Windows PowerShell 5.1+ or PowerShell 7+.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-FirstExistingPath {
  param(
    [Parameter(Mandatory = $true)]
    [string[]] $Candidates
  )
  foreach ($candidate in $Candidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
    $expanded = [Environment]::ExpandEnvironmentVariables($candidate)
    if (Test-Path -LiteralPath $expanded -PathType Leaf) {
      return (Resolve-Path -LiteralPath $expanded).Path
    }
  }
  return $null
}

function Expand-CandidatePaths {
  <#
  .SYNOPSIS
    Expand candidate paths; wildcard globs prefer newest LastWriteTime
    (FullName descending as a stable tie-break), matching Go firstExisting.
  #>
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [string[]] $Candidates
  )
  $resolved = New-Object System.Collections.Generic.List[string]
  foreach ($pattern in $Candidates) {
    if ([string]::IsNullOrWhiteSpace($pattern)) { continue }
    $expanded = [Environment]::ExpandEnvironmentVariables($pattern)
    if ($expanded -match '\*') {
      $items = @(Get-Item -Path $expanded -ErrorAction SilentlyContinue |
        Where-Object { -not $_.PSIsContainer } |
        Sort-Object `
          @{ Expression = 'LastWriteTime'; Descending = $true }, `
          @{ Expression = 'FullName'; Descending = $true })
      foreach ($item in $items) {
        $resolved.Add($item.FullName)
      }
    }
    else {
      $resolved.Add($expanded)
    }
  }
  return , $resolved.ToArray()
}

function Test-ForceLaunchRequested {
  param([switch] $Force)
  if ($Force) { return $true }
  $v = $env:ZONELAUNCH_FORCE
  if ([string]::IsNullOrWhiteSpace($v)) { return $false }
  return $v -match '^(?i:1|true|yes|on)$'
}

function Test-ProcessNamesRunning {
  param(
    [Parameter(Mandatory = $true)]
    [string[]] $ProcessNames
  )
  foreach ($name in $ProcessNames) {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($null -ne $procs -and @($procs).Count -gt 0) {
      return $true
    }
  }
  return $false
}

function Start-ProcessWithTimezone {
  <#
  .SYNOPSIS
    Start an executable with TZ injected into the child process only.
  .NOTES
    Does not change the Windows system time zone.
    UseShellExecute must be false so EnvironmentVariables is applied.
  #>
  param(
    [Parameter(Mandatory = $true)]
    [string] $FilePath,

    [Parameter(Mandatory = $true)]
    [string] $Timezone,

    [string[]] $ArgumentList = @(),

    [string] $WorkingDirectory = $null
  )

  if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
    throw "Executable not found: $FilePath"
  }

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $FilePath
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $false

  if ($ArgumentList -and $ArgumentList.Count -gt 0) {
    # ProcessStartInfo.Arguments is a single string on older runtimes.
    $psi.Arguments = ($ArgumentList | ForEach-Object {
        if ($_ -match '\s') { '"{0}"' -f ($_ -replace '"', '\"') } else { $_ }
      }) -join ' '
  }

  if ($WorkingDirectory) {
    $psi.WorkingDirectory = $WorkingDirectory
  }
  else {
    $psi.WorkingDirectory = Split-Path -Parent $FilePath
  }

  # Copy current environment, then override TZ for the child only.
  $machineEnv = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Machine)
  $userEnv = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User)
  $processEnv = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process)

  foreach ($key in $machineEnv.Keys) {
    try { $psi.EnvironmentVariables[$key] = [string]$machineEnv[$key] } catch { }
  }
  foreach ($key in $userEnv.Keys) {
    try { $psi.EnvironmentVariables[$key] = [string]$userEnv[$key] } catch { }
  }
  foreach ($key in $processEnv.Keys) {
    try { $psi.EnvironmentVariables[$key] = [string]$processEnv[$key] } catch { }
  }
  $psi.EnvironmentVariables['TZ'] = $Timezone

  $proc = [System.Diagnostics.Process]::Start($psi)
  if ($null -eq $proc) {
    throw "Failed to start process: $FilePath"
  }
  return $proc
}

function Invoke-TimezoneLauncher {
  param(
    [Parameter(Mandatory = $true)]
    [string] $DisplayName,

    [Parameter(Mandatory = $true)]
    [string] $Timezone,

    [Parameter(Mandatory = $true)]
    [string] $ExecutablePath,

    [Parameter(Mandatory = $true)]
    [string[]] $RunningProcessNames,

    [string] $AppPathHint = 'APP_PATH',

    [switch] $Force
  )

  if ([string]::IsNullOrWhiteSpace($Timezone)) {
    Write-Error "Timezone is empty."
    exit 1
  }

  if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
    Write-Host "Executable not found: $ExecutablePath" -ForegroundColor Red
    Write-Host "Set $AppPathHint to the full path of the .exe (or app folder containing it)." -ForegroundColor Yellow
    exit 1
  }

  if (-not (Test-ForceLaunchRequested -Force:$Force) -and
    (Test-ProcessNamesRunning -ProcessNames $RunningProcessNames)) {
    Write-Host "$DisplayName is already running."
    Write-Host "Quit $DisplayName completely before running this command, otherwise the existing process will not pick up the new TZ value."
    Write-Host "Or pass -Force / set ZONELAUNCH_FORCE=1 to launch anyway."
    exit 2
  }

  try {
    $proc = Start-ProcessWithTimezone -FilePath $ExecutablePath -Timezone $Timezone
  }
  catch {
    Write-Host "Failed to start ${DisplayName}: $_" -ForegroundColor Red
    exit 3
  }

  Start-Sleep -Seconds 1

  try {
    $stillAlive = -not $proc.HasExited
  }
  catch {
    $stillAlive = $true
  }

  if ($stillAlive -or (Test-ProcessNamesRunning -ProcessNames $RunningProcessNames)) {
    Write-Host "Started $DisplayName with TZ=$Timezone"
    exit 0
  }

  Write-Host "$DisplayName did not stay running after launch." -ForegroundColor Red
  exit 3
}

function Resolve-AppExecutable {
  param(
    [string] $AppPath,
    [string[]] $DefaultCandidates,
    [string[]] $RelativeExeNames = @()
  )

  if ($AppPath) {
    $expanded = [Environment]::ExpandEnvironmentVariables($AppPath)
    if (Test-Path -LiteralPath $expanded -PathType Leaf) {
      return (Resolve-Path -LiteralPath $expanded).Path
    }
    if (Test-Path -LiteralPath $expanded -PathType Container) {
      foreach ($name in $RelativeExeNames) {
        $candidate = Join-Path $expanded $name
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
          return (Resolve-Path -LiteralPath $candidate).Path
        }
      }
    }
    return $expanded
  }

  return Resolve-FirstExistingPath -Candidates $DefaultCandidates
}
