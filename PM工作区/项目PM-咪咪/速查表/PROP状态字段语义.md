---
name: prop-status-semantics
description: 改 PROP 状态字段时核对完成定义。防 PM 自纠 #44 状态语义错位（pending/approved/in_progress/completed/rejected 边界）。
trigger: 改 PROP 状态字段时
loaded: 条件加载（按 trigger 匹配时由 PM 调度）
---

# 速查：PROP 状态字段语义边界（PM 自纠 #44）

> 改 PROP 状态字段前 — **核对完成定义**

## 铁律

```
PROP-XXX 状态字段：
  - 待审批             ← zlbdh 未 approve
  - 已审批 · 实施中    ← approve 但未 ship
  - 已审批 · 已完成    ⭐ 需满足全部 ship 条件（含 git push）
  - 已审批 · 已弃用    ← 中途方案错
  - 拒绝               ← review 直接 pass
```

## 「已完成」语义（铁律）

✅ 全部满足才能切：
1. 代码 ship（Claude Code）
2. 测试通过 / build OK / APK build
3. 真机 smoke 8/8（如 L3+）
4. **commit + push origin main**（Codex）
5. PROP 文件 mv `进行中/` → `已完成/`
6. `确认改动/README.md` 计数更新

⚠️ **代码完成 ≠ PROP 完成** — 必须等 Codex push 后才能切「已完成」

## 历史实证

### PM 自纠 #44（2026-05-14 PROP-021）

- PM 一开始把 PROP-021 状态切「已完成」过早
- 实际 Claude Code 代码 ship 完成 ≠ Codex push 完成（中间还有 v3.5.8 闭环）
- PM 自纠 revert 回「实施中」
- 等 Codex push `a1a8322` 后才真切「已完成」

## 防御措施

### 写 PROP 状态字段前 30 秒自检

1. **Codex push 完了吗**？git status / commit hash 实证
2. **README 计数更新了吗**？
3. **PROP 文件已 mv 已完成/吗**？
4. **真机 smoke 全过吗**（如适用）？

→ 全 ✅ 才切「已完成」

## 跟其他元规则关系

- [审批与归档.md](../../../操作系统/07_完整工作流/审批与归档.md) — PROP 状态机
- [实施循环.md](../../../操作系统/07_完整工作流/实施循环.md) — DoD
- decision-checkpoint Q4.c — PROP 状态字段语义边界候选
