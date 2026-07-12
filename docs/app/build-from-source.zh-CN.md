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

## 发布 GitHub Release（推荐）

完整维护者说明（前提、全部 `package.json` scripts、版本约定、排障）：

→ **[发布 Release](releasing.zh-CN.md)**

在**干净**的 `master` 且与 `origin/master` 一致时，快速开始：

```bash
npm run release:tag:dry-run        # 预览下一 tag
npm run release:tag                # 自动 patch 递增、打 tag、推送 → CI 打包上传
npm run release:tag -- 0.2.0       # 指定版本
```

| Script | 作用 |
| --- | --- |
| `npm run release:tag` | patch 递增 + tag + 推送 |
| `npm run release:tag -- X.Y.Z` | 指定版本 + tag + 推送 |
| `npm run release:tag:dry-run` | 仅预览 |
| `npm run release:tag:test` | 自检 |
| `npm run release:package` | 仅本地 zip（不发 GitHub Release） |
| `npm run release:notes -- vX.Y.Z` | 预览中英双语 Release 说明 |

与 supermarkets 的 `pnpm miniapp:tag` 同思路。实现：`scripts/release-tag.sh`，由根目录 `package.json` 调用。

## 打出版本包（仅本地，与 CI 相同）

```bash
npm run release:package -- 0.1.0
# 或：./macos/AppTimezoneLauncher/scripts/package-release.sh 0.1.0
```

在 `dist/` 生成 `ZoneLaunch-0.1.0-macos.zip`、`SHA256SUMS`（已 gitignore）。**不会**创建 GitHub Release。

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

- [发布 Release](releasing.zh-CN.md) — `npm run release:tag` 等
- [从 Release 安装](install-from-release.zh-CN.md)
- [概览](overview.zh-CN.md)
