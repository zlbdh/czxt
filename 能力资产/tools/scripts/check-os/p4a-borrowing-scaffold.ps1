$ErrorActionPreference = 'Stop'

function Test-CzxtBorrowingPath {
  param(
    [string]$Root,
    [string]$RelativePath,
    [ValidateSet('Leaf', 'Container')][string]$PathType,
    [object]$Failures,
    [object]$Passes
  )
  $path = Join-Path $Root $RelativePath
  if (Test-Path -LiteralPath $path -PathType $PathType) {
    $Passes.Add($RelativePath)
  } else {
    $label = if ($PathType -eq 'Leaf') { 'file' } else { 'directory' }
    $Failures.Add("🔴 Borrowing area lacks required $label`: $RelativePath")
  }
}

function Get-CzxtBorrowingInstallerItems {
  param([string]$InstallerText)
  $tokens = $null
  $parseErrors = $null
  $ast = [Management.Automation.Language.Parser]::ParseInput(
    $InstallerText, [ref]$tokens, [ref]$parseErrors)
  if ($parseErrors.Count -gt 0) {
    return [pscustomobject]@{
      Success = $false; Items = @(); Error = 'Cannot parse the instantiation script: ' + $parseErrors[0].Message
    }
  }
  $assignments = @($ast.FindAll({
      param($node)
      return ($node -is [Management.Automation.Language.AssignmentStatementAst] -and
        $node.Left -is [Management.Automation.Language.VariableExpressionAst] -and
        $node.Left.VariablePath.UserPath -ieq 'copyItems')
    }, $true))
  if ($assignments.Count -ne 1) {
    return [pscustomobject]@{
      Success = $false; Items = @(); Error = 'The instantiation script must declare $copyItems statically exactly once'
    }
  }
  $right = $assignments[0].Right
  $unsupported = @($right.FindAll({
      param($node)
      return @(
        'ArrayExpressionAst', 'ArrayLiteralAst', 'CommandExpressionAst',
        'PipelineAst', 'StatementBlockAst', 'StringConstantExpressionAst'
      ) -notcontains $node.GetType().Name
    }, $true))
  $strings = @($right.FindAll({
      param($node)
      return $node -is [Management.Automation.Language.StringConstantExpressionAst]
    }, $true) | ForEach-Object { $_.Value })
  if ($unsupported.Count -gt 0 -or $strings.Count -eq 0) {
    return [pscustomobject]@{
      Success = $false; Items = @(); Error = '$copyItems accepts only a static string array'
    }
  }
  return [pscustomobject]@{ Success = $true; Items = [string[]]$strings; Error = '' }
}

