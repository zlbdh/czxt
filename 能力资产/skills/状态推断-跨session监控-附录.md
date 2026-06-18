---
name: state-inference-cross-session-monitor-appendix
scope: project
type: reference
loaded: on-demand
description: 状态推断推断项 5-9 附录 — Bash/GNU fallback、旧环境命令模板与完整跑法示例。
---

# 状态推断 5-9 附录

主入口见 [`状态推断-跨session监控.md`](状态推断-跨session监控.md)。本附录保存旧环境 Bash/GNU fallback 和完整跑法示例；Windows/Codex 优先用项目 PowerShell 检查器。

## 推断 5 Bash 示例

```bash
latest_card=$(ls -t 交接区/待接手/*.md 2>/dev/null | head -1)
if [ -z "$latest_card" ]; then
  echo "✅ 无待接手卡"
else
  echo "📍 最新待接手卡：$latest_card"

  card_mtime=$(stat -c %Y "$latest_card" 2>/dev/null)
  latest_code_mtime=$(find {{APP_REPO_DIR}}/src -type f \( -name '*.jsx' -o -name '*.js' \) -printf '%T@\n' | sort -rn | head -1 | cut -d. -f1)
  diff_days=$(( (latest_code_mtime - card_mtime) / 86400 ))

  if [ "$diff_days" -ge 1 ]; then
    echo "🟡 最新交接卡 比代码改动旧 $diff_days 天 — 可能 stale"
  fi
fi

pending_count=$(ls 交接区/待接手/*.md 2>/dev/null | wc -l)
if [ "$pending_count" -gt 3 ]; then
  echo "⚠️ 待接手/ 有 $pending_count 张卡，可能积压"
fi
```

## 推断 6 Bash 示例

```bash
threshold=$(date -d '7 days ago' +%s)
for f in 确认改动/已审批/进行中/PROP-*.md; do
  [ -f "$f" ] || continue
  mtime=$(stat -c %Y "$f")
  if [ "$mtime" -lt "$threshold" ]; then
    days=$(( ($(date +%s) - mtime) / 86400 ))
    echo "⚠️ $(basename $f) 卡了 $days 天 — 要不要 mv 到 已弃用/ 或拆分？"
  fi
done
```

## 推断 7 Bash 示例

```bash
recent_changes="..."

echo "$recent_changes" | grep -qE "git push|git commit" && echo "⚠️ 触碰 git，复核 ADR-016 6 条件；如有新场景，升级 git流程.md"
echo "$recent_changes" | grep -qE "API key|token|隐私" && echo "⚠️ 触碰隐私，按安全与隐私规则补专项规范或 PROP/ADR"
```

## 推断 8 Bash 示例

```bash
matches=$(grep -ril "破例\|exception\|此次例外\|一次性放行" \
  交接区/已接手/ 交接区/待接手/ 状态.md 2>/dev/null)

git_count=$(echo "$matches" | xargs grep -l "git\|push\|commit" 2>/dev/null | wc -l)
version_count=$(echo "$matches" | xargs grep -l "version\|bump\|package.json" 2>/dev/null | wc -l)
other_count=$(echo "$matches" | wc -l)

[ "$git_count" -ge 2 ] && echo "🔴 破例计数器：git 类破例 $git_count 次 — 立刻开 PROP 治理（不等第 3 次）"
[ "$version_count" -ge 2 ] && echo "🔴 破例计数器：version 类破例 $version_count 次 — 立刻开 PROP"
[ "$other_count" -ge 2 ] && echo "🟡 破例总数 $other_count 次 — 分类核查同方向是否 ≥ 2"
```

## 推断 9 Bash 示例

```bash
actual=$(ls Docs/7-复盘/RETRO-*.md 2>/dev/null | wc -l)
indexed=$(grep -c "^| \[RETRO-" Docs/7-复盘/README.md 2>/dev/null || echo 0)

if [ "$actual" = "$indexed" ]; then
  echo "✅ RETRO 索引一致（$actual 个）"
else
  echo "🔴 RETRO 索引不一致：文件 $actual / 索引 $indexed — 立刻补全 Docs/7-复盘/README.md"
fi
```

## 完整跑法旧模板

```bash
cd "<项目根>"

echo "🔍 状态推断 — $(date)"
echo "============================================"

echo "【推断 5】上次 session 状态"
[ -f 状态.md ] && head -30 状态.md || echo "  (无缓存)"
echo ""

echo "【推断 1】APK + smoke 是否完成"
latest_apk=$(ls -t {{APP_REPO_DIR}}/apk/*.apk 2>/dev/null | head -1)
[ -n "$latest_apk" ] && stat -c "  最新 APK: %n (%y)" "$latest_apk"
echo "  当前需求清单 ⏳ 待 APK："
grep -Eh "^\| F-[A-Z0-9-]+.*⏳" Docs/1-需求文档/Sprint-*需求清单.md | sed 's/^/    /'
echo ""

echo "【推断 3】RETRO 触发"
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-retro-cadence.ps1
echo ""

echo "【推断 4】ADR 头部 vs 索引表"
echo "  （详见 项目体检 P4g/P4i）"
```
