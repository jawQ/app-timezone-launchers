#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=app-identity.sh
source "$PROJECT_DIR/scripts/app-identity.sh"

APP_BUNDLE="$PROJECT_DIR/.build/app/$APP_NAME.app"
LEGACY_APP_BUNDLE="$PROJECT_DIR/build/$APP_NAME.app"

mkdir -p "$LEGACY_APP_BUNDLE"
touch "$LEGACY_APP_BUNDLE/legacy-resource"
"$PROJECT_DIR/scripts/build-app.sh"

test ! -e "$LEGACY_APP_BUNDLE"
test "$(plutil -extract CFBundleIdentifier raw "$APP_BUNDLE/Contents/Info.plist")" = "$CANONICAL_BUNDLE_ID"
test "$(plutil -extract CFBundleName raw "$APP_BUNDLE/Contents/Info.plist")" = "$APP_NAME"
test "$(plutil -extract LSUIElement raw "$APP_BUNDLE/Contents/Info.plist")" = "true"
codesign --verify --deep --strict "$APP_BUNDLE"
