$ErrorActionPreference = 'Stop'

function global:Set-BorrowingContextSeal {
  param($Context, [string]$Name, $Seal)
  $Context | Add-Member -NotePropertyName $Name -NotePropertyValue $Seal -Force
  return $Seal
}

function global:Close-BorrowingContextSeal {
  param($Context, [string]$Name)
  if ($null -eq $Context -or $null -eq $Context.PSObject.Properties[$Name]) {
    return
  }
  $seal = $Context.$Name
  if ($null -ne $seal) { Close-BorrowingOwnedTreeSeal $seal }
  $Context.$Name = $null
}

function global:Close-BorrowingContextTreeSeals {
  param($Context)
  foreach ($name in @('StagingSeal', 'CaptureSeal', 'ExistingSeal')) {
    try { Close-BorrowingContextSeal $Context $name } catch { }
  }
}

function global:New-BorrowingContextStagingSeal {
  param($Context, [string]$Stage = 'candidate',
    [string]$ReasonCode = 'candidate-invalid')
  Close-BorrowingContextSeal $Context StagingSeal
  $seal = New-BorrowingOwnedTreeSeal $Context.Ownership `
    $Context.StagingPath $Stage $ReasonCode
  return Set-BorrowingContextSeal $Context StagingSeal $seal
}

function global:New-BorrowingContextCaptureSeal {
  param($Context)
  Close-BorrowingContextSeal $Context CaptureSeal
  $seal = New-BorrowingOwnedTreeSeal $Context.Ownership `
    $Context.CapturePath promotion source-unsafe `
    $Context.Ownership.StagingLease
  return Set-BorrowingContextSeal $Context CaptureSeal $seal
}

function global:New-BorrowingContextExistingSeal {
  param($Context)
  Close-BorrowingContextSeal $Context ExistingSeal
  if ($null -eq $Context.ExistingLease) {
    Throw-BorrowingFailure idempotency idempotency-conflict `
      'existing capture tree lease is missing'
  }
  $seal = New-BorrowingOwnedTreeSeal $Context.Ownership `
    $Context.CapturePath idempotency idempotency-conflict `
    $Context.ExistingLease
  return Set-BorrowingContextSeal $Context ExistingSeal $seal
}

function global:Assert-BorrowingContextSeal {
  param($Context, [string]$Name, [string]$Stage, [string]$ReasonCode)
  $seal = if ($null -ne $Context.PSObject.Properties[$Name]) {
    $Context.$Name
  } else { $null }
  if ($null -eq $seal) {
    Throw-BorrowingFailure $Stage $ReasonCode `
      ('transaction tree seal is missing: ' + $Name)
  }
  Assert-BorrowingOwnedTreeSeal $seal
}

function global:Assert-BorrowingGateTreeSeals {
  param($Context, [string]$Gate)
  if ($Gate -ceq 'p4t-before') {
    Assert-BorrowingContextSeal $Context StagingSeal candidate candidate-invalid
    if ($Context.Disposition -ceq 'HealthyReuse') {
      Assert-BorrowingContextSeal $Context ExistingSeal `
        idempotency idempotency-conflict
    }
    return
  }
  if ($Context.Disposition -ceq 'New') {
    Assert-BorrowingContextSeal $Context CaptureSeal promotion source-unsafe
  }
  elseif ($Context.Disposition -ceq 'RepairMissingCache') {
    Assert-BorrowingContextSeal $Context ExistingSeal `
      idempotency idempotency-conflict
  }
}

function global:Assert-BorrowingOwnedPromotedContent {
  param($Context)
  $ownership = $Context.Ownership
  if ($null -eq $ownership -or $null -eq $ownership.StagingLease -or
      $null -eq $ownership.StagingLease.Native) {
    Throw-BorrowingFailure promotion source-unsafe `
      'promoted owned root lease is missing'
  }
  try { $ownership.StagingLease.Native.Verify() }
  catch {
    Throw-BorrowingFailure promotion source-unsafe `
      'promoted owned root lease changed'
  }
  foreach ($owned in @($ownership.DirectoryLeases.Values)) {
    if ((Get-BorrowingPathRelation $Context.CapturePath $owned.Path) -ne `
        'ancestor') { continue }
    $safe = Get-BorrowingSafePathInfo $owned.Path Directory promotion source-unsafe
    if ($safe.IdentityKey -cne $owned.IdentityKey) {
      Throw-BorrowingFailure promotion source-unsafe `
        'promoted owned directory changed'
    }
  }
  foreach ($owned in @($ownership.FileLeases.Values)) {
    if ((Get-BorrowingPathRelation $Context.CapturePath $owned.Path) -ne `
        'ancestor') { continue }
    [void](Get-BorrowingOwnedFileBytes $ownership $owned.Path `
        promotion source-unsafe)
  }
}

function global:Invoke-BorrowingFinalBoundTreeCheck {
  param($Context)
  if ($Context.Disposition -ceq 'New') {
    Assert-BorrowingContextSeal $Context CaptureSeal promotion source-unsafe
    Assert-BorrowingPromotedPathIdentity $Context
    return
  }
  Assert-BorrowingContextSeal $Context ExistingSeal `
    idempotency idempotency-conflict
  [void](Assert-BorrowingExistingCandidateState $Context Healthy)
}

