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
test "$(plutil -extract SUFeedURL raw "$APP_BUNDLE/Contents/Info.plist")" = "$SPARKLE_FEED_URL"
test "$(plutil -extract SUPublicEDKey raw "$APP_BUNDLE/Contents/Info.plist")" = "$SPARKLE_PUBLIC_ED_KEY"
test "$(plutil -extract SUEnableAutomaticChecks raw "$APP_BUNDLE/Contents/Info.plist")" = "false"
test "$(plutil -extract SUAutomaticallyUpdate raw "$APP_BUNDLE/Contents/Info.plist")" = "false"
test -d "$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
otool -L "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME" \
  | grep -Fq '@rpath/Sparkle.framework/Versions/B/Sparkle'
otool -l "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME" \
  | grep -Fq '@executable_path/../Frameworks'
codesign --verify --deep --strict "$APP_BUNDLE"
