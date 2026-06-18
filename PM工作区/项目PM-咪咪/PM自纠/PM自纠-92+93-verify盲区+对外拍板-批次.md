---
name: pm-self-correction-92-93
scope: pm-workspace
pm: 项目PM-咪咪
type: episodic
loaded: triggered
trigger: verify 工具静默损坏未被发现 / zlbdh "你是项目PM" 第 N 次 trigger（问句代替拍板）
description: PM 自纠 #92+#93 批次 — #92 check-operating-system + check-pm-tracking 双脚本路径残留致 verify 静默坏多日（体检盲区 #88-91 延续）/ #93 项目 PM 又用问句代替自主拍板（ADR-031 执行层失守）
---

# PM 自纠 #92+#93 批次

> 触发：zlbdh「跑一遍 verify」→ 真机暴露脚本崩溃 + 我用「要不要我接着写沉淀？」收尾 → zlbdh「你是项目PM」
> 时间：2026-05-29 16:30
> 议题：DN 体检质量（#92）+ ADR-031 对外拍板（#93）

---

## #92 — verify 工具静默损坏多日没被发现

### 错向

`check-operating-system.ps1` 的「⏳ Windows 真机 verify 留 zlbdh」自 task #125（05-29 09:00）一直挂着 = 加了 P4g 后**从没真机整跑过一次**。真机一跑直接崩：

