# ADR-034 · LLM 关键路径工程铁律（加固闸 + marker AC + 多层门控全链同词 + prompt 动词配边界）

- **状态**：现行
- **日期**：2026-06-09
- **决策人**：zlbdh approve / 沉淀 PM 起草（PROP-043）
- **关联**：RETRO-018（F 钠盐 4 轮 saga）+ RETRO-019（G-F6 周期预约 5 轮 epic）/ 元规则 DO + DP

## 背景

本 session F 钠盐（v3.34，4 轮 smoke）与 G-F6 周期预约（v3.36，5 轮 smoke）两次出现「node 真调全过、真机设备屡挂」的 LLM 尾部行为黑洞，累计 9 轮往返。根因复盘发现这不是实施质量问题，而是**把 LLM 输出放进了关键路径却没有可观测/确定性保障**：控钠是「模型内心戏」smoke 无法验证；周期 recurrence 求 LLM 给而非从 canonical 句式算；多层门控（预筛 RE→prompt→normalize→兜底）只改一层导致 G-F6「二进宫」。需要把这套教训固化为 LLM 工程的关键路径设计铁律。

## 决定

凡涉及 LLM 调用的功能刀，遵守以下四条（DO/DP 升元规则，另两条为本 ADR 细则）：

- **DO 加固闸（canonical 机读输入正则为准、LLM 兜底）**：结构化可机读的字段（每月 N 号/每年 M 月 N 号/数值），第一刀就用正则【为准】覆盖 LLM 的 null/畸形/错频率，`extract(原文) || normalize(llm)`，把 LLM 移出关键路径；非 canonical 才退守 LLM。
- **DP marker AC（LLM 行为约束必须输出可见 marker）**：LLM 行为约束类需求第一刀必须定义「输出必含什么可见字段/关键词」的 AC + smoke 判据同卡拍板，禁止「隐性约束」（smoke 无可验对象）。
- **多层门控全链同词**：预筛 RE/prompt 例表/normalize/兜底任一层增删锚词，必须全链同步跟进（G-F6 理发只补 RE 第 1 层、prompt 例表第 2 层漏 → 二进宫）。
- **prompt 诱导动作类动词必配边界**：替代/删除/避免等动词必配「不顶替原物/只作补充」边界（v3.34「替代」二字诱导 MiMo 把含钠调料整体删掉=丢调料 bug）。

## 后果

### 好处
- LLM 关键路径从「赌模型心情」变为「确定性算 + 可验 marker」，根因级终结 node-pass-device-fail 捉迷藏。
- 第一刀就定 marker AC，smoke 有可验对象，避免 3-5 轮往返。

### 代价
- 每个 LLM 刀第一刀设计成本上升（需想清 canonical 边界 + marker 定义）。
- 加固闸正则需维护（canonical 句式扩展时同步）。

### 后续如果反悔了
- 翻案成本低：这些是 prompt/纯函数层约定，删除加固闸退回纯 LLM 即可，但会重新暴露尾部黑洞。不推荐。

---

## 备注
DP 与 ADR-030（CC token 预算真机实证）互补：CC 管 token 头寸，DP 管行为可观测性。DO 与 ADR-033（大文件 mount 不可信）同属「不信不可控来源、用确定性兜底」哲学。
