param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "Missing anchor-common.ps1" }
. $common

Assert-Contains "操作系统\02_智能体\共享技能\git撤销恢复.md" '(?:不要自动 `rm \.git/index` 或 `git reset --hard`|Do\ not\ automatically\ run\ `rm\ \.git/index`\ or\ `git\ reset\ \-\-hard`)' "No automatic destructive Git recovery"
Assert-Contains "操作系统\02_智能体\共享技能\git撤销恢复.md" '(?:必须等 zlbdh 本次明确授权|Wait\ for\ zlbdh''s\ explicit\ authorization\ for\ this\ occurrence\.)' "Git recovery requires authorization for this occurrence"

foreach ($needle in @(
  '(?:真实代码 grep verify|Verify\ actual\ code:\ caller\ imports,\ module\ entries,\ tab\ configuration,\ and\ path\ conventions\.)',
  '(?:AC 数值有实证基础|Ground\ acceptance\ numbers\ in\ evidence)',
  '(?:内部一致性 cross-validate|Cross\-check\ consistency\ between\ procedural\ steps,\ hard\ acceptance\ constraints,\ and\ warnings\.)',
  '(?:分支名 main 不写 master|Use\ this\ project''s\ `main`\ branch\ name\ rather\ than\ `master`)',
  '(?:APK 历史大小有参考值|Use\ a\ measured\ historical\ APK\ size,\ not\ a\ guess\.)',
  '(?:提示词 ≤ 10 行|Keep\ the\ execution\ prompt\ at\ ten\ lines\ or\ fewer)',
  '(?:v3\.0 哲学新功能必加 settings 开关|Under\ philosophy\ v3\.0,\ new\ features\ require\ a\ settings\ toggle\ for\ user\ control)'
)) {
  Assert-Contains "操作系统\02_智能体\共享技能\handoff卡-verify清单.md" $needle "Handoff verification checklist mismatch"
}

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ Shared-skill safety anchors aligned" -ForegroundColor Green
exit 0
