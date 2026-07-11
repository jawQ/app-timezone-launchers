#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=app-identity.sh
source "$PROJECT_DIR/scripts/app-identity.sh"

# Optional overrides for Release packaging (defaults keep local builds simple).
APP_VERSION="${APP_VERSION:-0.1.0}"
APP_BUILD="${APP_BUILD:-1}"

BUILD_ROOT="$PROJECT_DIR/.build/app"
APP_BUNDLE="$BUILD_ROOT/$APP_NAME.app"
LEGACY_APP_BUNDLE="$PROJECT_DIR/build/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$PROJECT_DIR"
swift build -c release

rm -rf "$LEGACY_APP_BUNDLE" "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$PROJECT_DIR/.build/release/$BINARY_NAME" "$MACOS_DIR/$BINARY_NAME"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

cat >"$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$BINARY_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$CANONICAL_BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP_BUNDLE"

echo "Built: $APP_BUNDLE ($CANONICAL_BUNDLE_ID v$APP_VERSION build $APP_BUILD)"

