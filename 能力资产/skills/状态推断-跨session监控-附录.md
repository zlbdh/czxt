---
name: state-inference-cross-session-monitor-appendix
scope: project
type: reference
loaded: on-demand
description: Appendix for state inference checks 5–9 — Bash/GNU fallbacks, legacy command templates, and full execution examples.
---

# State Inference Checks 5–9 — Appendix

Main entry: [Cross-session monitoring](状态推断-跨session监控.md). This appendix preserves Bash/GNU fallbacks and complete examples for older environments. Prefer the project's PowerShell checkers on Windows/Codex.

## Check 5: Bash example

```bash
latest_card=$(ls -t 交接区/待接手/*.md 2>/dev/null | head -1)
if [ -z "$latest_card" ]; then
  echo "✅ No pending handoff card"
else
  echo "📍 Latest pending handoff card: $latest_card"

  card_mtime=$(stat -c %Y "$latest_card" 2>/dev/null)
  latest_code_mtime=$(find {{APP_REPO_DIR}}/src -type f \( -name '*.jsx' -o -name '*.js' \) -printf '%T@\n' | sort -rn | head -1 | cut -d. -f1)
  diff_days=$(( (latest_code_mtime - card_mtime) / 86400 ))

  if [ "$diff_days" -ge 1 ]; then
    echo "🟡 The latest handoff card is $diff_days days older than the code changes and may be stale"
  fi
fi

pending_count=$(ls 交接区/待接手/*.md 2>/dev/null | wc -l)
if [ "$pending_count" -gt 3 ]; then
  echo "⚠️ The pending handoff directory has $pending_count cards and may have a backlog"
fi
```

## Check 6: Bash example

```bash
threshold=$(date -d '7 days ago' +%s)
for f in 确认改动/已审批/进行中/PROP-*.md; do
  [ -f "$f" ] || continue
  mtime=$(stat -c %Y "$f")
  if [ "$mtime" -lt "$threshold" ]; then
    days=$(( ($(date +%s) - mtime) / 86400 ))
    echo "⚠️ $(basename $f) has been stalled for $days days. Move it to the deprecated directory or split it?"
  fi
done
```

## Check 7: Bash example

This keyword search is a diagnostic example for legacy records; it does not validate current English privacy descriptions. Use `能力资产/tools/scripts/check-operating-system.ps1` for authoritative automated checks and review the security/privacy rules manually.

```bash
recent_changes="..."

echo "$recent_changes" | grep -qE "git push|git commit" && echo "⚠️ Git changed: recheck the six ADR-016 conditions; update the Git workflow for any new scenario"
echo "$recent_changes" | grep -qE "API key|token|隐私" && echo "⚠️ Privacy affected: add focused security/privacy rules or a PROP/ADR"
```

## Check 8: Bash example

This keyword search is a diagnostic example for legacy records; it does not validate every current English exception description. Use `能力资产/tools/scripts/check-operating-system.ps1` for authoritative automated checks and review exception evidence manually.

```bash
matches=$(grep -ril "破例\|exception\|此次例外\|一次性放行" \
  交接区/已接手/ 交接区/待接手/ 状态.md 2>/dev/null)

git_count=$(echo "$matches" | xargs grep -l "git\|push\|commit" 2>/dev/null | wc -l)
version_count=$(echo "$matches" | xargs grep -l "version\|bump\|package.json" 2>/dev/null | wc -l)
other_count=$(echo "$matches" | wc -l)

[ "$git_count" -ge 2 ] && echo "🔴 Exception counter: $git_count Git exceptions. Open a governance PROP immediately; do not wait for a third"
[ "$version_count" -ge 2 ] && echo "🔴 Exception counter: $version_count version exceptions. Open a PROP immediately"
[ "$other_count" -ge 2 ] && echo "🟡 Total exceptions: $other_count. Check whether at least two concern the same issue"
```

## Check 9: Bash example

```bash
actual=$(ls Docs/7-复盘/RETRO-*.md 2>/dev/null | wc -l)
indexed=$(grep -c "^| \[RETRO-" Docs/7-复盘/README.md 2>/dev/null || echo 0)

if [ "$actual" = "$indexed" ]; then
  echo "✅ RETRO index is consistent ($actual records)"
else
  echo "🔴 RETRO index mismatch: $actual files / $indexed index entries. Complete Docs/7-复盘/README.md immediately"
fi
```

## Legacy full-run template

```bash
cd "<project root>"

echo "🔍 State inference — $(date)"
echo "============================================"

echo "[Check 5] Previous session state"
[ -f 状态.md ] && head -30 状态.md || echo "  (No cached state)"
echo ""

echo "[Check 1] APK and smoke completion"
latest_apk=$(ls -t {{APP_REPO_DIR}}/apk/*.apk 2>/dev/null | head -1)
[ -n "$latest_apk" ] && stat -c "  Latest APK: %n (%y)" "$latest_apk"
echo "  Current requirements pending APK:"
grep -Eh "^\| F-[A-Z0-9-]+.*⏳" Docs/1-需求文档/Sprint-*需求清单.md | sed 's/^/    /'
echo ""

echo "[Check 3] RETRO triggers"
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-retro-cadence.ps1
echo ""

echo "[Check 4] ADR header versus index"
echo "  (See project health checks P4g/P4i)"
```
