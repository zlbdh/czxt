$ErrorActionPreference = 'Stop'

function New-CzxtInstallerTreeChildMap {
  param([object[]]$Children)
  $map = New-Object 'Collections.Generic.Dictionary[string,object]' `
    ([StringComparer]::OrdinalIgnoreCase)
  foreach ($child in @($Children)) {
    $kind = if ($child.PSIsContainer) { 'Directory' } else { 'File' }
    if ($map.ContainsKey($child.Name)) {
      throw ("实例化来源目录子项重复：{0}" -f $child.FullName)
    }
    $map.Add($child.Name, [pscustomobject]@{ Name = $child.Name; Kind = $kind })
  }
  return $map
}

function Assert-CzxtInstallerTreeChildrenStable {
  param([object]$ExpectedChildren, [object[]]$ActualChildren, [string]$Context)
  $actual = New-CzxtInstallerTreeChildMap $ActualChildren
  if ($null -eq $ExpectedChildren -or $ExpectedChildren.Count -ne $actual.Count) {
    throw ($Context + '子项集在预检后发生变化')
  }
  foreach ($name in $ExpectedChildren.Keys) {
    if (-not $actual.ContainsKey($name) -or
        $ExpectedChildren[$name].Name -cne $actual[$name].Name -or
        $ExpectedChildren[$name].Kind -cne $actual[$name].Kind) {
      throw ("{0}子项在预检后发生变化：{1}" -f $Context, $name)
    }
  }
}

function Get-CzxtInstallerBoundSourceDirectoryView {
  param([object]$Node)
  $before = Get-CzxtInstallerDirectoryState -Path $Node.SourcePath `
    -Context '实例化来源目录'
  Assert-CzxtInstallerDirectoryStateStable $Node.SourceState $before '实例化来源目录'
  $children = @(Get-ChildItem -LiteralPath $Node.SourcePath -Force -ErrorAction Stop)
  $after = Get-CzxtInstallerDirectoryState -Path $Node.SourcePath `
    -Context '实例化来源目录'
  Assert-CzxtInstallerDirectoryStateStable $Node.SourceState $after '实例化来源目录'
  Assert-CzxtInstallerTreeChildrenStable $Node.SourceChildren $children '实例化来源目录'
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
    -CandidatePath $TargetPath -Context '实例化树预检目标'
  $sourceItem = Get-Item -LiteralPath $source -Force -ErrorAction Stop
  if (($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw ("实例化来源含 reparse point：{0}" -f $source)
  }
  if ($Nodes.ContainsKey($target)) { throw ("实例化树预检路径重复：{0}" -f $target) }

  if ($sourceItem.PSIsContainer) {
    $sourceState = Get-CzxtInstallerDirectoryState -Path $source `
      -Context '实例化树预检来源目录'
    $sourceChildren = @(Get-ChildItem -LiteralPath $source -Force -ErrorAction Stop)
    $sourceChildMap = New-CzxtInstallerTreeChildMap $sourceChildren
    if ([IO.File]::Exists($target)) {
      throw ("实例化目录目标已被文件占用：{0}" -f $target)
    }
    $exists = [IO.Directory]::Exists($target)
    $targetState = if ($exists) {
      Get-CzxtInstallerDirectoryState -Path $target `
        -Context '实例化树预检目标目录'
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
      -Context '实例化树预检来源目录'
    Assert-CzxtInstallerDirectoryStateStable $sourceState $sourceAfter `
      '实例化树预检来源目录'
    Assert-CzxtInstallerTreeChildrenStable $sourceChildMap `
      @(Get-ChildItem -LiteralPath $source -Force -ErrorAction Stop) `
      '实例化树预检来源目录'
    return
  }

  if ([IO.Directory]::Exists($target)) {
    throw ("实例化文件目标已被目录占用：{0}" -f $target)
  }
  $sourceState = Get-CzxtInstallerFileState -Path $source `
    -Context '实例化树预检来源文件'
  $expected = $null
  if ([IO.File]::Exists($target)) {
    $expected = Get-CzxtInstallerFileState -Path $target -Context '实例化树预检文件'
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
      -Context '实例化树预检来源文件') `
    '实例化树预检来源文件'
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
    throw '实例化树计划无效。'
  }
  $source = Get-CzxtBorrowingFullPath $SourcePath
  $target = Get-CzxtBorrowingFullPath $TargetPath
  if (-not $TreePlan.Nodes.ContainsKey($target)) {
    throw ("实例化树出现未经预检的节点：{0}" -f $target)
  }
  $node = $TreePlan.Nodes[$target]
  if ($node.Kind -cne $Kind -or
      -not $node.SourcePath.Equals($source, [StringComparison]::OrdinalIgnoreCase) -or
      -not $node.TargetPath.Equals($target, [StringComparison]::OrdinalIgnoreCase)) {
    throw ("实例化树计划与当前节点不匹配：{0}" -f $target)
  }
  return $node
}
