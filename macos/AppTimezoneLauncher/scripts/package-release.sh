#!/usr/bin/env bash
# Build an ad-hoc signed ZoneLaunch.zip for GitHub Releases (no paid Apple ID).
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
APP_BUNDLE="$PROJECT_DIR/.build/app/$APP_NAME.app"
VERIFY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ZoneLaunch-release-verify.XXXXXX")"

cleanup() {
  rm -rf "$VERIFY_DIR"
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
rm -f "$ZIP_PATH"

# Sparkle requires framework symlinks and executable bits to survive archiving.
# Keep the release archive app-only so the same asset works for manual and in-app updates.
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

# Verify the exact archive Sparkle and manual installers will consume.
ditto -x -k "$ZIP_PATH" "$VERIFY_DIR"
test -L "$VERIFY_DIR/$APP_NAME.app/Contents/Frameworks/Sparkle.framework/Versions/Current"
codesign --verify --deep --strict "$VERIFY_DIR/$APP_NAME.app"

(
  cd "$DIST_DIR"
  shasum -a 256 "$ZIP_NAME" >SHA256SUMS
)

echo "Wrote: $ZIP_PATH"
echo "Wrote: $DIST_DIR/SHA256SUMS"
cat "$DIST_DIR/SHA256SUMS"
