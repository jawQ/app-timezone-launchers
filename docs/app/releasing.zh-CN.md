# 发布 ZoneLaunch Release

[English](releasing.md)

维护者如何在**终端**完成 GitHub Release，无需在网页上点「Draft a release」。

## 前提

1. 可用 Node.js / npm（仅用于执行根目录 `package.json` 里的 scripts，无需 `npm install`）。
2. `git` 在 `PATH` 中，且对 `origin` 有推送权限。
3. **工作区干净**（`git status` 无改动）。
4. 当前分支为 **`master`**。
5. **`HEAD` 与 `origin/master` 一致**（本地有提交时先 `git push origin master`）。

推送 tag `vX.Y.Z` 会触发 [`.github/workflows/release-macos-app.yml`](../../.github/workflows/release-macos-app.yml)：跑测试、打包 zip、上传资产。

## `package.json` scripts

在**仓库根目录**执行。

| npm script | 作用 |
| --- | --- |
| `npm run release:tag` | 在最新 `vX.Y.Z` 上自动 **patch +1**（如 `v0.1.0` → `v0.1.1`），创建 annotated tag 并 **推送** → CI 发版 |
| `npm run release:tag -- 0.2.0` | 指定版本（`v0.2.0`），同样 tag + 推送 |
| `npm run release:tag:dry-run` | 打印下一自动 tag 与 workflow 链接；**不**打 tag、**不**推送 |
| `npm run release:tag:test` | 版本辅助逻辑自检 |
| `npm run test:release-tag` | 同 `release:tag:test` |
| `npm run release:package` | 仅本地打 zip（可传版本：`npm run release:package -- 0.1.1`）——**不会**创建 GitHub Release |
| `npm run release:notes -- v0.1.2` | 预览某版本的**中英双语** Release 说明 |

不用 npm 时等价命令：

```bash
./scripts/release-tag.sh
./scripts/release-tag.sh 0.2.0
./scripts/release-tag.sh --dry-run
./scripts/release-tag.sh --self-test
./macos/AppTimezoneLauncher/scripts/package-release.sh 0.1.1
```

## VS Code / Cursor 任务（快速触发）

[`.vscode/tasks.json`](../../.vscode/tasks.json) 只提供一个任务：

**命令面板** → **Tasks: Run Task** → **`release:tag`**

等同于 `pnpm release:tag`（自动 patch 递增 + 推送 tag → CI）。

要求工作区干净、`master` 与 `origin/master` 一致（有未推送提交时先 `git push`）。

## 推荐流程

```bash
# 1. 先让 origin 上有最新代码
git status
git add -A && git commit -m "…"   # 如有需要
git push origin master

# 2. 预览下一版本（可选）
npm run release:tag:dry-run
# → 例如 Would create and push: v0.1.1

# 3. 正式发版
npm run release:tag
# 或 VS Code / Cursor: Tasks: Run Task → release:tag

# 4. 等待 CI（可选）
gh run watch
gh release view   # 或打开脚本打印的链接
```

CI 结束后，用户从这里下载：

https://github.com/jawQ/app-timezone-launchers/releases/latest

## 版本约定

| 场景 | 命令 |
| --- | --- |
| 文档 / 小修复 | `npm run release:tag`（patch） |
| 功能增量 | `npm run release:tag -- 0.2.0`（minor） |
| 不兼容大改 | `npm run release:tag -- 1.0.0`（major） |

tag 必须是 `v1.2.3` 这种三段数字。workflow 匹配 `v*`。

## 会发布什么

- `ZoneLaunch-<version>-macos.zip` — ad-hoc 签名的 App + `README-FIRST.txt`
- `SHA256SUMS`
- GitHub Release 页面上的**中英双语版本日志**
- GitHub 自动附带的源码 zip/tar（不是 App）

构建**未公证**。终端用户门禁步骤见：[从 Release 安装](install-from-release.zh-CN.md)。

## 更新日志（默认英文 + 中文入口）

结构参考 [cc-switch](https://github.com/farion1231/cc-switch/releases) 的多语言写法，本项目**默认英文**：

1. **GitHub Release 默认英文**  
2. 顶部 **[中文 →](…)** 进入完整中文说明  
3. 章节：**Overview / Highlights** → 明细 → **Download & install**  
4. 附带：发布日期、commit / diff 规模  

CI 运行 `scripts/generate-release-notes.sh`，通过 `body_path` 写入 Release 描述。

### 手写说明（推荐）

```text
docs/release-notes/vX.Y.Z-en.md   # 英文正文（Release 默认）
docs/release-notes/vX.Y.Z-zh.md   # 中文全文（顶部入口）
```

详见 [docs/release-notes/README.zh-CN.md](../release-notes/README.zh-CN.md)。

### 自动生成

若无 `vX.Y.Z-en.md`，则根据 `git log` **只生成英文**正文（提交说明保持 git 原文）。  
若无 `vX.Y.Z-zh.md`，Release 页**不会**出现中文段落，也没有中文入口链接。

```bash
pnpm release:notes -- v0.1.2
./scripts/generate-release-notes.sh v0.1.2 --write-zh-auto   # 起草中文文件（需提交后再打 tag）
```

## 与 supermarkets 的对应

与那边 `pnpm miniapp:tag` 同思路：本地脚本创建并推送版本 tag，由 CI 负责构建与上传。

| supermarkets | 本仓库 |
| --- | --- |
| `pnpm miniapp:tag` | `npm run release:tag` |
| tag `miniapp/vX.Y.Z` | tag `vX.Y.Z` |
| `miniapp-release.yml` | `release-macos-app.yml` |

## 排障

| 报错 | 处理 |
| --- | --- |
| working tree is not clean | 先提交或 stash |
| must be created from master | `git checkout master` |
| HEAD does not match origin/master | `git pull` / `git push` 直到一致 |
| tag already exists | 使用更高版本；仅在有意重发时再谨慎删除远程 tag |

## 另见

- [从源码构建](build-from-source.zh-CN.md) — 本地构建 / 安装
- [从 Release 安装](install-from-release.zh-CN.md) — 用户下载路径
