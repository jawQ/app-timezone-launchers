# app-timezone-launchers

[Simplified Chinese](README.zh-CN.md)

Launch apps in a **chosen time zone** — independent of the system time zone.

| Platform | Status |
| --- | --- |
| **macOS** | Shell launchers + optional **ZoneLaunch** GUI |
| **Windows** | Native CMD/PowerShell launchers + **WSL** helpers |
| Linux (bare metal) | Not a first-class target; WSL path covers many Windows+Linux workflows |

Technically, each launch injects a `TZ` value into a **new** process only. It does not rewrite the system clock, and already-running apps are unaffected until you quit and relaunch them through these tools.

## Background

This project targets a common high-frequency scenario: when using AI software with strict regional checks — such as **Claude**, **ChatGPT**, and similar tools — you often need to change the system time zone to a region the product supports. That change propagates to every other app on the system, which disrupts everyday work.

To solve this, the project lets you assign a time zone to specific office or social apps (or CLI tools). You can run AI tools under a supported regional zone while everything else stays on your real local time — or the reverse.

## Supported entry points

| | **macOS scripts** | **ZoneLaunch (macOS GUI)** | **Windows native** | **WSL** |
| --- | --- | --- | --- | --- |
| Best for | Fixed apps (Feishu, WeChat, …) | Many apps, drag-and-drop | CMD / PowerShell / double-click | VS Code, Docker, Linux CLIs; optional Windows `.exe` interop |
| Install | `./install.sh` | [Releases](https://github.com/jawQ/app-timezone-launchers/releases/latest) (`*-macos.zip`) | `windows\install.ps1` | `windows/wsl/install.sh` |
| Docs | below | [App overview](docs/app/overview.md) | [Windows](docs/windows/overview.md) | [WSL](docs/windows/wsl.md) |

**Most people only need scripts** — lightest path.

macOS users who want a GUI: **[ZoneLaunch](docs/app/overview.md)**.

---

## macOS shell launchers (recommended default on Mac)

> These commands and `./install.sh` are **macOS only** (Darwin). Windows users: see [Windows](docs/windows/install.md).

### Built-in commands

| Command | App | Default time zone |
| --- | --- | --- |
| `feishu-tz` | Feishu/Lark | `Asia/Shanghai` |
| `wechat-tz` | WeChat | `Asia/Shanghai` |

Slack and LINE are optional. See [optional launchers](docs/scripts/optional-launchers.md).

### Install

```bash
git clone https://github.com/jawQ/app-timezone-launchers.git
cd app-timezone-launchers
./install.sh
```

By default this installs `feishu-tz`.

WeChat as well:

```bash
./install.sh --feishu --wechat
```

Default install directory is `~/.local/bin`. Add it to your `PATH` if needed:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Usage

```bash
feishu-tz
wechat-tz
```

One-shot time zone override:

```bash
LARK_TZ=America/Los_Angeles feishu-tz
WECHAT_TZ=Asia/Singapore wechat-tz
```

Custom app path:

```bash
APP_PATH="/Applications/Lark.app" feishu-tz
APP_PATH="/Applications/WeChat.app" wechat-tz
```

### Notes

- Quit the target app first. Existing processes do not pick up a new `TZ`.
- These launchers do not change macOS system time, terminal time, or other apps.
- Some app screens may ignore `TZ` and follow account, server, or device settings.
- App output is discarded; no launch log file is written.

### Uninstall

```bash
rm -f "$HOME/.local/bin/feishu-tz" "$HOME/.local/bin/wechat-tz"
```

---

## Windows (CMD / PowerShell / WSL)

Side-by-side support — **does not change** the macOS install path above.

| Surface | Install | Docs |
| --- | --- | --- |
| CMD / PowerShell / double-click | `powershell -ExecutionPolicy Bypass -File .\windows\install.ps1 -All -AddToPath` | [Install](docs/windows/install.md) |
| WSL (VS Code, Docker, Linux CLIs) | `./windows/wsl/install.sh --all` inside the distro | [WSL](docs/windows/wsl.md) |

Release zip for this platform: **`app-timezone-launchers-<version>-windows.zip`** (name and extracted folder both include `-windows`).

macOS app zip remains **`ZoneLaunch-<version>-macos.zip`**.

Overview: [docs/windows/overview.md](docs/windows/overview.md).

---

## ZoneLaunch app (macOS GUI, optional)

Prebuilt **ad-hoc signed** builds are on GitHub Releases (no paid Apple Developer account, **not notarized**). Asset name ends with **`-macos`**.

- **Download:** https://github.com/jawQ/app-timezone-launchers/releases/latest  
- **Full install + Gatekeeper guide:** [Install from Releases](docs/app/install-from-release.md)  
- **What it is / when to use it:** [App overview](docs/app/overview.md)  
- **Build yourself:** [Build from source](docs/app/build-from-source.md)  
- **Maintainers — cut a release:** see **[Publishing releases](docs/app/releasing.md)**

```bash
npm run release:tag:dry-run   # preview next vX.Y.Z
npm run release:tag           # patch-bump + tag + push → CI uploads the zip
npm run release:tag -- 0.2.0  # explicit version
```

| npm script | Purpose |
| --- | --- |
| `release:tag` | Auto patch-bump, tag, push |
| `release:tag -- X.Y.Z` | Explicit version, tag, push |
| `release:tag:dry-run` | Preview only |
| `release:tag:test` | Self-test |
| `release:package` | Local zip only (no GitHub Release) |
| `release:notes -- vX.Y.Z` | Preview bilingual release notes (EN + 中文) |

Bundle ID for all official builds: `app.zonelaunch.launcher`.

### First open is blocked — expected

After downloading the zip, double-click is blocked. Moving the app into Applications does **not** fix this by itself.

**Why:** internet quarantine + ad-hoc signature + no Apple notarization (keeps distribution free).

| Step | What you see |
| --- | --- |
| 1. Double-click → click **Done** (not Move to Trash) | ![Not Opened dialog](docs/app/images/gatekeeper-not-opened.png) |
| 2. **System Settings → Privacy & Security** → **Open Anyway** | ![Open Anyway](docs/app/images/gatekeeper-open-anyway.png) |

Later launches work normally. Full guide and alternatives (`xattr`, right-click Open): [Install from Releases](docs/app/install-from-release.md).

---

## Documentation

| Module | Contents |
| --- | --- |
| [Optional launchers](docs/scripts/optional-launchers.md) | Slack / LINE scripts (macOS) |
| [Regional references](docs/scripts/regional-references.md) | Common time zones by region |
| [Windows overview](docs/windows/overview.md) | CMD / PowerShell / WSL |
| [Windows install](docs/windows/install.md) | Native + Release zip |
| [WSL](docs/windows/wsl.md) | VS Code, Docker, interop |
| [App overview](docs/app/overview.md) | Scripts vs GUI (macOS) |
| [Install app from Releases](docs/app/install-from-release.md) | Download zip, Gatekeeper |
| [Build app from source](docs/app/build-from-source.md) | Local build / package |
| [Publishing releases](docs/app/releasing.md) | Maintainer: `npm run release:tag` |
