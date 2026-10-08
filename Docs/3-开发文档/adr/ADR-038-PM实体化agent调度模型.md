---
name: adr-038
scope: project
type: semantic
loaded: on-demand
description: "ADR-038 concrete PM agent scheduling (PROP-044 made permanent / meta-rule 23 DX): agents for all nine PMs, Project PM as sole scheduler and acceptor, main-session final writes to single sources, no nesting, and controlled B-lite parallelism"
---

# ADR-038 · Concrete PM agent scheduling (PROP-044 made permanent)

- **Status**: Current
- **Date**: 2026-06-14
- **Decision maker**: zlbdh approved after asking "Why not start an agent?" four times; Knowledge PM drafted.
- **Related**: [PROP-044](../../../确认改动/已审批/已完成/PROP-044-2026-06-14-framework写入实体化与PM-agent化评估.md), made permanent · [RETRO-021](../../7-复盘/RETRO-021-2026-06.md), first B-lite trial · [RETRO-022](../../7-复盘/RETRO-022-2026-06.md), this batch's review · [ADR-027](ADR-027-议题CU+DD永久化-沉淀PM元层架构.md), nine PMs / four layers · [ADR-031](ADR-031-项目PM对外身份完整铁律.md), sole outward-facing Project PM · [`子agent调度机制.md`](../../../操作系统/01_架构/子agent调度机制.md), §III.5 + §IV.

> Current terminology: The earlier lead–meta–child–grandchild terminology is now consistently lead–meta–decision–implementation. This ADR's PM agent scheduling model is unchanged.

## Context

ADR-027 established the **role model** of nine PMs across lead–meta–decision–implementation, but work remained concentrated in the main session: roles were abstract, not instantiated as real agents. zlbdh asked four times today why agents were not being started. The root problem was default main-session framework editing, which was slow and failed to separate writing from acceptance. The role model needs an **executable agent scheduling model**, with real agents by default, while preserving ADR-031's single outward identity / decision point and ADR-027's hierarchy.

Decisive constraint: **Git worktree isolation does not apply to the framework**. The project root, {{PROJECT_ROOT}}, is not a git repository. Multiple framework workers cannot be isolated with worktrees; controlled parallelism must use disjoint write-set declarations, main-session integration, and a health-check gate.

## Decision

Make PROP-044 permanent as the **concrete PM agent scheduling model**, meta-rule **DX**, number 23:

### 1 — Agents for all nine PM roles

PM work **defaults to a real agent**: **writing = worker / read-only = explorer**.
- Project PM Mimi **is not separately instantiated**; it is the scheduler / main session.
- The other eight PMs start agents under this mapping when assuming a role, as defined in the PM→agent table in `子agent调度机制.md` §IV.

### 2 — Project PM is the sole scheduler and acceptor (ADR-031/027)

- **Spawn and acceptance authority always remain with Project PM Mimi**. Other PMs must not independently start agents or delegate spawn authority.
- The outward identity remains Project PM Mimi under ADR-031. Other agents provide internal signals, without independent outward attribution.
- **The acceptance chain stays flat and centralized in the Project PM**, with no unaccepted intermediate layer.

### 3 — Single-source files: agents draft; the main session writes last

`状态.md`, `CHANGELOG`, **`元规则池.md`**, and `角色边界.md` are single-source files with no parallel writing. Workers **draft only**; the main session **performs the final write**. Never assign parallel workers to edit them directly.

### 4 — No autonomous nested agents; acceptance remains centralized

Workers **must not spawn child agents themselves**. A worker needing help returns the request to the Project PM, which starts a **peer** agent and personally accepts its output.
- Nesting creates unsupervised first-line acceptance by a parent worker, weakening ADR-031's centralized quality control.
- B-lite, where the Project PM starts multiple **peer** workers, **is not nesting**. The former is allowed; an agent spawning another agent is prohibited.

### 5 — Controlled B-lite parallelism

Framework writes default to the main session. Use multiple workers **only for batches of at least six mutually exclusive files**:
- Split write sets by disjoint subdirectories/files; dispatch cards must declare exclusivity.
- The main session **integrates once** and enforces the health-check **gate**: accept only after `check-operating-system.ps1` exits 0.
- Single-source no-parallel files always retain one writer, as in decision 3.
- See `子agent调度机制.md` §III.5.

### 6 — Expand the meta-rule pool from 22 to 23, DX

```
…DT(ADR-037)
🆕 DX Concrete PM agent scheduling: agents for all nine PMs, sole Project PM scheduling/acceptance, main-session final writes to single sources, no nesting → ADR-038, this record
```

## Consequences

### Benefits
- PM work moves from main-session manual editing to default agents, separating writing and acceptance for higher throughput and quality.
- ADR-027's role model becomes an executable scheduling model with a standard answer to "Why not start an agent?"
- Single-source final writes, no nesting, and centralized acceptance extend ADR-031 into the agent model without dilution through parallelism.

### Costs
- The main session carries all spawning, integration, and acceptance load. Large parallel batches can waste time at barriers, as noted in candidate DU.
- Controlled parallelism adds independent scanning, sampling, and health checks; below six files, this may consume the benefit, hence §III.5's threshold.
- Without worktree isolation, exclusivity depends on declarations and acceptance rather than physical separation, requiring dispatch discipline; DV boundary probes mitigate this.

### If the decision is reversed later
- Return to direct main-session framework editing by removing agent instantiation, losing writing/acceptance separation and parallel throughput.
- Allowing nesting reintroduces unsupervised first-line acceptance. Strongly discouraged: this is an acceptance-quality baseline.

## Referenced decisions
- PROP-044: B-lite approval and assessment of concrete framework writers / PM agents.
- RETRO-021: First B-lite trial, 26 files / three workers / zero boundary violations; RETRO-022: R2, 35 files + agents for all nine PMs.
- ADR-027: Knowledge PM meta layer and nine-PM role model; ADR-031: sole outward Project PM identity.
- `子agent调度机制.md` §III.5, controlled parallelism; §IV, PM→agent mapping; §VI, centralized acceptance.

---

⭐ **ADR-038 is permanently current: meta-rule 23 DX, concrete PM agent scheduling, extending ADR-027+031 while preserving sole Project PM scheduling, acceptance, and outward identity.**
