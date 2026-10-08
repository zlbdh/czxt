# ADR-024 · Make topic P's three-state user-input boundaries permanent (10 cross-Sprint trials + consistency across three layers)

- **Status**: Current
- **Date**: 2026-05-19
- **Related**: [ADR-019 dual-source data governance (topic P first applied in F-DAY-2)](ADR-019-数据双源治理.md) · [ADR-023 PM subroles + decision-checkpoint](ADR-023-议题AJ落地-PM角色子类化+decision-checkpoint.md) · Topic P closeout criteria 10/10 ✅
- **Topic P closure criteria**: ≥10 complete trials + consistent design / tests / UI + zero boundary violations (zero incidents caused by violations) ✅ Met

> ⚠️ **Current override notice (2026-06-15)**: The three-state principle remains current. Old `agent/` paths in the body show the implementation locations at the time and are not current execution entry points. Current rule entry points are under `操作系统/` + `能力资产/`.

## Context

Since its first application in Sprint-4 F-DAY-2 / F-DEVIATION-2, topic P's three-state user-input handling has had **10 complete implementations** across Sprint-4 and Sprint-5:

| # | Feature | Sprint | Consistent across three layers |
|---|---|---|---|
| 1 | F-DAY-2 day rollover | Sprint-4 | ✅ |
| 2 | F-DAY-3 exceptions | Sprint-4 | ✅ |
| 3 | F-BRIEFING-1 LLM | Sprint-4 | ✅ |
| 4 | F-DEVIATION-2 detection | Sprint-4 | ✅ |
| 5 | F-PREP-1 inventory | Sprint-4 | ✅ |
| 6 | F-SYSCHECK-1 system status | Sprint-5 | ✅ |
| 7 | F-ALARM-1 alarms | Sprint-5 | ✅ |
| 8 | F-REMIND-1 reminders | Sprint-5 | ✅ |
| 9 | F-DEVIATION-3 plans | Sprint-5 | ✅ (v3.6.1 shipped) |
| 10 | **F-WEEKLY-1 weekly report** | Sprint-5 | ✅ (this card shipped) |

**Across six sprints / 10 complete implementations / zero boundary violations / three-layer consistency** — all topic P closeout criteria are met.

Original topic P statement, triggered by Sprint-4 PM self-correction #28:
> JavaScript's `Number("")` === 0 trap accompanies three states of user-input data: null, a valid value, and a missing field. Every new feature involving user input or external data must handle these states consistently in design, tests, and UI.

## Decision

**Permanently close topic P** and include it among the framework's eight permanent meta-rules: G / AT / AM / AO / BC / BE / AJ / **P**.

### Decision 1 — Four mandatory topic P boundaries

Every new feature involving user input, external data, LLM output, or time-related data **must** handle four boundary categories:

```
#1 null / unavailable → fallback without breaking the application
#2 Invalid value (out-of-range number / invalid string / wrong type) → filter / error / default
#3 Missing field (undefined / unset) → explicitly distinguish default from null
#4 Boundary crossing (midnight / week / time zone / language) → defer automatically / recalculate
```

### Decision 2 — Mandatory consistency across three layers

Each topic P boundary scenario must align across **design + tests + UI**:

```
Design: Handoff card §④ explicitly states all four boundaries; PM searches 项目PM/速查表/ when drafting.
Tests: Unit/source contract tests cover every boundary; Claude Code must add them during implementation.
UI: Visible user feedback and fallback paths through Chat / Card / Toast, etc.
```

A missing layer violates topic P and triggers the PM self-correction chain, as with topic AJ path violations.

### Decision 3 — Add topic P to quick references and Q4 defenses

Add `项目PM/速查表/议题P边界速查表.md` under a future PROP-N. The PM **must check it** before drafting a handoff card, following topic BE's startup mechanism.

### Decision 4 — Cross-Sprint monitoring after closeout

- ✅ **Stop labeling work as "topic P implementation N"**: Every feature must apply it; it is no longer a milestone.
- ❌ If a future violation omits a boundary or three-layer consistency, **reopen topic P**, create a new PROP for root-cause investigation, and upgrade to topic P v2.
- ✅ From Sprint-6, RETRO no longer counts topic P implementations: they are mandatory by default, following the topic AJ post-closure pattern for path violations.

## Consequences

### Benefits

1. **Permanent topic P means an internalized defense**: Each feature defaults to four boundaries and three-layer consistency, **without a PM reminder**.
2. **Seven framework meta-rules become eight**: Topic P permanently joins the mandatory rule pool.
3. **Faster handoff drafting**: The PM can search the quick reference and fill in the four boundaries.
4. **More robust future features**: Common LLM failures, missing data, skipped user input, and boundary-crossing bugs are handled by default.

### Costs

1. **A fixed ~30 extra minutes per feature** for handoff design and test coverage of all four boundaries, offset by debugging avoided; historical topic P self-corrections #28-30 saved about 10h.
2. **One new topic P boundary quick-reference file**, pending PROP-N and not blocking closeout.
3. **Reopening requires reversing ADR-024**: Follow the ADR README rule by writing a new ADR, not changing the original decision.

### Related assets

- `项目PM/速查表/议题P边界速查表.md` — pending / to be created at RETRO-009.
- `agent/rules/议题P-用户输入三态.md` — pending / companion to the quick reference.
- Update the permanent eight-rule list: G / AT / AM / AO / BC / BE / AJ / **P**.

## Reversal rule

If the four boundaries and three-layer consistency have a structural blind spot, such as a new feature type they cannot cover, **do not revise this ADR**. Create ADR-N explaining why and mark this ADR "Partially superseded by ADR-N," following the ADR README.

## Related files

- [Sprint-5需求清单.md](../../1-需求文档/Sprint-5需求清单.md) — topic P boundaries required for each F-XXX.
- [ADR-023 PM subroles](ADR-023-议题AJ落地-PM角色子类化+decision-checkpoint.md) — the same permanent-closure pattern for topic AJ.
- [项目PM/速查表/](../../../项目PM/速查表/) — topic P quick-reference location.
- v3.6.2 commit message — milestone anchoring this ADR's draft.
