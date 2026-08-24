$ErrorActionPreference = 'Stop'

function Invoke-BorrowingInstallerTransactionWindowContracts {
  param([string]$FixtureRoot)

  Invoke-CzxtContract 'prepared text CreateNew rejects a preoccupied transaction path' {
    $project = Join-Path $FixtureRoot 'prepared-create-new\project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project 'README.md'
    $script:CzxtPreoccupiedPrepared = $null
    $occupyPrepared = {
      param([string]$HookPrepared)
      $script:CzxtPreoccupiedPrepared = $HookPrepared
      Write-CzxtNoBomText $HookPrepared 'PREEXISTING'
    }
    $rejected = $false
    try {
      Write-CzxtInstallerTextFile -ProjectRoot $project -TargetPath $target `
        -Content 'installer-owner' -Encoding $script:CzxtUtf8NoBom -ExpectAbsent `
        -BeforePreparedWrite $occupyPrepared
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $rejected 'prepared writer overwrote a preoccupied temp path'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $target)) `
      'preoccupied prepared path still reached the install target'
    Assert-CzxtEqual 'PREEXISTING' `
      ([IO.File]::ReadAllText($script:CzxtPreoccupiedPrepared)) `
      'prepared writer changed or deleted the preexisting object'
  }

  Invoke-CzxtContract 'prepared cleanup preserves a later object at the consumed temp path' {
    $project = Join-Path $FixtureRoot 'prepared-cleanup-aba\project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project 'README.md'
    $script:CzxtLaterPrepared = $null
    $replaceConsumedTemp = {
      param([string]$HookPrepared)
      $script:CzxtLaterPrepared = $HookPrepared
      Write-CzxtNoBomText $HookPrepared 'LATER-OWNER'
    }
    $rejected = $false
    try {
      Write-CzxtInstallerTextFile -ProjectRoot $project -TargetPath $target `
        -Content 'installer-owner' -Encoding $script:CzxtUtf8NoBom -ExpectAbsent `
        -BeforePreparedCleanup $replaceConsumedTemp
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $rejected 'prepared cleanup accepted a later temp-path object'
    Assert-CzxtEqual 'installer-owner' ([IO.File]::ReadAllText($target)) `
      'prepared cleanup changed the installed object'
    Assert-CzxtEqual 'LATER-OWNER' `
      ([IO.File]::ReadAllText($script:CzxtLaterPrepared)) `
      'prepared cleanup deleted the later temp-path object'
  }

  Invoke-CzxtContract 'prepared creation holds its parent against a late junction swap' {
    $caseRoot = Join-Path $FixtureRoot 'prepared-parent-junction'
    $project = Join-Path $caseRoot 'project'
    $parent = Join-Path $project 'Docs'
    $savedParent = Join-Path $project 'Docs.before'
    $outside = Join-Path $caseRoot 'outside'
    $target = Join-Path $parent 'README.md'
    [void](New-Item -ItemType Directory -Path $parent -Force)
    [void](New-Item -ItemType Directory -Path $outside -Force)
    $script:CzxtPreparedParentHookRan = $false
    $script:CzxtPreparedParentSwapBlocked = $false
    $script:CzxtPreparedParentSwapSucceeded = $false
    $script:CzxtPreparedOutsideTempObserved = $false
    $swapParent = {
      param([string]$HookPrepared)
      $script:CzxtPreparedParentHookRan = $true
      try {
        [IO.Directory]::Move($parent, $savedParent)
        [void](New-Item -ItemType Junction -Path $parent -Target $outside)
        $script:CzxtPreparedParentSwapSucceeded = $true
      }
      catch { $script:CzxtPreparedParentSwapBlocked = $true }
    }
    $observePrepared = {
      param([string]$HookPrepared)
      $outsidePrepared = Join-Path $outside ([IO.Path]::GetFileName($HookPrepared))
      $script:CzxtPreparedOutsideTempObserved = [IO.File]::Exists($outsidePrepared)
    }
    $caught = $null
    try {
      Write-CzxtInstallerTextFile -ProjectRoot $project -TargetPath $target `
        -Content 'trusted-parent-bound' -Encoding $script:CzxtUtf8NoBom `
        -Context 'prepared parent junction fixture' -ExpectAbsent `
        -BeforePreparedWrite $swapParent -BeforePreparedCleanup $observePrepared
    }
    catch { $caught = $_.Exception }
    finally {
      if ((Get-Item -LiteralPath $parent -Force -ErrorAction SilentlyContinue).Attributes `
          -band [IO.FileAttributes]::ReparsePoint) {
        [IO.Directory]::Delete($parent, $false)
      }
      if ([IO.Directory]::Exists($savedParent) -and
          -not [IO.Directory]::Exists($parent)) {
        [IO.Directory]::Move($savedParent, $parent)
      }
    }
    Assert-CzxtTrue $script:CzxtPreparedParentHookRan `
      'prepared parent junction hook did not run'
    Assert-CzxtTrue $script:CzxtPreparedParentSwapBlocked `
      'prepared parent could be replaced after path validation'
    Assert-CzxtTrue (-not $script:CzxtPreparedParentSwapSucceeded) `
      'prepared parent junction swap unexpectedly succeeded'
    Assert-CzxtTrue (-not $script:CzxtPreparedOutsideTempObserved) `
      'prepared writer created a transaction file outside ProjectRoot'
    Assert-CzxtTrue ($null -eq $caught) `
      ('bound prepared write failed: ' + $(if ($null -eq $caught) { '' } else { $caught.Message }))
    Assert-CzxtEqual 'trusted-parent-bound' ([IO.File]::ReadAllText($target)) `
      'bound prepared write did not land trusted bytes'
  }

  Invoke-CzxtContract 'bound source rejection deletes its created temp through the same handle' {
    $caseRoot = Join-Path $FixtureRoot 'source-rejection-owned-temp'
    $template = Join-Path $caseRoot 'template'
    $project = Join-Path $caseRoot 'project'
    $source = Join-Path $template 'source.txt'
    $target = Join-Path $project 'target.txt'
    [void](New-Item -ItemType Directory -Path $template -Force)
    [void](New-Item -ItemType Directory -Path $project -Force)
    Write-CzxtNoBomText $source 'trusted-source-bytes'
    $trusted = Get-CzxtInstallerFileState $source 'source rejection fixture'
    $wrongDigest = [pscustomobject]@{
      Path = $trusted.Path
      Identity = $trusted.Identity
      NumberOfLinks = $trusted.NumberOfLinks
      Length = $trusted.Length
      Sha256 = ('0' * 64)
    }
    $sourceBefore = Get-BorrowingByteSignature $source
    $rejected = $false
    try {
      Copy-CzxtInstallerFile -ProjectRoot $project -SourcePath $source `
        -TargetPath $target -Context 'source rejection fixture' -ExpectAbsent `
        -ExpectedSourceState $wrongDigest
    }
    catch { $rejected = $true }
    $residues = @(Get-ChildItem -LiteralPath $project `
        -Filter '.czxt-install-*.tmp' -Force -ErrorAction SilentlyContinue)
    Assert-CzxtTrue $rejected 'bound source copy accepted a wrong trusted digest'
    Assert-CzxtTrue (-not [IO.File]::Exists($target)) `
      'bound source rejection still landed an install target'
    Assert-CzxtEqual 0 $residues.Count `
      'bound source rejection retained a temp containing copied source bytes'
    Assert-CzxtEqual $sourceBefore (Get-BorrowingByteSignature $source) `
      'bound source rejection changed the source object'
  }

  Invoke-CzxtContract 'backup path preoccupation never overwrites an unowned object' {
    $project = Join-Path $FixtureRoot 'backup-preoccupied\project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project 'README.md'
    $prepared = Join-Path $project '.prepared.tmp'
    Write-CzxtNoBomText $target 'original-owner'
    Write-CzxtNoBomText $prepared 'installer-owner'
    $expected = Get-CzxtInstallerFileState $target 'backup preoccupation fixture'
    $script:CzxtPreoccupiedBackup = $null
    $occupyBackup = {
      param([string]$HookTarget, [string]$HookPrepared, [string]$HookBackup)
      $script:CzxtPreoccupiedBackup = $HookBackup
      Write-CzxtNoBomText $HookBackup 'PREEXISTING'
    }
    $rejected = $false
    try {
      [void](Set-CzxtInstallerPreparedFile -ProjectRoot $project `
        -PreparedPath $prepared -TargetPath $target -ExpectedPresentState $expected `
        -ExpectedPreparedState (Get-CzxtInstallerFileState $prepared 'preoccupied prepared') `
        -Context 'backup preoccupation fixture' -BeforeBackupMove $occupyBackup)
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $rejected 'replace accepted a preoccupied backup path'
    Assert-CzxtEqual 'original-owner' ([IO.File]::ReadAllText($target)) `
      'backup preoccupation changed the original target'
    Assert-CzxtEqual 'installer-owner' ([IO.File]::ReadAllText($prepared)) `
      'backup preoccupation changed the prepared object'
    Assert-CzxtEqual 'PREEXISTING' `
      ([IO.File]::ReadAllText($script:CzxtPreoccupiedBackup)) `
      'replace overwrote the unowned backup-path object'
  }

  Invoke-CzxtContract 'second move failure reports backup and preserves every path owner' {
    $project = Join-Path $FixtureRoot 'second-move-occupied\project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project 'README.md'
    $prepared = Join-Path $project '.prepared.tmp'
    Write-CzxtNoBomText $target 'original-owner'
    Write-CzxtNoBomText $prepared 'installer-owner'
    $expected = Get-CzxtInstallerFileState $target 'second move fixture'
    $script:CzxtSecondMoveBackup = $null
    $occupyTarget = {
      param([string]$HookTarget, [string]$HookPrepared, [string]$HookBackup)
      $script:CzxtSecondMoveBackup = $HookBackup
      Write-CzxtNoBomText $HookTarget 'LATER-OWNER'
    }
    $caught = $null
    try {
      [void](Set-CzxtInstallerPreparedFile -ProjectRoot $project `
        -PreparedPath $prepared -TargetPath $target -ExpectedPresentState $expected `
        -ExpectedPreparedState (Get-CzxtInstallerFileState $prepared 'second move prepared') `
        -Context 'second move fixture' -BeforePreparedMove $occupyTarget)
    }
    catch { $caught = $_.Exception }
    Assert-CzxtTrue ($null -ne $caught) 'second move target occupation was accepted'
    Assert-CzxtTrue $caught.Message.Contains($script:CzxtSecondMoveBackup) `
      'second move failure omitted the retained backup path'
    Assert-CzxtEqual $script:CzxtSecondMoveBackup `
      ([string]$caught.Data['CzxtInstallerBackupPath']) `
      'second move failure backup data'
    Assert-CzxtEqual `
      'backup=retained,target=untouched,prepared=retained-for-owned-cleanup' `
      ([string]$caught.Data['CzxtInstallerPreserved']) 'second move preserved-state data'
    Assert-CzxtEqual 'LATER-OWNER' ([IO.File]::ReadAllText($target)) `
      'second move overwrote the concurrent target'
    Assert-CzxtEqual 'original-owner' `
      ([IO.File]::ReadAllText($script:CzxtSecondMoveBackup)) `
      'second move lost the displaced original target'
    Assert-CzxtEqual 'installer-owner' ([IO.File]::ReadAllText($prepared)) `
      'second move lost the prepared object before caller cleanup'
  }

  Invoke-CzxtContract 'replace transaction holds its parent across both no-overwrite moves' {
    $caseRoot = Join-Path $FixtureRoot 'replace-parent-lock'
    $project = Join-Path $caseRoot 'project'
    $savedParent = Join-Path $caseRoot 'project.before'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project 'README.md'
    $prepared = Join-Path $project '.prepared.tmp'
    Write-CzxtNoBomText $target 'original-owner'
    Write-CzxtNoBomText $prepared 'installer-owner'
    $expected = Get-CzxtInstallerFileState $target 'replace parent fixture'
    $script:CzxtReplaceParentHookRan = $false
    $script:CzxtReplaceParentSwapBlocked = $false
    $script:CzxtReplaceParentSwapSucceeded = $false
    $swapParent = {
      param([string]$HookTarget, [string]$HookPrepared, [string]$HookBackup)
      $script:CzxtReplaceParentHookRan = $true
      try {
        [IO.Directory]::Move($project, $savedParent)
        [void](New-Item -ItemType Directory -Path $project)
        $script:CzxtReplaceParentSwapSucceeded = $true
      }
      catch { $script:CzxtReplaceParentSwapBlocked = $true }
    }
    $caught = $null
    try {
      [void](Set-CzxtInstallerPreparedFile -ProjectRoot $project `
        -PreparedPath $prepared -TargetPath $target `
        -ExpectedPresentState $expected `
        -ExpectedPreparedState (Get-CzxtInstallerFileState $prepared 'replace parent prepared') `
        -Context 'replace parent fixture' -BeforePreparedMove $swapParent)
    }
    catch { $caught = $_.Exception }
    finally {
      if ([IO.Directory]::Exists($savedParent)) {
        if ([IO.Directory]::Exists($project)) {
          [IO.Directory]::Delete($project, $true)
        }
        [IO.Directory]::Move($savedParent, $project)
      }
    }
    Assert-CzxtTrue $script:CzxtReplaceParentHookRan `
      'replace parent hook did not run between no-overwrite moves'
    Assert-CzxtTrue $script:CzxtReplaceParentSwapBlocked `
      'replace parent could be renamed between no-overwrite moves'
    Assert-CzxtTrue (-not $script:CzxtReplaceParentSwapSucceeded) `
      'replace parent swap unexpectedly succeeded'
    Assert-CzxtTrue ($null -eq $caught) `
      ('bound replace failed: ' + $(if ($null -eq $caught) { '' } else { $caught.Message }))
    Assert-CzxtEqual 'installer-owner' ([IO.File]::ReadAllText($target)) `
      'bound replace did not land the prepared object'
    Assert-CzxtTrue (-not [IO.File]::Exists($prepared)) `
      'bound replace retained the consumed prepared path'
    Assert-CzxtEqual 0 @(Get-ChildItem -LiteralPath $project `
        -Filter '.czxt-backup-*.tmp' -Force).Count `
      'bound replace retained a backup after successful commit'
  }

  Invoke-CzxtContract 'backup owned-delete window is handle-bound' {
    $project = Join-Path $FixtureRoot 'transaction-owned-delete\project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project 'README.md'
    $prepared = Join-Path $project '.prepared.tmp'
    $saved = Join-Path $project '.backup-stolen.tmp'
    Write-CzxtNoBomText $target 'original-owner'
    Write-CzxtNoBomText $prepared 'installer-owner'
    $expected = Get-CzxtInstallerFileState $target 'owned-delete fixture'
    $script:CzxtOwnedDeleteHookRan = $false
    $script:CzxtOwnedDeleteBlocked = $false
    $stealBackup = {
      param([string]$HookBackup)
      $script:CzxtOwnedDeleteHookRan = $true
      try { [IO.File]::Move($HookBackup, $saved) }
      catch { $script:CzxtOwnedDeleteBlocked = $true }
    }
    [void](Set-CzxtInstallerPreparedFile -ProjectRoot $project `
      -PreparedPath $prepared -TargetPath $target -ExpectedPresentState $expected `
      -ExpectedPreparedState (Get-CzxtInstallerFileState $prepared 'owned-delete prepared') `
      -Context 'owned-delete fixture' -BeforeOwnedDelete $stealBackup)
    Assert-CzxtTrue $script:CzxtOwnedDeleteHookRan 'owned-delete hook did not run'
    Assert-CzxtTrue $script:CzxtOwnedDeleteBlocked `
      'backup path could be replaced between binding and delete'
    Assert-CzxtEqual 'installer-owner' ([IO.File]::ReadAllText($target)) `
      'owned-delete window changed the installed target'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $saved)) `
      'owned-delete window moved the bound backup'
  }

  Invoke-CzxtContract 'commit holds the installed target through backup deletion' {
    $project = Join-Path $FixtureRoot 'transaction-commit-target\project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project '状态.md'
    $prepared = Join-Path $project '.prepared.tmp'
    $saved = Join-Path $project '.installed-stolen.tmp'
    $second = Join-Path $project '.second-owner.tmp'
    Write-CzxtNoBomText $target 'original-owner'
    Write-CzxtNoBomText $prepared 'installer-owner'
    Write-CzxtNoBomText $second 'second-owner'
    $expected = Get-CzxtInstallerFileState $target 'commit-target fixture'
    $script:CzxtCommitTargetHookRan = $false
    $script:CzxtCommitTargetBlocked = $false
    $swapTarget = {
      param([string]$HookTarget)
      $script:CzxtCommitTargetHookRan = $true
      try {
        [IO.File]::Move($HookTarget, $saved)
        [IO.File]::Move($second, $HookTarget)
      }
      catch { $script:CzxtCommitTargetBlocked = $true }
    }
    [void](Set-CzxtInstallerPreparedFile -ProjectRoot $project `
      -PreparedPath $prepared -TargetPath $target -ExpectedPresentState $expected `
      -ExpectedPreparedState (Get-CzxtInstallerFileState $prepared 'commit-target prepared') `
      -Context 'commit-target fixture' -AfterCommitTargetRead $swapTarget)
    Assert-CzxtTrue $script:CzxtCommitTargetHookRan 'commit target hook did not run'
    Assert-CzxtTrue $script:CzxtCommitTargetBlocked `
      'installed target could be replaced after final commit read'
    Assert-CzxtEqual 'installer-owner' ([IO.File]::ReadAllText($target)) `
      'commit target binding did not preserve the installed object'
    Assert-CzxtEqual 'second-owner' ([IO.File]::ReadAllText($second)) `
      'commit target binding changed the later object'
  }

  Invoke-CzxtContract 'recovery path race stops without overwriting any later object' {
    $project = Join-Path $FixtureRoot 'transaction-restore-window\project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project 'README.md'
    $prepared = Join-Path $project '.prepared.tmp'
    $first = Join-Path $project '.first-owner.tmp'
    $second = Join-Path $project '.second-owner.tmp'
    $savedOriginal = Join-Path $project '.saved-original.tmp'
    $savedInstalled = Join-Path $project '.saved-installed.tmp'
    Write-CzxtNoBomText $target 'original-owner'
    Write-CzxtNoBomText $prepared 'installer-owner'
    Write-CzxtNoBomText $first 'first-owner'
    Write-CzxtNoBomText $second 'second-owner'
    $expected = Get-CzxtInstallerFileState $target 'restore-window fixture'
    $firstSwap = {
      param([string]$HookTarget, [string]$HookPrepared)
      [IO.File]::Move($HookTarget, $savedOriginal)
      [IO.File]::Move($first, $HookTarget)
    }
    $script:CzxtRestoreWindowHookRan = $false
    $secondSwap = {
      param([string]$HookTarget, [string]$HookBackup)
      $script:CzxtRestoreWindowHookRan = $true
      [IO.File]::Move($HookTarget, $savedInstalled)
      [IO.File]::Move($second, $HookTarget)
    }
    $rejected = $false
    try {
      [void](Set-CzxtInstallerPreparedFile -ProjectRoot $project `
        -PreparedPath $prepared -TargetPath $target -ExpectedPresentState $expected `
        -ExpectedPreparedState (Get-CzxtInstallerFileState $prepared 'restore-window prepared') `
        -Context 'restore-window fixture' -BeforeReplace $firstSwap `
        -BeforeRestoreReplace $secondSwap)
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $script:CzxtRestoreWindowHookRan 'restore window hook did not run'
    Assert-CzxtTrue $rejected 'recovery path race was accepted'
    Assert-CzxtEqual 'second-owner' ([IO.File]::ReadAllText($target)) `
      'recovery overwrote the later target object'
    Assert-CzxtEqual 'installer-owner' ([IO.File]::ReadAllText($savedInstalled)) `
      'recovery lost the installed object'
    Assert-CzxtEqual 'original-owner' ([IO.File]::ReadAllText($savedOriginal)) `
      'recovery lost the original preflight object'
    Assert-BorrowingBackupWithText -Directory $project -ExpectedText 'first-owner' `
      -Message 'recovery lost the first displaced object'
  }
}

function Invoke-BorrowingInstallerFinalManifestContract {
  param([string]$FixtureRoot, [string]$InstallerPath)

  Invoke-CzxtContract 'installer revalidates every installed file before project marker and success' {
    $project = Join-Path $FixtureRoot 'final-manifest-window\project'
    $originalBytes = [IO.File]::ReadAllBytes($InstallerPath)
    $installerText = [IO.File]::ReadAllText($InstallerPath)
    $needle = 'Complete-CzxtInstallerOutput -ProjectRoot $ProjectRoot'
    Assert-CzxtEqual 1 ([regex]::Matches($installerText, [regex]::Escape($needle)).Count) `
      'final manifest injection anchor count'
    $injection = @'
