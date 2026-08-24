$ErrorActionPreference = 'Stop'

function Invoke-BorrowingInstallerDirectoryLockContracts {
  param([string]$FixtureRoot)

  Invoke-CzxtContract 'all ProjectRoot child directory mutations use the bound creator' {
    $scriptsRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
    foreach ($name in @(
        'installer-borrowing-zone.ps1', 'installer-borrowing-skeleton.ps1',
        'installer-file-safety.ps1')) {
      $text = [IO.File]::ReadAllText((Join-Path $scriptsRoot $name))
      Assert-CzxtTrue (-not [regex]::IsMatch(
          $text, 'New-Item\s+-ItemType\s+Directory', 'IgnoreCase')) `
        ('raw ProjectRoot directory mutation remains: ' + $name)
    }
    $installer = [IO.File]::ReadAllText(
      [IO.Path]::GetFullPath((Join-Path $scriptsRoot '..\..\..\实例化项目.ps1')))
    Assert-CzxtEqual 0 ([regex]::Matches(
        $installer, 'New-Item\s+-ItemType\s+Directory', 'IgnoreCase').Count) `
      'ProjectRoot creation must not remain a raw directory mutation'
    Assert-CzxtTrue $installer.Contains('New-CzxtInstallerBoundProjectRoot') `
      'installer does not use the bound ProjectRoot creator'
    Assert-CzxtTrue $installer.Contains('New-CzxtInstallerBoundDirectory') `
      'installer does not use the bound directory creator'
  }

  Invoke-CzxtContract 'bound ProjectRoot creation rejects a late junction without outside writes' {
    $caseRoot = Join-Path $FixtureRoot 'project-root-late-junction'
    $existingParent = Join-Path $caseRoot 'existing-parent'
    $outside = Join-Path $caseRoot 'outside'
    $project = Join-Path $existingParent 'late-root\project'
    $link = Join-Path $existingParent 'late-root'
    [void](New-Item -ItemType Directory -Path $existingParent -Force)
    [void](New-Item -ItemType Directory -Path $outside -Force)
    [void](Assert-CzxtBorrowingNoReparseAncestor `
      -Path $project -Context 'ProjectRoot RED preflight')
    Assert-CzxtTrue ($null -ne (Get-Command New-CzxtInstallerBoundProjectRoot `
          -ErrorAction SilentlyContinue)) 'bound ProjectRoot creator is missing'
    $script:CzxtProjectRootRaceHookRan = $false
    $insertLateJunction = {
      param([string]$HookParent, [string]$HookNext)
      if (-not $HookNext.Equals($link, [StringComparison]::OrdinalIgnoreCase)) { return }
      $script:CzxtProjectRootRaceHookRan = $true
      [void](New-Item -ItemType Junction -Path $HookNext -Target $outside)
    }
    $rejected = $false
    try {
      [void](New-CzxtInstallerBoundProjectRoot -ProjectRoot $project `
        -Context 'ProjectRoot late junction' -BeforeParentLease $insertLateJunction)
    }
    catch { $rejected = $true }
    finally {
      if ([IO.Directory]::Exists($link)) { [IO.Directory]::Delete($link, $false) }
    }
    Assert-CzxtTrue $script:CzxtProjectRootRaceHookRan `
      'late ProjectRoot junction hook did not run'
    Assert-CzxtTrue $rejected 'bound ProjectRoot creator accepted a late junction'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $outside 'project'))) `
      'bound ProjectRoot creator wrote through a late junction'
  }

  Invoke-CzxtContract 'bound ProjectRoot creation keeps its parent locked through child creation' {
    $caseRoot = Join-Path $FixtureRoot 'project-root-parent-lock'
    $existingParent = Join-Path $caseRoot 'existing-parent'
    $savedParent = Join-Path $caseRoot 'existing-parent.before'
    $outside = Join-Path $caseRoot 'outside'
    $project = Join-Path $existingParent 'child\project'
    [void](New-Item -ItemType Directory -Path $existingParent -Force)
    [void](New-Item -ItemType Directory -Path $outside -Force)
    $script:CzxtProjectRootParentHookRan = $false
    $script:CzxtProjectRootParentSwapBlocked = $false
    $script:CzxtProjectRootParentSwapSucceeded = $false
    $swapLockedParent = {
      param([string]$HookParent, [string]$HookNext)
      if (-not $HookParent.Equals(
          $existingParent, [StringComparison]::OrdinalIgnoreCase)) { return }
      $script:CzxtProjectRootParentHookRan = $true
      try {
        [IO.Directory]::Move($HookParent, $savedParent)
        [void](New-Item -ItemType Junction -Path $HookParent -Target $outside)
        $script:CzxtProjectRootParentSwapSucceeded = $true
      }
      catch { $script:CzxtProjectRootParentSwapBlocked = $true }
    }
    $caught = $null
    try {
      [void](New-CzxtInstallerBoundProjectRoot -ProjectRoot $project `
        -Context 'ProjectRoot parent lock' -AfterParentLease $swapLockedParent)
    }
    catch { $caught = $_.Exception }
    finally {
      $parentItem = Get-Item -LiteralPath $existingParent -Force -ErrorAction SilentlyContinue
      if ($null -ne $parentItem -and
          ($parentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        [IO.Directory]::Delete($existingParent, $false)
      }
      if ([IO.Directory]::Exists($savedParent) -and
          -not [IO.Directory]::Exists($existingParent)) {
        [IO.Directory]::Move($savedParent, $existingParent)
      }
    }
    Assert-CzxtTrue $script:CzxtProjectRootParentHookRan `
      'ProjectRoot parent-lock hook did not run'
    Assert-CzxtTrue $script:CzxtProjectRootParentSwapBlocked `
      'ProjectRoot parent could be renamed after its lease opened'
    Assert-CzxtTrue (-not $script:CzxtProjectRootParentSwapSucceeded) `
      'ProjectRoot parent swap unexpectedly succeeded'
    Assert-CzxtTrue ($null -eq $caught) `
      ('bound ProjectRoot creation failed: ' + `
        $(if ($null -eq $caught) { '' } else { $caught.Message }))
    Assert-CzxtTrue ([IO.Directory]::Exists($project)) `
      'bound ProjectRoot creator did not create the requested path'
    Assert-CzxtTrue (-not [IO.Directory]::Exists((Join-Path $outside 'child'))) `
      'bound ProjectRoot creator wrote through a swapped parent'
  }

  Invoke-CzxtContract 'bound directory creation rejects three pre-lease reparse insertions' {
    foreach ($case in @(
        @{ Name = 'pz'; Relative = '项目区\本地实例'; Link = '项目区'; Child = '本地实例' },
        @{ Name = 'ensure'; Relative = 'Docs\1-需求文档'; Link = 'Docs'; Child = '1-需求文档' },
        @{ Name = 'app'; Relative = 'app\src'; Link = 'app'; Child = 'src' })) {
      $caseRoot = Join-Path $FixtureRoot ('directory-create-' + $case.Name)
      $project = Join-Path $caseRoot 'project'
      $outside = Join-Path $caseRoot 'outside'
      [void](New-Item -ItemType Directory -Path $project -Force)
      [void](New-Item -ItemType Directory -Path $outside -Force)
      $link = Join-Path $project $case.Link
      $script:CzxtDirectoryCreateHookRan = $false
      $insertReparse = {
        param([string]$HookParent, [string]$HookNext)
        if (-not $HookNext.Equals($link, [StringComparison]::OrdinalIgnoreCase)) { return }
        $script:CzxtDirectoryCreateHookRan = $true
        [void](New-Item -ItemType Junction -Path $HookNext -Target $outside)
      }
      $rejected = $false
      try {
        [void](New-CzxtInstallerBoundDirectory -ProjectRoot $project `
          -TargetPath (Join-Path $project $case.Relative) `
          -Context ('directory create ' + $case.Name) `
          -BeforeParentLease $insertReparse)
      }
      catch { $rejected = $true }
      finally {
        if ([IO.Directory]::Exists($link)) { [IO.Directory]::Delete($link, $false) }
      }
      Assert-CzxtTrue $script:CzxtDirectoryCreateHookRan `
        ('directory create hook did not run: ' + $case.Name)
      Assert-CzxtTrue $rejected ('directory create accepted reparse: ' + $case.Name)
      Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $outside $case.Child))) `
        ('directory create wrote outside ProjectRoot: ' + $case.Name)
    }
  }

  Invoke-CzxtContract 'directory lease rejects a pre-open replacement before creating its marker' {
    $caseRoot = Join-Path $FixtureRoot 'target-directory-pre-open-window'
    $template = Join-Path $caseRoot 'template'
    $project = Join-Path $caseRoot 'project'
    $sourceRoot = Join-Path $template 'Docs'
    $targetRoot = Join-Path $project 'Docs'
    $savedTarget = Join-Path $project 'Docs-before-window'
    [void](New-Item -ItemType Directory -Path $sourceRoot -Force)
    [void](New-Item -ItemType Directory -Path $targetRoot -Force)
    Write-CzxtNoBomText (Join-Path $sourceRoot 'child.md') 'trusted-child'
    $entry = New-CzxtInstallerCopyPlanEntry -ProjectRoot $project `
      -SourcePath $sourceRoot -TargetPath $targetRoot -Item 'Docs' -Force
    $script:CzxtDirectoryPreOpenHookRan = $false
    $script:CzxtDirectoryPreOpenWatcher = $null
    $script:CzxtDirectoryPreOpenEventId = 'czxt-dir-marker-' + [guid]::NewGuid().ToString('N')
    $replaceBeforeOpen = {
      param([string]$HookTarget)
      if (-not $HookTarget.Equals($targetRoot, [StringComparison]::OrdinalIgnoreCase)) { return }
      $script:CzxtDirectoryPreOpenHookRan = $true
      [IO.Directory]::Move($HookTarget, $savedTarget)
      [void](New-Item -ItemType Directory -Path $HookTarget)
      $watcher = New-Object IO.FileSystemWatcher($HookTarget, '.czxt-dir-lock-*.tmp')
      $watcher.EnableRaisingEvents = $true
      $script:CzxtDirectoryPreOpenWatcher = $watcher
      $null = Register-ObjectEvent -InputObject $watcher -EventName Created `
        -SourceIdentifier $script:CzxtDirectoryPreOpenEventId
    }
    $rejected = $false
    try {
      Copy-CzxtInstallerTree -TemplateRoot $template -ProjectRoot $project `
        -SourcePath $sourceRoot -TargetPath $targetRoot -TreePlan $entry.TreePlan `
        -BeforeTargetDirectoryLeaseOpen $replaceBeforeOpen
    }
    catch { $rejected = $true }
    $markerEvent = Wait-Event -SourceIdentifier $script:CzxtDirectoryPreOpenEventId -Timeout 1
    if ($null -ne $markerEvent) { Remove-Event -EventIdentifier $markerEvent.EventIdentifier }
    Unregister-Event -SourceIdentifier $script:CzxtDirectoryPreOpenEventId -ErrorAction SilentlyContinue
    if ($null -ne $script:CzxtDirectoryPreOpenWatcher) {
      $script:CzxtDirectoryPreOpenWatcher.Dispose()
    }
    Assert-CzxtTrue $script:CzxtDirectoryPreOpenHookRan `
      'pre-open directory replacement hook did not run'
    Assert-CzxtTrue $rejected 'directory lease adopted a pre-open replacement'
    Assert-CzxtTrue ($null -eq $markerEvent) `
      'directory lease created a marker in the untrusted replacement'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $targetRoot 'child.md'))) `
      'directory lease wrote a child into the untrusted replacement'
  }

  Invoke-CzxtContract 'target directory stays locked from validation through child landing' {
    $caseRoot = Join-Path $FixtureRoot 'target-directory-lock-window'
    $template = Join-Path $caseRoot 'template'
    $project = Join-Path $caseRoot 'project'
    $sourceRoot = Join-Path $template 'Docs'
    $targetRoot = Join-Path $project 'Docs'
    $savedTarget = Join-Path $project 'Docs-before-window'
    [void](New-Item -ItemType Directory -Path $sourceRoot -Force)
    [void](New-Item -ItemType Directory -Path $targetRoot -Force)
    Write-CzxtNoBomText (Join-Path $sourceRoot 'child.md') 'trusted-child'
    $entry = New-CzxtInstallerCopyPlanEntry -ProjectRoot $project `
      -SourcePath $sourceRoot -TargetPath $targetRoot -Item 'Docs' -Force
    $script:CzxtDirectoryWindowHookRan = $false
    $script:CzxtDirectoryWindowBlocked = $false
    $swapDirectory = {
      param([string]$HookTarget)
      if (-not $HookTarget.Equals($targetRoot, [StringComparison]::OrdinalIgnoreCase)) { return }
      $script:CzxtDirectoryWindowHookRan = $true
      try {
        [IO.Directory]::Move($HookTarget, $savedTarget)
        [void](New-Item -ItemType Directory -Path $HookTarget)
      }
      catch { $script:CzxtDirectoryWindowBlocked = $true }
    }
    Copy-CzxtInstallerTree -TemplateRoot $template -ProjectRoot $project `
      -SourcePath $sourceRoot -TargetPath $targetRoot -TreePlan $entry.TreePlan `
      -AfterTargetDirectoryValidation $swapDirectory
    Assert-CzxtTrue $script:CzxtDirectoryWindowHookRan `
      'target directory window hook did not run'
    Assert-CzxtTrue $script:CzxtDirectoryWindowBlocked `
      'target directory could be replaced after validation'
    Assert-CzxtEqual 'trusted-child' `
      ([IO.File]::ReadAllText((Join-Path $targetRoot 'child.md'))) `
      'trusted child did not land in the bound target directory'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $savedTarget)) `
      'target directory replacement unexpectedly succeeded'
  }

  Invoke-CzxtContract 'explicit gitkeep target expectation still rejects a source swap' {
    $caseRoot = Join-Path $FixtureRoot 'gitkeep-source-swap'
    $sourceRoot = Join-Path $caseRoot 'template'
    $project = Join-Path $caseRoot 'project'
    $targetRoot = Join-Path $project '借鉴区'
    $source = Join-Path $sourceRoot '来源\.gitkeep'
    $savedSource = Join-Path $sourceRoot '来源\.gitkeep.before'
    $target = Join-Path $targetRoot '来源\.gitkeep'
    [void](New-Item -ItemType Directory -Path (Split-Path -Parent $source) -Force)
    [void](New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force)
    Write-CzxtNoBomText $source 'trusted-gitkeep'
    $script:CzxtStaticSourceHookRan = $false
    $swapSource = {
      param([string]$HookSource)
      $script:CzxtStaticSourceHookRan = $true
      [IO.File]::Move($HookSource, $savedSource)
      Write-CzxtNoBomText $HookSource 'later-gitkeep'
    }
    $rejected = $false
    try {
      Copy-CzxtBorrowingStaticFile -SourceRoot $sourceRoot -TargetRoot $targetRoot `
        -RelativePath '来源\.gitkeep' -ProjectRoot $project -ExpectAbsent `
        -AfterSourceBind $swapSource
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $script:CzxtStaticSourceHookRan `
      'explicit gitkeep source hook did not run after source binding'
    Assert-CzxtTrue $rejected 'explicit gitkeep copy adopted a replacement source'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $target)) `
      'explicit gitkeep source rejection still wrote a target'
    Assert-CzxtEqual 'trusted-gitkeep' ([IO.File]::ReadAllText($savedSource)) `
      'explicit gitkeep source rejection changed the trusted object'
    Assert-CzxtEqual 'later-gitkeep' ([IO.File]::ReadAllText($source)) `
      'explicit gitkeep source rejection changed the later object'
  }
}
