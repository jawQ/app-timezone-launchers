# ZoneLaunch（macOS）

将 macOS 应用拖入时区分组，再以分组指定的 `TZ` 值启动。

> 仅支持 macOS 14 及更高版本，仅供本地自用。

## 构建与运行

```bash
cd macos/AppTimezoneLauncher
./scripts/build-app.sh
./scripts/install-app.sh
open "/Applications/ZoneLaunch.app"
```

构建产物使用 ad-hoc 签名，不需要付费 Apple Developer 账号。
Bundle ID 固定为公开的 `io.github.jawq.zonelaunch`。

## 使用

- 将 `.app` 应用包拖入窗口。
- 选择或新建时区分组。
- 点击应用卡片上的 `Launch`。
- 需要以不同时区启动同一应用时，可将其添加到多个分组。

## 作用范围

- 只有新启动的应用会收到 `TZ`；macOS、终端和已运行的应用不会改变。
- 目标应用必须尊重 `TZ`。部分页面仍可能由账号、服务端或设备设置控制。
- 此本地构建未经公证，也未启用 Apple App Sandbox。
- 不支持 Windows 和 Linux。

## 验证

```bash
swift test
./scripts/build-app.sh
./scripts/test-build-app.sh
./scripts/test-install-app.sh
codesign --verify --deep --strict ".build/app/ZoneLaunch.app"
```
