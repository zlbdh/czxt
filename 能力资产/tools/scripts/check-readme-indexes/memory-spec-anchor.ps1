param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "缺少 anchor-common.ps1" }
. $common

Assert-Contains "操作系统\05_记忆\INDEX.md" 'AGENTS\.md.*操作系统/00_总入口\.md' "05 记忆入口不替代起手链路"
Assert-Contains "操作系统\05_记忆\INDEX.md" '进入本文件后' "05 记忆 checklist 不是首个起手入口"
Assert-Contains "操作系统\05_记忆\INDEX.md" 'AppData memory.*不再作为项目真相' "AppData memory 退役口径"
Assert-NotContains "操作系统\05_记忆\INDEX.md" '每次新对话\)\s*\r?\n\s*1\.\s*Read 本文件' "05 记忆自封第一入口"
Assert-NotContains "操作系统\05_记忆\INDEX.md" 'ADR 完整索引（当前 \d+）|RETRO 完整索引（当前 \d+）|元规则永久池（当前 \d+）' "05 记忆入口硬编码治理计数"

Assert-Contains "操作系统\05_记忆\scope-schema.md" 'global \| project \| agent \| pm-workspace \| session' "scope 字段当前取值"
Assert-Contains "操作系统\05_记忆\scope-schema.md" 'scope=agent.*02_智能体' "scope=agent 限定为 PM playbook"
Assert-Contains "操作系统\05_记忆\scope-schema.md" 'scope=pm-workspace.*PM工作区' "PM 工作区使用 pm-workspace"
Assert-Contains "操作系统\05_记忆\scope-schema.md" 'pm: <PM 名>' "pm-workspace 使用 pm 字段"
Assert-Contains "操作系统\05_记忆\scope-schema.md" 'PROP-039 已重估拆分 / 若开新试点' "PROP-039 记忆路由当前口径"
Assert-NotContains "操作系统\05_记忆\scope-schema.md" 'scope=agent 时 agent 字段填 PM 名\s*$' "scope=agent 泛化为 PM 私区"
Assert-NotContains "操作系统\05_记忆\scope-schema.md" 'Mem0 / Skills SDK GA 后' "Mem0/Skills SDK GA 旧阻塞口径"

Assert-Contains "操作系统\05_记忆\AppData-memory退役清单.md" '不作为项目真相源' "AppData 清单非真源"
Assert-Contains "操作系统\05_记忆\AppData-memory退役清单.md" '新对话不再依赖' "AppData 新会话不依赖"
Assert-Contains "操作系统\05_记忆\行为反思.md" '非密钥、非本机例外的项目真源' "项目外存储铁律含密钥例外"
Assert-Contains "操作系统\05_记忆\行为反思.md" '由项目 PM 主会话或对应白名单收口加 1 行' "PM 轨迹留痕主语"
Assert-NotContains "操作系统\05_记忆\行为反思.md" '项目所需数据 / 配置 / 状态，必须在 `D:\\WGKJ\\{{PROJECT_NAME}}\\` 内，Git 版本化' "项目外存储铁律过宽"
Assert-Contains "能力资产\skills\状态推断.md" '普通回应不自动写状态字段' "状态推断不自动写状态"
Assert-Contains "能力资产\skills\状态推断-跨session监控.md" '不直接替用户拍板' "状态推断建议边界"
Assert-Contains "操作系统\07_完整工作流\实施循环.md" 'AGENTS\.md.*00_总入口' "实施循环起手链路优先"
Assert-Contains "操作系统\07_完整工作流\实施循环.md" '状态推断.*作为补充对账' "状态推断补充对账"
Assert-NotContains "操作系统\07_完整工作流\实施循环.md" '第一个响应之前[\s\S]{0,80}状态推断' "状态推断先于起手链路"
Assert-NotContains "能力资产\skills\状态推断-推断项.md" '立刻切 ✅' "状态推断立刻切状态"
Assert-NotContains "操作系统\07_完整工作流\实施循环-DoD.md" 'confirm 后立刻切换|立刻切换' "DoD 立刻切状态"
Assert-Contains "Docs\3-开发文档\adr\ADR-028-议题CW永久化-记忆scope-YAML显式化.md" '当前口径补记（2026-06-17）' "ADR-028 当前口径补记"
Assert-Contains "Docs\3-开发文档\adr\ADR-028-议题CW永久化-记忆scope-YAML显式化.md" 'PROP-037 待重审状态' "ADR-028 PROP-037 待重审"
Assert-Contains "操作系统\04_台账\逐文件审计覆盖台账.md" '操作系统/05_记忆' "覆盖台账已登记 05"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 05_记忆规格锚点对齐" -ForegroundColor Green
exit 0
