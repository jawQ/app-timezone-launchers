# Windows 支持概览

[English](overview.md)

Windows 与 macOS **并排支持**。macOS 的 `bin/`、`install.sh` 与 ZoneLaunch.app **保持不变**。

## 你能用到什么

| 工作面 | 入口 | 典型场景 |
| --- | --- | --- |
| **CMD** | `feishu-tz.cmd` | 经典终端、批处理、双击 |
| **PowerShell** | `feishu-tz.ps1` | Windows PowerShell 5.1 / PowerShell 7+ |
| **GUI（基础）** | 双击 `.cmd` | 固定几个 App 时可不进终端 |
| **WSL** | `windows/wsl/` | 类 Linux 终端；VS Code、Docker、CLI |

与 macOS 同一产品语义：只向**新进程**注入 IANA `TZ`，**不修改** Windows 系统时区。

## 安装

见 [Windows 安装](install.zh-CN.md)（原生 + WSL）。

## 限制

- 请先退出目标应用；已在运行的进程不会收到新环境变量。
- 并非所有 Windows 应用都识别 POSIX `TZ`。Electron/Chromium 类较常见；纯 Win32 / 商店应用可能忽略。
- Docker：容器内也需要 `TZ`（`-e TZ=…` / Compose），见 [WSL](wsl.zh-CN.md)。

## 发版资源（必须标注平台）

| 平台 | 下载文件名模式 |
| --- | --- |
| macOS ZoneLaunch（推荐安装） | `ZoneLaunch-<version>-macos.dmg` |
| macOS ZoneLaunch（zip / 更新器用） | `ZoneLaunch-<version>-macos.zip` |
| Windows 脚本（CMD/PS + WSL） | `app-timezone-launchers-<version>-windows.zip` |
| Windows CLI（amd64） | `ZoneLaunch-cli-<version>-windows-amd64.zip` |
| Windows CLI（arm64） | `ZoneLaunch-cli-<version>-windows-arm64.zip` |

发版根目录还有统一的 `SHA256SUMS`，覆盖上述五个资源。Windows 脚本包解压后的**顶层文件夹名**也带 `-windows`。多平台发版时禁止使用无平台后缀的模糊名（如单独的 `ZoneLaunch.zip`）。

## 仓库布局

```text
windows/
  bin/              # 原生 PowerShell + CMD
  cli/              # Go CLI（交叉编译 feishu-tz.exe / zonelaunch.exe）
  install.ps1
  wsl/              # WSL bash 辅助
    bin/
    install.sh
  scripts/          # 打包、CLI 构建与自测
    package-scripts.sh
    build-cli.sh
```
