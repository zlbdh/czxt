# PROP-001 · 路径白名单 / C 类铁律加 PreToolUse 软门禁（ask 不 deny）

- **状态**：已审批 · 已完成（2026-06-22 实施完毕，见 CHANGELOG 2026-06-22）
- **日期**：2026-06-22
- **提议人**：操作系统 PM「框架管家」（dogfood 多维审计 rank-4 落档；项目 PM「咪咪」调度）
- **预估等级**：L3（动 hooks 拦截语义 / framework 守卫）
- **实施记录**：2026-06-22 项目 PM 派 操作系统 PM worker agent 实现两份 `pre-write-guard.ps1` 路径软门禁 + hooks-smoke fixture；主会话验收 + readme-index / hooks-smoke / 体检 gate 全绿。详见 CHANGELOG 2026-06-22。

> 📌 发布 / git 边界：本 PROP 实现**不含**任何 commit/push/tag/version 动作；正文提到的 git `--force`/`rebase`/`tag` 仅作 Plan C 范围说明。实施产生的 commit/push 由**测试发布 PM「闭环者」**按 **ADR-016** 6 条件、主会话单点收口（push 失败即停手不重试）。

## 一句话

把"写 `Docs/6-历史归档/**` 和已存在 `apk/**`"这类 C 类边界，从**只靠 AI 自觉**升级为 `pre-write-guard.ps1` 的**机械软门禁（permissionDecision=ask，绝不 deny）**，让"三道护栏"名实相符。

## 背景 / 动机

- 触发场景：本轮 dogfood 多维审计（2026-06-22）头号主线——框架自称"三道护栏（Q1-Q7 / 路径白名单 / 三类铁律）"，但**路径白名单 / C 类铁律在写入时零机械门禁**，全靠 AI 记得 grep `三类行为铁律.md`。
- 框架自己的 PM 自纠 #88（"PM 也会忘"）、#91（"软规则失守 = 终极自动化 Hooks"）早已论证：只靠自觉这条路走不通。
- 现状证据：`能力资产/tools/hooks/claude|codex/pre-write-guard.ps1` 当前**只**检测"密钥写入非 .env 文件 → ask"，对路径类 C 类边界（`Docs/6-历史归档/`、历史 `apk/`）**无任何拦截**。
- 这是名副其实的 dogfooding 自指漏洞：规则写在纸上，没有门禁兜底。修它即"用操作系统优化操作系统"。

## 建议怎么做

复用现有 `pre-write-guard.ps1` 已验证的设计（**只 ask 不 deny + 全程 fail-safe**），在密钥检测之后追加**路径裁决**：

- Edit/Write 目标命中 `Docs/6-历史归档/**` → `permissionDecision=ask`，引用 C 类"历史归档不动"。
- 写**已存在**的 `apk/**` 文件 → `ask`，引用 C 类"改历史 APK"。
- 一律 **ask 不 deny**；任何不确定 / 解析失败一律放行（continue），与现有密钥门禁同款 fail-safe。
- claude + codex **两份** `pre-write-guard.ps1` 同步改（互斥写集，按调度纪律派 worker 实现，主会话验收）。
- 同步 `能力资产/tools/hooks/tests/hooks-smoke.ps1` 加正 / 负向 fixture，体检 gate 验证。

## 影响 / 代价（粗估）

- 工作量：S–M
- 影响文件数：~3–4（claude/codex 两份 hook + hooks-smoke fixture +（如计数变动）hooks README / 事件矩阵）
- 风险：**低**——这两类路径日常几乎不写，ask 不会造成 prompt 疲劳；只 ask 不 deny，误判也不阻断真实工作；fail-safe 保证 hook 出错时不挡路。
- 是否改 schema：否

## 备选方案

- **A（本提案）**：先做"历史归档 + 历史 APK"两类高价值、低噪声路径。
- **B**：连"单源禁并行文件（`状态.md`/`CHANGELOG` 等）"也加 ask —— ❌ **不建议**：这些文件每个 sprint 都写（本会话已写 5+ 次），ask 会造成严重 prompt 疲劳；并发风险靠调度纪律 + C 类规则管，不靠 per-write hook。
- **C**：再加 git `--force`/`reset --hard`/`rebase`/`tag -d` 命令级提醒（user-prompt-submit 或 Bash PreToolUse）—— 可作 **Phase 2**，本 PROP 先不含，避免 scope 膨胀和"rebase"等词的误报。

## 拒绝的话理由会是什么

- "这两类路径本来就很少写，加门禁收益边际"——但护栏价值正在于"忘记时兜底"，零成本兜底优于零兜底。
- 或希望先把 git 命令级 C 类（force/rebase）一起做再统一上（→ 选 Plan C 合并）。

## 不在范围

- 不做 deny（永远 ask）。
- 不动单源禁并行文件的 ask 门禁（Plan B，本轮不做）。
- 不做 git 命令级拦截（Plan C / Phase 2）。
- 不改 C 类清单本身、不改路径白名单语义——只给"已立规则"加机械兜底。
