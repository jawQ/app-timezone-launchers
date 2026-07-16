# Canonical ZoneLaunch app identity — single source of truth for build and install.
# Every release and every machine that builds from this repository must use the same
# Bundle ID. Do not substitute personal, GitHub-user, or local-development identifiers.
#
# shellcheck shell=bash

APP_NAME="ZoneLaunch"
BINARY_NAME="AppTimezoneLauncher"
CANONICAL_BUNDLE_ID="app.zonelaunch.launcher"
SPARKLE_FEED_URL="https://github.com/jawQ/app-timezone-launchers/releases/latest/download/appcast-macos.xml"
SPARKLE_PUBLIC_ED_KEY="GZWEU8WkRUQIvVCvNyHesU5T7ccsIJ+6kprkjnpCHK4="
SPARKLE_KEY_ACCOUNT="app.zonelaunch.launcher"

# Prior identities that install-app.sh must purge so LaunchServices keeps one Dock entry.
LEGACY_BUNDLE_IDS=(
  "io.github.jawq.zonelaunch"
)

# Prior .app directory basenames that must not remain under the install prefix.
LEGACY_APP_BUNDLE_NAMES=(
  "App Timezone Launcher.app"
)
