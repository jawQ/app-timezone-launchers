# app-timezone-launchers

[Simplified Chinese](README.zh-CN.md)

Launch macOS apps in a chosen time zone without changing the system time zone.

> macOS only. Windows and Linux are untested and unsupported.

## Built-in launchers

| Command | App | Default time zone |
| --- | --- | --- |
| `feishu-tz` | Feishu/Lark | `Asia/Shanghai` |
| `wechat-tz` | WeChat | `Asia/Shanghai` |

Slack and LINE launchers are optional. See [optional launchers](docs/optional-launchers.md).

## Install

```bash
git clone https://github.com/jawQ/app-timezone-launchers.git
cd app-timezone-launchers
./install.sh
```

By default, this installs `feishu-tz`.

To install the WeChat launcher too:

```bash
./install.sh --feishu --wechat
```

The default installation path is `~/.local/bin`. Add it to your shell `PATH` if needed:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

```bash
feishu-tz
wechat-tz
```

Use a different time zone for a single launch:

```bash
LARK_TZ=America/Los_Angeles feishu-tz
WECHAT_TZ=Asia/Singapore wechat-tz
```

Use a custom app path:

```bash
APP_PATH="/Applications/Lark.app" feishu-tz
APP_PATH="/Applications/WeChat.app" wechat-tz
```

## Notes

- Quit the target app first. Existing processes do not receive the new `TZ` value.
- These launchers do not change the macOS system time, terminal time, or other apps.
- Some app pages may ignore `TZ` and use account, server, or device settings instead.
- App output is discarded; no launch log file is written.

## Uninstall

```bash
rm -f "$HOME/.local/bin/feishu-tz" "$HOME/.local/bin/wechat-tz"
```

## More documentation

- [Optional launchers](docs/optional-launchers.md): Slack and LINE launchers.
- [Regional references](docs/regional-references.md): common time-zone examples for the United States, Europe, Japan, South Korea, and Singapore.
- [macOS app](macos/AppTimezoneLauncher/README.md): a local SwiftUI app that manages apps and time-zone groups with drag and drop.
