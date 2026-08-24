$ErrorActionPreference = 'Stop'

function global:Test-BorrowingExactBytes {
  param([byte[]]$Left, [byte[]]$Right)
  if ($null -eq $Left -or $null -eq $Right -or $Left.Length -ne $Right.Length) {
    return $false
  }
  for ($index = 0; $index -lt $Left.Length; $index++) {
    if ($Left[$index] -ne $Right[$index]) { return $false }
  }
  return $true
}

function global:Read-BorrowingStableSafeFile {
  param([string]$Path, [string]$Stage, [string]$ReasonCode)
  $snapshot = Read-BorrowingStableSafeFileSnapshot $Path $Stage $ReasonCode
  return [pscustomobject]@{ Bytes = $snapshot.Bytes; Info = $snapshot }
}

function global:Assert-BorrowingStagingMembers {
  param([string]$StagingPath)
  $rootBefore = Get-BorrowingSafePathInfo $StagingPath Directory candidate candidate-invalid
  $expectedNames = @('来源版本卡.md', 'capture.local.json', '快照')
  try { $members = @(Get-ChildItem -LiteralPath $rootBefore.CanonicalPath -Force) }
  catch { Throw-BorrowingFailure candidate candidate-invalid 'staging members are unreadable' }
  if ($members.Count -ne $expectedNames.Count) {
    Throw-BorrowingFailure candidate candidate-invalid 'staging contains unknown members'
  }
  foreach ($member in $members) {
    if ($expectedNames -cnotcontains $member.Name) {
      Throw-BorrowingFailure candidate candidate-invalid 'staging contains unknown members'
    }
    $kind = if ($member.PSIsContainer) { 'Directory' } else { 'File' }
    $expectedKind = if ($member.Name -ceq '快照') { 'Directory' } else { 'File' }
    if ($kind -cne $expectedKind) {
      Throw-BorrowingFailure candidate candidate-invalid 'staging member kind is invalid'
    }
    [void](Get-BorrowingSafePathInfo $member.FullName $kind candidate candidate-invalid)
  }
  $rootAfter = Get-BorrowingSafePathInfo $rootBefore.CanonicalPath Directory `
    candidate candidate-invalid
  if ($rootAfter.IdentityKey -cne $rootBefore.IdentityKey) {
    Throw-BorrowingFailure candidate candidate-invalid 'staging identity changed'
  }
  return $rootAfter
}

function global:Assert-BorrowingStagedEnvelope {
  param($Prepared, $Envelope, $Staging, $Validated)
  [void](Assert-BorrowingStagingMembers $Staging.StagingPath)
  if ($Validated.CaptureStatus -cne 'ready') {
    Throw-BorrowingFailure candidate candidate-invalid 'staging source card is not ready'
  }
  $cardPath = Join-Path $Staging.StagingPath '来源版本卡.md'
  $card = Read-BorrowingStableSafeFile $cardPath candidate candidate-invalid
  if ((Get-BorrowingPathRelation $card.Info.CanonicalPath $Validated.CardPath) -cne 'equal' -or
      -not (Test-BorrowingExactBytes $card.Bytes $Validated.CardBytes) -or
      -not (Test-BorrowingExactBytes $card.Bytes $Envelope.Artifact.Bytes)) {
    Throw-BorrowingFailure candidate candidate-invalid 'staging source card bytes differ'
  }
  $state = Read-BorrowingStableSafeFile `
    (Join-Path $Staging.StagingPath 'capture.local.json') candidate candidate-invalid
  if (-not (Test-BorrowingExactBytes $state.Bytes $Envelope.LocalStateBytes)) {
    Throw-BorrowingFailure candidate candidate-invalid 'staging local state bytes differ'
  }
}

$orchestratorValidationRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
. (Join-Path $orchestratorValidationRoot 'orchestrator-path-guards.ps1')
