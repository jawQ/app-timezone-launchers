#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=app-identity.sh
source "$PROJECT_DIR/scripts/app-identity.sh"

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

built_bundle_id="$(plutil -extract CFBundleIdentifier raw "$SOURCE_APP/Contents/Info.plist")"
if [[ "$built_bundle_id" != "$CANONICAL_BUNDLE_ID" ]]; then
  echo "Refusing to install: built Bundle ID is '$built_bundle_id', expected '$CANONICAL_BUNDLE_ID'." >&2
  echo "Rebuild with scripts/build-app.sh so identity stays strongly bound." >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"

if [[ "$REFRESH_LAUNCH_SERVICES" == "1" ]]; then
  LSREGISTER="${LSREGISTER:-$(find /System/Library/Frameworks/CoreServices.framework -path '*lsregister' -type f -print -quit)}"
fi

unregister_path() {
  local path="$1"
  if [[ "$REFRESH_LAUNCH_SERVICES" == "1" ]]; then
    # Missing paths are expected during cleanup; keep stderr quiet.
    "$LSREGISTER" -u "$path" >/dev/null 2>&1 || true
  fi
}

remove_app_bundle() {
  local path="$1"
  unregister_path "$path"
  if [[ -e "$path" ]]; then
    rm -rf "$path"
  fi
}

bundle_id_of() {
  local app="$1"
  plutil -extract CFBundleIdentifier raw "$app/Contents/Info.plist" 2>/dev/null || true
}

is_legacy_bundle_id() {
  local bid="$1"
  local legacy
  for legacy in "${LEGACY_BUNDLE_IDS[@]}"; do
    if [[ "$bid" == "$legacy" ]]; then
      return 0
    fi
  done
  return 1
}

is_product_bundle_id() {
  local bid="$1"
  [[ "$bid" == "$CANONICAL_BUNDLE_ID" ]] || is_legacy_bundle_id "$bid"
}

# True for ZoneLaunch.app, "ZoneLaunch 2.app", "ZoneLaunch 3.app", legacy product name, etc.
is_product_app_path() {
  local path="$1"
  local base
  base="$(basename "$path")"
  case "$base" in
    ZoneLaunch.app | "App Timezone Launcher.app" | ZoneLaunch\ *.app)
      return 0
      ;;
  esac
  return 1
}

# Unregister known paths that historically produced a second Dock icon.
known_paths=(
  "$LEGACY_BUILD_APP"
  "$PROJECT_DIR/build/App Timezone Launcher.app"
  "$SOURCE_APP"
  "$TARGET_APP"
  "$INSTALL_DIR/App Timezone Launcher.app"
)
for path in "${known_paths[@]}"; do
  unregister_path "$path"
done

# Drop prior product names under the install prefix (and local build tree).
for legacy_name in "${LEGACY_APP_BUNDLE_NAMES[@]}"; do
  if [[ -d "$INSTALL_DIR/$legacy_name" && "$INSTALL_DIR/$legacy_name" != "$TARGET_APP" ]]; then
    remove_app_bundle "$INSTALL_DIR/$legacy_name"
  fi
  if [[ -d "$PROJECT_DIR/build/$legacy_name" ]]; then
    remove_app_bundle "$PROJECT_DIR/build/$legacy_name"
  fi
done

# Purge install-prefix apps that still carry a legacy Bundle ID, a second copy
# of the canonical identity, or Finder-style numbered clones (ZoneLaunch 2.app).
shopt -s nullglob
for app in "$INSTALL_DIR"/*.app; do
  [[ -d "$app" ]] || continue
  [[ "$app" == "$TARGET_APP" ]] && continue

  bid="$(bundle_id_of "$app")"
  if is_product_bundle_id "$bid" || is_product_app_path "$app"; then
    remove_app_bundle "$app"
  fi
done
shopt -u nullglob

# Replace the canonical install path atomically from LaunchServices' perspective.
unregister_path "$TARGET_APP"
rm -rf "$TARGET_APP"
ditto "$SOURCE_APP" "$TARGET_APP"
codesign --verify --deep --strict "$TARGET_APP"

installed_bundle_id="$(plutil -extract CFBundleIdentifier raw "$TARGET_APP/Contents/Info.plist")"
if [[ "$installed_bundle_id" != "$CANONICAL_BUNDLE_ID" ]]; then
  echo "Installed Bundle ID mismatch: '$installed_bundle_id' (expected '$CANONICAL_BUNDLE_ID')." >&2
  exit 1
fi

# Drop every LaunchServices record for this product except the install target.
# Covers: identity migration, numbered Finder clones (ZoneLaunch 2/3.app), Trash
# ghosts, build-tree copies, Sparkle caches, and tmp paths that produce multi-icons.
unregister_stale_product_paths() {
  [[ "$REFRESH_LAUNCH_SERVICES" == "1" ]] || return 0

  local line path identifier
  path=""
  identifier=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      path:*)
        path="${line#path:}"
        # Trim leading spaces and trailing " (0x....)" token from lsregister -dump.
        path="${path#"${path%%[![:space:]]*}"}"
        path="${path%"${path##*[![:space:]]}"}"
        if [[ "$path" =~ ^(.*[[:graph:]])[[:space:]]+\(0x[0-9a-fA-F]+\)$ ]]; then
          path="${BASH_REMATCH[1]}"
        fi
        ;;
      identifier:*)
        identifier="${line#identifier:}"
        identifier="${identifier#"${identifier%%[![:space:]]*}"}"
        identifier="${identifier%"${identifier##*[![:space:]]}"}"

        if [[ -z "$path" || "$path" == "$TARGET_APP" ]]; then
          path=""
          identifier=""
          continue
        fi

        # Prefer bundle-id match (catches Trash ghosts, caches, arbitrary names).
        # Fall back to product path name match when dump omits identifier lines.
        if is_product_bundle_id "$identifier" || is_product_app_path "$path"; then
          unregister_path "$path"
        fi
        path=""
        identifier=""
        ;;
    esac
  done < <("$LSREGISTER" -dump 2>/dev/null || true)

  # Second sweep by path name only: some dump formats interleave fields oddly,
  # and numbered clones must never remain registered.
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    [[ "$path" == "$TARGET_APP" ]] && continue
    if is_product_app_path "$path"; then
      unregister_path "$path"
    fi
  done < <(
    "$LSREGISTER" -dump 2>/dev/null \
      | sed -n 's/^path:[[:space:]]*//p' \
      | sed -E 's/[[:space:]]+\(0x[0-9a-fA-F]+\)[[:space:]]*$//' \
      || true
  )
}

if [[ "$REFRESH_LAUNCH_SERVICES" == "1" ]]; then
  # Build product stays on disk for development; it must not stay registered.
  unregister_path "$SOURCE_APP"
  unregister_path "$LEGACY_BUILD_APP"
  unregister_stale_product_paths
  "$LSREGISTER" -f "$TARGET_APP" >/dev/null 2>&1
  "$LSREGISTER" -gc >/dev/null 2>&1
  # Second pass: GC can revive discovery of nearby copies; pin target only.
  unregister_stale_product_paths
  unregister_path "$SOURCE_APP"
  "$LSREGISTER" -f "$TARGET_APP" >/dev/null 2>&1
  "$LSREGISTER" -gc >/dev/null 2>&1
fi

if [[ "$INSTALL_DIR" == "/Applications" ]]; then
  killall Dock 2>/dev/null || true
fi

echo "Installed: $TARGET_APP ($CANONICAL_BUNDLE_ID)"
