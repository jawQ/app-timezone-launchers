# Optional launchers

[Simplified Chinese](optional-launchers.zh-CN.md)

Optional macOS shell launchers that are not installed by default.

> macOS only. Windows and Linux are untested and unsupported.

## Commands

| Command | App | Default app path | Default time zone |
| --- | --- | --- | --- |
| `slack-tz` | Slack | `/Applications/Slack.app` | `Asia/Shanghai` |
| `line-tz` | LINE | `/Applications/LINE.app` | `Asia/Shanghai` |

## Install

Slack only:

```bash
./install.sh --slack
```

LINE only:

```bash
./install.sh --line
```

Both:

```bash
./install.sh --slack --line
```

All launchers in the repository:

```bash
./install.sh --all
```

Custom install directory:

```bash
./install.sh --slack --line --prefix /usr/local/bin
```

## Usage

```bash
slack-tz
line-tz
```

Override time zone for one launch:

```bash
SLACK_TZ=UTC slack-tz
LINE_TZ=UTC line-tz
```

Examples:

```bash
SLACK_TZ=America/Los_Angeles slack-tz
LINE_TZ=America/Los_Angeles line-tz

SLACK_TZ=Asia/Singapore slack-tz
LINE_TZ=Asia/Singapore line-tz
```

Custom app path:

```bash
APP_PATH="/Applications/Slack.app" slack-tz
APP_PATH="/Applications/LINE.app" line-tz
```

## Environment variables

| Variable | Used by | Default | Meaning |
| --- | --- | --- | --- |
| `SLACK_TZ` | `slack-tz` | `Asia/Shanghai` | Time zone injected as `TZ` into Slack |
| `LINE_TZ` | `line-tz` | `Asia/Shanghai` | Time zone injected as `TZ` into LINE |
| `APP_PATH` | both | per-app default | Override the `.app` bundle path |

## Uninstall

```bash
rm -f "$HOME/.local/bin/slack-tz" "$HOME/.local/bin/line-tz"
```

If you used `--prefix`, remove the commands from that directory instead.

## Troubleshooting

```bash
command -v slack-tz
command -v line-tz
test -x /Applications/Slack.app/Contents/MacOS/Slack && echo OK
test -x /Applications/LINE.app/Contents/MacOS/LINE && echo OK
ps eww -p <PID> | tr ' ' '\n' | grep '^TZ='
```

Replace `<PID>` with the process ID (for example `pgrep -x Slack`).

## See also

- [Regional references](regional-references.md)
- [ZoneLaunch app](../app/overview.md)
