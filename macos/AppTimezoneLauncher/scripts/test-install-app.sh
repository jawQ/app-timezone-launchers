#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$(mktemp -d /tmp/ZoneLaunch-install-test.XXXXXX)"
TARGET_APP="$INSTALL_DIR/ZoneLaunch.app"
LEGACY_BUILD_APP="$PROJECT_DIR/build/ZoneLaunch.app"
LSREGISTER_LOG="$INSTALL_DIR/lsregister.log"
LSREGISTER_RECORDER="$INSTALL_DIR/lsregister-recorder"

cleanup() {
  rm -rf "$INSTALL_DIR"
}
trap cleanup EXIT

"$PROJECT_DIR/scripts/build-app.sh"
mkdir -p "$TARGET_APP/Contents/Resources"
touch "$TARGET_APP/Contents/Resources/stale-resource"

cat >"$LSREGISTER_RECORDER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$1" == "-u" && "$2" == "$TARGET_APP" ]]; then
  test -d "$2"
fi

printf '%s\n' "$*" >>"$LSREGISTER_LOG"
EOF
chmod +x "$LSREGISTER_RECORDER"

INSTALL_DIR="$INSTALL_DIR" \
  LSREGISTER="$LSREGISTER_RECORDER" \
  LSREGISTER_LOG="$LSREGISTER_LOG" \
  TARGET_APP="$TARGET_APP" \
  REFRESH_LAUNCH_SERVICES=1 \
  "$PROJECT_DIR/scripts/install-app.sh"

test -d "$TARGET_APP"
test ! -e "$TARGET_APP/Contents/Resources/stale-resource"
test "$(plutil -extract CFBundleIdentifier raw "$TARGET_APP/Contents/Info.plist")" = "io.github.jawq.zonelaunch"
codesign --verify --deep --strict "$TARGET_APP"

test "$(sed -n '1p' "$LSREGISTER_LOG")" = "-u $LEGACY_BUILD_APP"
test "$(sed -n '2p' "$LSREGISTER_LOG")" = "-u $PROJECT_DIR/.build/app/ZoneLaunch.app"
test "$(sed -n '3p' "$LSREGISTER_LOG")" = "-u $TARGET_APP"
test "$(sed -n '4p' "$LSREGISTER_LOG")" = "-f $TARGET_APP"
test "$(sed -n '5p' "$LSREGISTER_LOG")" = "-gc"
