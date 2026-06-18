# API 规范

> ⚠️ **安全说明（2026-06-15）**：本文示例不包含真实 key。真实 apiKey 只允许由用户在本机配置，不写入 tracked 文件、不外传；baseUrl/model 属半敏感配置，按当前 `操作系统/01_架构/三类行为铁律.md` 与 ADR-022 的 B/C 分层判断。

## AI 调用（唯一对外 API）

代码：`src/shared/ai.js`

### 配置

```js
LLM_DEFAULTS = {
  baseUrl: 'https://token-plan-sgp.xiaomimimo.com/anthropic',
  model:   'mimo-v2.5-pro',
  apiKey:  '', // 默认不内置 key，用户在本机「我」页面填写
}
```

用户可在「我」页面填写/清空（存 localStorage `llm-config-v1`）。

### 协议

兼容 Anthropic Messages API。

```
POST {baseUrl}/v1/messages
Headers:
  x-api-key: <key>
  anthropic-version: 2023-06-01
  anthropic-dangerous-direct-browser-access: true
  Content-Type: application/json

Body:
{
  "model": "<model>",
  "max_tokens": 1024,
  "system": "<system prompt>",
  "messages": [
    { "role": "user", "content": "..." },
    { "role": "assistant", "content": "..." },
    ...
  ]
}
```

图片消息：

```js
content: [
  { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: '<base64>' } },
  { type: 'text', text: '...' },
]
```

### 4 个 AI 能力

#### 1. callAI — 通用聊天

```js
import { callAI } from '../shared/ai.js';

const reply = await callAI({
  messages: [{ role: 'user', content: '...' }],
  systemOverride: '...',  // 可选
  maxTokens: 800,         // 默认 1024
});
// 返回 string
```

#### 2. analyzeMealImage — 餐照分析

```js
import { analyzeMealImage } from '../shared/ai.js';

const json = await analyzeMealImage({
  image: base64,         // 不带 data:image 前缀
  profile: data.profile,
  mealType: '早餐',
});
// 返回 { summary, calories, protein, suggestion }
```

#### 3. parseLedgerWithAI — 自然语言记账兜底

```js
const ai = await parseLedgerWithAI({
  text: '昨天打车 28',
  ledgerContext: { today: '2026-05-07' },
});
// 返回 { action, reply, records: [{ text, amount, type, category, date }] }
```

只在本地 `parseLedgerText()` 解析失败时才调（节约 API 调用）。

#### 4. summarizeDay — 今日整理

```js
const text = await summarizeDay({
  date: today,
  tasks: ...,
  habits: ...,
  meals: ...,
  ...
});
// 返回 string
```

### 错误处理

所有调用必须 try/catch：

```js
try {
  const reply = await callAI({ ... });
} catch (e) {
  // e.message 形如 "API 401: Unauthorized"
  setError(`AI 暂时没接上：${e.message?.slice(0, 80)}`);
}
```

常见错误：
- 401：API key 错或过期 → 引导用户去「我」改 key
- 429：限流 → 等几分钟再试
- 500/502：服务端 → 重试一次
- 缺 key：抛 `MissingApiKeyError`，UI 显示「请先在我页面设置 API Key」

## 内部数据 API（store actions）

代码：`src/app/useAppData.js`

```js
const { data, actions, today } = store;

// 档案
await actions.saveProfile(profile);

// 任务打卡
await actions.setTask(taskId, 'done' | 'skip' | null);
await actions.resetToday();

// 喝水
await actions.setHydration(8);

// 习惯
await actions.addHabit({ title, note, category, color });
await actions.toggleHabit(habitId, dateKey);
await actions.resetHabits();

// 通用 CRUD（适用于 weightRecords / mealRecords / exerciseRecords / ledgerEntries / moments / chatMessages / deviceEvents）
await actions.addRecord('mealRecords', { ... });    // 自动加 id + date + createdAt
await actions.updateRecord('mealRecords', record);
await actions.deleteRecord('mealRecords', id);

// 备份
const json = await actions.exportData();
await actions.importData(jsonString);
```

### 设计原则

- 所有 actions 都是 async（返回 Promise）
- actions 内部：先写 DB → 再 setData → 触发 React 重渲染
- 失败抛错，调用方 try/catch
- 不在 actions 里弹 toast / alert（让 UI 决定怎么展示错）

## Capacitor 原生 API（未来扩展）

目前只用 Capacitor 6 核心。未来可能加：

| 用途 | 插件 |
|---|---|
| 喝水通知（F-104） | `@capacitor/local-notifications` |
| 应用锁（F-201） | `@capacitor/biometric-auth` 或 `@capacitor-community/biometric-auth` |
| 自动备份（F-204） | `@capacitor/filesystem` |
| BLE 体重秤 / 终端 | `@capacitor-community/bluetooth-le` |

每加一个原生插件，要：
1. `npm install <plugin>`
2. `npx cap sync android`
3. 在 `android/app/src/main/AndroidManifest.xml` 加权限（如 BLUETOOTH）
4. 真机测试
