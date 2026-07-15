# WSL（Windows Subsystem for Linux）

[English](wsl.md)

很多 Windows 用户在 **WSL 终端**里开发，或从类 Linux 环境打开 **VS Code / Docker**。本路径覆盖这些场景，且**不改动** macOS 启动器。

## 从仓库克隆目录安装

```bash
./windows/wsl/install.sh           # run-with-tz、code-tz、docker-tz
./windows/wsl/install.sh --all     # 另含飞书/微信 Windows 互通包装
```

请在仓库根目录执行上述命令。

## 从 Windows Release 压缩包安装

解压 `app-timezone-launchers-<version>-windows.zip` 后，在解压所得的顶层目录中执行：

```bash
bash ./wsl/install.sh              # run-with-tz、code-tz、docker-tz
bash ./wsl/install.sh --all        # 另含飞书/微信 Windows 互通包装
```

默认前缀：WSL 发行版内的 `~/.local/bin`。

## Linux 侧工具（VS Code、Docker 等）

### 通用

```bash
run-with-tz Asia/Shanghai date
run-with-tz America/Los_Angeles -- your-command --flags
RUN_TZ=Asia/Tokyo run-with-tz -- node server.js
# 已设置 RUN_TZ 时，若首参不是 IANA 时区，可省略 --：
RUN_TZ=Asia/Shanghai run-with-tz date
```

### VS Code

```bash
code-tz .
CODE_TZ=America/Los_Angeles code-tz /path/to/project
CODE_BIN=code-insiders code-tz .
```

会为 WSL 内的 `code` CLI 及其子进程设置 `TZ`。部分 Windows 界面元素仍可能跟随系统区域设置；从本包装启动时，WSL 远端与集成终端更容易继承 `TZ`。

### Docker

```bash
# 仅影响 docker 客户端进程
docker-tz version

# 容器内时区（推荐）
docker-tz run --rm -e TZ=Asia/Shanghai alpine date

# 对普通 docker run 自动注入 -e TZ=（若你未自行传入）
DOCKER_INJECT_TZ=1 docker-tz run --rm alpine date
```

Compose 示例：

```yaml
services:
  app:
    image: alpine
    environment:
      TZ: Asia/Shanghai
```

**重要：** 只给 Docker CLI 设 `TZ` **不会**改变容器内部时间。请使用 `-e TZ=…` 或 Compose 的 `environment`。

## 从 WSL 启动 Windows 图形应用

```bash
# 从仓库克隆目录：
./windows/wsl/install.sh --feishu --wechat

# 从解压后的 Windows Release 压缩包：
bash ./wsl/install.sh --feishu --wechat

feishu-tz
LARK_TZ=America/Los_Angeles feishu-tz
WECHAT_TZ=Asia/Singapore wechat-tz
```

这些包装通过 Windows PowerShell（`powershell.exe` / `pwsh.exe`）给 **Windows 进程**注入 `TZ`。需要开启 WSL 与 Windows 的互通（现代 WSL 默认可用）。

可选：

```bash
export ZONELAUNCH_WINDOWS_BIN=/mnt/c/path/to/windows/bin
```

## 不要混用的路径

| 目标 | 使用 |
| --- | --- |
| WSL 内 Linux 二进制 / CLI | `run-with-tz` / `code-tz` / `docker-tz` |
| Windows `.exe`（飞书、微信） | WSL 的 `feishu-tz` / `wechat-tz`，或原生 `windows\bin\*.cmd` |
| macOS | 仅仓库根目录 `./install.sh` 与 `bin/*` |
