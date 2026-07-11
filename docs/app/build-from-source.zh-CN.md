# 从源码构建 ZoneLaunch

[English](build-from-source.md)

适合贡献者，或希望自己本地构建、不下载 Release zip 的用户。

## 要求

- macOS 14+
- Xcode Command Line Tools（或完整 Xcode）及 Swift 6 工具链

## 构建并安装到「应用程序」

```bash
cd macos/AppTimezoneLauncher
./scripts/build-app.sh
./scripts/install-app.sh
open /Applications/ZoneLaunch.app
```

`install-app.sh` 会：

- 拒绝非规范 Bundle ID
- 清理曾导致双 Dock 图标的历史 ID / 旧应用名
- 仅注册 `/Applications/ZoneLaunch.app`

规范 Bundle ID：**`app.zonelaunch.launcher`**（见 `scripts/app-identity.sh`）。

## 打出版本包（与 CI 相同）

在仓库根目录：

```bash
./macos/AppTimezoneLauncher/scripts/package-release.sh 0.1.0
```

在 `dist/` 生成：

- `ZoneLaunch-0.1.0-macos.zip`
- `SHA256SUMS`

`dist/` 已被 gitignore。

## 验证

```bash
cd macos/AppTimezoneLauncher
swift test
./scripts/test-build-app.sh
./scripts/test-install-app.sh
codesign --verify --deep --strict ".build/app/ZoneLaunch.app"
plutil -extract CFBundleIdentifier raw ".build/app/ZoneLaunch.app/Contents/Info.plist"
```

## 另见

- [从 Release 安装](install-from-release.zh-CN.md)
- [概览](overview.zh-CN.md)
