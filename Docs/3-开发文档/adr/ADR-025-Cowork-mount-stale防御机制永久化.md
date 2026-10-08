# ADR-025 · Permanent Cowork stale-mount defenses (topic BK v3)

- **Status**: Current
- **Date**: 2026-05-19
- **Related**: [ADR-023 topic AJ PM subroles](ADR-023-议题AJ落地-PM角色子类化+decision-checkpoint.md) · [ADR-024 permanent topic P](ADR-024-议题P用户输入三态边界永久化.md) · [PROP-024 Phase 2 defenses](../../../确认改动/已审批/已完成/PROP-024-2026-05-19-架构债治理v4-4包综合治理.md) · [Current source of truth for post-codex-push defenses](../../../能力资产/rules/codex-push后防御.md)
- **Topic BK closure criteria**: ≥3 accumulated trials + zero application incidents + complete multidimensional symptom identification + stable, effective defenses ✅ Met

> ⚠️ **Current safety override notice (2026-06-15)**: This record preserves the May 2026 stale-mount evidence, but the preapproved reset path has been superseded by current Class B/C boundaries. Suspected stale/dirty state now requires read-only verification first. Any recovery command that rewrites the working tree requires explicit authorization for this occurrence under [`能力资产/rules/codex-push后防御.md`](../../../能力资产/rules/codex-push后防御.md); historical commands here must not be copied and executed directly.

## Context

Topic BK first appeared after Codex pushed Sprint-5 v3.6.1. Three cases accumulated **symptoms across several dimensions**:

| Trial | Time | Dimension | Symptoms |
|---|---|---|---|
| #1 | 2026-05-19 12:00 (v3.6.1) | Falsely dirty working tree + corrupt git index | Five modified files, including apparent deletion of 143 real F-DEVIATION-3 code lines; `.git/index` reported `bad signature 0x00000000` |
| #2 | 2026-05-19 14:45 (v3.6.2) | Apparent file truncation | Profile.jsx appeared to lose seven lines, gain trailing spaces, and lose its final newline |
| #3 | 2026-05-19 17:00 (v3.6.3) | Multiple simultaneous patterns | 18 falsely dirty files; physically present `alarmManager.js` reported `no read permission`; the first ls of `personaPrompts/` missed two of three files, while the second refreshed automatically |

**Confirmed root cause**, from PROP-024 Phase 2:
- Cowork mount POSIX permissions + cross-tool stale cache + unsynchronized refresh windows.
- **Not a bug**, but a mount design tradeoff between speed and freshness.
- **No application blocker**: Codex's fresh filesystem showed the real state; every push was correct and GitHub code remained complete.

**Historical recovery evidence**: All three cases used `git reset --hard HEAD` for recovery; early case #1 also used `rm .git/index + git reset`. Both verification checks passed each time, with **zero application incidents**.

## Decision

**Permanently close topic BK** and add it to the framework's permanent cross-tool infrastructure limitation meta-rules.

### Decision 1 — Mandatory dual PM verification after a Codex push

After every Codex report of "push complete / working tree clean," the Cowork PM **must** run:

```bash
# 1. Verify immediately after the push
cd "$PROJECT_ROOT"
git status --short    # Check for a dirty tree
git log --oneline -1  # Check HEAD against the commit hash reported by Codex
```

If `git status` is not clean, proceed immediately to the recovery guidance in decision 2.

Before any PM Edit / Write / mv operation, **verify again** to prevent delayed stale-mount refresh from contaminating later work.

### Decision 2 — Historical recovery path, superseded by current safety boundaries

The May 2026 recovery path below is historical evidence only. **It is no longer preapproved for execution**:

```bash
cd "$PROJECT_ROOT"
git status --short              # Confirm the dirty state
git diff <file> | head -30      # Distinguish real deletion from a stale-mount artifact, usually the latter
git reset --hard HEAD           # Restore the working tree
git status                      # Verify a clean tree
```

⭐ **Current execution**: After read-only checks, request explicit authorization for this occurrence under `codex-push后防御.md`, then decide whether to restore the working tree.

### Decision 3 — Special index-corruption path, historical and rare

When `git reset` reported `bad signature 0x00000000 / fatal: index file corrupt`, which occurred only in case #1 on v3.6.1, the following was used:

```bash
rm .git/index           # Remove the corrupt index
git reset               # Rebuild the index from HEAD with a soft reset
git reset --hard HEAD   # Apply the basic recovery
```

