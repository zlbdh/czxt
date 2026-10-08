param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "Missing anchor-common.ps1" }
. $common

Assert-Contains "操作系统\05_记忆\INDEX.md" 'AGENTS\.md.*操作系统/00_总入口\.md' "Memory entry does not replace the startup chain"
Assert-Contains "操作系统\05_记忆\INDEX.md" '进入本文件后|after reaching this file' "Memory checklist is not the first startup entry"
Assert-Contains "操作系统\05_记忆\INDEX.md" 'AppData memory.*不再作为项目真相|AppData memory.*no longer authoritative for project facts' "AppData memory retirement guidance"
Assert-NotContains "操作系统\05_记忆\INDEX.md" '每次新对话\)\s*\r?\n\s*1\.\s*Read 本文件|every new conversation\)\s*\r?\n\s*1\.\s*Read this file' "Memory entry declares itself the first entry"
Assert-NotContains "操作系统\05_记忆\INDEX.md" 'ADR 完整索引（当前 \d+）|RETRO 完整索引（当前 \d+）|元规则永久池（当前 \d+）|Complete ADR index \(currently \d+\)|Complete RETRO index \(currently \d+\)|Permanent meta-rule pool \(currently \d+\)' "Memory entry hardcodes governance counts"

Assert-Contains "操作系统\05_记忆\scope-schema.md" 'global \| project \| agent \| pm-workspace \| session' "Current scope field values"
Assert-Contains "操作系统\05_记忆\scope-schema.md" 'scope=agent.*02_智能体' "scope=agent is limited to PM playbooks"
Assert-Contains "操作系统\05_记忆\scope-schema.md" 'scope=pm-workspace.*PM工作区' "PM workspaces use pm-workspace"
Assert-Contains "操作系统\05_记忆\scope-schema.md" 'pm: <PM 名>|pm: <PM name>' "pm-workspace uses the pm field"
Assert-Contains "操作系统\05_记忆\scope-schema.md" 'PROP-039 已重估拆分 / 若开新试点|PROP-039 has been reassessed and split\. If a new pilot starts' "Current PROP-039 memory-routing guidance"
Assert-NotContains "操作系统\05_记忆\scope-schema.md" 'scope=agent 时 agent 字段填 PM 名\s*$|For scope=agent, put the PM name in `agent`\s*$' "scope=agent incorrectly includes private PM workspaces"
Assert-NotContains "操作系统\05_记忆\scope-schema.md" 'Mem0 / Skills SDK GA 后|after Mem0 / Skills SDK GA' "Obsolete Mem0/Skills SDK GA blocker"

Assert-Contains "操作系统\05_记忆\AppData-memory退役清单.md" '不作为项目真相源|not authoritative for project facts' "AppData inventory is not authoritative"
Assert-Contains "操作系统\05_记忆\AppData-memory退役清单.md" '新对话不再依赖|new conversations no longer depend on these files' "New sessions do not depend on AppData"
Assert-Contains "操作系统\05_记忆\行为反思.md" '非密钥、非本机例外的项目真源|project sources of truth other than secrets and explicit machine-local exceptions' "Project-external storage rule includes secret exceptions"
Assert-Contains "操作系统\05_记忆\行为反思.md" '由项目 PM 主会话或对应白名单收口加 1 行|the Project PM main session or the responsible allowlisted role adds the final row' "Actor responsible for recording PM transitions"
Assert-NotContains "操作系统\05_记忆\行为反思.md" ('项目所需数据 / 配置 / 状态，必须在 `D:\\WGKJ\\' + [regex]::Escape('{{PROJECT_NAME}}') + '\\` 内，Git 版本化|Project data / configuration / state must be kept in `D:\\WGKJ\\' + [regex]::Escape('{{PROJECT_NAME}}') + '\\` and versioned in Git') "Overbroad project-external storage restriction"
Assert-Contains "能力资产\skills\状态推断.md" '普通回应不自动写状态字段|Ordinary responses do not automatically update status fields' "Status inference does not automatically write status"
Assert-Contains "能力资产\skills\状态推断-跨session监控.md" '不直接替用户拍板|Do not decide on the user.s behalf' "Status-inference recommendation boundary"
Assert-Contains "操作系统\07_完整工作流\实施循环.md" 'AGENTS\.md.*00_总入口' "Implementation loop prioritizes the startup chain"
Assert-Contains "操作系统\07_完整工作流\实施循环.md" '(?:状态推断.*作为补充对账|status inference.*as a supplementary reconciliation)' "Status inference supplements reconciliation"
Assert-NotContains "操作系统\07_完整工作流\实施循环.md" '第一个响应之前[\s\S]{0,80}状态推断|before the first response[\s\S]{0,120}status inference' "Status inference precedes the startup chain"
Assert-NotContains "能力资产\skills\状态推断-推断项.md" '立刻切 ✅|Immediately mark ✅' "Status inference switches status immediately"
Assert-NotContains "操作系统\07_完整工作流\实施循环-DoD.md" 'confirm 后立刻切换|立刻切换|switch immediately after confirmation|switch immediately' "DoD switches status immediately"
Assert-Contains "Docs\3-开发文档\adr\ADR-028-议题CW永久化-记忆scope-YAML显式化.md" '当前口径补记（2026-06-17）|Current guidance addendum \(2026-06-17\)' "ADR-028 current-guidance addendum"
Assert-Contains "Docs\3-开发文档\adr\ADR-028-议题CW永久化-记忆scope-YAML显式化.md" 'PROP-037 待重审状态|PROP-037 pending rereview status' "ADR-028 PROP-037 pending rereview"
Assert-Contains "操作系统\04_台账\逐文件审计覆盖台账.md" '操作系统/05_记忆' "Coverage ledger includes memory"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ Memory specification anchors are aligned" -ForegroundColor Green
exit 0
