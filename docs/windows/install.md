# Install on Windows

[Simplified Chinese](install.zh-CN.md)

## Native Windows (CMD / PowerShell)

From a clone of this repository:

```powershell
cd path\to\app-timezone-launchers
powershell -ExecutionPolicy Bypass -File .\windows\install.ps1
```

Feishu only by default. More options:

```powershell
.\windows\install.ps1 -Feishu -WeChat -AddToPath
.\windows\install.ps1 -All -AddToPath
.\windows\install.ps1 -Prefix "$env:LOCALAPPDATA\ZoneLaunch\bin" -All -AddToPath
```

### Usage

**PowerShell:**

```powershell
feishu-tz.cmd
$env:LARK_TZ = 'America/Los_Angeles'; feishu-tz.cmd
$env:APP_PATH = 'C:\path\to\Feishu.exe'; feishu-tz.cmd
# Launch even if the app is already running (new process may still not replace the old TZ):
feishu-tz.cmd -Force
# or: $env:ZONELAUNCH_FORCE = '1'; feishu-tz.cmd
```

**CMD:**

```cmd
feishu-tz.cmd
set LARK_TZ=America/Los_Angeles && feishu-tz.cmd
set APP_PATH=%LOCALAPPDATA%\Feishu\Feishu.exe && feishu-tz.cmd
feishu-tz.cmd -Force
```

Double-click `feishu-tz.cmd` in Explorer if the install prefix is used as a shortcut target.

### Uninstall

Delete the installed `*-tz.ps1`, `*-tz.cmd`, and `_lib.ps1` from your prefix (default `%USERPROFILE%\.local\bin`).

## WSL

Inside your WSL distro (Ubuntu, etc.):

```bash
cd /mnt/c/path/to/app-timezone-launchers   # or your clone path
./windows/wsl/install.sh --all
```

Details: [WSL guide](wsl.md).

## Prebuilt `.exe` (easiest try)

Cross-compiled CLI zip. Local packaging requires Go, `zip`, and either `shasum` or `sha256sum`:

| PC type | Download name |
| --- | --- |
| Most Intel/AMD PCs | `ZoneLaunch-cli-<version>-windows-amd64.zip` |
| ARM / Snapdragon Windows | `ZoneLaunch-cli-<version>-windows-arm64.zip` |

Extract, then double-click **`feishu-tz.exe`** or **`wechat-tz.exe`**, or from cmd:

```cmd
feishu-tz.exe
zonelaunch.exe feishu
zonelaunch.exe run --tz Asia/Shanghai --exe C:\path\to\app.exe
```

Local rebuild from this repo:

```bash
npm run release:package:windows-cli -- 0.1.0
# → dist/ZoneLaunch-cli-0.1.0-windows-amd64.zip
```

SmartScreen may warn (unsigned). Use **More info → Run anyway** if you trust the build.

## From a scripts Release zip

Download **`app-timezone-launchers-<version>-windows.zip`** (name must contain `-windows`).

Extract, then:

```powershell
# Native
.\install.ps1 -All -AddToPath
```

```bash
# WSL
bash ./wsl/install.sh --all
```

Do **not** use `ZoneLaunch-*-macos.dmg` / `ZoneLaunch-*-macos.zip` on Windows — those assets are the macOS app only.
