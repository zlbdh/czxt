$ErrorActionPreference = 'Stop'

function global:Get-BlcPolicy {
  param([string]$Phase)
  switch -CaseSensitive ($Phase) {
    'source-before' { return [pscustomobject]@{ Stage = 'input'; Unsafe = 'source-boundary'; Io = 'source-boundary' } }
    'source-after' { return [pscustomobject]@{ Stage = 'capture'; Unsafe = 'source-unsafe'; Io = 'capture-failed' } }
    'staging-content' { return [pscustomobject]@{ Stage = 'capture'; Unsafe = 'source-unsafe'; Io = 'capture-failed' } }
    'promoted-content' { return [pscustomobject]@{ Stage = 'promotion'; Unsafe = 'source-unsafe'; Io = 'promotion-failed' } }
    default { Throw-BorrowingFailure input invalid-parameters 'Local phase is invalid' }
  }
}

function global:Test-BlcKnownFailure {
  param($Exception)
  return $null -ne $Exception -and
    -not [string]::IsNullOrEmpty([string]$Exception.Data['BorrowingStage']) -and
    -not [string]::IsNullOrEmpty([string]$Exception.Data['BorrowingReasonCode'])
}

function global:Test-BlcBytesEqual {
  param([byte[]]$Left, [byte[]]$Right)
  if ($null -eq $Left -or $null -eq $Right -or $Left.Length -ne $Right.Length) { return $false }
  for ($i = 0; $i -lt $Left.Length; $i++) { if ($Left[$i] -ne $Right[$i]) { return $false } }
  return $true
}

function global:New-BorrowingProductionLocalOperations {
  return [pscustomobject][ordered]@{
    GetSafePathInfo = { param($Path, $Kind, $Stage, $Reason) Get-BorrowingSafePathInfo $Path $Kind $Stage $Reason }
    GetChildren = { param($Path) Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction Stop }
    ReadAllBytes = { param($Path) return ,([IO.File]::ReadAllBytes($Path)) }
    CopyFile = {
      param($SourcePath, $DestinationPath, [byte[]]$ExpectedBytes)
      if ($null -eq $ExpectedBytes) {
        Throw-BorrowingFailure capture source-unsafe 'Local bound source bytes are missing'
      }
      [IO.File]::WriteAllBytes($DestinationPath, $ExpectedBytes)
    }
    WriteAllBytes = { param($Path, [byte[]]$Bytes) [IO.File]::WriteAllBytes($Path, $Bytes) }
    CreateDirectory = { param($Path) [void][IO.Directory]::CreateDirectory($Path) }
    MoveDirectory = { param($SourcePath, $DestinationPath) [IO.Directory]::Move($SourcePath, $DestinationPath) }
  }
}

