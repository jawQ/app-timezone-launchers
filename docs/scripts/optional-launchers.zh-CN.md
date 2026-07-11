# 可选启动命令

[English](optional-launchers.md)

本文介绍仓库中提供但未放入主 README 的可选 macOS 启动命令。

> 仅支持 macOS：这些启动命令面向 macOS `.app` 应用包设计。尚未测试 Windows 和 Linux，因而不提供支持。

## 命令

| 命令 | 应用 | 默认应用路径 | 默认时区 |
| --- | --- | --- | --- |
| `slack-tz` | Slack | `/Applications/Slack.app` | `Asia/Shanghai` |
| `line-tz` | LINE | `/Applications/LINE.app` | `Asia/Shanghai` |

## 安装

仅安装 Slack：

```bash
./install.sh --slack
```

仅安装 LINE：

```bash
./install.sh --line
```

同时安装两个可选启动命令：

```bash
./install.sh --slack --line
```

安装仓库内的全部启动命令：

```bash
./install.sh --all
```

安装到其他目录：

```bash
./install.sh --slack --line --prefix /usr/local/bin
```

## 使用

以默认时区启动 Slack：

```bash
slack-tz
```

以默认时区启动 LINE：

```bash
line-tz
```

临时覆盖时区：

```bash
SLACK_TZ=UTC slack-tz
LINE_TZ=UTC line-tz
```

常用示例：

```bash
# 美国旧金山
SLACK_TZ=America/Los_Angeles slack-tz
LINE_TZ=America/Los_Angeles line-tz

# 新加坡
SLACK_TZ=Asia/Singapore slack-tz
LINE_TZ=Asia/Singapore line-tz

# 德国
SLACK_TZ=Europe/Berlin slack-tz
LINE_TZ=Europe/Berlin line-tz
```

使用非默认应用路径：

```bash
APP_PATH="/Applications/Slack.app" slack-tz
APP_PATH="/Applications/LINE.app" line-tz
```

## 环境变量

| 变量 | 使用方 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `SLACK_TZ` | `slack-tz` | `Asia/Shanghai` | 以 `TZ` 传给 Slack 的时区。 |
| `LINE_TZ` | `line-tz` | `Asia/Shanghai` | 以 `TZ` 传给 LINE 的时区。 |
| `APP_PATH` | 两个可选启动命令 | 按应用而定 | 覆盖默认 `.app` 应用包路径。 |

## 应用可执行文件

可选启动命令默认使用以下可执行文件路径：

```text
/Applications/Slack.app/Contents/MacOS/Slack
/Applications/LINE.app/Contents/MacOS/LINE
```

## 卸载

从安装目录删除已安装命令：

```bash
rm -f "$HOME/.local/bin/slack-tz" "$HOME/.local/bin/line-tz"
```

若使用自定义 `--prefix` 安装，请从相应目录删除命令。

## 排查问题

检查命令是否已安装：

```bash
command -v slack-tz
command -v line-tz
```

检查默认应用可执行文件是否存在：

```bash
test -x /Applications/Slack.app/Contents/MacOS/Slack && echo OK
test -x /Applications/LINE.app/Contents/MacOS/LINE && echo OK
```

检查已启动进程是否收到 `TZ`：

```bash
ps eww -p <PID> | tr ' ' '\n' | grep '^TZ='
```

将 `<PID>` 替换为进程检查命令输出的进程 ID，例如 `pgrep -x Slack` 或 `pgrep -x LINE`。

## 另见

- [地区参考](regional-references.zh-CN.md)
- [ZoneLaunch App](../app/overview.zh-CN.md)

