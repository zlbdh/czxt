$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'borrowing-scaffold-file-cas-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-scaffold-installer-race-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-scaffold-recovery-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-scaffold-directory-lock-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-scaffold-transaction-window-contracts.ps1')

function New-BorrowingInstallerSafetyTemplate {
  param([string]$TemplateRoot, [string]$FixtureRoot)

  $root = Join-Path $FixtureRoot 'minimal-template'
  [void](New-Item -ItemType Directory -Path $root -Force)
  foreach ($directory in @(
      '.codex', '.claude', '操作系统', '能力资产\tools\scripts', 'PM工作区',
      '交接区', '确认改动', '项目配置', 'Docs', '项目区\本地实例',
      '借鉴区\模板', '借鉴区\来源', '借鉴区\事项')) {
    [void](New-Item -ItemType Directory -Path (Join-Path $root $directory) -Force)
  }
  foreach ($file in @('.gitignore', 'AGENTS.md', 'README.md', '状态.md')) {
    Write-CzxtNoBomText (Join-Path $root $file) ("fixture={0}`n" -f $file)
  }
  foreach ($file in @('README.md', '清单.md', '.gitignore')) {
    Write-CzxtNoBomText (Join-Path $root ('项目区\' + $file)) ("fixture={0}`n" -f $file)
  }
  Write-CzxtNoBomText (Join-Path $root '项目区\本地实例\.gitkeep') ''

  [IO.File]::Copy(
    (Join-Path $TemplateRoot '实例化项目.ps1'),
    (Join-Path $root '实例化项目.ps1'), $true)
  foreach ($helper in @(
      'installer-borrowing-zone.ps1', 'installer-borrowing-skeleton.ps1',
      'installer-path-safety.ps1',
      'installer-file-safety.ps1', 'installer-source-copy.ps1',
      'installer-handle-lease.ps1',
      'installer-replace-transaction.ps1',
      'installer-output-manifest.ps1', 'installer-tree-plan.ps1',
      'installer-copy-expectation.ps1')) {
    [IO.File]::Copy(
      (Join-Path $TemplateRoot ('能力资产\tools\scripts\' + $helper)),
      (Join-Path $root ('能力资产\tools\scripts\' + $helper)), $true)
  }
  foreach ($relative in @(
      'README.md', '.gitignore', '模板\来源版本卡.md', '模板\借鉴卡.md',
      '来源\.gitkeep', '事项\.gitkeep')) {
    $source = Join-Path (Join-Path $TemplateRoot '借鉴区') $relative
    $target = Join-Path (Join-Path $root '借鉴区') $relative
    $parent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
      [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    [IO.File]::Copy($source, $target, $true)
  }
  return $root
}

function New-BorrowingSafetyJunction {
  param([string]$LinkPath, [string]$TargetPath, [object]$Links)
  [void](New-Item -ItemType Directory -Path $TargetPath -Force)
  $parent = Split-Path -Parent $LinkPath
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent -Force)
  }
  [void](New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath)
  $Links.Add($LinkPath)
}

function Remove-BorrowingSafetyJunctions {
  param([object]$Links)
  foreach ($link in @($Links | Sort-Object Length -Descending)) {
    if ([IO.Directory]::Exists($link)) { [IO.Directory]::Delete($link, $false) }
  }
  $Links.Clear()
}

function Invoke-BorrowingRejectedInstall {
  param(
    [string]$InstallerPath,
    [string]$ProjectRoot,
    [string]$AppRepoDir,
    [string[]]$MustRemainAbsent = @(),
    [switch]$Force
  )
  $arguments = @(
    '-ProjectRoot', $ProjectRoot, '-ProjectName', '路径安全 fixture',
    '-AppRepoDir', $AppRepoDir
  )
  if ($Force) { $arguments += '-Force' }
  $result = Invoke-CzxtPowerShell -ScriptPath $InstallerPath -ScriptArguments $arguments
  Assert-CzxtTrue ($result.ExitCode -ne 0) `
    ("installer accepted unsafe AppRepoDir <{0}>" -f $AppRepoDir)
  foreach ($path in $MustRemainAbsent) {
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $path)) `
      ("unsafe install wrote before rejection: {0}" -f $path)
  }
}

function Invoke-BorrowingPathSafetyContracts {
  param(
    [string]$TemplateRoot,
    [string]$FixtureRoot
  )

  $helperPath = Join-Path $TemplateRoot '能力资产\tools\scripts\installer-borrowing-zone.ps1'
  . $helperPath
  . (Join-Path $TemplateRoot '能力资产\tools\scripts\check-os\p4a-borrowing-assets.ps1')
  $minimalTemplate = New-BorrowingInstallerSafetyTemplate `
    -TemplateRoot $TemplateRoot -FixtureRoot $FixtureRoot
  $installer = Join-Path $minimalTemplate '实例化项目.ps1'
  $links = New-Object 'Collections.Generic.List[string]'

  Invoke-CzxtContract 'borrowing asset manifest includes the path-safety contract' {
    $manifest = Get-CzxtBorrowingAssetManifest -RootMode template
    Assert-CzxtTrue ($manifest.Files -ccontains `
        '能力资产/tools/scripts/check-os/tests/borrowing-scaffold-path-safety-contracts.ps1') `
      'borrowing asset manifest omitted the path-safety contract'
  }

  Invoke-CzxtContract 'borrowing skeleton rejects a junction before writing outside ProjectRoot' {
    $caseRoot = Join-Path $FixtureRoot 'borrowing-junction-case'
    $project = Join-Path $caseRoot 'project'
    $outside = Join-Path $caseRoot 'outside'
    [void](New-Item -ItemType Directory -Path $project -Force)
    New-BorrowingSafetyJunction -LinkPath (Join-Path $project '借鉴区') `
      -TargetPath $outside -Links $links
    try {
      $rejected = $false
      try {
        Copy-BorrowingZoneSkeleton -TemplateRoot $minimalTemplate -ProjectRoot $project
      }
      catch { $rejected = $true }
      Assert-CzxtTrue $rejected 'borrowing helper accepted a target junction'
      Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $outside 'README.md'))) `
        'borrowing helper wrote through a target junction'
    }
    finally { Remove-BorrowingSafetyJunctions $links }
  }

  Invoke-CzxtContract 'installer rejects ProjectRoot below recursive Docs source with zero writes' {
    $sourceMarker = Join-Path $minimalTemplate 'Docs\source-only.txt'
    Write-CzxtNoBomText $sourceMarker 'recursive-source-must-remain-unchanged'
    $sourceBefore = Get-BorrowingByteSignature $sourceMarker
    $project = Join-Path $minimalTemplate 'Docs\embedded-instance'
    $result = Invoke-CzxtPowerShell -ScriptPath $installer -ScriptArguments @(
      '-ProjectRoot', $project, '-ProjectName', '递归来源 fixture',
      '-AppRepoDir', 'app'
    ) -TimeoutMilliseconds 30000
    Assert-CzxtTrue ($result.ExitCode -ne 0) `
      'installer accepted ProjectRoot below the recursive Docs source'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $project)) `
      'installer wrote below the recursive Docs source before rejection'
    Assert-CzxtEqual $sourceBefore (Get-BorrowingByteSignature $sourceMarker) `
      'installer changed an existing Docs source file during rejection'
  }

  Invoke-CzxtContract 'installer keeps ProjectRoot below project local instances legal' {
    $project = Join-Path $minimalTemplate '项目区\本地实例\legal-instance'
    $result = Invoke-CzxtPowerShell -ScriptPath $installer -ScriptArguments @(
      '-ProjectRoot', $project, '-ProjectName', '本地实例 fixture',
      '-AppRepoDir', 'app'
    )
    Assert-CzxtEqual 0 $result.ExitCode `
      ("installer rejected a legal local instance: {0}" -f $result.StdErr)
    Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $project '.czxt-project-root') -PathType Leaf) `
      'legal local instance did not receive its project marker'
  }

  $cases = @(
    @{ Name = 'rooted'; Value = (Join-Path $FixtureRoot 'rooted-app'); Outside = 'rooted-app' },
    @{ Name = 'parent-escape'; Value = '..\outside-app'; Outside = 'outside-app' },
    @{ Name = 'blank'; Value = ' '; Outside = '' },
    @{ Name = 'borrowing-root'; Value = '借鉴区'; Outside = '' },
    @{ Name = 'borrowing-child'; Value = '借鉴区\来源\runtime'; Outside = '' }
  )
  foreach ($case in $cases) {
    Invoke-CzxtContract ("installer preflight rejects {0} AppRepoDir without writes" -f $case.Name) {
      $project = Join-Path $FixtureRoot ('app-case-' + $case.Name)
      $mustRemainAbsent = @($project)
      if (-not [string]::IsNullOrEmpty($case.Outside)) {
        $mustRemainAbsent += Join-Path $FixtureRoot $case.Outside
      }
      Invoke-BorrowingRejectedInstall -InstallerPath $installer -ProjectRoot $project `
        -AppRepoDir $case.Value -MustRemainAbsent $mustRemainAbsent
    }
  }

  Invoke-CzxtContract 'installer rejects an AppRepoDir reparse ancestor before writes' {
    $caseRoot = Join-Path $FixtureRoot 'app-reparse-case'
    $project = Join-Path $caseRoot 'project'
    $outside = Join-Path $caseRoot 'outside'
    [void](New-Item -ItemType Directory -Path $project -Force)
    New-BorrowingSafetyJunction -LinkPath (Join-Path $project 'linked') `
      -TargetPath $outside -Links $links
    try {
      Invoke-BorrowingRejectedInstall -InstallerPath $installer -ProjectRoot $project `
        -AppRepoDir 'linked\app' -Force -MustRemainAbsent @(
          (Join-Path $project 'README.md'), (Join-Path $outside 'app'),
          (Join-Path $project '.czxt-project-root'))
    }
    finally { Remove-BorrowingSafetyJunctions $links }
  }

  Invoke-CzxtContract 'installer -Force rejects an existing Docs junction before copying outside ProjectRoot' {
    $caseRoot = Join-Path $FixtureRoot 'copy-target-reparse-case'
    $project = Join-Path $caseRoot 'project'
    $outside = Join-Path $caseRoot 'outside'
    $sourceMarker = Join-Path $minimalTemplate 'Docs\installer-junction-escape.txt'
    Write-CzxtNoBomText $sourceMarker 'copy-target-reparse-regression'
    [void](New-Item -ItemType Directory -Path $project -Force)
    New-BorrowingSafetyJunction -LinkPath (Join-Path $project 'Docs') `
      -TargetPath $outside -Links $links
    try {
      $result = Invoke-CzxtPowerShell -ScriptPath $installer -ScriptArguments @(
        '-ProjectRoot', $project, '-ProjectName', '路径安全 fixture',
        '-AppRepoDir', 'app', '-Force'
      )
      $outsideMarkers = @(Get-ChildItem -LiteralPath $outside -Recurse -File `
        -Filter 'installer-junction-escape.txt' -ErrorAction SilentlyContinue)
      Assert-CzxtEqual 0 $outsideMarkers.Count `
        'installer copied through an existing Docs junction outside ProjectRoot'
      Assert-CzxtTrue ($result.ExitCode -ne 0) `
        'installer accepted an existing Docs junction with -Force'
      Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $project '.czxt-project-root'))) `
        'installer wrote the project marker after detecting an unsafe copy target'
    }
    finally {
      Remove-BorrowingSafetyJunctions $links
      if (Test-Path -LiteralPath $sourceMarker -PathType Leaf) {
        [IO.File]::Delete($sourceMarker)
      }
    }
  }

  Invoke-CzxtContract 'installer -Force rejects a hard-linked install target without changing its sentinel' {
    $caseRoot = Join-Path $FixtureRoot 'copy-target-hardlink-case'
    $project = Join-Path $caseRoot 'project'
    $outside = Join-Path $caseRoot 'outside'
    [void](New-Item -ItemType Directory -Path $project -Force)
    [void](New-Item -ItemType Directory -Path $outside -Force)
    $sentinel = Join-Path $outside 'README-sentinel.md'
    Write-CzxtNoBomText $sentinel "outside={{PROJECT_NAME}}`n"
    $before = Get-BorrowingByteSignature $sentinel
    [void](New-Item -ItemType HardLink -Path (Join-Path $project 'README.md') `
      -Target $sentinel)
    $result = Invoke-CzxtPowerShell -ScriptPath $installer -ScriptArguments @(
      '-ProjectRoot', $project, '-ProjectName', '硬链接 fixture',
      '-AppRepoDir', 'app', '-Force'
    )
    Assert-CzxtTrue ($result.ExitCode -ne 0) `
      'installer accepted a hard-linked install target with -Force'
    Assert-CzxtEqual $before (Get-BorrowingByteSignature $sentinel) `
      'installer changed bytes through a hard-linked install target'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $project '.czxt-project-root'))) `
      'installer wrote the project marker after detecting a hard-linked install target'
  }

  Invoke-BorrowingInstallerFileCasContracts -FixtureRoot $FixtureRoot
  Invoke-BorrowingInstallerRaceContracts -TemplateRoot $TemplateRoot `
    -FixtureRoot $FixtureRoot -MinimalTemplate $minimalTemplate -InstallerPath $installer
  Invoke-BorrowingInstallerRecoveryContracts -FixtureRoot $FixtureRoot
  Invoke-BorrowingInstallerDirectoryLockContracts -FixtureRoot $FixtureRoot
  Invoke-BorrowingInstallerTransactionWindowContracts -FixtureRoot $FixtureRoot
  Invoke-BorrowingInstallerFinalManifestContract -FixtureRoot $FixtureRoot `
    -InstallerPath $installer

  Invoke-CzxtContract 'installer rejects a ProjectRoot reparse ancestor before writes' {
    $caseRoot = Join-Path $FixtureRoot 'root-reparse-case'
    $outside = Join-Path $caseRoot 'outside'
    $link = Join-Path $caseRoot 'linked-root'
    New-BorrowingSafetyJunction -LinkPath $link -TargetPath $outside -Links $links
    try {
      $project = Join-Path $link 'project'
      Invoke-BorrowingRejectedInstall -InstallerPath $installer -ProjectRoot $project `
        -AppRepoDir 'app' -MustRemainAbsent @($project)
    }
    finally { Remove-BorrowingSafetyJunctions $links }
  }
}
