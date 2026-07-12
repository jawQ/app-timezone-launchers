# Release notes (cc-switch style)

[简体中文](README.zh-CN.md)

Release notes follow the layout used by [cc-switch releases](https://github.com/farion1231/cc-switch/releases):

1. **Chinese is the default language** on the GitHub Release page  
2. **English** is a separate file linked at the top: `**[English →](...)**`  
3. Structured sections: **概览** → **重点内容** → details → **下载与安装**

## Files per version

| File | Role |
| --- | --- |
| `vX.Y.Z-zh.md` | Chinese changelog (**preferred** for GH Release body) |
| `vX.Y.Z-en.md` | Full English notes (linked from the Release page) |

Example: `v0.1.2-zh.md`, `v0.1.2-en.md`

## Suggested Chinese template (`vX.Y.Z-zh.md`)

Do **not** put the `# ZoneLaunch vX.Y.Z` title or download footer here — the generator adds those.

```markdown
> 一句话总结本版最重要的变化（blockquote，像 cc-switch 一样放在标题下）。

---

## 概览

用 1～3 段说明本版定位、相对上一版的重点。

---

## 重点内容

- **亮点一**：说明
- **亮点二**：说明

---

## 新功能 / 变更 / 修复

### 小节标题

详细说明……
```

## Suggested English template (`vX.Y.Z-en.md`)

```markdown
# ZoneLaunch vX.Y.Z

> One-paragraph summary.

**[中文 →](https://github.com/jawQ/app-timezone-launchers/blob/vX.Y.Z/docs/release-notes/vX.Y.Z-zh.md)**

---

## Overview

…

## Highlights

- …

## Details

…
```

English files may include their own download section, or rely on the Chinese Release page footer.

## Workflow

1. Write `docs/release-notes/vX.Y.Z-zh.md` (+ optional `-en.md`).  
2. Commit and push to `master`.  
3. `pnpm release:tag` / `npm run release:tag`.  
4. CI runs `scripts/generate-release-notes.sh` and publishes the body.

### Auto mode

If `vX.Y.Z-zh.md` is missing, notes are generated from git (`概览` + `重点内容` + `提交列表` + English auto section).

```bash
pnpm release:notes -- v0.1.2
./scripts/generate-release-notes.sh v0.1.2 --write-en-auto   # draft EN file from git
```
