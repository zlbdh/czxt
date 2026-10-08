param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$items = @(
  @{ PM = "项目PM-咪咪"; Playbook = "操作系统\02_智能体\项目PM-咪咪.md" },
  @{ PM = "沉淀PM-沉淀者"; Playbook = "操作系统\02_智能体\沉淀PM-沉淀者.md" },
  @{ PM = "操作系统PM-框架管家"; Playbook = "操作系统\02_智能体\操作系统PM-框架管家.md" },
  @{ PM = "产品PM-需求拆解者"; Playbook = "操作系统\02_智能体\产品PM-需求拆解者.md" },
  @{ PM = "技术PM-修复决策者"; Playbook = "操作系统\02_智能体\技术PM-修复决策者.md" },
  @{ PM = "测试PM-质量门户"; Playbook = "操作系统\02_智能体\测试PM-质量门户.md" },
  @{ PM = "运营PM-运营咪咪"; Playbook = "操作系统\02_智能体\运营PM-运营咪咪.md" },
  @{ PM = "开发PM-实施者"; Playbook = "操作系统\02_智能体\开发PM-实施者.md" },
  @{ PM = "测试发布PM-闭环者"; Playbook = "操作系统\02_智能体\测试发布PM-闭环者.md" }
)

$failures = New-Object System.Collections.Generic.List[string]
foreach ($item in $items) {
  $path = Join-Path $Root $item.Playbook
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $failures.Add("$($item.Playbook) is missing")
    continue
  }
  $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  $workspace = "PM工作区/$($item.PM)/"
  if ($text -notmatch [regex]::Escape($workspace)) {
    $failures.Add("$($item.Playbook) does not explicitly link its own $workspace")
  }
}

if ($failures.Count -gt 0) {
  Write-Host "  🔴 PM playbook private-workspace entries are misaligned: $($failures.Count) matches" -ForegroundColor Red
  foreach ($failure in $failures) { Write-Host "    - $failure" -ForegroundColor Red }
  exit 10
}

Write-Host "  ✅ All nine PM playbooks link their own private workspaces" -ForegroundColor Green
exit 0
