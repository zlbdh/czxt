---
name: real-device-smoke-checklist
description: 真机 smoke 必跑 N 项清单 / 议题 CC 已升 ADR-030 与第 13 元规则「vitest ≠ 真机」/ Sprint-6+7 累积 5 次教训
trigger: 测试发布 PM 闭环前 / 开发 PM 完成代码后仅作交接自查引用 / W-3 v1→v2 / F-NIGHT v1→v2 类教训
loaded: 条件加载
---

# 真机 smoke 必跑清单

> 执行 owner 是测试发布 PM「闭环者」。开发 PM 只可在交接前引用本清单自查风险，不执行真机 smoke、commit、tag、APK 或发布闭环。

## 痛点（议题 CC 已永久化）

「**单测过 ≠ 真机过**」— 跨 Sprint 累积 5 次教训：
- F-NIGHT-1 v1 单测 879 ✅ / 真机 AC2 fail（70 字超 50 字限）
- W-3 v1 单测 900 ✅ / 真机普通聊天未走 buildPersonaPrompt 路径
- F-DEVIATION-3 单测 771 ✅ / git 损坏 .git/index 紧急恢复（议题 BK v1）
- F-WEEKLY-1 单测 820 ✅ / 真机 recharts 渲染问题
- 议题 BV W-4 / 真机 timelineBuilder 早晚餐显示验证

## 必跑清单（7 项）

### 1. AC 三层一致核验
- [ ] 设计层（PRD AC #N）
- [ ] 测试层（vitest 真实路径覆盖，不是辅助路径）
- [ ] UI 层（真机 smoke 走端到端用户流）
- ✅ 三层一致 → AC 通过

### 2. 关键路径手动走一遍（不是 grep）
- [ ] 用户主流程（如聊天 / 记账 / 训练）
- [ ] 边界场景（议题 P 三态边界 / 空状态 / 设置开关）

### 3. 议题 BG / BH 防御
- [ ] commit msg 无 BOM 前缀（git commit -F 模式）
- [ ] .bat 文件无 CRLF/LF 异常

### 4. 议题 BK mount stale 起手核验
- [ ] git status --short 干净
- [ ] HEAD hash 与测试发布 PM 闭环报告一致

### 5. 议题 BR AI 模型确认
- [ ] LLM 调通 + 内容合规（MiMo / 国内）

### 6. APK 路径单源
- [ ] {{APP_REPO_DIR}}/apk/ 单源（议题 BQ 永久关闭）

### 7. Sprint 全棒回归
- [ ] 已 ship 棒不破坏
- [ ] vitest N/N 通过

## 真知识源

- ADR-030 / 第 13 元规则：议题 CC 已永久化；本清单是执行型 SOP
- RETRO-010/011 PM 自纠 #51/#52/#54 案例
- 状态.md PM 切换轨迹 5/19-5/21
