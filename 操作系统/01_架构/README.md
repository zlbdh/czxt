---
name: architecture-index
scope: project
type: semantic
loaded: on-demand
description: Architecture entry point — role boundaries, agent scheduling, meta-rules, runtime matrix, three-class behavior rules, and README design.
---
# Collaboration Architecture

> The framework's constitutional layer: evolution principles, role boundaries, decision ownership, and the state machine.

| File | Contents |
|---|---|
| [Evolution philosophy](演化哲学.md) | Three expansion questions specifically for new PM roles; do not imitate a real company's structure or complicate a single workflow |
| [Role boundaries](角色边界.md) | **Nine PMs across lead, meta, decision, and implementation layers**, path allowlists, and decision ownership; v4.0 / task #104.1 |
| [Specialized PM modes](PM专业mode能力层.md) | Requirements, design, frontend, backend, and hardware specialties first use modes, plugins, and workers; avoid casually adding PM roles |
| [Collaboration appendix](角色边界-协作附录.md) | External identity rule, counterexamples, knowledge retention, verification, and meta-rule governance |
| [PM workspace boundaries](PM工作区边界.md) | Nine private PM workspace paths and cross-boundary prohibitions |
| [Agent scheduling](子agent调度机制.md) + [appendix](子agent调度机制-附录.md) | PM work instantiated as agents, workers/explorers, single-source files with no parallel writes, and B-lite |
| [Meta-rule pool](元规则池.md) + [candidates](元规则池-候选.md) + [appendix](元规则池-附录.md) | **23 permanent meta-rules, v3.9**, 17 candidates, Knowledge PM governance, ADR-023–038 |
| [Tool/runtime matrix](工具载体矩阵.md) + [appendix](工具载体矩阵-附录.md) | Complete separation of abstract PM roles from tool runtimes; ADR-026 / issue CT. Appendix covers candidate runtimes and migration vision |
| [Three-class behavior rules](三类行为铁律.md) + [appendix](三类行为铁律-附录.md) | Class A automatic, Class B requires asking, Class C never; appendix covers gray areas, reversal, and L1-L4 mapping |
| [README design](README设计规范.md) | Three required sections, update triggers, and issue DN health-check procedure; task #120 |
| [State machine](状态机.md) | Five task states: PLANNED→DELIVERED→ACCEPTED/CONDITIONAL/REJECT→CLOSED |

## Maintenance

- Synchronize whenever roles or decision ownership change.
- Owner: Operating System PM “Framework Steward.”
