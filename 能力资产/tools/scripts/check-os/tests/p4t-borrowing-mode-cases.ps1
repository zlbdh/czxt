[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-item-test-support.ps1')

Initialize-P4tTestFixture
try {
  $template = New-TemplateSkeleton 'mode-template'
  $project = New-ProjectSkeleton 'mode-project'
  $unknown = New-TemplateSkeleton 'mode-unknown'
  Remove-Item -LiteralPath (Join-Path $unknown '.czxt-template-root') -Force
  $conflict = New-TemplateSkeleton 'mode-conflict'
  Write-P4tUtf8 (Join-Path $conflict '.czxt-project-root') "czxt-root-mode=project`nschema=1`n"

  $templateSource = New-TemplateSkeleton 'mode-template-source'
  [void](New-P4tSourceCapture -Root $templateSource -SourceType local)
  $templateItem = New-TemplateSkeleton 'mode-template-item'
  $itemSource = New-P4tSourceCapture -Root $templateItem -SourceType local
  [void](New-P4tItemCard -Root $templateItem -BorrowId 'borrow-20260719-template' `
    -Bindings @($itemSource) -Status assessing -Decision pending)

  $missingTemplate = New-TemplateSkeleton 'mode-missing-template'
  Remove-Item -LiteralPath (Join-Path $missingTemplate '借鉴区\模板\来源版本卡.md') -Force
  $missingItemTemplate = New-TemplateSkeleton 'mode-missing-item-template'
  Remove-Item -LiteralPath (Join-Path $missingItemTemplate '借鉴区\模板\借鉴卡.md') -Force
  $missingInstaller = New-TemplateSkeleton 'mode-missing-installer'
  Remove-Item -LiteralPath (Join-Path $missingInstaller '实例化项目.ps1') -Force
  $missingSkeletonHelper = New-TemplateSkeleton 'mode-missing-skeleton-helper'
  Remove-Item -LiteralPath (Join-Path $missingSkeletonHelper `
      '能力资产\tools\scripts\installer-borrowing-skeleton.ps1') -Force
  $missingSkeletonLoad = New-TemplateSkeleton 'mode-missing-skeleton-load'
  $zonePath = Join-Path $missingSkeletonLoad `
    '能力资产\tools\scripts\installer-borrowing-zone.ps1'
  $zoneText = [IO.File]::ReadAllText($zonePath, $script:P4tUtf8Bom)
  Write-Utf8Bom $zonePath $zoneText.Replace(
    'installer-borrowing-skeleton.ps1', 'installer-removed-skeleton.ps1')
  $recursiveInstaller = New-TemplateSkeleton 'mode-recursive-installer'
  $recursivePath = Join-Path $recursiveInstaller '实例化项目.ps1'
  $recursiveText = [IO.File]::ReadAllText($recursivePath, $script:P4tUtf8Bom)
  $recursiveText = [regex]::Replace($recursiveText, '\$copyItems\s*=\s*@\(',
    "`$copyItems = @(`r`n    `"借鉴区`",", 1)
  Write-Utf8Bom $recursivePath $recursiveText
  $missingAnchor = New-TemplateSkeleton 'mode-missing-anchor'
  $anchorPath = Join-Path $missingAnchor '实例化项目.ps1'
  $anchorText = [IO.File]::ReadAllText($anchorPath, $script:P4tUtf8Bom)
  Write-Utf8Bom $anchorPath $anchorText.Replace('Copy-BorrowingZoneSkeleton', 'Copy-RemovedSkeleton')

  $cases = @(
    [pscustomobject]@{ Name = 'template-only empty distributable skeleton'; Root = $template; Exit = 0; Mode = 'template' },
    [pscustomobject]@{ Name = 'project-only empty skeleton'; Root = $project; Exit = 0; Mode = 'project' },
    [pscustomobject]@{ Name = 'no root marker'; Root = $unknown; Exit = 10; Mode = 'unknown' },
    [pscustomobject]@{ Name = 'conflicting root markers'; Root = $conflict; Exit = 10; Mode = 'conflict' },
    [pscustomobject]@{ Name = 'template contains a concrete source capture'; Root = $templateSource; Exit = 10; Mode = 'template' },
    [pscustomobject]@{ Name = 'template contains a concrete borrowing item'; Root = $templateItem; Exit = 10; Mode = 'template' },
    [pscustomobject]@{ Name = 'template misses source-card template'; Root = $missingTemplate; Exit = 10; Mode = 'template' },
    [pscustomobject]@{ Name = 'template misses item-card template'; Root = $missingItemTemplate; Exit = 10; Mode = 'template' },
    [pscustomobject]@{ Name = 'template misses installer'; Root = $missingInstaller; Exit = 10; Mode = 'template' },
    [pscustomobject]@{ Name = 'template misses skeleton helper'; Root = $missingSkeletonHelper; Exit = 10; Mode = 'template' },
    [pscustomobject]@{ Name = 'zone helper loses skeleton load'; Root = $missingSkeletonLoad; Exit = 10; Mode = 'template' },
    [pscustomobject]@{ Name = 'installer recursively copies borrowing zone'; Root = $recursiveInstaller; Exit = 10; Mode = 'template' },
    [pscustomobject]@{ Name = 'installer loses dedicated copy anchor'; Root = $missingAnchor; Exit = 10; Mode = 'template' }
  )

  Invoke-CzxtContract 'mode fixtures are isolated and fully constructed before helper discovery' {
    Assert-CzxtEqual $cases.Count (@($cases | Select-Object -ExpandProperty Root -Unique)).Count `
      'mode fixture roots must be unique'
    foreach ($case in $cases) {
      Assert-P4tPathInside -Path $case.Root -Parent $script:P4tFixtureRoot -Context $case.Name | Out-Null
      Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $case.Root '借鉴区') -PathType Container) `
        ($case.Name + ' lost borrowing root')
    }
    $allowed = @(@(
      '.gitignore', 'README.md', '事项/.gitkeep', '来源/.gitkeep',
      '模板/借鉴卡.md', '模板/来源版本卡.md'
    ) | Sort-Object)
    $actual = @(Get-ChildItem -LiteralPath (Join-Path $template '借鉴区') -Recurse -Force -File |
      ForEach-Object { $_.FullName.Substring((Join-Path $template '借鉴区').Length + 1) -replace '\\', '/' } |
      Sort-Object)
    Assert-CzxtEqual ($allowed -join '|') ($actual -join '|') 'template borrowing distributable state'
  }

  $script:ModeHelperReady = $false
  Invoke-CzxtContract 'P4t mode helper exists with its dedicated leaf API' {
    Import-P4tHelper -FileName 'borrowing-mode.ps1' -CommandName 'Invoke-BorrowingP4tModeCheck'
    $script:ModeHelperReady = $true
  }

  if ($script:ModeHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('mode: ' + $case.Name) {
        $before = Get-P4tTreeState $case.Root
        $result = Invoke-BorrowingP4tModeCheck -Root $case.Root
        Assert-P4tResult $result $case.Exit $case.Name
        Assert-CzxtEqual $case.Mode ([string]$result.Mode) ($case.Name + ' RootMode')
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $case.Root) ($case.Name + ' read-only')
      }
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
