[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-item-test-support.ps1')

$script:SealHelperRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$script:SealCaptureRoot = Join-Path $script:SealHelperRoot 'borrowing-capture'

function Assert-BsiCondition {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Test-BsiSamePath {
  param([string]$Left, [string]$Right)
  return [string]::Equals($Left, $Right, [StringComparison]::OrdinalIgnoreCase)
}

. (Join-Path $script:SealCaptureRoot 'common.ps1')
. (Join-Path $script:SealCaptureRoot 'file-safety.ps1')
. (Join-Path $script:SealCaptureRoot 'source-candidate-parser.ps1')
. (Join-Path $script:SealHelperRoot 'borrowing-seal-transaction.ps1')
. (Join-Path $script:SealHelperRoot 'borrowing-conditional-replace.ps1')
. (Join-Path $script:SealHelperRoot 'borrowing-seal-attestation.ps1')

function New-SealFailureCase {
  param([string]$Name, [ValidateSet('project', 'template', 'unknown', 'conflict')][string]$Mode)
  $root = if ($Mode -eq 'template') { New-TemplateSkeleton ('seal-' + $Name) } `
    else { New-ProjectSkeleton ('seal-' + $Name) }
  if ($Mode -eq 'unknown') { Remove-Item -LiteralPath (Join-Path $root '.czxt-project-root') -Force }
  if ($Mode -eq 'conflict') {
    Write-P4tUtf8 (Join-Path $root '.czxt-template-root') "czxt-root-mode=template`nschema=1`n"
  }
  $source = New-P4tSourceCapture $root local 'source-seal'
  Set-P4tSourceReuseScope $source adapt-internal-approved
  $item = New-P4tItemCard -Root $root -BorrowId ('borrow-20260719-' + $Name) `
    -Bindings @($source) -Status closed -Decision adapt
  return [pscustomobject]@{ Name = $Name; Root = $root; Source = $source; Item = $item }
}

function Write-SealCasRaceWrapper {
  param([string]$Path)
  Write-P4tUtf8 $Path @'
[CmdletBinding()]
param(
  [string]$Root, [string]$CardPath,
  [string]$SealPath, [string]$MarkerPath
)
$ErrorActionPreference = 'Stop'
$global:BsiContractRaceInjected = $false
$global:BsiContractRaceCardPath = $CardPath
$global:BsiContractRaceMarkerPath = $MarkerPath
$global:BsiContractRaceBytes = [Text.Encoding]::UTF8.GetBytes("concurrent-seal-race`n")
[void](Set-PSBreakpoint -Command Assert-BsiTemporaryUnchanged -Action {
  if (-not $global:BsiContractRaceInjected) {
    $global:BsiContractRaceInjected = $true
    $directory = Split-Path -Parent $global:BsiContractRaceCardPath
    $replacement = Join-Path $directory `
      ('.contract-seal-race-' + [guid]::NewGuid().ToString('N') + '.tmp')
    [IO.File]::WriteAllBytes($replacement, $global:BsiContractRaceBytes)
    [IO.File]::Delete($global:BsiContractRaceCardPath)
    [IO.File]::Move($replacement, $global:BsiContractRaceCardPath)
    $snapshot = Get-BsiStableSnapshot $global:BsiContractRaceCardPath
    $marker = $snapshot.IdentityKey + "`n" +
      [Convert]::ToBase64String($snapshot.Bytes) + "`n"
    [IO.File]::WriteAllText($global:BsiContractRaceMarkerPath, $marker,
      (New-Object Text.UTF8Encoding($false)))
  }
})
& $SealPath -Root $Root -CardPath $CardPath
exit $LASTEXITCODE
'@
}

Initialize-P4tTestFixture
try {
  Invoke-CzxtContract 'seal snapshot consumes one handle-bound metadata and byte snapshot' {
    $path = Join-Path $script:P4tFixtureRoot 'seal-snapshot-source.txt'
    $bytes = [Text.Encoding]::UTF8.GetBytes("handle-bound`n")
    [IO.File]::WriteAllBytes($path, $bytes)
    Assert-CzxtTrue ($null -ne (Get-Command Read-BorrowingStableSafeFileSnapshot `
          -CommandType Function -ErrorAction SilentlyContinue)) `
      'handle-bound snapshot API is missing'
    $realBytesReader = (Get-Command Read-BorrowingStableSafeFileBytes `
        -CommandType Function).ScriptBlock
    try {
      Set-Item -LiteralPath Function:\global:Read-BorrowingStableSafeFileBytes -Value {
        throw 'bytes-only trusted reader must not be composed into a metadata snapshot'
      }
      $snapshot = Get-BsiStableSnapshot $path
    }
    finally {
      Set-Item -LiteralPath Function:\global:Read-BorrowingStableSafeFileBytes `
        -Value $realBytesReader
    }
    Assert-CzxtEqual ([Convert]::ToBase64String($bytes)) `
      ([Convert]::ToBase64String([byte[]]$snapshot.Bytes)) `
      'handle-bound seal snapshot bytes'
    Assert-CzxtEqual ([uint64]$bytes.LongLength) ([uint64]$snapshot.Length) `
      'handle-bound seal snapshot length'
  }

  $failures = @(
    (New-SealFailureCase 'template-mode' template),
    (New-SealFailureCase 'unknown-mode' unknown),
    (New-SealFailureCase 'conflict-mode' conflict)
  )
  $case = New-SealFailureCase 'non-closed' project
  Set-P4tFrontmatterField $case.Item.CardPath lifecycle_status verifying
  Set-P4tFrontmatterField $case.Item.CardPath decision adapt
  $failures += $case
  $case = New-SealFailureCase 'already-sealed' project
  [void](Set-P4tFixtureSeal $case.Item.CardPath)
  $failures += $case
  $case = New-SealFailureCase 'outside-item-zone' project
  $outsideCard = Join-Path $case.Root 'outside-card.md'
  Copy-Item -LiteralPath $case.Item.CardPath -Destination $outsideCard
  $case.Item.CardPath = $outsideCard
  $failures += $case
  $case = New-SealFailureCase 'reparse-item-path' project
  $itemDirectory = Split-Path -Parent $case.Item.CardPath
  $outsideDirectory = Join-Path $script:P4tFixtureRoot 'seal-reparse-target'
  Move-Item -LiteralPath $itemDirectory -Destination $outsideDirectory
  [void](New-P4tJunction $itemDirectory $outsideDirectory)
  $case.Item.CardPath = Join-Path $itemDirectory '借鉴卡.md'
  $failures += $case

  $validRoot = New-ProjectSkeleton 'seal-valid'
  $validSource = New-P4tSourceCapture $validRoot local 'source-seal'
  Set-P4tSourceReuseScope $validSource adapt-internal-approved
  $validItem = New-P4tItemCard -Root $validRoot -BorrowId 'borrow-20260719-valid-seal' `
    -Bindings @($validSource) -Status closed -Decision adapt
  $otherItem = New-P4tItemCard $validRoot 'borrow-20260719-other-item' @($validSource) draft pending

  Invoke-CzxtContract 'seal fixtures cover mode path state and explicit-target boundaries' {
    Assert-CzxtEqual 7 $failures.Count 'seal failure fixture count'
    foreach ($entry in $failures) {
      Assert-CzxtTrue (Test-Path -LiteralPath $entry.Item.CardPath -PathType Leaf) `
        ($entry.Name + ' target card')
    }
    Assert-CzxtTrue (Test-Path -LiteralPath $validItem.CardPath -PathType Leaf) 'valid seal target'
  }

  $script:SealReady = $false
  Invoke-CzxtContract 'seal borrowing item façade exists as the only write entry' {
    Assert-CzxtTrue (Test-Path -LiteralPath $script:P4tSealPath -PathType Leaf) `
      ('missing seal façade: ' + $script:P4tSealPath)
    $script:SealReady = $true
  }

  if ($script:SealReady) {
    Invoke-CzxtContract 'conditional replace restores the old object when post-replace snapshots fail' {
      foreach ($failureCall in @(3, 4)) {
        $directory = Join-Path $script:P4tFixtureRoot `
          ('seal-start-snapshot-failure-' + $failureCall)
        [void](New-Item -ItemType Directory -Path $directory)
        $target = Join-Path $directory '借鉴卡.md'
        [byte[]]$originalBytes = [Text.Encoding]::UTF8.GetBytes("original-$failureCall`n")
        [byte[]]$replacementBytes = [Text.Encoding]::UTF8.GetBytes("sealed-$failureCall`n")
        [IO.File]::WriteAllBytes($target, $originalBytes)
        $baseline = Get-BsiStableSnapshot $target
        $temporary = New-BsiTemporaryFile $directory $replacementBytes
        $realSnapshot = (Get-Item Function:\Get-BsiStableSnapshot).ScriptBlock
        $script:BsiSnapshotFailureCall = 0
        $script:BsiSnapshotFailureSeen = $false
        try {
          Set-Item Function:\Get-BsiStableSnapshot -Value {
            param([string]$Path)
            $script:BsiSnapshotFailureCall++
            if (-not $script:BsiSnapshotFailureSeen -and
                $script:BsiSnapshotFailureCall -eq $failureCall) {
              $script:BsiSnapshotFailureSeen = $true
              throw 'contract injected post-replace snapshot failure'
            }
            return & $realSnapshot $Path
          }
          $rejected = $false
          try {
            [void](Start-BsiConditionalReplace $temporary $target `
                $baseline $replacementBytes)
          }
          catch { $rejected = $true }
        }
        finally {
          Set-Item Function:\Get-BsiStableSnapshot -Value $realSnapshot
        }
        Assert-CzxtTrue $script:BsiSnapshotFailureSeen `
          ('post-replace snapshot injection ' + $failureCall)
        Assert-CzxtTrue $rejected `
          ('post-replace snapshot failure accepted ' + $failureCall)
        $after = Get-BsiStableSnapshot $target
        Assert-CzxtEqual $baseline.IdentityKey $after.IdentityKey `
          ('post-replace snapshot failure identity ' + $failureCall)
        Assert-CzxtEqual ([Convert]::ToBase64String($originalBytes)) `
          ([Convert]::ToBase64String($after.Bytes)) `
          ('post-replace snapshot failure bytes ' + $failureCall)
        $residue = @(Get-ChildItem -LiteralPath $directory -Force |
          Where-Object { $_.Name -like '.staging-replace-*' })
        Assert-CzxtEqual 0 $residue.Count `
          ('post-replace snapshot failure residue ' + $failureCall)
      }
    }

    Invoke-CzxtContract 'conditional replace never installs over an ABA target after final validation' {
      $directory = Join-Path $script:P4tFixtureRoot 'seal-conditional-aba-window'
      [void](New-Item -ItemType Directory -Path $directory)
      $target = Join-Path $directory '借鉴卡.md'
      [byte[]]$originalBytes = [Text.Encoding]::UTF8.GetBytes("original`n")
      [byte[]]$replacementBytes = [Text.Encoding]::UTF8.GetBytes("sealed`n")
      [byte[]]$concurrentBytes = [Text.Encoding]::UTF8.GetBytes("concurrent`n")
      [IO.File]::WriteAllBytes($target, $originalBytes)
      $baseline = Get-BsiStableSnapshot $target
      $temporary = New-BsiTemporaryFile $directory $replacementBytes
      $script:BsiAbaTarget = $target
      $script:BsiAbaConcurrentBytes = $concurrentBytes
      $script:BsiAbaRealTemporaryCheck =
        (Get-Item Function:\Assert-BsiTemporaryUnchanged).ScriptBlock
      $existingAtomicReplace = Get-Item Function:\Invoke-BsiAtomicReplace `
        -ErrorAction SilentlyContinue
      $script:BsiAbaInjected = $false
      $script:BsiAbaInstalledOverConcurrent = $false
      $script:BsiAbaConcurrent = $null
      $rejected = $false
      try {
        Set-Item Function:\Assert-BsiTemporaryUnchanged -Value {
          param($Temporary, [byte[]]$ExpectedBytes)
          & $script:BsiAbaRealTemporaryCheck $Temporary $ExpectedBytes
          if (-not $script:BsiAbaInjected) {
            $replacement = $script:BsiAbaTarget + '.concurrent'
            [IO.File]::WriteAllBytes($replacement, $script:BsiAbaConcurrentBytes)
            [IO.File]::Delete($script:BsiAbaTarget)
            [IO.File]::Move($replacement, $script:BsiAbaTarget)
            $script:BsiAbaConcurrent = Get-BsiStableSnapshot $script:BsiAbaTarget
            $script:BsiAbaInjected = $true
          }
        }
        Set-Item Function:\Invoke-BsiAtomicReplace -Value {
          param([string]$TemporaryPath, [string]$TargetPath, [string]$BackupPath)
          $script:BsiAbaInstalledOverConcurrent = $true
          throw 'legacy overwrite primitive must not be called'
        }
        try {
          [void](Start-BsiConditionalReplace $temporary $target `
              $baseline $replacementBytes)
        }
        catch { $rejected = $true }
      }
      finally {
        Set-Item Function:\Assert-BsiTemporaryUnchanged `
          -Value $script:BsiAbaRealTemporaryCheck
        if ($null -ne $existingAtomicReplace) {
          Set-Item Function:\Invoke-BsiAtomicReplace `
            -Value $existingAtomicReplace.ScriptBlock
        }
        else {
          Remove-Item Function:\Invoke-BsiAtomicReplace -ErrorAction SilentlyContinue
        }
      }
      Assert-CzxtTrue $script:BsiAbaInjected 'conditional ABA injection did not run'
      Assert-CzxtTrue $rejected 'conditional ABA target was accepted'
      Assert-CzxtTrue (-not $script:BsiAbaInstalledOverConcurrent) `
        'conditional replace transiently installed over the concurrent formal object'
      $after = Get-BsiStableSnapshot $target
      Assert-CzxtEqual $script:BsiAbaConcurrent.IdentityKey $after.IdentityKey `
        'conditional ABA changed the concurrent target identity'
      Assert-CzxtEqual ([Convert]::ToBase64String($concurrentBytes)) `
        ([Convert]::ToBase64String($after.Bytes)) `
        'conditional ABA changed the concurrent target bytes'
    }

    Invoke-CzxtContract 'conditional replace keeps the installed object bound through commit cleanup' {
      $directory = Join-Path $script:P4tFixtureRoot 'seal-complete-target-lock'
      [void](New-Item -ItemType Directory -Path $directory)
      $target = Join-Path $directory '借鉴卡.md'
      [byte[]]$originalBytes = [Text.Encoding]::UTF8.GetBytes("original`n")
      [byte[]]$replacementBytes = [Text.Encoding]::UTF8.GetBytes("sealed`n")
      [byte[]]$laterBytes = [Text.Encoding]::UTF8.GetBytes("later-version`n")
      [IO.File]::WriteAllBytes($target, $originalBytes)
      $baseline = Get-BsiStableSnapshot $target
      $temporary = New-BsiTemporaryFile $directory $replacementBytes
      $transaction = Start-BsiConditionalReplace $temporary $target `
        $baseline $replacementBytes
      $global:BsiCommitTargetPath = $target
      $global:BsiCommitLaterBytes = $laterBytes
      $global:BsiCommitSwapAttempted = $false
      $global:BsiCommitSwapInstalled = $false
      $breakpoint = Set-PSBreakpoint -Command Remove-BsiOwnedSnapshotFile -Action {
        if (-not $global:BsiCommitSwapAttempted) {
          $global:BsiCommitSwapAttempted = $true
          $replacement = $global:BsiCommitTargetPath + '.later'
          try {
            [IO.File]::WriteAllBytes($replacement, $global:BsiCommitLaterBytes)
            [IO.File]::Delete($global:BsiCommitTargetPath)
            [IO.File]::Move($replacement, $global:BsiCommitTargetPath)
            $global:BsiCommitSwapInstalled = $true
          }
          catch {
            if (Test-Path -LiteralPath $replacement -PathType Leaf) {
              [IO.File]::Delete($replacement)
            }
          }
        }
      }
      try { $completed = Complete-BsiConditionalReplace $transaction }
      finally { Remove-PSBreakpoint $breakpoint }
      Assert-CzxtTrue $global:BsiCommitSwapAttempted 'commit target replacement was not attempted'
      Assert-CzxtTrue (-not $global:BsiCommitSwapInstalled) `
        'commit cleanup did not keep the installed target bound'
      $after = Get-BsiStableSnapshot $target
      Assert-CzxtEqual $completed.IdentityKey $after.IdentityKey `
        'commit returned a stale target identity'
      Assert-CzxtEqual ([Convert]::ToBase64String($replacementBytes)) `
        ([Convert]::ToBase64String($after.Bytes)) 'commit returned stale target bytes'
    }

    Invoke-CzxtContract 'conditional replace stays completed after ignored pre-dispose hook failures' {
      foreach ($failureContext in @('条件替换 backup ', '条件替换 commit target ')) {
        $slug = if ($failureContext.Contains('backup')) { 'backup' } else { 'target' }
        $directory = Join-Path $script:P4tFixtureRoot `
          ('seal-post-commit-close-' + $slug)
        [void](New-Item -ItemType Directory -Path $directory)
        $target = Join-Path $directory '借鉴卡.md'
        [byte[]]$originalBytes = [Text.Encoding]::UTF8.GetBytes("original-$slug`n")
        [byte[]]$replacementBytes = [Text.Encoding]::UTF8.GetBytes("sealed-$slug`n")
        [IO.File]::WriteAllBytes($target, $originalBytes)
        $baseline = Get-BsiStableSnapshot $target
        $temporary = New-BsiTemporaryFile $directory $replacementBytes
        $transaction = Start-BsiConditionalReplace $temporary $target `
          $baseline $replacementBytes
        $script:BsiPreDisposeHookSeen = $false
        $script:BsiOwnedObjectTestInjections = @{
          'before-file-lock-dispose' = {
            param($Context)
            if (-not $script:BsiPreDisposeHookSeen -and
                $Context.Context -ceq $failureContext) {
              $script:BsiPreDisposeHookSeen = $true
              throw 'contract injected pre-dispose hook failure'
            }
          }
        }
        try { $completed = Complete-BsiConditionalReplace $transaction }
        finally {
          Remove-Variable BsiOwnedObjectTestInjections -Scope Script `
            -ErrorAction SilentlyContinue
        }
        Assert-CzxtTrue $script:BsiPreDisposeHookSeen `
          ('post-commit pre-dispose hook injection ' + $slug)
        Assert-CzxtEqual completed $transaction.State `
          ('post-commit transaction state ' + $slug)
        $after = Get-BsiStableSnapshot $target
        Assert-CzxtEqual $completed.IdentityKey $after.IdentityKey `
          ('post-commit target identity ' + $slug)
        Assert-CzxtEqual ([Convert]::ToBase64String($replacementBytes)) `
          ([Convert]::ToBase64String($after.Bytes)) `
          ('post-commit target bytes ' + $slug)
        $residue = @(Get-ChildItem -LiteralPath $directory -Force |
          Where-Object { $_.Name -like '.staging-replace-*' })
        Assert-CzxtEqual 0 $residue.Count ('post-commit residue ' + $slug)
      }
    }

    Invoke-CzxtContract 'owned temporary cleanup preserves a replacement at the same path' {
      $directory = Join-Path $script:P4tFixtureRoot 'seal-temporary-bound-delete'
      [void](New-Item -ItemType Directory -Path $directory)
      [byte[]]$ownedBytes = [Text.Encoding]::UTF8.GetBytes("owned-temp`n")
      [byte[]]$laterBytes = [Text.Encoding]::UTF8.GetBytes("later-temp`n")
      $temporary = New-BsiTemporaryFile $directory $ownedBytes
      $preservedPath = $temporary.Path + '.preserved'
      $script:BsiOwnedObjectTestInjections = @{
        'before-file-handle-open' = {
          param($Context)
          if ($Context.Path -ceq $temporary.Path) {
            [IO.File]::Move($temporary.Path, $preservedPath)
            [IO.File]::WriteAllBytes($temporary.Path, $laterBytes)
          }
        }
      }
      try { Remove-BsiOwnedTemporaryFile $temporary }
      finally { Remove-Variable BsiOwnedObjectTestInjections -Scope Script -ErrorAction SilentlyContinue }
      Assert-CzxtTrue (Test-Path -LiteralPath $temporary.Path -PathType Leaf) `
        'temporary cleanup deleted the later object'
      Assert-CzxtEqual ([Convert]::ToBase64String($laterBytes)) `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes($temporary.Path))) `
        'temporary cleanup changed the later object'
    }

    Invoke-CzxtContract 'owned backup and rescue cleanup preserve a replacement at the same path' {
      foreach ($kind in @('backup', 'rescue')) {
        $directory = Join-Path $script:P4tFixtureRoot ('seal-bound-delete-' + $kind)
        [void](New-Item -ItemType Directory -Path $directory)
        $path = Join-Path $directory ($kind + '.tmp')
        [byte[]]$ownedBytes = [Text.Encoding]::UTF8.GetBytes("owned-$kind`n")
        [byte[]]$laterBytes = [Text.Encoding]::UTF8.GetBytes("later-$kind`n")
        [IO.File]::WriteAllBytes($path, $ownedBytes)
        $owned = Get-BsiStableSnapshot $path
        $preservedPath = $path + '.preserved'
        $script:BsiOwnedObjectTestInjections = @{
          'before-file-handle-open' = {
            param($Context)
            if ($Context.Path -ceq $path) {
              [IO.File]::Move($path, $preservedPath)
              [IO.File]::WriteAllBytes($path, $laterBytes)
            }
          }
        }
        $rejected = $false
        try { Remove-BsiOwnedSnapshotFile $owned ('seal ' + $kind + ' ') }
        catch { $rejected = $true }
        finally {
          Remove-Variable BsiOwnedObjectTestInjections -Scope Script `
            -ErrorAction SilentlyContinue
        }
        Assert-CzxtTrue $rejected ($kind + ' cleanup accepted a replacement object')
        Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) `
          ($kind + ' cleanup deleted the replacement object')
        Assert-CzxtEqual ([Convert]::ToBase64String($laterBytes)) `
          ([Convert]::ToBase64String([IO.File]::ReadAllBytes($path))) `
          ($kind + ' cleanup changed the replacement object')
      }
    }

    foreach ($entry in $failures) {
      Invoke-CzxtContract ('seal refuses without writes: ' + $entry.Name) {
        $beforeRoot = Get-P4tTreeState $entry.Root
        $beforeCard = [IO.File]::ReadAllBytes($entry.Item.CardPath)
        $result = Invoke-CzxtPowerShell -ScriptPath $script:P4tSealPath -ScriptArguments @(
          '-Root', $entry.Root, '-CardPath', $entry.Item.CardPath)
        Assert-ExitCode $result 10 $entry.Name
        Assert-P4tTreeUnchanged $beforeRoot (Get-P4tTreeState $entry.Root) ($entry.Name + ' root')
        Assert-CzxtEqual ([Convert]::ToBase64String($beforeCard)) `
          ([Convert]::ToBase64String([IO.File]::ReadAllBytes($entry.Item.CardPath))) `
          ($entry.Name + ' card bytes')
      }
    }

    Invoke-CzxtContract 'seal preserves a concurrent object swapped after validation' {
      $root = New-ProjectSkeleton 'seal-cas-after-validation'
      $source = New-P4tSourceCapture $root local 'source-seal-cas'
      Set-P4tSourceReuseScope $source adapt-internal-approved
      $item = New-P4tItemCard -Root $root `
        -BorrowId 'borrow-20260719-seal-cas-after-validation' `
        -Bindings @($source) -Status closed -Decision adapt
      $wrapper = Join-Path $script:P4tFixtureRoot 'seal-cas-race-wrapper.ps1'
      $marker = Join-Path $script:P4tFixtureRoot 'seal-cas-race-marker.txt'
      Write-SealCasRaceWrapper $wrapper
      $result = Invoke-CzxtPowerShell -ScriptPath $wrapper -ScriptArguments @(
        '-Root', $root, '-CardPath', $item.CardPath,
        '-SealPath', $script:P4tSealPath, '-MarkerPath', $marker)
      Assert-CzxtTrue (Test-Path -LiteralPath $marker -PathType Leaf) `
        'seal CAS injection did not run after expected snapshot validation'
      $markerLines = @([IO.File]::ReadAllLines($marker, $script:P4tUtf8NoBom))
      Assert-CzxtEqual 2 $markerLines.Count 'seal CAS marker shape'
      $after = Get-BsiStableSnapshot $item.CardPath
      Assert-CzxtEqual $markerLines[0] $after.IdentityKey `
        'seal CAS overwrote the concurrent object identity'
      Assert-CzxtEqual $markerLines[1] ([Convert]::ToBase64String($after.Bytes)) `
        'seal CAS overwrote the concurrent object bytes'
      $residue = @(Get-ChildItem -LiteralPath (Split-Path -Parent $item.CardPath) `
        -Force | Where-Object { $_.Name -like '.staging-replace-*' })
      Assert-CzxtEqual 0 $residue.Count 'seal CAS recovery left replacement residue'
      Assert-CzxtEqual 10 $result.ExitCode `
        'seal CAS accepted a changed replacement target'
    }

    Invoke-CzxtContract 'seal restores the exact original object when post-check fails' {
      $root = New-ProjectSkeleton 'seal-post-check-rollback'
      $source = New-P4tSourceCapture $root local 'source-seal-post-check'
      Set-P4tSourceReuseScope $source adapt-internal-approved
      $item = New-P4tItemCard -Root $root `
        -BorrowId 'borrow-20260719-seal-post-check-rollback' `
        -Bindings @($source) -Status closed -Decision adapt
      $invalid = New-P4tItemCard -Root $root `
        -BorrowId 'borrow-20260719-seal-post-check-invalid' `
        -Bindings @($source) -Status draft -Decision pending
      Set-P4tFrontmatterField $invalid.CardPath decision invalid
      $before = Get-BsiStableSnapshot $item.CardPath

      $result = Invoke-CzxtPowerShell -ScriptPath $script:P4tSealPath -ScriptArguments @(
        '-Root', $root, '-CardPath', $item.CardPath)

      Assert-ExitCode $result 10 'seal post-check rollback'
      $after = Get-BsiStableSnapshot $item.CardPath
      Assert-CzxtEqual $before.IdentityKey $after.IdentityKey `
        'seal post-check rollback did not restore the original object identity'
      Assert-CzxtEqual ([Convert]::ToBase64String($before.Bytes)) `
        ([Convert]::ToBase64String($after.Bytes)) `
        'seal post-check rollback did not restore the original bytes'
      $residue = @(Get-ChildItem -LiteralPath (Split-Path -Parent $item.CardPath) `
        -Force | Where-Object { $_.Name -like '.staging-replace-*' })
      Assert-CzxtEqual 0 $residue.Count `
        'seal post-check rollback left replacement residue'
    }

    Invoke-CzxtContract 'seal atomically fills only the explicit valid card seal line' {
      $beforeText = [IO.File]::ReadAllText($validItem.CardPath, $script:P4tUtf8NoBom)
      $otherBefore = [IO.File]::ReadAllBytes($otherItem.CardPath)
      $result = Invoke-CzxtPowerShell -ScriptPath $script:P4tSealPath -ScriptArguments @(
        '-Root', $validRoot, '-CardPath', $validItem.CardPath)
      Assert-ExitCode $result 0 'valid seal'
      $attestation = [regex]::Match($result.StdOut.Trim(),
        '\ASEALED borrow_id=(?<borrow>borrow-[^ ]+) identity_key=(?<identity>[0-9a-f]{8}:[0-9a-f]{8}:[0-9a-f]{8}) length=(?<length>[0-9]+) sha256=(?<sha>[0-9a-f]{64})\z')
      Assert-CzxtTrue $attestation.Success 'valid seal attestation shape'
      $afterText = [IO.File]::ReadAllText($validItem.CardPath, $script:P4tUtf8NoBom)
      $match = [regex]::Match($afterText, '(?m)^closure_seal_sha256: ([0-9a-f]{64})$')
      Assert-CzxtTrue $match.Success 'valid seal line was not filled'
      Assert-CzxtEqual (Get-P4tClosureSealFromText $afterText) $match.Groups[1].Value `
        'valid seal digest'
      $blanked = [regex]::Replace($afterText, '(?m)^closure_seal_sha256: [0-9a-f]{64}$',
        'closure_seal_sha256: ""', 1)
      Assert-CzxtEqual $beforeText $blanked 'seal changed decoded content outside seal value'
      $installed = Get-BsiStableSnapshot $validItem.CardPath
      Assert-CzxtEqual $validItem.BorrowId $attestation.Groups['borrow'].Value `
        'valid seal attestation borrow_id'
      Assert-CzxtEqual $installed.IdentityKey $attestation.Groups['identity'].Value `
        'valid seal attestation identity'
      Assert-CzxtEqual ([string]$installed.Length) $attestation.Groups['length'].Value `
        'valid seal attestation length'
      Assert-CzxtEqual (Get-BorrowingSha256Hex -Bytes $installed.Bytes) `
        $attestation.Groups['sha'].Value 'valid seal attestation hash'
      Assert-CzxtEqual ([Convert]::ToBase64String($otherBefore)) `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes($otherItem.CardPath))) `
        'seal changed a non-target card'
      $residue = @(Get-ChildItem -LiteralPath (Split-Path -Parent $validItem.CardPath) -Force |
        Where-Object { $_.Name -match '\.(?:tmp|temp)$|^\.staging-' })
      Assert-CzxtEqual 0 $residue.Count 'seal left transaction residue'
    }

    Invoke-CzxtContract 'freshly sealed card passes the read-only item helper' {
      Import-P4tHelper 'borrowing-item-cards.ps1' 'Invoke-BorrowingP4tItemCheck'
      $state = New-P4tSourceState @($validSource)
      $before = Get-P4tTreeState $validRoot
      $result = Invoke-BorrowingP4tItemCheck $validRoot $state
      Assert-P4tResult $result 0 'freshly sealed card'
      Assert-P4tTreeUnchanged $before (Get-P4tTreeState $validRoot) 'item helper read-only after seal'
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
