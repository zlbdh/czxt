# ADR-014 · 习惯补签字段不升 Dexie 版本

- **状态**：现行
- **日期**：2026-05-11
- **决策人**：zlbdh / 咪咪
- **关联**：F-006

## 背景

F-006 需要区分「当天正常打卡」和「事后补签」，UI 上用 `⏪` 标记补签日期。现有 `habits` 表只有 `checkIns` 日期数组，不能表达某个已打卡日期是否为补签。

候选方案：
- A. 给 `habits` 增加嵌套字段 `backfilledDates: string[]`，不建索引，不升 Dexie 版本
- B. Dexie v2 -> v3，给 `habits` 增加索引字段
- C. 新建独立 `habitBackfills` 表

F-006 只在单个习惯对象内读写补签状态，不需要按补签日期跨表查询。B/C 会引入 schema 迁移和更多表关系，超出当前收益。

## 决定

采用 A：在 `habit` 对象内追加非索引字段 `backfilledDates: string[]`，不修改 `db.version(2).stores(...)`，因此不升 Dexie v3。

边界：
- 新建默认习惯时写入 `backfilledDates: []`
- 旧数据允许没有该字段，业务逻辑按空数组兼容
- 只有 `backfillHabit` 写这个字段；当天 `toggleHabit` 仍只写 `checkIns`
- 若未来需要「所有补签记录列表 / 按日期统计补签」再考虑 v3 或独立表

## 后果

### 好处
- 不触发 IndexedDB schema 迁移，降低真机存量数据风险
- F-006 代码面小，读写仍围绕单个 habit 对象
- 旧习惯数据天然兼容，纯函数已覆盖缺省字段场景

### 代价
- `backfilledDates` 不能被 IndexedDB 直接索引查询
- 数据契约由代码和文档保证，不由 Dexie schema 字符串强约束
- 以后如果要跨习惯统计补签，需要补一次 schema / 数据迁移决策

### 后续如果反悔了
- 若需要查询性能或独立审计记录，新建 ADR-015，升 Dexie v3 或拆 `habitBackfills` 表
- 迁移方式：遍历 `habits`，把 `backfilledDates` 展开为新表记录或索引字段

## 实施记录

- `{{APP_REPO_DIR}}/src/shared/database.js`：`createDefaultHabits()` 加 `backfilledDates: []`
- `{{APP_REPO_DIR}}/src/shared/habitBackfill.js`：旧数据缺省字段按空数组处理
- `Docs/3-开发文档/数据库schema.md`：同步记录非索引字段语义
