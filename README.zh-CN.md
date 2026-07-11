# app-timezone-launchers

[English](README.md)

以指定时区启动 macOS 应用，而不改变系统时区。

> 仅支持 macOS，尚未测试 Windows 和 Linux，因而不提供支持。

## 内置启动命令

| 命令 | 应用 | 默认时区 |
| --- | --- | --- |
| `feishu-tz` | Feishu/Lark | `Asia/Shanghai` |
| `wechat-tz` | WeChat | `Asia/Shanghai` |

Slack 和 LINE 启动命令为可选功能，详见[可选启动命令](docs/optional-launchers.md)。

## 安装

```bash
git clone https://github.com/jawQ/app-timezone-launchers.git
cd app-timezone-launchers
./install.sh
```

默认安装 `feishu-tz`。

同时安装微信：

```bash
./install.sh --feishu --wechat
```

默认安装路径是 `~/.local/bin`。如有需要，将其加入 shell 的 `PATH`：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## 使用

```bash
feishu-tz
wechat-tz
```

单次启动时使用其他时区：

```bash
LARK_TZ=America/Los_Angeles feishu-tz
WECHAT_TZ=Asia/Singapore wechat-tz
```

使用自定义应用路径：

```bash
APP_PATH="/Applications/Lark.app" feishu-tz
APP_PATH="/Applications/WeChat.app" wechat-tz
```

## 注意事项

- 请先退出目标应用。已运行的进程不会收到新的 `TZ`。
- 该命令不会改变 macOS 系统时间、终端时间或其他应用。
- 部分应用页面可能忽略 `TZ`，转而使用账号、服务端或设备设置。
- 应用输出会被丢弃，不会写入启动日志文件。

## 卸载

```bash
rm -f "$HOME/.local/bin/feishu-tz" "$HOME/.local/bin/wechat-tz"
```

## 更多文档

- [可选启动命令](docs/optional-launchers.md)：Slack 和 LINE 启动命令。
- [地区参考](docs/regional-references.md)：美国、欧洲、日本、韩国和新加坡的常用时区示例。
- [macOS App](macos/AppTimezoneLauncher/README.md)：支持拖拽管理应用和时区分组的本地 SwiftUI App。
