$ErrorActionPreference = 'Stop'

function New-CzxtInstallerTreeChildMap {
  param([object[]]$Children)
  $map = New-Object 'Collections.Generic.Dictionary[string,object]' `
    ([StringComparer]::OrdinalIgnoreCase)
  foreach ($child in @($Children)) {
    $kind = if ($child.PSIsContainer) { 'Directory' } else { 'File' }
    if ($map.ContainsKey($child.Name)) {
      throw ("Duplicate installer source-directory child: {0}" -f $child.FullName)
    }
    $map.Add($child.Name, [pscustomobject]@{ Name = $child.Name; Kind = $kind })
  }
  return $map
}

function Assert-CzxtInstallerTreeChildrenStable {
  param([object]$ExpectedChildren, [object[]]$ActualChildren, [string]$Context)
  $actual = New-CzxtInstallerTreeChildMap $ActualChildren
  if ($null -eq $ExpectedChildren -or $ExpectedChildren.Count -ne $actual.Count) {
    throw ($Context + ' child set changed after preflight')
  }
  foreach ($name in $ExpectedChildren.Keys) {
    if (-not $actual.ContainsKey($name) -or
        $ExpectedChildren[$name].Name -cne $actual[$name].Name -or
        $ExpectedChildren[$name].Kind -cne $actual[$name].Kind) {
      throw ("{0} child changed after preflight: {1}" -f $Context, $name)
    }
  }
}

function Get-CzxtInstallerBoundSourceDirectoryView {
  param([object]$Node)
  $before = Get-CzxtInstallerDirectoryState -Path $Node.SourcePath `
    -Context 'Installer source directory'
  Assert-CzxtInstallerDirectoryStateStable $Node.SourceState $before 'Installer source directory'
  $children = @(Get-ChildItem -LiteralPath $Node.SourcePath -Force -ErrorAction Stop)
  $after = Get-CzxtInstallerDirectoryState -Path $Node.SourcePath `
    -Context 'Installer source directory'
  Assert-CzxtInstallerDirectoryStateStable $Node.SourceState $after 'Installer source directory'
  Assert-CzxtInstallerTreeChildrenStable $Node.SourceChildren $children 'Installer source directory'
  return [pscustomobject]@{ State = $after; Children = $children }
}

function Add-CzxtInstallerTreePlanNode {
  param(
    [string]$ProjectRoot,
    [string]$SourcePath,
    [string]$TargetPath,
    [object]$Nodes
  )
  $source = Get-CzxtBorrowingFullPath $SourcePath
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context 'Installer tree preflight target'
  $sourceItem = Get-Item -LiteralPath $source -Force -ErrorAction Stop
  if (($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw ("Installer source contains a reparse point: {0}" -f $source)
  }
  if ($Nodes.ContainsKey($target)) { throw ("Duplicate installer tree preflight path: {0}" -f $target) }

  if ($sourceItem.PSIsContainer) {
    $sourceState = Get-CzxtInstallerDirectoryState -Path $source `
      -Context 'Installer tree preflight source directory'
    $sourceChildren = @(Get-ChildItem -LiteralPath $source -Force -ErrorAction Stop)
    $sourceChildMap = New-CzxtInstallerTreeChildMap $sourceChildren
    if ([IO.File]::Exists($target)) {
      throw ("Installer directory target is occupied by a file: {0}" -f $target)
    }
    $exists = [IO.Directory]::Exists($target)
    $targetState = if ($exists) {
      Get-CzxtInstallerDirectoryState -Path $target `
        -Context 'Installer tree preflight target directory'
    } else { $null }
    $Nodes.Add($target, [pscustomobject]@{
        SourcePath = $source
        SourceState = $sourceState
        SourceChildren = $sourceChildMap
        TargetPath = $target
        Kind = 'Directory'
        ExpectAbsent = -not $exists
        ExpectedPresentState = $targetState
      })
    foreach ($child in $sourceChildren) {
      Add-CzxtInstallerTreePlanNode -ProjectRoot $ProjectRoot `
        -SourcePath $child.FullName -TargetPath (Join-Path $target $child.Name) -Nodes $Nodes
    }
    $sourceAfter = Get-CzxtInstallerDirectoryState -Path $source `
      -Context 'Installer tree preflight source directory'
    Assert-CzxtInstallerDirectoryStateStable $sourceState $sourceAfter `
      'Installer tree preflight source directory'
    Assert-CzxtInstallerTreeChildrenStable $sourceChildMap `
      @(Get-ChildItem -LiteralPath $source -Force -ErrorAction Stop) `
      'Installer tree preflight source directory'
    return
  }

  if ([IO.Directory]::Exists($target)) {
    throw ("Installer file target is occupied by a directory: {0}" -f $target)
  }
  $sourceState = Get-CzxtInstallerFileState -Path $source `
    -Context 'Installer tree preflight source file'
  $expected = $null
  if ([IO.File]::Exists($target)) {
    $expected = Get-CzxtInstallerFileState -Path $target -Context 'Installer tree preflight file'
  }
  $Nodes.Add($target, [pscustomobject]@{
      SourcePath = $source
      SourceState = $sourceState
      SourceChildren = $null
      TargetPath = $target
      Kind = 'File'
      ExpectAbsent = $null -eq $expected
      ExpectedPresentState = $expected
    })
  Assert-CzxtInstallerFileStateStable $sourceState `
    (Get-CzxtInstallerFileState -Path $source `
      -Context 'Installer tree preflight source file') `
    'Installer tree preflight source file'
}

function New-CzxtInstallerTreePlan {
  param([string]$ProjectRoot, [string]$SourcePath, [string]$TargetPath)
  $nodes = New-Object 'Collections.Generic.Dictionary[string,object]' `
    ([StringComparer]::OrdinalIgnoreCase)
  Add-CzxtInstallerTreePlanNode -ProjectRoot $ProjectRoot -SourcePath $SourcePath `
    -TargetPath $TargetPath -Nodes $nodes
  return [pscustomobject]@{
    Schema = 'czxt-installer-tree-plan/v1'
    SourceRoot = Get-CzxtBorrowingFullPath $SourcePath
    TargetRoot = Get-CzxtBorrowingFullPath $TargetPath
    Nodes = $nodes
  }
}

function Get-CzxtInstallerTreePlanNode {
  param([object]$TreePlan, [string]$SourcePath, [string]$TargetPath, [string]$Kind)
  if ($null -eq $TreePlan -or $TreePlan.Schema -cne 'czxt-installer-tree-plan/v1' -or
      $null -eq $TreePlan.Nodes) {
    throw 'Invalid installer tree plan.'
  }
  $source = Get-CzxtBorrowingFullPath $SourcePath
  $target = Get-CzxtBorrowingFullPath $TargetPath
  if (-not $TreePlan.Nodes.ContainsKey($target)) {
    throw ("Installer tree contains a node that was not preflighted: {0}" -f $target)
  }
  $node = $TreePlan.Nodes[$target]
  if ($node.Kind -cne $Kind -or
      -not $node.SourcePath.Equals($source, [StringComparison]::OrdinalIgnoreCase) -or
      -not $node.TargetPath.Equals($target, [StringComparison]::OrdinalIgnoreCase)) {
    throw ("Installer tree plan does not match the current node: {0}" -f $target)
  }
  return $node
}
