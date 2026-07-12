# Release 更新日志

[English](README.md)

**每个版本都必须有两种语言。**

| | 英文 | 中文 |
| --- | --- | --- |
| 内容 | 只写英文说明 | 只写中文说明 |
| GitHub Release 页 | **默认正文** | 顶部 **[中文 →]** 进入完整中文 |
| 手写源文件 | `vX.Y.Z-en.md`（可选） | `vX.Y.Z-zh.md`（可选） |
| CI 始终产出 | `RELEASE_NOTES.md`（正文） | `RELEASE_NOTES.zh-CN.md`（附件） |

提交说明（commit message）**不翻译**，保持 git 原文。

**同一文件内不要中英夹带**（英文文件不要写中文段落，中文文件不要写英文段落）；仅 Release 页顶部保留语言入口链接。

## 文件

```text
docs/release-notes/v0.1.2-en.md   # 英文
docs/release-notes/v0.1.2-zh.md   # 中文
```

发版时若缺某一侧，CI 会按该语言从 git **自动生成**。建议打 tag 前手写齐两种。

## 起草双语文档

```bash
./scripts/generate-release-notes.sh v0.1.2 --write-files
# 编辑 docs/release-notes/v0.1.2-en.md 与 v0.1.2-zh.md
# 提交、push master，再 pnpm release:tag
```

## 预览英文 Release 正文

```bash
pnpm release:notes -- v0.1.2
# 生成 dist/RELEASE_NOTES.md + dist/RELEASE_NOTES.zh-CN.md
```
