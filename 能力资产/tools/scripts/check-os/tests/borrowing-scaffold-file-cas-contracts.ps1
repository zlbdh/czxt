$ErrorActionPreference = 'Stop'

function Invoke-BorrowingInstallerFileCasContracts {
  param([string]$FixtureRoot)

  foreach ($casCase in @(
      @{ Name = 'same-byte'; SentinelText = "expected-target`n" },
      @{ Name = 'different-byte'; SentinelText = "outside-different`n" })) {
    Invoke-CzxtContract ("prepared-file CAS preserves a {0} displaced swap without changing its sentinel" -f `
        $casCase.Name) {
      $caseRoot = Join-Path $FixtureRoot ('prepared-cas-' + $casCase.Name)
      $project = Join-Path $caseRoot 'project'
      $outside = Join-Path $caseRoot 'outside'
      [void](New-Item -ItemType Directory -Path $project -Force)
      [void](New-Item -ItemType Directory -Path $outside -Force)
      $target = Join-Path $project 'README.md'
      $prepared = Join-Path $project '.prepared.tmp'
      $sentinel = Join-Path $outside 'sentinel.md'
      Write-CzxtNoBomText $target "expected-target`n"
      Write-CzxtNoBomText $prepared "installer-new`n"
      Write-CzxtNoBomText $sentinel $casCase.SentinelText
      $expectedTarget = Get-CzxtInstallerFileState -Path $target -Context 'CAS fixture'
      $sentinelBefore = Get-BorrowingByteSignature $sentinel
      $script:CzxtInstallerCasHookRan = $false
      $swapIdentity = {
        param([string]$HookTarget, [string]$HookPrepared)
        $script:CzxtInstallerCasHookRan = $true
        [IO.File]::Delete($HookTarget)
        [void](New-Item -ItemType HardLink -Path $HookTarget -Target $sentinel)
      }
      $rejected = $false
      try {
        [void](Set-CzxtInstallerPreparedFile -ProjectRoot $project `
          -PreparedPath $prepared -TargetPath $target -Context 'CAS fixture' `
          -ExpectedPresentState $expectedTarget `
          -ExpectedPreparedState (Get-CzxtInstallerFileState $prepared 'CAS prepared') `
          -BeforeReplace $swapIdentity)
      }
      catch { $rejected = $true }
      Assert-CzxtTrue $script:CzxtInstallerCasHookRan `
        ("{0} CAS injection hook did not run" -f $casCase.Name)
      Assert-CzxtTrue $rejected ("{0} CAS identity swap was accepted" -f $casCase.Name)
      Assert-CzxtEqual $sentinelBefore (Get-BorrowingByteSignature $sentinel) `
        ("{0} CAS identity swap changed the external sentinel" -f $casCase.Name)
      Assert-CzxtEqual "installer-new`n" ([IO.File]::ReadAllText($target)) `
        ("{0} CAS did not preserve the installed object at target" -f $casCase.Name)
      $backups = @(Get-BorrowingInstallerBackupFiles $project)
      Assert-CzxtEqual 1 $backups.Count `
        ("{0} CAS did not retain exactly one displaced backup" -f $casCase.Name)
      $backupState = [Czxt.InstallerNative]::Read($backups[0].FullName)
      $sentinelState = [Czxt.InstallerNative]::Read($sentinel)
      $backupIdentity = '{0:x8}:{1:x8}:{2:x8}' -f $backupState.VolumeSerialNumber,
        $backupState.FileIndexHigh, $backupState.FileIndexLow
      $sentinelIdentity = '{0:x8}:{1:x8}:{2:x8}' -f $sentinelState.VolumeSerialNumber,
        $sentinelState.FileIndexHigh, $sentinelState.FileIndexLow
      Assert-CzxtEqual $sentinelIdentity $backupIdentity `
        ("{0} CAS backup did not preserve the displaced identity" -f $casCase.Name)
      Assert-CzxtEqual $sentinelBefore (Get-BorrowingByteSignature $backups[0].FullName) `
        ("{0} CAS backup did not preserve the displaced bytes" -f $casCase.Name)
    }
  }

  Invoke-CzxtContract 'prepared-file CAS preserves an equal-length displaced content race' {
    $caseRoot = Join-Path $FixtureRoot 'prepared-cas-in-place-content'
    $project = Join-Path $caseRoot 'project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project 'README.md'
    $prepared = Join-Path $project '.prepared.tmp'
    Write-CzxtNoBomText $target 'aaaaaaaaaaaaaaaa'
    Write-CzxtNoBomText $prepared 'installer-new'
    $expectedTarget = Get-CzxtInstallerFileState -Path $target -Context 'CAS content fixture'
    $script:CzxtInstallerCasHookRan = $false
    $mutateInPlace = {
      param([string]$HookTarget, [string]$HookPrepared)
      $script:CzxtInstallerCasHookRan = $true
      [IO.File]::WriteAllText($HookTarget, 'bbbbbbbbbbbbbbbb', $script:CzxtUtf8NoBom)
    }
    $rejected = $false
    try {
      [void](Set-CzxtInstallerPreparedFile -ProjectRoot $project `
        -PreparedPath $prepared -TargetPath $target -Context 'CAS content fixture' `
        -ExpectedPresentState $expectedTarget `
        -ExpectedPreparedState (Get-CzxtInstallerFileState $prepared 'CAS content prepared') `
        -BeforeReplace $mutateInPlace)
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $script:CzxtInstallerCasHookRan 'in-place CAS injection hook did not run'
    Assert-CzxtTrue $rejected 'equal-length in-place CAS content race was accepted'
    Assert-CzxtEqual 'installer-new' ([IO.File]::ReadAllText($target)) `
      'CAS did not preserve the installed object after the content race'
    Assert-BorrowingBackupWithText -Directory $project `
      -ExpectedText 'bbbbbbbbbbbbbbbb' `
      -Message 'CAS did not retain the displaced in-place bytes'
  }

  Invoke-CzxtContract 'recursive copy ExpectAbsent rejects a target created immediately before landing' {
    $caseRoot = Join-Path $FixtureRoot 'recursive-expect-absent-race'
    $template = Join-Path $caseRoot 'template'
    $project = Join-Path $caseRoot 'project'
    $sourceRoot = Join-Path $template 'Docs'
    $targetRoot = Join-Path $project 'Docs'
    $source = Join-Path $sourceRoot 'race.md'
    $target = Join-Path $targetRoot 'race.md'
    [void](New-Item -ItemType Directory -Path $sourceRoot -Force)
    [void](New-Item -ItemType Directory -Path $project -Force)
    Write-CzxtNoBomText $source "installer-source`n"
    $script:CzxtInstallerAbsentHookRan = $false
    $createConcurrentTarget = {
      param([string]$HookTarget, [string]$HookPrepared)
      $script:CzxtInstallerAbsentHookRan = $true
      Write-CzxtNoBomText $HookTarget "concurrent-owner`n"
    }
    $rejected = $false
    try {
      Copy-CzxtInstallerTree -TemplateRoot $template -ProjectRoot $project `
        -SourcePath $sourceRoot -TargetPath $targetRoot -ExpectAbsentTree `
        -BeforeTargetCommit $createConcurrentTarget
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $script:CzxtInstallerAbsentHookRan `
      'ExpectAbsent injection hook did not run at the recursive leaf'
    Assert-CzxtTrue $rejected 'ExpectAbsent accepted a concurrently created target'
    Assert-CzxtEqual "concurrent-owner`n" ([IO.File]::ReadAllText($target)) `
      'ExpectAbsent changed the concurrently created target'
  }

  Invoke-CzxtContract 'recursive copy rejects an omitted target expectation mode' {
    $caseRoot = Join-Path $FixtureRoot 'recursive-missing-expectation'
    $template = Join-Path $caseRoot 'template'
    $project = Join-Path $caseRoot 'project'
    $source = Join-Path $template 'README.md'
    $target = Join-Path $project 'README.md'
    [void](New-Item -ItemType Directory -Path $template -Force)
    [void](New-Item -ItemType Directory -Path $project -Force)
    Write-CzxtNoBomText $source "installer-source`n"
    $rejected = $false
    try {
      Copy-CzxtInstallerTree -TemplateRoot $template -ProjectRoot $project `
        -SourcePath $source -TargetPath $target
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $rejected 'recursive copy accepted an omitted expectation mode'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $target)) `
      'recursive copy wrote a target without an explicit expectation mode'
  }

  Invoke-CzxtContract 'output manifest rejects an installed file replaced before placeholder snapshot' {
    $caseRoot = Join-Path $FixtureRoot 'installed-output-replaced-before-rewrite'
    $project = Join-Path $caseRoot 'project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project 'README.md'
    $manifest = New-CzxtInstallerOutputManifest
    Write-CzxtInstallerTextFile -ProjectRoot $project -TargetPath $target `
      -Content 'name={{PROJECT_NAME}}' -Encoding $script:CzxtUtf8NoBom `
      -Context 'output manifest fixture' -ExpectAbsent -InstalledFiles $manifest
    $installed = Get-CzxtInstallerOutputState -InstalledFiles $manifest -Path $target
    [IO.File]::Delete($target)
    Write-CzxtNoBomText $target 'attacker={{PROJECT_NAME}}'
    $attackerBefore = Get-BorrowingByteSignature $target
    $attackerState = Get-CzxtInstallerFileState -Path $target -Context 'attacker target'
    Assert-CzxtTrue ($installed.Identity -cne $attackerState.Identity) `
      'replacement fixture did not change the target identity'
    $rejected = $false
    try {
      [void](Get-CzxtInstallerOutputTextSnapshot -ProjectRoot $project `
        -InstalledFiles $manifest -TargetPath $target -Context 'output manifest fixture')
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $rejected `
      'output manifest accepted a replacement as the placeholder rewrite baseline'
    Assert-CzxtEqual $attackerBefore (Get-BorrowingByteSignature $target) `
      'output manifest rejection changed the replacement target'
  }

  Invoke-CzxtContract 'bound text snapshot rejects a placeholder read-side ABA' {
    $caseRoot = Join-Path $FixtureRoot 'placeholder-read-aba'
    $project = Join-Path $caseRoot 'project'
    $outside = Join-Path $caseRoot 'outside'
    [void](New-Item -ItemType Directory -Path $project -Force)
    [void](New-Item -ItemType Directory -Path $outside -Force)
    $target = Join-Path $project 'README.md'
    $savedOriginal = Join-Path $project '.original.saved'
    $sentinel = Join-Path $outside 'attacker.md'
    Write-CzxtNoBomText $target 'original={{PROJECT_NAME}}'
    Write-CzxtNoBomText $sentinel 'attacker={{PROJECT_NAME}}'
    $targetBefore = Get-BorrowingByteSignature $target
    $sentinelBefore = Get-BorrowingByteSignature $sentinel
    $script:CzxtInstallerBeforeReadHookRan = $false
    $script:CzxtInstallerAfterReadHookRan = $false
    $beforeRead = {
      param([string]$HookTarget)
      $script:CzxtInstallerBeforeReadHookRan = $true
      [IO.File]::Move($HookTarget, $savedOriginal)
      [IO.File]::Move($sentinel, $HookTarget)
    }
    $afterRead = {
      param([string]$HookTarget)
      [IO.File]::Move($HookTarget, $sentinel)
      [IO.File]::Move($savedOriginal, $HookTarget)
      $script:CzxtInstallerAfterReadHookRan = $true
    }
    $rejected = $false
    try {
      $snapshot = Get-CzxtInstallerTextSnapshot -ProjectRoot $project `
        -TargetPath $target -Context 'placeholder ABA fixture' `
        -BeforeSnapshotRead $beforeRead -AfterSnapshotRead $afterRead
      $rewritten = $snapshot.Text.Replace('{{PROJECT_NAME}}', 'safe-project')
      Write-CzxtInstallerTextFile -ProjectRoot $project -TargetPath $target `
        -Content $rewritten -Encoding $script:CzxtUtf8NoBom `
        -Context 'placeholder ABA fixture' -ExpectedPresentState $snapshot.State
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $script:CzxtInstallerBeforeReadHookRan `
      'placeholder ABA before-read hook did not run'
    Assert-CzxtTrue $script:CzxtInstallerAfterReadHookRan `
      'placeholder ABA after-read hook did not restore the original'
    Assert-CzxtTrue $rejected 'placeholder read-side ABA was accepted'
    Assert-CzxtEqual $targetBefore (Get-BorrowingByteSignature $target) `
      'placeholder read-side ABA changed the original target'
    Assert-CzxtEqual $sentinelBefore (Get-BorrowingByteSignature $sentinel) `
      'placeholder read-side ABA changed the attacker sentinel'
  }

  Invoke-CzxtContract 'bound byte snapshot rejects an append read-side ABA' {
    $caseRoot = Join-Path $FixtureRoot 'append-read-aba'
    $project = Join-Path $caseRoot 'project'
    $outside = Join-Path $caseRoot 'outside'
    [void](New-Item -ItemType Directory -Path $project -Force)
    [void](New-Item -ItemType Directory -Path $outside -Force)
    $target = Join-Path $project '状态.md'
    $savedOriginal = Join-Path $project '.original.saved'
    $sentinel = Join-Path $outside 'attacker.md'
    Write-CzxtNoBomText $target 'original-state'
    Write-CzxtNoBomText $sentinel 'attacker-base'
    $expectedTarget = Get-CzxtInstallerFileState -Path $target -Context 'append ABA fixture'
    $targetBefore = Get-BorrowingByteSignature $target
    $sentinelBefore = Get-BorrowingByteSignature $sentinel
    $script:CzxtInstallerBeforeReadHookRan = $false
    $script:CzxtInstallerAfterReadHookRan = $false
    $beforeRead = {
      param([string]$HookTarget)
      $script:CzxtInstallerBeforeReadHookRan = $true
      [IO.File]::Move($HookTarget, $savedOriginal)
      [IO.File]::Move($sentinel, $HookTarget)
    }
    $afterRead = {
      param([string]$HookTarget)
      [IO.File]::Move($HookTarget, $sentinel)
      [IO.File]::Move($savedOriginal, $HookTarget)
      $script:CzxtInstallerAfterReadHookRan = $true
    }
    $rejected = $false
    try {
      Add-CzxtInstallerTextFile -ProjectRoot $project -TargetPath $target `
        -Content '+append' -Encoding $script:CzxtUtf8NoBom -Context 'append ABA fixture' `
        -ExpectedPresentState $expectedTarget `
        -BeforeSnapshotRead $beforeRead -AfterSnapshotRead $afterRead
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $script:CzxtInstallerBeforeReadHookRan `
      'append ABA before-read hook did not run'
    Assert-CzxtTrue $script:CzxtInstallerAfterReadHookRan `
      'append ABA after-read hook did not restore the original'
    Assert-CzxtTrue $rejected 'append read-side ABA was accepted'
    Assert-CzxtEqual $targetBefore (Get-BorrowingByteSignature $target) `
      'append read-side ABA changed the original target'
    Assert-CzxtEqual $sentinelBefore (Get-BorrowingByteSignature $sentinel) `
      'append read-side ABA changed the attacker sentinel'
  }
}
