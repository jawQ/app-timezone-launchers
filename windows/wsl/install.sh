#!/usr/bin/env bash
# Install WSL (Linux-side) timezone helpers into a prefix (default: ~/.local/bin).
# Does not touch macOS install.sh or Windows install.ps1.
#
# Usage:
#   ./install.sh                 # run-with-tz + code-tz + docker-tz
#   ./install.sh --all           # helpers + feishu-tz + wechat-tz interop
#   ./install.sh --feishu --wechat
#   ./install.sh --prefix DIR

set -euo pipefail

usage() {
  cat <<'EOF'
WSL / Linux-side installers (for use inside a WSL distro).

Usage:
  ./install.sh              Install run-with-tz, code-tz, docker-tz
  ./install.sh --tools      Same as default (Linux-side tools)
  ./install.sh --feishu     Also install feishu-tz (Windows app interop)
  ./install.sh --wechat     Also install wechat-tz (Windows app interop)
  ./install.sh --all        Tools + Feishu + WeChat interop
  ./install.sh --prefix DIR Install into DIR (default: ~/.local/bin)

Examples:
  ./install.sh
  ./install.sh --all
  ./install.sh --prefix "$HOME/.local/bin"
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIN_BIN_DIR="$(cd "$SCRIPT_DIR/../bin" && pwd)"
PREFIX="${PREFIX:-$HOME/.local/bin}"
INSTALL_TOOLS=1
INSTALL_FEISHU=0
INSTALL_WECHAT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tools)
      INSTALL_TOOLS=1
      ;;
    --feishu)
      INSTALL_FEISHU=1
      ;;
    --wechat)
      INSTALL_WECHAT=1
      ;;
    --all)
      INSTALL_TOOLS=1
      INSTALL_FEISHU=1
      INSTALL_WECHAT=1
      ;;
    --prefix)
      if [[ $# -lt 2 ]]; then
        echo "--prefix requires a directory." >&2
        exit 1
      fi
      PREFIX="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

mkdir -p "$PREFIX"

install_cmd() {
  local name="$1"
  local src="$SCRIPT_DIR/bin/$name"
  if [[ ! -f "$src" ]]; then
    echo "Missing source: $src" >&2
    exit 1
  fi
  install -m 0755 "$src" "$PREFIX/$name"
  echo "Installed $name -> $PREFIX/$name"
}

if (( INSTALL_TOOLS )); then
  install_cmd run-with-tz
  install_cmd code-tz
  install_cmd docker-tz
fi

# Windows .ps1 helpers must sit beside WSL interop wrappers after install.
copy_win_ps1() {
  local name="$1"
  install -m 0644 "$WIN_BIN_DIR/${name}.ps1" "$PREFIX/${name}.ps1"
  install -m 0644 "$WIN_BIN_DIR/_lib.ps1" "$PREFIX/_lib.ps1"
  echo "Installed ${name}.ps1 + _lib.ps1 (Windows interop) -> $PREFIX"
}

if (( INSTALL_FEISHU )); then
  install_cmd feishu-tz
  copy_win_ps1 feishu-tz
fi

if (( INSTALL_WECHAT )); then
  install_cmd wechat-tz
  copy_win_ps1 wechat-tz
fi

printf '\nDone.\nMake sure this directory is on PATH:\n  %s\n\n' "$PREFIX"
printf 'For bash, add if needed:\n  export PATH=%q:"$PATH"\n\n' "$PREFIX"
printf 'Examples:\n'
if (( INSTALL_TOOLS )); then
  printf '  run-with-tz Asia/Shanghai date\n'
  printf '  code-tz .\n'
  printf '  docker-tz run --rm -e TZ=Asia/Shanghai alpine date\n'
fi
if (( INSTALL_FEISHU )); then
  printf '  LARK_TZ=America/Los_Angeles feishu-tz   # Windows Feishu via interop\n'
fi
if (( INSTALL_WECHAT )); then
  printf '  WECHAT_TZ=Asia/Singapore wechat-tz      # Windows WeChat via interop\n'
fi
cat <<'EOF'

Native Windows (CMD/PowerShell): use install.ps1 from the matching source tree or release archive.
macOS: use the repository-root install.sh.
EOF
