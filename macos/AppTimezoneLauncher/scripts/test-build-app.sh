#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$PROJECT_DIR/.build/app/ZoneLaunch.app"
LEGACY_APP_BUNDLE="$PROJECT_DIR/build/ZoneLaunch.app"

mkdir -p "$LEGACY_APP_BUNDLE"
touch "$LEGACY_APP_BUNDLE/legacy-resource"
"$PROJECT_DIR/scripts/build-app.sh"

test ! -e "$LEGACY_APP_BUNDLE"
test "$(plutil -extract CFBundleIdentifier raw "$APP_BUNDLE/Contents/Info.plist")" = "io.github.jawq.zonelaunch"
test "$(plutil -extract CFBundleName raw "$APP_BUNDLE/Contents/Info.plist")" = "ZoneLaunch"
codesign --verify --deep --strict "$APP_BUNDLE"
