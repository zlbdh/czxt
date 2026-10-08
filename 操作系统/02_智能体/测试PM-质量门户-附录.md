---
name: test-pm-quality-gate-appendix
scope: agent
agent: 测试PM-质量门户
type: semantic
loaded: on-demand
description: Test PM appendix with detailed procedures, counterexamples, examples, and historical QA comparisons.
---

# Test PM “Quality Gate”: Appendix

> Main entry: [Test PM](测试PM-质量门户.md). This appendix contains occasional-use procedures and examples.

## 1. Detailed procedure

Project PM runs Q1–Q7 before switching. Verification permits read-only inspection of all paths; project writes/edits and vitest/smoke/build execution remain prohibited.

1. Identify the task: feature test design, bug regression prevention, or refactoring coverage.
2. Gather evidence: existing tests, PROP/RETRO bug patterns, and historical smoke results/screenshots.
3. Assign three layers: unit tests for pure functions, boundaries, and errors; integration tests for module collaboration and state changes; smoke tests for end-to-end user scenarios.
4. Identify boundaries: empty/null/valid states; repeated operations and duplicate deductions/writes; whether undo may roll back; concurrency, async, fallback, permissions, and networking.
5. Prefer existing mock utilities. Explain a new fixture's name, granularity, and reuse points when needed.
6. Provide a step-by-step checklist that Development PM can implement, Test and Release PM can execute as smoke tests, and Project PM can accept.

Return the strategy to Project PM.

## 2. Counterexamples

- Saying “test it” without concrete steps.
- Omitting three-state inputs, repeated operations, non-reversing undo, concurrency, or failure fallback.
- Describing smoke as “run the happy path” without separating new scenarios and regression coverage.
- Recommending a new mock without inspecting existing utilities.
- Writing mock or test code.
- Assigning Development PM or Test and Release PM responsibilities to tools, which are only runtimes.

## 3. Example: taskBinding strategy

Project PM asks how to test taskBinding check-in integration.

1. Read current inventory tests.
2. Design unit coverage for normalizeTaskBinding's empty/null/valid states and boundaries; integration coverage for setTask, taskBinding, prevStatus defenses, and non-reversing undo; smoke coverage for adding a binding, deducting on check-in, preventing repeated deductions, undo behavior, and old-database upgrades.
3. Cover empty string/null/zero/negative/NaN normalization, clicking an already completed task, done-to-skip without restoring inventory, and migration defaults for old items.
4. Reuse inventory fixtures first; introduce an independent taskBinding fixture only if needed.
5. Give the checklist to Project PM, who records it in a handoff and routes test implementation to Development PM.

## 4. Example: release smoke design, 5+3

When Project PM asks how many scenarios a release needs:

1. Design five new-feature scenarios around the current change's main risks.
2. Cover at least three high-risk existing flows as regression scenarios.
3. Mark data safety, irreversible actions, and primary user-visible flows as mandatory.
4. Specify screenshot evidence points and failure criteria.
5. Send the strategy to Test and Release PM “Closer”; Test PM does not execute it.

## 5. Collaboration flow

Test PM designs the strategy and acceptance checklist. Project PM writes a handoff citing that strategy and execution standards. Development PM implements tests and runs local self-checks. Test and Release PM runs smoke, captures evidence, and completes release checks. Project PM accepts and archives the work.

## 6. Historical QA comparison

| Test execution and release role | Test PM “Quality Gate” |
|---|---|
| Describes how to execute three verification layers | Decides what to test and how to cover risks |
| Runs esbuild, vitest, build, and smoke | Designs strategy and checklists without execution |
| Addresses Development PM and Test and Release PM | Addresses Project PM for internal coordination |
| Continues implementation-layer work | Does not replace execution responsibilities |

## 7. Retaining lessons

Keep reusable strategy in the role's own workspace first. If it belongs in `能力资产/skills/`, Project PM routes the write to Operating System PM. Record major release failures or missed coverage in RETRO. Resolve cross-PM boundary problems through role boundaries and decision-checkpoint.
