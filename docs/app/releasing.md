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
- `SHA256SUMS`
- **Release notes** — English body by default; optional top **[中文 →]** link to full Chinese notes
- GitHub’s automatic source zip/tar (not the app)

Builds are **not notarized**. End-user Gatekeeper steps: [Install from Releases](install-from-release.md).

## Release notes (English default + Chinese entry)

1. **English only** on the GitHub Release page (UI copy, download/install, section titles)  
2. Top **[中文 →](…)** only when `docs/release-notes/vX.Y.Z-zh.md` exists — full Chinese lives there, not mixed into the body  
3. **Commit subjects** are listed as written in git (may still be Chinese)  
4. Meta: release date + commit/diff scale  

CI runs `scripts/generate-release-notes.sh` and sets `body_path` on the Release.

### Curated notes (recommended)

```text
docs/release-notes/vX.Y.Z-en.md   # English body (GH Release default)
docs/release-notes/vX.Y.Z-zh.md   # Full Chinese (entry link only)
```

See [docs/release-notes/README.md](../release-notes/README.md).

### Auto notes

If `vX.Y.Z-en.md` is missing, notes are built from `git log` in **English only**. No in-body Chinese section.
```bash
pnpm release:notes -- v0.1.2
./scripts/generate-release-notes.sh v0.1.2 --write-zh-auto   # draft Chinese file
```

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
