# app-timezone-launchers

[English](README.md)

以**指定时区**启动应用，与系统时区相互独立。

| 平台 | 状态 |
| --- | --- |
| **macOS** | Shell 启动命令 + 可选 **ZoneLaunch** 图形界面 |
| **Windows** | 原生 CMD/PowerShell 启动器 + **WSL** 辅助命令 |
| 裸机 Linux | 非一等目标；Windows 上的 WSL 路径可覆盖大量 Linux 工作流 |

技术上，每次启动只向**新进程**注入 `TZ`，不会改写系统时钟；已在运行的应用需退出后，再用本工具重新启动才会生效。

## 项目背景

本项目针对高频场景：在使用 Claude、ChatGPT 等对区域/时区较敏感的 AI 软件时，用户常需把**系统时区**改成产品支持的地区，但这会牵连微信、飞书等所有应用。

本项目支持为特定办公/社交软件（或 CLI）单独注入时区，让 AI 工具与日常软件可以并存。

## 支持的入口

| | **macOS 脚本** | **ZoneLaunch（macOS GUI）** | **Windows 原生** | **WSL** |
| --- | --- | --- | --- | --- |
| 适合 | 固定几个 App（飞书、微信等） | 任意 App、拖拽、多时区组 | CMD / PowerShell / 双击 | VS Code、Docker、Linux CLI；可选拉起 Windows `.exe` |
| 安装 | `./install.sh` | [Releases](https://github.com/jawQ/app-timezone-launchers/releases/latest)（`*-macos.zip`） | `windows\install.ps1` | `windows/wsl/install.sh` |
| 文档 | 下文 | [App 概览](docs/app/overview.zh-CN.md) | [Windows](docs/windows/overview.zh-CN.md) | [WSL](docs/windows/wsl.zh-CN.md) |

**大多数场景只装脚本即可**。macOS 需要图形界面时用 **[ZoneLaunch](docs/app/overview.zh-CN.md)**。

---

## macOS Shell 启动命令（Mac 上推荐默认）

> 下列命令与 `./install.sh` **仅适用于 macOS（Darwin）**。Windows 用户请看 [Windows 安装](docs/windows/install.zh-CN.md)。

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

## Windows（CMD / PowerShell / WSL）

与 macOS **并排支持**——**不改变**上文 macOS 安装路径。

| 工作面 | 安装 | 文档 |
| --- | --- | --- |
| CMD / PowerShell / 双击 | `powershell -ExecutionPolicy Bypass -File .\windows\install.ps1 -All -AddToPath` | [安装](docs/windows/install.zh-CN.md) |
| WSL（VS Code、Docker、Linux CLI） | 在发行版内执行 `./windows/wsl/install.sh --all` | [WSL](docs/windows/wsl.zh-CN.md) |

本平台发版压缩包：**`app-timezone-launchers-<version>-windows.zip`**（文件名与解压顶层目录均含 `-windows`）。

macOS 应用包仍为：**`ZoneLaunch-<version>-macos.zip`**。

概览：[docs/windows/overview.zh-CN.md](docs/windows/overview.zh-CN.md)。

---

## ZoneLaunch App（macOS 图形界面，可选）

GitHub Releases 提供 **ad-hoc 签名** 预构建包（无需付费苹果开发者账号，**未公证**）。资源文件名以 **`-macos`** 结尾。

- **下载：** https://github.com/jawQ/app-timezone-launchers/releases/latest  
- **完整安装与门禁说明：** [从 Release 安装](docs/app/install-from-release.zh-CN.md)  
- **是什么 / 何时用：** [App 概览](docs/app/overview.zh-CN.md)  
- **自己构建：** [从源码构建](docs/app/build-from-source.zh-CN.md)  
- **维护者 — 终端发版：** 见 **[发布 Release](docs/app/releasing.zh-CN.md)**

```bash
npm run release:tag:dry-run   # 预览下一 vX.Y.Z
npm run release:tag           # patch 递增 + tag + 推送 → CI 上传 zip
npm run release:tag -- 0.2.0  # 指定版本
```

| npm script | 作用 |
| --- | --- |
| `release:tag` | 自动 patch 递增、打 tag、推送 |
| `release:tag -- X.Y.Z` | 指定版本、打 tag、推送 |
| `release:tag:dry-run` | 仅预览 |
| `release:tag:test` | 自检 |
| `release:package` | 仅本地 zip（不发 GitHub Release） |
| `release:notes -- vX.Y.Z` | 预览中英双语 Release 说明 |

官方构建 Bundle ID：`app.zonelaunch.launcher`。

### 首次打开被拦截 —— 正常现象

下载 zip 后双击会被拦截。仅移到「应用程序」**不会**自动解除。

**原因：** 网络下载的隔离标记 + 仅 ad-hoc 签名 + 未做苹果公证（为保持免费分发）。

| 步骤 | 界面示意 |
| --- | --- |
| 1. 双击后点 **Done / 完成**（不要移到废纸篓） | ![无法打开对话框](docs/app/images/gatekeeper-not-opened.png) |
| 2. **系统设置 → 隐私与安全性** → **Open Anyway / 仍要打开** | ![仍要打开](docs/app/images/gatekeeper-open-anyway.png) |

之后可正常启动。完整说明与备选方案（`xattr`、右键打开）见 [从 Release 安装](docs/app/install-from-release.zh-CN.md)。

---

## 文档

| 模块 | 内容 |
| --- | --- |
| [可选启动命令](docs/scripts/optional-launchers.zh-CN.md) | Slack / LINE 脚本（macOS） |
| [地区参考](docs/scripts/regional-references.zh-CN.md) | 各地区常用时区 |
| [Windows 概览](docs/windows/overview.zh-CN.md) | CMD / PowerShell / WSL |
| [Windows 安装](docs/windows/install.zh-CN.md) | 原生 + Release zip |
| [WSL](docs/windows/wsl.zh-CN.md) | VS Code、Docker、互通 |
| [App 概览](docs/app/overview.zh-CN.md) | 脚本 vs 图形界面（macOS） |
| [从 Release 安装 App](docs/app/install-from-release.zh-CN.md) | 下载 zip、门禁提示 |
| [从源码构建 App](docs/app/build-from-source.zh-CN.md) | 本地构建 / 打包 |
| [发布 Release](docs/app/releasing.zh-CN.md) | 维护者：`npm run release:tag` |
