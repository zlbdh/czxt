# ADR-023 · Topic AJ implementation — PM subroles + decision-checkpoint (PROP-020 path D closeout)

- **Status**: Current
- **Date**: 2026-05-15
- **Related**: [PROP-020 main proposal](../../../确认改动/已审批/进行中/PROP-020-2026-05-14-Agent团队架构.md) · [PROP-020 path D plan v0](../../../确认改动/已审批/进行中/PROP-020-路径D-方案v0.md) · [PROP-021 useAppData split](../../../确认改动/已审批/已完成/PROP-021-2026-05-14-useAppData-hook拆分.md) · [PROP-022 navigator matrix](../../../确认改动/已审批/已完成/PROP-022-2026-05-15-navigator矩阵+capacitor-network依赖.md) · [PROP-023 Project PM memory hub](../../../确认改动/已审批/进行中/PROP-023-2026-05-15-项目PM记忆中枢化.md) · [ADR-022 decision 5](ADR-022-跨工具同步与角色边界规范.md)
- **Topic AJ closure criteria**: 3/3 cross-Sprint field trials + zero recurrences of the #38/#41/#42 pattern ✅

> ⚠️ **Current override notice (2026-06-15)**: This record is a predecessor of Q1-Q7 / the nine-PM architecture and preserves historical evidence of five PM categories and three questions. Current execution follows [`操作系统/07_完整工作流/decision-checkpoint.md`](../../../操作系统/07_完整工作流/decision-checkpoint.md), [`ADR-027`](ADR-027-议题CU+DD永久化-沉淀PM元层架构.md), and [`ADR-038`](ADR-038-PM实体化agent调度模型.md).

## Context

After the operating-system portion of PROP-018a closed, zlbdh raised topic AJ on 5/13: the Project PM's simultaneous application and operating-system responsibilities create a **structural root cause**, not an isolated mistake, as shown by the repeated misrouting in PM self-corrections #38/#41/#42.

P0 experiments on the **initial PROP-020 path C Hybrid** proposal (five runtime subagents + .claude/agents/) found:
- `.claude/` is an Anthropic-specific convention that Codex / Cowork do not recognize.
- Cross-tool consistency failed, so zlbdh **switched to path D** on 5/14: enhanced plain Markdown.

**Enhanced path D**, in PROP-020's "Path D plan v0":
- Five Markdown PM subroles: Project / Operating System / Product / Technical / Test.
- Expand AI边界.md from four categories to five.
- A `decision-checkpoint` workflow with three mandatory questions: Which role? Is the path allowlisted? What if it crosses a boundary?
- A PM role-transition history in 状态.md for topic AJ traceability.

## Decision

**Close topic AJ formally** and adopt enhanced PROP-020 path D as routine framework meta-rules.

### Decision 1 — Five internal PM subroles (path D)

```
Project PM "Mimi" (orchestrator; sole outward-facing identity)
    ├─→ Operating System PM "Framework Steward" (agent/ + tools/ + Docs/3+7/ + 确认改动/ + 交接区/ + 项目PM/)
    ├─→ Product PM "Requirements Analyst" (Docs/1-需求文档/ + 确认改动/待审批/)
    ├─→ Technical PM "Fix Strategist" (read-only; no implementation)
    └─→ Test PM "Quality Gate" (read-only; no implementation)
```

Each subrole has an independent Markdown playbook and a mandatory path allowlist.

### Decision 2 — Three mandatory decision-checkpoint questions

Run before switching roles, writing a handoff card, or starting a PROP:
- Q1: Which role owns this work?
- Q2: Does this role's allowlist permit the paths I will change? Search AI边界.md.
- Q3: If the work crosses a boundary, write a handoff card / switch roles.

### Decision 3 — Q4 rule-validation extension (topic AR upgrade)

