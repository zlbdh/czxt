param([string]$Root)

$ErrorActionPreference = "Stop"

function Fail-P4bAnchor {
  param([string]$Message)
  Write-Host "  🔴 $Message" -ForegroundColor Red
  exit 10
}

function Require-Snippet {
  param(
    [string]$Text,
    [string]$Snippet,
    [string]$Label,
    [string[]]$EnglishSnippets = @()
  )
  if ($Text -match [regex]::Escape($Snippet)) { return }
  if ($EnglishSnippets.Count -gt 0) {
    $allEnglishPresent = $true
    foreach ($englishSnippet in $EnglishSnippets) {
      if ([string]::IsNullOrWhiteSpace($englishSnippet) -or $Text -notmatch [regex]::Escape($englishSnippet)) {
        $allEnglishPresent = $false
        break
      }
    }
    if ($allEnglishPresent) { return }
  }
  Fail-P4bAnchor "Missing P4b debt guidance: $Label"
}

$tasks = Join-Path $Root "TASKS.md"
if (-not (Test-Path -LiteralPath $tasks)) { exit 0 }

$text = Get-Content -LiteralPath $tasks -Raw -Encoding UTF8
$sectionMatch = [regex]::Match($text, '(?is)### 🟢 (?:业务侧 P4b 历史债监控|Business P4b Historical Debt Monitoring)(?<body>.*?)(?:\r?\n---|\z)')
if (-not $sectionMatch.Success) {
  Fail-P4bAnchor "TASKS.md lacks the P4b debt-monitoring section"
}
$section = $sectionMatch.Groups["body"].Value
$p4bLine = @($section -split "\r?\n" | Where-Object { $_ -match [regex]::Escape('{{APP_REPO_DIR}}/src') -and $_ -match 'P4b 业务历史债|P4b business historical debt' } | Select-Object -First 1)
if ($p4bLine.Count -eq 0) {
  Fail-P4bAnchor "TASKS.md P4b row lacks {{APP_REPO_DIR}}/src or debt status"
}

Require-Snippet $p4bLine[0] "P4b 业务历史债" "P4b historical debt" @("P4b business historical debt")
Require-Snippet $p4bLine[0] "owner=开发 PM「实施者」" "Development PM ownership" @("owner=Development PM 'Implementer'")
Require-Snippet $p4bLine[0] "不代表操作系统未完成" "Application debt is not unfinished OS work" @("Does not indicate unfinished operating-system work")
Require-Snippet $p4bLine[0] "按功能触发拆，不为数字单独动业务代码" "Feature-triggered split boundary" @("split when a feature change calls for it, not solely to reduce a number")

Require-Snippet $section "#### P4b 业务债策略入口" "Strategy entry" @("#### P4b Business Debt Policy Entry")
$groupAliases = @{
  "测试膨胀" = "Test growth"
  "shared 生产逻辑" = "Shared production logic"
  "feature UI" = "Feature UI"
  "app hook" = "App hooks"
}
foreach ($group in @("测试膨胀", "shared 生产逻辑", "feature UI", "app hook")) {
  Require-Snippet $section $group "Strategy group: $group" @($groupAliases[$group])
}

$p4bScript = Join-Path $Root "能力资产\tools\scripts\check-os\p4b-file-size.ps1"
if (Test-Path -LiteralPath $p4bScript) {
  $scriptText = Get-Content -LiteralPath $p4bScript -Raw -Encoding UTF8
  Require-Snippet $scriptText "业务 P4b 治理摘要" "P4b output governance summary" @("business P4b governance summary")
  Require-Snippet $scriptText "owner=开发 PM「实施者」" "P4b output owner" @("owner=Development PM 'Implementer'")
  Require-Snippet $scriptText "不为数字清零单独动业务代码" "P4b output avoids counter-only work" @("not solely to reduce a number")
}

$devPlaybook = Join-Path $Root "操作系统\02_智能体\开发PM-实施者.md"
if (Test-Path -LiteralPath $devPlaybook) {
  $devText = Get-Content -LiteralPath $devPlaybook -Raw -Encoding UTF8
  Require-Snippet $devText "P4b 业务债触发治理" "Development PM playbook governance triggers" @("P4b business-debt triggers")
  Require-Snippet $devText "触碰 P4b 红/软区" "Development PM trigger conditions" @("Related work touches a P4b red/advisory area")
  Require-Snippet $devText "按功能触发拆，不为数字单独动业务代码" "Development PM counter-only-work boundary" @("split with the feature", "Do not change business code merely to clear numeric debt.")
  Require-Snippet $devText "不是操作系统未完成项" "Development PM framework-work boundary" @("This is not unfinished Operating System PM work.")
}

