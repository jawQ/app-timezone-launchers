# app-timezone-launchers

[English](README.md)

以指定时区启动 macOS 应用，**不**改变系统时区。

> 仅支持 macOS。尚未测试 Windows / Linux，因而不提供支持。

## 两种用法

| | **Shell 启动命令（默认）** | **ZoneLaunch App（可选）** |
| --- | --- | --- |
| 适合 | 固定几个 App（飞书、微信等） | 任意 App、拖拽管理、多时区组 |
| 体积 | 几 KB 脚本 | 普通 macOS `.app` |
| 安装 | 下文 `./install.sh` | [GitHub Releases](https://github.com/jawQ/app-timezone-launchers/releases/latest) 或源码构建 |
| 依赖 | 终端 + `PATH` | macOS 14+ |

**大多数场景只装脚本即可**——最轻量，无需图形界面。  
想要更好体验时再用 **[ZoneLaunch](docs/app/overview.zh-CN.md)**（下载或自建）。机制相同：只给**新启动**的进程注入 `TZ`。

---

## Shell 启动命令（推荐默认）

### 内置命令

| 命令 | 应用 | 默认时区 |
| --- | --- | --- |
| `feishu-tz` | Feishu/Lark | `Asia/Shanghai` |
| `wechat-tz` | WeChat | `Asia/Shanghai` |

Slack、LINE 为可选，见[可选启动命令](docs/scripts/optional-launchers.zh-CN.md)。

### 安装

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

默认安装目录为 `~/.local/bin`。如需加入 `PATH`：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### 使用

```bash
feishu-tz
wechat-tz
```

单次覆盖时区：

```bash
LARK_TZ=America/Los_Angeles feishu-tz
WECHAT_TZ=Asia/Singapore wechat-tz
```

自定义应用路径：

```bash
APP_PATH="/Applications/Lark.app" feishu-tz
APP_PATH="/Applications/WeChat.app" wechat-tz
```

### 注意事项

- 请先退出目标应用。已在运行的进程不会收到新的 `TZ`。
- 不会改变 macOS 系统时间、终端时间或其他应用。
- 部分页面可能忽略 `TZ`，改走账号、服务端或设备设置。
- 应用输出会被丢弃，不写启动日志。

### 卸载

```bash
rm -f "$HOME/.local/bin/feishu-tz" "$HOME/.local/bin/wechat-tz"
```

---

## ZoneLaunch App（更好体验，可选）

GitHub Releases 提供 **ad-hoc 签名** 预构建包（无需付费苹果开发者账号；首次打开可能需右键 → 打开）。

- **下载：** https://github.com/jawQ/app-timezone-launchers/releases/latest  
- **zip 安装说明：** [从 Release 安装](docs/app/install-from-release.zh-CN.md)  
- **是什么 / 何时用：** [App 概览](docs/app/overview.zh-CN.md)  
- **自己构建：** [从源码构建](docs/app/build-from-source.zh-CN.md)

官方构建 Bundle ID：`app.zonelaunch.launcher`。

---

## 文档

| 模块 | 内容 |
| --- | --- |
| [可选启动命令](docs/scripts/optional-launchers.zh-CN.md) | Slack / LINE 脚本 |
| [地区参考](docs/scripts/regional-references.zh-CN.md) | 各地区常用时区 |
| [App 概览](docs/app/overview.zh-CN.md) | 脚本 vs 图形界面 |
| [从 Release 安装 App](docs/app/install-from-release.zh-CN.md) | 下载 zip、门禁提示 |
| [从源码构建 App](docs/app/build-from-source.zh-CN.md) | 本地构建 / 打包 |
