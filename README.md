# app-timezone-launchers

[Simplified Chinese](README.zh-CN.md)

Launch macOS apps in a chosen time zone **without** changing the system time zone.

> macOS only. Windows and Linux are untested and unsupported.

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

Prebuilt **ad-hoc signed** builds are published on GitHub Releases (no paid Apple Developer account; Gatekeeper may ask you to right-click → Open the first time).

- **Download:** https://github.com/jawQ/app-timezone-launchers/releases/latest  
- **How to install the zip:** [Install from Releases](docs/app/install-from-release.md)  
- **What it is / when to use it:** [App overview](docs/app/overview.md)  
- **Build yourself:** [Build from source](docs/app/build-from-source.md)

Bundle ID for all official builds: `app.zonelaunch.launcher`.

---

## Documentation

| Module | Contents |
| --- | --- |
| [Optional launchers](docs/scripts/optional-launchers.md) | Slack / LINE scripts |
| [Regional references](docs/scripts/regional-references.md) | Common time zones by region |
| [App overview](docs/app/overview.md) | Scripts vs GUI |
| [Install app from Releases](docs/app/install-from-release.md) | Download zip, Gatekeeper |
| [Build app from source](docs/app/build-from-source.md) | Local build / package |
