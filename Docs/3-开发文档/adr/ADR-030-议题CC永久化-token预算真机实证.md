# ADR-030 · Make topic CC permanent: evidence-driven acceptance + device-tested token budgets (unit tests passing ≠ device passing)

- **Status**: Current
- **Date**: 2026-05-28
- **Related**: [PROP-040 F-F1](../../../确认改动/已审批/已完成/PROP-040-2026-05-22-Sprint-8-W-1-F-F1-AI餐食推荐.md) · [PROP-041 F-F2+F-F4](../../../确认改动/已审批/已完成/PROP-041-2026-05-24-Sprint-9-W-1-F-F2+F-F4-食谱+采购闭环.md) · [PM self-corrections #51/#53](../../../PM工作区/项目PM-咪咪/PM自纠/) · [RETRO-013](../../7-复盘/RETRO-013-2026-05.md)
- **Topic CC closure criteria**: ≥3 repeated cases, actually four across Sprint-5/8/9; effective defenses demonstrated through thinking-model.test; applicability across PMs / tools ✅ Met

## Context

Topic CC, "evidence-driven acceptance / unit tests must cover the device call chain," originated in PM self-corrections #51/#53. **Four cross-Sprint cases** established that passing unit tests does not imply device success, especially for **token budgets**:

| # | Time | Scenario | Unit tests | Device |
|---|---|---|---|---|
| 1 | Sprint-5 | F-DEVIATION-2 detection | ✅ Passed | ❌ smoke#1: empty max_tokens response |
| 2 | Sprint-5 | F-NIGHT-1 early-morning protection | ✅ Passed | ❌ 150 tokens insufficient → 2000 |
| 3 | **Sprint-8** | **F-F1 AI meal recommendations** | ✅ Passed at 2000 | ❌ **Thinking exhausted the device budget → 4000** |
| 4 | **Sprint-9** | **F-F2+F-F4 recipes + shopping** | ✅ Passed, set directly to 4000 | ✅ **Device passed**, using the lesson and thinking-model.test |

**Root cause**: MiMo is a thinking model. Its `thinking` segment consumes many tokens; insufficient `max_tokens` causes `stop_reason=max_tokens` with thinking but no text, then JSON.parse failure and permanent fallback. **Ordinary mocked unit tests do not cover the thinking path**, so tests pass while the device always falls back.

## Decision

**Permanently close CC** and add it as the thirteenth meta-rule.

### Decision 1 — Evidence-driven acceptance

Acceptance criteria for any LLM-integrated feature **must cover the actual device call chain**, not just mocked unit tests:
- Unit tests verify **logic**: happy path, fallback, and field parsing.
- Device smoke tests verify **actual LLM behavior**: token use, thinking paths, and output volume.
- **Both must pass for acceptance.**

### Decision 2 — Device-tested token budgets (core)

When designing a new LLM caller's budget:
1. **Do not rely on memory or copy another caller's value**. F-F1 copied SUGGESTION_MAX_TOKENS=2000 and still failed.
2. Estimate **output volume × thinking multiplier**: a thinking-model budget should be at least 2-3 times the output JSON volume.
3. **Start with a larger value**. F-F2+F-F4 passed on the first attempt at 4000, avoiding repeated small-budget failures.
4. Actual device measurement is the **final authority**, not unit tests.

### Decision 3 — Mandatory thinking-model.test

Every caller of a thinking model **must** have `*.thinking-model.test.js` coverage:
- Explicit `MAX_TOKENS ≥ threshold` guard.
- Mock `stop_reason=max_tokens` with thinking only and no text; verify fallback to reproduce the device-blocking path.
- Mock normal thinking + text; verify real data is returned.
- Reference templates: `{{APP_REPO_DIR}}/src/shared/__tests__/dailyBriefing-llm.thinking-model.test.js` + `llmMealRecommend.thinking-model.test.js`.

### Decision 4 — Expand the meta-rule pool from twelve to thirteen

```
G / AT / AM / AO / BC / BE(ADR-029) / AJ(ADR-023) / P(ADR-024)
BK(ADR-025) / CT(ADR-026) / CU+DD(ADR-027) / CW(ADR-028)
🆕 CC Evidence-driven acceptance + device-tested token budgets → ADR-030, this record
```

## Consequences

### Benefits
- ✅ New LLM features avoid device failures from token budgets, as demonstrated by F-F2+F-F4 passing immediately with 4000 + thinking-model.test.
- ✅ Thinking paths, formerly a mock-test blind spot, are explicitly covered.
- ✅ Shared PM understanding: unit tests alone do not establish acceptance; devices are authoritative.

### Risks and mitigations
| Risk | Mitigation |
|---|---|
| 4000 tokens increases LLM cost | Acceptable compared with a feature permanently in fallback; future optimization through PROP-034 model tiers |
| thinking-model.test adds maintenance | Template the dailyBriefing pattern and reuse it |

### Verification
| Dimension | Result |
|---|---|
| F-F1 device blocker fixed | ✅ 2000→4000; v3.9.0 smoke 8/8 |
| F-F2+F-F4 set directly to 4000 | ✅ v3.10.0 smoke 8/8 on the first attempt |
| thinking-model.test coverage | ✅ All four callers covered |

## Referenced decisions
- PM self-correction #51: evidence-driven AC2 text-length revision; #53: empty MiMo thinking max_tokens response.
- Four field cases: F-DEVIATION-2 / F-NIGHT-1 / F-F1 / F-F2+F-F4.
- RETRO-013, Sprint-8+9 retrospective.

---

⭐ **ADR-030 is permanently current: meta-rule thirteen, mandatory device evidence for token budgets.**

---

## 2026-06-09 addendum (PROP-043 / RETRO-018 lessons 3+4) — Path-dependent maxTokens

Specific token-budget consequences of CC's "unit tests passing ≠ device passing":
- **maxTokens is path-dependent**: Accumulated prompt-injection blocks make a generic 4000 floor insufficient for thinking models. Every new JSON-output path needs **measured output_tokens headroom**, using a real-shell call and stop_reason/output_tokens, rather than a generic value.
- **Account for injected blocks globally**: Each sodium / allergy / packed-lunch block added to a caller's prompt consumes thinking headroom across all that caller's scenarios. Track the total injected text.
- **Evidence from four v3.34 rounds**: A rich-profile shopping path at maxTokens=4000 exhausted the budget on thinking, emitted zero visible JSON characters, and fell back deterministically. At 8000 it produced a list, using 4940 tokens / 62%. The root cause was an overlong prompt causing thinking overflow; **adding prompt text can backfire**, so an item-limit sentence was deliberately rejected.
