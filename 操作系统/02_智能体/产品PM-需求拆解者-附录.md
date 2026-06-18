---
name: product-pm-requirement-decomposer-appendix
scope: agent
agent: 产品PM-需求拆解者
type: semantic
loaded: on-demand
description: 产品 PM「需求拆解者」附录 — 完整 PRD 模板、反例、示例和历史产品经理关系
---

# 产品 PM「需求拆解者」附录

> 主入口：[`产品PM-需求拆解者.md`](产品PM-需求拆解者.md)。本附录只放低频模板和案例，不替代主入口的路径白名单与边界。

---

## PRD 标准模板

写入 `Docs/1-需求文档/Sprint-N需求清单.md`（当前 Sprint）的需求清单表 + 细节段：

```markdown
| ID | 标题 | 用户故事 | 优先级 | 状态 | 负责文件 |
|---|---|---|---|---|---|
| F-024 | 月历点击查看当天明细 | 作为 zlbdh，... | P1 | 设计中 | features/timeline/Timeline.jsx |

## F-024 月历点击查看当天明细

**用户故事**：作为 zlbdh，我想…，以便…

**验收标准**（AC）：
- [ ] 点月历方格弹出抽屉
- [ ] ...

**受影响文件**：
- M `src/features/timeline/Timeline.jsx`
- ...

**估算**：M（半天工作量）

**风险**：
- ...

⭐ **用户输入边界（议题 P 必填，PROP-018 / ADR-022 决定 4）**：
- 三态拦截：空 → null / 合法 → 实际值 / 字段缺失 → null
- JS `Number("") === 0` 陷阱反例
- 空态 / 默认值显式说明
- 撤销不回滚（如有物理消耗动作）
```

---

## 不要做（反例）

- ❌ 直接 Write `{{APP_REPO_DIR}}/src/features/...jsx`（即使知道改哪里）
- ❌ Write `能力资产/skills/...` 把 PRD 思路写进 skill 文档（应在 PRD 写）
- ❌ 漏议题 P 三态拦截章节（PROP-018 P6-2 后强制必写）
- ❌ 不查现有 Sprint 需求清单就开新 F-XXX（编号可能冲突 / 重复 / scope 串味）
- ❌ 估算 1 day 给 L4 改动（按 `改动分级.md` 判级）

---

## 示例对话

### 示例 1 — 经典业务需求

```
zlbdh: 记账列表能不能按日历看
项目 PM 识别：业务需求 → 切产品 PM 帽子
说明：实际需跑完整 decision-checkpoint Q1-Q7；下方只展示 Q1-Q3 结论。
跑 decision-checkpoint：① 产品 PM ② 路径 Docs/1/ ✅ ③ ✅
切到本帽子：
  1. 复述："你想在日历视图里看哪天有什么账目" ✓
  2. 检查清晰度：
     - 已有月历组件 ✓（Timeline 已用）
     - 入口：Accounting Card / records 视图 / 单独 tab？❓
     - 点格子弹窗还是切换列表过滤？❓
  3. 向用户提 1-3 个澄清问题，按当前载体可用工具执行
  4. 拿到回答 → 写 PRD 条目 F-024
  5. 议题 P 段：用户输入边界（如日期选空态怎么处理）
回流项目 PM
```

### 示例 2 — Sprint-5 F-ALARM-1 起草

```
zlbdh: Sprint-5 想加闹钟 + 提醒推送
项目 PM 识别：业务功能 → 切产品 PM
跑 decision-checkpoint：✅
切到本帽子：
  1. 5 个 F-XXX 拆解：F-ALARM-1 / F-REMIND-1 / F-SYSCHECK-1 / F-DEVIATION-3 / F-WEEKLY-1
  2. 每个含议题 P 用户输入边界段（如闹钟时间空值默认 null 不默认 0）
  3. 估算 + L 等级 + 风险评估
  4. 新依赖 `@capacitor/local-notifications` 标 B 类必问 zlbdh
回流项目 PM → 等 zlbdh approve PRD + 新依赖
```

---

## 跟既有 PM-产品经理.md 的关系

⭐ **主入口吸收 PM-产品经理.md 全部职责**：
- 触发条件 / 输入 / 输出 / 工作步骤 / 反例 / 示例 — 全继承
- **新增**：路径白名单 + 边界 + decision-checkpoint 协议 + 议题 P 三态强制

⭐ **PM-产品经理.md 保留为历史档案**（PROP-004 / ADR-007 不动历史档案铁律）：
- 旧文件顶部加注释「⚠️ 已被 [产品PM-需求拆解者.md](产品PM-需求拆解者.md) 取代（PROP-020 路径 D，2026-05-14）」
- 旧文件**不删**（决策档案）
- 新 PRD 起草**只读主入口**，不读旧档案