function Test-CzxtP4aPathWithinRoot {
  param([string]$CandidatePath, [string]$RootPath)
  $candidate = [IO.Path]::GetFullPath($CandidatePath).TrimEnd('\', '/')
  $root = [IO.Path]::GetFullPath($RootPath).TrimEnd('\', '/')
  if ($candidate.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { return $true }
  return $candidate.StartsWith(
    $root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

function Get-CzxtBorrowingCopyItemState {
  param([string]$Root, [string]$Item)
  try {
    $rootFull = [IO.Path]::GetFullPath($Root)
    $itemFull = [IO.Path]::GetFullPath((Join-Path $rootFull $Item))
    $borrowingFull = [IO.Path]::GetFullPath((Join-Path $rootFull '借鉴区'))
  }
  catch { return 'invalid' }
  if (-not (Test-CzxtP4aPathWithinRoot $itemFull $rootFull)) { return 'escape' }
  if ((Test-CzxtP4aPathWithinRoot $borrowingFull $itemFull) -or
      (Test-CzxtP4aPathWithinRoot $itemFull $borrowingFull)) {
    return 'borrowing'
  }
  return 'safe'
}

function Test-CzxtBorrowingInstaller {
  param([string]$Root, [object]$Failures, [object]$Passes)
  $installerPath = Join-Path $Root '实例化项目.ps1'
  $helperPath = Join-Path $Root '能力资产\tools\scripts\installer-borrowing-zone.ps1'
  $skeletonPath = Join-Path $Root '能力资产\tools\scripts\installer-borrowing-skeleton.ps1'
  if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    $Failures.Add('🔴 Borrowing-area guard requires 实例化项目.ps1')
    return
  }
  $helperText = ''
  $skeletonText = ''
  if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    $Failures.Add('🔴 Borrowing-area guard requires installer-borrowing-zone.ps1')
  } else {
    $helperText = [IO.File]::ReadAllText($helperPath)
  }
  if (-not (Test-Path -LiteralPath $skeletonPath -PathType Leaf)) {
    $Failures.Add('🔴 Borrowing-area guard requires installer-borrowing-skeleton.ps1')
  } else {
    $skeletonText = [IO.File]::ReadAllText($skeletonPath)
  }
  $installerText = [IO.File]::ReadAllText($installerPath)
  $copyItemsResult = Get-CzxtBorrowingInstallerItems $installerText
  $copyItemsSafe = $copyItemsResult.Success
  if (-not $copyItemsResult.Success) {
    $Failures.Add(('🔴 {0}' -f $copyItemsResult.Error))
  } else {
    foreach ($item in $copyItemsResult.Items) {
      $state = Get-CzxtBorrowingCopyItemState -Root $Root -Item $item
      if ($state -eq 'borrowing') {
        $Failures.Add('🔴 Instantiation script $copyItems must not recursively copy the borrowing area')
        $copyItemsSafe = $false
        break
      }
      if ($state -ne 'safe') {
        $Failures.Add(("🔴 Instantiation script `$copyItems path is invalid or escapes the root: {0}" -f $item))
        $copyItemsSafe = $false
        break
      }
    }
  }
  if ($copyItemsSafe) {
    $Passes.Add('Instantiation script excludes the borrowing area from recursive copying')
  }
  $anchors = @(
    @($installerText, 'installer-borrowing-zone.ps1', 'Instantiation script does not load the dedicated borrowing-area helper', 'Instantiation script loads the dedicated borrowing-area helper'),
    @($installerText, 'Copy-BorrowingZoneSkeleton', 'Instantiation script does not invoke dedicated borrowing-area copying', 'Instantiation script invokes dedicated borrowing-area copying'),
    @($installerText, 'Test-CzxtBorrowingPlaceholderRewriteAllowed', 'Instantiation script does not protect borrowing-card placeholder rewrites', 'Instantiation script protects borrowing-card placeholder rewrites'),
    @($helperText, 'installer-borrowing-skeleton.ps1', 'Main borrowing-area helper does not load the scaffold helper', 'Main borrowing-area helper loads the scaffold helper'),
    @($skeletonText, 'function Copy-BorrowingZoneSkeleton', 'Borrowing-area scaffold helper lacks the dedicated copy function', 'Borrowing-area scaffold helper provides the dedicated copy function'),
    @($helperText, 'function Test-CzxtBorrowingPlaceholderRewriteAllowed', 'Borrowing-area helper lacks the rewrite-protection function', 'Borrowing-area helper provides the rewrite-protection function')
  )
  foreach ($anchor in $anchors) {
    if (-not $anchor[0].Contains($anchor[1])) {
      $Failures.Add(('🔴 {0}' -f $anchor[2]))
    } else {
      $Passes.Add($anchor[3])
    }
  }
}

function Test-CzxtBorrowingScaffold {
  param(
    [string]$Root,
    [string]$RootMode,
    [object]$Failures,
    [object]$Passes
  )
  foreach ($relativePath in @(
      '借鉴区/README.md',
      '借鉴区/.gitignore',
      '借鉴区/模板/来源版本卡.md',
      '借鉴区/模板/借鉴卡.md')) {
    Test-CzxtBorrowingPath -Root $Root -RelativePath $relativePath `
      -PathType Leaf -Failures $Failures -Passes $Passes
  }
  foreach ($relativePath in @('借鉴区', '借鉴区/模板', '借鉴区/来源', '借鉴区/事项')) {
    Test-CzxtBorrowingPath -Root $Root -RelativePath $relativePath `
      -PathType Container -Failures $Failures -Passes $Passes
  }
  if ($RootMode -eq 'template') {
    foreach ($relativePath in @('借鉴区/来源/.gitkeep', '借鉴区/事项/.gitkeep')) {
      Test-CzxtBorrowingPath -Root $Root -RelativePath $relativePath `
        -PathType Leaf -Failures $Failures -Passes $Passes
    }
    Test-CzxtBorrowingInstaller -Root $Root -Failures $Failures -Passes $Passes
  }
}
