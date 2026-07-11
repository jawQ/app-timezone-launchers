# Install ZoneLaunch from GitHub Releases

[Simplified Chinese](install-from-release.zh-CN.md)

Download a prebuilt **ZoneLaunch.app** without cloning the repo or installing Xcode tooling for day-to-day use.

> Builds are **ad-hoc signed** (no paid Apple Developer certificate, no notarization). That is intentional so the project stays free to ship. macOS Gatekeeper may warn on first open.

## Download

1. Open the latest release:  
   **https://github.com/jawQ/app-timezone-launchers/releases/latest**
2. Download `ZoneLaunch-<version>-macos.zip`
3. Optional: check the checksum against `SHA256SUMS` in the same release

## Install

```bash
# Example after downloading to ~/Downloads
cd ~/Downloads
unzip ZoneLaunch-*-macos.zip
# You should see ZoneLaunch.app (and a short README-FIRST.txt)
```

Then either:

- Drag **ZoneLaunch.app** into **Applications**, or
- Move it in Terminal:

```bash
rm -rf /Applications/ZoneLaunch.app
mv ZoneLaunch.app /Applications/
```

Open:

```bash
open /Applications/ZoneLaunch.app
```

## First open (Gatekeeper)

Because the app is not notarized:

1. If macOS says the app **cannot be opened** / is from an unidentified developer:
   - Finder → right-click (or Control-click) **ZoneLaunch** → **Open** → confirm **Open**
2. Or: **System Settings → Privacy & Security** → allow the blocked app, then open again

This is normal for free, ad-hoc distributed Mac apps.

## After upgrading

Replace `/Applications/ZoneLaunch.app` with the new build. Prefer one install path only so you do not get two Dock icons.

If you previously installed from source with `./scripts/install-app.sh`, that script also cleans legacy Bundle IDs and duplicate registrations. For zip installs, removing the old app before moving the new one is enough in most cases.

## Requirements

- macOS 14 or later
- Bundle ID of official builds: `app.zonelaunch.launcher`

## Uninstall

```bash
rm -rf /Applications/ZoneLaunch.app
```

User configuration (time-zone groups, dropped apps) lives under:

```text
~/Library/Application Support/App Timezone Launcher/
```

Delete that folder only if you also want to wipe settings.

## Still prefer scripts?

Shell launchers remain the lightest path. See the [repository README](../../README.md).

## Build it yourself instead

See [Build from source](build-from-source.md).
