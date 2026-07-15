#!/usr/bin/env bash
# Verify Windows package naming, output paths, checksums, and cleanup.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_SCRIPT="$ROOT/scripts/package-scripts.sh"
CLI_SCRIPT="$ROOT/scripts/build-cli.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/atl-package-test-XXXXXX")"
DIST_DIR="$TMP_ROOT/dist"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

fail() {
  echo "FAIL $*" >&2
  exit 1
}

verify_checksum() {
  local directory="$1" checksum_file="$2"
  if command -v shasum >/dev/null 2>&1; then
    (cd "$directory" && shasum -a 256 -c "$checksum_file") >/dev/null
  elif command -v sha256sum >/dev/null 2>&1; then
    (cd "$directory" && sha256sum -c "$checksum_file") >/dev/null
  else
    fail "no SHA-256 verification tool found"
  fi
}

DIST_DIR="$DIST_DIR" "$PACKAGE_SCRIPT" 0.0.0-test >/dev/null

ZIP="$DIST_DIR/app-timezone-launchers-0.0.0-test-windows.zip"
[[ -f "$ZIP" ]] || fail "no platform-labeled package in $DIST_DIR"
echo "OK  zip name has -windows: $(basename "$ZIP")"

if command -v zipinfo >/dev/null 2>&1; then
  top="$(zipinfo -1 "$ZIP" | sed -n '1p')"
else
  top="$(unzip -Z1 "$ZIP" 2>/dev/null | sed -n '1p')"
fi
[[ "$top" == "app-timezone-launchers-0.0.0-test-windows/" ]] \
  || fail "unexpected zip top-level entry: $top"
echo "OK  zip top-level platform label: $top"

CHECKSUMS="$DIST_DIR/SHA256SUMS-windows.txt"
[[ -f "$CHECKSUMS" ]] || fail "missing scripts checksum"
verify_checksum "$DIST_DIR" "$(basename "$CHECKSUMS")"
echo "OK  scripts checksum verifies"

if ! unzip -p "$ZIP" "app-timezone-launchers-0.0.0-test-windows/docs/wsl.md" \
  | grep -Fq "bash ./wsl/install.sh"; then
  fail "bundled WSL guide does not contain the release-archive install path"
fi
echo "OK  bundled WSL guide uses release-archive path"

# Rebuilding the same file replaces its checksum entry instead of appending.
DIST_DIR="$DIST_DIR" "$PACKAGE_SCRIPT" 0.0.0-test >/dev/null
[[ "$(awk '$2 == "app-timezone-launchers-0.0.0-test-windows.zip" { count++ } END { print count + 0 }' "$CHECKSUMS")" == "1" ]] \
  || fail "duplicate checksum entry after same-version rebuild"
echo "OK  same-version scripts checksum is replaced"

# A relative DIST_DIR is resolved from the caller's working directory.
CALLER_DIR="$TMP_ROOT/caller"
mkdir -p "$CALLER_DIR"
(
  cd "$CALLER_DIR"
  DIST_DIR="relative-dist" "$PACKAGE_SCRIPT" 0.0.1-test >/dev/null
)
[[ -f "$CALLER_DIR/relative-dist/app-timezone-launchers-0.0.1-test-windows.zip" ]] \
  || fail "relative DIST_DIR was not resolved from caller directory"
echo "OK  relative scripts DIST_DIR"

# Missing zip fails before staging and does not claim a tar fallback.
MISSING_DIST="$TMP_ROOT/missing-dist"
if ZIP_BIN="atl-no-such-zip" DIST_DIR="$MISSING_DIST" "$PACKAGE_SCRIPT" 0.0.2-test >/dev/null 2>&1; then
  fail "missing zip command unexpectedly succeeded"
fi
[[ ! -e "$MISSING_DIST" ]] || fail "missing zip command created output directory"
echo "OK  missing zip fails before staging"

