# ADR-016 · Delegate Conditional Git Permissions to AI (PROP-012)

- **Status**: Current
- **Date**: 2026-05-11
- **Decision maker**: zlbdh
- **Related**: [PROP-012](../../../确认改动/已审批/已完成/PROP-012-2026-05-11-AI-git权限下放.md) · Revises AI-boundary portions of [ADR-008](ADR-008-框架自动化升级.md) / [ADR-010](ADR-010-框架自动化v3-9隐患全封堵.md)

> ⚠️ **Current override notice (2026-06-15)**: The 6 Class B conditions for git commit / push remain the foundation. ADR-022 and [`../../../操作系统/01_架构/三类行为铁律.md`](../../../操作系统/01_架构/三类行为铁律.md) refine AI configuration: local baseUrl/model/apiKey configuration in `{{APP_REPO_DIR}}/.env.local` follows Class B safeguards; disclosing real secrets, writing them into tracked files, or sharing real keys is Class C.

## Context

PROP-011's handoff area improved collaboration but exposed **new workflow friction**.

### 3 Violations or Exceptions on 2026-05-11

| Time | Event | Nature |
|---|---|---|
| 15:30 | zlbdh explicitly asked Codex to push the debt-cleanup changes | One-time exception |
| 16:00 | After F-002 smoke, zlbdh again asked Codex to run git push | Second signal in the same direction |
| 16:05 | Cowork PM used Edit to change `{{APP_REPO_DIR}}/package.json` from 2.3.0 to 2.7.0, only later recognizing Class C rule 1 | PM violated its own rules |

### Pain Points

- zlbdh is PM/Owner, not the Git operator; requiring a manual push each time adds friction.
- Class C's “never” assumed irreversible, high-risk operations. The application repository was recorded at that time as:
  - Private, not public.
  - Owned by zlbdh, who could roll back with force-push.
  - Having no collaborators to affect.
  - Low actual risk.
- Allowing AI to build APKs while forbidding version bumps interrupts the workflow.
- ≥2 exceptions indicate a rule that no longer matches practice.

## Decision

Move the following from Class C, forbidden, to **Class B, conditionally allowed for AI**:

| Former Class C action | New class | Conditions |
|---|---|---|
| Change `package.json` version | **Class B** | Allowed with an APK release task; an isolated bump still requires asking |
| Routine git commit / push on main | **Class B** | All 6 conditions must hold |

### 6 Class B Git Push Conditions

1. ✅ Only the main branch of the primary `{{APP_REPO_DIR}}/` repository.
2. ✅ Truthful commit message based on actual working-tree changes; no false claims.
3. ✅ No force, rebase, or history rewriting.
4. ✅ On push failure, stop immediately, record the error in a handoff card, and do not retry.
5. ✅ State the commit hash and push result in the handoff card.
6. ✅ Contextual authorization: zlbdh explicitly requested it, or the previous handoff explicitly allows the next recipient to push.

If any condition fails, stop immediately, write a handoff, and await zlbdh's decision.

### Hard Class C Safeguards Retained

| Class C action | Reason |
|---|---|
| `git push --force` / force push | Irreversible history rewriting |
| `git rebase` of pushed commits | Same |
| Delete branches or tags; operate on another fork-remote | Irreversible or out of scope |
| Create Git tags or publish releases | Release decision |
| Upload APKs to distribution channels | Publication decision |
| AI baseUrl / apiKey configuration | Historical classification; local `.env.local` now follows Class B safeguards, while disclosing real keys or writing them into tracked files remains Class C |
| Delete user notes, backups, or data | User ownership |
| Change historical `apk/` or `Docs/6-历史归档/` content | Historical records stay unchanged |
| Fabricate data | Honesty first |

## Implementation Details

| Phase | File | Change |
|---|---|---|
| P1 | `agent/agents/AI边界.md` | Remove version from C; add force-push safeguard; add commit/push and version rows to B; update L1–L4 matrix |
| P2 | `agent/workflows/实施循环.md` | Change commit/push capability from ❌ to conditional ✅; add force push ❌; update 4 environments' DoD; add 6-condition reference |
| P3 | This ADR and ADR README index | — |
| P4 | `确认改动/README.md` counts/completed list and PROP-012 closure | — |

## Consequences

### Benefits
- ✅ Removes repeated manual pushes from zlbdh's workflow.
- ✅ Codex / Claude Code / Cowork can complete the cycle, including commit/push.
- ✅ Rules match actual work without repeated exceptions.
- ✅ Force push, publication decisions, private keys, and user data remain protected by Class C.

### Costs
- ❌ AI must follow all 6 conditions, checked through handoff warning section ⑤.
- ❌ Contextual authorization can be ambiguous and must be explicit in the handoff.

### Mitigated Risks
- ✅ False commit claims: condition ② requires truth and ⑤ records a verifiable hash.
- ✅ Misread authorization: condition ⑥ requires identifying its source explicitly.
- ✅ Repeated failed pushes: condition ④ requires immediate stop.
- ✅ Wrong branches or force: conditions ① and ③ set hard limits.

## L3+ Change Sequence

| # | Change | ADR |
|---|---|---|
| 12 | **PROP-012 AI Git delegation** (this ADR) | **ADR-016** |

PROP-012 is the second new L3+ after RETRO-004. RETRO-005 follows the fourteenth L3+, 2 changes later.

## Summary of the Recorded Decision

ADR-016 changes git push from forbidden to conditional, enabling the development/test/release cycle while retaining 6 safeguards against exceeding authority.
