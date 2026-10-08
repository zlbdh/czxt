$ErrorActionPreference = 'Stop'

function Copy-CzxtBorrowingStaticFile {
  param(
    [string]$SourceRoot, [string]$TargetRoot, [string]$RelativePath,
    [string]$ProjectRoot, [switch]$Force, [switch]$ExpectAbsent,
    [object]$ExpectedPresentState, [object]$InstalledFiles,
    [scriptblock]$AfterSourceBind
  )
  $source = Get-CzxtBorrowingFullPath (Join-Path $SourceRoot $RelativePath)
  $target = Get-CzxtBorrowingFullPath (Join-Path $TargetRoot $RelativePath)
  if (-not (Test-CzxtBorrowingPathWithinRoot $source $SourceRoot) -or
      -not (Test-CzxtBorrowingPathWithinRoot $target $TargetRoot)) {
    throw "Borrowing scaffolding path is out of bounds: $RelativePath"
  }
  [void](Assert-CzxtBorrowingNoReparseAncestor $source 'Borrowing scaffolding source')
  [void](Assert-CzxtBorrowingNoReparseAncestor $target 'Borrowing scaffolding target')
  if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Template is missing borrowing scaffolding: $RelativePath"
  }
  $sourceState = Get-CzxtInstallerFileState $source 'Borrowing scaffolding source'
  if ($null -ne $AfterSourceBind) { & $AfterSourceBind $source }
  if ($ExpectAbsent -and $null -ne $ExpectedPresentState) {
    throw 'Borrowing scaffolding target cannot declare both absence and an existing snapshot.'
  }
  if (-not $ExpectAbsent -and $null -eq $ExpectedPresentState) {
    $expectation = Get-CzxtInstallerTargetExpectation -ProjectRoot $ProjectRoot `
      -TargetPath $target -Context 'Borrowing scaffolding target' -AllowExisting:$Force
    $ExpectAbsent = $expectation.Mode -eq 'ExpectAbsent'
    $ExpectedPresentState = $expectation.State
  }
  $parent = Split-Path -Parent $target
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
      -TargetPath $parent -Context 'Borrowing scaffolding parent directory')
  }
  [void](Assert-CzxtBorrowingNoReparseAncestor $target 'Borrowing scaffolding target')
  Copy-CzxtInstallerFile -ProjectRoot $ProjectRoot -SourcePath $source `
    -TargetPath $target -Context 'Borrowing scaffolding target' -ExpectAbsent:$ExpectAbsent `
    -ExpectedPresentState $ExpectedPresentState -ExpectedSourceState $sourceState `
    -InstalledFiles $InstalledFiles
}

function Copy-BorrowingZoneSkeleton {
  [CmdletBinding()]
  param(
    [string]$TemplateRoot, [string]$ProjectRoot, [switch]$Force,
    [object]$InstalledFiles, [scriptblock]$BeforeBorrowingSentinelCopy
  )
  $sourceRoot = Get-CzxtBorrowingFullPath (Join-Path $TemplateRoot '借鉴区')
  $targetRoot = Get-CzxtBorrowingFullPath (Join-Path $ProjectRoot '借鉴区')
  if (-not (Test-CzxtBorrowingPathStrictlyWithinRoot $sourceRoot $TemplateRoot) -or
      -not (Test-CzxtBorrowingPathStrictlyWithinRoot $targetRoot $ProjectRoot)) {
    throw 'Borrowing scaffolding root path is out of bounds.'
  }
  [void](Assert-CzxtBorrowingNoReparseAncestor $sourceRoot 'Borrowing template root')
  [void](Assert-CzxtBorrowingNoReparseAncestor $targetRoot 'Borrowing target root')
  if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw 'Template is missing a required item: borrowing area'
  }
  foreach ($relativePath in @(
      'README.md', '.gitignore', '模板\来源版本卡.md', '模板\借鉴卡.md')) {
    Copy-CzxtBorrowingStaticFile -SourceRoot $sourceRoot -TargetRoot $targetRoot `
      -RelativePath $relativePath -ProjectRoot $ProjectRoot -Force:$Force `
      -InstalledFiles $InstalledFiles
  }
  foreach ($relativeDirectory in @('来源', '事项')) {
    $targetDirectory = Join-Path $targetRoot $relativeDirectory
    [void](Assert-CzxtBorrowingNoReparseAncestor $targetDirectory 'Borrowing directory')
    if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
      $sentinelRelative = Join-Path $relativeDirectory '.gitkeep'
      $sentinelTarget = Join-Path $targetDirectory '.gitkeep'
      $sentinelExpectation = Get-CzxtInstallerTargetExpectation `
        -ProjectRoot $ProjectRoot -TargetPath $sentinelTarget `
        -Context 'New borrowing directory .gitkeep'
      [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
        -TargetPath $targetDirectory -Context 'Borrowing directory')
      if ($null -ne $BeforeBorrowingSentinelCopy) {
        & $BeforeBorrowingSentinelCopy $targetDirectory $sentinelTarget
      }
      Copy-CzxtBorrowingStaticFile -SourceRoot $sourceRoot -TargetRoot $targetRoot `
        -RelativePath $sentinelRelative -ProjectRoot $ProjectRoot `
        -ExpectAbsent:($sentinelExpectation.Mode -eq 'ExpectAbsent') `
        -ExpectedPresentState $sentinelExpectation.State -InstalledFiles $InstalledFiles
    }
  }
}
