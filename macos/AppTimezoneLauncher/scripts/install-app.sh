#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="ZoneLaunch"
SOURCE_APP="$PROJECT_DIR/.build/app/$APP_NAME.app"
LEGACY_BUILD_APP="$PROJECT_DIR/build/$APP_NAME.app"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
TARGET_APP="$INSTALL_DIR/$APP_NAME.app"

if [[ -z "${REFRESH_LAUNCH_SERVICES+x}" ]]; then
  REFRESH_LAUNCH_SERVICES=0
  if [[ "$INSTALL_DIR" == "/Applications" ]]; then
    REFRESH_LAUNCH_SERVICES=1
  fi
fi

test -d "$SOURCE_APP"
mkdir -p "$INSTALL_DIR"

if [[ "$REFRESH_LAUNCH_SERVICES" == "1" ]]; then
  LSREGISTER="${LSREGISTER:-$(find /System/Library/Frameworks/CoreServices.framework -path '*lsregister' -type f -print -quit)}"
  "$LSREGISTER" -u "$LEGACY_BUILD_APP" || true
  "$LSREGISTER" -u "$SOURCE_APP" || true
  "$LSREGISTER" -u "$TARGET_APP"
fi

rm -rf "$TARGET_APP"
ditto "$SOURCE_APP" "$TARGET_APP"
codesign --verify --deep --strict "$TARGET_APP"

if [[ "$REFRESH_LAUNCH_SERVICES" == "1" ]]; then
  "$LSREGISTER" -f "$TARGET_APP"
  "$LSREGISTER" -gc
fi

if [[ "$INSTALL_DIR" == "/Applications" ]]; then
  killall Dock
fi

echo "Installed: $TARGET_APP"
