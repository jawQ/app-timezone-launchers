# 在 Windows 上安装

[English](install.md)

## 原生 Windows（CMD / PowerShell）

在仓库克隆目录中：

```powershell
cd path\to\app-timezone-launchers
powershell -ExecutionPolicy Bypass -File .\windows\install.ps1
```

默认只装飞书。更多选项：

```powershell
.\windows\install.ps1 -Feishu -WeChat -AddToPath
.\windows\install.ps1 -All -AddToPath
.\windows\install.ps1 -Prefix "$env:LOCALAPPDATA\ZoneLaunch\bin" -All -AddToPath
```

### 使用

**PowerShell：**

```powershell
feishu-tz.cmd
$env:LARK_TZ = 'America/Los_Angeles'; feishu-tz.cmd
$env:APP_PATH = 'C:\path\to\Feishu.exe'; feishu-tz.cmd
# 目标应用已在运行时仍要启动（旧进程不会换 TZ）：
feishu-tz.cmd -Force
# 或：$env:ZONELAUNCH_FORCE = '1'; feishu-tz.cmd
```

**CMD：**

```cmd
feishu-tz.cmd
set LARK_TZ=America/Los_Angeles && feishu-tz.cmd
set APP_PATH=%LOCALAPPDATA%\Feishu\Feishu.exe && feishu-tz.cmd
feishu-tz.cmd -Force
```

也可在资源管理器中双击安装目录里的 `feishu-tz.cmd`。

### 卸载

删除安装前缀中的 `*-tz.ps1`、`*-tz.cmd` 与 `_lib.ps1`（默认 `%USERPROFILE%\.local\bin`）。

## WSL

在 WSL 发行版（如 Ubuntu）内：

```bash
cd /mnt/c/path/to/app-timezone-launchers   # 按你的克隆路径调整
./windows/wsl/install.sh --all
```

详见 [WSL 指南](wsl.zh-CN.md)。

## 预编译 `.exe`（最快试用）

交叉编译的 CLI 压缩包。本地打包需要 Go、`zip`，以及 `shasum` 或 `sha256sum`：

| 电脑类型 | 下载文件名 |
| --- | --- |
| 大多数 Intel/AMD PC | `ZoneLaunch-cli-<version>-windows-amd64.zip` |
| ARM / 骁龙 Windows | `ZoneLaunch-cli-<version>-windows-arm64.zip` |

解压后双击 **`feishu-tz.exe`** 或 **`wechat-tz.exe`**，或在 cmd 中：

```cmd
feishu-tz.exe
zonelaunch.exe feishu
zonelaunch.exe run --tz Asia/Shanghai --exe C:\path\to\app.exe
```

在本仓库本地重新打包：

```bash
npm run release:package:windows-cli -- 0.1.0
# → dist/ZoneLaunch-cli-0.1.0-windows-amd64.zip
```

SmartScreen 可能提示未签名：若信任该构建，选 **更多信息 → 仍要运行**。

## 从脚本 Release 压缩包安装

请下载文件名含 **`-windows`** 的包：`app-timezone-launchers-<version>-windows.zip`。

解压后：

```powershell
# 原生
.\install.ps1 -All -AddToPath
```

```bash
# WSL
bash ./wsl/install.sh --all
```

**不要**在 Windows 上使用 `ZoneLaunch-*-macos.dmg` / `ZoneLaunch-*-macos.zip`——那是 macOS 应用专用资源。
