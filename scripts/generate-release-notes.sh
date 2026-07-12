#!/usr/bin/env bash
# Build GitHub Release notes (English default + Chinese entry).
#
# Layout (inspired by structured multi-language notes, e.g. cc-switch):
#   - English is the default language on the Release page
#   - Chinese is linked at the top: **[中文 →](.../vX.Y.Z-zh.md)**
#   - Sections: Overview / Highlights / details + download footer
#
# Usage:
#   ./scripts/generate-release-notes.sh v0.1.2
#   ./scripts/generate-release-notes.sh v0.1.2 --output dist/RELEASE_NOTES.md
#
# Curated sources (optional, under docs/release-notes/):
#   vX.Y.Z-en.md   English body (**preferred** for GH Release description)
#   vX.Y.Z-zh.md   Chinese full notes (linked from the Release page)
#
# If curated EN is missing, notes are auto-built from git history
# (English layout; Chinese section in-body if no -zh.md, else link only).
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
  ./scripts/generate-release-notes.sh vX.Y.Z --write-zh-auto

English is the default Release body language; Chinese is a top entry link
(or an in-body 中文 section when no curated zh file exists).
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
  local log
  log="$(git log --pretty=format:'- %s' --no-merges "$range" 2>/dev/null || true)"
  if [[ -z "$log" ]]; then
    printf '%s\n' "- (no non-merge commits in this range)"
    return
  fi
  printf '%s\n' "$log"
}

highlight_bullets() {
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

zh_entry_link() {
  local tag="$1"
  local slug
  slug="$(repo_slug)"
  if [[ -f "$NOTES_DIR/${tag}-zh.md" ]]; then
    printf '**[中文 →](https://github.com/%s/blob/%s/docs/release-notes/%s-zh.md)**\n' \
      "$slug" "$tag" "$tag"
  else
    printf '**中文：** see the *中文* section below when present, or open install docs in [Simplified Chinese](https://github.com/%s/blob/master/docs/app/install-from-release.zh-CN.md).\n' \
      "$slug"
  fi
}

# Strip a leading "# ZoneLaunch ..." title from curated files (generator adds it).
strip_leading_title() {
  local file="$1"
  awk '
    BEGIN { skip=1 }
    skip && /^# ZoneLaunch/ { next }
    skip && /^[[:space:]]*$/ { next }
    { skip=0; print }
  ' "$file"
}

build_auto_en() {
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
  [[ -n "$highlights" ]] || highlights="- (none)"
  [[ -n "$files_stat" ]] || files_stat="(no diff stat)"

  local prev_label="${prev:-the initial commit}"

  cat <<EOF
# ZoneLaunch ${tag}

> ZoneLaunch **${version}** updates since **${prev_label}**. See **Highlights** and **Commits** below.

$(zh_entry_link "$tag")

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
EOF

  # If no curated Chinese file, embed a short 中文 section so CN users still see content on the Release page.
  if [[ ! -f "$NOTES_DIR/${tag}-zh.md" ]]; then
    cat <<EOF

---

## 中文

### 概览

ZoneLaunch ${tag} 相对 ${prev_label} 的更新。下列条目来自 git 提交说明原文。

**发布日期**：${date}

**更新规模**：${commits} commits | ${files_stat}

### 提交列表

${bullets}
EOF
  fi

  download_footer_en "$version"
}

build_from_curated_en() {
  local tag="$1"
  local version="${tag#v}"
  local en_path="$NOTES_DIR/${tag}-en.md"
  local date prev range commits files_stat en_body
  date="$(release_date "$tag")"
  prev="$(previous_tag "$tag")"
  range="$(resolve_range "$tag")"
  commits="$(commit_count "$range")"
  files_stat="$(diff_stat_line "$range")"
  [[ -n "$files_stat" ]] || files_stat="n/a"
  en_body="$(strip_leading_title "$en_path")"

  cat <<EOF
# ZoneLaunch ${tag}

$(zh_entry_link "$tag")

${en_body}

---

**Release date:** ${date}

**Scale:** ${commits} commits | ${files_stat}${prev:+ | since ${prev}}
EOF
  download_footer_en "$version"
}

# Draft Chinese file from git for maintainers.
build_auto_zh_file() {
  local tag="$1"
  local version="${tag#v}"
  local prev range commits files_stat date bullets
  prev="$(previous_tag "$tag")"
  range="$(resolve_range "$tag")"
  commits="$(commit_count "$range")"
  files_stat="$(diff_stat_line "$range")"
  date="$(release_date "$tag")"
  bullets="$(commit_bullets "$range")"
  [[ -n "$files_stat" ]] || files_stat="（无 diff 统计）"

  cat <<EOF
> ZoneLaunch **${version}** 相对 **${prev:-初始提交}** 的更新。

**[English →](https://github.com/$(repo_slug)/blob/${tag}/docs/release-notes/${tag}-en.md)**

---

## 概览

ZoneLaunch ${tag} 是 ${prev:-初始提交} 之后的一版更新。

**发布日期**：${date}

**更新规模**：${commits} commits | ${files_stat}

---

## 重点内容

$(highlight_bullets "$range")

---

## 提交列表

${bullets}
EOF
}

generate() {
  local tag="$1"
  local en_path="$NOTES_DIR/${tag}-en.md"

  if [[ -f "$en_path" ]]; then
    build_from_curated_en "$tag"
  else
    build_auto_en "$tag"
  fi
}

main() {
  local tag="" output="" do_print=0 write_zh_auto=0
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
      --write-zh-auto)
        write_zh_auto=1
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

  if (( write_zh_auto )); then
    mkdir -p "$NOTES_DIR"
    local zh_out="$NOTES_DIR/${tag}-zh.md"
    build_auto_zh_file "$tag" >"$zh_out"
    echo "Wrote $zh_out" >&2
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
