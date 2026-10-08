---
name: decision-checkpoint-附录
scope: project
type: procedural
loaded: on-demand
description: Decision checkpoint reference appendix — failure cases, DoD integration, practical records, issue AJ closure conditions, and references; split out in PROP-042 handoff 1.
---

# Decision Checkpoint Appendix — References, Examples, and History

> Primary document: [decision-checkpoint.md](decision-checkpoint.md): Q1–Q7 protocol, core path allowlist, and agent instantiation.
> This appendix contains reference examples, historical conditions, and related links. Read as needed; split out in PROP-042 handoff 1 / issue AY.
> Tool names in historical examples identify the runtime used at that time; they do not define current responsibility or authority.

---

## Failure handling: actual issue AJ cases

### Case 1: Q2 identifies a boundary violation — issue AJ defense works

```text
Project PM intends: "Split messages out of anomalyDetector.js, 9070B."

Q1: Appears to be framework governance: refactor without changing business behavior → Operating System PM role.
Q2: Search the path allowlist in 操作系统/01_架构/角色边界.md.
   → Operating System PM allowlist: 操作系统/ + 能力资产/ + tools/ + 确认改动/ + Docs/3/ + 7/ + project root.
   → Intended edit: {{APP_REPO_DIR}}/src/shared/anomalyDetector.js.
   → ❌ {{APP_REPO_DIR}}/** is not allowlisted → proceed to Q3.
Q3: Outside boundary → return to Project PM → write a handoff to Development PM "Implementer" (runtime: Claude Code).
   → ✅ Defense works and prevents a repeat of PM self-correction #41.
```

### Case 2: Ambiguous Q1 — risk of selecting the wrong role

```text
Project PM intends: "Rename PROP-020 P0 experiment file _pingtest.md to archived."

Q1: File is under .claude/agents/ → not framework maintenance in the then-current five-PM path example.
    Current work follows the nine-PM path allowlist and actual agent mechanism.
   → Return to Project PM and hand off to Development PM "Implementer" (runtime: Claude Code).
Q2: N/A; Q1 already identified that this role cannot perform the work.
Q3: Default action = hand off to Development PM "Implementer" (runtime: Claude Code).

→ ✅ Defense identifies the gray area: work may look like internal maintenance but belong to another PM's responsibility; tools are only runtimes.
```

### Case 3: Rare Q3 exception — emergency

```text
Emergency: a framework bug crashes PM role switching and blocks all work.

Q1: Operating System PM.
Q2: Skipped as a rare exception.
Q3: Take the Operating System PM role and repair the framework bug.
   → At the same time, explicitly record "Boundary exception — emergency framework repair" in the PM transition log in 状态.md.
   → Immediately after repair, open the governance PROP required by the issue AJ reassessment mechanism.
```

---

## Integration with the implementation-loop DoD

The [implementation loop](实施循环.md) DoD expanded from five to six items:

- [ ] **Decision checkpoint** Q1–Q7 completed ✅: PROP-020 P3' + ADR-038 Q7.
- [ ] **Code** implements the PRD with no remaining TODOs.
- [ ] **Tests**: vitest, esbuild, and vite build all pass.
- [ ] **PRD** moves from in progress to completed, with an entry in requirement history.
- [ ] **PROP archival**: status changes to completed, file moves, and README counts are updated.
- [ ] **Both reconciliation skills** pass: project health check and status inference.

---

## Practical records: PM transition log in 状态.md

Each decision-checkpoint run and role transition adds one row to `状态.md`, as designed in PROP-020 §5:

```markdown
## 🎩 PM Role Transitions

| Time | From role | To role | Task | Decision checkpoint completed? | Completion feedback |
|---|---|---|---|---|---|
| 2026-05-14 12:15 | Project PM | Operating System PM | Draft PROP-020 path D enhanced v0 | ✅ | ✅ |
```

This makes PM self-correction patterns visible across sessions and runtimes and supplies evidence for RETRO-009.

⭐ **Lesson from PM self-correction #76**: after editing `状态.md`, search for `task #XXX` and verify its actual line number. A keyword match alone is insufficient; use Read to verify against misleading Bash mount-cache output.

---

## Issue AJ closure conditions: PROP-020 §6, archived under ADR-023

Issue AJ closes only when all four subconditions pass:

1. ✅ Five role Markdown files implemented: PROP-020 P1' completed 2026-05-14 12:25.
2. ✅ Role-boundary rules upgraded; the early AI-boundary document was merged into `操作系统/01_架构/角色边界.md`.
3. ✅ This workflow created and referenced by the implementation loop: PROP-020 P3' complete.
4. ✅ At least three real PM uses did not repeat the #38/#41/#42 pattern, verified across Sprints.

Archived under [ADR-023: issue AJ PM role specialization and decision checkpoint](../../Docs/3-开发文档/adr/ADR-023-议题AJ落地-PM角色子类化+decision-checkpoint.md).

---

## Related references

- [Role boundaries](../01_架构/角色边界.md) — nine PMs across lead, meta, decision, and implementation layers; path allowlists.
- [Project PM](../02_智能体/项目PM-咪咪.md) — coordinator, routing decision maker, and sole external identity under ADR-031.
- [Operating System PM](../02_智能体/操作系统PM-框架管家.md) — core issue AJ role.
- [Implementation loop](实施循环.md) — six-item DoD includes this workflow.
- [Meta-rule pool](../01_架构/元规则池.md) — permanent AJ rule, ADR-023.
- [ADR-023](../../Docs/3-开发文档/adr/ADR-023-议题AJ落地-PM角色子类化+decision-checkpoint.md) — current decision record for issue AJ.
