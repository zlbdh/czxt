[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$CardPath
)

$ErrorActionPreference = 'Stop'

$sealScriptRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$p4tRoot = Join-Path $sealScriptRoot 'check-os\p4t'
foreach ($dependency in @(
    'borrowing-mode.ps1', 'borrowing-source-cards.ps1',
    'borrowing-item-cards.ps1')) {
  $dependencyPath = Join-Path $p4tRoot $dependency
  if (-not (Test-Path -LiteralPath $dependencyPath -PathType Leaf)) {
    throw ('seal is missing a trusted dependency: ' + $dependency)
  }
  . $dependencyPath
}

function Assert-BsiCondition {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Test-BsiSamePath {
  param([string]$Left, [string]$Right)
  return [string]::Equals(
    $Left, $Right, [StringComparison]::OrdinalIgnoreCase)
}

$transactionNames = @(
  'borrowing-seal-transaction.ps1',
  'borrowing-conditional-replace.ps1',
  'borrowing-seal-attestation.ps1'
)
foreach ($transactionName in $transactionNames) {
  $transactionPath = Join-Path $sealScriptRoot $transactionName
  if (-not (Test-Path -LiteralPath $transactionPath -PathType Leaf)) {
    throw ('seal is missing a transaction dependency: ' + $transactionName)
  }
  . $transactionPath
}

function Get-BsiFormalTarget {
  param([string]$SafeRoot, [string]$RequestedPath)
  $itemsPath = Join-Path $SafeRoot '借鉴区\事项'
  $items = Get-BorrowingSafePathInfo $itemsPath Directory seal source-unsafe
  $requested = Get-BorrowingSafePathInfo $RequestedPath File seal source-unsafe
  $card = Read-BpiItemCard $requested.CanonicalPath
  $expectedPath = Join-Path (Join-Path $items.CanonicalPath $card.BorrowId) '借鉴卡.md'
  $expected = Get-BorrowingSafePathInfo $expectedPath File seal source-unsafe
  Assert-BsiCondition (Test-BsiSamePath $requested.CanonicalPath $expected.CanonicalPath) `
    'seal target is not a formal item card path'
  Assert-BsiCondition ($requested.IdentityKey -ceq $expected.IdentityKey) `
    'seal target identity does not match the formal item card'
  return [pscustomobject]@{
    Path = $expected.CanonicalPath
    Card = $card
  }
}

function Get-BsiSealedBytes {
  param($Card)
  Assert-BsiCondition ($Card.ClosureSeal.Length -eq 0) 'Item card is already sealed'
  $seal = Get-BpiClosureSeal $Card.Text
  $pattern = '(?m)^closure_seal_sha256: ""$'
  Assert-BsiCondition ([regex]::Matches($Card.Text, $pattern).Count -eq 1) `
    'Empty seal line is not unique'
  $sealedText = [regex]::Replace(
    $Card.Text, $pattern, ('closure_seal_sha256: ' + $seal), 1)
  $encoding = New-Object Text.UTF8Encoding($false, $true)
  return ,$encoding.GetBytes($sealedText)
}

$temporary = $null
$replacement = $null
try {
  $mode = Invoke-BorrowingP4tModeCheck -Root $Root
  Assert-BsiCondition ($mode.ExitCode -eq 0 -and $mode.Mode -ceq 'project') `
    'seal permits only a project-only Root'
  $safeRoot = Resolve-BorrowingP4tSafeRoot $Root
  $formal = Get-BsiFormalTarget $safeRoot $CardPath

  $sourceState = Invoke-BorrowingP4tSourceCheck -Root $safeRoot -Mode project
  Assert-BsiCondition ($sourceState.ExitCode -eq 0) 'Source validation failed'
  $validation = Invoke-BpiSingleItemValidation -Root $safeRoot `
    -CardPath $formal.Path -SourceState $sourceState -AllowEmptyClosedSeal
  Assert-BsiCondition $validation.IsValid 'Item card contract is invalid apart from the seal'
  Assert-BsiCondition ($validation.Card.Status -ceq 'closed') 'Item card is not yet closed'
  Assert-BsiCondition ($validation.Card.ClosureSeal.Length -eq 0) 'Item card is already sealed'

  $baseline = Get-BsiStableSnapshot $formal.Path
  Assert-BsiCondition (Test-BcvBytesEqual $validation.Card.Bytes $baseline.Bytes) `
    'Item card changed after validation'
  [byte[]]$sealedBytes = Get-BsiSealedBytes $validation.Card
  $temporary = New-BsiTemporaryFile (Split-Path -Parent $formal.Path) $sealedBytes

  $preReplace = Get-BsiStableSnapshot $formal.Path
  Assert-BsiSnapshotUnchanged $baseline $preReplace
  Assert-BsiTemporaryUnchanged $temporary $sealedBytes
  $replacement = Start-BsiConditionalReplace $temporary $formal.Path `
    $baseline $sealedBytes
  $temporary = $null
  $sealed = $replacement.Installed

  Assert-BsiCondition (Test-BcvBytesEqual $sealedBytes $sealed.Bytes) `
    'Bytes differ after atomic seal replacement'
  $postSource = Invoke-BorrowingP4tSourceCheck -Root $safeRoot -Mode project
  Assert-BsiCondition ($postSource.ExitCode -eq 0) 'Post-seal source validation failed'
  $postItem = Invoke-BorrowingP4tItemCheck -Root $safeRoot -SourceState $postSource
  Assert-BsiCondition ($postItem.ExitCode -eq 0) 'Post-seal item validation failed'
  $attested = Get-BsiStableSnapshot $formal.Path
  Assert-BsiSnapshotUnchanged $sealed $attested
  $attestationLine = New-BsiSealAttestationLine $validation.Card.BorrowId $attested
  $completed = Complete-BsiConditionalReplace $replacement
  $replacement = $null
  Assert-BsiSnapshotUnchanged $attested $completed
  Write-Output $attestationLine
  exit 0
}
catch {
  if ($null -ne $replacement -and $replacement.State -ceq 'pending') {
    try { [void](Undo-BsiConditionalReplace $replacement) }
    catch { }
  }
  Remove-BsiOwnedTemporaryFile $temporary
  [Console]::Error.WriteLine('[FAIL] Failed to seal borrowing item')
  exit 10
}
