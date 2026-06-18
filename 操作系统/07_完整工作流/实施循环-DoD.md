---
name: implementation-loop-dod
scope: project
type: procedural
loaded: on-demand
description: 「一个改动算做完了」的 DoD 检查清单（L1-L4）+ 跨 session 同步包 + 失败回退
---

# 实施循环 — Definition of Done

> 主文件见 [`实施循环.md`](实施循环.md)。本文件存放 L1-L4 DoD、跨 session 同步包和失败回退。

不同等级有不同完成标准。L3/L4 用完整版，L1/L2 按需简化；未勾完前 task 保持 in_progress。

## L3 / L4 完整清单

> ⭐ **核心 6 项（必勾）** — 漏一项 = 未完成
> - [ ] **decision-checkpoint** Q1-Q7 已跑过，含 Q7 agent 实例化判定
> - [ ] **代码** 按 PRD 实现，无 TODO 残留
> - [ ] **测试** vitest + esbuild + vite build 三层全过
> - [ ] **PRD** 状态从「实施中」→「已完成」+ 需求历史加条目
> - [ ] **PROP 收档** 状态字段切「已完成」+ mv 进行中→已完成 + README 计数更新
> - [ ] **对账 skill** [项目体检](../../能力资产/skills/项目体检.md) + [状态推断](../../能力资产/skills/状态推断.md) 全过
>
> 下面是**扩展项**（按需补，不是每次必勾）：

**代码（扩展）**
- [ ] 按 PRD 全部实现，无 TODO 残留
- [ ] 不留 `console.log` / `debugger` / 测试时的 hardcode
- [ ] `wc -lc` + `tail -3` 验证文件没被 mount 截断

**测试（3 层 — 扩展）**
- [ ] esbuild 语法 OK（0 fail）
- [ ] vitest 全过（含新加测试；既有测试不破）
- [ ] vite build 成功（warnings 可忍，errors 必须 0）
- [ ] smoke test 5 个 tab 都正常
- [ ] **端能力对照**：哪些测试在哪端跑（见 [`实施循环-附录.md`](实施循环-附录.md)）

**文档**
- [ ] PRD 条目状态从「实施中」→「已完成」
- [ ] `Docs/1-需求文档/需求历史.md` 加新版本条目
- [ ] `Docs/3-开发文档/` 相关章节同步（如改 schema 必更新 `数据库schema.md`）
- [ ] L4 必须已写 ADR 到 `Docs/3-开发文档/adr/`

**PROP 收档（L3/L4 必做，避免 PROP 卡在「进行中/」）**
- [ ] PROP 文件头状态改为：`已审批 · 已完成（YYYY-MM-DD 实施完毕，对应 ADR-XXX）`
- [ ] 把 PROP 文件从 `确认改动/已审批/进行中/` mv 到 `确认改动/已审批/已完成/`
- [ ] 更新 `确认改动/README.md` 的「当前」清单（计数 + 进行中/已完成 列表）

**PRD 双源一致性**
- [ ] PRD 若有"表格 + 子段标题"双层结构，两处状态必须一致
- [ ] 「已完成」段落不得含「待 / TBD / ⏳ / 待 APK / 待 smoke」；若 APK 真没出，Sprint 顶部状态列标 ⏳ 而非 ✅

**项目体检**
- [ ] 跑 [`项目体检.md`](../../能力资产/skills/项目体检.md) 9 项检查全过
- [ ] 报告 ✅ / 🟡 / 🔴 三色，🔴 必须先解决再标 task completed

**状态推断对账（跨 session 自动化保护）**
- [ ] 跑 [`状态推断.md`](../../能力资产/skills/状态推断.md) 10 项推断
- [ ] 看 APK / 代码改动 / RETRO 触发 / ADR 一致性 / 跨 session 状态
- [ ] 任何「应该切换但未切」的状态字段 → 用户确认后，按对应 PM 路径白名单、状态规则和留痕要求更新

**APK**
- [ ] dev APK 已出（zlbdh Windows 或 GitHub Actions）
- [ ] APK 拷到 `{{APP_REPO_DIR}}/apk/{{PROJECT_NAME}}-vX.Y.Z-debug.apk`，命名按交接卡当前规则（格式：`{{PROJECT_NAME}}-vX.Y.Z-debug.apk`）
- [ ] zlbdh 已装机跑过 smoke test 单子（`Docs/4-测试文档/手动测试用例.md`）

**收尾**
- [ ] task 状态 = completed
- [ ] 顶层 README.md 如有用户感知改动 → 更新
- [ ] 给 zlbdh 汇报：「做了啥 / 测试结果 / APK 路径」；实施收尾仍按 chat ①-⑦ 输出
- [ ] 如本批改动是第 N 个 L3+，触发一次复盘（写 `Docs/7-复盘/RETRO-XXX.md`）

## L2 简化清单

- [ ] 代码改完
- [ ] vitest 全过
- [ ] 需求历史或对应变更记录加一行
- [ ] `Docs/3-开发文档/` 受影响章节同步
- [ ] task = completed
- [ ] 若涉及文件改动、跨角色或跨 session，仍按交接卡矩阵写完整卡 + chat ①-⑦ + `状态.md L<line>`

## L1 简化清单

- [ ] 代码改完
- [ ] 需求历史或对应变更记录加一行（同一批 L1 可合并："修了 X / Y / Z 三个 typo"）
- [ ] task = completed
- [ ] 若是实施收尾，不用“一句话汇报”替代 chat ①-⑦

## 跨 session 同步包 / 交接卡

⭐ 完整模板见 [`交接卡格式.md`](../03_交接/交接卡格式.md)。  
⭐ 写入位置：`交接区/待接手/YYYY-MM-DD-HHMM-任务-从到.md`；从到优先写 PM 职责角色，工具名只作执行载体补充。

三层结构速记：
1. **`交接区/待接手/...md`** — 完整独立文件，基础 ①-⑥；涉及 framework / PM 轨迹时追加文件 ⑦
2. **`状态.md` 顶部摘要段** — 极简 + 链接到上面那张
3. **简版交接卡文本** — 给 zlbdh 一键 copy 到另一端 session 用

→ 实施完成必做（详见 [`交接区/README.md`](../../交接区/README.md)）：
  ① mv 自己之前接的卡到 `交接区/已接手/`
  ② 写新卡到 `交接区/待接手/`
  ③ 更新 `状态.md` 顶部摘要段
  ④ 给 zlbdh chat 简版 ①-⑦ 交接卡

→ 下个 session 起手读 `状态.md` 摘要 + `交接区/待接手/` 最新文件（见 [`状态推断-跨session监控.md`](../../能力资产/skills/状态推断-跨session监控.md) 推断 5）。
→ 旧格式向后兼容，但**新写一律走交接区**，并至少包含文件基础 ①-⑥。

## 失败回退

如果某一项没法勾完（比如 APK 出不了、smoke test 失败）：
1. 把当前进度写到 PROP（`确认改动/待审批/`），描述卡在哪
2. task 状态保持 in_progress
3. 若跨 session，写 `交接区/待接手/` 卡并发 chat ①-⑦
4. 让 zlbdh review 后决定是修复继续 / 回滚 / 改方案
