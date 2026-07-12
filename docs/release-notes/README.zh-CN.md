# Release 更新日志

[English](README.md)

GitHub Release 页面**默认英文**，顶部提供 **中文入口**（结构参考 [cc-switch](https://github.com/farion1231/cc-switch/releases) 的多语言写法，本项目语言优先级为英文优先）。

1. **英文** = Release 正文默认语言  
2. **[中文 →](…)** 链到完整中文说明  
3. 章节：**Overview / 概览** → **Highlights / 重点** → 明细 → **Download / 下载安装**

## 每个版本的文件

| 文件 | 作用 |
| --- | --- |
| `vX.Y.Z-en.md` | 英文更新说明（**作为 Release 正文主体**） |
| `vX.Y.Z-zh.md` | 中文全文（在 Release 页顶部入口链接） |

例如：`v0.1.2-en.md`、`v0.1.2-zh.md`

## 英文模板（`vX.Y.Z-en.md`）

**不要**写 `# ZoneLaunch vX.Y.Z` 标题和中文链接——生成脚本会自动加。

```markdown
> One-paragraph summary of this release.

---

## Overview

…

## Highlights

- **Item:** details
```

## 中文模板（`vX.Y.Z-zh.md`）

完整中文页（可自带标题与下载说明）：

```markdown
# ZoneLaunch vX.Y.Z

> 一句话摘要。

**[English →](…/vX.Y.Z-en.md)**

---

## 概览
…
```

## 流程

1. 编写 `docs/release-notes/vX.Y.Z-en.md`（建议同时写 `-zh.md`）。  
2. 提交并 `git push origin master`。  
3. `pnpm release:tag` / `npm run release:tag`。  
4. CI 生成 **英文正文 + 中文入口**。

### 自动模式

若无 `vX.Y.Z-en.md`，则根据 git 自动生成英文说明；若无 `-zh.md` 会在正文内嵌简短中文小节。

```bash
pnpm release:notes -- v0.1.2
./scripts/generate-release-notes.sh v0.1.2 --write-zh-auto   # 从 git 起草中文文件
```
