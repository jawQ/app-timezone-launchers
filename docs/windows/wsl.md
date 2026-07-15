# WSL (Windows Subsystem for Linux)

[Simplified Chinese](wsl.zh-CN.md)

Many Windows developers work in **WSL terminals** or open **VS Code / Docker** from a Linux-like environment. This path covers those cases without changing macOS launchers.

## Install from a repository clone

```bash
./windows/wsl/install.sh           # run-with-tz, code-tz, docker-tz
./windows/wsl/install.sh --all     # + Feishu/WeChat Windows interop wrappers
```

Run these commands from the repository root.

## Install from the Windows Release archive

After extracting `app-timezone-launchers-<version>-windows.zip`, run this from the extracted top-level folder:

```bash
bash ./wsl/install.sh              # run-with-tz, code-tz, docker-tz
bash ./wsl/install.sh --all        # + Feishu/WeChat Windows interop wrappers
```

Default prefix: `~/.local/bin` (inside the WSL distro).

## Linux-side tools (VS Code, Docker, anything)

### Generic

```bash
run-with-tz Asia/Shanghai date
run-with-tz America/Los_Angeles -- your-command --flags
RUN_TZ=Asia/Tokyo run-with-tz -- node server.js
# When RUN_TZ is set, -- is optional if the first arg is not an IANA id:
RUN_TZ=Asia/Shanghai run-with-tz date
```

### VS Code

```bash
code-tz .
CODE_TZ=America/Los_Angeles code-tz /path/to/project
CODE_BIN=code-insiders code-tz .
```

This sets `TZ` for the `code` CLI process and children started from WSL. Some Windows UI chrome may still follow Windows regional settings; WSL remote servers and integrated terminals usually pick up `TZ` more reliably when launched this way.

### Docker

```bash
# Client process only
docker-tz version

# Container time zone (recommended)
docker-tz run --rm -e TZ=Asia/Shanghai alpine date

# Auto-inject -e TZ= for plain `docker run` (when you did not pass TZ yourself)
DOCKER_INJECT_TZ=1 docker-tz run --rm alpine date
```

Compose example:

```yaml
services:
  app:
    image: alpine
    environment:
      TZ: Asia/Shanghai
```

**Important:** `TZ` on the Docker CLI alone does not change time *inside* a container. Prefer `-e TZ=…` / Compose `environment`.

## Launch Windows GUI apps from WSL

```bash
# From a repository clone:
./windows/wsl/install.sh --feishu --wechat

# From the extracted Windows Release archive:
bash ./wsl/install.sh --feishu --wechat

feishu-tz
LARK_TZ=America/Los_Angeles feishu-tz
WECHAT_TZ=Asia/Singapore wechat-tz
```

These wrappers call Windows PowerShell (`powershell.exe` / `pwsh.exe`) so `TZ` is applied to the **Windows** process. Requires WSL interop (default on Docker Desktop / modern WSL).

Optional:

```bash
export ZONELAUNCH_WINDOWS_BIN=/mnt/c/path/to/windows/bin
```

## What not to mix up

| Goal | Use |
| --- | --- |
| Linux binary / CLI in WSL | `run-with-tz` / `code-tz` / `docker-tz` |
| Windows `.exe` (Feishu, WeChat) | WSL `feishu-tz` / `wechat-tz` **or** native `windows\bin\*.cmd` |
| macOS | Repo-root `./install.sh` and `bin/*` only |
