---
name: database-schema
scope: project
type: semantic
loaded: on-demand
description: Dexie 数据库 schema 索引；当前版本以 {{APP_REPO_DIR}}/src/shared/database/schema.js 为单一真源
---

# 数据库 Schema

数据库：`{{PROJECT_SLUG}}-db-v1`（Dexie / IndexedDB）
**当前 schema 版本：v16**（M 偏离记录第一刀；真源：[`../../{{APP_REPO_DIR}}/src/shared/database/schema.js`](../../{{APP_REPO_DIR}}/src/shared/database/schema.js)）

> 本文用于开发速查，不替代代码真源。若本文与 `schema.js` / `migrations.js` 冲突，以代码为准。
> 下方 v1-v5 展开是基础结构；v6-v16 当前增量先看本节速查。

## 当前版本速查

| Dexie 版本 | 变更 | 迁移/数据安全口径 |
|---|---|---|
| v1 | 基础 12 表 + `meta` | 初始 schema |
| v2 | `chatMessages.archived` 索引 | `upgradeV2` |
| v3 | `userProfile` 单例表 | 新表 |
| v4 | `profiles` → `userProfile` 数据合并 | `upgradeV4`，`profiles` 保留兼容 |
| v5 | `inventory` 常备库存表 | `upgradeV5` |
| v6 | `inventory.taskBinding` 字段 | `upgradeV6`，无新索引 |
| v7 | `alarms` 闹钟表 | `upgradeV7` |
| v8 | `alarms.kind` 索引 | `upgradeV8` |
| v9 | `userProfile` 习惯偏好字段 | `upgradeV9`，无新索引 |
| v10 | `trainingExercises` 训练动作表 | 新表 |
| v11 | `userProfile.nightProtectionEnabled` | 无新索引 |
| v12 | `smoking` → `smokeHabit` | `upgradeV12` |
| v13 | `calendarEvents` 事件表 | 新空表，0 数据丢失 |
| v14 | `shoppingList` 采购清单表 | 新空表，0 数据丢失 |
| v15 | `weightLogs` 单动作重量记录表 | 新空表，0 数据丢失 |
| v16 | `deviationLogs` 偏离记录表 | 新空表，0 数据丢失 |

## 19 张业务表 + meta

```js
// v1（项目首版）
db.version(1).stores({
  profiles:        'id',                    // 个人档案
  dailyTasks:      'id,date',               // 每日打卡（id = "yyyy-mm-dd-taskId"）
  habits:          'id,createdAt',          // 习惯模板 + checkIns + backfilledDates
  weightRecords:   'id,date',               // 体重记录
  mealRecords:     'id,date,mealType',      // 餐食 + AI 分析
  exerciseRecords: 'id,date',               // 训练
  ledgerEntries:   'id,date,type,bookId',   // 账目
  ledgerBooks:     'id',                    // 账本（默认 main）
  moments:         'id,createdAt,type,starred', // 时光碎片
  chatMessages:    'id,createdAt',          // 聊天历史
  deviceEvents:    'id,createdAt,type',     // BLE 设备事件
  meta:            'key',                   // 元数据
});

// v2（F-203 / ADR-005，2026-05-09）：chatMessages 加 archived 索引
db.version(2).stores({
  ...V1_STORES,
  chatMessages: 'id,createdAt,archived',    // archived: 0|1
}).upgrade(tx => tx.table('chatMessages').toCollection().modify(m => {
  if (m.archived === undefined) m.archived = 0;
}));

// v3（Sprint-2 / F-PROFILE-1）：userProfile 单例表
db.version(3).stores({
  ...V2_STORES,
  userProfile: 'id',                        // id = 1
});

// v4（PROP-015 / ADR-019）：profiles → userProfile 数据合并
db.version(4).stores(V4_STORES).upgrade(async tx => {
  // 旧 profiles.main 只填 userProfile 空字段；profiles 表保留用于回滚与备份兼容
});

// v5（F-PREP-1）：inventory 常备库存表
db.version(5).stores({
  ...V4_STORES,
  inventory: 'id,name,updatedAt',           // 用户常备物品，低库存触发「该买」
});
```

## 各表字段

