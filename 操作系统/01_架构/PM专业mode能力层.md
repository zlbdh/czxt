---
name: pm-specialized-mode-capability-layer
scope: project
type: semantic
loaded: on-demand
description: Rules for specialized modes, plugins, and workers covering requirements, design, frontend, backend, and hardware without expanding the nine PM roles.
---

# Specialized PM Modes and Capabilities

> **PMs define responsibility boundaries; modes provide specialized perspectives; plugins and workers provide execution capabilities.**
> Only a new responsibility boundary justifies a new PM. For specialized skills, first use an existing PM's mode, plugin, or worker.

## 1. Keep the current nine PMs

Retain the nine-PM structure. Do not add separate Requirements, Design, Frontend, Backend, or Hardware PMs.

| Specialty | Current owner | Implementation approach |
|---|---|---|
| Requirements PM | Product PM “Requirements Analyst,” requirements analysis mode | PRDs, requirements boundaries, and acceptance criteria |
| Design PM | Product PM “Requirements Analyst,” experience design mode | May use the `product-design` plugin for experience, information architecture, prototypes, and visual exploration |
| Frontend PM | Development PM “Implementer” worker + Technical PM explorer | Development owns frontend implementation; complex approaches receive technical diagnosis first |
| Backend PM | Development PM “Implementer” worker + Technical PM explorer | Development owns backend implementation; architecture, interface, and data risks receive technical diagnosis first |
| Hardware PM | Technical PM sub-mode + Development PM worker | Consider adding a PM only after actual work enters the device, firmware, BOM, or production-test workflow |

## 2. The Product PM's two modes

Product PM “Requirements Analyst” includes two modes by default:

| Mode | Trigger | Output |
|---|---|---|
| Requirements analysis | “I want,” “Can we,” “This is difficult to use,” or “Add a feature” | PRD entries, acceptance criteria, priorities, and edge cases |
| Experience design | Interface design, information architecture, prototypes, visuals, or interaction experience | Experience proposals, IA, prototype descriptions, and design exploration findings |

Using the `product-design` plugin does not change the path allowlist. It is a Product PM capability tool; it neither creates a new PM nor dispatches an agent automatically.

## 3. Conditions for adding a PM

A specialty seeking an independent PM role must still satisfy the three expansion questions in [evolution philosophy](演化哲学.md):

1. At least three documented instances of the same boundary conflict or misrouting.
2. A frequency of at least once per week.
3. Existing PM sub-modes, plugins, workers, and explorers cannot cover it.

If any condition is unmet, do not add a PM. First capture the capability as a mode, plugin capability, or worker brief template.

## 4. Role summary

> **Nine PMs provide the structure; specialized modes provide perspectives; plugins provide tools; workers and explorers are temporary execution instances.**
