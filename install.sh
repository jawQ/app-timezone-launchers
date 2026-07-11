#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
macOS only. Windows and Linux are not supported.

Usage:
  ./install.sh              Install feishu-tz only
  ./install.sh --feishu     Install feishu-tz only
  ./install.sh --wechat     Install wechat-tz only
  ./install.sh --slack      Install slack-tz only
  ./install.sh --line       Install line-tz only
  ./install.sh --all        Install all launchers
  ./install.sh --prefix DIR Install into DIR instead of ~/.local/bin

Examples:
  ./install.sh
  ./install.sh --all
  ./install.sh --wechat --prefix /usr/local/bin
  ./install.sh --slack --line
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local/bin}"
INSTALL_FEISHU=0
INSTALL_WECHAT=0
INSTALL_SLACK=0
INSTALL_LINE=0
APP_SELECTED=0

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This project currently supports macOS only. Windows and Linux are not supported." >&2
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --feishu)
      INSTALL_FEISHU=1
      APP_SELECTED=1
      ;;
    --wechat)
      INSTALL_WECHAT=1
      APP_SELECTED=1
      ;;
    --slack)
      INSTALL_SLACK=1
      APP_SELECTED=1
      ;;
    --line)
      INSTALL_LINE=1
      APP_SELECTED=1
      ;;
    --all)
      INSTALL_FEISHU=1
      INSTALL_WECHAT=1
      INSTALL_SLACK=1
      INSTALL_LINE=1
      APP_SELECTED=1
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

if (( ! APP_SELECTED )); then
  INSTALL_FEISHU=1
fi

mkdir -p "$PREFIX"

install_command() {
  local command_name="$1"
  install -m 0755 "$SCRIPT_DIR/bin/$command_name" "$PREFIX/$command_name"
  echo "Installed $command_name -> $PREFIX/$command_name"
}

if (( INSTALL_FEISHU )); then
  install_command feishu-tz
fi

if (( INSTALL_WECHAT )); then
  install_command wechat-tz
fi

if (( INSTALL_SLACK )); then
  install_command slack-tz
fi

if (( INSTALL_LINE )); then
  install_command line-tz
fi

cat <<EOF

Done.
Make sure this directory is on PATH:
  $PREFIX

For zsh, add this to ~/.zshrc if needed:
  export PATH="\$HOME/.local/bin:\$PATH"
EOF
