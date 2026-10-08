---
name: state-inference-cross-session-monitor
scope: project
type: procedural
loaded: triggered
trigger: Session startup / cross-session handoff / an in-progress PROP / implementation keywords that may require rule updates / an exception is mentioned
description: Main entry for state inference checks 5–9 — cross-session handoffs, PROP alerts, rule-update triggers, exception counting, and RETRO index consistency.
---

# State Inference — Checks 5–9: Cross-Session Monitoring

> Main entry: [State inference](状态推断.md). Checks 1–4: [Basic reconciliation](状态推断-推断项.md).
> This file keeps the frequently used decision rules for checks 5–9. Full Bash/GNU fallbacks are in the [monitoring appendix](状态推断-跨session监控-附录.md).

## Startup order

1. Complete the five AGENTS startup steps first: `状态.md`, `操作系统/00_总入口.md`, `角色边界.md`, the latest pending handoff card, and the project health check plus Q1–Q7.
2. Run the necessary checks from items 5–9. Address or clearly hand off stale records, backlogs, stalled PROPs, repeated exceptions of the same kind, and RETRO index mismatches.
3. Treat findings as recommendations or risk signals. Do not decide on the user's behalf or replace the formal ①–⑦ handoff and PM tracking records.

## Check 5: Cross-session handoff cards

**Logic**: Prefer the newest file in `交接区/待接手/` as the previous handoff. Fall back to the summary at the top of `状态.md`.

Check:

- Whether the latest card exists.
- Whether the pending card includes complete sections ①–⑥, plus ⑦ when PM tracking applies.
- Whether the top of `状态.md` links to the latest pending handoff.
- Whether the handoff is substantially older than recent code or framework changes.
- Whether `交接区/待接手/` has a backlog; use the current threshold in `check-handoff-zone.ps1`.

Output format:

```text
📍 Previous handoff (YYYY-MM-DD HH:MM, from <A> to <B>):
   ① Task: …
   ② File changes: N new / M modified (including ≥6500B warnings: …)
   ③ Tests: vitest ✅/❌ | build ✅/❌ | APK ✅/❌ | smoke ✅/❌
   ④ Your next steps: …
   ⑤ Alerts: …
   ⑥ Q&A: …
   ⑦ PM transitions / next step: … (if included in the card)
```

If stale, rerun checks 1–4 to reconcile the facts instead of directly trusting `状态.md`. Legacy three-section cards remain readable, but recommend upgrading the next card to the base ①–⑥ format.

## Check 6: Stalled in-progress PROP alerts

**Logic**: When the modification time of a `确认改动/已审批/进行中/PROP-*.md` file is more than seven days old, ask whether to deprecate, split, or continue it.

Output:

- ✅ No long-running in-progress PROP.
- 🟡 `PROP-XXX` has been stalled for N days. Confirm whether to continue, split it, or move it to `已弃用/`.

## Check 7: Rule-update trigger monitoring

**Logic**: When implementation touches high-risk keywords, proactively check whether the corresponding rules need updating. For an already completed rules file, recommend focused rules or a PROP/ADR according to risk, rather than asking to populate it again.

| Rules file | Trigger keywords | Action |
|---|---|---|
| `操作系统/07_完整工作流/git流程.md` | git commit / git push / commit message / branch / tag | Recheck all six ADR-016 conditions; update the Git workflow for new branch, tag, or release scenarios |
| `能力资产/rules/安全与隐私.md` | API key / token / user privacy / backup / cloud upload | Add focused security rules or open a PROP/ADR according to risk |
| `能力资产/mcp/README.md` + `INSTALLED.md` | MCP / MCP integration / claude-in-chrome / cowork-mcp | Update the MCP inventory and sensitive-action boundaries |

## Check 8: Exception counter

**Logic**: Scan handoff cards and `状态.md` history for exceptions and one-time allowances, including legacy terms. Two or more exceptions in the same direction require an immediate governance PROP; do not wait for a third.

Broad categories:

- git / push / commit.
- version / bump / package.json.
- Other repeated process exceptions.

Output:

- 🔴 At least two in the same direction: open a governance PROP immediately.
- 🟡 One: record it and watch for recurrence.
- ✅ Zero: no action.

## Check 9: RETRO README index consistency

**Logic**: Warn when the number of actual `Docs/7-复盘/RETRO-*.md` files differs from the number of index rows in `Docs/7-复盘/README.md`.

Output:

- ✅ RETRO index is consistent.
- 🔴 File and index counts differ: complete the README index immediately.

## Current implementation entry points

- Handoff health: `能力资产/tools/scripts/check-handoff-zone.ps1`
- PM tracking freshness: `能力资产/tools/scripts/check-pm-tracking.ps1`
- Full health check: `能力资产/tools/scripts/check-operating-system.ps1`
- Legacy Bash/GNU fallback: [Monitoring appendix](状态推断-跨session监控-附录.md)

## Related references

- [State inference](状态推断.md) — entry point for all ten checks
- [Basic reconciliation](状态推断-推断项.md) — checks 1–4
- [Monitoring appendix](状态推断-跨session监控-附录.md) — Bash/GNU fallbacks and complete examples
- [Handoff format](../../操作系统/03_交接/交接卡格式.md) — the ①–⑦ contract
- [Handoff checker](../tools/scripts/check-handoff-zone.ps1) — current implementation of check 5
