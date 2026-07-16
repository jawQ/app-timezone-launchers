#!/usr/bin/env bash
# Generate the signed Sparkle feed for a ZoneLaunch GitHub Release.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PROJECT_DIR/../.." && pwd)"
# shellcheck source=app-identity.sh
source "$PROJECT_DIR/scripts/app-identity.sh"

VERSION="${1:-}"
VERSION="${VERSION#v}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: generate-appcast.sh X.Y.Z" >&2
  exit 1
fi

DIST_DIR="${DIST_DIR:-$REPO_ROOT/dist}"
ZIP_NAME="ZoneLaunch-${VERSION}-macos.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"
APPCAST_PATH="$DIST_DIR/appcast-macos.xml"
GENERATE_APPCAST="$PROJECT_DIR/.build/artifacts/sparkle/Sparkle/bin/generate_appcast"
SIGN_UPDATE="$PROJECT_DIR/.build/artifacts/sparkle/Sparkle/bin/sign_update"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ZoneLaunch-appcast.XXXXXX")"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

test -f "$ZIP_PATH"
test -x "$GENERATE_APPCAST"
test -x "$SIGN_UPDATE"
ditto "$ZIP_PATH" "$WORK_DIR/$ZIP_NAME"

args=(
  --download-url-prefix "https://github.com/jawQ/app-timezone-launchers/releases/download/v${VERSION}/"
  --full-release-notes-url "https://github.com/jawQ/app-timezone-launchers/releases/tag/v${VERSION}"
  --maximum-deltas 0
  -o "$APPCAST_PATH"
  "$WORK_DIR"
)

if [[ -n "${SPARKLE_ED25519_PRIVATE_KEY:-}" ]]; then
  printf '%s\n' "$SPARKLE_ED25519_PRIVATE_KEY" \
    | "$GENERATE_APPCAST" --ed-key-file - "${args[@]}"
else
  "$GENERATE_APPCAST" --account "$SPARKLE_KEY_ACCOUNT" "${args[@]}"
fi

xmllint --noout "$APPCAST_PATH"
grep -Fq "ZoneLaunch-${VERSION}-macos.zip" "$APPCAST_PATH"
grep -Fq 'sparkle:edSignature=' "$APPCAST_PATH"
signature="$(
  xmllint --xpath \
    'string(//*[local-name()="enclosure"]/@*[local-name()="edSignature"])' \
    "$APPCAST_PATH"
)"
test -n "$signature"

if [[ -n "${SPARKLE_ED25519_PRIVATE_KEY:-}" ]]; then
  printf '%s\n' "$SPARKLE_ED25519_PRIVATE_KEY" \
    | "$SIGN_UPDATE" --ed-key-file - --verify "$ZIP_PATH" "$signature"
else
  "$SIGN_UPDATE" --account "$SPARKLE_KEY_ACCOUNT" --verify "$ZIP_PATH" "$signature"
fi

echo "Wrote: $APPCAST_PATH"
