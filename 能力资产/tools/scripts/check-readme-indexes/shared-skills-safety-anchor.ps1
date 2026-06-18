param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "缺少 anchor-common.ps1" }
. $common

Assert-Contains "操作系统\02_智能体\共享技能\git撤销恢复.md" '不要自动 `rm \.git/index` 或 `git reset --hard`' "git 恢复危险动作禁自动执行"
Assert-Contains "操作系统\02_智能体\共享技能\git撤销恢复.md" '必须等 zlbdh 本次明确授权' "git 恢复需本次明确授权"

foreach ($needle in @(
  '真实代码 grep verify',
  'AC 数值有实证基础',
  '内部一致性 cross-validate',
  '分支名 main 不写 master',
  'APK 历史大小有参考值',
  '提示词 ≤ 10 行',
  'v3\.0 哲学新功能必加 settings 开关'
)) {
  Assert-Contains "操作系统\02_智能体\共享技能\handoff卡-verify清单.md" $needle "handoff verify checklist 漂移"
}

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 共享技能安全锚点对齐" -ForegroundColor Green
exit 0