### Decision 4 — Record the defense in the framework; its current source has moved

The current source of truth is [`能力资产/rules/codex-push后防御.md`](../../../能力资产/rules/codex-push后防御.md). Historical `agent/rules/` paths are no longer execution entry points.

### Decision 5 — Expand the meta-rule pool from eight to nine

`Topic BK defenses` — dual stale-mount verification + preapproved reset — becomes the ninth permanent meta-rule, alongside G/AT/AM/AO/BC/BE/AJ/P, named **Topic BK · Cowork stale-mount defenses**.

Future cross-tool infrastructure limitations belong in this category, including similar issues that might appear in Codex's fresh filesystem.

## Consequences

### Benefits

1. **Persistent cross-Sprint protection**: The PM verifies after every Codex push, protecting the zero-incident record.
2. **Independent of PM conversation changes**: A new PM reads this ADR and `codex-push后防御.md` to begin.
3. **Complete evidence from three cases**: No need to explain stale mounts and the historical reset rationale repeatedly.
4. **Eight permanent meta-rules become nine**, strengthening framework assets.

### Costs

1. **Five seconds of PM verification after each Codex push**, a very low cost.
2. **The stale-mount root cause remains** and depends on future Cowork mount improvements; topic BK v4 remains a candidate.
3. **A PM in a new conversation must read ADR-025 and codex-push后防御.md** to recognize stale-mount symptoms.

### Cross-Sprint monitoring after topic BK closes

- ✅ Stop labeling cases as "topic BK trial N"; verification is routine after every Codex push.
- ❌ If a **new dimension** appears, such as stale state in Codex or after a GitHub Actions push, **reopen BK** and create a new ADR to revise the decision.
- ✅ After ≥10 post-push verifications without a trigger, assess whether the mount implementation has improved and whether the rule can become monitoring-only.

## Reversal rule

If a previously unidentified stale-mount dimension appears, **do not revise this ADR**. Create ADR-N explaining why and mark this ADR "Partially superseded by ADR-N," following the ADR README.

## Related files

- [agent/rules/codex-push后防御.md](../../../agent/rules/codex-push后防御.md) — defense implementation: six sections, dual verification, three recovery levels.
- [PROP-024 Phase 2 implementation](../../../确认改动/已审批/已完成/PROP-024-2026-05-19-架构债治理v4-4包综合治理.md) — first delivery of the defense.
- [RETRO-009 topic BK v3](../../7-复盘/RETRO-009-2026-05.md) — full records of three trials and the ADR decision.
- [agent/rules/]/ — framework meta-rule pool; BK becomes rule nine.

## Milestone after topic BK closes

Permanent BK closure establishes the **nine-rule permanent framework pool**:

| # | Topic | ADR |
|---|---|---|
| 1 | G: reactive hooks | Implicit in PROP-021 |
| 2 | AT: web API source authority | Implicit in PROP-022 |
| 3 | AM: CHANGELOG headers | Implicit in PROP-018 |
| 4 | AO: PROP status-field semantics | Implicit in PROP-020 |
| 5 | BC: static Capacitor plugin imports | Implicit in PROP-024 Phase 1 |
| 6 | BE: mandatory PM startup quick-reference check | Implicit in PROP-023 |
| 7 | AJ: PM subroles + decision-checkpoint | **ADR-023** |
| 8 | P: three-state user-input boundaries | **ADR-024** |
| **9** | **BK: Cowork stale-mount defenses** | **ADR-025, this record** |

---

## 2026-06-09 addendum (PROP-043 / RETRO-016 lesson 3) — Four mount defenses

Four defenses distilled from Cowork stale-mount / truncation incidents, related to ADR-033's large-file mount distrust and focused here on collaborative git use and 状态.md append operations:
1. **git show HEAD:<path>** bypasses the mount cache to read committed truth. diff/status metadata is trustworthy; wc/Read content may be stale.
2. **Do not trust wc/grep on large files**: A stale chimera may expose old bytes or incomplete function bodies. Use the Read tool directly plus a positive match: a new string matched by grep must really exist, because stale content cannot invent it.
3. **Use `cat >> ` with O_APPEND for append-only files such as 状态.md**. Never use read-modify-write, which can overwrite concurrent PM append entries.
4. **Green build/vitest results in a real shell are code-integrity ground truth**. The implementer's real shell is authoritative; incomplete Cowork mount reads do not mean missing code. Codex's real-shell gates provide the final check.