function global:Get-BorrowingLocalSnapshot {
  param($Path, $Phase, $Operations)
  $policy = Get-BlcPolicy $Phase
  try {
    if ($null -eq $Operations) { Throw-BorrowingFailure input invalid-parameters 'Local operations are missing' }
    $safe = $Operations.GetSafePathInfo
    $children = $Operations.GetChildren
    $root = & $safe $Path Directory $policy.Stage $policy.Unsafe
    $byPath = New-Object 'Collections.Generic.Dictionary[string,object]' ([StringComparer]::Ordinal)
    $total = [int64]0
    foreach ($item in @(& $children $root.CanonicalPath)) {
      $kind = if ($item.PSIsContainer) { 'Directory' } else { 'File' }
      $info = & $safe $item.FullName $kind $policy.Stage $policy.Unsafe
      if ($kind -eq 'Directory') { continue }
      if (-not $info.CanonicalPath.StartsWith($root.CanonicalPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        Throw-BorrowingFailure $policy.Stage $policy.Unsafe 'Local path escaped its source root'
      }
      $relative = $info.CanonicalPath.Substring($root.CanonicalPath.Length + 1).Replace('\', '/')
      try { $relative = $relative.Normalize([Text.NormalizationForm]::FormC) }
      catch { Throw-BorrowingFailure $policy.Stage $policy.Unsafe 'Local relative path is invalid' }
      if ([string]::IsNullOrEmpty($relative) -or [IO.Path]::IsPathRooted($relative) -or
          $relative -match '(^|/)(?:\.|\.\.)(?:/|$)|[\t\r\n]') {
        Throw-BorrowingFailure $policy.Stage $policy.Unsafe 'Local relative path is invalid'
      }
      if ($byPath.ContainsKey($relative)) { Throw-BorrowingFailure $policy.Stage $policy.Unsafe 'Local paths collide' }
      if ([Text.Encoding]::UTF8.GetByteCount($relative) -gt 1024 -or
          $relative.Split([char]'/').Count -gt 64) {
        Throw-BorrowingFailure $policy.Stage resource-limit 'Local path limit exceeded'
      }
      $length = [uint64]$info.Length
      if ($length -gt 67108864 -or $length -gt [uint64][int64]::MaxValue -or
          $total -gt (536870912 - [int64]$length)) {
        Throw-BorrowingFailure $policy.Stage resource-limit 'Local byte limit exceeded'
      }
      if ($Phase -ceq 'staging-content' -and
          $null -ne $Operations.ReadAllBytes) {
        $readBytes = $Operations.ReadAllBytes
        [byte[]]$bytes = & $readBytes $info.CanonicalPath
        if ($bytes.LongLength -ne [int64]$length) {
          Throw-BorrowingFailure $policy.Stage $policy.Unsafe `
            'Local staged file length changed'
        }
      }
      else {
        $snapshot = Read-BorrowingStableSafeFileSnapshot `
          $info.CanonicalPath $policy.Stage $policy.Unsafe
        if (-not (Test-BorrowingTrustedSnapshotEqual $info $snapshot)) {
          Throw-BorrowingFailure $policy.Stage $policy.Unsafe `
            'Local file changed while reading'
        }
        [byte[]]$bytes = $snapshot.Bytes
      }
      $total += [int64]$length
      $entry = [ordered]@{
          RelativePath = $relative; CanonicalPath = $info.CanonicalPath
          IdentityKey = $info.IdentityKey; NumberOfLinks = [uint32]$info.NumberOfLinks
          Length = [int64]$length; Sha256 = Get-BorrowingSha256Hex -Bytes $bytes
        }
      if ($Phase -ceq 'source-before') { $entry['Bytes'] = $bytes }
      $byPath.Add($relative, [pscustomobject]$entry)
      if ($byPath.Count -gt 10000) { Throw-BorrowingFailure $policy.Stage resource-limit 'Local leaf limit exceeded' }
    }
    $rootAfter = & $safe $root.CanonicalPath Directory $policy.Stage $policy.Unsafe
    if ($rootAfter.IdentityKey -cne $root.IdentityKey) {
      Throw-BorrowingFailure $policy.Stage $policy.Unsafe 'Local root changed while reading'
    }
    [string[]]$paths = @($byPath.Keys)
    [Array]::Sort($paths, [StringComparer]::Ordinal)
    $entries = @($paths | ForEach-Object { $byPath[$_] })
    $builder = New-Object Text.StringBuilder
    foreach ($entry in $entries) {
      [void]$builder.Append($entry.Sha256).Append("`t").Append(
        $entry.Length.ToString([Globalization.CultureInfo]::InvariantCulture)).Append("`t").Append(
        $entry.RelativePath).Append("`n")
    }
    [byte[]]$manifest = [Text.Encoding]::UTF8.GetBytes($builder.ToString())
    return [pscustomobject][ordered]@{
      Schema = 'borrowing-local-snapshot/v1'; Phase = $Phase; RootPath = $root.CanonicalPath
      RootIdentityKey = $root.IdentityKey; Entries = $entries; ManifestBytes = $manifest
      Fingerprint = Get-BorrowingSha256Hex -Bytes $manifest
      FileCount = $entries.Count; TotalBytes = $total
    }
  }
  catch {
    if (Test-BlcKnownFailure $_.Exception) { throw }
    Throw-BorrowingFailure $policy.Stage $policy.Io 'Local snapshot failed'
  }
}
