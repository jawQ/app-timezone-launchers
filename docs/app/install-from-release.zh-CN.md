# 从 GitHub Releases 安装 ZoneLaunch

[English](install-from-release.md)

下载预构建的 **ZoneLaunch.app**，日常使用无需 clone 仓库，也无需为日常启动准备完整 Xcode 工具链。

> 构建为 **ad-hoc 签名**（无付费苹果开发者证书、**未公证**）。这是为了保持免费分发。  
> **从 Release 下载后第一次打开，几乎一定会被 macOS 拦截**——这是预期行为，不是安装包坏了。

## 下载

1. 打开最新 Release：  
   **https://github.com/jawQ/app-timezone-launchers/releases/latest**
2. **推荐下载** `ZoneLaunch-<version>-macos.dmg`（磁盘映像：打开后拖到「应用程序」即可）。  
   `.zip` 是同一份 App（同时供应用内更新使用）；更习惯压缩包时用 zip。  
   **Source code** 的 zip/tar 是整仓库源码，不是现成 App。
3. 可选：用同页的 `SHA256SUMS` 核对校验和

## 安装（推荐：DMG）

1. 双击 `ZoneLaunch-*-macos.dmg` 挂载磁盘映像。
2. 将 **ZoneLaunch** 拖到映像里的 **Applications** 快捷方式（或 `/Applications`）。
3. 推出该磁盘映像。
4. 从「应用程序」打开 ZoneLaunch（首次打开通常会被拦截——见下文）。

## 安装（zip）

```bash
# 假设 zip 在 ~/Downloads
cd ~/Downloads
unzip ZoneLaunch-*-macos.zip
# 应看到 ZoneLaunch.app
```

然后任选其一：

- 将 **ZoneLaunch.app** 拖到「应用程序」，或
- 在终端移动：

```bash
rm -rf /Applications/ZoneLaunch.app
mv ZoneLaunch.app /Applications/
```

**不要指望**从 Release 下载后双击立刻成功（见下文）。

## 为什么会被拦截

| 原因 | 说明 |
| --- | --- |
| 从网络下载 | macOS 会给文件打上 **隔离（quarantine）** 标记 |
| 仅 ad-hoc 签名 | 没有付费的 **Developer ID** 证书 |
| 未公证（notarize） | 苹果未对该二进制做 Gatekeeper 认可扫描 |

于是 Gatekeeper 会弹出下图这类对话框。把 App 移到「应用程序」**不会**自动解除拦截。在系统里**明确允许一次**之前，双击或 `open` 都会失败。

![门禁对话框：「ZoneLaunch」无法打开 — 点 Done/完成，不要点移到废纸篓](images/gatekeeper-not-opened.png)

许多免费、开源、未加入苹果付费开发者计划的 Mac 应用都会遇到同类提示。**这不等于应用有病毒。**

## 首次打开 —— 推荐步骤（对应当前系统界面）

### 1. 先触发一次拦截

双击 **ZoneLaunch**（在「下载」或「应用程序」均可）。出现上图带黄色警告的对话框时，点 **Done / 完成**（**不要**点 **Move to Trash / 移到废纸篓**）。

### 2. 在「隐私与安全性」里允许

1. 打开 **系统设置 → 隐私与安全性**（**System Settings → Privacy & Security**）
2. 向下滚动到安全性相关区域，应能看到下图所示横幅
3. 点击 **Open Anyway / 仍要打开**
4. 若再次确认，按提示继续

![隐私与安全性：已阻止 “ZoneLaunch” — 点 Open Anyway / 仍要打开](images/gatekeeper-open-anyway.png)

之后再打开 ZoneLaunch 即可正常使用。

### 备选：右键打开

在 Finder 中对 **ZoneLaunch** **Control-单击**（或右键）→ **打开** → **打开**。  
较新的 macOS 上有时仍不够，仍需上面的 **Open Anyway**。

### 可选（进阶）：终端清除隔离属性

仅在你信任该构建时使用（例如已核对 `SHA256SUMS`）：

```bash
xattr -dr com.apple.quarantine /Applications/ZoneLaunch.app
open /Applications/ZoneLaunch.app
```

## 以后发版还会不会出现？

只要仍用 **免费 ad-hoc 签名、不做公证**，从 Release 下载的用户首次仍会遇到此提示。  
只有项目将来使用付费 **Developer ID + 公证** 后，双击即开才可能成为默认体验。

## 升级

从首个接入 Sparkle 的版本开始，ZoneLaunch 每天检查一次更新。有新版本时，主窗口工具栏会出现蓝色小更新按钮；点击一次即可下载经 Ed25519 签名的压缩包，校验和安装完成后会自动重启。也可在主窗口工具栏或菜单栏打开 **关于**，查看当前版本并手动检查更新。

仍在使用不含更新器的旧版本时，需要最后手动替换一次 `/Applications/ZoneLaunch.app`。尽量只保留一个安装路径，避免 Dock 出现两个图标。

若你曾用源码里的 `./scripts/install-app.sh` 安装，该脚本还会清理历史 Bundle ID 与重复注册。纯 DMG/zip 安装时，先删旧再移入新版本通常即可。

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
