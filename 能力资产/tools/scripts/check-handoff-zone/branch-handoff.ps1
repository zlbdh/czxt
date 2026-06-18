function Get-BranchHandoffIssues {
  param(
    [Parameter(Mandatory=$true)][string]$Root,
    [int]$MaxPending = 3,
    [int]$OldPendingDays = 30
  )

  $branchRoot = Join-Path $Root "交接区\分支间"
  $expectedDirs = @(
    "项目PM→运营咪咪\待处理",
    "项目PM→运营咪咪\已处理",
    "运营咪咪→项目PM\待处理",
    "运营咪咪→项目PM\已处理"
  )

  $issues = @()
  $warnings = @()
  $pendingCards = @()
  $processedCards = @()

  $readmePath = Join-Path $Root "交接区\README.md"
  if (Test-Path -LiteralPath $readmePath -PathType Leaf) {
    $readmeText = Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8
    foreach ($needle in @("分支间/", "项目PM→运营咪咪", "运营咪咪→项目PM", "待处理/", "已处理/")) {
      if ($readmeText -notmatch ([regex]::Escape($needle))) {
        $issues += [pscustomobject]@{ File = "交接区\README.md"; Issue = "分支间结构说明缺少：$needle" }
      }
    }
    if ($readmeText -match "Dev到QA|QA到zlbdh|PM到Dev") {
      $issues += [pscustomobject]@{ File = "交接区\README.md"; Issue = "文件命名示例仍使用旧 Dev/QA/PM 工具流口径" }
    }
  } else {
    $issues += [pscustomobject]@{ File = "交接区\README.md"; Issue = "交接区 README 缺失" }
  }

  if (-not (Test-Path -LiteralPath $branchRoot -PathType Container)) {
    $issues += [pscustomobject]@{ File = "交接区\分支间"; Issue = "分支间交接根目录缺失" }
    return [pscustomobject]@{ Issues = @($issues); Warnings = @($warnings); Pending = @(); Processed = @() }
  }

  foreach ($relativeDir in $expectedDirs) {
    $dir = Join-Path $branchRoot $relativeDir
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
      $issues += [pscustomobject]@{ File = "交接区\分支间\$relativeDir"; Issue = "分支间交接目录缺失" }
      continue
    }

    $cards = @(Get-ChildItem -LiteralPath $dir -File -Filter "*.md" -ErrorAction SilentlyContinue)
    if ($relativeDir -like "*\待处理") {
      $pendingCards += $cards
    } else {
      $processedCards += $cards
    }
  }

  if ($pendingCards.Count -gt $MaxPending) {
    $issues += [pscustomobject]@{ File = "交接区\分支间"; Issue = "分支间待处理卡 $($pendingCards.Count) 张，超过上限 $MaxPending" }
  }

  $threshold = (Get-Date).AddDays(-1 * $OldPendingDays)
  foreach ($card in $pendingCards) {
    $sortValue = Get-HandoffSortValue $card
    if ($sortValue -lt $threshold) {
      $issues += [pscustomobject]@{ File = $card.FullName; Issue = "分支间待处理卡超过 $OldPendingDays 天未处理" }
    }
  }

  return [pscustomobject]@{
    Issues = @($issues)
    Warnings = @($warnings)
    Pending = @($pendingCards)
    Processed = @($processedCards)
  }
}
