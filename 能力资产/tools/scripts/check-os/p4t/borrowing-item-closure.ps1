$ErrorActionPreference = 'Stop'

function global:Test-BpiSectionEvidence {
  param([string[]]$Lines, [string[]]$Forbidden)
  foreach ($line in $Lines) {
    if (-not $line.StartsWith('- ', [StringComparison]::Ordinal)) { continue }
    $content = $line.Substring(2)
    if ([string]::IsNullOrWhiteSpace($content) -or $content -cne $content.Trim()) {
      continue
    }
    $rejected = $false
    foreach ($value in $Forbidden) {
      if ($line.IndexOf($value, [StringComparison]::Ordinal) -ge 0) { $rejected = $true }
    }
    if (-not $rejected) { return $true }
  }
  return $false
}

function global:Assert-BpiSafeTargetRow {
  param([string]$Root, $Row)
  [string[]]$cells = $Row.Cells
  if ($cells[0] -ceq '待填写' -or $cells[0] -match '^[A-Za-z]:|^[/\\]|(^|/)\.\.(/|$)' -or
      $cells[2] -notin @('L1', 'L2', 'L3', 'L4')) { throw 'item target row invalid' }
  $target = [IO.Path]::GetFullPath((Join-Path $Root $cells[0].Replace('/', '\')))
  $prefix = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
  if (-not $target.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'item target escapes root'
  }
  $borrowingRoot = [IO.Path]::GetFullPath((Join-Path $Root '借鉴区')).TrimEnd('\')
  if ($target.Equals($borrowingRoot, [StringComparison]::OrdinalIgnoreCase) -or
      $target.StartsWith(
        $borrowingRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'item target cannot be inside borrowing zone'
  }
  $targetInfo = Get-BorrowingSafePathInfo $target File p4t-item source-unsafe
  if (-not $targetInfo.CanonicalPath.Equals(
      $target, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'item target canonical path mismatch'
  }
}

function global:Get-BpiStableClosureBytes {
  param([string]$Path)
  $before = Get-BorrowingSafePathInfo $Path File p4t-item source-unsafe
  [byte[]]$bytes = Read-BorrowingStableSafeFileBytes `
    $before.CanonicalPath p4t-item source-unsafe
  $after = Get-BorrowingSafePathInfo $before.CanonicalPath File p4t-item source-unsafe
  if ($before.IdentityKey -cne $after.IdentityKey -or
      [uint64]$before.Length -ne [uint64]$after.Length -or
      [uint64]$after.Length -ne [uint64]$bytes.LongLength) {
    throw 'closure file changed while reading'
  }
  return $bytes
}

function global:Get-BpiTargetManifestSha256 {
  param($Card, [string]$Root)
  $records = New-Object 'Collections.Generic.List[string]'
  foreach ($row in $Card.TargetRows) {
    [string]$relative = $row.Cells[0].Replace('\', '/')
    $target = [IO.Path]::GetFullPath((Join-Path $Root $relative.Replace('/', '\')))
    [byte[]]$bytes = Get-BpiStableClosureBytes $target
    $hash = Get-BorrowingSha256Hex $bytes
    [void]$records.Add($relative + "`t" + $hash + "`n")
  }
  [string[]]$ordered = $records.ToArray()
  [Array]::Sort($ordered, [StringComparer]::Ordinal)
  $manifest = $ordered -join ''
  return Get-BorrowingSha256Hex ([Text.Encoding]::UTF8.GetBytes($manifest))
}

function global:Get-BpiCanonicalEvidenceBytes {
  param(
    $Card, [string]$Root, [string]$Time,
    [string]$Command, [string]$Exit
  )
  $commandHash = Get-BorrowingSha256Hex ([Text.Encoding]::UTF8.GetBytes($Command))
  $targetManifestHash = Get-BpiTargetManifestSha256 $Card $Root
  $text = (@(
      'schema=borrowing-evidence/v1'
      ('time=' + $Time)
      ('command_sha256=' + $commandHash)
      ('exit=' + $Exit)
      ('target_manifest_sha256=' + $targetManifestHash)
    ) -join "`n") + "`n"
  return [Text.Encoding]::UTF8.GetBytes($text)
}

function global:Assert-BpiFreshEvidencePath {
  param($Card, [string]$RelativePath, [byte[]]$ExpectedBytes)
  $uri = $null
  if ([Uri]::TryCreate($RelativePath, [UriKind]::Absolute, [ref]$uri) -or
      -not (Test-BpiEvidenceLocator $RelativePath)) {
    throw 'fresh evidence path is not a safe relative path'
  }
  foreach ($segment in $RelativePath.Split('/')) {
    if ($segment.StartsWith('.staging-', [StringComparison]::OrdinalIgnoreCase)) {
      throw 'fresh evidence cannot use staging content'
    }
  }
  $itemRoot = [IO.Path]::GetFullPath((Split-Path -Parent $Card.Path)).TrimEnd('\')
  $evidence = [IO.Path]::GetFullPath(
    (Join-Path $itemRoot $RelativePath.Replace('/', '\')))
  if (-not $evidence.StartsWith(
      $itemRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'fresh evidence path escapes item root'
  }
  $evidenceInfo = Get-BorrowingSafePathInfo $evidence File p4t-item source-unsafe
  if (-not $evidenceInfo.CanonicalPath.Equals(
      $evidence, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'fresh evidence canonical path mismatch'
  }
  [byte[]]$actualBytes = Get-BpiStableClosureBytes $evidenceInfo.CanonicalPath
  if ($actualBytes.LongLength -eq 0) { throw 'fresh evidence file is empty' }
  if (-not (Test-BcvBytesEqual $actualBytes $ExpectedBytes)) {
    throw 'fresh evidence machine record does not bind verification facts'
  }
}

function global:Assert-BpiFreshEvidenceContract {
  param($Card, [string]$Root)
  $created = ConvertFrom-BpiOffsetTime $Card.CreatedAt
  $updated = ConvertFrom-BpiOffsetTime $Card.UpdatedAt
  $verifying = $null
  foreach ($row in $Card.HistoryRows) {
    [string[]]$cells = $row.Cells
    if ($cells[2] -ceq 'verifying' -and $cells[1] -cne 'verifying') {
      $entry = ConvertFrom-BpiOffsetTime $cells[0]
      if ($null -eq $verifying -or $entry -gt $verifying) { $verifying = $entry }
    }
  }
  if ($null -eq $verifying) { throw 'fresh evidence lacks verifying transition' }
  $count = 0
  foreach ($line in $Card.Sections['## fresh 验证证据']) {
    if (-not $line.StartsWith('- ', [StringComparison]::Ordinal)) { continue }
    $pattern = '\A- time=(?<time>[^;]+); command=(?<command>[^;]+); ' +
      'exit=(?<exit>[0-9]+); evidence=(?<evidence>[^;]+)\z'
    $match = [regex]::Match($line, $pattern)
    if (-not $match.Success) { throw 'fresh evidence record format invalid' }
    $time = ConvertFrom-BpiOffsetTime $match.Groups['time'].Value
    $command = $match.Groups['command'].Value
    if ($time -lt $created -or $time -lt $verifying -or $time -gt $updated -or
        $command -cne $command.Trim() -or
        -not (Test-BpiSafeScalar $command)) {
      throw 'fresh evidence time or command invalid'
    }
    if ($match.Groups['exit'].Value -cne '0') {
      throw 'fresh evidence exit is not successful'
    }
    [byte[]]$expected = Get-BpiCanonicalEvidenceBytes $Card $Root `
      $match.Groups['time'].Value $command $match.Groups['exit'].Value
    Assert-BpiFreshEvidencePath $Card $match.Groups['evidence'].Value $expected
    [byte[]]$confirmed = Get-BpiCanonicalEvidenceBytes $Card $Root `
      $match.Groups['time'].Value $command $match.Groups['exit'].Value
    if (-not (Test-BcvBytesEqual $expected $confirmed)) {
      throw 'fresh evidence target manifest changed while validating'
    }
    $count++
  }
  if ($count -eq 0) { throw 'fresh evidence record missing' }
}

function global:Get-BpiClosureSeal {
  param([string]$Text)
  $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n") + "`n"
  $pattern = '(?m)^closure_seal_sha256:.*$'
  if ([regex]::Matches($normalized, $pattern).Count -ne 1) {
    throw 'item seal line count invalid'
  }
  $blank = [regex]::Replace($normalized, $pattern, 'closure_seal_sha256: ""', 1)
  return Get-BorrowingSha256Hex ([Text.Encoding]::UTF8.GetBytes($blank))
}

function global:Assert-BpiClosureContract {
  param($Card, [string]$Root, [switch]$AllowEmptyClosedSeal)
  if ($Card.Status -ceq 'closed') {
    if ($Card.Decision -in @('adopt', 'adapt')) {
      foreach ($row in $Card.TargetRows) { Assert-BpiSafeTargetRow $Root $row }
      if (-not (Test-BpiSectionEvidence $Card.Sections['## 明确采纳'] @('待填写')) -or
          -not (Test-BpiSectionEvidence $Card.Sections['## 实施记录'] @('当前尚未实施', '待填写')) -or
          -not (Test-BpiSectionEvidence $Card.Sections['## fresh 验证证据'] @('当前尚无', '待填写'))) {
        throw 'closed adopt/adapt evidence is incomplete'
      }
      Assert-BpiFreshEvidenceContract $Card $Root
    }
    elseif ($Card.Decision -ceq 'reject') {
      foreach ($row in $Card.CandidateRows) {
        if ($row.Cells[4] -ceq '待填写') { throw 'closed reject assessment evidence missing' }
      }
      if (-not (Test-BpiSectionEvidence $Card.Sections['## 明确不采纳'] @(
              '待填写', '无其他排除项', '恢复条件', '复查时间'))) {
        throw 'closed reject reason missing'
      }
    }
    if ($Card.ClosureSeal.Length -eq 0) {
      if (-not $AllowEmptyClosedSeal) { throw 'closed item seal missing' }
    }
    elseif ($Card.ClosureSeal -cne (Get-BpiClosureSeal $Card.Text)) {
      throw 'closed item seal stale'
    }
  }
  elseif ($Card.ClosureSeal.Length -gt 0) { throw 'active item contains closure seal' }
  if ($Card.Status -ceq 'parked') {
    $hasResume = $false
    foreach ($line in $Card.Sections['## 明确不采纳']) {
      if (($line.Contains('恢复条件') -or $line.Contains('复查时间')) -and
          -not $line.Contains('当前没有') -and -not $line.Contains('待填写')) {
        $hasResume = $true
      }
    }
    if (-not $hasResume) { throw 'parked item resume condition missing' }
  }
}