if ($ProjectName -ceq 'final manifest fixture') {
  $victim = Join-Path $ProjectRoot 'AGENTS.md'
  $saved = Join-Path $ProjectRoot 'AGENTS.before-final-verify.md'
  $bytes = [IO.File]::ReadAllBytes($victim)
  [IO.File]::Move($victim, $saved)
  [IO.File]::WriteAllBytes($victim, $bytes)
}
'@
    $instrumented = $installerText.Replace($needle, $injection + "`n" + $needle)
    [IO.File]::WriteAllText($InstallerPath, $instrumented, $script:CzxtUtf8Bom)
    try {
      $result = Invoke-CzxtPowerShell -ScriptPath $InstallerPath -ScriptArguments @(
        '-ProjectRoot', $project, '-ProjectName', 'final manifest fixture',
        '-AppRepoDir', 'app'
      )
    }
    finally { [IO.File]::WriteAllBytes($InstallerPath, $originalBytes) }
    $saved = Join-Path $project 'AGENTS.before-final-verify.md'
    $later = Join-Path $project 'AGENTS.md'
    Assert-CzxtTrue ($result.ExitCode -ne 0) `
      'installer reported success after an installed file identity replacement'
    Assert-CzxtTrue (Test-Path -LiteralPath $saved -PathType Leaf) `
      'final manifest fixture did not preserve the original installed object'
    Assert-CzxtTrue (Test-Path -LiteralPath $later -PathType Leaf) `
      'final manifest fixture lost the later installed-path object'
    Assert-CzxtEqual (Get-BorrowingByteSignature $saved) `
      (Get-BorrowingByteSignature $later) 'same-byte final manifest replacement drifted'
    Assert-CzxtTrue ((Get-CzxtInstallerFileState $saved).Identity -cne `
        (Get-CzxtInstallerFileState $later).Identity) `
      'final manifest fixture did not replace file identity'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $project '.czxt-project-root'))) `
      'installer wrote the project marker before rejecting final manifest drift'
  }

  Invoke-CzxtContract 'Force rejects a preserved status deleted before append' {
    $project = Join-Path $FixtureRoot 'preserved-status-delete-window\project'
    $fresh = Invoke-CzxtPowerShell -ScriptPath $InstallerPath -ScriptArguments @(
      '-ProjectRoot', $project, '-ProjectName', 'status delete fresh fixture',
      '-AppRepoDir', 'app'
    )
    Assert-CzxtEqual 0 $fresh.ExitCode ('status delete fresh stderr: ' + $fresh.StdErr)
    $marker = Join-Path $project '.czxt-project-root'
    [IO.File]::Delete($marker)
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $marker)) `
      'status delete fixture retained the fresh success marker'
    $originalBytes = [IO.File]::ReadAllBytes($InstallerPath)
    $installerText = [IO.File]::ReadAllText($InstallerPath)
    $needle = '$statePath = Join-Path $ProjectRoot "状态.md"'
    Assert-CzxtEqual 1 ([regex]::Matches($installerText, [regex]::Escape($needle)).Count) `
      'preserved status delete injection anchor count'
    $injection = @'
if ($ProjectName -ceq 'status delete window fixture') {
  $victim = Join-Path $ProjectRoot '状态.md'
  [IO.File]::Delete($victim)
  Write-Host 'CZXT_STATUS_DELETE_HOOK_RAN'
}
'@
    $instrumented = $installerText.Replace($needle, $injection + "`n" + $needle)
    [IO.File]::WriteAllText($InstallerPath, $instrumented, $script:CzxtUtf8Bom)
    try {
      $result = Invoke-CzxtPowerShell -ScriptPath $InstallerPath -ScriptArguments @(
        '-ProjectRoot', $project, '-ProjectName', 'status delete window fixture',
        '-AppRepoDir', 'app', '-Force'
      )
    }
    finally { [IO.File]::WriteAllBytes($InstallerPath, $originalBytes) }
    $successOutput = $result.StdOut.Contains('review/trust .codex hooks')
    $markerExists = Test-Path -LiteralPath $marker -PathType Leaf
    Assert-CzxtTrue $result.StdOut.Contains('CZXT_STATUS_DELETE_HOOK_RAN') `
      'preserved status delete hook did not run'
    Assert-CzxtTrue ($result.ExitCode -ne 0 -and -not $markerExists -and -not $successOutput) `
      ("preserved status deletion did not fail closed: exit={0}, marker={1}, success={2}" -f `
        $result.ExitCode, $markerExists, $successOutput)
    Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $project '状态.md'))) `
      'installer guessed recovery for the concurrently deleted status path'
  }

  Invoke-CzxtContract 'Force rejects a later status directory before append' {
    $project = Join-Path $FixtureRoot 'preserved-status-directory-window\project'
    $fresh = Invoke-CzxtPowerShell -ScriptPath $InstallerPath -ScriptArguments @(
      '-ProjectRoot', $project, '-ProjectName', 'status directory fresh fixture',
      '-AppRepoDir', 'app'
    )
    Assert-CzxtEqual 0 $fresh.ExitCode ('status directory fresh stderr: ' + $fresh.StdErr)
    $marker = Join-Path $project '.czxt-project-root'
    [IO.File]::Delete($marker)
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $marker)) `
      'status directory fixture retained the fresh success marker'
    $originalBytes = [IO.File]::ReadAllBytes($InstallerPath)
    $installerText = [IO.File]::ReadAllText($InstallerPath)
    $needle = '$statePath = Join-Path $ProjectRoot "状态.md"'
    Assert-CzxtEqual 1 ([regex]::Matches($installerText, [regex]::Escape($needle)).Count) `
      'preserved status directory injection anchor count'
    $injection = @'
