$ErrorActionPreference = 'Stop'

function Get-BorrowingInstallerBackupFiles {
  param([string]$Directory)
  return @(Get-ChildItem -LiteralPath $Directory -Force -File `
      -Filter '.czxt-backup-*.tmp' -ErrorAction SilentlyContinue)
}

function Assert-BorrowingBackupWithText {
  param([string]$Directory, [string]$ExpectedText, [string]$Message)
  $matches = @(Get-BorrowingInstallerBackupFiles $Directory | Where-Object {
      [IO.File]::ReadAllText($_.FullName) -ceq $ExpectedText
    })
  Assert-CzxtEqual 1 $matches.Count $Message
}

function Invoke-BorrowingInstallerRecoveryContracts {
  param([string]$FixtureRoot)

  Invoke-CzxtContract 'prepared-file recovery stops on a second target change and retains every object' {
    $caseRoot = Join-Path $FixtureRoot 'prepared-double-change'
    $project = Join-Path $caseRoot 'project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project 'README.md'
    $prepared = Join-Path $project '.prepared.tmp'
    $first = Join-Path $project '.first-owner.tmp'
    $second = Join-Path $project '.second-owner.tmp'
    $savedOriginal = Join-Path $project '.saved-original.tmp'
    $savedInstalled = Join-Path $project '.saved-installed.tmp'
    Write-CzxtNoBomText $target 'original-owner'
    Write-CzxtNoBomText $prepared 'installer-owner'
    Write-CzxtNoBomText $first 'first-concurrent-owner'
    Write-CzxtNoBomText $second 'second-concurrent-owner'
    $expectedTarget = Get-CzxtInstallerFileState -Path $target -Context 'double-change fixture'
    $script:CzxtInstallerBeforeRecoveryHookRan = $false
    $firstSwap = {
      param([string]$HookTarget, [string]$HookPrepared)
      [IO.File]::Move($HookTarget, $savedOriginal)
      [IO.File]::Move($first, $HookTarget)
    }
    $secondSwap = {
      param([string]$HookTarget, [string]$HookBackup)
      $script:CzxtInstallerBeforeRecoveryHookRan = $true
      [IO.File]::Move($HookTarget, $savedInstalled)
      [IO.File]::Move($second, $HookTarget)
    }
    $rejected = $false
    try {
      [void](Set-CzxtInstallerPreparedFile -ProjectRoot $project `
        -PreparedPath $prepared -TargetPath $target -Context 'double-change fixture' `
        -ExpectedPresentState $expectedTarget `
        -ExpectedPreparedState (Get-CzxtInstallerFileState $prepared 'double-change prepared') `
        -BeforeReplace $firstSwap `
        -BeforeRecovery $secondSwap)
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $script:CzxtInstallerBeforeRecoveryHookRan `
      'second target change hook did not run before recovery'
    Assert-CzxtTrue $rejected 'prepared-file recovery accepted a second target change'
    Assert-CzxtEqual 'second-concurrent-owner' ([IO.File]::ReadAllText($target)) `
      'recovery overwrote the second concurrent target'
    Assert-CzxtEqual 'original-owner' ([IO.File]::ReadAllText($savedOriginal)) `
      'recovery lost the original preflight object'
    Assert-CzxtEqual 'installer-owner' ([IO.File]::ReadAllText($savedInstalled)) `
      'recovery lost the installer-owned object'
    Assert-BorrowingBackupWithText -Directory $project `
      -ExpectedText 'first-concurrent-owner' `
      -Message 'recovery did not retain the first displaced concurrent object'
  }

  Invoke-CzxtContract 'prepared-file post-write failure retains backup until final verification' {
    $caseRoot = Join-Path $FixtureRoot 'prepared-post-write-failure'
    $project = Join-Path $caseRoot 'project'
    [void](New-Item -ItemType Directory -Path $project -Force)
    $target = Join-Path $project '状态.md'
    $prepared = Join-Path $project '.prepared.tmp'
    $second = Join-Path $project '.second-owner.tmp'
    $savedInstalled = Join-Path $project '.saved-installed.tmp'
    Write-CzxtNoBomText $target 'original-owner'
    Write-CzxtNoBomText $prepared 'installer-owner'
    Write-CzxtNoBomText $second 'post-write-concurrent-owner'
    $expectedTarget = Get-CzxtInstallerFileState -Path $target -Context 'post-write fixture'
    $script:CzxtInstallerBeforeCommitVerificationHookRan = $false
    $replaceAfterLanding = {
      param([string]$HookTarget, [string]$HookBackup)
      $script:CzxtInstallerBeforeCommitVerificationHookRan = $true
      [IO.File]::Move($HookTarget, $savedInstalled)
      [IO.File]::Move($second, $HookTarget)
    }
    $rejected = $false
    try {
      [void](Set-CzxtInstallerPreparedFile -ProjectRoot $project `
        -PreparedPath $prepared -TargetPath $target -Context 'post-write fixture' `
        -ExpectedPresentState $expectedTarget `
        -ExpectedPreparedState (Get-CzxtInstallerFileState $prepared 'post-write prepared') `
        -BeforeCommitVerification $replaceAfterLanding)
    }
    catch { $rejected = $true }
    Assert-CzxtTrue $script:CzxtInstallerBeforeCommitVerificationHookRan `
      'post-write verification hook did not run before backup commit'
    Assert-CzxtTrue $rejected 'prepared-file write accepted a changed landed target'
    Assert-CzxtEqual 'post-write-concurrent-owner' ([IO.File]::ReadAllText($target)) `
      'post-write failure changed the later target object'
    Assert-CzxtEqual 'installer-owner' ([IO.File]::ReadAllText($savedInstalled)) `
      'post-write failure lost the installer-owned object'
    Assert-BorrowingBackupWithText -Directory $project -ExpectedText 'original-owner' `
      -Message 'post-write failure deleted the original backup before final verification'
  }
}
