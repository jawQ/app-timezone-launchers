# app-timezone-launchers

[English](README.md)

以**指定时区**启动 macOS 应用，与系统时区相互独立。

> 仅支持 macOS。尚未测试 Windows / Linux，因而不提供支持。

## 项目背景

本项目可针对特定高频场景开发：在使用 Claude、ChatGPT 等对 IP 校验较为严格的 AI 软件时，用户通常需要将系统时区修改为产品支持的允许地区。然而，这会导致系统内其他软件也同步切换至该时区，影响日常办公。

为了解决这一痛点，本项目支持为特定的办公或社交软件单独配置时区，确保在运行 AI 软件的同时，其他程序仍能保持本地时间。本项目旨在完美解决此类时区冲突场景。

技术上，每次启动只向**新进程**注入 `TZ`，不会改写系统时钟；已在运行的应用需退出后，再用本工具重新启动才会生效。

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

GitHub Releases 提供 **ad-hoc 签名** 预构建包（无需付费苹果开发者账号，**未公证**）。

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
| [可选启动命令](docs/scripts/optional-launchers.zh-CN.md) | Slack / LINE 脚本 |
| [地区参考](docs/scripts/regional-references.zh-CN.md) | 各地区常用时区 |
| [App 概览](docs/app/overview.zh-CN.md) | 脚本 vs 图形界面 |
| [从 Release 安装 App](docs/app/install-from-release.zh-CN.md) | 下载 zip、门禁提示 |
| [从源码构建 App](docs/app/build-from-source.zh-CN.md) | 本地构建 / 打包 |
| [发布 Release](docs/app/releasing.zh-CN.md) | 维护者：`npm run release:tag` |
