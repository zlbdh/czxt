param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"

$p4o = Join-Path $PSScriptRoot "..\check-os\p4o-markdown-links.ps1"
if (-not (Test-Path -LiteralPath $p4o -PathType Leaf)) {
  Write-Host "  🔴 P4o Markdown 链接守卫脚本缺失：$p4o" -ForegroundColor Red
  exit 10
}

& $p4o -Root $Root
exit $LASTEXITCODE
