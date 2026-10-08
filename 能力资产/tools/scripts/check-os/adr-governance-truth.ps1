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
  if ($normalized -eq '现行' -or $normalized -eq 'Current') { return 'current' }
  if (($normalized -match '被') -and ($normalized -match '(替代|覆盖)')) { return 'replaced' }
  if ($normalized -match '^(?:Partially )?Superseded by (?:ADR-\d{3}|the current structure)$') { return 'replaced' }
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
    $failures.Add("Docs/3-开发文档/adr is missing; cannot determine authoritative ADR counts")
  } else {
    $fileRecords = @(
      Get-ChildItem -LiteralPath $adrDir -Filter "ADR-*.md" -File -ErrorAction SilentlyContinue |
        ForEach-Object {
          $match = [regex]::Match($_.Name, '^ADR-(\d{3})-.+\.md$')
          if (-not $match.Success) {
            $failures.Add(("{0} does not follow the ADR-001-title.md filename format" -f (Get-CzxtAdrRelativePath $repoRoot $_.FullName)))
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
    $failures.Add("Docs/3-开发文档/adr/README.md is missing; cannot determine ADR index status")
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
      $failures.Add("No ADR index table rows found in Docs/3-开发文档/adr/README.md")
    }
  }

  foreach ($group in (@($fileRecords) | Group-Object Number | Where-Object { $_.Count -gt 1 })) {
    $paths = @($group.Group | ForEach-Object { $_.Path }) -join ", "
    $failures.Add("ADR-$($group.Name) has duplicate file numbers: $paths")
  }

  foreach ($group in (@($indexRecords) | Group-Object Number | Where-Object { $_.Count -gt 1 })) {
    $failures.Add("ADR-$($group.Name) appears $($group.Count) times in the ADR index table")
  }

  foreach ($record in @($indexRecords | Where-Object { $_.StatusClass -eq 'unknown' })) {
    $failures.Add("ADR-$($record.Number) has an unknown index status: $($record.Status); only current or superseded/replaced status is accepted")
  }

  $fileNumbers = @($fileRecords | ForEach-Object { $_.Number } | Sort-Object -Unique)
  $indexNumbers = @($indexRecords | ForEach-Object { $_.Number } | Sort-Object -Unique)

  foreach ($number in $fileNumbers) {
    if ($indexNumbers -notcontains $number) {
      $failures.Add("ADR-$number has a file but no index table row")
    }
  }

  foreach ($number in $indexNumbers) {
    if ($fileNumbers -notcontains $number) {
      $failures.Add("ADR-$number has an index table row but no ADR file")
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
    $failures.Add("$entryRelative is missing; cannot validate the ADR count entry")
    return @($failures)
  }

  $entryText = Get-Content -LiteralPath $entryPath -Raw -Encoding UTF8
  $pattern = '(?<total>\d+)\s*ADR\s*永久档案\s*（\s*(?<current>\d+)\s*现行\s*\+\s*(?<replaced>\d+)\s*被替代/覆盖\s*）'
  $match = [regex]::Match($entryText, $pattern)
  if (-not $match.Success) {
    $englishPattern = '(?<total>\d+)\s+permanent ADR records\s*\(\s*(?<current>\d+)\s+current\s*\+\s*(?<replaced>\d+)\s+superseded/overridden\s*\)'
    $match = [regex]::Match($entryText, $englishPattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
  }
  if (-not $match.Success) {
    $failures.Add("$entryRelative lacks the ADR count anchor: N permanent ADR records (N current + N superseded/replaced)")
    return @($failures)
  }

  $claimedTotal = [int]$match.Groups['total'].Value
  $claimedCurrent = [int]$match.Groups['current'].Value
  $claimedReplaced = [int]$match.Groups['replaced'].Value
  if ($claimedTotal -ne [int]$Truth.Total) {
    $failures.Add("$entryRelative ADR total mismatch: $claimedTotal vs authoritative count $($Truth.Total)")
  }
  if ($claimedCurrent -ne [int]$Truth.Current) {
    $failures.Add("$entryRelative current ADR count mismatch: $claimedCurrent vs authoritative count $($Truth.Current)")
  }
  if ($claimedReplaced -ne [int]$Truth.Replaced) {
    $failures.Add("$entryRelative superseded/replaced ADR count mismatch: $claimedReplaced vs authoritative count $($Truth.Replaced)")
  }

  return @($failures)
}
