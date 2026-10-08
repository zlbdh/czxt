---
name: dev-role-legacy
scope: project
type: semantic
loaded: on-demand
description: "Historical Claude Code development role: file inventory, mount write limits, write strategy, and pre-QA checks. Superseded by the Development PM playbook."
---

# Dev Playbook: Development Role

> Historical archive: the current Development PM entry is [Development PM](开发PM-实施者.md). This file preserves the former Dev role as a historical example, not current execution policy. Do not copy its commands or write procedures into current execution.

Mimi used this role while writing code. Its purpose was reliable, verifiable implementation of the PRD.

## Trigger

A PRD item moves from “Designing” to “Implementing.”

## Inputs

- A PRD item with acceptance criteria (AC) and affected files.
- The corresponding design document section.

## Outputs

- Modified source files.
- New or updated tests.
- Historical example: the old workflow also updated CHANGELOG. The current Development PM does not write framework files.

## Standard procedure

### Step 1: Historical file inventory — do not copy into execution

Check each affected file's size to avoid mount write problems:

```bash
wc -lc src/features/xxx/Xxx.jsx src/shared/yyy.jsx
```

### Step 2: Historical write strategy — do not copy into execution

```text
< 6 KB: Write directly to the target.
6–8 KB: Write to outputs/X.jsx, then use bash cp -f.
> 8 KB: Write part1 and part2 to outputs, then concatenate into the target.
Small edits: Python re.sub in place was the most reliable option.
```

### Step 3: Write code

- Change the data layer first: database.js, defaults.js, and shared helpers.
- Then change the component layer: components.jsx.
- Finally change features: features/*.jsx.
- **Immediately verify each modified file with `tail -3` and `wc -lc`.**

### Step 4: Write tests

Each new pure function requires a vitest test in a neighboring `*.test.js` file.

Template:

```js
import { describe, expect, it } from 'vitest';
import { newFn } from './newFile.js';

describe('newFn', () => {
  it('handles happy path', () => {
    expect(newFn(input)).toEqual(expected);
  });
  it('handles edge: null/empty', () => {
    expect(newFn(null)).toBe(null);
  });
});
```

### Step 5: Historical documentation synchronization — do not copy into execution

- CHANGELOG.md: the former workflow updated this file; the current Development PM does not write the framework CHANGELOG.
- Update affected README.md files and documentation sections.

## Anti-patterns

- Changing five files and running tests without verifying the files first.
- Overlooking a file above 9 KB and truncating it through a direct Write.
- Changing logic without tests.
- Ignoring vite build warnings.

## Historical 9 KB write-limit rule — do not copy into execution

```text
Observed behavior: Write/Edit tools had an approximately 9,105-byte hard limit on mount paths.
They could report success after writing only part of a file, truncating at a UTF-8 boundary.
Symptoms: an incomplete tail or a file size stuck at 9,105 bytes.

Workarounds, in descending order of reliability:
1. Python re.sub in place: most reliable for small edits.
2. Write to outputs/ and copy with bash cp -f: outputs also had limits, but sometimes worked.
3. Write part1 and part2, then concatenate with bash cat: the only reliable large-file method.
4. Direct Write: only for files below 6 KB.
```

## Verification checklist before step 5

- [ ] `tail -3` shows a valid JavaScript ending for every modified file.
- [ ] No file above 8 KB was truncated.
- [ ] All key markers remain after Python in-place edits.
- [ ] Every acceptance criterion has corresponding implementation or tests.
