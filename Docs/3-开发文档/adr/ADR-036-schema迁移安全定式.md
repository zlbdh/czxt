# ADR-036 · schema 迁移安全定式（新表 4 处改 checklist + 真机零丢失 smoke）

- **状态**：现行
- **日期**：2026-06-09
- **决策人**：zlbdh approve / 沉淀 PM 起草（PROP-043）
- **关联**：RETRO-020（E 重量曲线 v15 + M 偏离记录 v16 两把 schema 刀）/ 元规则 DS / 承 ADR-014（习惯补签不升版本）

## 背景

项目曾约 28 刀靠 schema-less（profile spread / 复用现表）刻意避开 Dexie 版本升级。E 重量曲线（v3.41，IndexedDB v140→v150）首次有意打破，M 偏离记录（v3.42，v150→v160）第二把。两把刀真机验证了一套安全升级定式 + 一个高危陷阱（exportAllData 漏加新表 = 用户备份丢数据 = C 类红线相邻）。需固化为「以后所有 schema bump 必走的 checklist」。

## 决定

- **DS schema 迁移安全定式**：新增 Dexie 表（schema bump）必须四处改齐 + 一处真机验，缺一不可：
  1. `schema.js`：`V_N_STORES = {...V_{N-1}_STORES, newTable}` + `db.version(N).stores()`，🔴 **无 .upgrade() 回调**（纯新空表，Dexie 增量升级只建空表不碰老表 = 零丢失）；绝不改老表 store 定义。
  2. `snapshot.js · exportAllData`：tables 数组 **必加新表名**（漏 = 备份不含 = 导出后导入丢数据 / C 类红线相邻）。
  3. `snapshot.js · loadSnapshot`：`db.newTable?.toArray().catch(()=>[]) || []` 容错读（旧库无表→空数组）。
  4. `useAppData.js`：initial state 加 `newTable: []`（setData 兜底）。
  5. 🔴 **真机零丢失 smoke**：装旧版→造数据→覆盖装新版→逐项核老表数据全在 + IndexedDB version 升对。
- 适用边界：纯新增表用本定式；**若需改老表结构/数据迁移（带 .upgrade()）→ 风险骤升，必须停下专门设计 + ultracode 审**（不在本定式快速通道内）。

## 后果

### 好处
- schema bump 从「高风险动作」变为「照 checklist 走的安全操作」，两把刀真机零丢失实证。
- 解除 schema-less 的自我设限，daysLeft/月报等需数据基建的功能可放心做。

### 代价
- 每次 bump 多 4 处改 + 1 次真机升级 smoke（比 schema-less 重）。
- 仍需 ultracode 审（与 ADR-037 叠加）。

### 后续如果反悔了
- 不可逆性高（用户数据已按新 schema 落地），翻案需数据迁移。故 bump 前必须确认必要性（能 schema-less 则优先 schema-less，承 ADR-014 精神）。

---

## 备注
与 ADR-014（习惯补签字段不升 Dexie 版本）不矛盾：ADR-014 说「能不升就不升」，ADR-036 说「确需升时怎么安全升」。两者共同构成 Dexie 版本治理。
