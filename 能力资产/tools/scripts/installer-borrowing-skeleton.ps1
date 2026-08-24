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
    throw "借鉴区骨架路径越界：$RelativePath"
  }
  [void](Assert-CzxtBorrowingNoReparseAncestor $source '借鉴区骨架来源')
  [void](Assert-CzxtBorrowingNoReparseAncestor $target '借鉴区骨架目标')
  if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "模板缺少借鉴区骨架：$RelativePath"
  }
  $sourceState = Get-CzxtInstallerFileState $source '借鉴区骨架来源'
  if ($null -ne $AfterSourceBind) { & $AfterSourceBind $source }
  if ($ExpectAbsent -and $null -ne $ExpectedPresentState) {
    throw '借鉴区骨架目标不能同时声明不存在与已存在快照。'
  }
  if (-not $ExpectAbsent -and $null -eq $ExpectedPresentState) {
    $expectation = Get-CzxtInstallerTargetExpectation -ProjectRoot $ProjectRoot `
      -TargetPath $target -Context '借鉴区骨架目标' -AllowExisting:$Force
    $ExpectAbsent = $expectation.Mode -eq 'ExpectAbsent'
    $ExpectedPresentState = $expectation.State
  }
  $parent = Split-Path -Parent $target
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
      -TargetPath $parent -Context '借鉴区骨架父目录')
  }
  [void](Assert-CzxtBorrowingNoReparseAncestor $target '借鉴区骨架目标')
  Copy-CzxtInstallerFile -ProjectRoot $ProjectRoot -SourcePath $source `
    -TargetPath $target -Context '借鉴区骨架目标' -ExpectAbsent:$ExpectAbsent `
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
    throw '借鉴区骨架根路径越界。'
  }
  [void](Assert-CzxtBorrowingNoReparseAncestor $sourceRoot '借鉴区模板根')
  [void](Assert-CzxtBorrowingNoReparseAncestor $targetRoot '借鉴区目标根')
  if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw '模板缺少必要项：借鉴区'
  }
  foreach ($relativePath in @(
      'README.md', '.gitignore', '模板\来源版本卡.md', '模板\借鉴卡.md')) {
    Copy-CzxtBorrowingStaticFile -SourceRoot $sourceRoot -TargetRoot $targetRoot `
      -RelativePath $relativePath -ProjectRoot $ProjectRoot -Force:$Force `
      -InstalledFiles $InstalledFiles
  }
  foreach ($relativeDirectory in @('来源', '事项')) {
    $targetDirectory = Join-Path $targetRoot $relativeDirectory
    [void](Assert-CzxtBorrowingNoReparseAncestor $targetDirectory '借鉴区目录')
    if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
      $sentinelRelative = Join-Path $relativeDirectory '.gitkeep'
      $sentinelTarget = Join-Path $targetDirectory '.gitkeep'
      $sentinelExpectation = Get-CzxtInstallerTargetExpectation `
        -ProjectRoot $ProjectRoot -TargetPath $sentinelTarget `
        -Context '借鉴区新建目录 .gitkeep'
      [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
        -TargetPath $targetDirectory -Context '借鉴区目录')
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
