# PROP-001 · PreToolUse Soft Gates for Path Allowlists and Class C Rules

- **Status**: Approved · Completed (implemented 2026-06-22, as recorded in CHANGELOG for that date)
- **Date**: 2026-06-22.
- **Proposed by**: Operating System PM "Framework Steward"; recorded from rank 4 of the multidimensional dogfood audit, scheduled by Project PM "Mimi".
- **Estimated level**: L3; changes hook interception semantics and framework guards.
- **Implementation record**: On 2026-06-22, Project PM assigned an Operating System PM worker to implement path soft gates in both `pre-write-guard.ps1` files and hooks-smoke fixtures. The main session reviewed the work; README/index, hooks-smoke, and health gates all passed. See CHANGELOG for 2026-06-22.

> **Publication and Git boundary:** this proposal's implementation excludes commit, push, tag, and version actions. Git `--force`, `rebase`, and `tag` below describe only the scope of option C. Implementation commits and pushes must be finalized at a single point in the main session by Test and Release PM "Closer", subject to ADR-016's six conditions. Stop after a failed push; do not retry.

## One sentence

Turn Class C boundaries such as writing `Docs/6-历史归档/**` and existing `apk/**` files into mechanical soft gates in `pre-write-guard.ps1`, using `permissionDecision=ask`, never deny, so the claimed three safeguards have an operational foundation beyond AI remembering the rules.

## Background and motivation

- The main finding of the 2026-06-22 multidimensional dogfood audit was that the framework claimed three safeguards—Q1–Q7, path allowlists, and three-class rules—but provided no mechanical write-time enforcement of the latter two. It relied on the AI remembering to search `三类行为铁律.md`.
- PM self-corrections 88, "PMs also forget," and 91, "soft-rule failure requires automated hooks," had already demonstrated that memory alone was insufficient.
- Both `能力资产/tools/hooks/claude|codex/pre-write-guard.ps1` files detected only secret writes to files other than .env and asked for confirmation. They did not intercept Class C paths such as `Docs/6-历史归档/` or historical `apk/` files.
- This was a self-hosting gap: written rules lacked an operational gate. Fixing it used the operating system to improve itself.

## Proposed approach

Reuse the proven design of `pre-write-guard.ps1`: ask without denying, with fail-safe behavior throughout. Add path decisions after secret detection:

- An Edit/Write target under `Docs/6-历史归档/**` produces `permissionDecision=ask`, citing the Class C rule against changing historical archives.
- A write to an **existing** `apk/**` file asks for confirmation, citing the historical-APK rule.
- Always ask, never deny. Uncertainty and parse failures continue without blocking, matching the existing secret gate's fail-safe behavior.
- Update both Claude and Codex versions using disjoint worker write sets and main-session review.
- Add positive and negative fixtures to `能力资产/tools/hooks/tests/hooks-smoke.ps1` and verify the health gate.

## Estimated impact and cost

- Effort: S–M.
- Affected files: approximately 3–4; both hooks, smoke fixtures, and the hooks README/event matrix if counts change.
- Risk: low. These paths are rarely written, minimizing prompt fatigue. False positives ask without blocking legitimate work, and hook errors remain fail-safe.
- Schema change: No.

## Alternatives

- **A, this proposal:** begin with the two high-value, low-noise groups: historical archives and historical APKs.
- **B:** also ask on single-source files that prohibit parallel writing, such as `状态.md` and CHANGELOG. **Not recommended:** these change every sprint and had been edited more than five times in this session. Per-write prompts would create fatigue. Scheduling discipline and Class C rules govern concurrency.
- **C:** add command-level warnings for Git `--force`, `reset --hard`, `rebase`, and `tag -d` through user-prompt-submit or Bash PreToolUse. Reserve this for Phase 2 to avoid scope growth and false positives for words such as "rebase."

## Likely reasons for rejection

- The two path groups are rarely written, so the marginal benefit may appear small. The safeguard is specifically for forgotten rules; a low-cost fallback is preferable to none.
- zlbdh may prefer to cover Git command-level Class C actions at the same time, which would combine this work with option C.

## Out of scope

- Deny behavior; the hook always asks.
- Ask gates for single-source files, option B.
- Git command interception, option C / Phase 2.
- Changing the Class C list or path-allowlist semantics. This adds mechanical support for existing rules only.
