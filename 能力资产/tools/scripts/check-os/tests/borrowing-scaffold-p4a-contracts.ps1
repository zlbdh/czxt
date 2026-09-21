$ErrorActionPreference = 'Stop'

function Initialize-BorrowingGuardFixture {
  param([string]$TemplateRoot, [string]$GuardRoot, [string[]]$SkeletonPaths)
  foreach ($relativePath in $SkeletonPaths) {
    $target = Join-Path $GuardRoot ($relativePath.Replace('/', '\'))
    [void](New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force)
    [IO.File]::WriteAllText($target, '', $script:CzxtUtf8NoBom)
  }
  foreach ($helper in @(
      'installer-borrowing-zone.ps1', 'installer-borrowing-skeleton.ps1',
      'installer-path-safety.ps1',
      'installer-file-safety.ps1', 'installer-source-copy.ps1',
      'installer-handle-lease.ps1',
      'installer-replace-transaction.ps1',
      'installer-output-manifest.ps1', 'installer-render-text.ps1', 'installer-tree-plan.ps1',
      'installer-copy-expectation.ps1')) {
    $source = Join-Path $TemplateRoot ('能力资产\tools\scripts\' + $helper)
    $target = Join-Path $GuardRoot ('能力资产\tools\scripts\' + $helper)
    [void](New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force)
    [IO.File]::Copy($source, $target, $true)
  }
}

function Invoke-BorrowingP4aGuardContracts {
  param([string]$TemplateRoot, [string]$FixtureRoot, [string[]]$SkeletonPaths)

  Invoke-CzxtContract 'P4a borrowing guard normalizes static copyItems paths' {
    $helperPath = Join-Path $TemplateRoot '能力资产\tools\scripts\check-os\p4a-borrowing-scaffold.ps1'
    Assert-CzxtTrue (Test-Path -LiteralPath $helperPath -PathType Leaf) 'P4a borrowing helper is missing'
    . $helperPath
    $guardRoot = Join-Path $FixtureRoot 'guard-template'
    Initialize-BorrowingGuardFixture -TemplateRoot $TemplateRoot `
      -GuardRoot $guardRoot -SkeletonPaths $SkeletonPaths
    $installerTemplate = @'
. (Join-Path $TemplateRoot "能力资产\tools\scripts\installer-borrowing-zone.ps1")
{COPY_ITEMS}
Copy-BorrowingZoneSkeleton -TemplateRoot $TemplateRoot -ProjectRoot $ProjectRoot
$files | Where-Object { Test-CzxtBorrowingPlaceholderRewriteAllowed -ProjectRoot $ProjectRoot -CandidatePath $_.FullName }
'@
    $unsafeCases = @(
      @{ Name = 'double quote exact'; Code = '$copyItems = @("借鉴区")' },
      @{ Name = 'single quote exact'; Code = '$copyItems = @(''借鉴区'')' },
      @{ Name = 'dot backslash'; Code = '$copyItems = @(".\借鉴区")' },
      @{ Name = 'dot slash trailing'; Code = '$copyItems = @("./借鉴区/")' },
      @{ Name = 'root covers borrowing'; Code = '$copyItems = @(".")' },
      @{ Name = 'borrowing child'; Code = '$copyItems = @("借鉴区\模板")' }
    )
    $installerPath = Join-Path $guardRoot '实例化项目.ps1'
    foreach ($case in $unsafeCases) {
      $text = $installerTemplate.Replace('{COPY_ITEMS}', $case.Code)
      [IO.File]::WriteAllText($installerPath, $text, $script:CzxtUtf8Bom)
      $failures = New-Object 'Collections.Generic.List[string]'
      $passes = New-Object 'Collections.Generic.List[string]'
      Test-CzxtBorrowingScaffold -Root $guardRoot -RootMode 'template' `
        -Failures $failures -Passes $passes
      Assert-CzxtTrue (($failures -join "`n").Contains('不得递归复制借鉴区')) `
        ("copyItems bypass was accepted: {0}" -f $case.Name)
    }
    $safeText = $installerTemplate.Replace('{COPY_ITEMS}', '$copyItems = @("借鉴区2")')
    [IO.File]::WriteAllText($installerPath, $safeText, $script:CzxtUtf8Bom)
    $safeFailures = New-Object 'Collections.Generic.List[string]'
    $safePasses = New-Object 'Collections.Generic.List[string]'
    Test-CzxtBorrowingScaffold -Root $guardRoot -RootMode 'template' `
      -Failures $safeFailures -Passes $safePasses
    Assert-CzxtEqual 0 $safeFailures.Count 'neighbor path must not be treated as 借鉴区'
  }
}
