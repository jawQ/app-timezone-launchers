#!/usr/bin/env bash
# Package Windows + WSL launchers into a platform-labeled zip for releases.
# Does not build or touch the macOS ZoneLaunch app.
#
# Output (platform suffix is mandatory):
#   dist/app-timezone-launchers-<VERSION>-windows.zip
# Top-level folder inside the zip is also platform-labeled:
#   app-timezone-launchers-<VERSION>-windows/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINDOWS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$WINDOWS_DIR/.." && pwd)"
DIST_DIR="${DIST_DIR:-$REPO_ROOT/dist}"
ZIP_BIN="${ZIP_BIN:-zip}"

absolute_dir() {
  local dir="$1"
  mkdir -p "$dir"
  (cd "$dir" && pwd -P)
}

usage() {
  cat <<'EOF'
Usage:
  package-scripts.sh [VERSION]

VERSION defaults to APP_VERSION, else git tag without leading v, else 0.1.0.

Outputs:
  $DIST_DIR/app-timezone-launchers-<VERSION>-windows.zip

Requirements:
  zip, and either shasum or sha256sum.

The zip root folder name includes "-windows" so downloads are unambiguous
even after extraction. macOS app assets remain ZoneLaunch-<VERSION>-macos.dmg / .zip.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -n "${1:-}" ]]; then
  VERSION="$1"
elif [[ -n "${APP_VERSION:-}" ]]; then
  VERSION="$APP_VERSION"
elif git -C "$REPO_ROOT" describe --tags --exact-match HEAD >/dev/null 2>&1; then
  VERSION="$(git -C "$REPO_ROOT" describe --tags --exact-match HEAD)"
  VERSION="${VERSION#v}"
else
  VERSION="0.1.0"
fi
VERSION="${VERSION#v}"

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,3}([.-][A-Za-z0-9.]+)?$ ]]; then
  echo "Invalid VERSION: $VERSION" >&2
  exit 1
fi

if ! command -v "$ZIP_BIN" >/dev/null 2>&1; then
  echo "zip command not found: $ZIP_BIN" >&2
  exit 1
fi

DIST_DIR="$(absolute_dir "$DIST_DIR")"

STAGE_NAME="app-timezone-launchers-${VERSION}-windows"
ZIP_NAME="${STAGE_NAME}.zip"
STAGE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/atl-windows-XXXXXX")"
STAGE_DIR="$STAGE_ROOT/$STAGE_NAME"
CHECKSUM_TMP=""

cleanup() {
  rm -rf "$STAGE_ROOT"
  if [[ -n "$CHECKSUM_TMP" ]]; then
    rm -f "$CHECKSUM_TMP"
  fi
}
trap cleanup EXIT

write_sha256() {
  local file_name="$1"
  if command -v shasum >/dev/null 2>&1; then
    (cd "$DIST_DIR" && shasum -a 256 "$file_name")
  elif command -v sha256sum >/dev/null 2>&1; then
    (cd "$DIST_DIR" && sha256sum "$file_name")
  else
    echo "A SHA-256 tool (shasum or sha256sum) is required." >&2
    return 1
  fi
}

update_checksum() {
  local file_name="$1"
  local checksum_file="$DIST_DIR/SHA256SUMS-windows.txt"
  CHECKSUM_TMP="$(mktemp "$DIST_DIR/.SHA256SUMS-windows.XXXXXX")"
  if [[ -f "$checksum_file" ]]; then
    awk -v target="$file_name" '$2 != target' "$checksum_file" >"$CHECKSUM_TMP"
  fi
  write_sha256 "$file_name" >>"$CHECKSUM_TMP"
  mv "$CHECKSUM_TMP" "$checksum_file"
  CHECKSUM_TMP=""
}

mkdir -p "$STAGE_DIR/bin" "$STAGE_DIR/wsl/bin" "$STAGE_DIR/docs" "$DIST_DIR"

cp -R "$WINDOWS_DIR/bin/." "$STAGE_DIR/bin/"
cp -R "$WINDOWS_DIR/wsl/bin/." "$STAGE_DIR/wsl/bin/"
cp "$WINDOWS_DIR/install.ps1" "$STAGE_DIR/install.ps1"
cp "$WINDOWS_DIR/wsl/install.sh" "$STAGE_DIR/wsl/install.sh"
chmod +x "$STAGE_DIR/wsl/install.sh" "$STAGE_DIR/wsl/bin/"* 2>/dev/null || true

# Bundled docs (optional if not yet present during partial checkout)
if [[ -d "$REPO_ROOT/docs/windows" ]]; then
  cp -R "$REPO_ROOT/docs/windows/." "$STAGE_DIR/docs/"
fi

cat >"$STAGE_DIR/README.txt" <<EOF
app-timezone-launchers ${VERSION} — Windows package
=====================================================

This archive is for Windows (native CMD/PowerShell + WSL).
It is NOT the macOS ZoneLaunch app.

Platform label: windows
macOS app downloads use: ZoneLaunch-<version>-macos.dmg (install) and ZoneLaunch-<version>-macos.zip (updater)

Native Windows (CMD / PowerShell / double-click):
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -All -AddToPath

WSL (Ubuntu, etc.):
  bash ./wsl/install.sh --all

See docs/ inside this zip, or the repository docs/windows/.
EOF

# Replace previous artifact so zip does not "update" a stale archive in place.
rm -f "$DIST_DIR/$ZIP_NAME" "$DIST_DIR/${STAGE_NAME}.tar.gz"

(
  cd "$STAGE_ROOT"
  "$ZIP_BIN" -r "$DIST_DIR/$ZIP_NAME" "$STAGE_NAME"
)

echo "Wrote $DIST_DIR/$ZIP_NAME"
update_checksum "$ZIP_NAME"
echo "Updated $DIST_DIR/SHA256SUMS-windows.txt"
