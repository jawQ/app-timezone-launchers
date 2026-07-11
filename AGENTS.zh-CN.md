# 仓库指南

[English](AGENTS.md)

## 项目结构与模块组织

根目录的 `bin/` 包含 `feishu-tz`、`wechat-tz` 等 shell 启动命令；`install.sh`
会将它们安装到用户指定的前缀目录。面向用户的文档位于 `README.md` / `README.zh-CN.md`
与分模块的 `docs/`：

- `docs/scripts/` — shell 启动命令（主路径、最轻量）
- `docs/app/` — ZoneLaunch 图形界面（可选、体验更好）
- `docs/superpowers/` 与 `.superpowers/` — 仅内部 agent/设计笔记（已 gitignore）

原生 App 是位于 `macos/AppTimezoneLauncher/` 的 Swift Package。将可复用的非 UI
逻辑放在 `Sources/AppTimezoneLauncherCore/`；SwiftUI 页面和 ViewModel 放在
`Sources/AppTimezoneLauncher/`。测试位于 `Tests/AppTimezoneLauncherTests/`，图标源文件
和生成资源位于 `Resources/`。不要编辑 `.build/` 或 `build/`，两者均为已忽略的生成目录。
Release zip 输出到 `dist/`（同样已忽略）。

### GitHub Releases（App zip，无需付费苹果账号）

推送匹配 `v*` 的 tag 会在 `macos-latest` 上运行 `.github/workflows/release-macos-app.yml`：
测试、`package-release.sh`，并上传 `ZoneLaunch-<version>-macos.zip` 与 `SHA256SUMS`。
构建仅为 **ad-hoc 签名**（无 Developer ID / 公证）。本地打包：

```bash
./macos/AppTimezoneLauncher/scripts/package-release.sh 0.1.0
```

## 应用身份

公开且稳定的 macOS Bundle ID 为 **`app.zonelaunch.launcher`**，对所有构建与安装强绑定：凡从本仓库
构建/分发的 ZoneLaunch，在任何机器、fork、发布版本中都必须使用同一 ID。唯一真相源是
`macos/AppTimezoneLauncher/scripts/app-identity.sh`（由 `build-app.sh` 与 `install-app.sh` 引用）。
不得替换为个人、GitHub 用户或本地开发用 ID。

`install-app.sh` 必须保证 Dock / LaunchServices 只有一个应用入口：拒绝非规范 Bundle ID 的构建产物，
清理安装目录下的历史 Bundle ID（当前含 `io.github.jawq.zonelaunch`）与历史应用名，注销已知会
产生双图标的路径，仅强制注册 `ZoneLaunch.app`，并执行 LaunchServices 垃圾回收。若确需再次迁移
身份，必须扩展 `LEGACY_BUNDLE_IDS` / 清理逻辑，并保持安装回归测试通过。

## 构建、测试与开发命令

在仓库根目录使用 `./install.sh --feishu --wechat` 安装 shell 命令。在
`macos/AppTimezoneLauncher/` 中使用：

```bash
swift test
xcrun swift-format lint --recursive Sources Tests Package.swift
./scripts/build-app.sh
./scripts/install-app.sh
open "/Applications/ZoneLaunch.app"
```

`build-app.sh` 会创建并以 ad-hoc 方式签名可分发 `.app`。`/Applications/ZoneLaunch.app`
中的安装副本是构建产物，不是 Git 工作区。请在本仓库修改代码、重新构建，需要时再替换已安装 App。

### 每次改动后：自动重新构建并安装

只要改动了 macOS App（Swift 源码、资源、`Package.swift` 或构建/安装脚本），**结束时必须重新
构建并安装**，保证 `/Applications/ZoneLaunch.app` 与工作区一致：

```bash
cd macos/AppTimezoneLauncher
swift test
./scripts/build-app.sh
./scripts/install-app.sh
```

在每个完成的改动集末尾执行，而不是只在提交前执行。仅文档类、或明确不影响已安装 App 的改动
可以跳过。

## 编码风格与命名规范

使用 Swift 6 和 macOS 14 API。遵循 `swift-format`；现有 Swift 代码使用两个空格缩进。
类型使用 `UpperCamelCase`，成员使用 `lowerCamelCase`，文件名应对应主要类型，例如
`ConfigurationStore.swift`。将 UI 状态放在 ViewModel，将解析、启动和持久化逻辑放在核心
target。Shell 脚本使用 `#!/usr/bin/env bash` 和 `set -euo pipefail`。

## 测试规范

在 `LauncherModelTests.swift` 中使用 Swift Testing（`@Test`、`#expect`）。测试名称应
描述行为，例如 `configurationStoreUsesEnvironmentConfigPathOverride`。修改共享解析、持久化、
时区注入或启动行为时必须补充测试。提交改动前运行完整测试套件和格式检查。

## 提交与合并请求规范

近期提交使用 Conventional Commit 前缀，可选 emoji，例如 `feat: add app timezone
launchers` 或 `🎉 feat: add macOS launcher`。保持每个提交聚焦，并使用祈使式摘要。合并请求
应说明用户可见效果、列出验证命令、在可用时关联 Issue；SwiftUI 改动需附截图。
不要提交生成的构建产物、日志、个人路径或凭据。
