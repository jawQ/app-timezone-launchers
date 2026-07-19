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

## Publish a GitHub Release (recommended)

Full maintainer guide (prerequisites, all `package.json` scripts, version policy, troubleshooting):

→ **[Publishing releases](releasing.md)**

Quick start from a **clean** `master` that matches `origin/master`:

```bash
npm run release:tag:dry-run        # preview next tag
npm run release:tag                # auto patch-bump, tag, push → CI builds the zip
npm run release:tag -- 0.2.0       # explicit version
```

| Script | Purpose |
| --- | --- |
| `npm run release:tag` | Patch-bump + tag + push |
| `npm run release:tag -- X.Y.Z` | Explicit version + tag + push |
| `npm run release:tag:dry-run` | Preview only |
| `npm run release:tag:test` | Self-test |
| `npm run release:package` | Local zip only (no GitHub Release) |
| `npm run release:notes -- vX.Y.Z` | Preview bilingual release notes |

Same idea as supermarkets `pnpm miniapp:tag`. Implementation: `scripts/release-tag.sh` via root `package.json`.

## Versioned package (local only, same as CI)

```bash
npm run release:package -- 0.1.0
# or: ./macos/AppTimezoneLauncher/scripts/package-release.sh 0.1.0
```

Produces under `dist/`: `ZoneLaunch-0.1.0-macos.zip`, `ZoneLaunch-0.1.0-macos.dmg`, `SHA256SUMS` (gitignored). **Does not** create a GitHub Release.

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

- [Publishing releases](releasing.md) — `npm run release:tag` and friends
- [Install from Releases](install-from-release.md)
- [Overview](overview.md)
