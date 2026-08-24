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
    throw ('seal 缺少受信依赖：' + $dependency)
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
    throw ('seal 缺少事务依赖：' + $transactionName)
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
    'seal 目标不是正式事项卡路径'
  Assert-BsiCondition ($requested.IdentityKey -ceq $expected.IdentityKey) `
    'seal 目标身份与正式事项卡不一致'
  return [pscustomobject]@{
    Path = $expected.CanonicalPath
    Card = $card
  }
}

function Get-BsiSealedBytes {
  param($Card)
  Assert-BsiCondition ($Card.ClosureSeal.Length -eq 0) '事项卡已经 seal'
  $seal = Get-BpiClosureSeal $Card.Text
  $pattern = '(?m)^closure_seal_sha256: ""$'
  Assert-BsiCondition ([regex]::Matches($Card.Text, $pattern).Count -eq 1) `
    '空 seal 行不唯一'
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
    'seal 只允许 project-only Root'
  $safeRoot = Resolve-BorrowingP4tSafeRoot $Root
  $formal = Get-BsiFormalTarget $safeRoot $CardPath

  $sourceState = Invoke-BorrowingP4tSourceCheck -Root $safeRoot -Mode project
  Assert-BsiCondition ($sourceState.ExitCode -eq 0) '来源检查未通过'
  $validation = Invoke-BpiSingleItemValidation -Root $safeRoot `
    -CardPath $formal.Path -SourceState $sourceState -AllowEmptyClosedSeal
  Assert-BsiCondition $validation.IsValid '事项卡除 seal 外合同无效'
  Assert-BsiCondition ($validation.Card.Status -ceq 'closed') '事项卡尚未 closed'
  Assert-BsiCondition ($validation.Card.ClosureSeal.Length -eq 0) '事项卡已经 seal'

  $baseline = Get-BsiStableSnapshot $formal.Path
  Assert-BsiCondition (Test-BcvBytesEqual $validation.Card.Bytes $baseline.Bytes) `
    '事项卡在校验后改变'
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
    'seal 原子替换后的字节不一致'
  $postSource = Invoke-BorrowingP4tSourceCheck -Root $safeRoot -Mode project
  Assert-BsiCondition ($postSource.ExitCode -eq 0) 'seal 后来源检查未通过'
  $postItem = Invoke-BorrowingP4tItemCheck -Root $safeRoot -SourceState $postSource
  Assert-BsiCondition ($postItem.ExitCode -eq 0) 'seal 后事项检查失败'
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
  [Console]::Error.WriteLine('[FAIL] seal 借鉴事项失败')
  exit 10
}
