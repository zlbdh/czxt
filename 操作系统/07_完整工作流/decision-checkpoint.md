---
name: decision-checkpoint
scope: project
type: procedural
loaded: on-demand
description: Mandatory Q1–Q7 checks before a PM changes roles or starts work.
---

# Workflow: Decision Checkpoint — Mandatory Q1–Q7 Checks

> The core defense against role misrouting in issue AJ. Replace intuitive judgments with evidence from the rule tables.

## Triggers

Run Q1–Q7 first in any of these situations:

1. The Project PM is about to take on any other PM role.
2. Before editing or writing any file.
3. When an intuitive judgment suggests that work “looks like framework or internal maintenance.”
4. During a long task, to prevent process drift.
5. At the start of a new session, as required by the [implementation loop](实施循环.md) DoD.

## Mandatory Q1–Q7 protocol

| Question | Assessment | Required action |
|---|---|---|
| Q1: Which PM owns this work? | Check the task and path: framework → Operating System PM; PRD → Product PM; diagnosis → Technical PM; test strategy → Test PM; `{{APP_REPO_DIR}}/src/` → Development PM; release completion → Test and Release PM | Identify the role; switch roles if necessary |
| Q2: Is the path allowlisted? | Search the complete nine-PM path allowlist in the [role boundaries](../01_架构/角色边界.md) | Work only on an allowlisted path; otherwise proceed to Q3 |
| Q3: How is an out-of-scope task handled? | Default to the responsible PM; an emergency framework repair requires an explicit exception | Write a handoff card, switch to the correct PM, and record the transition in status |
| Q4: Which quick reference applies? | Read `PM工作区/<X-PM>/速查表/INDEX.md` and the [shared skills index](../02_智能体/共享技能/INDEX.md); load by trigger | Load only applicable references; do not fill context with unrelated material |
| Q5: What is the change scale? | Classify L1–L4 using the [decision details](decision-checkpoint-判定细则.md) | If scale increases, rerun Q1–Q7 and update the handoff/status records |
| Q6: Does this require cross-PM coordination? | Coordinate PM roles, not tools; see the decision details | Write a handoff/ship card through the handoff area |
| Q7: Should an agent be instantiated? | Writes default to a worker; read-only work defaults to an explorer; single-source files and release actions have a single-owner exception | The Project PM centrally spawns and accepts the work |

## Q1: Role routing

| Scenario | Owner |
|---|---|
| Change `操作系统/`, `能力资产/`, `确认改动/`, `交接区/`, or root framework files | Operating System PM “Framework Steward” |
| Write a PRD or change a Sprint requirement list | Product PM “Requirements Analyst” |
| Diagnose bugs, choose technology, or assess effects across files | Technical PM “Fix Strategist” — read-only |
| Test strategy, acceptance checklist, or mock design | Test PM “Quality Gate” — read-only |
| Change any business or test code in `{{APP_REPO_DIR}}/src/` | Development PM “Implementer” |
| Version bump, APK build, vitest, physical-device smoke, commit, or push | Test and Release PM “Closer” |
| Simple confirmation, status query, or external report | Project PM “Mimi” |

## Q2: Path allowlist

Consult the [role boundaries](../01_架构/角色边界.md) every time you run Q2. Do not rely on memory.

| Path | Authorized role | Boundary |
|---|---|---|
| `操作系统/**`, `能力资产/**`, `项目配置/**`, `项目区/**`, `Docs/3-开发文档/**`, `Docs/7-复盘/**` | Operating System PM | Other PMs must not write directly |
| `确认改动/**` | Operating System PM; Product PM may write `待审批/` | Technical and Test PMs must not write |
| `交接区/**`, `状态.md` | Project PM / Operating System PM, according to responsibility | Single-source files must not be written concurrently |
| Root `README.md`, `AGENTS.md`, `实例化项目.ps1`, `.gitignore` | Operating System PM maintains entry points; Project PM only finalizes records | Class B review boundary; entry points must not carry detailed rules |
| `Docs/1-需求文档/**` | Product PM | Other PMs must not write |
| `{{APP_REPO_DIR}}/src/**` | Development PM | A different current PM must write a handoff or dispatch a worker |
| `{{APP_REPO_DIR}}/package.json`, APK, tag, push | Test and Release PM under ADR-016/release conditions | Other PMs must not directly bump versions or produce packages |
| Local untracked `{{APP_REPO_DIR}}/.env.local` configuration | Conditional Class B; only user-authorized local environment repairs | Do not commit, disclose, or copy into tracked documentation |
| API key disclosure, tracked secrets, or irreversible deletion of user data | None | Class C; AI must never perform these actions |

## Q4–Q7 details

- Q4 triggers, Q5 scale adaptation, Q6 cross-PM coordination, and Q7 agent instantiation: [decision details](decision-checkpoint-判定细则.md).
- Failures, DoD integration, practical records, and issue AJ history: [decision appendix](decision-checkpoint-附录.md).

## Prohibited shortcuts

- Switching roles intuitively without Q1 routing.
- Deciding whether a path is allowed from memory during Q2.
- Acting outside the boundary after Q3 to save time.
- Running Q1–Q7 without recording it in `状态.md`.
- Treating the checkpoint as a recitation without consulting the tables.

## Related references

- [Role boundaries](../01_架构/角色边界.md) — nine-PM path allowlist.
- [Three-class behavior rules](../01_架构/三类行为铁律.md) — authoritative Class A/B/C and Class C list.
- [Agent scheduling](../01_架构/子agent调度机制.md) — worker, explorer, and B-lite.
- [Project PM](../02_智能体/项目PM-咪咪.md) — coordinator and sole external identity.
- [Implementation loop](实施循环.md) — DoD includes this workflow.
