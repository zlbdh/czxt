param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "Missing anchor-common.ps1" }
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
      Add-Failure "$Rel Link escapes root：$target"
    } elseif (-not (Test-Path -LiteralPath $targetPath)) {
      $line = ($text.Substring(0, $m.Index) -split "`n").Count
      Add-Failure "$Rel L$line Broken link：$target"
    }
  }
}

Assert-Contains "操作系统\04_台账\INDEX.md" '版本总览指针（当前 v3\.52\.0；明细表阶段截至 v3\.8\.2）|Version\ overview\ pointer\ \(current\ \{\{CURRENT_VERSION\}\};\ detailed\ snapshot\ through\ v3\.8\.2\)' "Version overview snapshot boundary"
Assert-Contains "操作系统\04_台账\INDEX.md" ('(?:Sprint 总览指针（当前 ' + [regex]::Escape('{{CURRENT_SPRINT}}') + '；明细表阶段截至 Sprint-7）|Sprint overview pointer \(current ' + [regex]::Escape('{{CURRENT_SPRINT}}') + '; detailed snapshot through Sprint-7\))') "Sprint overview snapshot boundary"
Assert-Contains "操作系统\04_台账\INDEX.md" '阶段性快照，不追实时全量|periodic\ snapshots,\ not\ exhaustive\ real\-time\ records' "Ledger data-lag boundary"
Assert-Contains "操作系统\04_台账\INDEX.md" '项目沉淀/README\.md' "Project-learning entry"

Assert-Contains "操作系统\04_台账\版本时间线.md" '阶段性快照 / 本表明细截至 2026-05-21|periodic\ snapshot\ /\ table\ details\ through\ 2026\-05\-21' "Version timeline periodic snapshot"
Assert-Contains "操作系统\04_台账\版本时间线.md" '当前生产 \*\*v3\.52\.0\*\*|current\ production\ \*\*\{\{CURRENT_VERSION\}\}\*\*' "Version timeline current version"
Assert-Contains "操作系统\04_台账\版本时间线.md" '本表明细截至 v3\.8\.2|table\ details\ through\ v3\.8\.2' "Version timeline detail cutoff"

Assert-Contains "操作系统\04_台账\Sprint节奏.md" '阶段性快照 / 明细截至 2026-05-21|periodic\ snapshot\ /\ details\ through\ 2026\-05\-21' "Sprint periodic snapshot"
Assert-Contains "操作系统\04_台账\Sprint节奏.md" ('(?:当前|current) \*\*' + [regex]::Escape('{{CURRENT_SPRINT}}') + '\*\*') "Current Sprint"
Assert-Contains "操作系统\04_台账\Sprint节奏.md" ('(?:Sprint-8 预告（历史快照 / 已收档，项目已进行至 ' + [regex]::Escape('{{CURRENT_SPRINT}}') + '）|Sprint-8 Preview \(historical snapshot / archived; project has reached ' + [regex]::Escape('{{CURRENT_SPRINT}}') + '\))') "Sprint-8 preview historical boundary"

Assert-Contains "操作系统\04_台账\议题全景.md" '本文件是高频入口，不再承载全部历史表格|This\ is\ a\ frequent\-use\ entry;\ it\ no\ longer\ contains\ every\ historical\ table\.' "Issue panorama entry boundary"
Assert-Contains "操作系统\04_台账\议题全景.md" '当前真源|Current\ sources\ of\ truth' "Issue panorama current sources"
Assert-Contains "操作系统\04_台账\议题全景.md" '不为追当前数字改写旧快照采集时点|Do\ not\ rewrite\ an\ old\ snapshot''s\ collection\ date\ to\ chase\ current\ numbers\.' "Issue panorama no historical backfill"
Assert-NotContains "操作系统\04_台账\议题全景.md" '(?m)^##\s*(一、永久关闭|二、永久关闭候选|六、PROP 当前状态|七、PM 自纠系列|八、议题编号约定|1\. Permanently closed|2\. Permanent-closure candidates|6\. Current PROP status|7\. PM self-correction series|8\. Issue-ID conventions)' "Issue panorama must not reactivate old large tables"

Assert-Contains "操作系统\04_台账\逐文件审计覆盖台账.md" '## 三、时点基线（非实时计数）|\#\#\ 3\.\ Point\-in\-time\ baselines\ —\ not\ live\ counts' "Coverage ledger point-in-time baseline"
Assert-Contains "操作系统\04_台账\逐文件审计覆盖台账.md" '操作系统/03_交接' "Coverage ledger registers section 03"
Assert-Contains "操作系统\04_台账\逐文件审计覆盖台账.md" '操作系统/04_台账' "Coverage ledger registers section 04"

Assert-Contains "操作系统\04_台账\项目沉淀\README.md" '未来候选沉淀产物（未建，非链接）|Future\ candidate\ artifacts\ —\ not\ created,\ not\ links' "Project-learning candidates are not links"
Assert-Contains "操作系统\04_台账\项目沉淀\README.md" '暂无数据时保持本入口，不虚构正文|When\ no\ data\ exists,\ retain\ this\ entry;\ do\ not\ invent\ body\ content\.' "Do not invent project learning"
Assert-NotContains "操作系统\04_台账\项目沉淀\README.md" '\]\(' "Project-learning candidates must not be Markdown links"

Assert-Contains "操作系统\04_台账\历史归档\2026-05\议题全景-2026-05-22-历史快照.md" '2026-05-22 快照口径' "Issue historical snapshot date"
Assert-Contains "操作系统\04_台账\历史归档\2026-05\议题全景-2026-05-22-历史快照.md" '不作为当前永久数/候选数单一信息源' "Issue historical snapshot is not current truth"
Assert-Contains "操作系统\04_台账\历史归档\2026-05\议题全景-2026-05-22-历史快照.md" '当前 / 待 / 候选 / 下一个 / 载体 / 层级' "Issue historical snapshot legacy terminology boundary"
Assert-MarkdownLinksResolve "操作系统\04_台账\历史归档\2026-05\议题全景-2026-05-22-历史快照.md"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ Ledger specification anchors aligned" -ForegroundColor Green
exit 0
