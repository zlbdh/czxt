Assert-Contains "Docs\3-开发文档\adr\README.md" "ADR-011.*ADR-017 分层化" "ADR-011 阈值继承边界"
Assert-Contains "Docs\3-开发文档\adr\README.md" "ADR-018.*①-⑦" "ADR-018 chat 简版现行口径"
Assert-Contains "Docs\3-开发文档\adr\README.md" "ADR-027.*主-元-决策-实施" "ADR-027 四层术语"
Assert-Contains "Docs\3-开发文档\通用提示词-开发操作系统体检.md" '历史模板说明.*当前内化入口见' "开发操作系统体检提示词历史边界"
Assert-Contains "Docs\3-开发文档\通用提示词-开发操作系统体检.md" '\.\./\.\./操作系统/01_架构/三类行为铁律\.md' "开发操作系统体检提示词 A/B/C 当前关联"
Assert-Contains "Docs\3-开发文档\通用提示词-开发操作系统体检.md" '\.\./\.\./能力资产/skills/项目体检\.md' "开发操作系统体检提示词项目体检当前关联"
Assert-Contains "Docs\3-开发文档\通用-记忆系统架构.md" '历史模板说明.*当前执行入口是' "记忆系统架构历史边界"
Assert-Contains "Docs\3-开发文档\通用-记忆系统架构.md" '\.\./\.\./操作系统/00_总入口\.md' "记忆系统架构操作系统当前关联"
Assert-Contains "Docs\3-开发文档\通用-记忆系统架构.md" '\.\./\.\./能力资产/skills/状态推断\.md' "记忆系统架构状态推断当前关联"
Assert-Contains "Docs\3-开发文档\adr\ADR-018-流程优先与交接卡强制.md" "现行执行口径：.*①-⑦" "ADR-018 现行补丁"
Assert-Contains "Docs\3-开发文档\adr\ADR-025-Cowork-mount-stale防御机制永久化.md" "当前安全覆盖说明.*reset 预批路径.*当前 B/C 边界取代" "ADR-025 reset 历史覆盖说明"
Assert-NotContains "Docs\3-开发文档\adr\ADR-025-Cowork-mount-stale防御机制永久化.md" "预批路径（不需重新 ask）" "ADR-025 reset 预批旧标题"
foreach ($rel in @(
  "Docs\3-开发文档\adr\ADR-026-议题CT永久化-PM角色去工具绑定.md",
  "Docs\3-开发文档\adr\ADR-027-议题CU+DD永久化-沉淀PM元层架构.md",
  "Docs\3-开发文档\adr\ADR-038-PM实体化agent调度模型.md"
)) {
  Assert-Contains $rel "术语现行统一.*主-元-决策-实施" "ADR 四层术语现行说明"
}

Assert-NotContains "Docs\7-复盘\README.md" "agent/workflows|agent/rules" "RETRO 活流程旧路径"
Assert-Contains "Docs\7-复盘\README.md" "ADR-017 分层化" "RETRO 6500B 历史边界"
Assert-Contains "Docs\7-复盘\README.md" "RETRO-009-候选议题\.md.*不计入正式编号" "RETRO 附属候选文件边界"
Assert-Contains "Docs\7-复盘\RETRO-022-2026-06.md" "当日补齐.*3 个 lifecycle.*当前事件数以 hooks README / 事件矩阵 / 真实配置为准" "RETRO-022 hooks 当时/当前边界"