### userProfile
```ts
{
  id: 1,                    // 单例
  height: number | null,    // cm
  weight: number | null,    // kg
  bodyFat: number | null,   // %
  age: number | null,
  gender: string | null,
  bodyType: string | null,
  workdayMorningStart: '09:00' | null,
  workdayMorningEnd: '12:00' | null,
  workdayAfternoonStart: '14:00' | null,
  workdayAfternoonEnd: '18:00' | null,
  commuteType: string | null,
  commuteDuration: number | null,     // 分钟
  lunchTime: string | null,
  lunchLocation: string | null,
  napHabit: string | null,
  napDuration: number | null,
  napLocation: string | null,
  mealTimes: { breakfast: string | null, lunch: string | null, dinner: string | null },
  coffee: string | null,
  tea: string | null,
  milkTea: string | null,
  energyDrink: string | null,
  cola: string | null,
  smoking: string | null,
  mainGoal: string | null,
  focusAreas: string[],
  assistantMode: 'strict' | 'neutral' | 'friendly',
  anomalyToleranceThreshold: number | null, // F-DAY-3：1-7，null 走默认 3
}
```

### profiles
```ts
{
  id: 'main',           // 唯一
  age: 25,
  height: 175,          // cm
  weight: 68.5,         // kg
  bodyFat: 18,          // %
  goal: 'recomp' | 'cut' | 'bulk',
  activity: 'sedentary' | 'light' | 'moderate' | 'active',
  notes: string,        // 备注
}
```

说明：`profiles` 是 v1-v3 旧表；PROP-015 / v4 已把旧数据合并到 `userProfile`，表仍保留用于回滚、备份导入兼容与历史数据保护。

### dailyTasks
```ts
{
  id: '2026-05-07-water',  // date-taskId 复合主键
  date: '2026-05-07',
  taskId: 'water',         // water / stretch / sk-am / breakfast / ...
  status: 'done' | 'skip',
  createdAt: ISO 字符串,
}
```

### habits
```ts
{
  id: 'habit-1',
  title: '早睡',
  note: '给明天留一点精神',
  category: 'health' | 'life' | 'mind' | 'study',
  color: '#8a5a3c',
  checkIns: ['2026-05-07', '2026-05-06', ...],  // 已打卡日期数组
  backfilledDates: ['2026-05-06', ...],          // F-006：补签日期数组，非索引字段；旧数据可缺省为 []
  createdAt: '2026-05-06',
}
```

### weightRecords
```ts
{
  id: 'weight-XXX',
  date: '2026-05-07',
  weight: 68.5,
  bodyFat: 18,           // 可选
  source: 'manual' | 'ble-scale-mock',
  createdAt: ISO,
}
```

### mealRecords
```ts
{
  id: 'meal-XXX',
  date: '2026-05-07',
  mealType: '早餐' | '午餐' | '晚餐' | '加餐',
  title: '燕麦 + 鸡蛋',
  calories: 400,
  protein: 30,
  image: 'data:image/jpeg;base64,...',  // 拍的照片
  aiAnalysis: { score, identified, ... },  // AI 返回的 JSON
  createdAt: ISO,
}
```

### exerciseRecords
```ts
{
  id: 'exercise-XXX',
  date: '2026-05-07',
  type: '上肢线条',
  minutes: 40,
  calories: 200,
  completed: true,
  createdAt: ISO,
}
```

### ledgerEntries
```ts
{
  id: 'ledger-XXX',
  bookId: 'main',
  date: '2026-05-07',
  type: 'expense' | 'income',
  title: '午餐',
  amount: 35,
  category: '餐饮',  // 餐饮/交通/购物/健康/学习/娱乐/居家/日常/收入
  source: 'local' | 'ai' | 'ble-terminal-mock',
  note: '原始输入',
  createdAt: ISO,
}
```

### ledgerBooks
```ts
{
  id: 'main',
  name: '主账本',
  createdAt: ISO,
}
```

