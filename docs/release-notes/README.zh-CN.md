# Release 更新日志（对齐 cc-switch 风格）

[English](README.md)

结构参考 [cc-switch Releases](https://github.com/farion1231/cc-switch/releases)：

1. **GitHub Release 页面默认中文**  
2. 顶部链接到 **英文全文**：`**[English →](...)**`  
3. 章节顺序：**概览** → **重点内容** → 明细 → **下载与安装**

## 每个版本的文件

| 文件 | 作用 |
| --- | --- |
| `vX.Y.Z-zh.md` | 中文更新说明（**作为 Release 正文主体**） |
| `vX.Y.Z-en.md` | 英文全文（在 Release 页顶部链接） |

例如：`v0.1.2-zh.md`、`v0.1.2-en.md`

## 中文模板（`vX.Y.Z-zh.md`）

**不要**写 `# ZoneLaunch vX.Y.Z` 标题和下载安装附录——生成脚本会自动加。

```markdown
> 一句话总结本版最重要的变化（引用块，对应 cc-switch 标题下的摘要）。

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

## 英文模板（`vX.Y.Z-en.md`）

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

## 流程

1. 编写 `docs/release-notes/vX.Y.Z-zh.md`（可选 `-en.md`）。  
2. 提交并 `git push origin master`。  
3. `pnpm release:tag` / `npm run release:tag`。  
4. CI 调用 `scripts/generate-release-notes.sh` 写入 Release 描述。

### 自动模式

若没有 `vX.Y.Z-zh.md`，则根据 git 历史自动生成（概览 / 重点 / 提交列表 + 英文小节）。

```bash
pnpm release:notes -- v0.1.2
./scripts/generate-release-notes.sh v0.1.2 --write-en-auto   # 从 git 起草英文文件
```
