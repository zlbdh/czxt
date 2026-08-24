$ErrorActionPreference = 'Stop'

$orchestratorOperationsRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
if (-not (Get-Command New-BorrowingContextStagingSeal -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $orchestratorOperationsRoot 'orchestrator-seals.ps1')
}

function global:Invoke-BorrowingOrchestratorTestInjection {
  param([string]$Name, $Context)
  if ($script:BorrowingOrchestratorTestInjections -is [Collections.IDictionary] -and
      $script:BorrowingOrchestratorTestInjections.Contains($Name)) {
    & $script:BorrowingOrchestratorTestInjections[$Name] $Context
  }
}

function global:Set-BorrowingContextProperty {
  param($Context, [string]$Name, $Value)
  $Context | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}

function global:Test-BorrowingCommittedRenameFailure {
  param($ErrorRecord)
  return $null -ne $ErrorRecord -and
    [bool]$ErrorRecord.Exception.Data['BorrowingRenameCommitted']
}

function global:New-BorrowingProductionTransactionOperations {
  param($Context)
  if ($null -eq $Context.Ownership -or
      $null -eq $Context.Ownership.StagingLease) {
    Throw-BorrowingFailure preflight missing-trusted-component `
      'owned transaction context is missing'
  }
  $operations = [pscustomobject]@{
    RunP4t = {
      param($ctx, [string]$Gate)
      Assert-BorrowingGateTreeSeals $ctx $Gate
      $result = Invoke-BorrowingP4tGateCore `
        -Spec $ctx.Prepared.P4tSpec -Stage $Gate
      Assert-BorrowingGateTreeSeals $ctx $Gate
      return $result
    }
    AtomicMove = {
      param($ctx)
      try { Assert-BorrowingContextStagedCandidate $ctx promotion source-unsafe }
      catch {
        if ($_.Exception.Data['BorrowingStage']) { throw }
        Throw-BorrowingFailure promotion source-unsafe `
          'staging pre-move check failed'
      }
      Invoke-BorrowingOrchestratorTestInjection `
        'after-staged-candidate-validated-before-move' $ctx
      Assert-BorrowingContextSeal $ctx StagingSeal promotion source-unsafe
      $beforeMoveSeal = $ctx.StagingSeal
      Close-BorrowingContextSeal $ctx StagingSeal
      Invoke-BorrowingOrchestratorTestInjection `
        'after-staging-seal-closed-before-move' $ctx
      try {
        [void](Move-BorrowingOwnedDirectoryTree $ctx.Ownership `
            $ctx.Ownership.StagingLease $ctx.Ownership.SourceLease `
            $ctx.Artifact.CaptureId promotion source-unsafe)
      }
      catch {
        if (Test-BorrowingCommittedRenameFailure $_) {
          $ctx.Ownership.State = 'capture'
          try { Open-BorrowingNewCaptureTreeSeal $ctx $beforeMoveSeal } catch { }
        }
        throw
      }
      $ctx.Ownership.State = 'capture'
      Open-BorrowingNewCaptureTreeSeal $ctx $beforeMoveSeal
    }
    InstallMissingCache = {
      param($ctx)
      Assert-BorrowingContextSeal $ctx StagingSeal `
        idempotency idempotency-conflict
      Assert-BorrowingContextSeal $ctx ExistingSeal `
        idempotency idempotency-conflict
      Assert-BorrowingContextStagedCandidate $ctx idempotency idempotency-conflict
      [void](Assert-BorrowingExistingCandidateState $ctx AllMissing)
      Invoke-BorrowingOrchestratorTestInjection `
        'after-existing-repair-validated-before-install' $ctx
      Close-BorrowingContextSeal $ctx StagingSeal
      $snapshot = Find-BorrowingOwnedDirectoryState $ctx.Ownership `
        (Join-Path $ctx.Ownership.StagingLease.Path '快照')
      [void](Open-BorrowingTrackedDirectoryState $snapshot `
          promotion source-unsafe)
      try {
        [void](Move-BorrowingOwnedDirectoryTree $ctx.Ownership $snapshot `
            $ctx.ExistingLease '快照' promotion source-unsafe)
      }
      catch {
        if (Test-BorrowingCommittedRenameFailure $_) {
          Set-BorrowingContextProperty $ctx RepairSnapshot $snapshot
          Set-BorrowingContextProperty $ctx RepairSnapshotMoved $true
        }
        throw
      }
      Set-BorrowingContextProperty $ctx RepairSnapshot $snapshot
      Set-BorrowingContextProperty $ctx RepairSnapshotMoved $true
      Refresh-BorrowingExistingTreeSeal $ctx
      Invoke-BorrowingOrchestratorTestInjection `
        'after-repair-snapshot-sealed-before-state-move' $ctx
      $state = Get-BorrowingOwnedDirectChildFile $ctx.Ownership `
        'capture.local.json' promotion source-unsafe
      [void](Open-BorrowingOwnedFileState $state promotion source-unsafe)
      try {
        [void](Move-BorrowingOwnedFileState $state $ctx.ExistingLease `
            'capture.local.json' promotion source-unsafe $ctx.Ownership)
      }
      catch {
        if (Test-BorrowingCommittedRenameFailure $_) {
          Set-BorrowingContextProperty $ctx RepairStateFile $state
          Set-BorrowingContextProperty $ctx RepairStateMoved $true
        }
        throw
      }
      Set-BorrowingContextProperty $ctx RepairStateFile $state
      Set-BorrowingContextProperty $ctx RepairStateMoved $true
      $ctx.Ownership.State = 'repair-installed'
      Refresh-BorrowingRepairTreeSeals $ctx
    }
    PostLinkCheck = {
      param($ctx)
      if ($ctx.Disposition -ceq 'New') {
        Assert-BorrowingContextSeal $ctx CaptureSeal promotion source-unsafe
      }
      else {
        Assert-BorrowingContextSeal $ctx ExistingSeal `
          idempotency idempotency-conflict
      }
      Assert-BorrowingPromotedPathIdentity $ctx
      Assert-BorrowingOwnedPromotedContent $ctx
      $validated = Get-BorrowingValidatedSourceCandidate `
        -CaptureDirectory $ctx.CapturePath
      if ($validated.StableIdentitySha256 -cne $ctx.Artifact.StableIdentitySha256 -or
          $validated.Fingerprint -cne $ctx.Candidate.Fingerprint -or
          -not (Test-BorrowingValidatedFingerprint $validated)) {
        Throw-BorrowingFailure promotion source-unsafe `
          'promoted source candidate differs'
      }
      switch ($ctx.SourceType) {
        'local' {
          Test-BorrowingLocalPromotedContent -Candidate $ctx.Candidate `
            -CapturePath $ctx.CapturePath -Operations $ctx.Prepared.Operations | Out-Null
        }
        'web' { Test-BorrowingPostMoveWebCache $ctx }
        'git' { Test-BorrowingPostMoveGitCache $ctx }
      }
    }
    Rollback = {
      param($ctx)
      Assert-BorrowingRollbackPathIdentities $ctx
      Prepare-BorrowingRollbackTreeSeals $ctx
      if ($ctx.Disposition -eq 'New') {
        try {
          [void](Move-BorrowingOwnedDirectoryTree $ctx.Ownership `
              $ctx.Ownership.StagingLease $ctx.Ownership.SourceLease `
              ([IO.Path]::GetFileName($ctx.StagingPath)) rollback rollback-failed)
        }
        catch {
          if (Test-BorrowingCommittedRenameFailure $_) {
            $ctx.Ownership.State = 'staging'
            try { Refresh-BorrowingRollbackTreeSeals $ctx } catch { }
          }
          throw
        }
        $ctx.Ownership.State = 'staging'
        Refresh-BorrowingRollbackTreeSeals $ctx
      }
      elseif ($ctx.Disposition -eq 'RepairMissingCache') {
        if ([bool]$ctx.RepairStateMoved) {
          [void](Open-BorrowingOwnedFileState $ctx.RepairStateFile `
              rollback rollback-failed)
          try {
            [void](Move-BorrowingOwnedFileState $ctx.RepairStateFile `
                $ctx.Ownership.StagingLease 'capture.local.json' `
                rollback rollback-failed $ctx.Ownership)
          }
          catch {
            if (Test-BorrowingCommittedRenameFailure $_) {
              $ctx.RepairStateMoved = $false
            }
            throw
          }
          $ctx.RepairStateMoved = $false
        }
        if ([bool]$ctx.RepairSnapshotMoved) {
          [void](Open-BorrowingTrackedDirectoryState $ctx.RepairSnapshot `
              rollback rollback-failed)
          try {
            [void](Move-BorrowingOwnedDirectoryTree $ctx.Ownership `
                $ctx.RepairSnapshot $ctx.Ownership.StagingLease '快照' `
                rollback rollback-failed)
          }
          catch {
            if (Test-BorrowingCommittedRenameFailure $_) {
              $ctx.RepairSnapshotMoved = $false
            }
            throw
          }
          $ctx.RepairSnapshotMoved = $false
        }
        $ctx.Ownership.State = 'staging'
        Refresh-BorrowingRollbackTreeSeals $ctx
      }
    }
    Cleanup = {
      param($ctx)
      $name = [IO.Path]::GetFileName($ctx.StagingPath)
      if (-not $name.StartsWith('.staging-', [StringComparison]::Ordinal) -or
          (Get-BorrowingPathRelation $ctx.SourcePath $ctx.StagingPath) -cne `
            'ancestor') {
        Throw-BorrowingFailure cleanup cleanup-failed `
          'staging cleanup boundary failed'
      }
      if ($ctx.Ownership.State -ne 'cleaned') {
        try {
          Assert-BorrowingContextSeal $ctx StagingSeal cleanup cleanup-failed
          if ($ctx.Disposition -ceq 'RepairMissingCache') {
            [void](Assert-BorrowingExistingCandidateState $ctx Healthy)
            Assert-BorrowingRepairCleanupStaging $ctx
          }
          else {
            [void](Assert-BorrowingExistingCandidateState $ctx Healthy)
            Assert-BorrowingContextStagedCandidate $ctx cleanup cleanup-failed
          }
          Invoke-BorrowingOrchestratorTestInjection `
            'after-staging-cleanup-validated-before-delete' $ctx
          Remove-BorrowingContextStagingTreeSeal $ctx
          $ctx.Ownership.State = 'cleaned'
        }
        catch {
          if ($_.Exception.Data['BorrowingStage'] -in @('cleanup', 'idempotency')) {
            throw
          }
          Throw-BorrowingFailure cleanup cleanup-failed `
            'staging cleanup validation failed'
        }
      }
    }
    FinalCheck = {
      param($ctx)
      Invoke-BorrowingFinalBoundTreeCheck $ctx
    }
    ProbePathState = {
      param($ctx)
      $oldRootPath = [string]$ctx.Ownership.StagingLease.Path
      try {
        $ctx.Ownership.StagingLease.Native.RefreshFromHandle()
        $liveRootPath = ConvertFrom-BorrowingOwnedNativePath `
          $ctx.Ownership.StagingLease.Native.FinalPath promotion source-unsafe
        if (-not (Test-BorrowingOwnedSamePath $oldRootPath $liveRootPath)) {
          $ctx.Ownership.StagingLease.Path = $liveRootPath
          $ctx.Ownership.StagingLease.CanonicalPath = $liveRootPath
          Update-BorrowingOwnedPathPrefix $ctx.Ownership $oldRootPath $liveRootPath
        }
      }
      catch { }
      if ($null -ne $ctx.ExistingLease -and $null -ne $ctx.ExistingLease.Native) {
        try {
          $ctx.ExistingLease.Native.RefreshFromHandle()
          $liveExistingPath = ConvertFrom-BorrowingOwnedNativePath `
            $ctx.ExistingLease.Native.FinalPath idempotency idempotency-conflict
          $ctx.ExistingLease.Path = $liveExistingPath
          $ctx.ExistingLease.CanonicalPath = $liveExistingPath
        }
        catch { }
      }
      $rootPath = [string]$ctx.Ownership.StagingLease.Path
      [pscustomobject]@{
        CaptureExists = if ($ctx.Disposition -eq 'New') {
          Test-BorrowingOwnedSamePath $rootPath $ctx.CapturePath
        } else {
          $null -ne $ctx.ExistingLease -and
            (Test-BorrowingOwnedSamePath $ctx.ExistingLease.Path $ctx.CapturePath)
        }
        StagingExists = $ctx.Ownership.State -ne 'cleaned' -and
          (Test-BorrowingOwnedSamePath $rootPath $ctx.StagingPath)
      }
    }
  }
  return $operations
}
