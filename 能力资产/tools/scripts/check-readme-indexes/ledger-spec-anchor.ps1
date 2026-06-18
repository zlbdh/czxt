param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "缺少 anchor-common.ps1" }
. $common

function Assert-MarkdownLinksResolve {
  param([string]$Rel)

  $path = Join-Path $Root $Rel
  $text = Get-Text $Rel
  foreach ($m in [regex]::Matches($text, '\[[^\]]+\]\(([^)]+)\)')) {
    $target = $m.Groups[1].Value.Trim()
    if ($target -match '^(https?|mailto):') { continue }
    $withoutAnchor = ($target -split '#', 2)[0]
    if ([string]::IsNullOrWhiteSpace($withoutAnchor)) { continue }
    $targetPath = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $path) ($withoutAnchor -replace '/', '\')))
    if (-not $targetPath.StartsWith((Resolve-Path $Root).Path, [System.StringComparison]::OrdinalIgnoreCase)) {
      Add-Failure "$Rel 链接越界：$target"
    } elseif (-not (Test-Path -LiteralPath $targetPath)) {
      $line = ($text.Substring(0, $m.Index) -split "`n").Count
      Add-Failure "$Rel L$line 链接断链：$target"
    }
  }
}

Assert-Contains "操作系统\04_台账\INDEX.md" '版本总览指针（当前 v3\.52\.0；明细表阶段截至 v3\.8\.2）' "版本总览阶段边界"
Assert-Contains "操作系统\04_台账\INDEX.md" 'Sprint 总览指针（当前 {{CURRENT_SPRINT}}；明细表阶段截至 Sprint-7）' "Sprint 总览阶段边界"
Assert-Contains "操作系统\04_台账\INDEX.md" '阶段性快照，不追实时全量' "台账数据延迟边界"
Assert-Contains "操作系统\04_台账\INDEX.md" '项目沉淀/README\.md' "项目沉淀入口"

Assert-Contains "操作系统\04_台账\版本时间线.md" '阶段性快照 / 本表明细截至 2026-05-21' "版本时间线阶段性快照"
Assert-Contains "操作系统\04_台账\版本时间线.md" '当前生产 \*\*v3\.52\.0\*\*' "版本时间线当前版本"
Assert-Contains "操作系统\04_台账\版本时间线.md" '本表明细截至 v3\.8\.2' "版本时间线明细截至"

Assert-Contains "操作系统\04_台账\Sprint节奏.md" '阶段性快照 / 明细截至 2026-05-21' "Sprint 节奏阶段性快照"
Assert-Contains "操作系统\04_台账\Sprint节奏.md" '当前 \*\*{{CURRENT_SPRINT}}\*\*' "Sprint 节奏当前 Sprint"
Assert-Contains "操作系统\04_台账\Sprint节奏.md" 'Sprint-8 预告（历史快照 / 已收档，项目已进行至 {{CURRENT_SPRINT}}）' "Sprint-8 预告历史边界"

Assert-Contains "操作系统\04_台账\议题全景.md" '本文件是高频入口，不再承载全部历史表格' "议题全景入口化"
Assert-Contains "操作系统\04_台账\议题全景.md" '当前真源' "议题全景当前真源"
Assert-Contains "操作系统\04_台账\议题全景.md" '不为追当前数字改写旧快照采集时点' "议题全景不回填历史"
Assert-NotContains "操作系统\04_台账\议题全景.md" '(?m)^##\s*(一、永久关闭|二、永久关闭候选|六、PROP 当前状态|七、PM 自纠系列|八、议题编号约定)' "议题全景旧大表活化"

Assert-Contains "操作系统\04_台账\逐文件审计覆盖台账.md" '## 三、时点基线（非实时计数）' "覆盖台账时点基线"
Assert-Contains "操作系统\04_台账\逐文件审计覆盖台账.md" '操作系统/03_交接' "覆盖台账已登记 03"
Assert-Contains "操作系统\04_台账\逐文件审计覆盖台账.md" '操作系统/04_台账' "覆盖台账已登记 04"

Assert-Contains "操作系统\04_台账\项目沉淀\README.md" '未来候选沉淀产物（未建，非链接）' "项目沉淀候选非链接"
Assert-Contains "操作系统\04_台账\项目沉淀\README.md" '暂无数据时保持本入口，不虚构正文' "项目沉淀不虚构"
Assert-NotContains "操作系统\04_台账\项目沉淀\README.md" '\]\(' "项目沉淀候选不应是 Markdown 链接"

Assert-Contains "操作系统\04_台账\历史归档\2026-05\议题全景-2026-05-22-历史快照.md" '2026-05-22 快照口径' "议题历史快照口径"
Assert-Contains "操作系统\04_台账\历史归档\2026-05\议题全景-2026-05-22-历史快照.md" '不作为当前永久数/候选数单一信息源' "议题历史快照非当前真源"
Assert-Contains "操作系统\04_台账\历史归档\2026-05\议题全景-2026-05-22-历史快照.md" '当前 / 待 / 候选 / 下一个 / 载体 / 层级' "议题历史快照旧词边界"
Assert-MarkdownLinksResolve "操作系统\04_台账\历史归档\2026-05\议题全景-2026-05-22-历史快照.md"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 04_台账规格锚点对齐" -ForegroundColor Green
exit 0
