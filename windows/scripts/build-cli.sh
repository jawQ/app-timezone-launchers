#!/usr/bin/env bash
# Cross-compile ZoneLaunch Windows CLI (.exe) and package a platform-labeled zip.
# Safe to run on macOS; does not touch macOS ZoneLaunch.app.
#
# Outputs under dist/:
#   ZoneLaunch-cli-<VERSION>-windows-amd64.zip
#   ZoneLaunch-cli-<VERSION>-windows-arm64.zip  (optional second arch)
#
# Each zip extracts to a folder whose name includes the platform + arch.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINDOWS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI_DIR="$WINDOWS_DIR/cli"
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
  build-cli.sh [VERSION]

VERSION defaults to APP_VERSION, else 0.1.0.

Environment:
  ARCHS   space-separated GOARCH list (default: "amd64 arm64")
  DIST_DIR  output directory (default: <repo>/dist)
  ZIP_BIN   zip command (default: zip)

Requirements:
  Go, zip, and either shasum or sha256sum.
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

if ! command -v go >/dev/null 2>&1; then
  echo "Go is required to build the Windows CLI." >&2
  exit 1
fi

DIST_DIR="$(absolute_dir "$DIST_DIR")"

ARCHS="${ARCHS:-amd64 arm64}"
CURRENT_STAGE_ROOT=""
CHECKSUM_TMP=""

cleanup() {
  if [[ -n "$CURRENT_STAGE_ROOT" ]]; then
    rm -rf "$CURRENT_STAGE_ROOT"
  fi
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
  local checksum_file="$DIST_DIR/SHA256SUMS-windows-cli.txt"
  CHECKSUM_TMP="$(mktemp "$DIST_DIR/.SHA256SUMS-windows-cli.XXXXXX")"
  if [[ -f "$checksum_file" ]]; then
    awk -v target="$file_name" '$2 != target' "$checksum_file" >"$CHECKSUM_TMP"
  fi
  write_sha256 "$file_name" >>"$CHECKSUM_TMP"
  mv "$CHECKSUM_TMP" "$checksum_file"
  CHECKSUM_TMP=""
}

echo "Running go test..."
(
  cd "$CLI_DIR"
  go test ./...
)

for arch in $ARCHS; do
  stage_name="ZoneLaunch-cli-${VERSION}-windows-${arch}"
  CURRENT_STAGE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/zl-cli-XXXXXX")"
  stage_dir="$CURRENT_STAGE_ROOT/$stage_name"
  mkdir -p "$stage_dir"

  echo "Building windows/${arch}..."
  (
    cd "$CLI_DIR"
    CGO_ENABLED=0 GOOS=windows GOARCH="$arch" go build -trimpath -ldflags="-s -w -X main.version=${VERSION}" -o "$stage_dir/zonelaunch.exe" .
  )

  # Same binary, preset names for double-click / PATH convenience.
  # (Only Feishu + WeChat by default to keep the zip small; rename zonelaunch.exe for others.)
  cp "$stage_dir/zonelaunch.exe" "$stage_dir/feishu-tz.exe"
  cp "$stage_dir/zonelaunch.exe" "$stage_dir/wechat-tz.exe"

  cat >"$stage_dir/README.txt" <<EOF
ZoneLaunch Windows CLI ${VERSION} (${arch})
============================================

Platform label: windows-${arch}
This is NOT the macOS ZoneLaunch.app (that zip ends with -macos).

Quick try (double-click or from cmd/PowerShell):
  feishu-tz.exe
  wechat-tz.exe

  zonelaunch.exe feishu
  zonelaunch.exe wechat
  zonelaunch.exe run --tz Asia/Shanghai --exe C:\\path\\to\\app.exe

Override time zone:
  set LARK_TZ=America/Los_Angeles
  feishu-tz.exe

Override app path:
  set APP_PATH=%LOCALAPPDATA%\\Feishu\\Feishu.exe
  feishu-tz.exe

  feishu-tz.exe --tz Asia/Tokyo --exe C:\\path\\to\\Feishu.exe

Notes:
  - Quit the target app first (or use --force).
  - Does not change Windows system time zone.
  - SmartScreen may warn (unsigned). Choose More info → Run anyway if you trust the build.
  - Prefer windows-amd64 on most PCs; use windows-arm64 on Snapdragon/ARM Windows.

Uninstall: delete this folder.
EOF

  zip_name="${stage_name}.zip"
  rm -f "$DIST_DIR/$zip_name"
  (
    cd "$CURRENT_STAGE_ROOT"
    "$ZIP_BIN" -r "$DIST_DIR/$zip_name" "$stage_name"
  )
  rm -rf "$CURRENT_STAGE_ROOT"
  CURRENT_STAGE_ROOT=""

  update_checksum "$zip_name"
  echo "Wrote $DIST_DIR/$zip_name"
done

echo "Done. Copy the zip that matches your PC (usually *-windows-amd64.zip)."