# A zip process failure removes its staging directory.
FAIL_ZIP="$TMP_ROOT/fail-zip"
cat >"$FAIL_ZIP" <<'EOF'
#!/usr/bin/env bash
exit 42
EOF
chmod +x "$FAIL_ZIP"
mkdir -p "$TMP_ROOT/stages"
if TMPDIR="$TMP_ROOT/stages" ZIP_BIN="$FAIL_ZIP" DIST_DIR="$TMP_ROOT/fail-dist" \
  "$PACKAGE_SCRIPT" 0.0.3-test >/dev/null 2>&1; then
  fail "failing zip command unexpectedly succeeded"
fi
[[ -z "$(find "$TMP_ROOT/stages" -maxdepth 1 -name 'atl-windows-*' -print -quit)" ]] \
  || fail "scripts staging directory leaked after zip failure"
echo "OK  scripts staging cleanup after zip failure"

# Guard: never emit unlabeled ZoneLaunch.zip from this script
if ls "$DIST_DIR"/ZoneLaunch.zip >/dev/null 2>&1; then
  fail "unlabeled ZoneLaunch.zip must not be produced"
fi

# CLI packaging also fails before creating output when zip is unavailable.
CLI_MISSING_DIST="$TMP_ROOT/cli-missing-dist"
if ZIP_BIN="atl-no-such-zip" DIST_DIR="$CLI_MISSING_DIST" "$CLI_SCRIPT" 0.0.4-test >/dev/null 2>&1; then
  fail "missing CLI zip command unexpectedly succeeded"
fi
[[ ! -e "$CLI_MISSING_DIST" ]] || fail "missing CLI zip command created output directory"
echo "OK  missing CLI zip fails before staging"

if command -v go >/dev/null 2>&1; then
  CLI_CALLER="$TMP_ROOT/cli-caller"
  mkdir -p "$CLI_CALLER"
  (
    cd "$CLI_CALLER"
    ARCHS=amd64 DIST_DIR="relative-cli-dist" "$CLI_SCRIPT" 0.0.4-test >/dev/null
    ARCHS=amd64 DIST_DIR="relative-cli-dist" "$CLI_SCRIPT" 0.0.4-test >/dev/null
  )
  CLI_DIST="$CLI_CALLER/relative-cli-dist"
  CLI_ZIP="$CLI_DIST/ZoneLaunch-cli-0.0.4-test-windows-amd64.zip"
  CLI_CHECKSUMS="$CLI_DIST/SHA256SUMS-windows-cli.txt"
  [[ -f "$CLI_ZIP" ]] || fail "relative CLI DIST_DIR did not receive zip"
  [[ "$(awk '$2 == "ZoneLaunch-cli-0.0.4-test-windows-amd64.zip" { count++ } END { print count + 0 }' "$CLI_CHECKSUMS")" == "1" ]] \
    || fail "duplicate CLI checksum entry after same-version rebuild"
  verify_checksum "$CLI_DIST" "$(basename "$CLI_CHECKSUMS")"
  echo "OK  relative CLI DIST_DIR and checksum replacement"

  mkdir -p "$TMP_ROOT/cli-stages"
  if TMPDIR="$TMP_ROOT/cli-stages" ZIP_BIN="$FAIL_ZIP" ARCHS=amd64 \
    DIST_DIR="$TMP_ROOT/cli-fail-dist" "$CLI_SCRIPT" 0.0.5-test >/dev/null 2>&1; then
    fail "failing CLI zip command unexpectedly succeeded"
  fi
  [[ -z "$(find "$TMP_ROOT/cli-stages" -maxdepth 1 -name 'zl-cli-*' -print -quit)" ]] \
    || fail "CLI staging directory leaked after zip failure"
  echo "OK  CLI staging cleanup after zip failure"
else
  echo "SKIP CLI packaging checks (go not found)"
fi

echo "All Windows packaging checks passed."