Three consecutive PROP-021/022/023 self-correction episodes (#43-#48, six total) showed that Q1-Q3 cover only **paths**, leaving gaps in **rule recall, design self-review, status fields, version assumptions, chat output, and tool integration**.

Q4 adds seven dimensions as topic AJ implementation v2:
- Q4.a — CHANGELOG header rules (PM self-correction #43).
- Q4.b — PM design self-review (counterexample in tradeoff 2).
- Q4.c — PROP status-field semantics (PM self-correction #44).
- Q4.d — Mandatory matrix lookup for web API selection (PM self-correction #45 / topic AT meta-rule).
- Q4.e — Capacitor major-version assumptions (PM self-correction #46).
- Q4.f — Capacitor plugin imports + NotificationChannel (PM self-correction #47 / topic BC meta-rule).
- Q4.g — Deduplicate chat output; before handoff / PROP / chat writing, search `项目PM/速查表/` (PM self-correction #48 / topic BE meta-rule).

**Q4 implementation**: PROP-023 adds seven quick-reference files in `项目PM/速查表/`, each ≤2KB, for a one-minute check before a role switch.

### Decision 4 — Cross-Sprint traceability

Add a "## 🎩 PM role-transition history" section to `状态.md`. Record one line for each role switch and decision-checkpoint run, formally activating topic AJ traceability.

## Consequences

### Field validation: topic AJ closure criteria met

| Trial # | Date | Feature | Path violations? | PM self-corrections intercepted |
|---|---|---|---|---|
| #1 | 2026-05-14 | Full F-SYSCHECK-1 delivery + PROP-021 + PROP-022 | ❌ 0 | 3 (#43/#44/#45) |
| #2 | 2026-05-15 | Full F-ALARM-1 delivery + first topic BC meta-rule evidence | ❌ 0 | 3 (#46/#47/#48) |
| #3 | 2026-05-15 | Full F-REMIND-1 delivery + first Q4 field trial + topic G P0 prevention #3 | ❌ 0 | 0 (quick references worked) |

**Three cross-Sprint trials / zero path violations / zero recurrences of #38/#41/#42 / all six PM self-corrections intercepted** ✅

### Consecutive correct applications of ADR-022 decision 5

Since topic AJ started, ADR-022 decision 5's four-role boundary rule has been applied correctly **nine consecutive times**: PROP-019 P1/P2/P3 + F-SYSCHECK-1 + PROP-021 + PROP-022 + the F-ALARM-1 fix + F-ALARM-1 + F-REMIND-1. The #41/#42 pattern recurred **zero times**.

### Benefits

1. **Topic AJ works in practice**: Cross-tool consistency plus a reminder before misrouting provides 80% of the value. Markdown path D performs better than the original runtime path C.
2. **Six permanent meta-rules**: AJ / AT / AM / AO / BC / BE all enter framework `agent/rules/` and `项目PM/速查表/`.
3. **The self-correction chain is broken**: Today's six self-corrections (#43-#48) were all intercepted: five by Claude Code's PROP-014 three-level check and one by PM self-review; the first Q4 trial had zero boundary violations.
4. **Greater capacity for framework complexity**: The Project PM memory hub in PROP-023 addresses complexity exceeding what one PM chat can maintain.

### Costs

1. **About six PM hours**: PROP-020 P1'-P4' + PROP-023 P2+P3 + five role files + quick references + trial #26 ADR closeout.
2. **Ongoing cross-Sprint maintenance**: Each role switch requires decision-checkpoint and a 状态.md entry, about 1-2 minutes.
3. **Topic AR's seven Q4 dimensions remain candidates**: A future PROP-024 or similar must formally incorporate them into the workflow.

### Follow-up

1. **PROP-024 candidate**, at Sprint-5 closeout / RETRO-009:
   - Upgrade decision-checkpoint to Q1-Q4, including dimensions a-g.
   - Split alarmManager: topic AY's accumulated pressure increased it from 14.3KB to 23.0KB, beyond the warning range.
2. **Gradual PROP-023 P4-P6 migration across Sprints**: Centralize field reviews, topic backlog, PM self-corrections, and role-transition history.
3. Combine the **ADR-024 candidate** (topic AP cross-tool decision framework) and **topic AN subtype refinement** at RETRO-009.

### Cross-Sprint monitoring after topic AJ closes

- Mark PROP-020 Completed after this ADR ships.
- Continue the cross-Sprint PM role-transition history; do not stop recording it.
- If the #38/#41/#42 pattern recurs, reopen AJ and start a PROP-025 v3 upgrade.

## Reversal rule

If path D later reveals a structural blind spot, **do not revise this ADR**. Create ADR-N explaining why, and mark this ADR "Partially superseded by ADR-N," following the ADR README's reversal rule.

## Related files

- [PROP-020 main proposal](../../../确认改动/已审批/进行中/PROP-020-2026-05-14-Agent团队架构.md) — full topic AJ implementation plan.
- [agent/agents/项目PM-咪咪.md](../../../agent/agents/项目PM-咪咪.md) and four other role files — PROP-020 P1'.
- [agent/agents/AI边界.md](../../../agent/agents/AI边界.md) — five-category upgrade, PROP-020 P2'.
- [agent/workflows/decision-checkpoint.md](../../../agent/workflows/decision-checkpoint.md) — three mandatory questions, PROP-020 P3'.
- [agent/rules/web-api-信源选型.md](../../../agent/rules/web-api-信源选型.md) — topic AT meta-rule, PROP-022 Phase 3.
- [项目PM/](../../../项目PM/) — Q4 defense through seven PROP-023 P3 quick-reference files.