### moments
```ts
{
  id: 'moment-XXX',
  type: 'text' | 'image' | 'video' | 'link' | 'music',
  title: string,
  content: string,
  url: string,           // video/link/music 用
  platform: '微信视频号' | '抖音' | 'B站' | '小红书' | '其他' | '',
  tags: ['标签 1', '标签 2'],
  mood: 'calm' | 'happy' | 'tired' | 'spark',
  image: 'data:image/jpeg;base64,...',
  starred: boolean,
  date: '2026-05-07',
  createdAt: ISO,
}
```

### chatMessages
```ts
{
  id: 'chatMessages-XXX',
  role: 'user' | 'assistant',
  content: string,
  createdAt: ISO,
  archived: 0 | 1,        // ★ v2 / F-203：0 = 活跃（首页可见），1 = 归档（仅 Profile 抽屉 + 备份可见）
}
```

**归档规则**（实现见 `useAppData.js > addChatMessage`）：
- 每次新消息入库后，count 当前 `archived !== 1` 的总数
- 若 > 30，把最老的 `(N - 30)` 条标 archived = 1
- 已归档不再处理，备份导出（exportAllData）含归档全量
- 抽屉入口：「我」页「过往的话」Card，组件 `ChatHistoryDrawer.jsx`

### deviceEvents
```ts
{
  id: 'event-XXX',
  type: 'scale' | 'accounting-terminal' | 'error',
  raw: any,              // 设备事件用：原始 BLE 包；error 事件：null
  parsed: any,           // 设备事件用：解析后的记录；error 事件：null
  payload: any,          // ★ F-205 加：error 事件用此字段，结构见下
  status: 'mocked' | 'real' | 'failed' | 'caught',
  createdAt: ISO,
}
```

**error 事件的 payload 结构**（F-205 加，不动表 schema 仅约定字段）：
```ts
payload: {
  tab: 'home' | 'health' | 'accounting' | 'timeline' | 'profile' | 'unknown',
  message: string,        // error.message
  stack: string,          // error.stack
  componentStack: string, // React errorInfo.componentStack
  url: string,            // location.hash
  ts: ISO,                // 抓到的时间
}
```

### inventory
```ts
{
  id: 'inventory-XXX',
  name: '鸡蛋',
  icon: '🥚',
  unit: '个',
  thresholdType: 'count' | 'decimal',
  quantity: 10,          // 当前余量；count 类整数步进，decimal 类 0.05 步进
  threshold: 5,          // count 默认 5，decimal 默认 0.2；显式 0 合法
  source: 'preset' | 'custom',
  createdAt: ISO,
  updatedAt: ISO,
}
```

**低库存规则**（实现见 `inventoryMonitor.js`）：
- `quantity <= threshold` 进入低库存清单。
- 默认阈值：`count → 5`，`decimal → 0.2`。
- `threshold` 的 `'' | null | undefined` 走默认值；显式 `0` 保留为 0。
- `dailyBriefing` 的 warnings 段会聚合为 `🛒 该买的：...`。
- 备份导出 / 导入含 `inventory`；旧备份缺失该表时按空数组兜底。

### meta
```ts
{
  key: 'legacy-migrated' | 'legacy-hydration' | 'legacy-completed-dates' | ...,
  value: any,
  at: ISO,
}
```

## localStorage（不在 Dexie 里的）

```
profile-v1            v1 老 profile（保留迁移用）
app-state-v3          v1 老 app-state（保留迁移用）
chat-history          v1 老 chat（保留迁移用）
briefing-v1           今日 AI 简报缓存（每天 1 条）
llm-config-v1         AI 设置（API key + baseUrl + model）
api-setup-skipped     旧版引导跳过标记
main-budget           记账月预算
```

## v1 → v2 迁移逻辑

第一次启动 APP 会跑：
1. `migrateLegacyOnce()` 检查 `meta.legacy-migrated`
2. 没标记过 → 读旧 `localStorage` → 入 Dexie
3. 打 `legacy-migrated: true`，下次跳过

代码在 `src/shared/database.js`。

## 加新表怎么改

1. `database.js` schema 加字段
2. **bump version**：`db.version(2).stores({...})`
3. 写 upgrade 函数处理老数据
4. `useAppData.js` 加 actions
5. 加单元测试
6. README schema 段更新

不要不 bump version 直接改 stores（会丢数据）。
