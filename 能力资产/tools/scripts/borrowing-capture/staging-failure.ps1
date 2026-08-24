$ErrorActionPreference = 'Stop'

function global:Set-BorrowingGeneratedStagingFailurePath {
  param(
    $Exception,
    [string]$Root,
    [string]$SourcePath,
    [string]$StagingPath
  )
  if ($null -eq $Exception) { return }
  try {
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    $sourceFull = [IO.Path]::GetFullPath($SourcePath).TrimEnd('\')
    $stagingFull = [IO.Path]::GetFullPath($StagingPath).TrimEnd('\')
    $leaf = Split-Path -Leaf $stagingFull
    if ($leaf -cmatch '\A\.staging-[0-9a-f]{32}\z' -and
        (Get-BorrowingPathRelation $rootFull $stagingFull) -ceq 'ancestor' -and
        (Get-BorrowingPathRelation $sourceFull $stagingFull) -ceq 'ancestor' -and
        (Test-Path -LiteralPath $stagingFull -PathType Container)) {
      $Exception.Data['BorrowingStagingPath'] = $stagingFull
    }
  }
  catch { return }
}
