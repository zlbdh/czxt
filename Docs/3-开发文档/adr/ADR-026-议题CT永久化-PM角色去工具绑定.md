# ADR-026 · Make topic CT permanent: decouple PM roles from tools (PM abstraction layer ⊥ tool layer)

- **Status**: Current
- **Date**: 2026-05-22
- **Related**: [PROP-035 PM/tool decoupling](../../../确认改动/已审批/已完成/PROP-035-2026-05-22-PM角色去工具绑定.md) · [PM self-correction #64](../../../PM工作区/项目PM-咪咪/PM自纠/PM自纠-64.md) · [PM self-correction #66](../../../PM工作区/项目PM-咪咪/PM自纠/PM自纠-66.md) · [Tool matrix](../../../操作系统/01_架构/工具载体矩阵.md) · [Role boundaries](../../../操作系统/01_架构/角色边界.md)
- **Topic CT closure criteria**: Three pieces of evidence, task #104.2 / #104.4 / #104.5; two accumulated PM self-corrections, #64/#66; and all nine PMs decoupled from tools in the v4.0 target architecture ✅ Met

> Current terminology: Earlier "child / grandchild" roles correspond to today's "decision / implementation" roles. The four layers are now consistently called lead–meta–decision–implementation.

## Context

Topic CT originated in PM self-correction #64, when zlbdh asked whether names such as "Claude Code PM" and "Codex PM" in the eight-PM matrix bind roles to tools, and what would happen if tools changed.

Historical problems:
- The v3.x PM matrix used tool names as PM names, including Claude Code PM, Codex PM, and Cowork PM.
- PMs are actually **abstract collaboration roles** for decisions, implementation, verification, and knowledge consolidation. Tools are **replaceable hosts**: Cowork, Cursor, Cline, Codex, and Roo Code can run the same PM.
- Changing tools invalidated the whole framework, making it **nonportable across tools**.

PM self-correction #66 further identified that "cross-tool scheduling" is itself inaccurate. The activity is **cross-PM scheduling** through a Markdown protocol; which tool hosts each PM is a separate concern.

## Decision

**Permanently close topic CT** and add it as the tenth permanent meta-rule.

### Decision 1 — PM role definitions must not use tool-based names

All nine definitions in `操作系统/02_智能体/*.md` use **abstract identities**, implemented in task #104.2 ✅:

| PM role | Abstract identity | ❌ Prohibited name |
|---|---|---|
| Project PM | Mimi | ~~Cowork PM~~ |
| Knowledge PM | Curator | ~~Cowork PM~~ |
| Development PM | Implementer | ~~Claude Code PM~~ |
| Test and Release PM | Closer | ~~Codex PM~~ |
| Five decision PMs | Operating System / Product / Technical / Test / Operations | ~~Tool-name PM~~ |

Future PM roles **must** use responsibility names such as Curator or Closer, never tool names such as "xxx Code PM."

### Decision 2 — Tool mapping is separate from role definitions

`操作系统/01_架构/工具载体矩阵.md` maps the **PM abstraction layer to the tool layer**, implemented in task #104.4 ✅:

| Layer | File | Content | Mutable? |
|---|---|---|---|
| PM abstraction | `操作系统/02_智能体/*.md` | Nine roles, responsibilities, and decision authority | ❌ Stable |
| Tool hosting | `操作系统/01_架构/工具载体矩阵.md` | The current tool hosting each PM | ✅ Replaceable |

Replacing a tool, such as Cowork → Cursor, **changes only 工具载体矩阵.md, not PM role definitions**.

### Decision 3 — Pure Markdown protocol for cross-PM scheduling

PM communication uses **only a Markdown protocol**, with no tool-specific API dependency:

- Handoff cards in `交接区/`.
- Chat shorthand ①-⑦, PROP-014 + PROP-027 v2.
- Cross-PM transition history in 状态.md.
- PROP / ADR / RETRO / CHANGELOG.
- decision-checkpoint Q1-Q6.

Any Markdown-compatible tool can join the framework, with zero tool lock-in.

### Decision 4 — Expand the meta-rule pool from nine to ten

Add **Topic CT · PM/tool decoupling**, alongside G/AT/AM/AO/BC/BE/AJ/P/BK:

```
G  PRD source adherence          (accumulated field evidence)
AT Path adherence                (accumulated field evidence)
AM Multi-role collaboration      (accumulated field evidence)
AO Error isolation               (accumulated field evidence)
BC Cowork engineering consistency (accumulated field evidence)
BE Mandatory startup checks      (accumulated field evidence)
AJ PM subroles                   → ADR-023
P  Three-state input boundaries  → ADR-024
BK Cowork mount stale            → ADR-025
🆕 CT PM/tool decoupling         → ADR-026, this record
```

Future rules that decouple PM roles from their tool hosts belong to topic CT.

### Decision 5 — Permanent portability of the nine-PM matrix (inference)

Decisions 1-4 imply that the nine-PM lead–meta–decision–implementation architecture is portable to any Markdown-compatible tool combination: Cowork + Claude Code + Codex, Cursor + Cline, or Roo Code alone.

See v4.0 candidates A/B/C/D in the [tool matrix](../../../操作系统/01_架构/工具载体矩阵.md) for future tool-stack upgrades.

## Consequences

### Benefits

- ✅ Cross-tool framework portability: PM roles remain stable while tools are replaceable.
- ✅ PM definitions **do not become invalid when tools change**.
- ✅ Tool-replacement decisions and PM decisions are **fully decoupled**, permanently resolving topic CT.
- ✅ Introducing Cursor / Cline / Roo Code requires changing only the tool-matrix file.

### Risks and mitigations

| Risk | Mitigation |
|---|---|
| An abstract identity such as Curator may not reveal the actual hosting tool | Maintain the current mapping in 工具载体矩阵.md and state the current host at the top of each role file |
| Tool-specific behavior differs, such as Cowork stale mounts | ADR-025 is tool-specific but expressed through Markdown; adapt implementation to each tool's actual behavior |

### Verification

| Dimension | Method | Result |
|---|---|---|
| No tool names in role definitions | grep `Claude Code\|Codex\|Cowork` in 操作系统/02_智能体/*.md | ✅ Zero matches; no tool names in role files |
| No API dependency in cross-PM communication | Check handoff cards, chat shorthand, and 状态.md for Markdown | ✅ 100% Markdown |
| Replaceable hosting tools | Four v4.0 candidates A/B/C/D in 工具载体矩阵.md | ✅ Replacement demonstrated |

## Implementation checklist (retrospective)

- ✅ task #104.2 — Three new roles with tool-independent names: Development PM Implementer / Test and Release PM Closer / Knowledge PM Curator.
- ✅ task #104.4 — Create 工具载体矩阵.md, 6.5KB.
- ✅ task #104.5 — Create physical workspaces for nine PMs.
- ✅ task #106.1 — Synchronize topic CT in 议题全景.md.
- ✅ task #107.2 — Make this ADR permanent, 2026-05-22.

## Referenced decisions

- PM self-correction #64: The eight-PM matrix is bound to tool names and must be decoupled.
- PM self-correction #66: Rename cross-tool scheduling to cross-PM scheduling.
- v4.0 target vision §I: nine PMs × four categories; §III: tool-matrix layer.
- 工具载体矩阵.md in 操作系统/01_架构/: PM abstractions versus tool-host mapping.

---

⭐ **ADR-026 is permanently current, alongside ADR-022/023/024/025 as a framework meta-rule ADR.**
