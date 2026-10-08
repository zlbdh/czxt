$ErrorActionPreference = 'Stop'

$installerPathSafetyPath = Join-Path $PSScriptRoot 'installer-path-safety.ps1'
if (-not (Test-Path -LiteralPath $installerPathSafetyPath -PathType Leaf)) {
  throw ("Missing installer path-safety helper: {0}" -f $installerPathSafetyPath)
}
. $installerPathSafetyPath

$installerFileSafetyPath = Join-Path $PSScriptRoot 'installer-file-safety.ps1'
if (-not (Test-Path -LiteralPath $installerFileSafetyPath -PathType Leaf)) {
  throw ("Missing installer file-safety helper: {0}" -f $installerFileSafetyPath)
}
. $installerFileSafetyPath
$installerSourceCopyPath = Join-Path $PSScriptRoot 'installer-source-copy.ps1'
if (-not (Test-Path -LiteralPath $installerSourceCopyPath -PathType Leaf)) {
  throw ("Missing installer source-copy helper: {0}" -f $installerSourceCopyPath)
}
. $installerSourceCopyPath
$installerHandleLeasePath = Join-Path $PSScriptRoot 'installer-handle-lease.ps1'
if (-not (Test-Path -LiteralPath $installerHandleLeasePath -PathType Leaf)) {
  throw ("Missing installer handle-lease helper: {0}" -f $installerHandleLeasePath)
}
. $installerHandleLeasePath
$installerReplaceTransactionPath = Join-Path $PSScriptRoot 'installer-replace-transaction.ps1'
if (-not (Test-Path -LiteralPath $installerReplaceTransactionPath -PathType Leaf)) {
  throw ("Missing installer replacement-transaction helper: {0}" -f $installerReplaceTransactionPath)
}
. $installerReplaceTransactionPath
$installerOutputManifestPath = Join-Path $PSScriptRoot 'installer-output-manifest.ps1'
if (-not (Test-Path -LiteralPath $installerOutputManifestPath -PathType Leaf)) {
  throw ("Missing installer output-manifest helper: {0}" -f $installerOutputManifestPath)
}
. $installerOutputManifestPath
$installerTreePlanPath = Join-Path $PSScriptRoot 'installer-tree-plan.ps1'
if (-not (Test-Path -LiteralPath $installerTreePlanPath -PathType Leaf)) {
  throw ("Missing installer tree-plan helper: {0}" -f $installerTreePlanPath)
}
. $installerTreePlanPath
$installerCopyExpectationPath = Join-Path $PSScriptRoot 'installer-copy-expectation.ps1'
if (-not (Test-Path -LiteralPath $installerCopyExpectationPath -PathType Leaf)) {
  throw ("Missing installer copy-expectation helper: {0}" -f $installerCopyExpectationPath)
}
. $installerCopyExpectationPath

