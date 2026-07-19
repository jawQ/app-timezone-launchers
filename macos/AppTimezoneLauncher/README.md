# ZoneLaunch（macOS）

可选的图形界面：将 macOS 应用拖入时区分组，再以分组的 `TZ` 启动。

> 仅支持 macOS 14+。脚本启动仍是大多数场景的首选，见仓库根目录 [README](../../README.zh-CN.md)。

## 用户文档

| 文档 | 说明 |
| --- | --- |
| [概览](../../docs/app/overview.zh-CN.md) / [Overview](../../docs/app/overview.md) | 脚本 vs App |
| [从 Release 安装](../../docs/app/install-from-release.zh-CN.md) | 下载 zip（推荐） |
| [从源码构建](../../docs/app/build-from-source.zh-CN.md) | 本地构建与打包 |
| [发布 Release](../../docs/app/releasing.zh-CN.md) / [Publishing](../../docs/app/releasing.md) | 维护者发版：`npm run release:tag` |

预构建下载：https://github.com/jawQ/app-timezone-launchers/releases/latest

维护者发版（仓库根目录）：

```bash
npm run release:tag:dry-run
npm run release:tag
```

## 快速本地构建

```bash
cd macos/AppTimezoneLauncher
./scripts/build-app.sh
./scripts/install-app.sh
open "/Applications/ZoneLaunch.app"
```

Bundle ID **强绑定**为 `app.zonelaunch.launcher`（`scripts/app-identity.sh`）。  
`install-app.sh` 会清理历史 ID / 旧应用名，避免双 Dock 图标。

打 Release 同款 zip + dmg：

```bash
# 仓库根目录
./macos/AppTimezoneLauncher/scripts/package-release.sh 0.1.0
# → dist/ZoneLaunch-0.1.0-macos.zip  (Sparkle / 压缩包安装)
# → dist/ZoneLaunch-0.1.0-macos.dmg  (推荐：打开后拖到 Applications)
```

## 验证

```bash
swift test
./scripts/test-build-app.sh
./scripts/test-install-app.sh
codesign --verify --deep --strict ".build/app/ZoneLaunch.app"
```
