$ErrorActionPreference = 'Stop'

function Assert-BciCondition {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Test-BciSamePath {
  param([string]$Left, [string]$Right)
  return [string]::Equals(
    $Left, $Right, [StringComparison]::OrdinalIgnoreCase)
}

function Get-BciFormalTarget {
  param([string]$SafeRoot, [string]$RequestedPath)
  $items = Get-BorrowingSafePathInfo (Join-Path $SafeRoot '借鉴区\事项') `
    Directory close source-unsafe
  $requested = Get-BorrowingSafePathInfo $RequestedPath File close source-unsafe
  $card = Read-BpiItemCard $requested.CanonicalPath
  $expectedPath = Join-Path (Join-Path $items.CanonicalPath $card.BorrowId) '借鉴卡.md'
  $expected = Get-BorrowingSafePathInfo $expectedPath File close source-unsafe
  Assert-BciCondition (Test-BciSamePath $requested.CanonicalPath $expected.CanonicalPath) `
    'close 目标不是正式事项卡路径'
  Assert-BciCondition ($requested.IdentityKey -ceq $expected.IdentityKey) `
    'close 目标身份与正式事项卡不一致'
  return [pscustomobject]@{ Path = $expected.CanonicalPath; Card = $card }
}

function Set-BciSingleLine {
  param([string]$Text, [string]$OldLine, [string]$NewLine)
  $pattern = '(?m)^' + [regex]::Escape($OldLine) + '$'
  Assert-BciCondition ([regex]::Matches($Text, $pattern).Count -eq 1) `
    ('close 候选唯一行缺失：' + $OldLine)
  return [regex]::Replace($Text, $pattern, $NewLine, 1)
}

function New-BciClosedCandidate {
  param(
    $ActiveCard,
    [string]$ClosedAt,
    [string]$Reason,
    [string]$Confirmation
  )
  $validOrigin = ($ActiveCard.Status -ceq 'verifying' -and
      $ActiveCard.Decision -cin @('adopt', 'adapt')) -or
    ($ActiveCard.Status -ceq 'assessing' -and $ActiveCard.Decision -ceq 'reject')
  Assert-BciCondition $validOrigin '事项卡当前状态不能进入 closed'
  Assert-BciCondition (-not $ActiveCard.Blocked) '阻塞事项不能进入 closed'
  Assert-BciCondition ($ActiveCard.ClosureSeal.Length -eq 0) '活动事项含 seal'
  Assert-BciCondition ((Test-BpiSafeScalar $Reason) -and
      $Reason -ceq $Reason.Trim()) '关闭原因不安全或为空'
  Assert-BciCondition ((Test-BpiSafeScalar $Confirmation) -and
      $Confirmation -ceq $Confirmation.Trim()) '关闭确认不安全或为空'
  $closedTime = ConvertFrom-BpiOffsetTime $ClosedAt
  $updatedTime = ConvertFrom-BpiOffsetTime $ActiveCard.UpdatedAt
  Assert-BciCondition ($closedTime -ge $updatedTime) '关闭时间早于当前更新时间'

  $historyLine = '| {0} | {1} | closed | {2} | {3} | {4} |' -f
    $ClosedAt, $ActiveCard.Status, $ActiveCard.Decision, $Reason, $Confirmation
  $lastLine = [string]$ActiveCard.HistoryRows[-1].Line
  $anchor = $lastLine + "`n`n## 阻塞信息"
  Assert-BciCondition ([regex]::Matches(
      $ActiveCard.Text, [regex]::Escape($anchor)).Count -eq 1) `
    '关闭历史插入点不唯一'

  $text = Set-BciSingleLine $ActiveCard.Text `
    ('lifecycle_status: ' + $ActiveCard.Status) 'lifecycle_status: closed'
  $text = Set-BciSingleLine $text ('updated_at: ' + $ActiveCard.UpdatedAt) `
    ('updated_at: ' + $ClosedAt)
  $text = $text.Replace($anchor, $lastLine + "`n" + $historyLine + "`n`n## 阻塞信息")
  Assert-BciCondition ([regex]::Matches(
      $text, '(?m)^closure_seal_sha256: ""$').Count -eq 1) `
    '关闭候选空 seal 行不唯一'
  $encoding = New-Object Text.UTF8Encoding($false, $true)
  [byte[]]$bytes = $encoding.GetBytes($text)
  $seal = Get-BpiClosureSeal $text
  $sealedText = [regex]::Replace($text,
    '(?m)^closure_seal_sha256: ""$', ('closure_seal_sha256: ' + $seal), 1)
  return [pscustomobject]@{
    Text = $text; Bytes = $bytes; SealedText = $sealedText
    SealedBytes = [byte[]]$encoding.GetBytes($sealedText); Seal = $seal
  }
}

function Assert-BciClosedCandidate {
  param([string]$CandidatePath, [string]$FormalPath, $Context, [byte[]]$ExpectedBytes)
  $snapshot = Get-BsiStableSnapshot $CandidatePath
  Assert-BciCondition (Test-BcvBytesEqual $snapshot.Bytes $ExpectedBytes) `
    '关闭候选字节改变'
  $card = Read-BpiItemCard $snapshot.Path
  $card.Path = $FormalPath
  Assert-BciCondition ($card.Status -ceq 'closed') '关闭候选状态不是 closed'
  Assert-BciCondition ($card.ClosureSeal.Length -eq 0) '关闭候选提前含 seal'
  Test-BpiCardContract $card $Context -AllowEmptyClosedSeal
  return $card
}
