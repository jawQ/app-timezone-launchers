#!/usr/bin/env bash
# Build GitHub Release notes: always both languages.
#
# - English file / Release body: English UI only (commit subjects as in git)
# - Chinese file: Chinese UI only (commit subjects as in git)
# - GitHub Release page defaults to English and links to full Chinese notes
#
# Usage:
#   ./scripts/generate-release-notes.sh v0.1.2
#   ./scripts/generate-release-notes.sh v0.1.2 --output dist/RELEASE_NOTES.md
#   ./scripts/generate-release-notes.sh v0.1.2 --write-files   # write/update docs/release-notes/v*-{en,zh}.md
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
  ./scripts/generate-release-notes.sh vX.Y.Z --write-files

Every release has two languages:
  - English (default on GitHub Release page)
  - Chinese (entry link → full Chinese notes)

English body never embeds Chinese prose (except raw git commit subjects).
Chinese notes never embed English prose (except raw git commit subjects).

Curated sources (preferred):
  docs/release-notes/vX.Y.Z-en.md
  docs/release-notes/vX.Y.Z-zh.md

If either is missing, it is auto-generated from git for that language only.
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
  local remote
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
  git diff --shortstat "$1" 2>/dev/null | sed 's/^ *//' || true
}

commit_bullets() {
  local range="$1"
  local empty_msg="$2"
  local log
  log="$(git log --pretty=format:'- %s' --no-merges "$range" 2>/dev/null || true)"
  if [[ -z "$log" ]]; then
    printf '%s\n' "$empty_msg"
    return
  fi
  printf '%s\n' "$log"
}

highlight_bullets() {
  local range="$1"
  local empty_msg="$2"
  local log
  log="$(git log --pretty=format:'- %s' --no-merges "$range" 2>/dev/null | head -8 || true)"
  if [[ -z "$log" ]]; then
    printf '%s\n' "$empty_msg"
    return
  fi
  printf '%s\n' "$log"
}

release_date() {
  local tag="$1"
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
    git log -1 --format=%cs "$tag" 2>/dev/null || date +%F
  else
    date +%F
  fi
}

strip_leading_title() {
  local file="$1"
  awk '
    BEGIN { skip=1 }
    skip && /^# ZoneLaunch/ { next }
    skip && /^[[:space:]]*$/ { next }
    { skip=0; print }
  ' "$file"
}

# --- English content (English UI only) ---

