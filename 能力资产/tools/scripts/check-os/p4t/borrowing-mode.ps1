$ErrorActionPreference = 'Stop'

$null = . (Join-Path $PSScriptRoot 'borrowing-common.ps1')

function global:Add-P4tModeFailure {
  param([Collections.Generic.List[string]]$Failures, [string]$Message)
  if (-not $Failures.Contains($Message)) { [void]$Failures.Add($Message) }
}

function global:Test-P4tTemplateDirectoryShape {
  param(
    [string]$Path,
    [string[]]$ExpectedFiles,
    [string[]]$ExpectedDirectories,
    [Collections.Generic.List[string]]$Failures
  )

  try {
    $null = Get-BorrowingSafePathInfo -Path $Path -ExpectedKind Directory `
      -Stage 'p4t-mode' -ReasonCode 'unsafe-template-path'
  }
  catch {
    Add-P4tModeFailure $Failures ('Invalid template directory: {0}' -f $Path)
    return
  }

  $entries = @(Get-ChildItem -LiteralPath $Path -Force)
  foreach ($name in $ExpectedFiles) {
    $entry = @($entries | Where-Object { -not $_.PSIsContainer -and $_.Name -ceq $name })
    if ($entry.Count -ne 1) {
      Add-P4tModeFailure $Failures ('Missing file: {0}' -f (Join-Path $Path $name))
      continue
    }
    try {
      $null = Get-BorrowingSafePathInfo -Path $entry[0].FullName -ExpectedKind File `
        -Stage 'p4t-mode' -ReasonCode 'unsafe-template-path'
    }
    catch {
      Add-P4tModeFailure $Failures ('Unsafe file: {0}' -f $entry[0].FullName)
    }
  }
  foreach ($name in $ExpectedDirectories) {
    $entry = @($entries | Where-Object { $_.PSIsContainer -and $_.Name -ceq $name })
    if ($entry.Count -ne 1) {
      Add-P4tModeFailure $Failures ('Missing directory: {0}' -f (Join-Path $Path $name))
    }
  }

  foreach ($entry in $entries) {
    $allowed = if ($entry.PSIsContainer) {
      $ExpectedDirectories -ccontains $entry.Name
    }
    else {
      $ExpectedFiles -ccontains $entry.Name
    }
    if (-not $allowed) {
      Add-P4tModeFailure $Failures ('The template contains a concrete item: {0}' -f $entry.FullName)
    }
  }
}

function global:Get-P4tInstallerItems {
  param([string]$InstallerText)

  $tokens = $null
  $parseErrors = $null
  $ast = [Management.Automation.Language.Parser]::ParseInput(
    $InstallerText, [ref]$tokens, [ref]$parseErrors)
  if ($parseErrors.Count -gt 0) {
    return [pscustomobject]@{ Success = $false; Items = @(); Error = 'Instantiation script could not be parsed' }
  }
  $assignments = @($ast.FindAll({
      param($node)
      return ($node -is [Management.Automation.Language.AssignmentStatementAst] -and
        $node.Left -is [Management.Automation.Language.VariableExpressionAst] -and
        $node.Left.VariablePath.UserPath -ieq 'copyItems')
    }, $true))
  if ($assignments.Count -ne 1) {
    return [pscustomobject]@{
      Success = $false; Items = @(); Error = '$copyItems 非唯一静态数组'
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
      Success = $false; Items = @(); Error = '$copyItems 须为静态字符串数组'
    }
  }
  return [pscustomobject]@{ Success = $true; Items = [string[]]$strings; Error = '' }
}

