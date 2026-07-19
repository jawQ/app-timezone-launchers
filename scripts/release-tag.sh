#!/usr/bin/env bash
# Local one-command GitHub Release for ZoneLaunch (same idea as supermarkets `pnpm miniapp:tag`).
#
# Default: bump patch on the latest vX.Y.Z tag, create annotated tag, push to origin,
# which triggers .github/workflows/release-macos-app.yml.
#
# Usage (npm scripts in package.json, or call the script directly):
#   npm run release:tag                   # auto patch bump + push
#   npm run release:tag -- 0.2.0
#   npm run release:tag:dry-run
#   npm run release:tag:test
#   ./scripts/release-tag.sh …            # same under the hood
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RELEASE_WORKFLOW="release-macos-app.yml"
TAG_PREFIX="v"

usage() {
  cat <<'EOF'
Usage (prefer npm scripts from repo root package.json):
  npm run release:tag                   Auto patch-bump latest vX.Y.Z, tag, push
  npm run release:tag -- X.Y.Z          Explicit version
  npm run release:tag:dry-run           Show the tag that would be created
  npm run release:tag:test              Run helper unit checks

Direct script (equivalent):
  ./scripts/release-tag.sh
  ./scripts/release-tag.sh X.Y.Z
  ./scripts/release-tag.sh --dry-run
  ./scripts/release-tag.sh --self-test
  ./scripts/release-tag.sh -h|--help

Docs: docs/app/releasing.md  |  docs/app/releasing.zh-CN.md

Requirements:
  - git on PATH
  - clean working tree
  - current branch is master
  - HEAD matches origin/master (after fetch)

Pushing the tag triggers GitHub Actions to build and attach ZoneLaunch-*-macos.dmg / .zip.
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

normalize_version() {
  local value="${1:-}"
  value="${value#v}"
  if [[ ! "$value" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    die "version must be semantic X.Y.Z (got: ${1:-})"
  fi
  printf '%s\n' "$value"
}

build_tag() {
  printf '%s%s\n' "$TAG_PREFIX" "$(normalize_version "$1")"
}

build_tag_message() {
  local tag_name="$1"
  printf 'release: ZoneLaunch %s\n' "$tag_name"
}

list_release_tags() {
  git tag --list 'v*' 2>/dev/null \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    || true
}

get_next_tag() {
  local latest
  # Always sort so callers (and tests) need not pre-order tags.
  latest="$(list_release_tags | sort -V | tail -1 || true)"
  if [[ -z "$latest" ]]; then
    printf 'v0.1.0\n'
    return
  fi
  local version="${latest#v}"
  local major minor patch
  IFS=. read -r major minor patch <<<"$version"
  printf 'v%s.%s.%s\n' "$major" "$minor" "$((patch + 1))"
}

parse_github_remote() {
  local remote_url="$1"
  local owner repo
  if [[ "$remote_url" =~ ^git@github\.com:([^/]+)/(.+)$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    repo="${repo%.git}"
    printf '%s %s\n' "$owner" "$repo"
    return 0
  fi
  if [[ "$remote_url" =~ ^https://github\.com/([^/]+)/(.+)$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    repo="${repo%.git}"
    printf '%s %s\n' "$owner" "$repo"
    return 0
  fi
  return 1
}

actions_workflow_url() {
  local remote_url owner repo
  remote_url="$(git remote get-url origin)"
  if ! read -r owner repo < <(parse_github_remote "$remote_url"); then
    return 1
  fi
  printf 'https://github.com/%s/%s/actions/workflows/%s\n' \
    "$owner" "$repo" "$RELEASE_WORKFLOW"
}

release_page_url() {
  local remote_url owner repo tag_name="$1"
  remote_url="$(git remote get-url origin)"
  if ! read -r owner repo < <(parse_github_remote "$remote_url"); then
    return 1
  fi
  printf 'https://github.com/%s/%s/releases/tag/%s\n' "$owner" "$repo" "$tag_name"
}

ensure_git() {
  command -v git >/dev/null 2>&1 || die "missing required command: git"
}

ensure_clean_working_tree() {
  local status
  status="$(git status --porcelain)"
  if [[ -n "$status" ]]; then
    die "working tree is not clean. Commit or stash changes before creating a release tag."
  fi
}

ensure_on_master() {
  local branch
  branch="$(git branch --show-current)"
  if [[ "$branch" != "master" ]]; then
    die "release tags must be created from master (current: ${branch:-detached})"
  fi
}

ensure_head_matches_origin_master() {
  git fetch origin master --tags
  local head origin_master
  head="$(git rev-parse HEAD)"
  origin_master="$(git rev-parse origin/master)"
  if [[ "$head" != "$origin_master" ]]; then
    die "HEAD does not match origin/master. Pull or push master so the release tag points at the published commit."
  fi
}

ensure_tag_missing() {
  local tag_name="$1"
  if git rev-parse -q --verify "refs/tags/$tag_name" >/dev/null 2>&1; then
    die "tag already exists: $tag_name"
  fi
}

run_self_test() {
  local failed=0
  assert_eq() {
    local got="$1" want="$2" name="$3"
    if [[ "$got" != "$want" ]]; then
      echo "FAIL $name: got '$got' want '$want'" >&2
      failed=1
    else
      echo "ok   $name"
    fi
  }

  assert_eq "$(normalize_version "1.2.3")" "1.2.3" "normalize plain"
  assert_eq "$(normalize_version "v2.3.4")" "2.3.4" "normalize leading v"
  assert_eq "$(build_tag "1.2.3")" "v1.2.3" "build_tag"
  assert_eq "$(build_tag_message "v1.2.3")" "release: ZoneLaunch v1.2.3" "tag message"

  # Isolate list_release_tags / get_next_tag with a stub
  list_release_tags() { printf ''; }
  assert_eq "$(get_next_tag)" "v0.1.0" "next when empty"

  list_release_tags() { printf '%s\n' "v0.1.0" "v0.1.2" "v0.2.0"; }
  assert_eq "$(get_next_tag)" "v0.2.1" "next patch from latest sorted"

  list_release_tags() { printf '%s\n' "v1.2.8" "v1.2.10" "v1.1.9"; }
  assert_eq "$(get_next_tag)" "v1.2.11" "next prefers highest semver"

  if parse_github_remote "git@github.com:jawQ/app-timezone-launchers.git" >/dev/null; then
    read -r o r < <(parse_github_remote "git@github.com:jawQ/app-timezone-launchers.git")
    assert_eq "$o/$r" "jawQ/app-timezone-launchers" "parse ssh remote"
  fi
  if parse_github_remote "https://github.com/jawQ/app-timezone-launchers.git" >/dev/null; then
    read -r o r < <(parse_github_remote "https://github.com/jawQ/app-timezone-launchers.git")
    assert_eq "$o/$r" "jawQ/app-timezone-launchers" "parse https remote"
  fi

  if (( failed )); then
    die "self-test failed"
  fi
  echo "All self-tests passed."
}

main() {
  local dry_run=0
  local explicit_version=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      --self-test)
        run_self_test
        exit 0
        ;;
      -*)
        die "unknown option: $1"
        ;;
      *)
        if [[ -n "$explicit_version" ]]; then
          die "unexpected extra argument: $1"
        fi
        explicit_version="$1"
        shift
        ;;
    esac
  done

  ensure_git

  local tag_name
  if [[ -n "$explicit_version" ]]; then
    tag_name="$(build_tag "$explicit_version")"
  else
    # Need tags from remote for accurate bump when possible
    if (( ! dry_run )); then
      ensure_clean_working_tree
      ensure_on_master
      ensure_head_matches_origin_master
    else
      git fetch origin master --tags >/dev/null 2>&1 || true
    fi
    tag_name="$(get_next_tag)"
  fi

  if (( dry_run )); then
    echo "Would create and push: $tag_name"
    if url="$(actions_workflow_url 2>/dev/null)"; then
      echo "Workflow: $url"
    fi
    exit 0
  fi

  if [[ -n "$explicit_version" ]]; then
    ensure_clean_working_tree
    ensure_on_master
    ensure_head_matches_origin_master
  fi

  ensure_tag_missing "$tag_name"

  local message
  message="$(build_tag_message "$tag_name")"
  git tag -a "$tag_name" -m "$message"
  git push origin "$tag_name"

  echo "Created and pushed $tag_name"
  if url="$(actions_workflow_url)"; then
    echo "GitHub Actions: $url"
  fi
  if url="$(release_page_url "$tag_name")"; then
    echo "Release page (after CI): $url"
  fi
  echo "Latest: https://github.com/jawQ/app-timezone-launchers/releases/latest"
}

main "$@"
