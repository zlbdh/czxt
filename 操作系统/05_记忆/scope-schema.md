---
name: memory-scope-schema
scope: project
type: semantic
loaded: triggered
trigger: Creating memory files, adding frontmatter to existing files, or implementing PROP-037.
description: YAML scope schema for 12 memory locations — global, project, agent, pm-workspace, and session scopes with three types.
---

# Memory Scope YAML Schema (PROP-037 / ADR-028)

> **Background**: issue CW and the memory-governance plan require explicit scopes for 12 memory locations, preventing confusion between private PM context and shared context.
> **Terminology**: `scope=agent` identifies PM-playbook ownership under `操作系统/02_智能体/`; it does not mean a runtime subagent. Private PM workspaces use `scope=pm-workspace` with a `pm:` field.
> **Industry reference**: Mem0 uses three tiers, user/agent/runtime. This framework preserves ADR-028's global/project/agent/session semantics and adds the `pm-workspace` implementation layer so a private PM workspace is not mislabeled as a runtime agent.

---

## 1. YAML frontmatter schema

Put this at the **top** of each memory Markdown file in the framework:

```yaml
---
name: <kebab-case-slug>          # Required; unique identifier
scope: project                 # Required; global | project | agent | pm-workspace | session
type: semantic                 # Required; episodic | semantic | procedural
agent: <PM name>                # Optional; PM playbooks in 02_智能体 when scope=agent
pm: <PM name>                   # Required when scope=pm-workspace
loaded: always                 # Optional; always | on-demand | triggered
trigger: <condition>            # Required when loaded=triggered
description: <one sentence>     # Required; one line, at most 120 characters
---
```

## 2. Scope definitions

| Scope | Applies to | Examples |
|---|---|---|
| **global** | Cross-project, AppData, or user-level information | Retired AppData memory pointers and user preferences. |
| **project** | Project-wide information shared by all PMs | INDEX.md, issue overview, ADRs, shared skills. |
| **agent** | PM-role playbooks and abstract role ownership | `操作系统/02_智能体/*.md`. |
| **pm-workspace** | One PM's private workspace, not shared across PMs | Quick references and self-correction artifacts in `PM工作区/<X-PM>/`. |
| **session** | One conversation or short-lived context | Short chat handoff, handoff card, top status snapshot. |

## 3. Three types, aligned with Mem0/LangMem terminology

| Type | Meaning | Examples |
|---|---|---|
| **episodic** | Events where timestamps matter | `状态.md`, `Sprint节奏.md`, Git history, timestamped PM self-corrections. |
| **semantic** | Facts, reflections, and rules | INDEX.md, issue overview, ADRs, shared-skill procedures. |
| **procedural** | Executable steps or procedures | PM quick references, shared-skill procedures, handoff templates. |

## 4. Three loading modes

| loaded | When to load | Applies to |
|---|---|---|
| **always** | Required at the start of a new session | INDEX.md, AGENTS.md, top status snapshot. |
| **on-demand** | As needed during PM role transitions | Role definitions and decision records. |
| **triggered** | When a specific condition occurs | Self-correction triggers, stale-mount defenses, Git undo/recovery. |

## 5. Scope mapping for 12 memory locations

| # | Location | scope | type | loaded |
|---|---|---|---|---|
| 1 | `操作系统/05_记忆/INDEX.md` and memory appendices in the same directory | project | semantic | always / on-demand |
| 2 | `状态.md` | project | episodic | always |
| 3 | `操作系统/00_变更记录/状态-archive/`: historical status slices, for traceability only | project | episodic | on-demand |
| 4 | `PM工作区/<X-PM>/速查表/` | pm-workspace | procedural | on-demand |
| 5 | `PM工作区/项目PM-咪咪/PM自纠/` | pm-workspace | episodic | triggered |
| 6 | `操作系统/02_智能体/共享技能/` | project | procedural | on-demand |
| 7 | PROP / ADR / RETRO / CHANGELOG / `状态.md` / `交接区` | project | semantic | on-demand |
| 8 | `操作系统/04_台账/议题全景.md` | project | semantic | always |
| 9 | `操作系统/04_台账/版本时间线.md + Sprint节奏.md` | project | episodic | on-demand |
| 10 | `能力资产/rules/ + shared/ + mcp/` | project | semantic | on-demand |
| 11 | AppData memory → INDEX pointers, retired to pointers only | global | semantic | on-demand |
| 12 | `{{APP_REPO_DIR}}/.git/` | project | episodic | n/a: application code, outside the framework |

## 6. Checklist for new memory files

- Add frontmatter at the top.
- Use a kebab-case `name`, such as `decision-checkpoint`.
- Select from the current scopes: global / project / agent / pm-workspace / session.
- Select one of the three types.
- For scope=agent, put the PM name in `agent`; this applies only to `操作系统/02_智能体/`.
- For scope=pm-workspace, put the PM name in `pm`; this applies to `PM工作区/`.
- For loaded=triggered, describe the condition in `trigger`.

## 7. Future extensions

- PROP-039 has been reassessed and split. If a new pilot starts, first test the value of an external memory store through local, read-only Mem0 retrieval. Do not treat Mem0 / Skills SDK GA as a current blocker.
- Automatically narrow decision-checkpoint Q4 quick-reference filtering by scope: for the Project PM role, prioritize `scope=pm-workspace pm=项目PM-咪咪` or `scope=project`.

---

⭐ **ADR-028 approved this schema as permanent on 2026-05-22.**
