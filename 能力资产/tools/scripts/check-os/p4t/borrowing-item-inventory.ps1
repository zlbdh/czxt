$ErrorActionPreference = 'Stop'

function global:Add-BpiFailure {
  param($Failures, [string]$Message)
  if (-not $Failures.Contains($Message)) { [void]$Failures.Add($Message) }
}

function global:Assert-BpiCloseStagingDirectory {
  param([IO.DirectoryInfo]$Directory)
  if ($Directory.Name -cnotmatch '\A\.staging-close-[0-9a-f]{32}\z') {
    throw 'item staging name invalid'
  }
  $expected = @{
    '原活动卡.bin' = 'File'
    '借鉴卡.md' = 'File'
  }
  $entries = @(Get-ChildItem -LiteralPath $Directory.FullName -Force -ErrorAction Stop)
  if ($entries.Count -ne $expected.Count) { throw 'item close staging members invalid' }
  foreach ($entry in $entries) {
    if (-not $expected.ContainsKey($entry.Name) -or $entry.PSIsContainer) {
      throw 'item close staging member invalid'
    }
    [void](Get-BorrowingSafePathInfo $entry.FullName File p4t-item source-unsafe)
  }
}

function global:Get-BpiSafeItemCards {
  param([string]$ItemDirectory)
  $cards = New-Object 'Collections.Generic.List[string]'
  $pending = New-Object 'Collections.Generic.Queue[string]'
  $pending.Enqueue($ItemDirectory)
  while ($pending.Count -gt 0) {
    $current = $pending.Dequeue()
    [void](Get-BorrowingSafePathInfo $current Directory p4t-item source-unsafe)
    foreach ($entry in @(Get-ChildItem -LiteralPath $current -Force)) {
      $kind = if ($entry.PSIsContainer) { 'Directory' } else { 'File' }
      [void](Get-BorrowingSafePathInfo $entry.FullName $kind p4t-item source-unsafe)
      if ($entry.PSIsContainer -and
          $entry.Name.StartsWith('.staging-', [StringComparison]::Ordinal)) {
        Assert-BpiCloseStagingDirectory $entry
        continue
      }
      if ($entry.PSIsContainer) { $pending.Enqueue($entry.FullName) }
      elseif ($entry.Name -ceq '借鉴卡.md') { [void]$cards.Add($entry.FullName) }
    }
  }
  return $cards.ToArray()
}

function global:Get-BpiItemInventory {
  param([string]$Root, $Failures)
  $items = New-Object 'Collections.Generic.List[object]'
  $zone = Join-Path $Root '借鉴区\事项'
  try { [void](Get-BorrowingSafePathInfo $zone Directory p4t-item source-unsafe) }
  catch {
    Add-BpiFailure $Failures '借鉴区事项目录缺失或不安全'
    return $items.ToArray()
  }
  foreach ($entry in @(Get-ChildItem -LiteralPath $zone -Force)) {
    if (-not $entry.PSIsContainer) {
      if (-not $entry.Name.StartsWith('.', [StringComparison]::Ordinal)) {
        Add-BpiFailure $Failures ('事项区含非目录成员：' + $entry.Name)
      }
      continue
    }
    try {
      [void](Get-BorrowingSafePathInfo $entry.FullName Directory p4t-item source-unsafe)
      [string[]]$cards = @(Get-BpiSafeItemCards $entry.FullName)
      $expected = Join-Path $entry.FullName '借鉴卡.md'
      if ($cards.Count -ne 1 -or
          -not $cards[0].Equals($expected, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'item card count or location invalid'
      }
      $card = Read-BpiItemCard $cards[0]
      if ($card.BorrowId -cne $entry.Name) { throw 'item directory id mismatch' }
      [void]$items.Add($card)
    }
    catch { Add-BpiFailure $Failures ('借鉴事项无效：' + $entry.Name) }
  }
  $byId = @{}
  foreach ($card in $items) {
    if ($byId.ContainsKey($card.BorrowId)) {
      Add-BpiFailure $Failures ('borrow_id 重复：' + $card.BorrowId)
    }
    else { $byId[$card.BorrowId] = $card }
  }
  return $items.ToArray()
}

function global:Get-BpiRootMode {
  param([string]$Root)
  $template = Test-Path -LiteralPath (Join-Path $Root '.czxt-template-root') -PathType Leaf
  $project = Test-Path -LiteralPath (Join-Path $Root '.czxt-project-root') -PathType Leaf
  if ($template -and $project) { return 'conflict' }
  if ($template) { return 'template' }
  if ($project) { return 'project' }
  return 'unknown'
}
