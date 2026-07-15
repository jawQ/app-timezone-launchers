# Repository Guide

[Simplified Chinese](AGENTS.zh-CN.md)

## Project structure and modules

The root `bin/` directory contains **macOS** shell launchers such as `feishu-tz` and `wechat-tz`.
`install.sh` installs them to a user-specified prefix (**Darwin only**). User-facing documentation
lives in `README.md` / `README.zh-CN.md` and modular `docs/`:

- `docs/scripts/` — macOS shell launchers (primary, lightest path on Mac)
- `docs/app/` — ZoneLaunch GUI for macOS (optional, better UX)
- `docs/windows/` — Windows native (CMD/PowerShell) + WSL helpers
- `docs/superpowers/` and `.superpowers/` — internal agent/design notes only (gitignored)

**Windows** code lives only under `windows/` (do not fold into macOS paths):

- `windows/bin/` — PowerShell + CMD launchers
- `windows/install.ps1` — native install
- `windows/wsl/` — WSL bash helpers (`run-with-tz`, `code-tz`, `docker-tz`, Win app interop)
- `windows/scripts/package-scripts.sh` — produces `app-timezone-launchers-<ver>-windows.zip`

The native macOS app is a Swift Package at `macos/AppTimezoneLauncher/`. Put reusable non-UI
logic in `Sources/AppTimezoneLauncherCore/`; SwiftUI views and view models belong in
`Sources/AppTimezoneLauncher/`. Tests live in `Tests/AppTimezoneLauncherTests/`, and icon
source files and generated resources live in `Resources/`. Do not edit `.build/` or `build/`;
both are ignored generated directories. Release zips land in `dist/` (also gitignored).

### GitHub Releases (platform-labeled assets only)

Pushing a tag matching `v*` runs `.github/workflows/release-macos-app.yml` as three jobs:
parallel macOS and Windows builds, followed by one release job that verifies and uploads all assets.
macOS builds are **ad-hoc signed** only (no Developer ID / notarization).

**Every downloadable asset or top-level extract folder must include a platform suffix**
(`-macos`, `-windows`, future `-wsl` / Windows GUI names). Never publish an unlabeled
`ZoneLaunch.zip`. Windows scripts: `npm run release:package:windows` →
`app-timezone-launchers-<version>-windows.zip`; Windows CLI builds add platform + architecture
(`ZoneLaunch-cli-<version>-windows-amd64.zip` / `-arm64.zip`).

Full maintainer guide: [`docs/app/releasing.md`](docs/app/releasing.md) (and [zh-CN](docs/app/releasing.zh-CN.md)).

**Preferred local commands** (root `package.json`, same idea as supermarkets `pnpm miniapp:tag`):

```bash
# clean tree + on master + HEAD == origin/master, then:
npm run release:tag:dry-run           # preview next tag
npm run release:tag                   # auto patch-bump, tag, push
npm run release:tag -- 0.2.0          # explicit version
npm run release:package -- 0.1.1      # local zip only (no GitHub upload)
npm run release:tag:test              # self-test
```

| Script | Purpose |
| --- | --- |
| `release:tag` | Patch-bump + annotated tag + push → CI |
| `release:tag -- X.Y.Z` | Explicit version + tag + push |
| `release:tag:dry-run` | Preview only |
| `release:tag:test` / `test:release-tag` | Helper unit checks |
| `release:package` | `package-release.sh` only (optional version arg) |
| `release:notes -- vX.Y.Z` | Preview bilingual release notes |

Underlying scripts: `./scripts/release-tag.sh`, `./scripts/generate-release-notes.sh`.  
Every release has **both** languages (separate files, no mixed prose): `docs/release-notes/vX.Y.Z-en.md`
+ `vX.Y.Z-zh.md` (or auto-generated). GH body is English; **[中文 →]** opens the Chinese Markdown page at that tag.

**VS Code / Cursor:** `.vscode/tasks.json` — Command Palette → **Tasks: Run Task** → **`release:tag`**.
## App identity

The public, stable macOS bundle identifier is **`app.zonelaunch.launcher`**. It is strongly bound
for every build and install: all machines, forks, and releases that ship ZoneLaunch from this
repository must use this same ID. The single source of truth is
`macos/AppTimezoneLauncher/scripts/app-identity.sh` (sourced by `build-app.sh` and
`install-app.sh`). Do not substitute personal, GitHub-user, or local-development identifiers.

`install-app.sh` must keep a single Dock / LaunchServices entry: it refuses non-canonical built
IDs, purges legacy bundle IDs (currently `io.github.jawq.zonelaunch`) and legacy app names under
the install prefix, unregisters known dual-icon paths, force-registers only
`/Applications/ZoneLaunch.app` (or `$INSTALL_DIR/ZoneLaunch.app`), and runs LaunchServices GC.
Any intentional identity migration must extend `LEGACY_BUNDLE_IDS` / purge logic and keep the
install regression tests green.

## Build, test, and development commands

Use `./install.sh --feishu --wechat` from the repository root to install shell launchers. In
`macos/AppTimezoneLauncher/`, use:

```bash
swift test
xcrun swift-format lint --recursive Sources Tests Package.swift
./scripts/build-app.sh
./scripts/install-app.sh
open "/Applications/ZoneLaunch.app"
```

`build-app.sh` creates a distributable, ad-hoc-signed `.app`. The installed copy at
`/Applications/ZoneLaunch.app` is a build artifact, not the Git workspace. Make changes in
this repository, rebuild, then replace the installed app when needed.

### After every change: rebuild and reinstall

Whenever agent or developer work changes the macOS app (Swift sources, resources,
`Package.swift`, or build/install scripts), **always finish by rebuilding and reinstalling**
so `/Applications/ZoneLaunch.app` matches the workspace:

```bash
cd macos/AppTimezoneLauncher
swift test
./scripts/build-app.sh
./scripts/install-app.sh
```

Do this at the end of each completed change set, not only before commits. Skip only when the
change is docs-only or otherwise cannot affect the installed app.

## Coding style and naming

Use Swift 6 and macOS 14 APIs. Follow `swift-format`; existing Swift code uses two-space
indentation. Types use `UpperCamelCase`, members use `lowerCamelCase`, and file names match
their primary type, such as `ConfigurationStore.swift`. Keep UI state in view models; parsing,
launching, and persistence logic belong in the core target. Shell scripts use `#!/usr/bin/env bash`
and `set -euo pipefail`.

## Testing

Use Swift Testing (`@Test`, `#expect`) in `LauncherModelTests.swift`. Test names should describe
behavior, such as `configurationStoreUsesEnvironmentConfigPathOverride`. Add tests when changing
shared parsing, persistence, time-zone injection, or launch behavior. Run the full test suite and
format check before committing changes.

## Commits and pull requests

Recent commits use Conventional Commit prefixes, with an optional emoji, such as
`feat: add app timezone launchers` or `🎉 feat: add macOS launcher`. Keep each commit focused
and use an imperative summary. Pull requests should describe user-visible behavior, list validation
commands, and link related issues when available; include screenshots for SwiftUI changes. Do not
commit generated build artifacts, logs, personal paths, or credentials.
