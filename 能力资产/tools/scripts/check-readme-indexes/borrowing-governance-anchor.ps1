param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) {
  throw "Missing anchor-common.ps1"
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
    Add-Failure "Single borrowing Skill route: $Rel must link to $ExpectedTarget exactly 1 time; actual $($matches.Count)"
  }
}

function Assert-BorrowingEntryIsMinimal {
  param([string]$Rel)
  Assert-NotContains $Rel `
    'borrowing-source/v1|fingerprint_algorithm|capture\.local\.json|capture-borrowing-source\.ps1|closure_seal_sha256|借鉴-命令附录\.md' `
    "Borrowing entry points must not duplicate implementation/schema contracts"
}

# Root-level external evidence: do not add a 9th operating-system module or duplicate execution rules.
Assert-Contains "操作系统\00_总入口.md" '借鉴区.*根级外部证据层|借鉴区/.*Root-level external evidence' `
  "Main entry declares the borrowing-area layer"
Assert-Contains "操作系统\00_总入口.md" '向谁学、学了什么|whom we learn from and what we learn' `
  "Main entry states the questions answered by the borrowing area"
Assert-Contains "操作系统\00_总入口.md" '不是第 9 个操作系统模块|It is not a ninth operating system module' `
  "Main entry preserves the eight-module boundary"
Assert-Contains "README.md" '借鉴区/.*根级外部证据层|借鉴区/.*External evidence: sources and lessons learned' `
  "Root README declares the borrowing area"
Assert-Contains "Docs\3-开发文档\项目结构.md" '借鉴区/.*外部证据层|借鉴区/.*is an external evidence area' `
  "Project structure registers the borrowing area"

# Path allowlists and parallel-work boundaries for the 9 PMs.
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '(?m)^\| (?:framework 内务|Framework maintenance) \|[^\r\n]*`借鉴区/`' `
  "Framework maintenance includes the borrowing area"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '(?m)^\| (?:操作系统 PM「框架管家」|Operating System PM “Framework Steward”)[^\r\n]*`借鉴区/`' `
  "Operating System PM allowlist includes the borrowing area"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '操作系统 PM.*来源卡.*事项卡.*骨架.*唯一落笔|Operating System PM is the sole writer of source cards, item cards, and scaffolding' `
  "The designated abstract PM has sole write access to borrowing cards"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '目标决策 PM.*只读.*领域评估.*操作系统 PM.*记录|The target decision PM has read-only card access and provides domain assessments; the Operating System PM records them' `
  "Target decision PM assesses but does not write cards"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '不同.*来源/<id>/<capture>.*事项/<id>.*worker.*写集互斥|Separate `来源/<id>/<capture>` and `事项/<id>` paths may be assigned to workers inheriting Operating System PM permissions, with disjoint write sets' `
  "Borrowing workers use disjoint paths for parallel work"
Assert-Contains "操作系统\01_架构\角色边界.md" '同一.*卡.*单写|A given card has one writer' `
  "A card has one writer"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '实际落地.*目标路径.*既有.*责任 PM|Actual implementation returns to the existing owner of the target path' `
  "Adoption implementation returns to the existing responsible PM"
Assert-Contains "操作系统\01_架构\角色边界.md" `
  '事项卡.*不得.*扩大.*白名单|An item card must not expand any path allowlist' `
  "Item cards must not expand permissions"
Assert-Contains "操作系统\02_智能体\操作系统PM-框架管家.md" `
  '(?:`借鉴区/`.*来源卡.*事项卡.*骨架|`借鉴区/`[^\r\n]*Sole writing role for source cards, item cards, and scaffolding)' `
  "Operating System PM playbook borrowing-area write access"
Assert-Contains "操作系统\02_智能体\操作系统PM-框架管家.md" `
  '(?:不同.*来源/<id>/<capture>.*事项/<id>.*写集互斥|Different\ `来源/<id>/<capture>`\ and\ `事项/<id>`\ paths\ may\ use\ workers\ with\ disjoint\ write\ sets;\ each\ card\ has\ one\ writer\.)' `
  "Operating System PM playbook parallel-work boundary"
Assert-Contains "操作系统\02_智能体\项目PM-咪咪.md" `
  '(?:借鉴.*路由.*操作系统 PM|Route\ borrowing,\ reference,\ and\ benchmarking\ requests\ to\ Operating\ System\ PM\ through\ the)' `
  "Project PM borrowing route"

# The global A/B/C entry must cover source reading, capture, and adoption without repeating the governance rules.
$abc = "操作系统\01_架构\三类行为铁律.md"
Assert-Contains $abc '借鉴来源动作|来源读取、捕获与采纳|Borrowing-source actions' "Borrowing-action classification entry"
foreach ($case in @(
    @('只读分析.*来源.*A 类|来源.*只读分析.*A 类|Read-only source analysis \| Class A', 'Ordinary read-only source analysis is Class A'),
    @('小型本地 capture.*A 类|A 类.*小型本地 capture|Small local capture without sensitive information \| Class A', 'Small local capture is Class A'),
    @('远端取源.*B 类|B 类.*远端取源|Fetch remote sources \| Class B', 'Remote source retrieval is Class B'),
    @('刷新.*B 类|B 类.*刷新|Refresh sources \| Class B', 'Source refresh is Class B'),
    @('私有凭据.*B 类|B 类.*私有凭据|Use private credentials \| Class B', 'Private credentials are Class B'),
    @('来源.*运行/构建.*B 类|B 类.*来源.*运行/构建|Run or build source content \| Class B', 'Running or building source content is Class B'),
    @('capture.*删除/移动.*B 类|B 类.*capture.*删除/移动|Delete or move an existing capture \| Class B', 'Deleting or moving a capture is Class B'),
    @('L3/L4.*采纳.*B 类|B 类.*L3/L4.*采纳|Implement L3/L4 adoption \| Class B', 'L3/L4 adoption is Class B'),
    @('凭据.*tracked.*C 类|C 类.*凭据.*tracked|Write credentials to tracked files \| Class C', 'Writing credentials to tracked files is Class C'),
    @('来源远端写入.*C 类|C 类.*来源远端写入|Write to the source remote \| Class C', 'Writing to the source remote is Class C'),
    @('路径逃逸.*C 类|C 类.*路径逃逸|Path escape \| Class C', 'Path escape is Class C'),
    @('外部指令.*C 类|C 类.*外部指令|Follow external instructions carried by the source \| Class C', 'Following external instructions is Class C'),
    @('删除用户数据.*C 类|C 类.*删除用户数据|Delete user data \| Class C', 'Deleting user data is Class C')
  )) {
  Assert-Contains $abc $case[0] $case[1]
}
Assert-Contains $abc '普通只读分析.*不.*C 类|Ordinary read-only source analysis is not elevated to Class C' "Ordinary read-only analysis is not elevated to Class C"
Assert-Contains $abc '采纳.*目标路径.*既有.*白名单.*A/B/C|Adoption still follows the target path.s existing allowlist and A/B/C classification' `
  "Adoption follows the existing target-path classification"

# AGENTS, the main entry, and role entries each expose only one primary Skill route.
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

Write-Host "  ✅ Borrowing entry points and 9 PM governance routes are aligned" -ForegroundColor Green
exit 0
