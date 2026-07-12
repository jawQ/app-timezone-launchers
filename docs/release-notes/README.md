# Release notes

[简体中文](README.zh-CN.md)

**Every version has both languages.**

| | English | Chinese |
| --- | --- | --- |
| Content | English UI only | Chinese UI only |
| GitHub Release page | **Default body** | **[中文 →]** entry → full notes file |
| Source of truth | `vX.Y.Z-en.md` (optional curated) | `vX.Y.Z-zh.md` (optional curated) |
| CI always uploads | `RELEASE_NOTES.md` (body) | `RELEASE_NOTES.zh-CN.md` (asset) |

Commit subjects are never translated; they stay as written in git.

Do **not** mix languages inside one file (no English paragraphs in the Chinese file, no Chinese paragraphs in the English file), except the single language-switch entry on the Release page.

## Files

```text
docs/release-notes/v0.1.2-en.md   # English
docs/release-notes/v0.1.2-zh.md   # Chinese
```

If either file is missing at release time, CI **auto-generates** that language from git. Prefer writing both before tagging.

## Draft both languages

```bash
./scripts/generate-release-notes.sh v0.1.2 --write-files
# edit docs/release-notes/v0.1.2-en.md and v0.1.2-zh.md
# commit, push master, then pnpm release:tag
```

## Preview English Release body

```bash
pnpm release:notes -- v0.1.2
# writes dist/RELEASE_NOTES.md + dist/RELEASE_NOTES.zh-CN.md
```
