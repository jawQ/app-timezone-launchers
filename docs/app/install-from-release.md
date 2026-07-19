# Install ZoneLaunch from GitHub Releases

[Simplified Chinese](install-from-release.zh-CN.md)

Download a prebuilt **ZoneLaunch.app** without cloning the repo or installing Xcode tooling for day-to-day use.

> Builds are **ad-hoc signed** (no paid Apple Developer certificate, **not notarized**). That is intentional so the project stays free to ship. **First open is almost always blocked by macOS Gatekeeper** — this is expected, not a broken download.

## Download

1. Open the latest release:  
   **https://github.com/jawQ/app-timezone-launchers/releases/latest**
2. Prefer **`ZoneLaunch-<version>-macos.dmg`** (disk image — open and drag to Applications).  
   The **`.zip`** is the same app (also used by in-app updates); use it if you prefer a plain archive.  
   Ignore **Source code** zip/tar unless you want the full repository.
3. Optional: check the checksum against `SHA256SUMS` in the same release

## Install (recommended: DMG)

1. Double-click `ZoneLaunch-*-macos.dmg` to mount the disk image.
2. Drag **ZoneLaunch** into the **Applications** shortcut on the image (or into `/Applications`).
3. Eject the disk image.
4. Open ZoneLaunch from Applications (first open is usually blocked — see below).

## Install (zip)

```bash
# Example after downloading to ~/Downloads
cd ~/Downloads
unzip ZoneLaunch-*-macos.zip
# You should see ZoneLaunch.app
```

Then either:

- Drag **ZoneLaunch.app** into **Applications**, or
- Move it in Terminal:

```bash
rm -rf /Applications/ZoneLaunch.app
mv ZoneLaunch.app /Applications/
```

Do **not** expect a double-click to work on the first try after a Release download (see below).

## Why macOS blocks the first open

| Factor | What happens |
| --- | --- |
| Downloaded from the internet | macOS marks the file with a **quarantine** flag |
| Ad-hoc signature only | No paid **Developer ID** certificate |
| Not notarized | Apple did not scan/approve the binary for Gatekeeper |

Gatekeeper shows a dialog like the one below. Moving the app into Applications does **not** clear the block. You must **allow it once** in System Settings before double-click or `open` will succeed.

![Gatekeeper dialog: “ZoneLaunch” can’t be opened — click Done, not Move to Trash](images/gatekeeper-not-opened.png)

Many free, open-source Mac apps that are not in the paid Apple Developer Program hit the same prompt. **That is not the same as “this app is malware.”**

## First open — recommended steps (current System Settings UI)

### 1. Trigger the block once

Double-click **ZoneLaunch** (from Downloads or Applications). When you see the yellow warning dialog above, click **Done** (**not** **Move to Trash**).

### 2. Allow it in Privacy & Security

1. Open **System Settings → Privacy & Security**
2. Scroll to the security section; you should see a banner like the one below
3. Click **Open Anyway**
4. Confirm again if prompted

![Privacy & Security: “ZoneLaunch” was blocked — click Open Anyway](images/gatekeeper-open-anyway.png)

After that, opening ZoneLaunch works normally.

### Alternative: right-click Open

In Finder, **Control-click** (or right-click) **ZoneLaunch** → **Open** → **Open**.  
On newer macOS versions this is sometimes not enough; you may still need **Open Anyway** above.

### Optional (advanced): clear quarantine in Terminal

Only if you trust the build (e.g. you verified `SHA256SUMS`):

```bash
xattr -dr com.apple.quarantine /Applications/ZoneLaunch.app
open /Applications/ZoneLaunch.app
```

## Will later releases ask again?

As long as builds stay **free ad-hoc signed and not notarized**, first open of a newly downloaded build will still hit this prompt.  
Only **paid Developer ID + notarization** would make double-click-and-go the default experience.

## Upgrades

From the first Sparkle-enabled release onward, ZoneLaunch checks for updates once a day. When an update is available, a small blue button appears in the main window toolbar; one click downloads the Ed25519-signed zip, verifies it, installs, and restarts. You can also open **About** from the toolbar or menu bar to see the version and check for updates manually.

If you are still on a build without the updater, replace `/Applications/ZoneLaunch.app` once more by hand. Keep a single install path so the Dock does not show two icons.

If you previously installed with `./scripts/install-app.sh` from source, that script also cleans legacy bundle IDs and duplicate registrations. For pure DMG/zip installs, deleting the old app then moving in the new one is usually enough.

## Requirements

- macOS 14 or later
- Official build Bundle ID: `app.zonelaunch.launcher`

## Uninstall

```bash
rm -rf /Applications/ZoneLaunch.app
```

User settings (timezone groups, added apps) live at:

```text
~/Library/Application Support/App Timezone Launcher/
```

Delete that directory only if you also want to clear settings.

## Prefer shell launchers?

Shell commands remain the lightest path — see the [repository README](../../README.md).

## Build from source instead

See [Build from source](build-from-source.md).
