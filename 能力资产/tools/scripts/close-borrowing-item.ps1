[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$CardPath,
  [Parameter(Mandatory = $true)][string]$ClosedAt,
  [Parameter(Mandatory = $true)][string]$Reason,
  [Parameter(Mandatory = $true)][string]$Confirmation
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)

function Assert-BsiCondition {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Test-BsiSamePath {
  param([string]$Left, [string]$Right)
  return [string]::Equals(
    $Left, $Right, [StringComparison]::OrdinalIgnoreCase)
}

$scriptRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$p4tRoot = Join-Path $scriptRoot 'check-os\p4t'
$captureRoot = Join-Path $scriptRoot 'borrowing-capture'
foreach ($dependency in @(
    (Join-Path $p4tRoot 'borrowing-mode.ps1'),
    (Join-Path $p4tRoot 'borrowing-source-cards.ps1'),
    (Join-Path $p4tRoot 'borrowing-item-cards.ps1'),
    (Join-Path $captureRoot 'process.ps1'),
    (Join-Path $captureRoot 'p4t-runner.ps1'),
    (Join-Path $scriptRoot 'borrowing-seal-transaction.ps1'),
    (Join-Path $scriptRoot 'borrowing-conditional-replace.ps1'),
    (Join-Path $scriptRoot 'borrowing-seal-attestation.ps1'),
    (Join-Path $scriptRoot 'borrowing-close-candidate.ps1'),
    (Join-Path $scriptRoot 'borrowing-close-transaction.ps1'))) {
  if (-not (Test-Path -LiteralPath $dependency -PathType Leaf)) {
    [Console]::Error.WriteLine('[FAIL] close 缺少受信依赖')
    exit 10
  }
  . $dependency
}

try {
  $result = Invoke-BorrowingCloseTransaction -Root $Root -CardPath $CardPath `
    -ClosedAt $ClosedAt -Reason $Reason -Confirmation $Confirmation
}
catch {
  $result = [pscustomobject][ordered]@{
    ExitCode = 10; Result = 'FAIL'; Stage = 'facade'; BorrowId = 'none'
    CardPath = 'none'; StagingPath = 'none（未创建）'; P4t = 'not-run'
    ReasonCode = 'facade-failed'
  }
}

@(
  'CZXT_BORROWING_CLOSE_V1'
  ('result=' + $result.Result)
  ('stage=' + $result.Stage)
  ('borrow_id=' + $result.BorrowId)
  ('card_path=' + $result.CardPath)
  ('staging_path=' + $result.StagingPath)
  ('p4t=' + $result.P4t)
  ('reason_code=' + $result.ReasonCode)
) | ForEach-Object { [Console]::Out.WriteLine($_) }
exit ([int]$result.ExitCode)