function global:Assert-BorrowingMovedTreeSealLedger {
  param($BeforeMove, $AfterMove)
  if ($null -eq $BeforeMove -or $null -eq $AfterMove -or
      $BeforeMove.RootIdentityKey -cne $AfterMove.RootIdentityKey -or
      $BeforeMove.Directories.Count -ne $AfterMove.Directories.Count -or
      $BeforeMove.Files.Count -ne $AfterMove.Files.Count) {
    Throw-BorrowingFailure promotion source-unsafe `
      'promoted tree seal ledger changed'
  }
  foreach ($key in @($BeforeMove.Directories.Keys)) {
    if (-not $AfterMove.Directories.ContainsKey($key) -or
        $BeforeMove.Directories[$key].IdentityKey -cne
          $AfterMove.Directories[$key].IdentityKey) {
      Throw-BorrowingFailure promotion source-unsafe `
        'promoted directory seal ledger changed'
    }
  }
  foreach ($key in @($BeforeMove.Files.Keys)) {
    if (-not $AfterMove.Files.ContainsKey($key)) {
      Throw-BorrowingFailure promotion source-unsafe `
        'promoted file seal ledger changed'
    }
    $before = $BeforeMove.Files[$key]
    $after = $AfterMove.Files[$key]
    if ($before.IdentityKey -cne $after.IdentityKey -or
        [uint64]$before.Length -ne [uint64]$after.Length -or
        $before.Sha256 -cne $after.Sha256) {
      Throw-BorrowingFailure promotion source-unsafe `
        'promoted file seal content changed'
    }
  }
}

function global:Open-BorrowingNewCaptureTreeSeal {
  param($Context, $BeforeMoveSeal = $null)
  $afterMove = New-BorrowingContextCaptureSeal $Context
  Assert-BorrowingContextSeal $Context CaptureSeal promotion source-unsafe
  if ($null -ne $BeforeMoveSeal) {
    Assert-BorrowingMovedTreeSealLedger $BeforeMoveSeal $afterMove
  }
}

function global:Refresh-BorrowingExistingTreeSeal {
  param($Context)
  Close-BorrowingContextSeal $Context ExistingSeal
  [void](New-BorrowingContextExistingSeal $Context)
}

function global:Refresh-BorrowingRepairTreeSeals {
  param($Context)
  Refresh-BorrowingExistingTreeSeal $Context
  [void](New-BorrowingContextStagingSeal $Context cleanup cleanup-failed)
}

function global:Prepare-BorrowingRollbackTreeSeals {
  param($Context)
  Close-BorrowingContextSeal $Context StagingSeal
  Close-BorrowingContextSeal $Context CaptureSeal
  Close-BorrowingContextSeal $Context ExistingSeal
}

function global:Open-BorrowingTrackedDirectoryState {
  param($Owned, [string]$Stage, [string]$ReasonCode)
  if ($null -eq $Owned) {
    Throw-BorrowingFailure $Stage $ReasonCode `
      'tracked owned directory state is missing'
  }
  if ($null -ne $Owned.Native) {
    try { $Owned.Native.Verify(); return $Owned }
    catch {
      Throw-BorrowingFailure $Stage $ReasonCode `
        'tracked owned directory lease changed'
    }
  }
  $reopened = Open-BorrowingOwnedDirectoryState $Owned.Path $Stage `
    $ReasonCode $Owned.IdentityKey
  $Owned.Path = $reopened.Path
  $Owned.CanonicalPath = $reopened.CanonicalPath
  $Owned.IdentityKey = $reopened.IdentityKey
  $Owned.Native = $reopened.Native
  $reopened.Native = $null
  return $Owned
}

function global:Refresh-BorrowingRollbackTreeSeals {
  param($Context)
  [void](New-BorrowingContextStagingSeal $Context rollback rollback-failed)
  if ($Context.Disposition -ceq 'RepairMissingCache') {
    [void](New-BorrowingContextExistingSeal $Context)
  }
}

function global:Remove-BorrowingContextStagingTreeSeal {
  param($Context)
  Assert-BorrowingContextSeal $Context StagingSeal cleanup cleanup-failed
  $seal = $Context.StagingSeal
  Remove-BorrowingOwnedTreeSeal $seal
  $Context.StagingSeal = $null
}
