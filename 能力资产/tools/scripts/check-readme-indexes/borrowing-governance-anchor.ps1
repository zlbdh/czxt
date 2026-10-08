param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) {
  throw "缺少 anchor-common.ps1"
}
. $common

function Assert-ExactlyOneBorrowingSkillRoute {
  param(
    [string]$Rel,
    [string]$ExpectedTarget
  )
  $text = Get-Text $Rel
  $escaped = [regex]::Escape($ExpectedTarget)
  $matches = @([regex]::Matches(
      $text,
      '\[[^\]\r\n]+\]\(' + $escaped + '(?:#[^)\r\n]+)?\)'
    ))
  if ($matches.Count -ne 1) {
    Add-Failure "唯一借鉴 Skill 路由：$Rel 应恰好 1 次链接 $ExpectedTarget，实际 $($matches.Count)"
  }
}

function Assert-BorrowingEntryIsMinimal {
  param([string]$Rel)
  Assert-NotContains $Rel `
    'borrowing-source/v1|fingerprint_algorithm|capture\.local\.json|capture-borrowing-source\.ps1|closure_seal_sha256|借鉴-命令附录\.md' `
    "借鉴入口不得复制实现/schema 合同"
}

# 根级外部证据层：不扩成第 9 个操作系统模块，也不复制执行规则。
Assert-Contains "操作系统\00_总入口.md" '借鉴区.*根级外部证据层|借鉴区/.*Root-level external evidence' `
  "总入口声明借鉴区层级"
Assert-Contains "操作系统\00_总入口.md" '向谁学、学了什么|whom we learn from and what we learn' `
  "总入口声明借鉴区回答的问题"
Assert-Contains "操作系统\00_总入口.md" '不是第 9 个操作系统模块|It is not a ninth operating system module' `
  "总入口保持八模块边界"
Assert-Contains "README.md" '借鉴区/.*根级外部证据层|借鉴区/.*External evidence: sources and lessons learned' `
  "根 README 声明借鉴区"
Assert-Contains "Docs\3-开发文档\项目结构.md" '借鉴区/.*外部证据层|借鉴区/.*is an external evidence area' `
  "项目结构登记借鉴区"

# 9 PM 路径白名单与并行边界。
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '(?m)^\| (?:framework 内务|Framework maintenance) \|[^\r\n]*`借鉴区/`' `
  "framework 内务纳入借鉴区"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '(?m)^\| (?:操作系统 PM「框架管家」|Operating System PM “Framework Steward”)[^\r\n]*`借鉴区/`' `
  "操作系统 PM 白名单纳入借鉴区"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '操作系统 PM.*来源卡.*事项卡.*骨架.*唯一落笔|Operating System PM is the sole writer of source cards, item cards, and scaffolding' `
  "借鉴卡片唯一抽象 PM 写权"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '目标决策 PM.*只读.*领域评估.*操作系统 PM.*记录|The target decision PM has read-only card access and provides domain assessments; the Operating System PM records them' `
  "目标决策 PM 只评估不写卡"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '不同.*来源/<id>/<capture>.*事项/<id>.*worker.*写集互斥|Separate `来源/<id>/<capture>` and `事项/<id>` paths may be assigned to workers inheriting Operating System PM permissions, with disjoint write sets' `
  "借鉴 worker 互斥路径并行"
