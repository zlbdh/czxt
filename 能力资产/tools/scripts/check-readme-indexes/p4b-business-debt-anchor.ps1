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
    [string]$Label
  )
  if ($Text -notmatch [regex]::Escape($Snippet)) {
    Fail-P4bAnchor "P4b 业务债表达缺少：$Label"
  }
}

$tasks = Join-Path $Root "TASKS.md"
if (-not (Test-Path -LiteralPath $tasks)) { exit 0 }

$text = Get-Content -LiteralPath $tasks -Raw -Encoding UTF8
$sectionMatch = [regex]::Match($text, '(?s)### 🟢 业务侧 P4b 历史债监控(?<body>.*?)(?:\r?\n---|\z)')
if (-not $sectionMatch.Success) {
  Fail-P4bAnchor "TASKS.md 缺少 P4b 业务债监控区块"
}
$section = $sectionMatch.Groups["body"].Value
$p4bLine = @($section -split "\r?\n" | Where-Object { $_ -match '{{APP_REPO_DIR}}/src' -and $_ -match 'P4b 业务历史债' } | Select-Object -First 1)
if ($p4bLine.Count -eq 0) {
  Fail-P4bAnchor "TASKS.md P4b 表格行缺少 {{APP_REPO_DIR}}/src + P4b 业务历史债"
}

Require-Snippet $p4bLine[0] "P4b 业务历史债" "P4b 业务历史债"
Require-Snippet $p4bLine[0] "owner=开发 PM「实施者」" "开发 PM owner"
Require-Snippet $p4bLine[0] "不代表操作系统未完成" "非操作系统未完成"
Require-Snippet $p4bLine[0] "按功能触发拆，不为数字单独动业务代码" "功能触发拆分边界"

Require-Snippet $section "#### P4b 业务债策略入口" "策略入口"
foreach ($group in @("测试膨胀", "shared 生产逻辑", "feature UI", "app hook")) {
  Require-Snippet $section $group "策略分组：$group"
}

$p4bScript = Join-Path $Root "能力资产\tools\scripts\check-os\p4b-file-size.ps1"
if (Test-Path -LiteralPath $p4bScript) {
  $scriptText = Get-Content -LiteralPath $p4bScript -Raw -Encoding UTF8
  Require-Snippet $scriptText "业务 P4b 治理摘要" "P4b 输出治理摘要"
  Require-Snippet $scriptText "owner=开发 PM「实施者」" "P4b 输出 owner"
  Require-Snippet $scriptText "不为数字清零单独动业务代码" "P4b 输出非数字清零"
}

$devPlaybook = Join-Path $Root "操作系统\02_智能体\开发PM-实施者.md"
if (Test-Path -LiteralPath $devPlaybook) {
  $devText = Get-Content -LiteralPath $devPlaybook -Raw -Encoding UTF8
  Require-Snippet $devText "P4b 业务债触发治理" "开发 PM playbook 触发治理"
  Require-Snippet $devText "触碰 P4b 红/软区" "开发 PM 触发条件"
  Require-Snippet $devText "按功能触发拆，不为数字单独动业务代码" "开发 PM 非数字清零边界"
  Require-Snippet $devText "不是操作系统未完成项" "开发 PM 非 framework 未完成边界"
}

$badPattern = '(?is)(P4b|业务大文件债|业务历史债|{{APP_REPO_DIR}}/src)[\s\S]{0,260}((操作系统|framework)\s*(未完成|未闭环|不健康|失败)|必须[\s\S]{0,40}(全拆|清零)|全部[\s\S]{0,40}拆|数字(清零|归零)|为(数字|指标|P4b)[\s\S]{0,80}(拆|重构|改业务代码)|不清零(不能|不得|不许))'
$reverseBadPattern = '(?is)((操作系统|framework)\s*(未完成|未闭环|不健康|失败)|必须[\s\S]{0,40}(全拆|清零)|全部[\s\S]{0,40}拆|数字(清零|归零)|为(数字|指标|P4b)[\s\S]{0,80}(拆|重构|改业务代码)|不清零(不能|不得|不许))[\s\S]{0,260}(P4b|业务大文件债|业务历史债|{{APP_REPO_DIR}}/src)'
$allowedNegativeContext = '不代表操作系统未完成|不是操作系统未完成|不代表 framework 未完成|不是 framework 未完成'
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
  foreach ($match in @([regex]::Matches($activeText, $badPattern) + [regex]::Matches($activeText, $reverseBadPattern))) {
    if ($match.Value -notmatch $allowedNegativeContext) {
      Fail-P4bAnchor "$rel P4b 业务债语义疑似回退：$($match.Value.Substring(0, [Math]::Min(80, $match.Value.Length)))"
    }
  }
}

Write-Host "  ✅ TASKS.md P4b 业务债表达锚点有效"
exit 0
