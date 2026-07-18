# ZoneLaunch App 概览

[English](overview.md)

ZoneLaunch 是可选的 **图形界面**，与 shell 启动命令做同一件事：以指定 `TZ` 启动 macOS 应用，与系统时区相互独立。

**存在的意义：** 使用 Claude、ChatGPT 等对 IP 校验较严格的 AI 软件时，常需将系统时区改为产品支持的地区，但这会让微信、飞书等办公与社交软件一并切换时区。ZoneLaunch（以及 shell 命令）可为特定应用单独配置时区，在运行 AI 软件的同时让其他程序保持本地时间（反过来也可以）。

## 什么时候用脚本，什么时候用 App

| | Shell 启动命令 | ZoneLaunch.app |
| --- | --- | --- |
| 适合 | 固定几个 App（飞书、微信等） | 任意 App、拖拽管理、多时区组 |
| 体积 | 几 KB 脚本 | 普通 macOS `.app` |
| 安装 | `./install.sh` | [从 Release 下载](install-from-release.zh-CN.md) 或 [源码构建](build-from-source.zh-CN.md) |
| 依赖 | 终端 + `PATH` | macOS 14+ |

**大多数场景只装脚本就够。** 需要更好的界面、管理很多应用、或多个时区组时再用 ZoneLaunch。

两者都只给**新启动**的进程注入 `TZ`，可以同时安装、互不影响。

## App 能做什么

- 将 `.app` 拖入时区分组
- 新建 / 重命名 / 删除分组（IANA 时区）
- 一键启动
- 同一应用可加入多个分组，用不同时区启动
- 检测到签名更新时显示蓝色工具栏按钮，安装完成后自动重启
- 「关于」面板可查看版本信息并手动检查更新（主窗口工具栏或菜单栏）

## 限制（与脚本相同）

- 请先退出目标应用；已在运行的进程不会换 `TZ`
- 部分页面仍可能跟账号、服务端或设备设置走
- 不会改 macOS 系统时间或其他应用

## 如何获取

1. **推荐：** [从 GitHub Releases 安装](install-from-release.zh-CN.md)（ad-hoc 签名 zip，无需付费苹果开发者账号）。**首次打开会被门禁拦截，需在「隐私与安全性」点「仍要打开」**——详见该页。
2. **开发者：** [从源码构建](build-from-source.zh-CN.md)

## 应用身份

所有官方构建的 Bundle ID 均为 **`app.zonelaunch.launcher`**。若基于本仓库分发构建，请勿换成个人 Bundle ID。
