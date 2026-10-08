---
name: "capacitor-version-verify"
description: "Read {{APP_REPO_DIR}}/package.json before adding @capacitor/* dependencies to confirm the Capacitor major version. Prevents self-correction #46."
trigger: "Before adding a new @capacitor/XXX dependency"
loaded: "条件加载（按 trigger 匹配时由 PM 调度）"
---

# Quick Reference: Capacitor Dependency Versions — Self-Correction #46

> Before a handoff adds `@capacitor/*`, **read {{APP_REPO_DIR}}/package.json and confirm the Capacitor major version**.

## Mandatory sequence

1. Read `{{APP_REPO_DIR}}/package.json`.
2. Check the major version of `@capacitor/core`, such as `^6.1.2` or `^7.0.0`.
3. Explicitly specify `@capacitor/XXX@^N.x` in the handoff, where N is the core major version.
4. Do not write `^latest`, or `^7.x` when core is `^6.x`.

## Historical evidence

### Self-correction #46: May 15, 2026, PROP-022

- Handoff requested `@capacitor/network@^7.x`.
- Actual project used `@capacitor/core: ^6.1.2`.
- Claude Code followed decision-checkpoint and installed `^6.0.4` to avoid a major-version conflict.
- Installing `^7` would have broken the build in that setup.

### F-ALARM-1: May 15, 2026, PROP-023 review

- Handoff explicitly specified `@capacitor/local-notifications@^6.x`, incorporating lesson #46.
- Claude Code read package.json and installed `^6.1.3` based on that evidence.

## Required for later Capacitor-plugin proposals

- Read package.json before drafting the PROP/handoff.
- State the `^N.x` major version explicitly.
- Add a Capacitor-version check to handoff caution section ⑤.
- Record the major version in a commit-message note for future searches.

## Related rules

- [Web API source selection](../../../能力资产/rules/web-api-信源选型.md): issue AT matrix, another record of cross-platform pitfalls.
- [Plugin integration safeguards](plugin集成防御.md): installation also requires static imports and NotificationChannel setup.
