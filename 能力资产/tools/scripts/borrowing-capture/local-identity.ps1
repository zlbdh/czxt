$ErrorActionPreference = 'Stop'

function global:Assert-BlcContentEqual {
  param($Left, $Right, [string]$Stage)
  if (-not (Test-BlcBytesEqual $Left.ManifestBytes $Right.ManifestBytes)) {
    Throw-BorrowingFailure $Stage source-unsafe 'Local manifests differ'
  }
}

function global:Assert-BlcIdentityRelation {
  param($Left, $Right, [bool]$ExpectedEqual, [string]$Stage)
  if ($Left.Entries.Count -ne $Right.Entries.Count -or
      (($Left.RootIdentityKey -ceq $Right.RootIdentityKey) -ne $ExpectedEqual)) {
    Throw-BorrowingFailure $Stage source-unsafe 'Local identity chain differs'
  }
  for ($i = 0; $i -lt $Left.Entries.Count; $i++) {
    $a = $Left.Entries[$i]; $b = $Right.Entries[$i]
    if ($a.RelativePath -cne $b.RelativePath -or
        (($a.IdentityKey -ceq $b.IdentityKey) -ne $ExpectedEqual) -or $b.NumberOfLinks -ne 1) {
      Throw-BorrowingFailure $Stage source-unsafe 'Local identity chain differs'
    }
  }
}

function global:Move-BlcPromotionBack {
  param($Candidate, $CapturePath, $Operations)
  try {
    if (-not (Test-Path -LiteralPath $CapturePath -PathType Container) -or
        (Test-Path -LiteralPath $Candidate.StagingPath)) { throw 'rollback boundary' }
    $move = $Operations.MoveDirectory
    & $move $CapturePath $Candidate.StagingPath
  }
  catch { Throw-BorrowingFailure rollback rollback-failed 'Local rollback failed' }
}
