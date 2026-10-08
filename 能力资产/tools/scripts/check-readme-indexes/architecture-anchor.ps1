param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "Missing anchor-common.ps1" }
. $common

Assert-Contains "操作系统\01_架构\元规则池.md" '当前 \*\*17 候选\*\*|Currently \*\*17 candidates\*\*' "Meta-rule candidate count"
Assert-Contains "操作系统\01_架构\元规则池.md" '(?s)\| \*\*v3\.9\*\*.*\| \*\*17\*\*' "Meta-rule v3.9 table candidate count"

Assert-Contains "操作系统\01_架构\元规则池-候选.md" '## 一、17 候选元规则|## 1\. The 17 candidate meta-rules' "Candidate-pool heading"
Assert-Contains "操作系统\01_架构\元规则池-候选.md" '\| CK \| .* \| ⚪ P3' "CK priority"
Assert-Contains "操作系统\01_架构\元规则池-候选.md" 'CZ/DA 只保留未永久化的剩余评估项|CZ/DA retain only the remaining evaluation items not yet made permanent' "CZ/DA remaining-item boundary"

Assert-Contains "操作系统\01_架构\README设计规范.md" '只有“元规则类 ADR”才改元规则池|Update the meta-rule pool only for a meta-rule ADR' "ADR/meta-rule synchronization boundary"
Assert-Contains "操作系统\01_架构\README设计规范.md" '普通 ADR 不强行写入元规则池|Do not force ordinary ADRs into the meta-rule pool' "Ordinary ADRs do not require meta-rule changes"
Assert-NotContains "操作系统\01_架构\README设计规范.md" '本规范候选升 ADR-032|This standard is a candidate for ADR-032' "Obsolete README-standard candidate status"

Assert-Contains "操作系统\01_架构\工具载体矩阵.md" 'handoff 卡基础 ①-⑥ / framework 建议 ⑦|Handoff card sections ①–⑥; section ⑦ recommended for framework work' "Handoff section count"
Assert-Contains "操作系统\01_架构\工具载体矩阵.md" '工具解耦永久元规则|permanent tool-decoupling rule' "CT permanent meta-rule status"

Assert-Contains "操作系统\01_架构\三类行为铁律.md" '不主动问成可执行|must neither initiate execution nor ask to make it executable' "Class C must not be made executable by asking"
Assert-Contains "操作系统\01_架构\三类行为铁律.md" 'schema 表 / 字段定义|schema table, or field definition' "Schema deletion boundary"
Assert-NotContains "操作系统\01_架构\三类行为铁律.md" '等 zlbdh 决策|wait for zlbdh.s decision' "Class C cannot be bypassed by asking"

Assert-Contains "操作系统\01_架构\角色边界.md" ([regex]::Escape('{{APP_REPO_DIR}}') + '/\.env\.local') "Exact environment paths"
Assert-Contains "操作系统\01_架构\角色边界.md" '(?:常规版本 tag/push tag|ordinary version tags and tag pushes under ADR-016)' "Test and Release PM tag ownership"
Assert-Contains "操作系统\01_架构\角色边界.md" '(?:开发期本地自测=开发 PM|local development self-tests belong to the Development PM)' "Development self-test ownership"
Assert-Contains "操作系统\01_架构\角色边界.md" '(?:发布/ship gate 的 vitest 复核|Release/ship-gate vitest verification)' "Release-gate test ownership"
Assert-Contains "操作系统\01_架构\角色边界.md" '\.gitattributes' "Test and Release PM gitattributes allowlist"
Assert-NotContains "操作系统\01_架构\角色边界.md" '用户明确裁决处理|handled by a one-time explicit user decision' "Class C is not overridden by a one-time decision"

Assert-Contains "操作系统\00_总入口.md" '(?:除项目 PM 主会话外，每个 PM|Except for the Project PM.s main session, each PM)' "Main-entry agent exception"
Assert-Contains "操作系统\01_架构\子agent调度机制.md" '除项目 PM 主会话外，每个 PM|Except for the Project PM.s main session, each PM' "Agent-scheduling main-document exception"
Assert-Contains "操作系统\01_架构\子agent调度机制-附录.md" '除项目 PM 主会话外，每个 PM|Except for the Project PM.s main session, each PM' "Agent-scheduling appendix exception"
Assert-NotContains "操作系统\01_架构\演化哲学.md" 'Claude Code 等载体|Codex 等载体|只读 Docs/4-测试文档/|runtimes such as Claude Code|runtimes such as Codex|read-only Docs/4-测试文档/' "Evolution philosophy obsolete runtime/narrow-read guidance"
Assert-Contains "操作系统\01_架构\状态机.md" '5\+2 态|5\+2 state model' "State-machine 5+2 model"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ Architecture semantic anchors aligned" -ForegroundColor Green
exit 0
