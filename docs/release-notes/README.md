# Release notes

[简体中文](README.zh-CN.md)

GitHub Release pages use **English by default**, with a top **Chinese entry** link (same multi-language idea as structured notes on [cc-switch](https://github.com/farion1231/cc-switch/releases), language priority flipped for this project).

1. **English** = default body on the Release page  
2. **[中文 →](…)** links to full Chinese notes  
3. Sections: **Overview** → **Highlights** → details → **Download & install**

## Files per version

| File | Role |
| --- | --- |
| `vX.Y.Z-en.md` | English changelog (**preferred** for GH Release body) |
| `vX.Y.Z-zh.md` | Full Chinese notes (linked from the Release page) |

Example: `v0.1.2-en.md`, `v0.1.2-zh.md`

## English template (`vX.Y.Z-en.md`)

Do **not** put the `# ZoneLaunch vX.Y.Z` title or the Chinese link — the generator adds those.

```markdown
> One-paragraph summary of this release.

---

## Overview

…

## Highlights

- **Item:** details

## Changes

### Subsection

…
```

## Chinese template (`vX.Y.Z-zh.md`)

Full Chinese page (may include its own title and download section):

```markdown
# ZoneLaunch vX.Y.Z

> 一句话摘要。

**[English →](https://github.com/jawQ/app-timezone-launchers/blob/vX.Y.Z/docs/release-notes/vX.Y.Z-en.md)**

---

## 概览

…

## 重点内容

- …

## 下载与安装

…
```

## Workflow

1. Write `docs/release-notes/vX.Y.Z-en.md` (+ recommended `-zh.md`).  
2. Commit and push to `master`.  
3. `pnpm release:tag` / `npm run release:tag`.  
4. CI runs `scripts/generate-release-notes.sh` and publishes the English body with a Chinese link.

### Auto mode

If `vX.Y.Z-en.md` is missing, notes are generated from git (English overview / highlights / commits; Chinese subsection embedded if no `-zh.md`).

```bash
pnpm release:notes -- v0.1.2
./scripts/generate-release-notes.sh v0.1.2 --write-zh-auto   # draft Chinese file from git
```
