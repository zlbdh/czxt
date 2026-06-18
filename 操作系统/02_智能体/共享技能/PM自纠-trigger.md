---
name: pm-self-correction-trigger
description: PM 自纠触发条件 + 立即落地流程（PROP-030 / artifact 化 / 全 PM 通用）
trigger: 任何 PM 帽子下 / 发现自己错向时 / zlbdh 反问触发
loaded: 条件加载
---

# PM 自纠 trigger + 立即落地

## 触发条件（5 信号）

1. ⭐ zlbdh 反问「你为什么..?」/「这不是..吗？」
2. ⭐ 自己发现 5+ 分钟前的决策有误（任何角色帽子下）
3. RETRO 起稿时识别同模式跨 Sprint 复发
4. PM 切角色帽子前 decision-checkpoint 任一步触发反思，尤其 Q1-Q3
5. zlbdh 指令「停下来操作系统自检」

## 立即落地流程（PROP-030 落地 / 5 分钟内完成）

### Step 1: 判定归属 + 编号

- 项目 PM 对外身份、全局协作、framework 规则、跨 PM 问题 → 查 `PM工作区/项目PM-咪咪/PM自纠/INDEX.md`，新 PM 自纠 = max+1
- 某 PM 私人沉淀 → 回到对应 `PM工作区/<PM名>/`；若该 PM 尚无 PM自纠目录，由项目 PM 调度该 PM 建立或回流，不硬塞进项目 PM 自纠索引

### Step 2: 立即留痕（议题 AJ）
触发 PM 先记录自纠归属与草稿；`状态.md` PM 切换轨迹由项目 PM 主会话，或白名单允许的操作系统 PM，在收口时落笔：
```
| YYYY-MM-DD HH:MM | <from> | <to> | **PM 自纠 #N — 一句话** ... | ✅ | ✅ |
```

### Step 3: 独立 artifact（议题 CN / PROP-030）
按 Step 1 归属建对应 artifact；项目 PM / 全局问题使用 `PM工作区/项目PM-咪咪/PM自纠/PM自纠-N.md`。结构：
- 一句话
- 触发场景（时间 + 步骤）
- 根因
- 防御机制（落地位置）
- 同模式累积
- 元规则候选
- 真知识源

### Step 4: 更新 INDEX
对应 PM 的 `PM自纠/INDEX.md` 或工作区 README 加 1 行指针；跨 PM 私人目录改动走项目 PM 调度，不越权整理其他 PM 工作区。

### Step 5: 评估元规则升级
- 同模式 3+ 次 → 候选元规则池
- 已落地路径 → 直接铁律（不入元规则池）

## chat 简版必含 ⑦ 段（PROP-027 v2 简化版）

「⑦ PM 切换轨迹：本次 session 加 N 行（状态.md L<line>）」

## 真知识源

- `PM工作区/项目PM-咪咪/PM自纠/INDEX.md`
- `操作系统/03_交接/交接卡格式.md` §⑦ 段
- `操作系统/05_记忆/INDEX.md` §二反思 7
