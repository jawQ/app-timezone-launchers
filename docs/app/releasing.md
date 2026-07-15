# Publishing ZoneLaunch releases

[Simplified Chinese](releasing.zh-CN.md)

How maintainers cut a GitHub Release from the terminal — no need to use the GitHub website form.

## Prerequisites

1. Node.js / npm available (only used to run scripts in root `package.json`; no install step).
2. `git` on `PATH`, push access to `origin`.
3. **Clean working tree** (`git status` empty).
4. Branch is **`master`**.
5. **`HEAD` matches `origin/master`** (commit and `git push origin master` first if you have local commits).

Pushing a tag `vX.Y.Z` triggers [`.github/workflows/release-macos-app.yml`](../../.github/workflows/release-macos-app.yml): Swift tests, package zip, upload assets.

## `package.json` scripts

Run from the **repository root**.

| npm script | What it does |
| --- | --- |
| `npm run release:tag` | Auto **patch** bump from latest `vX.Y.Z` (e.g. `v0.1.0` → `v0.1.1`), create annotated tag, **push** → CI release |
| `npm run release:tag -- 0.2.0` | Explicit version (`v0.2.0`); still tag + push |
| `npm run release:tag:dry-run` | Print the next auto tag and workflow URL; **no** tag, **no** push |
| `npm run release:tag:test` | Self-test version helpers |
| `npm run test:release-tag` | Same as `release:tag:test` |
| `npm run release:package` | Local zip only via `package-release.sh` (optional version: `npm run release:package -- 0.1.1`) — **does not** create a GitHub Release |
| `npm run release:notes -- v0.1.2` | Preview **bilingual** release notes (EN + 中文) for a tag |

Equivalent without npm:

```bash
./scripts/release-tag.sh
./scripts/release-tag.sh 0.2.0
./scripts/release-tag.sh --dry-run
./scripts/release-tag.sh --self-test
./macos/AppTimezoneLauncher/scripts/package-release.sh 0.1.1
```

## VS Code / Cursor task (quick trigger)

[`.vscode/tasks.json`](../../.vscode/tasks.json) exposes a single task:

**Command Palette** → **Tasks: Run Task** → **`release:tag`**

Same as `pnpm release:tag` (auto patch-bump + push tag → CI).

Requires clean `master` matching `origin/master` (push commits first if needed).

## Recommended flow

```bash
# 1. Land all changes on origin
git status
git add -A && git commit -m "…"   # if needed
git push origin master

# 2. Preview next version (optional)
npm run release:tag:dry-run
# → e.g. Would create and push: v0.1.1

# 3. Publish
npm run release:tag
# or VS Code / Cursor: Tasks: Run Task → release:tag

# 4. Wait for CI (optional)
gh run watch
gh release view   # or open the URL printed by the script
```

After CI finishes, users download from:

https://github.com/jawQ/app-timezone-launchers/releases/latest

## Version policy

| Situation | Command |
| --- | --- |
| Docs / small fixes | `npm run release:tag` (patch) |
| Features / API surface | `npm run release:tag -- 0.2.0` (minor) |
| Breaking / major | `npm run release:tag -- 1.0.0` |

Tags must look like `v1.2.3` (three numeric parts). The workflow matches `v*`.

## What gets published

- `ZoneLaunch-<version>-macos.zip` — ad-hoc signed app + `README-FIRST.txt`
- `app-timezone-launchers-<version>-windows.zip` — native CMD/PowerShell launchers + WSL helpers
- `ZoneLaunch-cli-<version>-windows-amd64.zip` — Windows CLI for Intel/AMD PCs
- `ZoneLaunch-cli-<version>-windows-arm64.zip` — Windows CLI for ARM/Snapdragon PCs
- `SHA256SUMS` — checksums for all four platform archives
- **Release notes (always both languages)**
  - English: Release page body (`RELEASE_NOTES.md`)
  - Chinese: top **[中文 →]** opens `docs/release-notes/vX.Y.Z-zh.md` on GitHub; `RELEASE_NOTES.zh-CN.md` remains a download asset
- GitHub’s automatic source zip/tar (not the app)

Builds are **not notarized**. End-user Gatekeeper steps: [Install from Releases](install-from-release.md).

## Release notes (always EN + ZH, separate files)

| | English | Chinese |
| --- | --- | --- |
| Prose language | English only | Chinese only |
| GitHub | **Default body** | **[中文 →]** → rendered `docs/release-notes/vX.Y.Z-zh.md` |
| Optional curated | `docs/release-notes/vX.Y.Z-en.md` | `docs/release-notes/vX.Y.Z-zh.md` |

Commit subjects are **not** translated. Do not mix languages inside one notes file.

Every release **always** produces both files (curated if present, otherwise auto from git for that language).

```bash
./scripts/generate-release-notes.sh v0.1.2 --write-files   # draft both if missing
pnpm release:notes -- v0.1.2                               # preview → dist/RELEASE_NOTES*.md
```

See [docs/release-notes/README.md](../release-notes/README.md).

## Relation to supermarkets

Same idea as `pnpm miniapp:tag` there: a local script creates and pushes a version tag; CI does the heavy build/upload.

| supermarkets | this repo |
| --- | --- |
| `pnpm miniapp:tag` | `npm run release:tag` |
| tag `miniapp/vX.Y.Z` | tag `vX.Y.Z` |
| `miniapp-release.yml` | `release-macos-app.yml` |

## Troubleshooting

| Error | Fix |
| --- | --- |
| working tree is not clean | Commit or stash first |
| must be created from master | `git checkout master` |
| HEAD does not match origin/master | `git pull` / `git push` until they match |
| tag already exists | Use a higher version or delete the remote tag only if you intend to re-release carefully |

## See also

- [Build from source](build-from-source.md) — local build / install
- [Install from Releases](install-from-release.md) — user download path
