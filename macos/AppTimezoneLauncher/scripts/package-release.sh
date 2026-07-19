#!/usr/bin/env bash
# Build ad-hoc signed ZoneLaunch release assets for GitHub Releases (no paid Apple ID).
# - ZoneLaunch-<VERSION>-macos.zip  — app-only archive (Sparkle + advanced/manual install)
# - ZoneLaunch-<VERSION>-macos.dmg  — drag-to-Applications disk image (preferred first install)
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PROJECT_DIR/../.." && pwd)"
# shellcheck source=app-identity.sh
source "$PROJECT_DIR/scripts/app-identity.sh"

usage() {
  cat <<'EOF'
Usage:
  package-release.sh [VERSION]

VERSION defaults to APP_VERSION, else the current git tag without a leading "v",
else 0.1.0.

Environment:
  APP_VERSION   marketing version written into Info.plist
  APP_BUILD     build number (default: 1, or GITHUB_RUN_NUMBER when set)
  DIST_DIR      output directory (default: <repo>/dist)

Outputs:
  $DIST_DIR/ZoneLaunch-<VERSION>-macos.zip
  $DIST_DIR/ZoneLaunch-<VERSION>-macos.dmg
  $DIST_DIR/SHA256SUMS
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

# Strip a leading v if the caller passed v0.1.0
VERSION="${VERSION#v}"

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,3}([.-][A-Za-z0-9.]+)?$ ]]; then
  echo "Invalid VERSION: $VERSION" >&2
  exit 1
fi

APP_BUILD="${APP_BUILD:-${GITHUB_RUN_NUMBER:-1}}"
DIST_DIR="${DIST_DIR:-$REPO_ROOT/dist}"
ZIP_NAME="ZoneLaunch-${VERSION}-macos.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"
DMG_NAME="ZoneLaunch-${VERSION}-macos.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
APP_BUNDLE="$PROJECT_DIR/.build/app/$APP_NAME.app"
VERIFY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ZoneLaunch-release-verify.XXXXXX")"
DMG_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/ZoneLaunch-dmg-stage.XXXXXX")"
DMG_MOUNT=""

cleanup() {
  if [[ -n "$DMG_MOUNT" && -d "$DMG_MOUNT" ]]; then
    hdiutil detach "$DMG_MOUNT" -quiet -force >/dev/null 2>&1 || true
  fi
  rm -rf "$VERIFY_DIR" "$DMG_STAGE"
}
trap cleanup EXIT

export APP_VERSION="$VERSION"
export APP_BUILD

echo "Packaging $APP_NAME $VERSION (build $APP_BUILD, id $CANONICAL_BUNDLE_ID)"
"$PROJECT_DIR/scripts/build-app.sh"

test -d "$APP_BUNDLE"
built_id="$(plutil -extract CFBundleIdentifier raw "$APP_BUNDLE/Contents/Info.plist")"
built_ver="$(plutil -extract CFBundleShortVersionString raw "$APP_BUNDLE/Contents/Info.plist")"
if [[ "$built_id" != "$CANONICAL_BUNDLE_ID" ]]; then
  echo "Bundle ID mismatch: $built_id (expected $CANONICAL_BUNDLE_ID)" >&2
  exit 1
fi
if [[ "$built_ver" != "$VERSION" ]]; then
  echo "Version mismatch: $built_ver (expected $VERSION)" >&2
  exit 1
fi
codesign --verify --deep --strict "$APP_BUNDLE"

mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH" "$DMG_PATH"

# Sparkle requires framework symlinks and executable bits to survive archiving.
# Keep the release archive app-only so the same asset works for manual and in-app updates.
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

# Verify the exact archive Sparkle and manual installers will consume.
ditto -x -k "$ZIP_PATH" "$VERIFY_DIR"
test -L "$VERIFY_DIR/$APP_NAME.app/Contents/Frameworks/Sparkle.framework/Versions/Current"
codesign --verify --deep --strict "$VERIFY_DIR/$APP_NAME.app"

# Disk image for first-time install: open DMG → drag app to Applications.
ditto "$APP_BUNDLE" "$DMG_STAGE/$APP_NAME.app"
ln -s /Applications "$DMG_STAGE/Applications"
cat >"$DMG_STAGE/Install.txt" <<EOF
ZoneLaunch ${VERSION}

Install
1. Drag ZoneLaunch into the Applications folder.
2. Eject this disk image.
3. Open ZoneLaunch from Applications.

First open (Gatekeeper)
Builds are ad-hoc signed and not notarized. macOS may block the first open.
Click Done, then: System Settings → Privacy & Security → Open Anyway.
Guide: https://github.com/jawQ/app-timezone-launchers/blob/master/docs/app/install-from-release.md

Bundle ID: ${CANONICAL_BUNDLE_ID}
EOF

hdiutil create \
  -volname "ZoneLaunch ${VERSION}" \
  -srcfolder "$DMG_STAGE" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH" >/dev/null

# Mount and verify the shipped DMG payload.
# With -mountrandom, the mount path is the last field of the last non-empty line.
attach_output="$(hdiutil attach -nobrowse -readonly -mountrandom "${TMPDIR:-/tmp}" "$DMG_PATH")"
DMG_MOUNT="$(printf '%s\n' "$attach_output" | awk 'NF { mount=$NF } END { print mount }')"
if [[ -z "$DMG_MOUNT" || ! -d "$DMG_MOUNT" ]]; then
  echo "Failed to mount DMG for verification:" >&2
  printf '%s\n' "$attach_output" >&2
  exit 1
fi
test -d "$DMG_MOUNT/$APP_NAME.app"
test -L "$DMG_MOUNT/Applications"
codesign --verify --deep --strict "$DMG_MOUNT/$APP_NAME.app"
hdiutil detach "$DMG_MOUNT" -quiet
DMG_MOUNT=""

(
  cd "$DIST_DIR"
  shasum -a 256 "$ZIP_NAME" "$DMG_NAME" >SHA256SUMS
)

echo "Wrote: $ZIP_PATH"
echo "Wrote: $DMG_PATH"
echo "Wrote: $DIST_DIR/SHA256SUMS"
cat "$DIST_DIR/SHA256SUMS"
