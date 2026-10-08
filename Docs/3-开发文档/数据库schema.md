---
name: database-schema
scope: project
type: semantic
loaded: on-demand
description: Database schema template for a project instance. Code is authoritative for entities, indexes, migrations, and data safety.
---

# Database Schema

> The template root does not prescribe a storage engine, schema version, or business tables. After initialization, verify the project instance's facts against schema/migration code and the actual database. Leave unconfirmed content as `[fill in]`.

## Project instance source of truth

| Item | Current value | Authoritative evidence | Last verified |
|---|---|---|---|
| Storage engine | [fill in] | [fill in: configuration or initialization code] | Pending verification |
| Database name / namespace | [fill in] | [fill in] | Pending verification |
| Current schema version | [fill in] | [fill in: authoritative schema] | Pending verification |
| Migration entry point | [fill in] | [fill in: authoritative migrations] | Pending verification |
| Backup / restore entry point | [fill in] | [fill in] | Pending verification |
| Data residency and encryption | [fill in] | [fill in] | Pending verification |

When documentation conflicts with code, executable schemas, migration code, and actual probe results take precedence. Mark the documentation status as PENDING until the discrepancy is reconciled.

## Entity / table inventory

List only objects that actually exist in the current authoritative schema. Do not copy them from historical snapshots.

| Entity / table | Purpose | Primary key | Key indexes | Initial version | Data classification | Status |
|---|---|---|---|---|---|---|
| [fill in] | [fill in] | [fill in] | [fill in] | [fill in] | Public / internal / sensitive | Pending verification |

## Entity description template

### [Fill in: entity / table name]

| Field | Type | Required | Default | Index / constraint | Privacy notes |
|---|---|---|---|---|---|
| [fill in] | [fill in] | Yes / no | [fill in] | [fill in] | [fill in] |

Additional conventions:

- Primary key generation: [fill in]
- Time and time zone: [fill in]
- Deletion policy (soft delete / hard delete / retention period): [fill in]
- Concurrency and conflict handling: [fill in]
- Referential integrity: [fill in]
- Import/export mappings: [fill in]

## Version history

| Version | Change | Migration function / file | Forward compatibility | Rollback strategy | Verification evidence |
|---|---|---|---|---|---|
| [fill in] | [fill in] | [fill in] | [fill in] | [fill in] | [fill in] |

## Migration and compatibility

For every schema change, answer at least these questions:

1. Why is the change necessary, and could a nonstructural field address it?
2. How is old data upgraded? How are missing fields, null values, and duplicate records handled?
3. Is a version increment required, and which source controls that version?
4. Can an interrupted upgrade be rerun, and is it idempotent?
5. How does the old version handle or explicitly reject data written by the new version?
6. Have backup, restore, and rollback been verified on an actual copy?
7. Are record counts, key fields, and user data preserved across the migration?

### Migration acceptance record

| Scenario | Input version | Target version | Expected result | Actual evidence | Status |
|---|---|---|---|---|---|
| New installation | [fill in] | [fill in] | Empty database initializes | [fill in] | PENDING |
| Upgrade from an old version | [fill in] | [fill in] | No unintended data loss | [fill in] | PENDING |
| Retry after interruption | [fill in] | [fill in] | Safe recovery | [fill in] | PENDING |
| Restore from backup | [fill in] | [fill in] | Matching records and key fields | [fill in] | PENDING |

## Data safety gates

- Deleting real user data, irreversible migrations, and writing secrets are sensitive actions. Check the three-class behavior rules first.
- Prefer redacted copies for testing; do not output complete sensitive fields in logs.
- When adding an entity, update the schema, migrations, application read/write entry points, backup/restore behavior, and tests together.
- Passing tests alone does not establish the safety of real migrations. Record the actual version chain and evidence of data consistency.

## Historical boundary

Historical references from the source project are not current template facts. Earlier business tables, fields, and version chains have been removed from this document's current-facts section. Trace them through Git history or the corresponding ADR / RETRO when needed.
