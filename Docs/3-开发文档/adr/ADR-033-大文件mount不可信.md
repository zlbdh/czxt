---
name: adr-033
scope: project
type: semantic
loaded: on-demand
description: "ADR-033 permanent topic CY: large-file mount operations are untrustworthy (stale reads/inaccurate wc, truncated writes, Read as sole truth, tail verification after >6500B writes, full device runs for framework-tool changes); extends ADR-025 to writes; meta-rule 16"
---

# ADR-033 · Make topic CY permanent: large-file mount operations are untrustworthy

- **Status**: Current

> Promotion: Candidate CY (#67) + #92/#94/状态.md mount breakage, with 3+ cases today in Sprint-11, become meta-rule sixteen.
> Drafted by Knowledge PM Curator; decided by Project PM Mimi; RETRO-015.

## Context

ADR-025, topic BK, made Cowork stale-mount → git reset defenses permanent, but covered only **stale git status reads**. Sprint-11 revealed much broader **large-file** mount unreliability:

- **#92**: Tool verification relied solely on Read, without a full device run, allowing stale P4a-d paths to escape detection for days.
- **#94**: Editing 21KB outputs with Edit **truncated the tail** to `Wr`; copying to the device made the script fail.
- **状态.md, 84KB**: Python `open().read()` failed UTF-8 decoding on a partial character; bash `tail` stopped at L589; `grep` returned false negatives. The mount served incomplete, wrong-version, mutually inconsistent bytes for the same file.
- **#67, original topic CY**: wc -l was inaccurate before a long-file Read.

Common finding: **Mount reads (wc/grep/cat/python) and tool writes (Edit/Write) are both untrustworthy for files >6500B**, while the **Read tool is the truth channel**, consistently returning correct device content.

## Decision

**Large-file (>6500B) mount operations are untrustworthy. Four mandatory rules apply:**

1. **Read is the sole truth channel**. Before asserting file state, recheck with Read. Do not trust bash/python mount reads or memory; even the PM violated BK at 12:25.
2. **Verify the tail after every >6500B write**. Immediately use Read on the **tail** after Edit/Write/cp/heredoc writes to catch truncation, as in #94.
3. **Run the entire framework tool/script on the device after modifying it**. Testing only the new section is insufficient, as #92 showed.
4. **Mid-file edits to large files**: Edit risks truncation above 6500B, and mount-based Python reads may be stale or truncated. Use **bash append at EOF only**, which is reliable, or **Python read-modify-write with multiple guards** for decoding, size, a tail sentinel, and count==1. Stop if the read is incomplete. If all guards fail, edit on the actual device. Mount reads of the 84KB 状态.md were completely broken in practice, requiring device-side work.

## Consequences

- ✅ Extend ADR-025 from stale git reads to untrustworthy large-file reads and writes; permanently close CY.
- ✅ Give ADR authority to check-operating-system.ps1 P4e's mount-cache warning.
- 🟡 状态.md has reached 84KB; consider splitting it in the topic backlog.
- Meta-rule sixteen; meta-rule pool v3.6.1 → v3.7.
