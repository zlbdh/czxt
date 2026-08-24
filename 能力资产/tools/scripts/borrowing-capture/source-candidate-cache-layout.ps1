$ErrorActionPreference = 'Stop'

function global:Get-BcvExpectedSnapshotMembers {
  param([string]$SourceType)
  switch -CaseSensitive ($SourceType) {
    'git' {
      return @([pscustomobject]@{ Name = 'repository.git'; Kind = 'Directory' })
    }
    'local' {
      return @(
        [pscustomobject]@{ Name = '内容'; Kind = 'Directory' },
        [pscustomobject]@{ Name = 'manifest.tsv'; Kind = 'File' }
      )
    }
    'web' {
      return @(
        [pscustomobject]@{ Name = 'response.bin'; Kind = 'File' },
        [pscustomobject]@{ Name = 'response.metadata.json'; Kind = 'File' }
      )
    }
    default { Throw-BorrowingCandidateFailure 'cache source type is invalid' }
  }
}

function global:Test-BcvExactDirectoryMembers {
  param([string]$Path, [object[]]$ExpectedMembers)
  try {
    if (-not (Test-BcvSafeCachePath $Path Directory)) { return $false }
    $entries = @(Get-ChildItem -LiteralPath $Path -Force -ErrorAction Stop)
    if ($entries.Count -ne $ExpectedMembers.Count) { return $false }
    foreach ($expected in $ExpectedMembers) {
      $matches = @($entries | Where-Object { $_.Name -ceq [string]$expected.Name })
      if ($matches.Count -ne 1) { return $false }
      $actualKind = if ($matches[0].PSIsContainer) { 'Directory' } else { 'File' }
      if ($actualKind -cne [string]$expected.Kind -or
          -not (Test-BcvSafeCachePath $matches[0].FullName $actualKind)) {
        return $false
      }
    }
    return $true
  }
  catch { return $false }
}
