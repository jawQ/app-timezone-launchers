# Repository Guide

[Simplified Chinese](AGENTS.zh-CN.md)

## Project structure and modules

The root `bin/` directory contains shell launchers such as `feishu-tz` and `wechat-tz`.
`install.sh` installs them to a user-specified prefix. User-facing documentation lives in
`README.md` and `docs/`.

The native app is a Swift Package at `macos/AppTimezoneLauncher/`. Put reusable non-UI
logic in `Sources/AppTimezoneLauncherCore/`; SwiftUI views and view models belong in
`Sources/AppTimezoneLauncher/`. Tests live in `Tests/AppTimezoneLauncherTests/`, and icon
source files and generated resources live in `Resources/`. Do not edit `.build/` or `build/`;
both are ignored generated directories.

## App identity

The public, stable macOS bundle identifier is `io.github.jawq.zonelaunch`, derived from this
repository's canonical GitHub location. It must remain unchanged across releases: do not use a
personal or local-development identifier. Any intentional identity migration must include a
LaunchServices deregistration path and regression coverage for a single installed app entry.

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
