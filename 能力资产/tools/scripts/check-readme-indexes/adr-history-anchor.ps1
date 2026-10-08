param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

function Add-Failure([string]$Message) {
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

function Read-Text([string]$Rel) {
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "ADR 历史锚点缺文件：$Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Read-Head([string]$Rel, [int]$Lines = 18) {
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "ADR 历史锚点缺文件：$Rel"
    return ""
  }
  return (Get-Content -LiteralPath $path -TotalCount $Lines -Encoding UTF8) -join "`n"
}

$adrReadme = Read-Text "Docs\3-开发文档\adr\README.md"
if ($adrReadme -notmatch "ADR-007.*历史结构决策.*操作系统/.*能力资产/.*被现行结构覆盖|ADR-007.*Historical structural decision.*操作系统/.*能力资产/.*Superseded by the current structure") {
  Add-Failure "ADR README 未声明 ADR-007 被现行结构覆盖"
}

$adrDir = Join-Path $Root "Docs\3-开发文档\adr"
$riskPattern = "(?im)(^|[\s`'""(（])(?:agent|rules)[\\/]|chat 简版\s*①-⑥|chat shorthand\s*①[–-]⑥|交接卡\s*6\s*段|handoff card\s*(?:with\s*)?6\s*sections|主-元-子-子子|lead[–-]meta[–-]child[–-]grandchild|Claude Code 战场|Claude Code battlefield|Codex 战场|Codex battlefield|git reset --hard|rm\s+\.git/index|rm -rf|apiKey|baseUrl|API key|\.env\.local|hotfix/|GitHub Release"
foreach ($file in Get-ChildItem -LiteralPath $adrDir -Filter "ADR-*.md" -File -ErrorAction SilentlyContinue) {
  $rel = $file.FullName.Substring($Root.Length).TrimStart('\')
  $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  if ($text -notmatch $riskPattern) { continue }

  $head = Read-Head $rel 18
  if ($head -notmatch "当前覆盖说明|现行执行口径|术语现行统一|当前安全覆盖说明|历史结构决策|被现行结构覆盖|当前.*为准|现行.*为准|Current override notice|Current execution guidance|Current terminology|Current safety override notice|Historical structural decision|Superseded by the current structure|Current.*takes precedence|Current guidance addendum \(2026-06-17\)") {
    Add-Failure "$rel 命中 ADR 旧路径/旧口径/敏感配置但首屏缺当前覆盖说明"
  }

  if ($text -match "git reset --hard|rm\s+\.git/index|rm -rf" -and $head -notmatch "不能照抄|不可直接复制执行|不得|明确授权|当前安全覆盖说明|must not be copied and executed directly|explicit authorization|Current safety override notice") {
    Add-Failure "$rel 含破坏性历史命令但首屏未禁止照抄或指向当前授权边界"
  }

  if ($text -match "(?i)apiKey|baseUrl|API key|\.env\.local" -and $head -notmatch "ADR-022|三类行为铁律|真实.*key|密钥|B 类|C 类|tracked 文件|设置入口描述|Class B|Class C|tracked files|real secrets|settings entry description") {
    Add-Failure "$rel 含敏感配置语义但首屏未说明 B/C 边界"
  }
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ ADR 正文历史/敏感口径锚点对齐" -ForegroundColor Green
exit 0