function global:Test-P4tPathWithinRoot {
  param([string]$CandidatePath, [string]$RootPath)
  $candidate = [IO.Path]::GetFullPath($CandidatePath).TrimEnd('\', '/')
  $root = [IO.Path]::GetFullPath($RootPath).TrimEnd('\', '/')
  if ($candidate.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { return $true }
  return $candidate.StartsWith(
    $root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

function global:Test-P4tInstallerContract {
  param([string]$Root, [Collections.Generic.List[string]]$Failures)

  $installerPath = Join-Path $Root '实例化项目.ps1'
  $zoneHelperPath = Join-Path $Root '能力资产\tools\scripts\installer-borrowing-zone.ps1'
  $skeletonHelperPath = Join-Path $Root '能力资产\tools\scripts\installer-borrowing-skeleton.ps1'
  $texts = @{}
  foreach ($entry in @(
      [pscustomobject]@{ Name = 'installer'; Path = $installerPath },
      [pscustomobject]@{ Name = 'zoneHelper'; Path = $zoneHelperPath },
      [pscustomobject]@{ Name = 'skeletonHelper'; Path = $skeletonHelperPath })) {
    try {
      $null = Get-BorrowingSafePathInfo -Path $entry.Path -ExpectedKind File `
        -Stage 'p4t-mode' -ReasonCode 'unsafe-installer-path'
      $texts[$entry.Name] = [IO.File]::ReadAllText($entry.Path)
    }
    catch {
      Add-P4tModeFailure $Failures ('Missing or unsafe: {0}' -f $entry.Path)
      $texts[$entry.Name] = ''
    }
  }
  if ([string]::IsNullOrEmpty($texts.installer)) { return }

  $copyItems = Get-P4tInstallerItems $texts.installer
  if (-not $copyItems.Success) {
    Add-P4tModeFailure $Failures $copyItems.Error
  }
  else {
    $borrowingRoot = [IO.Path]::GetFullPath((Join-Path $Root '借鉴区'))
    foreach ($item in $copyItems.Items) {
      try { $itemPath = [IO.Path]::GetFullPath((Join-Path $Root $item)) }
      catch {
        Add-P4tModeFailure $Failures ('Invalid $copyItems path: {0}' -f $item)
        continue
      }
      if (-not (Test-P4tPathWithinRoot $itemPath $Root) -or
          (Test-P4tPathWithinRoot $borrowingRoot $itemPath) -or
          (Test-P4tPathWithinRoot $itemPath $borrowingRoot)) {
        Add-P4tModeFailure $Failures '$copyItems must not include the borrowing area or escape its bounds'
      }
    }
  }

  foreach ($anchor in @(
      @($texts.installer, 'installer-borrowing-zone.ps1', 'Instantiation script lacks a helper'),
      @($texts.installer, 'Copy-BorrowingZoneSkeleton', 'Instantiation script lacks dedicated copying'),
      @($texts.installer, 'Test-CzxtBorrowingPlaceholderRewriteAllowed', 'Instantiation script lacks card protection'),
      @($texts.zoneHelper, 'installer-borrowing-skeleton.ps1', 'Helper does not load the scaffold helper'),
      @($texts.zoneHelper, 'function Test-CzxtBorrowingPlaceholderRewriteAllowed', 'Helper lacks rewrite protection'),
      @($texts.skeletonHelper, 'function Copy-BorrowingZoneSkeleton', 'Scaffold helper lacks dedicated copying'))) {
    if (-not $anchor[0].Contains($anchor[1])) {
      Add-P4tModeFailure $Failures $anchor[2]
    }
  }
}

function global:Test-P4tTemplateSkeleton {
  param([string]$Root, [Collections.Generic.List[string]]$Failures)

  $borrowingRoot = Join-Path $Root '借鉴区'
  Test-P4tTemplateDirectoryShape -Path $borrowingRoot `
    -ExpectedFiles @('README.md', '.gitignore') `
    -ExpectedDirectories @('模板', '来源', '事项') -Failures $Failures

  foreach ($shape in @(
      [pscustomobject]@{ Relative = '模板'; Files = @('来源版本卡.md', '借鉴卡.md') },
      [pscustomobject]@{ Relative = '来源'; Files = @('.gitkeep') },
      [pscustomobject]@{ Relative = '事项'; Files = @('.gitkeep') })) {
    Test-P4tTemplateDirectoryShape -Path (Join-Path $borrowingRoot $shape.Relative) `
      -ExpectedFiles $shape.Files -ExpectedDirectories @() -Failures $Failures
  }

  Test-P4tInstallerContract -Root $Root -Failures $Failures
}

function global:Invoke-BorrowingP4tModeCheck {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string]$Root)

  $warnings = New-Object Collections.Generic.List[string]
  $failures = New-Object Collections.Generic.List[string]
  $mode = 'unknown'
  try {
    $safeRoot = Resolve-BorrowingP4tSafeRoot -Root $Root
  }
  catch {
    Add-P4tModeFailure $failures 'Invalid Root'
    return New-BorrowingP4tCheckResult -Mode $mode -Warnings $warnings -Failures $failures
  }

  $hasTemplateMarker = Test-Path -LiteralPath (Join-Path $safeRoot '.czxt-template-root') -PathType Leaf
  $hasProjectMarker = Test-Path -LiteralPath (Join-Path $safeRoot '.czxt-project-root') -PathType Leaf
  if ($hasTemplateMarker -and $hasProjectMarker) {
    $mode = 'conflict'
  }
  elseif ($hasTemplateMarker) {
    $mode = 'template'
  }
  elseif ($hasProjectMarker) {
    $mode = 'project'
  }

  if ($mode -eq 'unknown') {
    Add-P4tModeFailure $failures 'Root lacks a marker'
  }
  elseif ($mode -eq 'conflict') {
    Add-P4tModeFailure $failures 'Conflicting Root markers'
  }
  elseif ($mode -eq 'template') {
    Test-P4tTemplateSkeleton -Root $safeRoot -Failures $failures
  }

  return New-BorrowingP4tCheckResult -Mode $mode -Warnings $warnings -Failures $failures
}