function Copy-CzxtInstallerTree {
  param(
    [string]$TemplateRoot,
    [string]$ProjectRoot,
    [string]$SourcePath,
    [string]$TargetPath,
    [switch]$ExpectAbsentTree,
    [object]$TreePlan,
    [object]$ExpectedPresentState,
    [object]$ExpectedSourceState,
    [object]$InstalledFiles,
    [scriptblock]$BeforeTargetCommit,
    [scriptblock]$AfterTargetDirectoryValidation,
    [scriptblock]$BeforeTargetDirectoryLeaseOpen,
    [object]$ParentDirectoryLease
  )

  $modeCount = 0
  if ($ExpectAbsentTree) { $modeCount++ }
  if ($null -ne $TreePlan) { $modeCount++ }
  if ($null -ne $ExpectedPresentState) { $modeCount++ }
  if ($modeCount -ne 1) {
    throw 'Installer copy must declare exactly one of ExpectAbsentTree, TreePlan, or ExpectedPresentState.'
  }

  $template = Get-CzxtBorrowingFullPath $TemplateRoot
  $source = Get-CzxtBorrowingFullPath $SourcePath
  if (-not (Test-CzxtBorrowingPathWithinRoot $source $template)) {
    throw ("Installer source is outside TemplateRoot: {0}" -f $source)
  }
  $sourceItem = Get-Item -LiteralPath $source -Force -ErrorAction Stop
  if (($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw ("Installer source contains a reparse point: {0}" -f $source)
  }
  $target = Get-CzxtBorrowingFullPath $TargetPath
  if (-not (Test-CzxtBorrowingPathWithinRoot $target $ProjectRoot)) {
    throw ("Installer copy target path is outside ProjectRoot: {0}" -f $target)
  }

  if ($sourceItem.PSIsContainer) {
    $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
      -CandidatePath $target -Context 'Installer copy target'
    if ($null -ne $ExpectedPresentState) {
      throw ("Installer directory target does not accept a file snapshot: {0}" -f $target)
    }
    $node = $null
    if ($null -ne $TreePlan) {
      $node = Get-CzxtInstallerTreePlanNode -TreePlan $TreePlan `
        -SourcePath $source -TargetPath $target -Kind 'Directory'
    }
    $sourceView = if ($null -ne $node) {
      Get-CzxtInstallerBoundSourceDirectoryView $node
    } else {
      [pscustomobject]@{
        Children = @(Get-ChildItem -LiteralPath $source -Force -ErrorAction Stop)
      }
    }
    $targetExists = Test-Path -LiteralPath $target
    $expectDirectoryAbsent = $ExpectAbsentTree -or
      ($null -ne $node -and $node.ExpectAbsent)
    if ($expectDirectoryAbsent -and $targetExists) {
      throw ("Installer directory target was expected to be absent but appeared before writing: {0}" -f $target)
    }
    if ($null -ne $node -and -not $node.ExpectAbsent -and -not $targetExists) {
      throw ("Installer directory target disappeared after binding: {0}" -f $target)
    }
    if ($targetExists -and -not (Test-Path -LiteralPath $target -PathType Container)) {
      throw ("Installer directory target is occupied by a file: {0}" -f $target)
    }
    if ($targetExists -and $null -ne $node -and -not $node.ExpectAbsent) {
      $targetState = Get-CzxtInstallerDirectoryState -Path $target `
        -Context 'Installer target directory'
      Assert-CzxtInstallerDirectoryStateStable $node.ExpectedPresentState `
        $targetState 'Installer target directory'
    }
    if (-not $targetExists) {
      [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
        -TargetPath $target -Context 'Installer directory target')
    }
    [void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
      -CandidatePath $target -Context 'Installer directory target')
    $lockExpected = if ($null -ne $node -and -not $node.ExpectAbsent) {
      $node.ExpectedPresentState
    } else {
      Get-CzxtInstallerDirectoryState -Path $target -Context 'New installer target directory'
    }
    if ($null -ne $BeforeTargetDirectoryLeaseOpen) {
      & $BeforeTargetDirectoryLeaseOpen $target
    }
    $targetLease = Open-CzxtInstallerDirectoryLease -Path $target `
      -ExpectedState $lockExpected -Context 'Installer target directory'
    try {
      if ($null -ne $AfterTargetDirectoryValidation) {
        & $AfterTargetDirectoryValidation $target
      }
      foreach ($child in $sourceView.Children) {
        $childTarget = Join-Path $target $child.Name
        Copy-CzxtInstallerTree -TemplateRoot $template -ProjectRoot $ProjectRoot `
          -SourcePath $child.FullName -TargetPath $childTarget `
          -ExpectAbsentTree:$ExpectAbsentTree -TreePlan $TreePlan `
          -InstalledFiles $InstalledFiles -BeforeTargetCommit $BeforeTargetCommit `
          -AfterTargetDirectoryValidation $AfterTargetDirectoryValidation `
          -BeforeTargetDirectoryLeaseOpen $BeforeTargetDirectoryLeaseOpen `
          -ParentDirectoryLease $targetLease
      }
      if ($null -ne $node) {
        [void](Get-CzxtInstallerBoundSourceDirectoryView $node)
      }
    }
    finally { $targetLease.Native.Dispose() }
    return
  }

  $expectAbsent = $ExpectAbsentTree
  $expected = $ExpectedPresentState
  $expectedSource = $ExpectedSourceState
  if ($null -ne $TreePlan) {
    $node = Get-CzxtInstallerTreePlanNode -TreePlan $TreePlan `
      -SourcePath $source -TargetPath $target -Kind 'File'
    $expectAbsent = $node.ExpectAbsent
    $expected = $node.ExpectedPresentState
    $expectedSource = $node.SourceState
  }
  if ($null -eq $expectedSource) {
    $expectedSource = Get-CzxtInstallerFileState -Path $source `
      -Context 'Installer file source'
  }
  Copy-CzxtInstallerFile -ProjectRoot $ProjectRoot -SourcePath $source `
    -TargetPath $target -Context 'Installer file target' -ExpectAbsent:$expectAbsent `
    -ExpectedPresentState $expected -ExpectedSourceState $expectedSource `
    -InstalledFiles $InstalledFiles `
    -BeforeTargetCommit $BeforeTargetCommit -ParentDirectoryLease $ParentDirectoryLease
}

function Resolve-CzxtInstallerLayout {
  param([string]$ProjectRoot, [string]$AppRepoDir)

  if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { throw 'ProjectRoot cannot be empty.' }
  if ([string]::IsNullOrWhiteSpace($AppRepoDir)) { throw 'AppRepoDir cannot be empty.' }
  if ([IO.Path]::IsPathRooted($AppRepoDir)) { throw 'AppRepoDir must be a relative path inside the project root.' }

  $project = Assert-CzxtBorrowingNoReparseAncestor `
    -Path (Get-CzxtBorrowingFullPath $ProjectRoot) -Context 'ProjectRoot'
  if ((Test-Path -LiteralPath $project) -and
      -not (Test-Path -LiteralPath $project -PathType Container)) {
    throw ("ProjectRoot is not a directory: {0}" -f $project)
  }
  try { $app = Get-CzxtBorrowingFullPath (Join-Path $project $AppRepoDir) }
  catch { throw ("Invalid AppRepoDir path: {0}" -f $AppRepoDir) }
  if (-not (Test-CzxtBorrowingPathStrictlyWithinRoot $app $project)) {
    throw ("AppRepoDir must be strictly inside ProjectRoot: {0}" -f $AppRepoDir)
  }
  $borrowing = Get-CzxtBorrowingFullPath (Join-Path $project '借鉴区')
  if ((Test-CzxtBorrowingPathWithinRoot $app $borrowing) -or
      (Test-CzxtBorrowingPathWithinRoot $borrowing $app)) {
    throw ("AppRepoDir and the borrowing area must not contain one another: {0}" -f $AppRepoDir)
  }
  [void](Assert-CzxtBorrowingNoReparseAncestor -Path $app -Context 'AppRepoDir')
  [void](Assert-CzxtBorrowingNoReparseAncestor -Path $borrowing -Context 'Borrowing target')
  if ((Test-Path -LiteralPath $app) -and
      -not (Test-Path -LiteralPath $app -PathType Container)) {
    throw ("AppRepoDir is not a directory: {0}" -f $app)
  }
  $relative = $app.Substring($project.Length).TrimStart('\', '/')
  return [pscustomobject]@{
    ProjectRoot = $project
    AppRepoPath = $app
    AppRepoDir = $relative
    BorrowingRoot = $borrowing
  }
}

$installerBorrowingSkeletonPath = Join-Path $PSScriptRoot 'installer-borrowing-skeleton.ps1'
if (-not (Test-Path -LiteralPath $installerBorrowingSkeletonPath -PathType Leaf)) {
  throw ("Missing installer borrowing-scaffolding helper: {0}" -f $installerBorrowingSkeletonPath)
}
. $installerBorrowingSkeletonPath

function Test-CzxtBorrowingPlaceholderRewriteAllowed {
  param([string]$ProjectRoot, [string]$CandidatePath)
  $project = Get-CzxtBorrowingFullPath $ProjectRoot
  $candidate = Get-CzxtBorrowingFullPath $CandidatePath
  if (-not (Test-CzxtBorrowingPathWithinRoot $candidate $project)) { return $false }
  foreach ($protectedRoot in @(
      (Join-Path $project '借鉴区\来源'),
      (Join-Path $project '借鉴区\事项'))) {
    if (Test-CzxtBorrowingPathWithinRoot $candidate $protectedRoot) { return $false }
  }
  $selfTestRoot=Get-CzxtBorrowingFullPath (Join-Path $project '能力资产\tools\scripts\check-os\tests')
  $selfTestNames=@('installer-render-support.ps1','installer-render-unit-contracts.ps1',
    'installer-render-contracts.ps1','installer-render-hook-contracts.ps1',
    'installer-render-regex-contracts.ps1','installer-render-anchor-contracts.ps1')
  if ((Test-CzxtBorrowingPathWithinRoot $candidate $selfTestRoot) -and
      $selfTestNames -ccontains [IO.Path]::GetFileName($candidate) -and
      (Split-Path -Parent $candidate).Equals($selfTestRoot,[StringComparison]::OrdinalIgnoreCase)) {
    return $false
  }
  return $true
}