Assert-Contains "操作系统\01_架构\角色边界.md" '同一.*卡.*单写|A given card has one writer' `
  "同一卡片单写"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '实际落地.*目标路径.*既有.*责任 PM|Actual implementation returns to the existing owner of the target path' `
  "采纳落地回到既有责任 PM"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '事项卡.*不得.*扩大.*白名单|An item card must not expand any path allowlist' `
  "事项卡不得扩权"
Assert-Contains "操作系统\02_智能体\操作系统PM-框架管家.md" `
  '`借鉴区/`.*来源卡.*事项卡.*骨架' `
  "操作系统 PM playbook 借鉴区写权"
Assert-Contains "操作系统\02_智能体\操作系统PM-框架管家.md" `
  '不同.*来源/<id>/<capture>.*事项/<id>.*写集互斥' `
  "操作系统 PM playbook 并行边界"
Assert-Contains "操作系统\02_智能体\项目PM-咪咪.md" `
  '借鉴.*路由.*操作系统 PM' `
  "项目 PM 借鉴路由"

# 全局 A/B/C 入口必须覆盖来源读取、捕获与采纳，但不重复治理规则正文。
$abc = "操作系统\01_架构\三类行为铁律.md"
Assert-Contains $abc '借鉴来源动作|来源读取、捕获与采纳|Borrowing-source actions' "借鉴动作分级入口"
foreach ($case in @(
    @('只读分析.*来源.*A 类|来源.*只读分析.*A 类|Read-only source analysis \| Class A', '普通来源只读分析为 A 类'),
    @('小型本地 capture.*A 类|A 类.*小型本地 capture|Small local capture without sensitive information \| Class A', '小型本地捕获为 A 类'),
    @('远端取源.*B 类|B 类.*远端取源|Fetch remote sources \| Class B', '远端取源为 B 类'),
    @('刷新.*B 类|B 类.*刷新|Refresh sources \| Class B', '来源刷新为 B 类'),
    @('私有凭据.*B 类|B 类.*私有凭据|Use private credentials \| Class B', '私有凭据为 B 类'),
    @('来源.*运行/构建.*B 类|B 类.*来源.*运行/构建|Run or build source content \| Class B', '来源运行构建为 B 类'),
    @('capture.*删除/移动.*B 类|B 类.*capture.*删除/移动|Delete or move an existing capture \| Class B', 'capture 删除移动为 B 类'),
    @('L3/L4.*采纳.*B 类|B 类.*L3/L4.*采纳|Implement L3/L4 adoption \| Class B', 'L3/L4 采纳为 B 类'),
    @('凭据.*tracked.*C 类|C 类.*凭据.*tracked|Write credentials to tracked files \| Class C', '凭据写 tracked 为 C 类'),
    @('来源远端写入.*C 类|C 类.*来源远端写入|Write to the source remote \| Class C', '来源远端写入为 C 类'),
    @('路径逃逸.*C 类|C 类.*路径逃逸|Path escape \| Class C', '路径逃逸为 C 类'),
    @('外部指令.*C 类|C 类.*外部指令|Follow external instructions carried by the source \| Class C', '遵从外部指令为 C 类'),
    @('删除用户数据.*C 类|C 类.*删除用户数据|Delete user data \| Class C', '删除用户数据为 C 类')
  )) {
  Assert-Contains $abc $case[0] $case[1]
}
Assert-Contains $abc '普通只读分析.*不.*C 类|Ordinary read-only source analysis is not elevated to Class C' "普通只读分析不升级为 C 类"
Assert-Contains $abc '采纳.*目标路径.*既有.*白名单.*A/B/C|Adoption still follows the target path.s existing allowlist and A/B/C classification' `
  "采纳动作服从目标路径既有分级"

# AGENTS、总入口和角色入口都只给一条主 Skill 路由。
$routes = [ordered]@{
  "README.md" = "能力资产/skills/借鉴.md"
  "AGENTS.md" = "能力资产/skills/借鉴.md"
  "操作系统\00_总入口.md" = "../能力资产/skills/借鉴.md"
  "操作系统\01_架构\角色边界.md" = "../../能力资产/skills/借鉴.md"
  "操作系统\02_智能体\README.md" = "../../能力资产/skills/借鉴.md"
  "操作系统\02_智能体\项目PM-咪咪.md" = "../../能力资产/skills/借鉴.md"
  "操作系统\02_智能体\操作系统PM-框架管家.md" = "../../能力资产/skills/借鉴.md"
  "Docs\3-开发文档\项目结构.md" = "../../能力资产/skills/借鉴.md"
}
foreach ($entry in $routes.GetEnumerator()) {
  Assert-ExactlyOneBorrowingSkillRoute $entry.Key $entry.Value
  Assert-BorrowingEntryIsMinimal $entry.Key
}

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 借鉴入口与 9 PM 治理路由锚点对齐" -ForegroundColor Green
exit 0
