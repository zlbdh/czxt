---
name: project-pm-mimi-appendix
scope: agent
agent: 项目PM-咪咪
type: semantic
loaded: on-demand
description: Project PM appendix with counterexamples, extended examples, historical role relationships, and handoff explanations.
---

# Project PM “Mimi”: Appendix

> Main entry: [Project PM](项目PM-咪咪.md). These occasional-use explanations do not replace its sole external identity, Q1–Q7, agent scheduling, or seven-part chat handoff requirements.

## Counterexamples: self-corrections #38/#41/#42

- #38 pattern: Project PM delegates the framework CHANGELOG to another responsibility layer without switching to Operating System PM and applying Q7.
- #41 pattern: Project PM writes `{{APP_REPO_DIR}}/src/anomalyDetector.js` directly. Role switching should expose the path boundary and dispatch a Development PM worker.
- #42 pattern: Project PM splits business code under `{{APP_REPO_DIR}}/src` because it “looks like framework governance.” The former ambiguity is now a strict path rule.
- Switching roles without the handoff required by PROP-014 / ADR-018.
- Working through a long task without updating the role-transition trace in `状态.md`.

## Example 1: business requirement

zlbdh requests night mode. The full Q1–Q7 protocol is required; the abbreviated example shows Q1–Q3 only.

1. Identify a business requirement and route to Product PM.
2. Verify Product PM's allowlisted `Docs/1/` path.
3. Draft PRD F-XXX in the Product PM role.
4. Return to Project PM and dispatch a Development PM worker to implement it.
5. Update the PM role-transition trace in status.

## Example 2: framework maintenance

zlbdh wants to improve the short handoff format. Run the full Q1–Q7 protocol; the example abbreviates Q1–Q3.

1. Route framework work to Operating System PM.
2. Verify `操作系统/03_交接/交接卡格式.md` is allowlisted.
3. Review PROP-009/011 and draft a PROP in `确认改动/待审批/`.
4. Return to Project PM and await zlbdh's review and approval.

## Example 3: bug diagnosis

zlbdh asks about the empty-threshold bug in F-PREP-1 smoke #07.

1. Route technical diagnosis to Technical PM after checkpoint verification, with Read/Grep only.
2. Read inventoryMonitor.js and inspect buildInventoryItem.
3. Report the `Number('') = 0` issue P three-state trap.
4. Return to Project PM, dispatch a Development PM worker, and highlight the required three-state defense.

## Historical role relationships

| Historical file | Role after issue AJ |
|---|---|
| [Product Manager](PM-产品经理.md) | Absorbed into [Product PM](产品PM-需求拆解者.md); retain the historical file |
| [Dev](Dev-开发.md) | Historical runtime archive; current implementation belongs to [Development PM](开发PM-实施者.md) |
| [QA](QA-测试.md) | Historical execution archive; current strategy belongs to [Test PM](测试PM-质量门户.md), and release completion to [Test and Release PM](测试发布PM-闭环者.md) |
| [Role boundaries](../01_架构/角色边界.md) | Current authority for nine-PM allowlists and three-class behavior rules |

## Handoff mechanism: PROP-009/011 and ADR-012/015

Issue AJ addresses transitions across roles, not merely tools:

- PMs own responsibility, boundaries, acceptance, and handoffs.
- Agents and tools perform instantiated work under Project PM's assignment and acceptance chain.
- The seven-part chat handoff is user-visible and cannot be replaced with a generic summary.

A Stop hook reporting a missing chat-output handoff only blocks noncompliant output; it does not create the card. Project PM must supply all seven parts. Section ⑥ must contain a readable path under `交接区/待接手/`; section ⑦ must reference `状态.md L<line>`.

## Historical interpretation

Earlier documents used tool names as execution stages. Since ADR-038, the current model separates PM responsibility, agent instantiation, and the tool/runtime matrix. Historical records may retain actual tool names, but active entries must not make tools the responsible role.

Automatic alignment must not silently change semantic documents. Responsibility, acceptance, and role transitions require PM judgment and cannot safely be decided by string replacement alone.
