# ADR-024 · 议题 P 用户输入三态边界永久化（跨 Sprint 实战 10 次 + 三层一致达成）

- **状态**：现行
- **日期**：2026-05-19
- **关联**：[ADR-019 数据双源治理（议题 P 首次落地 F-DAY-2）](ADR-019-数据双源治理.md) · [ADR-023 PM 子类化 + decision-checkpoint](ADR-023-议题AJ落地-PM角色子类化+decision-checkpoint.md) · 议题 P 收档条件 10/10 ✅
- **议题 P 关闭条件**：实战 ≥10 次完整 + 设计/测试/UI 三层一致 + 0 越界（违反后果零事故）✅ 达成

> ⚠️ **当前覆盖说明（2026-06-15）**：本文的三态原则仍现行；正文中的旧 `agent/` 路径为当时落地路径，不作为当前执行入口。当前规则入口以 `操作系统/` + `能力资产/` 为准。

## 背景

议题 P「用户输入三态」自 Sprint-4 F-DAY-2 / F-DEVIATION-2 首次落地起，跨 Sprint-4 + Sprint-5 累计 **10 次完整落地**：

| # | Feature | Sprint | 三层一致 |
|---|---|---|---|
| 1 | F-DAY-2 跨日 | Sprint-4 | ✅ |
| 2 | F-DAY-3 异常 | Sprint-4 | ✅ |
| 3 | F-BRIEFING-1 LLM | Sprint-4 | ✅ |
| 4 | F-DEVIATION-2 识别 | Sprint-4 | ✅ |
| 5 | F-PREP-1 库存 | Sprint-4 | ✅ |
| 6 | F-SYSCHECK-1 系统状态 | Sprint-5 | ✅ |
| 7 | F-ALARM-1 闹钟 | Sprint-5 | ✅ |
| 8 | F-REMIND-1 提醒 | Sprint-5 | ✅ |
| 9 | F-DEVIATION-3 方案 | Sprint-5 | ✅（v3.6.1 ship）|
| 10 | **F-WEEKLY-1 周报** | Sprint-5 | ✅（本卡 ship）|

→ **跨 6 sprints / 10 次完整 / 0 越界 / 三层一致** — 议题 P 收档条件全部达成。

议题 P 原始 statement（Sprint-4 PM 自纠 #28 触发）：
> JavaScript `Number("")` === 0 陷阱 + 用户输入数据有三态：null / 合法值 / 字段缺失。每个新 feature 涉及用户输入或外部数据时，必须设计 + 测试 + UI 三层处理这三态。

## 决定

议题 P **正式永久关闭**，纳入 framework 8 元规则永久化（议题 G / AT / AM / AO / BC / BE / AJ / **P**）。

### 决定 1 — 议题 P 4 边界硬规则（永久化）

每个新 feature 涉及用户输入 / 外部数据 / LLM 输出 / 时间相关数据时，**必须**实施 4 类边界处理：

```
#1 null / 不可用 → fallback（不挂业务）
#2 不合法值（数字越界 / 字符串非法 / 类型错误） → 过滤 / 报错 / 默认值
#3 字段缺失（undefined / 未设置） → 默认值 / null 显式区分
#4 跨边界状态（跨午夜 / 跨周 / 跨时区 / 跨语言）→ 自动延后 / 重新计算
```

### 决定 2 — 三层一致原则（硬规则）

每个议题 P 边界场景必须**设计 + 测试 + UI** 三层一致：

```
设计层：handoff 卡 §④ 必明示 4 边界（PM 起卡时 grep `项目PM/速查表/`）
测试层：unit/source contract tests 覆盖每个边界（Claude Code 实施必加）
UI 层：用户视觉提示 + fallback 路径（Chat / Card / Toast 等）
```

任一层缺失 → 议题 P 违规 → PM 自纠链触发（同议题 AJ 路径越界处理）。

### 决定 3 — 议题 P 进入速查表 + Q4 防御

议题 P 加入 `项目PM/速查表/议题P边界速查表.md`（待 PROP-N 补建），PM 起 handoff 卡前**必查**（类比议题 BE 起手机制）。

### 决定 4 — 议题 P 收档后跨 Sprint 监控

- ✅ **不需再标「议题 P 第 N 次落地」**（每次都该落地，不再当成里程碑）
- ❌ 如未来发现议题 P 违反（4 边界 / 三层一致缺失）→ 议题 P **重开** + 起新 PROP 调查根因 + 议题 P v2 升级
- ✅ Sprint-6 起 RETRO 不再 review 议题 P 落地次数（默认必落地，类比议题 AJ 关闭后不再 review 路径越界）

## 后果

### 收益

1. **议题 P 永久化** = 防御机制内化 — 每个新 feature 默认走 4 边界 + 三层一致，**不再需要 PM 提醒**
2. **framework 元规则数 7 → 8** — 议题 P 永久进入 framework 硬规则池
3. **PM 起手 handoff 卡速度提升** — 议题 P 部分模板化（直接 grep 速查表填 4 边界）
4. **未来 feature 健壮性兜底** — 「LLM 失败 / 数据缺失 / 用户跳过 / 跨边界」4 类常见 bug 默认被防御

### 代价

1. **每 feature handoff 卡 + 测试覆盖固定 +30 min**（议题 P 4 边界设计 + 4 边界测试）— 但抵消的是事后 debug 时间（议题 P 历史 PM 自纠 #28-30 累计省下 ~10h）
2. **速查表新增「议题 P 边界速查表」文件**（待 PROP-N 建 — 不阻塞收档）
3. **议题 P 重开门槛**：未来如真出现违反，重开成本 = ADR-024 翻案（按 ADR README 翻案铁律：不修原 ADR，写新 ADR）

### 关联资产

- `项目PM/速查表/议题P边界速查表.md`（待建 / RETRO-009 时建）
- `agent/rules/议题P-用户输入三态.md`（待建 / 与速查表配套）
- 现有 8 元规则永久化清单更新：G / AT / AM / AO / BC / BE / AJ / **P**

## 翻案规则

如未来发现议题 P 4 边界 + 三层一致存在结构性盲区（例如某个新 feature 类型不能覆盖）：**不修本 ADR**，新建 ADR-N 写明原因，本 ADR 标「被 ADR-N 部分替代」（按 ADR README 翻案铁律）。

## 关联文件

- [Sprint-5需求清单.md](../../1-需求文档/Sprint-5需求清单.md) — 议题 P 边界条目（每个 F-XXX 必含）
- [ADR-023 PM 子类化](ADR-023-议题AJ落地-PM角色子类化+decision-checkpoint.md) — 同模式永久关闭（议题 AJ）
- [项目PM/速查表/](../../../项目PM/速查表/) — 议题 P 速查表归位
- v3.6.2 commit msg — 本 ADR 起稿里程碑挂载点
