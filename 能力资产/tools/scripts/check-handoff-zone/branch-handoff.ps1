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
        $issues += [pscustomobject]@{ File = "交接区\README.md"; Issue = "Cross-branch structure instructions are missing: $needle" }
      }
    }
    if ($readmeText -match "Dev到QA|QA到zlbdh|PM到Dev") {
      $issues += [pscustomobject]@{ File = "交接区\README.md"; Issue = "Filename examples still use the obsolete Dev/QA/PM tool-flow terminology" }
    }
  } else {
    $issues += [pscustomobject]@{ File = "交接区\README.md"; Issue = "Handoff area README is missing" }
  }

  if (-not (Test-Path -LiteralPath $branchRoot -PathType Container)) {
    $issues += [pscustomobject]@{ File = "交接区\分支间"; Issue = "Cross-branch handoff root directory is missing" }
    return [pscustomobject]@{ Issues = @($issues); Warnings = @($warnings); Pending = @(); Processed = @() }
  }

  foreach ($relativeDir in $expectedDirs) {
    $dir = Join-Path $branchRoot $relativeDir
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
      $issues += [pscustomobject]@{ File = "交接区\分支间\$relativeDir"; Issue = "Cross-branch handoff directory is missing" }
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
    $issues += [pscustomobject]@{ File = "交接区\分支间"; Issue = "There are $($pendingCards.Count) pending cross-branch cards, exceeding the limit $MaxPending" }
  }

  $threshold = (Get-Date).AddDays(-1 * $OldPendingDays)
  foreach ($card in $pendingCards) {
    $sortValue = Get-HandoffSortValue $card
    if ($sortValue -lt $threshold) {
      $issues += [pscustomobject]@{ File = $card.FullName; Issue = "Cross-branch pending card has remained unprocessed for more than $OldPendingDays days" }
    }
  }

  return [pscustomobject]@{
    Issues = @($issues)
    Warnings = @($warnings)
    Pending = @($pendingCards)
    Processed = @($processedCards)
  }
}
