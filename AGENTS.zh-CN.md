# 仓库指南

[English](AGENTS.md)

## 项目结构与模块组织

根目录的 `bin/` 包含 `feishu-tz`、`wechat-tz` 等 shell 启动命令；`install.sh`
会将它们安装到用户指定的前缀目录。面向用户的文档位于 `README.md` 和 `docs/`。

原生 App 是位于 `macos/AppTimezoneLauncher/` 的 Swift Package。将可复用的非 UI
逻辑放在 `Sources/AppTimezoneLauncherCore/`；SwiftUI 页面和 ViewModel 放在
`Sources/AppTimezoneLauncher/`。测试位于 `Tests/AppTimezoneLauncherTests/`，图标源文件
和生成资源位于 `Resources/`。不要编辑 `.build/` 或 `build/`，两者均为已忽略的生成目录。

## 构建、测试与开发命令

在仓库根目录使用 `./install.sh --feishu --wechat` 安装 shell 命令。在
`macos/AppTimezoneLauncher/` 中使用：

```bash
swift test
xcrun swift-format lint --recursive Sources Tests Package.swift
./scripts/build-app.sh
open "build/ZoneLaunch.app"
```

`build-app.sh` 会创建并以 ad-hoc 方式签名可分发 `.app`。`/Applications/ZoneLaunch.app`
中的安装副本是构建产物，不是 Git 工作区。请在本仓库修改代码、重新构建，需要时再替换已安装 App。

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
