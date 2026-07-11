# Build ZoneLaunch from source

[Simplified Chinese](build-from-source.zh-CN.md)

For contributors and anyone who prefers a local build over a Release zip.

## Requirements

- macOS 14+
- Xcode Command Line Tools (or full Xcode) with Swift 6 toolchain

## Build and install into Applications

```bash
cd macos/AppTimezoneLauncher
./scripts/build-app.sh
./scripts/install-app.sh
open /Applications/ZoneLaunch.app
```

`install-app.sh`:

- Refuses a non-canonical Bundle ID
- Removes legacy IDs / old app names that caused dual Dock icons
- Registers only `/Applications/ZoneLaunch.app`

Canonical Bundle ID: **`app.zonelaunch.launcher`** (see `scripts/app-identity.sh`).

## Versioned package (same as CI)

From the repository root:

```bash
./macos/AppTimezoneLauncher/scripts/package-release.sh 0.1.0
```

Produces under `dist/`:

- `ZoneLaunch-0.1.0-macos.zip`
- `SHA256SUMS`

`dist/` is gitignored.

## Verify

```bash
cd macos/AppTimezoneLauncher
swift test
./scripts/test-build-app.sh
./scripts/test-install-app.sh
codesign --verify --deep --strict ".build/app/ZoneLaunch.app"
plutil -extract CFBundleIdentifier raw ".build/app/ZoneLaunch.app/Contents/Info.plist"
```

## See also

- [Install from Releases](install-from-release.md)
- [Overview](overview.md)