$badPattern = '(?is)(P4b|业务大文件债|业务历史债|__CZXT_APP_REPO_DIR_REGEX__/src)[\s\S]{0,260}((操作系统|framework)\s*(未完成|未闭环|不健康|失败)|必须[\s\S]{0,40}(全拆|清零)|全部[\s\S]{0,40}拆|数字(清零|归零)|为(数字|指标|P4b)[\s\S]{0,80}(拆|重构|改业务代码)|不清零(不能|不得|不许))'
$reverseBadPattern = '(?is)((操作系统|framework)\s*(未完成|未闭环|不健康|失败)|必须[\s\S]{0,40}(全拆|清零)|全部[\s\S]{0,40}拆|数字(清零|归零)|为(数字|指标|P4b)[\s\S]{0,80}(拆|重构|改业务代码)|不清零(不能|不得|不许))[\s\S]{0,260}(P4b|业务大文件债|业务历史债|__CZXT_APP_REPO_DIR_REGEX__/src)'
$appLiteral = [regex]::Escape('{{APP_REPO_DIR}}')
$badPattern = $badPattern.Replace('__CZXT_APP_REPO_DIR_REGEX__', $appLiteral)
$reverseBadPattern = $reverseBadPattern.Replace('__CZXT_APP_REPO_DIR_REGEX__', $appLiteral)
$allowedNegativeContext = '不代表操作系统未完成|不是操作系统未完成|不代表 framework 未完成|不是 framework 未完成'
# Reject equivalent false claims in both languages.
$englishDebtSubject = '(?:P4b|business large-file debt|business historical debt|__CZXT_APP_REPO_DIR_REGEX__/src)'
$englishBadClaim = '(?:(?:operating[- ]system|framework)\s+(?:is\s+)?(?:unfinished|incomplete|unhealthy|failed)|must[\s\S]{0,40}(?:split all|clear all counts)|split (?:all files|everything)|(?:clear|zero) (?:all )?(?:numeric debt|counts)|(?:split|refactor|change business code)[\s\S]{0,80}for (?:numbers|metrics|P4b)|cannot (?:proceed|finish) until (?:the )?counts are zero)'
$englishDebtSubject = $englishDebtSubject.Replace('__CZXT_APP_REPO_DIR_REGEX__', $appLiteral)
$englishBadPattern = '(?is)' + $englishDebtSubject + '[\s\S]{0,260}' + $englishBadClaim
$englishReverseBadPattern = '(?is)' + $englishBadClaim + '[\s\S]{0,260}' + $englishDebtSubject
$englishAllowedContexts = @(
  'does not indicate unfinished operating-system work',
  'is not unfinished operating-system work',
  'does not indicate unfinished framework work',
  'is not unfinished framework work',
  'not solely to reduce a number',
  'do not change business code solely to clear counts',
  'do not change business code merely to clear numeric debt'
)

$activeFiles = @(
  "TASKS.md",
  "README.md",
  "状态.md",
  "操作系统\00_总入口.md",
  "能力资产\skills\项目体检.md"
)
$handoffPending = Join-Path $Root "交接区\待接手"
if (Test-Path -LiteralPath $handoffPending -PathType Container) {
  $activeFiles += @(Get-ChildItem -LiteralPath $handoffPending -Filter "*.md" -File | ForEach-Object {
    $_.FullName.Replace("$Root\", "")
  })
}

foreach ($rel in $activeFiles) {
  $path = Join-Path $Root $rel
  if (-not (Test-Path -LiteralPath $path)) { continue }
  $activeText = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  $activeText = $activeText `
    -replace '不代表操作系统未完成', 'P4B_ALLOWED_CONTEXT' `
    -replace '不是操作系统未完成', 'P4B_ALLOWED_CONTEXT' `
    -replace '不代表 framework 未完成', 'P4B_ALLOWED_CONTEXT' `
    -replace '不是 framework 未完成', 'P4B_ALLOWED_CONTEXT' `
    -replace '不为数字清零', 'P4B_ALLOWED_CONTEXT' `
    -replace '不为数字单独动业务代码', 'P4B_ALLOWED_CONTEXT'
  foreach ($allowedContext in $englishAllowedContexts) {
    $activeText = $activeText -replace [regex]::Escape($allowedContext), 'P4B_ALLOWED_CONTEXT'
  }
  foreach ($match in @([regex]::Matches($activeText, $badPattern) + [regex]::Matches($activeText, $reverseBadPattern) + [regex]::Matches($activeText, $englishBadPattern) + [regex]::Matches($activeText, $englishReverseBadPattern))) {
    if ($match.Value -notmatch $allowedNegativeContext) {
      Fail-P4bAnchor "$rel may reintroduce obsolete P4b application-debt semantics: $($match.Value.Substring(0, [Math]::Min(80, $match.Value.Length)))"
    }
  }
}

Write-Host "  ✅ TASKS.md P4b application-debt guidance anchors are valid"
exit 0
