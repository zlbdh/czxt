$ErrorActionPreference = "Stop"

function Get-CzxtAdrRelativePath {
  param([string]$Root, [string]$FullPath)

  $base = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
  $full = [IO.Path]::GetFullPath($FullPath)
  if ($full.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) {
    return $full.Substring($base.Length).Replace('\', '/')
  }
  return $full
}

function Get-CzxtAdrStatusClass {
  param([string]$Status)

  $normalized = ($Status -replace '\s+', ' ').Trim()
  if ($normalized -eq '现行') { return 'current' }
  if (($normalized -match '被') -and ($normalized -match '(替代|覆盖)')) { return 'replaced' }
  return 'unknown'
}

function Get-CzxtAdrGovernanceTruth {
  param([string]$Root)

  $repoRoot = (Resolve-Path $Root).Path
  $adrDir = Join-Path $repoRoot "Docs/3-开发文档/adr"
  $indexPath = Join-Path $adrDir "README.md"
  $failures = New-Object System.Collections.Generic.List[string]
  $fileRecords = @()
  $indexRecords = @()

  if (-not (Test-Path -LiteralPath $adrDir -PathType Container)) {
    $failures.Add("Docs/3-开发文档/adr 缺失；无法计算 ADR 真源")
  } else {
    $fileRecords = @(
      Get-ChildItem -LiteralPath $adrDir -Filter "ADR-*.md" -File -ErrorAction SilentlyContinue |
        ForEach-Object {
          $match = [regex]::Match($_.Name, '^ADR-(\d{3})-.+\.md$')
          if (-not $match.Success) {
            $failures.Add(("{0} 文件名不符合 ADR-001-标题.md 格式" -f (Get-CzxtAdrRelativePath $repoRoot $_.FullName)))
            return
          }
          [pscustomobject]@{
            Number = $match.Groups[1].Value
            Path = (Get-CzxtAdrRelativePath $repoRoot $_.FullName)
          }
        }
    )
  }

  if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
    $failures.Add("Docs/3-开发文档/adr/README.md 缺失；无法计算 ADR 索引状态")
  } else {
    $indexText = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
    foreach ($line in ($indexText -split "`r?`n")) {
      $match = [regex]::Match($line, '^\|\s*ADR-(?<number>\d{3})\s*\|\s*(?<title>[^|]+)\|\s*(?<status>[^|]+)\|\s*(?<date>[^|]+)\|')
      if (-not $match.Success) { continue }
      $status = $match.Groups['status'].Value.Trim()
      $class = Get-CzxtAdrStatusClass -Status $status
      $indexRecords += [pscustomobject]@{
        Number = $match.Groups['number'].Value
        Status = $status
        StatusClass = $class
      }
    }
    if (@($indexRecords).Count -eq 0) {
      $failures.Add("Docs/3-开发文档/adr/README.md 未找到 ADR 索引表行")
    }
  }

  foreach ($group in (@($fileRecords) | Group-Object Number | Where-Object { $_.Count -gt 1 })) {
    $paths = @($group.Group | ForEach-Object { $_.Path }) -join ", "
    $failures.Add("ADR-$($group.Name) 文件编号重复：$paths")
  }

  foreach ($group in (@($indexRecords) | Group-Object Number | Where-Object { $_.Count -gt 1 })) {
    $failures.Add("ADR-$($group.Name) 在 ADR 索引表中重复出现 $($group.Count) 次")
  }

  foreach ($record in @($indexRecords | Where-Object { $_.StatusClass -eq 'unknown' })) {
    $failures.Add("ADR-$($record.Number) 索引状态未知：$($record.Status)；只接受 现行 或 被替代/覆盖")
  }

  $fileNumbers = @($fileRecords | ForEach-Object { $_.Number } | Sort-Object -Unique)
  $indexNumbers = @($indexRecords | ForEach-Object { $_.Number } | Sort-Object -Unique)

  foreach ($number in $fileNumbers) {
    if ($indexNumbers -notcontains $number) {
      $failures.Add("ADR-$number 有文件但缺少索引表行")
    }
  }

  foreach ($number in $indexNumbers) {
    if ($fileNumbers -notcontains $number) {
      $failures.Add("ADR-$number 有索引表行但缺少 ADR 文件")
    }
  }

  $currentCount = @($indexRecords | Where-Object { $_.StatusClass -eq 'current' }).Count
  $replacedCount = @($indexRecords | Where-Object { $_.StatusClass -eq 'replaced' }).Count
  $totalCount = @($indexRecords).Count

  [pscustomobject]@{
    Total = $totalCount
    Current = $currentCount
    Replaced = $replacedCount
    Text = ("{0}/{1}/{2}" -f $totalCount, $currentCount, $replacedCount)
    IsValid = ($failures.Count -eq 0)
    Failures = @($failures)
  }
}

function Test-CzxtAdrMainEntryAnchor {
  param(
    [string]$Root,
    [pscustomobject]$Truth
  )

  $repoRoot = (Resolve-Path $Root).Path
  $entryRelative = "操作系统/00_总入口.md"
  $entryPath = Join-Path $repoRoot $entryRelative
  $failures = New-Object System.Collections.Generic.List[string]
  if (-not (Test-Path -LiteralPath $entryPath -PathType Leaf)) {
    $failures.Add("$entryRelative 缺失；无法校验 ADR 计数入口")
    return @($failures)
  }

  $entryText = Get-Content -LiteralPath $entryPath -Raw -Encoding UTF8
  $pattern = '(?<total>\d+)\s*ADR\s*永久档案\s*（\s*(?<current>\d+)\s*现行\s*\+\s*(?<replaced>\d+)\s*被替代/覆盖\s*）'
  $match = [regex]::Match($entryText, $pattern)
  if (-not $match.Success) {
    $failures.Add("$entryRelative 未找到 ADR 计数锚点：N ADR 永久档案（N 现行 + N 被替代/覆盖）")
    return @($failures)
  }

  $claimedTotal = [int]$match.Groups['total'].Value
  $claimedCurrent = [int]$match.Groups['current'].Value
  $claimedReplaced = [int]$match.Groups['replaced'].Value
  if ($claimedTotal -ne [int]$Truth.Total) {
    $failures.Add("$entryRelative ADR 总数漂移：$claimedTotal vs 真源 $($Truth.Total)")
  }
  if ($claimedCurrent -ne [int]$Truth.Current) {
    $failures.Add("$entryRelative ADR 现行数漂移：$claimedCurrent vs 真源 $($Truth.Current)")
  }
  if ($claimedReplaced -ne [int]$Truth.Replaced) {
    $failures.Add("$entryRelative ADR 被替代/覆盖数漂移：$claimedReplaced vs 真源 $($Truth.Replaced)")
  }

  return @($failures)
}