if ($ProjectName -ceq 'status directory window fixture') {
  $victim = Join-Path $ProjectRoot '状态.md'
  [IO.File]::Delete($victim)
  [void][IO.Directory]::CreateDirectory($victim)
  [IO.File]::WriteAllBytes((Join-Path $victim 'later-owner.txt'),
    [Text.Encoding]::UTF8.GetBytes('LATER-OWNER'))
  Write-Host 'CZXT_STATUS_DIRECTORY_HOOK_RAN'
}
'@
    $instrumented = $installerText.Replace($needle, $injection + "`n" + $needle)
    [IO.File]::WriteAllText($InstallerPath, $instrumented, $script:CzxtUtf8Bom)
    try {
      $result = Invoke-CzxtPowerShell -ScriptPath $InstallerPath -ScriptArguments @(
        '-ProjectRoot', $project, '-ProjectName', 'status directory window fixture',
        '-AppRepoDir', 'app', '-Force'
      )
    }
    finally { [IO.File]::WriteAllBytes($InstallerPath, $originalBytes) }
    $laterDirectory = Join-Path $project '状态.md'
    $laterSentinel = Join-Path $laterDirectory 'later-owner.txt'
    $successOutput = $result.StdOut.Contains('review/trust .codex hooks')
    $markerExists = Test-Path -LiteralPath $marker -PathType Leaf
    Assert-CzxtTrue $result.StdOut.Contains('CZXT_STATUS_DIRECTORY_HOOK_RAN') `
      'preserved status directory hook did not run'
    Assert-CzxtTrue ($result.ExitCode -ne 0 -and -not $markerExists -and -not $successOutput) `
      ("preserved status directory replacement did not fail closed: exit={0}, marker={1}, success={2}" -f `
        $result.ExitCode, $markerExists, $successOutput)
    Assert-CzxtTrue (Test-Path -LiteralPath $laterDirectory -PathType Container) `
      'installer deleted the later status-path directory'
    Assert-CzxtEqual 'LATER-OWNER' ([IO.File]::ReadAllText($laterSentinel)) `
      'installer changed or deleted the later status-path owner'
  }

  Invoke-CzxtContract 'final manifest lease blocks same-identity same-length in-place writes' {
    $project = Join-Path $FixtureRoot 'final-manifest-inplace\project'
    $templateRoot = Split-Path -Parent $InstallerPath
    $trustedSignature = Get-BorrowingByteSignature (Join-Path $templateRoot 'AGENTS.md')
    $originalBytes = [IO.File]::ReadAllBytes($InstallerPath)
    $installerText = [IO.File]::ReadAllText($InstallerPath)
    $needle = 'Write-Host "✅ 操作系统已实例化到：$ProjectRoot"'
    Assert-CzxtEqual 1 ([regex]::Matches($installerText, [regex]::Escape($needle)).Count) `
      'final in-place injection anchor count'
    $injection = @'
if ($ProjectName -ceq 'final in-place fixture') {
  $victim = Join-Path $ProjectRoot 'AGENTS.md'
  $bytes = [IO.File]::ReadAllBytes($victim)
  if ($bytes.Length -gt 0) { $bytes[0] = $bytes[0] -bxor 1 }
  try { [IO.File]::WriteAllBytes($victim, $bytes) } catch {}
  Write-Host 'CZXT_INPLACE_HOOK_RAN'
}
'@
    $instrumented = $installerText.Replace($needle, $injection + "`n" + $needle)
    [IO.File]::WriteAllText($InstallerPath, $instrumented, $script:CzxtUtf8Bom)
    try {
      $result = Invoke-CzxtPowerShell -ScriptPath $InstallerPath -ScriptArguments @(
        '-ProjectRoot', $project, '-ProjectName', 'final in-place fixture',
        '-AppRepoDir', 'app'
      )
    }
    finally { [IO.File]::WriteAllBytes($InstallerPath, $originalBytes) }
    Assert-CzxtEqual 0 $result.ExitCode ('in-place final lease stderr: ' + $result.StdErr)
    Assert-CzxtTrue $result.StdOut.Contains('CZXT_INPLACE_HOOK_RAN') `
      'final in-place hook did not run'
    Assert-CzxtEqual $trustedSignature `
      (Get-BorrowingByteSignature (Join-Path $project 'AGENTS.md')) `
      'final manifest lease allowed an in-place content write'
  }
}