- `$root` 只上溯 1 层（task #109 把脚本移进 `能力资产\tools\scripts\` 后没改）→ 项目根误判成 `能力资产\tools`
- P4a/P4b/P4c 仍引用 `agent\`（agent/→操作系统/+能力资产/ 重构后没回扫）→ P4c 崩在缺 `agent\`
- `check-pm-tracking.ps1` 同 `$root` 病（P4f 形同虚设，找不到 状态.md）

### 根因

1. **改 framework 工具/结构后没立即真机整跑 verify** —— 两次结构变动（task #109 移位 + agent/ 重构）都没回扫这个脚本的内部路径假设。
2. **「⏳ 留 zlbdh」= 验证债** —— 加 P4g 时只测了 P4g 自己（用对了 3 层 `$repoRoot`），没跑整脚本，旧的 P4a-d 残留躲过检查。
3. **体检盲区系列（#88/#89/#90/#91）延续**：**体检脚本自己从没被体检**。

### 修正

- ✅ 两脚本 `$root`/`$projectRoot` 1 层→3 层（对齐 P4g 已用对的 `$repoRoot`）；P4a-c 路径迁 `操作系统\`+`能力资产\`；P4b 补历史档案豁免
- ✅ 沙箱 framework 镜像实跑验证：exit 0 / P4a 49 过 / P4c 0 死代码 / P4g 全绿（ADR 32=32 / 元规则池 15=15 / frontmatter 100%）
- ⏳ 真机落地 + 重跑 verify 收尾（这次**不留验证债**，当场确认）

### 沉淀（候选元规则）

**「改任何 framework 工具/脚本后，必须真机整跑一次，不接受『只测新增段』」** —— 议题 D（mount stale）+ 议题 DN（体检质量）合流。候选补进 ADR-032 决定 7 或独立升 ADR。

---

## #93 — 项目 PM 又用问句代替自主拍板（ADR-031 执行层失守）

### 错向

上一条我用「要不要我接着把这条沉淀写了？」收尾 = 把明摆着该做的沉淀**当成需要 zlbdh 批准的决策**抛回去。zlbdh「你是项目PM」第 N 次 trigger（同 #63 / #77 / #80 / #83 / #86 模式）。

### 根因

ADR-031「自主拍板不推诿」是**已永久化的铁律**（第 14 元规则），本次不是规则缺失，是**执行层失守**：收尾时习惯性加「要不要我…？」确认问句 = 礼貌外壳下的决策推诿。同 #91「软规则在收尾处最易破防」同病。

### 修正

- ✅ 当场不问，直接写沉淀（本文件 + 状态.md 轨迹 + INDEX 指针）
- 自检钩子：**任何「要不要我…？/需要我…？」式收尾，若答案显然是「要」→ 删问句，直接做**（属于显然该做的事就做，真正多路径才用选择题）

### 沉淀

不升新 ADR（ADR-031 已覆盖）→ 进**沉淀 PM 速查表 B 类「PM 对外铁律」**加一条反面实例：**问句式收尾 = ADR-031 推诿的隐蔽变体**。

---

⭐ **教训**：① 工具自己也要被体检，改完必须真机整跑（#92）② 软规则在「收尾礼貌」处最易破防 —— 问句式收尾是 ADR-031 的隐蔽变体（#93）

## 真知识源

- 本次 session（2026-05-29）：[`状态.md`](../../../../状态.md) PM 切换轨迹 2026-05-29 16:30 行
- 修正版脚本：`能力资产/tools/scripts/check-operating-system.ps1` + `check-pm-tracking.ps1`（FIX 2026-05-29 注释）
- 同模式：[[pm-self-correction-91]]（软规则失守）/ #63/#77/#80（ADR-031 系列）

---

## #94 — 修 #92 的过程里当场又踩 #92（Edit 改 21KB outputs 截断尾部）

### 错向
出修正版后我用 Edit 工具给 outputs 的 check-operating-system.ps1（21KB）补「归档豁免」→ **Edit 把 >6500B 文件尾部截断**（丢了「下一步」+「exit 0」，只剩半行 `Wr`）→ 没复核尾部就 cp 到真机 → 真机跑到第 421 行 `Wr` 报错。

### 根因
- AGENTS.md「>6500B 绕 Edit、用 Python/Bash 写」铁律**我只对真机 framework 文件守，对自己 outputs/ 的 21KB 草稿没守** → 一样被截。
- #92 候选元规则「改完必真机整跑」嘴上说手上没做：出修正版后没在镜像/真机复跑整脚本验尾部，只信了「改之前」那次镜像 exit 0。

### 修正
- ✅ 真机 `truncate`（截到第 420 行末）+ bash 追加正确尾部（小操作，不整块重写）→ pwsh 解析通过 + diff 确认 body 与干净版逐行一致
- ✅ 教训升级：**任何 >6500B 文件（含 outputs/ 草稿）写入后必复核尾部字节/行**，Edit 工具同样会截

### 沉淀
强化 #92 候选元规则 → **「>6500B 文件任何写入（Edit/Write/cp）后必验尾部，不分真机/草稿」**（议题 D + DN 合流 / 下个治理 sprint 升 ADR）

---

## #95 — handoff AC 内部矛盾（没 grep 测试就写「0 测试改动」/ #54 复发）

### 错向
CA+CB handoff 卡 AC#2「0 现有测试改动」+ AC#3「Chat.jsx <8KB」。但 Chat.test.js 是**源码 grep 契约**（~13 断言锁逻辑字符串在 Chat.jsx）→ CA 把逻辑搬到 useChatController.js 后这些 grep 必红 → AC#2 与 AC#3 **数学互斥**。我起卡时没 grep Chat.test.js 就写了「0 测试改动」。

### 根因
PM 自纠 #54 同模式复发：**起 handoff 卡前没 grep 测试/caller 实际形态就假设**。#54 是 caller import 风格，#95 是测试契约形态 —— 同一个「凭假设写 AC」。

### 修正
- ✅ Claude Code 实施时逮住、用 AskUserQuestion 升 PM（议题 CD 防御机制有效）→ zlbdh 选 A（grep 目标随代码合法搬家 / 断言 regex 逐字不变 / PROP-024 SuggestionCard 先例）→ 修订卡 AC#2 → CA+CB v3.10.1 ship 成功、0 业务事故。

### 沉淀
强化议题 CD「PM 起卡 verify checklist」：加「源码 grep 契约 + 拆分重构 → AC 预先豁免 grep 目标跟随」维度。CD 仍候选（暂不升 ADR）。
