$ErrorActionPreference = 'Stop'

function global:Get-BorrowingP4tSafeSourceInventory {
  param([string]$SourcesPath, $Failures)
  $captures = New-Object 'Collections.Generic.List[object]'
  try {
    [void](Get-BorrowingSafePathInfo $SourcesPath Directory p4t-source source-unsafe)
    $sourceEntries = @(Get-ChildItem -LiteralPath $SourcesPath -Force -ErrorAction Stop)
  }
  catch {
    Add-BorrowingP4tSourceIssue $Failures '借鉴区来源目录缺失或不安全'
    return $captures.ToArray()
  }

  foreach ($sourceEntry in $sourceEntries) {
    if (-not $sourceEntry.PSIsContainer) {
      try {
        $info = Get-BorrowingSafePathInfo $sourceEntry.FullName File p4t-source source-unsafe
        if ($sourceEntry.Name -cne '.gitkeep' -or [uint64]$info.Length -ne 0) {
          throw 'unexpected source-root file'
        }
      }
      catch { Add-BorrowingP4tSourceIssue $Failures ('来源区含非法成员：' + $sourceEntry.Name) }
      continue
    }

    try {
      [void](Get-BorrowingSafePathInfo $sourceEntry.FullName Directory p4t-source source-unsafe)
      [void](Assert-BcvIdentifier $sourceEntry.Name)
      $captureEntries = @(Get-ChildItem -LiteralPath $sourceEntry.FullName -Force -ErrorAction Stop)
    }
    catch {
      Add-BorrowingP4tSourceIssue $Failures ('来源目录无效：' + $sourceEntry.Name)
      continue
    }
    foreach ($captureEntry in $captureEntries) {
      if (-not $captureEntry.PSIsContainer) {
        try { [void](Get-BorrowingSafePathInfo $captureEntry.FullName File p4t-source source-unsafe) }
        catch {}
        Add-BorrowingP4tSourceIssue $Failures `
          ('来源目录含非 capture 成员：' + $sourceEntry.Name + '/' + $captureEntry.Name)
        continue
      }
      try {
        [void](Get-BorrowingSafePathInfo $captureEntry.FullName Directory p4t-source source-unsafe)
      }
      catch {
        Add-BorrowingP4tSourceIssue $Failures `
          ('来源 capture 路径不安全：' + $sourceEntry.Name + '/' + $captureEntry.Name)
        continue
      }
      if ($captureEntry.Name -cmatch '\A\.staging-[0-9a-f]{32}\z') { continue }
      if ($captureEntry.Name.StartsWith('.staging-', [StringComparison]::Ordinal)) {
        Add-BorrowingP4tSourceIssue $Failures `
          ('来源 staging 名称非法：' + $sourceEntry.Name + '/' + $captureEntry.Name)
        continue
      }
      [void]$captures.Add([pscustomobject]@{
          SourceName = $sourceEntry.Name
          CaptureDirectory = $captureEntry.FullName
          CaptureName = $captureEntry.Name
        })
    }
  }
  return $captures.ToArray()
}

function global:Get-BorrowingP4tSafeSourceCards {
  param([string]$CaptureDirectory)
  $cards = New-Object 'Collections.Generic.List[object]'
  $pending = New-Object 'Collections.Generic.Queue[string]'
  $pending.Enqueue($CaptureDirectory)
  while ($pending.Count -gt 0) {
    $directory = $pending.Dequeue()
    [void](Get-BorrowingSafePathInfo $directory Directory p4t-source source-unsafe)
    foreach ($entry in @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
      $kind = if ($entry.PSIsContainer) { 'Directory' } else { 'File' }
      [void](Get-BorrowingSafePathInfo $entry.FullName $kind p4t-source source-unsafe)
      if ($entry.PSIsContainer) { $pending.Enqueue($entry.FullName) }
      elseif ($entry.Name -ceq '来源版本卡.md') { [void]$cards.Add($entry) }
    }
  }
  return $cards.ToArray()
}
