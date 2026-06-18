# ADR-030 · 议题 CC 永久化：AC 实证驱动 + token 预算真机实证（单测过 ≠ 真机过）

- **状态**：现行
- **日期**：2026-05-28
- **关联**：[PROP-040 F-F1](../../../确认改动/已审批/已完成/PROP-040-2026-05-22-Sprint-8-W-1-F-F1-AI餐食推荐.md) · [PROP-041 F-F2+F-F4](../../../确认改动/已审批/已完成/PROP-041-2026-05-24-Sprint-9-W-1-F-F2+F-F4-食谱+采购闭环.md) · [PM 自纠 #51/#53](../../../PM工作区/项目PM-咪咪/PM自纠/) · [RETRO-013](../../7-复盘/RETRO-013-2026-05.md)
- **议题 CC 关闭条件**：同模式累积 ≥3 次（实际 4 次跨 Sprint-5/8/9）+ 实证防御机制有效（thinking-model.test）+ 跨 PM/跨工具适用 ✅ 达成

## 背景

议题 CC「AC 实证驱动 / 单测须覆盖真机调用链」起源 PM 自纠 #51/#53，**4 次跨 Sprint 累积**实证「单测过 ≠ 真机过」，尤其 **token 预算**领域：

| # | 时间 | 场景 | 单测 | 真机 |
|---|---|---|---|---|
| 1 | Sprint-5 | F-DEVIATION-2 deviation 检测 | ✅ 过 | ❌ smoke#1 max_tokens 空回复 |
| 2 | Sprint-5 | F-NIGHT-1 凌晨保护 | ✅ 过 | ❌ 150 token 不够 → 改 2000 |
| 3 | **Sprint-8** | **F-F1 AI 餐食推荐** | ✅ 过（2000）| ❌ **真机 thinking 吃光 → 改 4000** |
| 4 | **Sprint-9** | **F-F2+F-F4 食谱+采购** | ✅ 过（直接锁 4000）| ✅ **真机过**（吸取教训直接锁 + thinking-model.test）|

**根因**：MiMo 是 thinking 模型 / `thinking` 段消耗大量 token / 若 `max_tokens` 不足 → `stop_reason=max_tokens` 只产 thinking 不产 text → JSON.parse 失败 → 永远走 fallback。**普通单测 mock 不覆盖 thinking 路径**,所以单测全过但真机永久 fallback。

## 决定

议题 CC **正式永久关闭**,作为第 13 元规则进入永久化池。

### 决定 1 — AC 实证驱动铁律（永久化）

任何 LLM 集成 feature 的验收条件（AC）**必须覆盖真机调用链** / 不能只靠单测 mock：
- 单测验证**逻辑**（happy / fallback / 字段解析）
- 真机 smoke 验证**实际 LLM 行为**（token 消耗 / thinking 路径 / 实际输出体量）
- **两者都过才算 AC 达成**

### 决定 2 — token 预算真机实证（永久化 / 核心）

新 LLM caller 设计 token 预算时：
1. **不靠记忆 / 不抄其他 caller 的值**（F-F1 教训：抄 SUGGESTION_MAX_TOKENS 2000 仍不够）
2. 按「**输出体量 × thinking 系数**」估：thinking 模型预算 ≥ 输出 JSON 体量的 2-3 倍
3. **直接锁较大值起步**（F-F2+F-F4 实证：直接锁 4000 一次过 / 不试小值反复打脸）
4. 真机实测是**最终裁判**(不是单测)

### 决定 3 — thinking-model.test 必建（永久化）

每个调用 thinking 模型的 LLM caller **必须**配套 `*.thinking-model.test.js`：
- 显式验证 `MAX_TOKENS ≥ 阈值` guard
- mock `stop_reason=max_tokens` + 只 thinking 不 text → 验证走 fallback（复现真机阻塞路径）
- mock 正常 thinking + text → 验证返回真数据
- 参考模板：`{{APP_REPO_DIR}}/src/shared/__tests__/dailyBriefing-llm.thinking-model.test.js` + `llmMealRecommend.thinking-model.test.js`

### 决定 4 — 元规则池升级 12 → 13（永久化第 13 元规则）

```
G / AT / AM / AO / BC / BE(ADR-029) / AJ(ADR-023) / P(ADR-024)
BK(ADR-025) / CT(ADR-026) / CU+DD(ADR-027) / CW(ADR-028)
🆕 CC AC 实证驱动 + token 预算真机实证 → ADR-030 本 ADR
```

## 后果

### 收益
- ✅ 新 LLM feature 不再因 token 预算被真机打脸（F-F2+F-F4 已验证：直接锁 4000 + thinking-model.test 一次过）
- ✅ 单测 mock 盲区（thinking 路径）被显式覆盖
- ✅ 跨 PM 共识：AC 不是单测过就行 / 真机是裁判

### 风险与缓解
| 风险 | 缓解 |
|---|---|
| 4000 token 增加 LLM 成本 | 可接受（vs 永久 fallback 功能废掉）/ PROP-034 模型分层未来优化 |
| thinking-model.test 增加测试维护 | 模板化（dailyBriefing 模式）/ 一次写多次复用 |

### 验证
| 维度 | 结果 |
|---|---|
| F-F1 真机阻塞修复 | ✅ 2000→4000 / v3.9.0 smoke 8/8 |
| F-F2+F-F4 直接锁 4000 | ✅ v3.10.0 smoke 8/8 一次过 |
| thinking-model.test 覆盖 | ✅ 4 个 caller 全配套 |

## 引用决议
- PM 自纠 #51（AC2 字数实证修订）+ #53（MiMo thinking max_tokens 空回复）
- F-DEVIATION-2 / F-NIGHT-1 / F-F1 / F-F2+F-F4 四次实证
- RETRO-013（Sprint-8+9 复盘）

---

⭐ **ADR-030 永久现行 / 第 13 元规则 / token 预算真机实证铁律**

---

## 2026-06-09 补录（PROP-043 / RETRO-018 教训3+4）— maxTokens path-dependent 升级

CC「单测过≠真机过」的 token 维度具体化：
- **maxTokens 是 path-dependent**：thinking 模型在「prompt 注入块累积」下，通用 4000 下限不够。新 LLM JSON 输出路必做 **output_tokens 实测头寸**（real-shell 真调看 stop_reason/output_tokens），而非套用通用值。
- **注入块全局记账**：每刀往同一 caller prompt 加注入块（钠盐/过敏/便当…）都在消耗该 caller 所有场景的 thinking 头寸——注入块字数应全局记账。
- **实证（v3.34 四轮取证）**：采购路 rich profile @maxTokens=4000 → thinking 吃光预算、可见 JSON 0 字、确定性 fallback；→8000 出单（4940/62% 利用）。根因是 prompt 太长致 thinking 溢出，故**加 prompt 文字会反噬**（item 上限句被刻意拒）。
