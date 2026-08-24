$ErrorActionPreference = 'Stop'

$installerPathSafetyPath = Join-Path $PSScriptRoot 'installer-path-safety.ps1'
if (-not (Test-Path -LiteralPath $installerPathSafetyPath -PathType Leaf)) {
  throw ("实例化路径安全 helper 缺失：{0}" -f $installerPathSafetyPath)
}
. $installerPathSafetyPath

$installerFileSafetyPath = Join-Path $PSScriptRoot 'installer-file-safety.ps1'
if (-not (Test-Path -LiteralPath $installerFileSafetyPath -PathType Leaf)) {
  throw ("实例化文件安全 helper 缺失：{0}" -f $installerFileSafetyPath)
}
. $installerFileSafetyPath
$installerSourceCopyPath = Join-Path $PSScriptRoot 'installer-source-copy.ps1'
if (-not (Test-Path -LiteralPath $installerSourceCopyPath -PathType Leaf)) {
  throw ("实例化来源复制 helper 缺失：{0}" -f $installerSourceCopyPath)
}
. $installerSourceCopyPath
$installerHandleLeasePath = Join-Path $PSScriptRoot 'installer-handle-lease.ps1'
if (-not (Test-Path -LiteralPath $installerHandleLeasePath -PathType Leaf)) {
  throw ("实例化句柄租约 helper 缺失：{0}" -f $installerHandleLeasePath)
}
. $installerHandleLeasePath
$installerReplaceTransactionPath = Join-Path $PSScriptRoot 'installer-replace-transaction.ps1'
if (-not (Test-Path -LiteralPath $installerReplaceTransactionPath -PathType Leaf)) {
  throw ("实例化替换事务 helper 缺失：{0}" -f $installerReplaceTransactionPath)
}
. $installerReplaceTransactionPath
$installerOutputManifestPath = Join-Path $PSScriptRoot 'installer-output-manifest.ps1'
if (-not (Test-Path -LiteralPath $installerOutputManifestPath -PathType Leaf)) {
  throw ("实例化输出 manifest helper 缺失：{0}" -f $installerOutputManifestPath)
}
. $installerOutputManifestPath
$installerTreePlanPath = Join-Path $PSScriptRoot 'installer-tree-plan.ps1'
if (-not (Test-Path -LiteralPath $installerTreePlanPath -PathType Leaf)) {
  throw ("实例化树计划 helper 缺失：{0}" -f $installerTreePlanPath)
}
. $installerTreePlanPath
$installerCopyExpectationPath = Join-Path $PSScriptRoot 'installer-copy-expectation.ps1'
if (-not (Test-Path -LiteralPath $installerCopyExpectationPath -PathType Leaf)) {
  throw ("实例化复制预期 helper 缺失：{0}" -f $installerCopyExpectationPath)
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
    throw '实例化复制必须且只能声明 ExpectAbsentTree、TreePlan 或 ExpectedPresentState。'
  }

  $template = Get-CzxtBorrowingFullPath $TemplateRoot
  $source = Get-CzxtBorrowingFullPath $SourcePath
  if (-not (Test-CzxtBorrowingPathWithinRoot $source $template)) {
    throw ("实例化来源越出 TemplateRoot：{0}" -f $source)
  }
  $sourceItem = Get-Item -LiteralPath $source -Force -ErrorAction Stop
  if (($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw ("实例化来源含 reparse point：{0}" -f $source)
  }
  $target = Get-CzxtBorrowingFullPath $TargetPath
  if (-not (Test-CzxtBorrowingPathWithinRoot $target $ProjectRoot)) {
    throw ("实例化复制目标路径越出 ProjectRoot：{0}" -f $target)
  }

  if ($sourceItem.PSIsContainer) {
    $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
      -CandidatePath $target -Context '实例化复制目标'
    if ($null -ne $ExpectedPresentState) {
      throw ("实例化目录目标不接受文件快照：{0}" -f $target)
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
      throw ("实例化目录目标原应不存在，但在落盘前出现：{0}" -f $target)
    }
    if ($null -ne $node -and -not $node.ExpectAbsent -and -not $targetExists) {
      throw ("实例化目录目标在绑定后消失：{0}" -f $target)
    }
    if ($targetExists -and -not (Test-Path -LiteralPath $target -PathType Container)) {
      throw ("实例化目录目标已被文件占用：{0}" -f $target)
    }
    if ($targetExists -and $null -ne $node -and -not $node.ExpectAbsent) {
      $targetState = Get-CzxtInstallerDirectoryState -Path $target `
        -Context '实例化目标目录'
      Assert-CzxtInstallerDirectoryStateStable $node.ExpectedPresentState `
        $targetState '实例化目标目录'
    }
    if (-not $targetExists) {
      [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
        -TargetPath $target -Context '实例化目录目标')
    }
    [void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
      -CandidatePath $target -Context '实例化目录目标')
    $lockExpected = if ($null -ne $node -and -not $node.ExpectAbsent) {
      $node.ExpectedPresentState
    } else {
      Get-CzxtInstallerDirectoryState -Path $target -Context '实例化新建目标目录'
    }
    if ($null -ne $BeforeTargetDirectoryLeaseOpen) {
      & $BeforeTargetDirectoryLeaseOpen $target
    }
    $targetLease = Open-CzxtInstallerDirectoryLease -Path $target `
      -ExpectedState $lockExpected -Context '实例化目标目录'
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
      -Context '实例化文件来源'
  }
  Copy-CzxtInstallerFile -ProjectRoot $ProjectRoot -SourcePath $source `
    -TargetPath $target -Context '实例化文件目标' -ExpectAbsent:$expectAbsent `
    -ExpectedPresentState $expected -ExpectedSourceState $expectedSource `
    -InstalledFiles $InstalledFiles `
    -BeforeTargetCommit $BeforeTargetCommit -ParentDirectoryLease $ParentDirectoryLease
}

function Resolve-CzxtInstallerLayout {
  param([string]$ProjectRoot, [string]$AppRepoDir)

  if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { throw 'ProjectRoot 不能为空。' }
  if ([string]::IsNullOrWhiteSpace($AppRepoDir)) { throw 'AppRepoDir 不能为空。' }
  if ([IO.Path]::IsPathRooted($AppRepoDir)) { throw 'AppRepoDir 必须是项目根内的相对路径。' }

  $project = Assert-CzxtBorrowingNoReparseAncestor `
    -Path (Get-CzxtBorrowingFullPath $ProjectRoot) -Context 'ProjectRoot'
  if ((Test-Path -LiteralPath $project) -and
      -not (Test-Path -LiteralPath $project -PathType Container)) {
    throw ("ProjectRoot 不是目录：{0}" -f $project)
  }
  try { $app = Get-CzxtBorrowingFullPath (Join-Path $project $AppRepoDir) }
  catch { throw ("AppRepoDir 路径无效：{0}" -f $AppRepoDir) }
  if (-not (Test-CzxtBorrowingPathStrictlyWithinRoot $app $project)) {
    throw ("AppRepoDir 必须严格位于 ProjectRoot 内：{0}" -f $AppRepoDir)
  }
  $borrowing = Get-CzxtBorrowingFullPath (Join-Path $project '借鉴区')
  if ((Test-CzxtBorrowingPathWithinRoot $app $borrowing) -or
      (Test-CzxtBorrowingPathWithinRoot $borrowing $app)) {
    throw ("AppRepoDir 必须与借鉴区互不包含：{0}" -f $AppRepoDir)
  }
  [void](Assert-CzxtBorrowingNoReparseAncestor -Path $app -Context 'AppRepoDir')
  [void](Assert-CzxtBorrowingNoReparseAncestor -Path $borrowing -Context '借鉴区目标')
  if ((Test-Path -LiteralPath $app) -and
      -not (Test-Path -LiteralPath $app -PathType Container)) {
    throw ("AppRepoDir 不是目录：{0}" -f $app)
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
  throw ("实例化借鉴区骨架 helper 缺失：{0}" -f $installerBorrowingSkeletonPath)
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
  return $true
}
