# Windows package sources

Native **CMD / PowerShell** launchers, **WSL** helpers, and packaging scripts.

User-facing docs: [`docs/windows/`](../docs/windows/overview.md)

| Path | Role |
| --- | --- |
| `bin/` | `*.ps1` + `*.cmd` (Feishu, WeChat, Slack, LINE) |
| `install.ps1` | Install native launchers; optional user PATH |
| `wsl/` | Linux-side tools in WSL + Windows app interop |
| `scripts/package-scripts.sh` | Build `app-timezone-launchers-<ver>-windows.zip` |

macOS code stays under `bin/`, `install.sh`, and `macos/` — do not merge platforms.
