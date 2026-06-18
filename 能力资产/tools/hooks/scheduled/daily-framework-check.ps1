param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$runner = Join-Path $Root "能力资产\tools\hooks\run-hooks.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $runner -Trigger scheduled -Mode Check -Root $Root
exit $LASTEXITCODE
