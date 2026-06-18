---
name: handoff-spec-index
scope: project
type: semantic
loaded: on-demand
description: 跨 PM 角色交接卡格式规范入口
---
# 03_交接 · 跨 PM 角色协作层

> 项目 PM / 操作系统 PM / 产品 PM / 技术 PM / 测试 PM / 开发 PM / 测试发布 PM 等职责角色之间的交接层。Cowork / Claude Code / Codex 只是执行载体，正文可注明但不作为新卡主体。

| 文件 | 内容 |
|---|---|
| [交接卡格式.md](交接卡格式.md) | 高频执行入口：完整文件基础 ①-⑥ + 可选文件 ⑦ + chat 简版 ①-⑦ |
| [交接卡格式-附录.md](交接卡格式-附录.md) | 低频解释：历史触发、失败案例、强制矩阵、自动对齐为何不静默改写 |

## 实际交接卡位置
- `交接区/待接手/` — 当前 in-flight 卡
- `交接区/已接手/` — 已接收 / 已完成暂存
- `交接区/历史归档/yyyy-mm/` — 长期历史归档

## 议题防御
- PROP-014 三阶判定（chat 简版 ①-⑦ 强制结构）
- PROP-029 v2 / O-1：⑤ 警戒段强制 `Status: <STATE>` 字段（5 态）
- 2026-06-15 守卫增强：`handoff-zone-check` 对待接手卡按 `## ①`→`## ⑥` 标题顺序和 `DONE / BLOCKED / HANDOFF / RISK / OBSERVE` 枚举校验；已接手超期优先按文件名日期判断。

## 维护
- 责任：项目 PM 编排者
