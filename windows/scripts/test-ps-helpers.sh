#!/usr/bin/env bash
# Structural + optional PowerShell tests for windows/bin helpers.
# Runs on macOS/Linux without PowerShell for source checks; runs Expand /
# Force unit tests when pwsh is available.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/bin"
LIB="$BIN/_lib.ps1"
PASS=0
FAIL=0

assert_file_contains() {
  local label="$1" file="$2" text="$3"
  if grep -Fq -- "$text" "$file"; then
    echo "OK  $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL $label (missing text: $text)" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_file_not_contains() {
  local label="$1" file="$2" text="$3"
  if grep -Fq -- "$text" "$file"; then
    echo "FAIL $label (unexpected text: $text)" >&2
    FAIL=$((FAIL + 1))
  else
    echo "OK  $label"
    PASS=$((PASS + 1))
  fi
}

# Shared lib API
assert_file_contains "_lib has Expand-CandidatePaths" "$LIB" "function Expand-CandidatePaths"
assert_file_contains "_lib has Test-ForceLaunchRequested" "$LIB" "function Test-ForceLaunchRequested"
assert_file_contains "_lib Force message" "$LIB" "ZONELAUNCH_FORCE=1"
assert_file_contains "_lib mtime sort" "$LIB" "LastWriteTime"

# Slack: empty LOCALAPPDATA guard + expand helper + Force
assert_file_contains "slack-tz guards LOCALAPPDATA" "$BIN/slack-tz.ps1" 'if ($local)'
assert_file_contains "slack-tz uses Expand-CandidatePaths" "$BIN/slack-tz.ps1" "Expand-CandidatePaths"
assert_file_contains "slack-tz passes -Force" "$BIN/slack-tz.ps1" '-Force:$Force'
assert_file_not_contains "slack-tz no bare Join-Path on empty local" "$BIN/slack-tz.ps1" \
  "(Join-Path \$local 'slack\\slack.exe')"

# Other launchers expose -Force
for name in feishu-tz wechat-tz line-tz; do
  assert_file_contains "$name has Force param" "$BIN/$name.ps1" '[switch] $Force'
  assert_file_contains "$name passes Force" "$BIN/$name.ps1" '-Force:$Force'
done

# install.ps1 dual-path WSL tip + single _lib copy
assert_file_contains "install dual WSL tip (clone)" "$ROOT/install.ps1" "windows/wsl/install.sh"
assert_file_contains "install dual WSL tip (zip)" "$ROOT/install.ps1" "bash ./wsl/install.sh"
# _lib should be copied once at top level, not dual-branch inside Install-Launcher
if grep -n '_lib.ps1' "$ROOT/install.ps1" | grep -q 'if (-not (Test-Path'; then
  echo "FAIL install.ps1 still has branched _lib.ps1 copy" >&2
  FAIL=$((FAIL + 1))
else
  echo "OK  install.ps1 single-path _lib copy"
  PASS=$((PASS + 1))
fi

# Optional live PowerShell tests
if command -v pwsh >/dev/null 2>&1; then
  TMP="$(mktemp -d "${TMPDIR:-/tmp}/atl-ps-test-XXXXXX")"
  trap 'rm -rf "$TMP"' EXIT

  # Newest wildcard match by mtime
  mkdir -p "$TMP/app-1" "$TMP/app-2"
  echo old >"$TMP/app-1/slack.exe"
  echo new >"$TMP/app-2/slack.exe"
  # app-2 newer
  touch -t 202001010101 "$TMP/app-1/slack.exe"
  touch -t 202501010101 "$TMP/app-2/slack.exe"

  out="$(
    pwsh -NoProfile -Command "
      . '$LIB'
      \$paths = Expand-CandidatePaths -Candidates @('$TMP/app-*/slack.exe')
      if (\$paths.Count -lt 1) { exit 2 }
      Write-Output \$paths[0]
    "
  )"
  if [[ "$out" == *"/app-2/slack.exe" ]]; then
    echo "OK  Expand-CandidatePaths picks newest (pwsh)"
    PASS=$((PASS + 1))
  else
    echo "FAIL Expand-CandidatePaths newest (got: $out)" >&2
    FAIL=$((FAIL + 1))
  fi

  force_out="$(
    pwsh -NoProfile -Command "
      . '$LIB'
      if (Test-ForceLaunchRequested -Force) { 'force-switch' }
      \$env:ZONELAUNCH_FORCE = '1'
      if (Test-ForceLaunchRequested) { 'force-env' }
      \$env:ZONELAUNCH_FORCE = '0'
      if (-not (Test-ForceLaunchRequested)) { 'force-off' }
    "
  )"
  if [[ "$force_out" == *force-switch* && "$force_out" == *force-env* && "$force_out" == *force-off* ]]; then
    echo "OK  Test-ForceLaunchRequested (pwsh)"
    PASS=$((PASS + 1))
  else
    echo "FAIL Test-ForceLaunchRequested (got: $force_out)" >&2
    FAIL=$((FAIL + 1))
  fi
else
  echo "SKIP pwsh not installed — live Expand/Force tests skipped"
fi

echo ""
echo "Passed: $PASS  Failed: $FAIL"
if (( FAIL > 0 )); then
  exit 1
fi
