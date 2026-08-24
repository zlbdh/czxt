$ErrorActionPreference = 'Stop'

function Get-BorrowingUnusedSubstDrive {
  $used = @{}
  foreach ($drive in [IO.DriveInfo]::GetDrives()) {
    $used[$drive.Name.Substring(0, 1).ToUpperInvariant()] = $true
  }
  $substOutput = (& subst.exe 2>$null | Out-String)
  foreach ($line in @($substOutput -split "`r?`n")) {
    if ($line -match '^([A-Za-z]):') { $used[$Matches[1].ToUpperInvariant()] = $true }
  }
  foreach ($letter in @('Z', 'Y', 'X', 'W', 'V', 'U', 'T', 'S', 'R')) {
    if (-not $used.ContainsKey($letter)) { return $letter }
  }
  throw 'no unused drive letter is available for the subst contract'
}

function Get-BorrowingSubstMappingTarget {
  param([string]$DriveName)
  $expectedDrive = $DriveName.TrimEnd(':').ToUpperInvariant()
  foreach ($line in @((& subst.exe 2>$null | Out-String) -split "`r?`n")) {
    if ($line -match '^([A-Za-z]):\\: => (.+)$' -and
        $Matches[1].ToUpperInvariant() -ceq $expectedDrive) {
      return [IO.Path]::GetFullPath($Matches[2].Trim()).TrimEnd('\')
    }
  }
  return $null
}

function Invoke-BorrowingInstallerRaceContracts {
  param(
    [string]$TemplateRoot,
    [string]$FixtureRoot,
    [string]$MinimalTemplate,
    [string]$InstallerPath
  )

  Invoke-CzxtContract 'installer rejects a subst alias ProjectRoot inside recursive Docs before writes' {
    $sourceMarker = Join-Path $MinimalTemplate 'Docs\subst-source-only.txt'
    Write-CzxtNoBomText $sourceMarker 'subst-source-must-remain-unchanged'
    $sourceBefore = Get-BorrowingByteSignature $sourceMarker
    $physicalProject = Join-Path $MinimalTemplate 'Docs\subst-contained-project'
    $letter = Get-BorrowingUnusedSubstDrive
    $driveName = '{0}:' -f $letter
    $createdMapping = $false
    try {
      & subst.exe $driveName $MinimalTemplate | Out-Null
      Assert-CzxtEqual 0 $LASTEXITCODE 'failed to create the subst fixture mapping'
      $createdMapping = $true
      $aliasProject = Join-Path ($driveName + '\') 'Docs\subst-contained-project'
      $result = Invoke-CzxtPowerShell -ScriptPath $InstallerPath -ScriptArguments @(
        '-ProjectRoot', $aliasProject, '-ProjectName', 'subst fixture',
        '-AppRepoDir', 'app'
      ) -TimeoutMilliseconds 30000
      Assert-CzxtTrue ($result.ExitCode -ne 0) `
        'installer accepted a subst alias below the recursive Docs source'
      Assert-CzxtTrue (-not (Test-Path -LiteralPath $physicalProject)) `
        'installer wrote below the recursive Docs source through a subst alias'
      Assert-CzxtEqual $sourceBefore (Get-BorrowingByteSignature $sourceMarker) `
        'installer changed an existing Docs source file during subst rejection'
    }
    finally {
      if ($createdMapping) {
        $currentTarget = Get-BorrowingSubstMappingTarget $driveName
        $ownedTarget = [IO.Path]::GetFullPath($MinimalTemplate).TrimEnd('\')
        if ($null -ne $currentTarget -and $currentTarget.Equals(
            $ownedTarget, [StringComparison]::OrdinalIgnoreCase)) {
          & subst.exe $driveName /d | Out-Null
          Assert-CzxtEqual 0 $LASTEXITCODE 'failed to remove the owned subst fixture mapping'
          Assert-CzxtTrue ($null -eq (Get-BorrowingSubstMappingTarget $driveName)) `
            'owned subst fixture mapping still exists after cleanup'
        } elseif ($null -ne $currentTarget) {
          throw 'owned subst drive was rebound; the later mapping was preserved'
        }
      }
    }
  }

  Invoke-CzxtContract 'Force recursive plan rejects a leaf replaced after preflight' {
    $caseRoot = Join-Path $FixtureRoot 'force-tree-preflight-swap'
    $template = Join-Path $caseRoot 'template'
    $project = Join-Path $caseRoot 'project'
    $sourceRoot = Join-Path $template 'Docs'
    $targetRoot = Join-Path $project 'Docs'
    $source = Join-Path $sourceRoot 'nested\race.md'
    $target = Join-Path $targetRoot 'nested\race.md'
    [void](New-Item -ItemType Directory -Path (Split-Path -Parent $source) -Force)
    [void](New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force)
    Write-CzxtNoBomText $source "installer-source`n"
    Write-CzxtNoBomText $target "preflight-owner`n"
    $entry = New-CzxtInstallerCopyPlanEntry -ProjectRoot $project `
      -SourcePath $sourceRoot -TargetPath $targetRoot -Item 'Docs' -Force
    Assert-CzxtTrue ($null -ne $entry.TreePlan) `
      'Force directory preflight did not bind a recursive tree plan'
    [IO.File]::Delete($target)
    Write-CzxtNoBomText $target "later-owner`n"
    $laterBefore = Get-BorrowingByteSignature $target
    $rejected = $false
    try {
      Copy-CzxtInstallerTree -TemplateRoot $template -ProjectRoot $project `
        -SourcePath $sourceRoot -TargetPath $targetRoot -TreePlan $entry.TreePlan
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $rejected 'Force recursive copy adopted a leaf replaced after preflight'
    Assert-CzxtEqual $laterBefore (Get-BorrowingByteSignature $target) `
      'Force recursive rejection changed the later leaf object'
  }

  Invoke-CzxtContract 'new borrowing directory keeps gitkeep ExpectAbsent through landing' {
    $caseRoot = Join-Path $FixtureRoot 'borrowing-gitkeep-race'
    $project = Join-Path $caseRoot 'project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project '借鉴区\来源\.gitkeep'
    $script:CzxtBorrowingGitkeepHookRan = $false
    $inject = {
      param([string]$TargetDirectory, [string]$SentinelPath)
      if ($TargetDirectory.EndsWith('\来源', [StringComparison]::OrdinalIgnoreCase)) {
        $script:CzxtBorrowingGitkeepHookRan = $true
        Write-CzxtNoBomText $SentinelPath 'later-owner'
      }
    }
    $rejected = $false
    try {
      Copy-BorrowingZoneSkeleton -TemplateRoot $MinimalTemplate -ProjectRoot $project `
        -BeforeBorrowingSentinelCopy $inject
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $script:CzxtBorrowingGitkeepHookRan `
      'borrowing gitkeep injection hook did not run after directory creation'
    Assert-CzxtTrue $rejected 'borrowing skeleton adopted a later gitkeep in a new directory'
    Assert-CzxtEqual 'later-owner' ([IO.File]::ReadAllText($target)) `
      'borrowing skeleton changed the later gitkeep object'
  }

  Invoke-CzxtContract 'Force tree rejects an existing target directory identity swap' {
    $caseRoot = Join-Path $FixtureRoot 'force-target-directory-swap'
    $template = Join-Path $caseRoot 'template'
    $project = Join-Path $caseRoot 'project'
    $sourceRoot = Join-Path $template 'Docs'
    $targetRoot = Join-Path $project 'Docs'
    $source = Join-Path $sourceRoot 'nested\race.md'
    $targetDirectory = Join-Path $targetRoot 'nested'
    $savedDirectory = Join-Path $targetRoot 'nested-before-preflight'
    [void](New-Item -ItemType Directory -Path (Split-Path -Parent $source) -Force)
    [void](New-Item -ItemType Directory -Path $targetDirectory -Force)
    Write-CzxtNoBomText $source 'installer-source'
    $entry = New-CzxtInstallerCopyPlanEntry -ProjectRoot $project `
      -SourcePath $sourceRoot -TargetPath $targetRoot -Item 'Docs' -Force
    [IO.Directory]::Move($targetDirectory, $savedDirectory)
    [void](New-Item -ItemType Directory -Path $targetDirectory)
    $laterMarker = Join-Path $targetDirectory 'later-owner.txt'
    Write-CzxtNoBomText $laterMarker 'later-directory-owner'
    $rejected = $false
    try {
      Copy-CzxtInstallerTree -TemplateRoot $template -ProjectRoot $project `
        -SourcePath $sourceRoot -TargetPath $targetRoot -TreePlan $entry.TreePlan
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $rejected 'Force tree adopted a replacement target directory identity'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $targetDirectory 'race.md'))) `
      'Force tree wrote into the later target directory'
    Assert-CzxtEqual 'later-directory-owner' ([IO.File]::ReadAllText($laterMarker)) `
      'Force tree changed the later target directory owner marker'
    Assert-CzxtTrue (Test-Path -LiteralPath $savedDirectory -PathType Container) `
      'Force tree lost the original target directory object'
  }

  Invoke-CzxtContract 'non-Force file copy rejects a same-path source identity replacement' {
    $caseRoot = Join-Path $FixtureRoot 'source-file-preflight-swap'
    $template = Join-Path $caseRoot 'template'
    $project = Join-Path $caseRoot 'project'
    $source = Join-Path $template 'README.md'
    $savedSource = Join-Path $template 'README.before-preflight.md'
    $target = Join-Path $project 'README.md'
    [void](New-Item -ItemType Directory -Path $template -Force)
    [void](New-Item -ItemType Directory -Path $project -Force)
    Write-CzxtNoBomText $source 'trusted-source'
    $entry = New-CzxtInstallerCopyPlanEntry -ProjectRoot $project `
      -SourcePath $source -TargetPath $target -Item 'README.md'
    [IO.File]::Move($source, $savedSource)
    Write-CzxtNoBomText $source 'later-source'
    Assert-CzxtTrue ($null -ne $entry.ExpectedSourceState) `
      'non-Force file preflight did not bind source identity and digest'
    $rejected = $false
    try {
      Copy-CzxtInstallerTree -TemplateRoot $template -ProjectRoot $project `
        -SourcePath $source -TargetPath $target `
        -ExpectAbsentTree:$entry.ExpectAbsentTree `
        -ExpectedPresentState $entry.ExpectedPresentState `
        -ExpectedSourceState $entry.ExpectedSourceState
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $rejected 'non-Force copy adopted a replacement source identity'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $target)) `
      'source identity rejection still wrote a target'
    Assert-CzxtEqual 'trusted-source' ([IO.File]::ReadAllText($savedSource)) `
      'source identity rejection changed the trusted source object'
    Assert-CzxtEqual 'later-source' ([IO.File]::ReadAllText($source)) `
      'source identity rejection changed the later source object'
  }

  Invoke-CzxtContract 'non-Force directory plan rejects a source child added after preflight' {
    $caseRoot = Join-Path $FixtureRoot 'source-directory-child-add'
    $template = Join-Path $caseRoot 'template'
    $project = Join-Path $caseRoot 'project'
    $sourceRoot = Join-Path $template 'Docs'
    $targetRoot = Join-Path $project 'Docs'
    [void](New-Item -ItemType Directory -Path $sourceRoot -Force)
    [void](New-Item -ItemType Directory -Path $project -Force)
    Write-CzxtNoBomText (Join-Path $sourceRoot 'planned.md') 'planned-source'
    $entry = New-CzxtInstallerCopyPlanEntry -ProjectRoot $project `
      -SourcePath $sourceRoot -TargetPath $targetRoot -Item 'Docs'
    Assert-CzxtTrue ($null -ne $entry.TreePlan) `
      'non-Force directory preflight did not bind its source tree'
    $laterSource = Join-Path $sourceRoot 'later.md'
    Write-CzxtNoBomText $laterSource 'later-source'
    $rejected = $false
    try {
      Copy-CzxtInstallerTree -TemplateRoot $template -ProjectRoot $project `
        -SourcePath $sourceRoot -TargetPath $targetRoot -TreePlan $entry.TreePlan
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $rejected 'non-Force directory copy adopted an unplanned source child'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $targetRoot)) `
      'source child rejection created the target tree'
    Assert-CzxtEqual 'later-source' ([IO.File]::ReadAllText($laterSource)) `
      'source child rejection changed the later source child'
  }

  Invoke-CzxtContract 'trusted source copy streams a large file without caching source bytes in the plan' {
    $caseRoot = Join-Path $FixtureRoot 'source-large-streaming'
    $template = Join-Path $caseRoot 'template'
    $project = Join-Path $caseRoot 'project'
    $source = Join-Path $template 'large.bin'
    $target = Join-Path $project 'large.bin'
    [void](New-Item -ItemType Directory -Path $template -Force)
    [void](New-Item -ItemType Directory -Path $project -Force)
    $stream = [IO.File]::Open($source, [IO.FileMode]::CreateNew,
      [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
      $stream.SetLength(8MB)
      $stream.Position = $stream.Length - 1
      $stream.WriteByte(0x5A)
    }
    finally { $stream.Dispose() }
    $entry = New-CzxtInstallerCopyPlanEntry -ProjectRoot $project `
      -SourcePath $source -TargetPath $target -Item 'large.bin'
    Assert-CzxtTrue ($null -ne $entry.ExpectedSourceState) `
      'large source preflight did not bind source state'
    Assert-CzxtTrue ($null -eq $entry.ExpectedSourceState.PSObject.Properties['Bytes']) `
      'large source plan cached unbounded source bytes'
    Copy-CzxtInstallerTree -TemplateRoot $template -ProjectRoot $project `
      -SourcePath $source -TargetPath $target `
      -ExpectAbsentTree:$entry.ExpectAbsentTree `
      -ExpectedPresentState $entry.ExpectedPresentState `
      -ExpectedSourceState $entry.ExpectedSourceState
    Assert-CzxtEqual (Get-BorrowingByteSignature $source) `
      (Get-BorrowingByteSignature $target) 'large trusted source stream changed bytes'
  }
}
