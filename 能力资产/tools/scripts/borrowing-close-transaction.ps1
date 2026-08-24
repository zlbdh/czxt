$ErrorActionPreference = 'Stop'

$closeStagingPath = Join-Path $PSScriptRoot 'borrowing-close-staging.ps1'
if (-not (Test-Path -LiteralPath $closeStagingPath -PathType Leaf)) {
  throw 'close 缺少 staging 生命周期 helper'
}
. $closeStagingPath

function New-BctResult {
  param(
    [int]$ExitCode, [string]$Result, [string]$Stage,
    [string]$BorrowId, [string]$CardPath, [string]$StagingPath,
    [string]$P4t, [string]$ReasonCode
  )
  return [pscustomobject][ordered]@{
    ExitCode = $ExitCode; Result = $Result; Stage = $Stage
    BorrowId = $BorrowId; CardPath = $CardPath; StagingPath = $StagingPath
    P4t = $P4t; ReasonCode = $ReasonCode
  }
}

function Install-BctFormalBytes {
  param([string]$FormalPath, [byte[]]$Bytes, $ExpectedSnapshot)
  Assert-BciCondition ($null -ne $ExpectedSnapshot) '正式事项卡缺少替换前快照'
  $current = Get-BsiStableSnapshot $FormalPath
  Assert-BsiSnapshotUnchanged $ExpectedSnapshot $current
  $temporary = New-BsiTemporaryFile (Split-Path -Parent $FormalPath) $Bytes
  try {
    $installed = Invoke-BsiConditionalReplace $temporary $FormalPath $current $Bytes
    $temporary = $null
  }
  finally { Remove-BsiOwnedTemporaryFile $temporary }
  Assert-BciCondition (Test-BcvBytesEqual $installed.Bytes $Bytes) `
    '正式事项卡原子替换后字节不一致'
  return $installed
}

function Open-BctFormalReadLock {
  param([string]$FormalPath, $ExpectedSnapshot)
  Assert-BciCondition ($null -ne $ExpectedSnapshot) '正式事项卡缺少最终稳定快照'
  Assert-BciCondition (Test-BsiSamePath $FormalPath $ExpectedSnapshot.Path) `
    '正式事项卡最终规范路径改变'
  Invoke-BctStagingTestInjection 'before-final-formal-handle-open' `
    ([pscustomobject]@{
        FormalPath = $ExpectedSnapshot.Path
        ExpectedSnapshot = $ExpectedSnapshot
      })
  # 单次 OPEN_REPARSE_POINT 打开后，从同一 handle 复核规范路径、类型、
  # link count、identity、length 与 bytes，并保持排他 lease 到 staging 清理结束。
  $lock = Open-BsiOwnedFileLock $ExpectedSnapshot '正式事项卡最终锁 '
  return $lock.Stream
}

function Restore-BctOriginal {
  param(
    [string]$FormalPath, [byte[]]$OriginalBytes,
    $ExpectedFormalSnapshot, $Staging
  )
  Assert-BciCondition ($null -ne $ExpectedFormalSnapshot) `
    '回滚缺少本事务正式卡快照'
  Assert-BciCondition ($null -ne $Staging -and $null -ne $Staging.Candidate -and
      $null -ne $Staging.Candidate.Bytes) '回滚缺少当前 staging 候选快照'
  [byte[]]$stagingCandidateBytes = $Staging.Candidate.Bytes
  Restore-BctStagingFiles $Staging $OriginalBytes $stagingCandidateBytes
  $current = Get-BsiStableSnapshot $FormalPath
  Assert-BsiSnapshotUnchanged $ExpectedFormalSnapshot $current
  [void](Install-BctFormalBytes $FormalPath $OriginalBytes $current)
  $restored = Get-BsiStableSnapshot $FormalPath
  Assert-BciCondition (Test-BcvBytesEqual $restored.Bytes $OriginalBytes) `
    '原活动卡恢复后字节不一致'
  Assert-BctOwnedFileLease $Staging.Original
  Assert-BciCondition (Test-BcvBytesEqual `
      $Staging.Original.Bytes $OriginalBytes) '回滚原活动卡 guard 字节改变'
  Assert-BsiSnapshotUnchanged $Staging.Candidate `
    (Get-BsiStableSnapshot $Staging.Candidate.Path)
}

function Invoke-BctSealProcess {
  param([string]$SafeRoot, [string]$FormalPath)
  $scriptPath = Join-Path $SafeRoot '能力资产\tools\scripts\seal-borrowing-item.ps1'
  $scriptInfo = Get-BorrowingSafePathInfo $scriptPath File close missing-trusted-component
  Assert-BciCondition ((Get-BorrowingPathRelation $SafeRoot $scriptInfo.CanonicalPath) -ceq `
      'ancestor') 'seal helper 跨出项目根'
  $executableInfo = Get-BorrowingSafePathInfo (Join-Path $PSHOME 'powershell.exe') `
    File close missing-trusted-component $true $true
  $environment = New-BorrowingProcessEnvironment -RemovePrefixes @('GIT_') `
    -RemoveNames @('SSH_ASKPASS', 'SSH_ASKPASS_REQUIRE') -Overrides @{}
  return Invoke-BorrowingBoundedProcess -Executable $executableInfo.CanonicalPath `
    -ArgumentList @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy',
      'Bypass', '-File', $scriptInfo.CanonicalPath, '-Root', $SafeRoot,
      '-CardPath', $FormalPath) -WorkingDirectory $SafeRoot `
    -EnvironmentVariables $environment -TimeoutMilliseconds 120000 `
    -StdOutLimitBytes 1048576 -StdErrLimitBytes 1048576 `
    -Stage seal -TimeoutReasonCode seal-failed -FailureReasonCode seal-failed
}

