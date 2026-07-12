#!/usr/bin/env bash
# Build GitHub Release notes in the style of cc-switch:
#   - Chinese is the default language on the Release page
#   - English is a separate file with a top-of-page link
#   - Sections: 概览 / 重点内容 / 更新明细 + download footer
#
# Usage:
#   ./scripts/generate-release-notes.sh v0.1.2
#   ./scripts/generate-release-notes.sh v0.1.2 --output dist/RELEASE_NOTES.md
#
# Curated sources (optional, under docs/release-notes/):
#   vX.Y.Z-zh.md   Chinese body (preferred for GH Release description)
#   vX.Y.Z-en.md   English full notes (linked from the Release page)
#
# If curated files are missing, notes are auto-built from git history
# (Chinese layout + English section in the same body so no missing blob links).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

NOTES_DIR="docs/release-notes"
REPO_SLUG_DEFAULT="jawQ/app-timezone-launchers"

die() {
  echo "error: $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/generate-release-notes.sh vX.Y.Z [--output PATH] [--print]

Style follows https://github.com/farion1231/cc-switch/releases
(Chinese-first Release body + link to English notes).
EOF
}

normalize_tag() {
  local t="${1:-}"
  t="${t#v}"
  if [[ ! "$t" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    die "tag/version must be vX.Y.Z (got: ${1:-})"
  fi
  printf 'v%s\n' "$t"
}

repo_slug() {
  local remote owner repo
  remote="$(git remote get-url origin 2>/dev/null || true)"
  if [[ "$remote" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
    printf '%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]%.git}"
    return
  fi
  printf '%s\n' "$REPO_SLUG_DEFAULT"
}

list_release_tags() {
  git tag --list 'v*' 2>/dev/null \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    || true
}

previous_tag() {
  local tag="$1"
  local prev="" t
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    if [[ "$t" == "$tag" ]]; then
      printf '%s\n' "$prev"
      return 0
    fi
    prev="$t"
  done < <(list_release_tags)
  list_release_tags | tail -1 || true
}

resolve_range() {
  local tag="$1"
  local prev
  prev="$(previous_tag "$tag")"
  if [[ -n "$prev" ]]; then
    if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
      printf '%s\n' "${prev}..${tag}"
    else
      printf '%s\n' "${prev}..HEAD"
    fi
    return
  fi
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
    printf '%s\n' "$(git rev-list --max-parents=0 "$tag")..$tag"
  else
    printf '%s\n' "$(git rev-list --max-parents=0 HEAD)..HEAD"
  fi
}

commit_count() {
  git rev-list --count "$1" 2>/dev/null || echo 0
}

diff_stat_line() {
  # e.g. "12 files changed, 340 insertions(+), 20 deletions(-)"
  git diff --shortstat "$1" 2>/dev/null | sed 's/^ *//' || true
}

commit_bullets() {
  local range="$1"
  local log
  log="$(git log --pretty=format:'- %s' --no-merges "$range" 2>/dev/null || true)"
  if [[ -z "$log" ]]; then
    printf '%s\n' "- （本区间无非 merge 提交）"
    return
  fi
  printf '%s\n' "$log"
}

highlight_bullets() {
  # First up to 8 commit subjects as "重点内容"
  local range="$1"
  git log --pretty=format:'- %s' --no-merges "$range" 2>/dev/null | head -8 || true
}

release_date() {
  local tag="$1"
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
    git log -1 --format=%cs "$tag" 2>/dev/null || date +%F
  else
    date +%F
  fi
}

download_footer_zh() {
  local version="$1"
  cat <<EOF

---

## 下载与安装

**资源**

- \`ZoneLaunch-${version}-macos.zip\` — \`ZoneLaunch.app\` + \`README-FIRST.txt\`（ad-hoc 签名，**未公证**）
- \`SHA256SUMS\` — 校验和

**安装步骤**

1. 解压后将 **ZoneLaunch.app** 拖到「应用程序」。
2. 首次打开常被门禁拦截：点 **Done / 完成**，再到 **系统设置 → 隐私与安全性 → Open Anyway / 仍要打开**。
3. 图文说明：[从 Release 安装](https://github.com/$(repo_slug)/blob/master/docs/app/install-from-release.zh-CN.md)

**更轻量：Shell 启动命令**

\`\`\`bash
git clone https://github.com/$(repo_slug).git
cd app-timezone-launchers
./install.sh --feishu --wechat
\`\`\`

**应用身份：** Bundle ID \`app.zonelaunch.launcher\`
EOF
}

download_footer_en() {
  local version="$1"
  cat <<EOF

---

## Download & install

**Assets**

- \`ZoneLaunch-${version}-macos.zip\` — \`ZoneLaunch.app\` + \`README-FIRST.txt\` (ad-hoc signed, **not notarized**)
- \`SHA256SUMS\` — checksum

**Install**

1. Unzip and drag **ZoneLaunch.app** into Applications.
2. First open is often blocked by Gatekeeper: **Done**, then **System Settings → Privacy & Security → Open Anyway**.
3. Guide with screenshots: [Install from Releases](https://github.com/$(repo_slug)/blob/master/docs/app/install-from-release.md)

**Lighter path: shell launchers**

\`\`\`bash
git clone https://github.com/$(repo_slug).git
cd app-timezone-launchers
./install.sh --feishu --wechat
\`\`\`

**Identity:** Bundle ID \`app.zonelaunch.launcher\`
EOF
}

build_auto_zh() {
  local tag="$1"
  local version="${tag#v}"
  local prev range commits files_stat date highlights bullets
  prev="$(previous_tag "$tag")"
  range="$(resolve_range "$tag")"
  commits="$(commit_count "$range")"
  files_stat="$(diff_stat_line "$range")"
  date="$(release_date "$tag")"
  highlights="$(highlight_bullets "$range")"
  bullets="$(commit_bullets "$range")"
  [[ -n "$highlights" ]] || highlights="- （无）"
  [[ -n "$files_stat" ]] || files_stat="（无 diff 统计）"

  local prev_label="${prev:-初始提交}"
  local en_link=""
  if [[ -f "$NOTES_DIR/${tag}-en.md" ]]; then
    en_link="**[English →](https://github.com/$(repo_slug)/blob/${tag}/docs/release-notes/${tag}-en.md)**"
  else
    en_link="**English summary:** see the auto-generated English section below / 英文摘要见下方 *English* 小节。"
  fi

  cat <<EOF
# ZoneLaunch ${tag}

> ZoneLaunch **${version}** 相对 **${prev_label}** 的更新：脚本与 ZoneLaunch App 的文档、发版与安装体验改进。完整条目见下方「提交列表」。

${en_link}

---

## 概览

ZoneLaunch ${tag} 是 ${prev_label} 之后的一版更新，聚焦维护者发版体验、Release 说明与用户安装文档。

**发布日期**：${date}

**更新规模**：${commits} commits | ${files_stat}

---

## 重点内容

${highlights}

---

## 提交列表

${bullets}

---

## English (auto)

### Overview

ZoneLaunch ${tag} ships updates since ${prev_label}. Commit subjects below are as recorded in git.

**Release date:** ${date}

**Scale:** ${commits} commits | ${files_stat}

### Commits

${bullets}
EOF
  download_footer_zh "$version"
}

build_from_curated() {
  local tag="$1"
  local version="${tag#v}"
  local zh_path="$NOTES_DIR/${tag}-zh.md"
  local en_path="$NOTES_DIR/${tag}-en.md"
  local slug date prev range commits files_stat
  slug="$(repo_slug)"
  date="$(release_date "$tag")"
  prev="$(previous_tag "$tag")"
  range="$(resolve_range "$tag")"
  commits="$(commit_count "$range")"
  files_stat="$(diff_stat_line "$range")"
  [[ -n "$files_stat" ]] || files_stat="n/a"

  local en_link
  if [[ -f "$en_path" ]]; then
    en_link="**[English →](https://github.com/${slug}/blob/${tag}/docs/release-notes/${tag}-en.md)**"
  else
    en_link=""
  fi

  # Chinese-first body (cc-switch style): title → language link → curated zh → meta → download.
  local zh_body
  zh_body="$(cat "$zh_path")"

  cat <<EOF
# ZoneLaunch ${tag}

${en_link}

${zh_body}

---

**发布日期**：${date}

**更新规模**：${commits} commits | ${files_stat}${prev:+ | since ${prev}}
EOF
  download_footer_zh "$version"
}

# Optional: materialize English file content for maintainers when using --write-en-auto
build_auto_en_file() {
  local tag="$1"
  local version="${tag#v}"
  local prev range commits files_stat date bullets
  prev="$(previous_tag "$tag")"
  range="$(resolve_range "$tag")"
  commits="$(commit_count "$range")"
  files_stat="$(diff_stat_line "$range")"
  date="$(release_date "$tag")"
  bullets="$(commit_bullets "$range")"
  [[ -n "$files_stat" ]] || files_stat="(no diff stat)"

  cat <<EOF
# ZoneLaunch ${tag}

> Updates since **${prev:-the initial commit}**.

**[中文 →](https://github.com/$(repo_slug)/blob/${tag}/docs/release-notes/${tag}-zh.md)**

---

## Overview

ZoneLaunch ${version} is a maintenance release focused on documentation, release automation, and install guidance.

**Release date:** ${date}

**Scale:** ${commits} commits | ${files_stat}

---

## Highlights

$(highlight_bullets "$range")

---

## Commits

${bullets}
EOF
  download_footer_en "$version"
}

generate() {
  local tag="$1"
  local zh_path="$NOTES_DIR/${tag}-zh.md"

  if [[ -f "$zh_path" ]]; then
    build_from_curated "$tag"
  else
    build_auto_zh "$tag"
  fi
}

main() {
  local tag="" output="" do_print=0 write_en_auto=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      --output)
        [[ $# -ge 2 ]] || die "--output requires a path"
        output="$2"
        shift 2
        ;;
      --print)
        do_print=1
        shift
        ;;
      --write-en-auto)
        # Write docs/release-notes/vX.Y.Z-en.md from git (for maintainers)
        write_en_auto=1
        shift
        ;;
      -*)
        die "unknown option: $1"
        ;;
      *)
        [[ -z "$tag" ]] || die "unexpected argument: $1"
        tag="$1"
        shift
        ;;
    esac
  done

  [[ -n "$tag" ]] || die "missing version/tag (e.g. v0.1.2)"
  command -v git >/dev/null 2>&1 || die "missing git"
  tag="$(normalize_tag "$tag")"

  if (( write_en_auto )); then
    mkdir -p "$NOTES_DIR"
    local en_out="$NOTES_DIR/${tag}-en.md"
    build_auto_en_file "$tag" >"$en_out"
    echo "Wrote $en_out" >&2
  fi

  local notes
  notes="$(generate "$tag")"

  if [[ -n "$output" ]]; then
    mkdir -p "$(dirname "$output")"
    printf '%s\n' "$notes" >"$output"
    echo "Wrote $output" >&2
  fi

  if (( do_print )) || [[ -z "$output" ]]; then
    printf '%s\n' "$notes"
  fi
}

main "$@"
