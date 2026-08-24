$ErrorActionPreference = 'Stop'

function global:Get-BorrowingOwnedTreeSealKey {
  param([string]$Kind, [string]$RootPath, [string]$Path)
  $relative = $Path.Substring($RootPath.Length).TrimStart([char]'\')
  return $Kind.Substring(0, 1).ToUpperInvariant() + ':' + $relative
}

function global:Get-BorrowingOwnedTreeSealLimits {
  $limits = [pscustomobject]@{
    MaxMembers = [uint64]20000
    MaxBytes = [uint64]536870912
  }
  if ($script:BorrowingOwnedTreeSealTestLimits -is `
      [Collections.IDictionary]) {
    foreach ($name in @('MaxMembers', 'MaxBytes')) {
      if ($script:BorrowingOwnedTreeSealTestLimits.Contains($name)) {
        $limits.$name = [uint64]$script:BorrowingOwnedTreeSealTestLimits[$name]
      }
    }
  }
  if ($limits.MaxMembers -eq 0 -or $limits.MaxBytes -eq 0) {
    Throw-BorrowingFailure capture resource-limit `
      'owned tree seal limits are invalid'
  }
  return $limits
}

function global:Get-BorrowingOwnedTreeSealInventory {
  param([string]$RootPath, [string]$Stage, [string]$ReasonCode)
  $root = Get-BorrowingSafePathInfo $RootPath Directory $Stage $ReasonCode
  $limits = Get-BorrowingOwnedTreeSealLimits
  [uint64]$memberCount = 0
  [uint64]$totalBytes = 0
  $members = New-Object `
    'Collections.Generic.Dictionary[string,object]' `
    ([StringComparer]::OrdinalIgnoreCase)
  $pending = New-Object 'Collections.Generic.Stack[string]'
  $pending.Push($root.CanonicalPath)
  try {
    while ($pending.Count -gt 0) {
      $directory = $pending.Pop()
      $nativeDirectory = '\\?\' + $directory
      foreach ($rawPath in [IO.Directory]::EnumerateFileSystemEntries(
          $nativeDirectory)) {
        $memberCount++
        if ($memberCount -gt $limits.MaxMembers) {
          Stop-BorrowingOwnedTreeSeal $Stage resource-limit `
            'owned tree seal member limit exceeded'
        }
        $path = if ($rawPath.StartsWith('\\?\',
            [StringComparison]::Ordinal)) {
          $rawPath.Substring(4)
        } else { $rawPath }
        $attributes = [IO.File]::GetAttributes($rawPath)
        $kind = if (($attributes -band [IO.FileAttributes]::Directory) -ne 0) {
          'Directory'
        } else { 'File' }
        $safe = Get-BorrowingSafePathInfo $path $kind $Stage $ReasonCode
        if ($kind -ceq 'File') {
          if ([uint64]$safe.Length -gt $limits.MaxBytes -or
              $totalBytes -gt ($limits.MaxBytes - [uint64]$safe.Length)) {
            Stop-BorrowingOwnedTreeSeal $Stage resource-limit `
              'owned tree seal byte limit exceeded'
          }
          $totalBytes += [uint64]$safe.Length
        }
        if ((Get-BorrowingPathRelation $root.CanonicalPath `
              $safe.CanonicalPath) -cne 'ancestor') {
          Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
            'owned tree seal member escaped its root'
        }
        $key = Get-BorrowingOwnedTreeSealKey $kind $root.CanonicalPath `
          $safe.CanonicalPath
        if ($members.ContainsKey($key)) {
          Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
            'owned tree seal member key collided'
        }
        $members.Add($key, [pscustomobject]@{
            Key = $key; Kind = $kind; Path = $safe.CanonicalPath
            IdentityKey = $safe.IdentityKey; Length = [uint64]$safe.Length
          })
        if ($kind -ceq 'Directory') { $pending.Push($safe.CanonicalPath) }
      }
    }
  }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
      'owned tree seal enumeration failed'
  }
  return [pscustomobject]@{
    Root = $root; Members = $members
    MemberCount = $memberCount; TotalBytes = $totalBytes
  }
}