function Invoke-BorrowingCloseTransaction {
  param(
    [string]$Root, [string]$CardPath, [string]$ClosedAt,
    [string]$Reason, [string]$Confirmation
  )
  $stage = 'preflight'
  $reasonCode = 'preflight-failed'
  $borrowId = 'none'
  $formalPath = 'none'
  $staging = $null
  $formalInstalled = $false
  $candidate = $null
  $p4t = 'not-run'
  $originalBytes = $null
  $ownedFormalSnapshot = $null
  $formalOwnershipUnproven = $false
  $formalLock = $null
  $stagingAttempt = [pscustomobject]@{ Value = 'none（未创建）' }
  $completeReached = $false
  try {
    $mode = Invoke-BorrowingP4tModeCheck -Root $Root
    Assert-BciCondition ($mode.ExitCode -eq 0 -and $mode.Mode -ceq 'project') `
      'close 只允许 project-only Root'
    $safeRoot = Resolve-BorrowingP4tSafeRoot $Root
    $formal = Get-BciFormalTarget $safeRoot $CardPath
    $borrowId = $formal.Card.BorrowId
    $formalPath = $formal.Path
    $sourceState = Invoke-BorrowingP4tSourceCheck -Root $safeRoot -Mode project
    Assert-BciCondition ($sourceState.ExitCode -eq 0) 'close 来源检查未通过'
    $active = Invoke-BpiSingleItemValidation -Root $safeRoot `
      -CardPath $formal.Path -SourceState $sourceState
    Assert-BciCondition $active.IsValid '原活动事项卡合同无效'
    Assert-BciCondition ($active.Card.Status -cne 'closed') '事项卡已经 closed'
    $itemRoot = Get-BorrowingSafePathInfo (Split-Path -Parent $formal.Path) `
      Directory close source-unsafe
    Assert-BciCondition ((Get-BorrowingPathRelation `
        $itemRoot.CanonicalPath $formal.Path) -ceq 'ancestor') `
      '正式事项卡不在受信事项目录直属范围'
    $baseline = Get-BsiStableSnapshot $formal.Path
    Assert-BciCondition (Test-BcvBytesEqual $active.Card.Bytes $baseline.Bytes) `
      '原活动事项卡在校验后改变'
    $originalBytes = $baseline.Bytes

    $stage = 'candidate'
    $reasonCode = 'candidate-invalid'
    $candidate = New-BciClosedCandidate $active.Card $ClosedAt $Reason $Confirmation
    $staging = New-BctStaging $itemRoot `
      $originalBytes $candidate.Bytes -AttemptedPath $stagingAttempt
    $context = New-BpiValidationContext $safeRoot $sourceState
    Assert-BciCondition ($context.Failures.Count -eq 0) '关闭候选上下文无效'
    [void](Assert-BciClosedCandidate $staging.Candidate.Path $formal.Path `
      $context $candidate.Bytes)

    $stage = 'install-candidate'
    $ownedFormalSnapshot = Install-BctFormalBytes $formal.Path $candidate.Bytes $baseline
    $formalInstalled = $true

    $stage = 'seal'
    $reasonCode = 'seal-failed'
    $sealResult = Invoke-BctSealProcess $safeRoot $formal.Path
    Assert-BciCondition ($sealResult.ExitCode -eq 0) 'seal helper 未通过'
    try { $sealed = Get-BsiStableSnapshot $formal.Path }
    catch {
      $formalOwnershipUnproven = $true
      $reasonCode = 'seal-ownership-unproven'
      throw
    }
    try { $attestation = ConvertFrom-BsiSealAttestation $sealResult.StdOut }
    catch {
      $formalOwnershipUnproven = $true
      $reasonCode = 'seal-ownership-unproven'
      throw
    }
    if ($attestation.IdentityKey -cne $sealed.IdentityKey -or
        [uint64]$attestation.Length -ne [uint64]$sealed.Length -or
        $attestation.Sha256 -cne (Get-BorrowingSha256Hex -Bytes $sealed.Bytes)) {
      $formalOwnershipUnproven = $true
      $reasonCode = 'seal-ownership-unproven'
      throw 'seal helper 证明未绑定当前正式卡'
    }
    $ownedFormalSnapshot = $sealed
    Set-BctCandidateBytes $staging $sealed.Bytes
    Assert-BciCondition ($attestation.BorrowId -ceq $borrowId) `
      'seal helper 证明 borrow_id 不一致'
    Assert-BciCondition (Test-BcvBytesEqual $sealed.Bytes $candidate.SealedBytes) `
      'seal helper 结果与关闭候选不一致'

    $stage = 'p4t-after'
    $reasonCode = 'p4t-failed'
    $p4tResult = Invoke-BorrowingP4tGate -Root $safeRoot -Stage p4t-after
    $p4t = [string]$p4tResult.ExitCode
    Assert-BciCondition ($p4tResult.ExitCode -eq 0) '完整根 P4t 未通过'

    $stage = 'stability-after-p4t'
    $reasonCode = 'concurrent-change'
    if ($script:BctTestInjections -is [Collections.IDictionary] -and
        $script:BctTestInjections.Contains('before-final-formal-lock')) {
      & $script:BctTestInjections['before-final-formal-lock'] `
        ([pscustomobject]@{ FormalPath = $formalPath; ExpectedSnapshot = $sealed })
    }
    $formalLock = Open-BctFormalReadLock $formalPath $sealed

    $stage = 'cleanup'
    $reasonCode = 'cleanup-failed'
    Remove-BctStaging $staging
    $completeReached = $staging.State -cin @('content-deleted', 'removed')
    $formalLock.Dispose()
    $formalLock = $null
    $staging = $null
    return New-BctResult 0 CLOSED complete $borrowId $formalPath `
      'none（已清理）' $p4t none
  }
  catch {
    if ($null -ne $staging -and
        $staging.State -cin @('content-deleted', 'removed')) {
      # 2026-07-21 by Codex — staging 证据全删后事务已不可逆完成，禁止再回滚正式卡。
      $completeReached = $true
    }
    if ($null -ne $formalLock) {
      try { $formalLock.Dispose() }
      catch { }
      $formalLock = $null
    }
    if (-not $completeReached -and $formalInstalled -and
        -not $formalOwnershipUnproven -and
        $null -ne $candidate -and $null -ne $staging) {
      try {
        Restore-BctOriginal $formalPath $originalBytes `
          $ownedFormalSnapshot $staging
      }
      catch {
        $stage = 'rollback'
        $reasonCode = 'rollback-failed'
      }
    }
    if ($null -ne $staging -and $null -ne $staging.Directory) {
      Close-BctStagingLeases $staging
    }
    $stagingPath = if ($null -ne $staging -and
        (Test-Path -LiteralPath $staging.Path -PathType Container)) {
      $staging.Path
    }
    elseif ($null -ne $staging -and $staging.State -ceq 'removed') {
      'none（已清理）'
    }
    elseif ($stagingAttempt.Value -cne 'none（未创建）') { $stagingAttempt.Value }
    else { 'none（未创建）' }
    return New-BctResult 10 FAIL $stage $borrowId $formalPath `
      $stagingPath $p4t $reasonCode
  }
}