build_en_auto() {
  local tag="$1"
  local version="${tag#v}"
  local prev range commits files_stat date highlights bullets
  prev="$(previous_tag "$tag")"
  range="$(resolve_range "$tag")"
  commits="$(commit_count "$range")"
  files_stat="$(diff_stat_line "$range")"
  date="$(release_date "$tag")"
  highlights="$(highlight_bullets "$range" "- (none)")"
  bullets="$(commit_bullets "$range" "- (no non-merge commits in this range)")"
  [[ -n "$files_stat" ]] || files_stat="(no diff stat)"
  local prev_label="${prev:-the initial commit}"

  cat <<EOF
# ZoneLaunch ${tag}

> ZoneLaunch **${version}** updates since **${prev_label}**.

---

## Overview

ZoneLaunch ${tag} is a release after ${prev_label}, covering documentation, packaging, and install guidance for shell launchers and the ZoneLaunch app.

**Release date:** ${date}

**Scale:** ${commits} commits | ${files_stat}

---

## Highlights

${highlights}

---

## Commits

${bullets}

_Commit subjects are shown as recorded in git (may be Chinese or English)._

---

## Download & install

**Assets**

- \`ZoneLaunch-${version}-macos.zip\` — \`ZoneLaunch.app\` + \`README-FIRST.txt\` (ad-hoc signed, **not notarized**)
- \`SHA256SUMS\` — checksum
- \`RELEASE_NOTES.zh-CN.md\` — full release notes in Chinese

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

build_en_from_curated() {
  local tag="$1"
  local version="${tag#v}"
  local en_path="$NOTES_DIR/${tag}-en.md"
  local date prev range commits files_stat body
  date="$(release_date "$tag")"
  prev="$(previous_tag "$tag")"
  range="$(resolve_range "$tag")"
  commits="$(commit_count "$range")"
  files_stat="$(diff_stat_line "$range")"
  [[ -n "$files_stat" ]] || files_stat="n/a"
  body="$(strip_leading_title "$en_path")"

  cat <<EOF
# ZoneLaunch ${tag}

${body}

---

**Release date:** ${date}

**Scale:** ${commits} commits | ${files_stat}${prev:+ | since ${prev}}

---

## Download & install

**Assets**

- \`ZoneLaunch-${version}-macos.zip\` — \`ZoneLaunch.app\` + \`README-FIRST.txt\` (ad-hoc signed, **not notarized**)
- \`SHA256SUMS\` — checksum
- \`RELEASE_NOTES.zh-CN.md\` — full release notes in Chinese

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

# --- Chinese content (Chinese UI only) ---

build_zh_auto() {
  local tag="$1"
  local version="${tag#v}"
  local prev range commits files_stat date highlights bullets
  prev="$(previous_tag "$tag")"
  range="$(resolve_range "$tag")"
  commits="$(commit_count "$range")"
  files_stat="$(diff_stat_line "$range")"
  date="$(release_date "$tag")"
  highlights="$(highlight_bullets "$range" "- （无）")"
  bullets="$(commit_bullets "$range" "- （本区间无非 merge 提交）")"
  [[ -n "$files_stat" ]] || files_stat="（无 diff 统计）"
  local prev_label="${prev:-初始提交}"

  cat <<EOF
# ZoneLaunch ${tag}

> ZoneLaunch **${version}** 相对 **${prev_label}** 的更新。

---

## 概览

ZoneLaunch ${tag} 是 ${prev_label} 之后的一版更新，涵盖脚本启动器与 ZoneLaunch App 的文档、打包与安装说明。

**发布日期**：${date}

**更新规模**：${commits} commits | ${files_stat}

---

## 重点内容

${highlights}

---

## 提交列表

${bullets}

_提交说明保持 git 原文（可能为中文或英文）。_

---

## 下载与安装

**资源**

- \`ZoneLaunch-${version}-macos.zip\` — \`ZoneLaunch.app\` + \`README-FIRST.txt\`（ad-hoc 签名，**未公证**）
- \`SHA256SUMS\` — 校验和
- \`RELEASE_NOTES.md\` — 英文版更新说明（GitHub Release 默认展示）

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

build_zh_from_curated() {
  local tag="$1"
  local version="${tag#v}"
  local zh_path="$NOTES_DIR/${tag}-zh.md"
  local date prev range commits files_stat body
  date="$(release_date "$tag")"
  prev="$(previous_tag "$tag")"
  range="$(resolve_range "$tag")"
  commits="$(commit_count "$range")"
  files_stat="$(diff_stat_line "$range")"
  [[ -n "$files_stat" ]] || files_stat="n/a"
  body="$(strip_leading_title "$zh_path")"

  # If curated already has download section, still wrap with title/meta when missing title
  cat <<EOF
# ZoneLaunch ${tag}

${body}

---

**发布日期**：${date}

**更新规模**：${commits} commits | ${files_stat}${prev:+ | 自 ${prev} 起}
EOF
}

resolve_en_content() {
  local tag="$1"
  if [[ -f "$NOTES_DIR/${tag}-en.md" ]]; then
    build_en_from_curated "$tag"
  else
    build_en_auto "$tag"
  fi
}

resolve_zh_content() {
  local tag="$1"
  if [[ -f "$NOTES_DIR/${tag}-zh.md" ]]; then
    build_zh_from_curated "$tag"
  else
    build_zh_auto "$tag"
  fi
}

# English Release body: English notes + Chinese entry only (no Chinese prose).
build_release_body_en() {
  local tag="$1"
  local version="${tag#v}"
  local slug en_body
  slug="$(repo_slug)"
  en_body="$(resolve_en_content "$tag")"
  # Drop leading H1 from content so we control title + 中文 link placement
  en_body="$(printf '%s\n' "$en_body" | awk '
    BEGIN { skip=1 }
    skip && /^# ZoneLaunch/ { next }
    skip && /^[[:space:]]*$/ { next }
    { skip=0; print }
  ')"

  cat <<EOF
# ZoneLaunch ${tag}

**[中文 →](https://github.com/${slug}/blob/${tag}/docs/release-notes/${tag}-zh.md)**

${en_body}
EOF
}

write_notes_files() {
  local tag="$1"
  mkdir -p "$NOTES_DIR"

  # Prefer existing curated sources; only draft missing language files.
  if [[ ! -f "$NOTES_DIR/${tag}-en.md" ]]; then
    build_en_auto "$tag" >"$NOTES_DIR/${tag}-en.md"
    echo "Wrote $NOTES_DIR/${tag}-en.md (auto English draft)" >&2
  else
    echo "Keep existing $NOTES_DIR/${tag}-en.md" >&2
  fi

  if [[ ! -f "$NOTES_DIR/${tag}-zh.md" ]]; then
    build_zh_auto "$tag" >"$NOTES_DIR/${tag}-zh.md"
    echo "Wrote $NOTES_DIR/${tag}-zh.md (auto Chinese draft)" >&2
  else
    echo "Keep existing $NOTES_DIR/${tag}-zh.md" >&2
  fi
}

main() {
  local tag="" output="" do_print=0 write_files=0
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
      --write-files)
        write_files=1
        shift
        ;;
      --write-zh-auto | --write-en-auto)
        # Back-compat aliases → always both files
        write_files=1
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

  if (( write_files )); then
    write_notes_files "$tag"
  fi

  mkdir -p dist
  local en_body zh_body
  en_body="$(build_release_body_en "$tag")"
  zh_body="$(resolve_zh_content "$tag")"

  # Always materialize both language artifacts for CI / local inspection
  printf '%s\n' "$en_body" >"dist/RELEASE_NOTES.md"
  printf '%s\n' "$zh_body" >"dist/RELEASE_NOTES.zh-CN.md"
  echo "Wrote dist/RELEASE_NOTES.md (English, GitHub Release body)" >&2
  echo "Wrote dist/RELEASE_NOTES.zh-CN.md (Chinese, full notes)" >&2

  if [[ -n "$output" && "$output" != "dist/RELEASE_NOTES.md" ]]; then
    mkdir -p "$(dirname "$output")"
    printf '%s\n' "$en_body" >"$output"
    echo "Wrote $output" >&2
  fi

  if (( do_print )); then
    printf '%s\n' "$en_body"
  fi
}

main "$@"
