[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

function New-BorrowingTransactionSafetyContext {
  param([string]$Name, [string]$Disposition)
  $root = New-BorrowingFixtureRoot ('transaction-safety-' + $Name) project
  $ownership = New-BorrowingStagingDirectory ([pscustomobject]@{
      Root = $root; Request = [pscustomobject]@{ SourceId = 'web-source' }
    })
  $sourcePath = $ownership.SourcePath
  $stagingPath = $ownership.StagingPath
  $candidateOperations = New-BorrowingOwnedCandidateOperations $null $ownership
  $createDirectory = $candidateOperations.CreateDirectory
  $writeBytes = $candidateOperations.WriteAllBytes
  & $createDirectory (Join-Path $stagingPath '快照')
  [byte[]]$cardBytes = [Text.Encoding]::UTF8.GetBytes("candidate`n")
  [byte[]]$stateBytes = [Text.Encoding]::UTF8.GetBytes("{}`n")
  & $writeBytes (Join-Path $stagingPath '来源版本卡.md') $cardBytes
  & $writeBytes (Join-Path $stagingPath 'capture.local.json') $stateBytes
  & $writeBytes (Join-Path $stagingPath '快照\response.bin') ([byte[]](1))
  & $writeBytes (Join-Path $stagingPath '快照\response.metadata.json') `
    ([Text.Encoding]::UTF8.GetBytes("{}`n"))
  Close-BorrowingOwnedDescendantFiles $ownership $stagingPath
  $sourceInfo = Get-BorrowingSafePathInfo $sourcePath Directory candidate candidate-invalid
  $stagingInfo = Get-BorrowingSafePathInfo $stagingPath Directory candidate candidate-invalid
  $capturePath = Join-Path $sourcePath 'web-20260719-aaaaaaaaaaaa'
  $existingIdentityKey = 'none'
  $existingCandidate = $null
  $existingLease = $null
  if ($Disposition -in @('HealthyReuse', 'RepairMissingCache')) {
    [void](New-Item -ItemType Directory -Path $capturePath -Force)
    Write-BorrowingFixtureBytes (Join-Path $capturePath '来源版本卡.md') $cardBytes
    $existingIdentityKey = (Get-BorrowingSafePathInfo $capturePath Directory `
        candidate candidate-invalid).IdentityKey
    $existingCandidate = [pscustomobject]@{
      SourceId = 'web-source'; SourceType = 'web'
      CaptureId = 'web-20260719-aaaaaaaaaaaa'; CaptureStatus = 'ready'
      FingerprintAlgorithm = 'sha256-raw-bytes-v1'; Fingerprint = ('a' * 64)
      StableIdentitySha256 = ('b' * 64)
      CardPath = (Join-Path $capturePath '来源版本卡.md')
    }
    $existingLease = Open-BorrowingOwnedExistingCapture `
      $capturePath $existingIdentityKey
  }
  $script:TransactionSafetyExistingCacheState = if ($Disposition -ceq `
      'RepairMissingCache') { 'AllMissing' } else { 'Healthy' }
  $script:TransactionSafetyCandidate = [pscustomobject]@{
    SourceId = 'web-source'; SourceType = 'web'
    CaptureId = 'web-20260719-aaaaaaaaaaaa'; CaptureStatus = 'ready'
    FingerprintAlgorithm = 'sha256-raw-bytes-v1'; Fingerprint = ('a' * 64)
    StableIdentitySha256 = ('b' * 64); CardBytes = $cardBytes
    CardPath = (Join-Path $stagingPath '来源版本卡.md')
  }
  $stagingSeal = New-BorrowingOwnedTreeSeal $ownership $stagingPath `
    candidate candidate-invalid
  $existingSeal = if ($null -ne $existingLease) {
    New-BorrowingOwnedTreeSeal $ownership $capturePath `
      idempotency idempotency-conflict $existingLease
  } else { $null }
  $context = [pscustomobject]@{
    Root = $root; SourceType = 'web'; SourcePath = $sourcePath
    StagingPath = $stagingPath; CapturePath = $capturePath
    Disposition = $Disposition; SourceIdentityKey = $sourceInfo.IdentityKey
    StagingIdentityKey = $stagingInfo.IdentityKey
    ExistingIdentityKey = $existingIdentityKey
    Prepared = [pscustomobject]@{}
    Candidate = [pscustomobject]@{ Fingerprint = ('a' * 64) }
    Artifact = [pscustomobject]@{
      CaptureId = 'web-20260719-aaaaaaaaaaaa'
      StableIdentitySha256 = ('b' * 64); Bytes = $cardBytes
    }
    LocalStateBytes = $stateBytes
    ExistingCandidate = $existingCandidate
    ExistingLease = $existingLease; Ownership = $ownership
    CandidateOperations = $candidateOperations
    StagingSeal = $stagingSeal; CaptureSeal = $null
    ExistingSeal = $existingSeal
  }
  [void]$script:TransactionSafetyContexts.Add($context)
  return $context
}

function Assert-BorrowingOperationFailure {
  param([scriptblock]$Body, [string]$Stage, [string]$ReasonCode, [string]$Label)
  $caught = $null
  try { & $Body }
  catch { $caught = $_.Exception }
  Assert-CzxtTrue ($null -ne $caught) ($Label + ' expected failure')
  Assert-CzxtEqual $Stage ([string]$caught.Data['BorrowingStage']) ($Label + ' stage')
  Assert-CzxtEqual $ReasonCode ([string]$caught.Data['BorrowingReasonCode']) `
    ($Label + ' reason')
}

Initialize-BorrowingCaptureFixture
$script:TransactionSafetyContexts = New-Object 'Collections.Generic.List[object]'
try {
  Invoke-CzxtContract 'production transaction safety operations are available' {
    Import-BorrowingCaptureModules @('common', 'file-safety', 'transaction', 'orchestrator')
    Assert-BorrowingCommandExists 'New-BorrowingProductionTransactionOperations'
  }
  function global:Get-BorrowingValidatedSourceCandidate {
    param([string]$CaptureDirectory)
    $candidate = $script:TransactionSafetyCandidate.PSObject.Copy()
    $candidate.CardPath = Join-Path $CaptureDirectory '来源版本卡.md'
    if (Test-Path -LiteralPath $candidate.CardPath -PathType Leaf) {
      $candidate.CardBytes = Read-BorrowingStableSafeFileBytes `
        $candidate.CardPath candidate candidate-invalid
    }
    return $candidate
  }
  function global:Get-BorrowingIgnoredCacheState {
    param([string]$CaptureDirectory, [string]$SourceType)
    if ([IO.Path]::GetFileName($CaptureDirectory).StartsWith('.staging-', `
        [StringComparison]::Ordinal)) {
      return [pscustomobject]@{ State = 'Healthy' }
    }
    return [pscustomobject]@{ State = $script:TransactionSafetyExistingCacheState }
  }
  function global:Test-BorrowingStoredCaptureFingerprint {
    param($Candidate)
    return [pscustomobject]@{ Applicable = $false; IsValid = $true }
  }

  Invoke-CzxtContract 'staging creation retains a bound lease across the write window' {
    $root = New-BorrowingFixtureRoot staging-retained-lease project
    $staging = New-BorrowingStagingDirectory ([pscustomobject]@{
        Root = $root
        Request = [pscustomobject]@{ SourceId = 'web-source' }
      })
    try {
      Assert-CzxtTrue ($null -ne $staging.StagingLease) `
        'staging creation must return its retained lease'
      Assert-CzxtTrue ($null -ne $staging.SourceLease) `
        'staging creation must retain its source parent lease'
      $replacement = $staging.StagingPath + '.original'
      $blocked = $false
      try { [IO.Directory]::Move($staging.StagingPath, $replacement) }
      catch { $blocked = $true }
      Assert-CzxtTrue $blocked `
        'retained staging lease must block path replacement before writes'
      $actual = Get-BorrowingSafePathInfo $staging.StagingPath Directory `
        capture source-unsafe
      Assert-CzxtEqual $staging.StagingIdentityKey $actual.IdentityKey `
        'retained staging identity'
    }
    finally {
      if ($null -ne (Get-Command Close-BorrowingOwnedStagingLeases `
          -CommandType Function -ErrorAction SilentlyContinue)) {
        Close-BorrowingOwnedStagingLeases $staging
      }
      if (Test-Path -LiteralPath $staging.StagingPath) {
        Remove-Item -LiteralPath $staging.StagingPath -Recurse -Force
      }
    }
  }

  Invoke-CzxtContract 'atomic move blocks a staging replacement in the validated window' {
    $context = New-BorrowingTransactionSafetyContext move-window New
    $script:TransactionSafetyMoveBlocked = $false
    $script:BorrowingOrchestratorTestInjections = @{
      'after-staged-candidate-validated-before-move' = {
        param($ctx)
        try { [IO.Directory]::Move($ctx.StagingPath, $ctx.StagingPath + '.attacker') }
        catch { $script:TransactionSafetyMoveBlocked = $true }
      }
    }
    $operations = New-BorrowingProductionTransactionOperations $context
    $move = $operations.AtomicMove
    try { & $move $context }
    finally { $script:BorrowingOrchestratorTestInjections = $null }
    Assert-CzxtTrue $script:TransactionSafetyMoveBlocked `
      'retained root lease did not block the validated-window replacement'
    Assert-CzxtTrue (Test-Path -LiteralPath $context.CapturePath -PathType Container) `
      'owned staging was not promoted after the blocked replacement'
    Assert-CzxtEqual $context.StagingIdentityKey `
      (Get-BorrowingSafePathInfo $context.CapturePath Directory `
        promotion source-unsafe).IdentityKey 'promoted root identity'
  }

  Invoke-CzxtContract 'atomic move rejects a member added after the final staging seal' {
    $context = New-BorrowingTransactionSafetyContext move-late-member New
    $unknownPath = Join-Path $context.StagingPath 'late-move-unknown.bin'
    $script:TransactionSafetyLateMoveInjectionRan = $false
    $script:BorrowingOrchestratorTestInjections = @{
      'after-staging-seal-closed-before-move' = {
        param($ctx)
        [IO.File]::WriteAllBytes((Join-Path $ctx.StagingPath `
            'late-move-unknown.bin'), ([byte[]](4, 5, 6)))
        $script:TransactionSafetyLateMoveInjectionRan = $true
      }
    }
    $operations = New-BorrowingProductionTransactionOperations $context
    $move = $operations.AtomicMove
    $caught = $null
    try { & $move $context }
    catch { $caught = $_.Exception }
    finally { $script:BorrowingOrchestratorTestInjections = $null }
    if (Test-Path -LiteralPath $context.CapturePath -PathType Container) {
      $rollback = $operations.Rollback
      & $rollback $context
    }
    Assert-CzxtTrue ([bool]$script:TransactionSafetyLateMoveInjectionRan) `
      'late move member injection did not run'
    Assert-CzxtTrue ($null -ne $caught) `
      'late move member was accepted into the promoted capture'
    Assert-CzxtEqual 'promotion' ([string]$caught.Data['BorrowingStage']) `
      'late move member failure stage'
    Assert-CzxtEqual 'source-unsafe' `
      ([string]$caught.Data['BorrowingReasonCode']) `
      'late move member failure reason'
    Assert-CzxtTrue (Test-Path -LiteralPath $unknownPath -PathType Leaf) `
      'late move unknown member was not retained in staging after rollback'
    Assert-CzxtEqual $false (Test-Path -LiteralPath $context.CapturePath) `
      'late move member left a promoted capture behind'
  }

  Invoke-CzxtContract 'cleanup preserves staging when an unknown member appears' {
    $context = New-BorrowingTransactionSafetyContext cleanup-unknown HealthyReuse
    Write-BorrowingFixtureBytes (Join-Path $context.StagingPath 'unknown.bin') ([byte[]](9))
    $operations = New-BorrowingProductionTransactionOperations $context
    $cleanup = $operations.Cleanup
    Assert-BorrowingOperationFailure { & $cleanup $context } cleanup cleanup-failed `
      'unknown cleanup member'
    Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
      'unsafe staging must be retained'
    Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $context.StagingPath 'unknown.bin')) `
      'unknown member must be retained'
  }

  Invoke-CzxtContract 'cleanup preserves an unknown member inserted after validation' {
    $context = New-BorrowingTransactionSafetyContext cleanup-late-unknown HealthyReuse
    $unknownPath = Join-Path $context.StagingPath 'late-unknown.bin'
    $script:BorrowingOrchestratorTestInjections = @{
      'after-staging-cleanup-validated-before-delete' = {
        param($ctx)
        [IO.File]::WriteAllBytes((Join-Path $ctx.StagingPath `
            'late-unknown.bin'), ([byte[]](7, 8, 9)))
      }
    }
    $operations = New-BorrowingProductionTransactionOperations $context
    $cleanup = $operations.Cleanup
    $caught = $null
    try { & $cleanup $context }
    catch { $caught = $_.Exception }
    finally { $script:BorrowingOrchestratorTestInjections = $null }
    Assert-CzxtTrue ($null -ne $caught) `
      'late unknown cleanup member must fail closed'
    Assert-CzxtTrue (Test-Path -LiteralPath $unknownPath -PathType Leaf) `
      'late unknown cleanup member must be retained'
    Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
      'staging root must remain after a late unknown cleanup member'
  }

  Invoke-CzxtContract 'healthy reuse keeps the existing capture bound through cleanup' {
    $context = New-BorrowingTransactionSafetyContext existing-window HealthyReuse
    $script:TransactionSafetyExistingBlocked = $false
    $script:BorrowingOrchestratorTestInjections = @{
      'after-staging-cleanup-validated-before-delete' = {
        param($ctx)
        try { [IO.Directory]::Move($ctx.CapturePath, $ctx.CapturePath + '.attacker') }
        catch { $script:TransactionSafetyExistingBlocked = $true }
      }
    }
    $operations = New-BorrowingProductionTransactionOperations $context
    $cleanup = $operations.Cleanup
    try { & $cleanup $context }
    finally { $script:BorrowingOrchestratorTestInjections = $null }
    Assert-CzxtTrue $script:TransactionSafetyExistingBlocked `
      'existing capture lease did not block cleanup-window replacement'
    Assert-CzxtTrue (Test-Path -LiteralPath $context.CapturePath -PathType Container) `
      'healthy existing capture changed during cleanup'
    Assert-CzxtEqual $false (Test-Path -LiteralPath $context.StagingPath) `
      'healthy reuse staging was not cleaned'
  }

  Invoke-CzxtContract 'cache repair keeps the existing capture bound while installing' {
    $context = New-BorrowingTransactionSafetyContext repair-window RepairMissingCache
    $script:TransactionSafetyRepairBlocked = $false
    $script:BorrowingOrchestratorTestInjections = @{
      'after-existing-repair-validated-before-install' = {
        param($ctx)
        try { [IO.Directory]::Move($ctx.CapturePath, $ctx.CapturePath + '.attacker') }
        catch { $script:TransactionSafetyRepairBlocked = $true }
      }
    }
    $operations = New-BorrowingProductionTransactionOperations $context
    $install = $operations.InstallMissingCache
    try { & $install $context }
    finally { $script:BorrowingOrchestratorTestInjections = $null }
    Assert-CzxtTrue $script:TransactionSafetyRepairBlocked `
      'existing capture lease did not block repair-window replacement'
    Assert-CzxtTrue (Test-Path -LiteralPath `
        (Join-Path $context.CapturePath '快照') -PathType Container) `
      'repair cache was not installed after the blocked replacement'
  }

  Invoke-CzxtContract 'cache repair seals the moved snapshot before state install' {
    $context = New-BorrowingTransactionSafetyContext repair-snapshot-window `
      RepairMissingCache
    $script:TransactionSafetySnapshotReplaceBlocked = $false
    $script:BorrowingOrchestratorTestInjections = @{
      'after-repair-snapshot-sealed-before-state-move' = {
        param($ctx)
        $path = Join-Path $ctx.CapturePath '快照\response.bin'
        try { [IO.File]::Delete($path) }
        catch { $script:TransactionSafetySnapshotReplaceBlocked = $true }
      }
    }
    $operations = New-BorrowingProductionTransactionOperations $context
    $install = $operations.InstallMissingCache
    try { & $install $context }
    finally { $script:BorrowingOrchestratorTestInjections = $null }
    Assert-CzxtTrue $script:TransactionSafetySnapshotReplaceBlocked `
      'moved snapshot was replaceable before state install'
    Assert-CzxtTrue (Test-Path -LiteralPath `
        (Join-Path $context.CapturePath '快照\response.bin') -PathType Leaf) `
      'snapshot protection changed the installed response bytes'
  }

  Invoke-CzxtContract 'cache repair rejects a same-byte source-card ABA replacement' {
    $context = New-BorrowingTransactionSafetyContext repair-card-aba `
      RepairMissingCache
    $cardPath = Join-Path $context.StagingPath '来源版本卡.md'
    $script:TransactionSafetyCardAbaRan = $false
    $script:BorrowingOrchestratorTestInjections = @{
      'after-repair-snapshot-sealed-before-state-move' = {
        param($ctx)
        $path = Join-Path $ctx.StagingPath '来源版本卡.md'
        [IO.File]::Delete($path)
        [IO.File]::WriteAllBytes($path, ([byte[]]$ctx.Artifact.Bytes))
        $script:TransactionSafetyCardAbaRan = $true
      }
    }
    $operations = New-BorrowingProductionTransactionOperations $context
    $install = $operations.InstallMissingCache
    try { & $install $context }
    finally { $script:BorrowingOrchestratorTestInjections = $null }
    $script:TransactionSafetyExistingCacheState = 'Healthy'
    $cleanup = $operations.Cleanup
    $caught = $null
    try { & $cleanup $context }
    catch { $caught = $_.Exception }
    Assert-CzxtTrue ([bool]$script:TransactionSafetyCardAbaRan) `
      'same-byte source-card ABA injection did not run'
    Assert-CzxtTrue ($null -ne $caught) `
      'same-byte source-card ABA replacement was accepted for cleanup'
    Assert-CzxtEqual 'cleanup' ([string]$caught.Data['BorrowingStage']) `
      'source-card ABA cleanup stage'
    Assert-CzxtEqual 'cleanup-failed' `
      ([string]$caught.Data['BorrowingReasonCode']) `
      'source-card ABA cleanup reason'
    Assert-CzxtTrue (Test-Path -LiteralPath $cardPath -PathType Leaf) `
      'same-byte replacement was deleted instead of retained'
  }

  Invoke-CzxtContract 'new rollback keeps the promoted root bound and moves the same object back' {
    $context = New-BorrowingTransactionSafetyContext rollback-bound New
    $operations = New-BorrowingProductionTransactionOperations $context
    $move = $operations.AtomicMove
    & $move $context
    $blocked = $false
    try { [IO.Directory]::Move($context.CapturePath, $context.CapturePath + '.attacker') }
    catch { $blocked = $true }
    $rollback = $operations.Rollback
    & $rollback $context
    Assert-CzxtTrue $blocked 'promoted root lease did not block replacement'
    Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
      'rollback did not restore the same staging root'
    Assert-CzxtEqual $false (Test-Path -LiteralPath $context.CapturePath) `
      'rollback left a promoted path behind'
  }

  Invoke-CzxtContract 'new move reconciles a committed rename before surfacing failure' {
    $context = New-BorrowingTransactionSafetyContext move-commit-reconcile New
    $script:BorrowingOwnedStagingTestInjections = @{
      'after-native-rename-before-state-update' = {
        param($state)
        if ($state.Kind -ceq 'directory') { throw 'injected post-rename failure' }
      }
    }
    $operations = New-BorrowingProductionTransactionOperations $context
    $move = $operations.AtomicMove
    $caught = $null
    try { & $move $context }
    catch { $caught = $_.Exception }
    finally { $script:BorrowingOwnedStagingTestInjections = $null }
    Assert-CzxtTrue ($null -ne $caught -and
      [bool]$caught.Data['BorrowingRenameCommitted']) `
      'committed new rename did not surface its commit state'
    Assert-CzxtEqual 'capture' $context.Ownership.State `
      'committed new rename left stale logical state'
    $probe = $operations.ProbePathState
    $state = & $probe $context
    Assert-CzxtTrue ($state.CaptureExists -and -not $state.StagingExists) `
      'committed new rename probe trusted stale paths'
    $rollback = $operations.Rollback
    & $rollback $context
  }

  Invoke-CzxtContract 'new rollback reconciles a committed reverse rename' {
    $context = New-BorrowingTransactionSafetyContext rollback-commit-reconcile New
    $operations = New-BorrowingProductionTransactionOperations $context
    $move = $operations.AtomicMove
    & $move $context
    $script:BorrowingOwnedStagingTestInjections = @{
      'after-native-rename-before-state-update' = {
        param($state)
        if ($state.Kind -ceq 'directory') { throw 'injected rollback commit failure' }
      }
    }
    $rollback = $operations.Rollback
    $caught = $null
    try { & $rollback $context }
    catch { $caught = $_.Exception }
    finally { $script:BorrowingOwnedStagingTestInjections = $null }
    Assert-CzxtTrue ($null -ne $caught -and
      [bool]$caught.Data['BorrowingRenameCommitted']) `
      'committed rollback rename did not surface its commit state'
    Assert-CzxtEqual 'staging' $context.Ownership.State `
      'committed rollback rename left stale logical state'
    Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
      'committed rollback did not restore staging path'
  }

  Invoke-CzxtContract 'repair rollback returns both bound cache objects to staging' {
    $context = New-BorrowingTransactionSafetyContext repair-rollback-bound `
      RepairMissingCache
    $operations = New-BorrowingProductionTransactionOperations $context
    $install = $operations.InstallMissingCache
    & $install $context
    $blocked = $false
    try { [IO.Directory]::Move($context.CapturePath, $context.CapturePath + '.attacker') }
    catch { $blocked = $true }
    $rollback = $operations.Rollback
    & $rollback $context
    Assert-CzxtTrue $blocked 'existing capture lease did not block replacement'
    Assert-CzxtTrue (Test-Path -LiteralPath $context.StagingPath -PathType Container) `
      'repair rollback staging missing'
    Assert-CzxtTrue (Test-Path -LiteralPath `
        (Join-Path $context.StagingPath '快照') -PathType Container) `
      'repair rollback snapshot missing'
    Assert-CzxtTrue (Test-Path -LiteralPath `
        (Join-Path $context.StagingPath 'capture.local.json') -PathType Leaf) `
      'repair rollback local state missing'
  }

  Invoke-CzxtContract 'repair install records a committed snapshot rename before rollback' {
    $context = New-BorrowingTransactionSafetyContext repair-commit-reconcile `
      RepairMissingCache
    $script:BorrowingOwnedStagingTestInjections = @{
      'after-native-rename-before-state-update' = {
        param($state)
        if ($state.Kind -ceq 'directory') { throw 'injected repair commit failure' }
      }
    }
    $operations = New-BorrowingProductionTransactionOperations $context
    $install = $operations.InstallMissingCache
    $caught = $null
    try { & $install $context }
    catch { $caught = $_.Exception }
    finally { $script:BorrowingOwnedStagingTestInjections = $null }
    Assert-CzxtTrue ($null -ne $caught -and
      [bool]$caught.Data['BorrowingRenameCommitted']) `
      'committed repair rename did not surface its commit state'
    Assert-CzxtTrue ([bool]$context.RepairSnapshotMoved) `
      'committed repair rename left its moved flag false'
    $rollback = $operations.Rollback
    & $rollback $context
    Assert-CzxtTrue (Test-Path -LiteralPath `
        (Join-Path $context.StagingPath '快照') -PathType Container) `
      'repair reconcile rollback did not restore snapshot'
  }

  Invoke-CzxtContract 'post-link validation retains the promoted root identity' {
    $context = New-BorrowingTransactionSafetyContext post-link-bound New
    $context.SourceType = 'fixture'
    $script:TransactionSafetyCandidate.SourceType = 'fixture'
    $operations = New-BorrowingProductionTransactionOperations $context
    $move = $operations.AtomicMove
    & $move $context
    $blocked = $false
    try { [IO.Directory]::Move($context.CapturePath, $context.CapturePath + '.attacker') }
    catch { $blocked = $true }
    $postLink = $operations.PostLinkCheck
    & $postLink $context
    Assert-CzxtTrue $blocked 'post-link root lease did not block replacement'
  }
}
finally {
  $script:BorrowingOrchestratorTestInjections = $null
  for ($index = 0; $index -lt $script:TransactionSafetyContexts.Count; $index++) {
    $context = $script:TransactionSafetyContexts[$index]
    try { Close-BorrowingContextTreeSeals $context } catch { }
    try { Close-BorrowingOwnedDirectoryState $context.ExistingLease } catch { }
    try { Close-BorrowingOwnedStagingLeases $context.Ownership } catch { }
  }
  Remove-BorrowingCaptureFixture
}

Complete-CzxtContracts
