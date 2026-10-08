# ADR-035 · Deterministic LLM-chain tests + the #95 source-grep assertion pattern

- **Status**: Current
- **Date**: 2026-06-09
- **Decision maker**: zlbdh approved; Knowledge PM drafted, PROP-043.
- **Related**: RETRO-016, three #95 collisions; RETRO-018/019, LLM call chains; meta-rules DQ + DR.

## Context

Two lessons recur. First, new LLM forms repeatedly pass unit tests and fail on devices, such as F sodium / G-F6, because tests cover pure functions instead of the complete mock → normalize → card-output chain. Second, source-grep assertions (#95) in RETRO-016 failed three times in one batch: forbidden-word checks matched terms appearing in comments or unqualified Chinese words, producing false passes or false failures. Both are cases of tests missing their real target.

## Decision

- **DQ: Deterministic LLM-chain tests**. Every new LLM form — caller, prompt injection, or parser — must include a deterministic mock LLM response → normalize → card/result test. Cover compliant response → correct artifact, malformed/null response → graceful fallback, and required markers. A passing pure-function test does not prove the chain works.
- **DR: #95 source-grep assertion pattern**. Assert only **code identifiers**: component names, testids, parenthesized calls such as `fn(`, and import paths. **Never assert strings that can also occur in comments, Chinese copy, or bare words**; a comment edit can create a false pass, while copy can create a false failure. To lock behavior, prefer parenthesized calls plus a negative assertion such as `not.toMatch`.

## Consequences

### Benefits
- CI gains a deterministic proxy for whether an LLM feature can produce a card on-device. Full-chain mocks reproduce device failures, such as v3.34 recurrence:null corrected by fallback.
- Source-grep checks enforce code contracts without false passes/failures caused by comments or copy changes.

### Costs
- More test-writing effort for LLM changes, including mocked callAIFn injection.
- DR requires considering whether an asserted term could occur in a comment.

### If the decision is reversed later
- Delete chain tests and return to pure-function tests, but the unit-green/device-fail risk returns. Reversal is inexpensive and not recommended.

---

## Notes
DQ makes ADR-030's evidence-driven CC rule concrete in tests: if passing unit tests does not imply device success, mock the full chain into the unit tests.
