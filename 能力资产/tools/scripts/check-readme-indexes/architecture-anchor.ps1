param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "缺少 anchor-common.ps1" }
. $common

Assert-Contains "操作系统\01_架构\元规则池.md" '当前 \*\*17 候选\*\*' "元规则池候选数"
Assert-Contains "操作系统\01_架构\元规则池.md" '(?s)\| \*\*v3\.9\*\*.*\| \*\*17\*\*' "元规则池 v3.9 表格候选数"

Assert-Contains "操作系统\01_架构\元规则池-候选.md" '## 一、17 候选元规则' "候选池标题"
Assert-Contains "操作系统\01_架构\元规则池-候选.md" '\| CK \| .* \| ⚪ P3' "CK 优先级"
Assert-Contains "操作系统\01_架构\元规则池-候选.md" 'CZ/DA 只保留未永久化的剩余评估项' "CZ/DA 剩余项边界"

Assert-Contains "操作系统\01_架构\README设计规范.md" '只有“元规则类 ADR”才改元规则池' "ADR 元规则同步边界"
Assert-Contains "操作系统\01_架构\README设计规范.md" '普通 ADR 不强行写入元规则池' "普通 ADR 不强制改元规则池"
Assert-NotContains "操作系统\01_架构\README设计规范.md" '本规范候选升 ADR-032' "README 规范旧候选状态"

Assert-Contains "操作系统\01_架构\工具载体矩阵.md" 'handoff 卡基础 ①-⑥ / framework 建议 ⑦' "handoff 段数口径"
Assert-Contains "操作系统\01_架构\工具载体矩阵.md" '工具解耦永久元规则' "CT 永久元规则口径"

Assert-Contains "操作系统\01_架构\三类行为铁律.md" '不主动问成可执行' "C 类不问成可执行"
Assert-Contains "操作系统\01_架构\三类行为铁律.md" 'schema 表 / 字段定义' "schema 删除边界"
Assert-NotContains "操作系统\01_架构\三类行为铁律.md" '等 zlbdh 决策' "C 类不可 ask-pass"

Assert-Contains "操作系统\01_架构\角色边界.md" '{{APP_REPO_DIR}}/\.env\.local' "env 路径精确化"
Assert-Contains "操作系统\01_架构\角色边界.md" '常规版本 tag/push tag' "测试发布 PM tag owner"
Assert-Contains "操作系统\01_架构\角色边界.md" '开发期本地自测=开发 PM' "开发期自测 owner"
Assert-Contains "操作系统\01_架构\角色边界.md" '发布/ship gate 的 vitest 复核' "发布 gate 测试 owner"
Assert-Contains "操作系统\01_架构\角色边界.md" '\.gitattributes' "测试发布 PM gitattributes 白名单"
Assert-NotContains "操作系统\01_架构\角色边界.md" '用户明确裁决处理' "C 类不走单次裁决"

Assert-Contains "操作系统\00_总入口.md" '除项目 PM 主会话外，每个 PM' "总入口 agent 例外"
Assert-Contains "操作系统\01_架构\子agent调度机制.md" '除项目 PM 主会话外，每个 PM' "子 agent 正文例外"
Assert-Contains "操作系统\01_架构\子agent调度机制-附录.md" '除项目 PM 主会话外，每个 PM' "子 agent 附录例外"
Assert-NotContains "操作系统\01_架构\演化哲学.md" 'Claude Code 等载体|Codex 等载体|只读 Docs/4-测试文档/' "演化哲学旧载体/窄读口径"
Assert-Contains "操作系统\01_架构\状态机.md" '5\+2 态' "状态机 5+2 口径"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 01_架构语义锚点对齐" -ForegroundColor Green
exit 0
