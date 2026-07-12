# app-timezone-launchers

[Simplified Chinese](README.zh-CN.md)

Launch macOS apps in a **chosen time zone** — independent of the system time zone.

> macOS only. Windows and Linux are untested and unsupported.

## Background

Many people change the **macOS system time zone** for work — for example to match a remote team, a client region, or a corporate calendar. After that change, social and messaging apps such as **WeChat**, **Feishu/Lark**, and similar tools often follow the system setting. In-app timestamps then no longer match the **physical time zone** where you actually are: messages, moments, and chat history look “shifted,” which is confusing in daily life.

This project addresses that gap. You can keep the system time zone set for work (or any other need) while starting selected apps under the time zone you care about — typically your **real local time** where you live — so app UI stays aligned with daily life. The same mechanism also works the other way around: leave the system on local time and launch only Feishu, WeChat, or other apps in a regional zone (for example `Asia/Shanghai`).

Technically, each launch injects a `TZ` value into a **new** process only. It does not rewrite the system clock, and already-running apps are unaffected until you quit and relaunch them through these tools.

## Two ways to use this project

| | **Shell launchers (default)** | **ZoneLaunch app (optional)** |
| --- | --- | --- |
| Best for | A few fixed apps (Feishu, WeChat, …) | Many apps, drag-and-drop, time-zone groups |
| Weight | A few KB of shell | Normal macOS `.app` |
| Install | `./install.sh` below | [GitHub Releases](https://github.com/jawQ/app-timezone-launchers/releases/latest) or build from source |
| Needs | Terminal + `PATH` | macOS 14+ |

**Most people only need the scripts** — lightest path, no GUI.  
Want a nicer UI? Use **[ZoneLaunch](docs/app/overview.md)** (download or build). Same idea either way: inject `TZ` into a **new** process only.

---

## Shell launchers (recommended default)

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

## ZoneLaunch app (better UI, optional)

Prebuilt **ad-hoc signed** builds are on GitHub Releases (no paid Apple Developer account, **not notarized**).

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
| [Optional launchers](docs/scripts/optional-launchers.md) | Slack / LINE scripts |
| [Regional references](docs/scripts/regional-references.md) | Common time zones by region |
| [App overview](docs/app/overview.md) | Scripts vs GUI |
| [Install app from Releases](docs/app/install-from-release.md) | Download zip, Gatekeeper |
| [Build app from source](docs/app/build-from-source.md) | Local build / package |
| [Publishing releases](docs/app/releasing.md) | Maintainer: `npm run release:tag` |
