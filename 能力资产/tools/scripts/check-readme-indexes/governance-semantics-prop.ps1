Assert-Contains "确认改动\README.md" "PROP-020-路径D-方案v0\.md.*不计独立递增编号" "PROP 编号例外 PROP-020"
Assert-Contains "确认改动\README.md" "PROP-027-v2-2026-05-21-chat简版⑦段硬约束\.md.*共用议题号" "PROP 编号例外 PROP-027"
Assert-Contains "确认改动\README.md" "PROP-025-2026-05-20-database拆分" "PROP-025 追溯补档索引"
Assert-Contains "确认改动\README.md" "chat 简版后续由 PROP-027 v2 扩为 ①-⑦" "PROP README chat 简版现行口径"
Assert-Contains "确认改动\已审批\已完成\PROP-024-2026-05-19-架构债治理v4-4包综合治理.md" "历史错误口径；现行不得预批破坏性命令" "PROP-024 破坏性命令封存"
Assert-Contains "确认改动\拒绝\PROP-027-2026-05-20-议题AJ-v2-留痕机制衰减防御.md" "历史拒绝方案，现行以 chat ①-⑦" "PROP-027 拒绝稿封存"
foreach ($rel in @(
  "确认改动\已审批\进行中\PROP-034-2026-05-21-模型分层.md",
  "确认改动\已审批\已完成\PROP-040-2026-05-22-Sprint-8-W-1-F-F1-AI餐食推荐.md",
  "确认改动\已审批\已完成\PROP-041-2026-05-24-Sprint-9-W-1-F-F2+F-F4-食谱+采购闭环.md"
)) {
  Assert-NotContains $rel "Claude Code 战场|Codex 战场" "PROP 工具主语战场旧口径"
}
