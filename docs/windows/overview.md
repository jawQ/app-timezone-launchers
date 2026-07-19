# Windows support overview

[Simplified Chinese](overview.zh-CN.md)

Windows support is **side-by-side** with macOS. The macOS shell scripts (`bin/`), `install.sh`, and ZoneLaunch.app are unchanged.

## What you get

| Work surface | Entry | Typical use |
| --- | --- | --- |
| **CMD** | `feishu-tz.cmd` | Classic terminal, batch files, double-click |
| **PowerShell** | `feishu-tz.ps1` | Windows PowerShell 5.1 / PowerShell 7+ |
| **GUI (basic)** | Double-click `.cmd` | No terminal required for fixed apps |
| **WSL** | `windows/wsl/` helpers | Linux-like shell; VS Code, Docker, CLI tools |

Same product idea as macOS: inject IANA `TZ` into a **new** process only. Does not change the Windows system time zone.

## Install

See [Install on Windows](install.md) (native + WSL).

## Limits

- Quit the target app first; running processes keep their old environment.
- Not every Windows app honors POSIX `TZ`. Electron/Chromium-based tools often do; pure Win32 or Store apps may ignore it.
- Docker: set `TZ` **inside the container** (`-e TZ=…` / Compose) as well as on the CLI when needed — see [WSL](wsl.md).

## Release assets (platform labels required)

| Platform | Download name pattern |
| --- | --- |
| macOS ZoneLaunch app (install) | `ZoneLaunch-<version>-macos.dmg` |
| macOS ZoneLaunch app (zip / updater) | `ZoneLaunch-<version>-macos.zip` |
| Windows scripts (CMD/PS + WSL) | `app-timezone-launchers-<version>-windows.zip` |
| Windows CLI (amd64) | `ZoneLaunch-cli-<version>-windows-amd64.zip` |
| Windows CLI (arm64) | `ZoneLaunch-cli-<version>-windows-arm64.zip` |

A unified `SHA256SUMS` at the release root lists all five archives. Windows script zips extract to a folder whose name also ends with `-windows`. Never publish an unlabeled `ZoneLaunch.zip` for multi-platform releases.

## Layout in the repo

```text
windows/
  bin/              # Native PowerShell + CMD
  cli/              # Go CLI (cross-compiled feishu-tz.exe / zonelaunch.exe)
  install.ps1
  wsl/              # WSL bash helpers
    bin/
    install.sh
  scripts/          # package + CLI build + self-tests
    package-scripts.sh
    build-cli.sh
```
