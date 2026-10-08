param([string]$Root)

$ErrorActionPreference = "Stop"
$checker = Join-Path $Root "能力资产\tools\scripts\check-os\p4n-pm-workspace.ps1"
if (-not (Test-Path -LiteralPath $checker -PathType Leaf)) {
  Write-Host "  🔴 PM workspace anchor check lacks the P4n subcheck: $checker" -ForegroundColor Red
  exit 10
}

$prev = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$out = & powershell -NoProfile -ExecutionPolicy Bypass -File $checker -Root $Root 2>&1
$code = $LASTEXITCODE
$ErrorActionPreference = $prev
$out | ForEach-Object { Write-Host $_ }
if ($code -ne 0) { exit 10 }
exit 0
