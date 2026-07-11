# 从 GitHub Releases 安装 ZoneLaunch

[English](install-from-release.md)

下载预构建的 **ZoneLaunch.app**，日常使用无需 clone 仓库，也无需为日常启动准备完整 Xcode 工具链。

> 构建为 **ad-hoc 签名**（无付费苹果开发者证书、未公证）。这是为了保持免费分发。首次打开时 macOS 门禁（Gatekeeper）可能会提示。

## 下载

1. 打开最新 Release：  
   **https://github.com/jawQ/app-timezone-launchers/releases/latest**
2. 下载 `ZoneLaunch-<version>-macos.zip`
3. 可选：用同页的 `SHA256SUMS` 核对校验和

## 安装

```bash
# 假设 zip 在 ~/Downloads
cd ~/Downloads
unzip ZoneLaunch-*-macos.zip
# 应看到 ZoneLaunch.app（以及简短的 README-FIRST.txt）
```

然后任选其一：

- 将 **ZoneLaunch.app** 拖到「应用程序」，或
- 在终端移动：

```bash
rm -rf /Applications/ZoneLaunch.app
mv ZoneLaunch.app /Applications/
```

打开：

```bash
open /Applications/ZoneLaunch.app
```

## 首次打开（门禁提示）

应用未经公证时：

1. 若提示**无法打开** / 来自身份不明的开发者：
   - 在 Finder 中对 **ZoneLaunch** 右键（或 Control-单击）→ **打开** → 再确认 **打开**
2. 或到 **系统设置 → 隐私与安全性**，允许仍被拦截的应用后再打开

对免费、ad-hoc 分发的 Mac 应用，这属于正常情况。

## 升级

用新版本替换 `/Applications/ZoneLaunch.app`。尽量只保留一个安装路径，避免 Dock 出现两个图标。

若你曾用源码里的 `./scripts/install-app.sh` 安装，该脚本还会清理历史 Bundle ID 与重复注册。纯 zip 安装时，先删旧再移入新版本通常即可。

## 要求

- macOS 14 及以上
- 官方构建 Bundle ID：`app.zonelaunch.launcher`

## 卸载

```bash
rm -rf /Applications/ZoneLaunch.app
```

用户配置（时区组、已添加的应用）在：

```text
~/Library/Application Support/App Timezone Launcher/
```

只有在也要清空设置时才删除该目录。

## 更想用脚本？

Shell 启动命令仍然是最轻量的路径，见[仓库 README](../../README.zh-CN.md)。

## 改为自己构建

见[从源码构建](build-from-source.zh-CN.md)。
