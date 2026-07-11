#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=app-identity.sh
source "$PROJECT_DIR/scripts/app-identity.sh"

INSTALL_DIR="$(mktemp -d /tmp/ZoneLaunch-install-test.XXXXXX)"
TARGET_APP="$INSTALL_DIR/$APP_NAME.app"
LEGACY_BUILD_APP="$PROJECT_DIR/build/$APP_NAME.app"
SOURCE_APP="$PROJECT_DIR/.build/app/$APP_NAME.app"
LSREGISTER_LOG="$INSTALL_DIR/lsregister.log"
LSREGISTER_RECORDER="$INSTALL_DIR/lsregister-recorder"
LEGACY_NAMED_APP="$INSTALL_DIR/App Timezone Launcher.app"
LEGACY_ID_APP="$INSTALL_DIR/OldZoneLaunch.app"
DUPLICATE_CANONICAL_APP="$INSTALL_DIR/ZoneLaunch Copy.app"

cleanup() {
  rm -rf "$INSTALL_DIR"
}
trap cleanup EXIT

"$PROJECT_DIR/scripts/build-app.sh"

# Stale resource on the install target path must be replaced.
mkdir -p "$TARGET_APP/Contents/Resources"
touch "$TARGET_APP/Contents/Resources/stale-resource"

# Prior product name under the install prefix (dual-icon source).
mkdir -p "$LEGACY_NAMED_APP/Contents"
cat >"$LEGACY_NAMED_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>io.github.jawq.zonelaunch</string>
  <key>CFBundleName</key>
  <string>App Timezone Launcher</string>
</dict>
</plist>
PLIST

# Same legacy Bundle ID under another path (identity migration dual-icon source).
mkdir -p "$LEGACY_ID_APP/Contents"
cat >"$LEGACY_ID_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>io.github.jawq.zonelaunch</string>
  <key>CFBundleName</key>
  <string>ZoneLaunch</string>
</dict>
</plist>
PLIST

# Second copy already on the canonical ID but wrong path.
mkdir -p "$DUPLICATE_CANONICAL_APP/Contents"
cat >"$DUPLICATE_CANONICAL_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>$CANONICAL_BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
</dict>
</plist>
PLIST

cat >"$LSREGISTER_RECORDER" <<EOF
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "\$*" >>"$LSREGISTER_LOG"
EOF
chmod +x "$LSREGISTER_RECORDER"

INSTALL_DIR="$INSTALL_DIR" \
  LSREGISTER="$LSREGISTER_RECORDER" \
  REFRESH_LAUNCH_SERVICES=1 \
  "$PROJECT_DIR/scripts/install-app.sh"

test -d "$TARGET_APP"
test ! -e "$TARGET_APP/Contents/Resources/stale-resource"
test ! -e "$LEGACY_NAMED_APP"
test ! -e "$LEGACY_ID_APP"
test ! -e "$DUPLICATE_CANONICAL_APP"
test "$(plutil -extract CFBundleIdentifier raw "$TARGET_APP/Contents/Info.plist")" = "$CANONICAL_BUNDLE_ID"
codesign --verify --deep --strict "$TARGET_APP"

# LaunchServices must unregister known dual-icon sources, then force-register once and GC.
# Use -- so patterns that start with -u/-f are not treated as grep options.
grep -Fxq -- "-u $LEGACY_BUILD_APP" "$LSREGISTER_LOG"
grep -Fxq -- "-u $SOURCE_APP" "$LSREGISTER_LOG"
grep -Fxq -- "-u $TARGET_APP" "$LSREGISTER_LOG"
grep -Fxq -- "-u $LEGACY_NAMED_APP" "$LSREGISTER_LOG"
grep -Fxq -- "-u $LEGACY_ID_APP" "$LSREGISTER_LOG"
grep -Fxq -- "-u $DUPLICATE_CANONICAL_APP" "$LSREGISTER_LOG"
grep -Fxq -- "-f $TARGET_APP" "$LSREGISTER_LOG"
grep -Fxq -- "-gc" "$LSREGISTER_LOG"

# Force-register must happen after the last unregister of the target path.
last_unregister_line="$(grep -n -F -- "-u $TARGET_APP" "$LSREGISTER_LOG" | tail -1 | cut -d: -f1)"
force_register_line="$(grep -n -F -- "-f $TARGET_APP" "$LSREGISTER_LOG" | tail -1 | cut -d: -f1)"
gc_line="$(grep -n -F -- "-gc" "$LSREGISTER_LOG" | tail -1 | cut -d: -f1)"
test "$last_unregister_line" -lt "$force_register_line"
test "$force_register_line" -lt "$gc_line"
