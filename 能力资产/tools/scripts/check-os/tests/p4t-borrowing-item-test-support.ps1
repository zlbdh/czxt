$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-source-test-support.ps1')

function New-P4tHistoryRow {
  param(
    [string]$Time, [string]$Old, [string]$New,
    [string]$Decision, [string]$Reason = 'fixture transition'
  )
  return [pscustomobject]@{
    Time = $Time; Old = $Old; New = $New; Decision = $Decision
    Reason = $Reason; Confirmation = 'fixture-owner'
  }
}

function Get-P4tDefaultItemHistory {
  param([string]$Status, [string]$Decision)
  $rows = @(
    (New-P4tHistoryRow '2026-07-19T01:00:00+00:00' none draft pending '建立事项')
  )
  if ($Status -eq 'draft') { return $rows }
  if ($Status -eq 'cancelled') {
    return $rows + (New-P4tHistoryRow '2026-07-19T02:00:00+00:00' draft cancelled $Decision '明确取消原因')
  }
  $assessingDecision = if ($Status -eq 'assessing') { $Decision } else { 'pending' }
  $rows += New-P4tHistoryRow '2026-07-19T02:00:00+00:00' draft assessing $assessingDecision
  if ($Status -eq 'assessing') { return $rows }
  if ($Status -eq 'parked') {
    return $rows + (New-P4tHistoryRow '2026-07-19T03:00:00+00:00' assessing parked defer '等待恢复条件')
  }
  if ($Status -eq 'closed' -and $Decision -eq 'reject') {
    return $rows + (New-P4tHistoryRow '2026-07-19T03:00:00+00:00' assessing closed reject '有证据拒绝')
  }
  $rows += New-P4tHistoryRow '2026-07-19T03:00:00+00:00' assessing implementation_ready $Decision '审批通过'
  if ($Status -eq 'implementation_ready') { return $rows }
  $rows += New-P4tHistoryRow '2026-07-19T04:00:00+00:00' implementation_ready implementing $Decision '开始实施'
  if ($Status -eq 'implementing') { return $rows }
  $rows += New-P4tHistoryRow '2026-07-19T05:00:00+00:00' implementing verifying $Decision '进入验证'
  if ($Status -eq 'verifying') { return $rows }
  return $rows + (New-P4tHistoryRow '2026-07-19T06:00:00+00:00' verifying closed $Decision 'fresh 验证通过')
}

function Get-P4tClosureSealFromText {
  param([string]$Text)
  $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n") + "`n"
  $pattern = '(?m)^closure_seal_sha256:.*$'
  Assert-CzxtEqual 1 ([regex]::Matches($normalized, $pattern)).Count 'fixture seal line count'
  $blank = [regex]::Replace($normalized, $pattern, 'closure_seal_sha256: ""', 1)
  return Get-P4tSha256Hex ([Text.Encoding]::UTF8.GetBytes($blank))
}

function Set-P4tFixtureSeal {
  param([string]$CardPath)
  $text = [IO.File]::ReadAllText($CardPath, $script:P4tUtf8NoBom)
  $seal = Get-P4tClosureSealFromText $text
  $updated = [regex]::Replace($text, '(?m)^closure_seal_sha256:.*$',
    ('closure_seal_sha256: ' + $seal), 1)
  Write-P4tUtf8 $CardPath $updated
  return $seal
}

function Set-P4tSourceReuseScope {
  param(
    $Source,
    [ValidateSet('copy-internal-approved', 'adapt-internal-approved')]
    [string]$ReuseScope
  )
  Set-P4tFrontmatterField $Source.CardPath reuse_scope $ReuseScope
  $text = [IO.File]::ReadAllText($Source.CardPath, $script:P4tUtf8NoBom)
  $old = '| reuse_scope | inspect-and-analyze-only | 2026-07-19T01:02:03.456Z | default-policy | current-capture |'
  $new = '| reuse_scope | {0} | 2026-07-19T01:00:00.000Z | approved-fixture | current-capture |' -f $ReuseScope
  Assert-CzxtTrue $text.Contains($old) 'fixture reuse authorization row'
  Write-P4tUtf8 $Source.CardPath $text.Replace($old, $new)
  Add-Member -InputObject $Source -NotePropertyName Permissions `
    -NotePropertyValue ([pscustomobject]@{ ReuseScope = $ReuseScope }) -Force
}

function Get-P4tEvidenceTargetManifestSha256 {
  param([string]$Root)
  $relative = 'app/borrowed.txt'
  $target = Join-Path $Root $relative.Replace('/', '\')
  $targetHash = Get-P4tSha256Hex ([IO.File]::ReadAllBytes($target))
  $manifest = $relative + "`t" + $targetHash + "`n"
  return Get-P4tSha256Hex ([Text.Encoding]::UTF8.GetBytes($manifest))
}

function Get-P4tEvidenceRecordText {
  param(
    [string]$Root,
    [string]$Time = '2026-07-19T05:30:00+00:00',
    [string]$Command = 'powershell -File check.ps1',
    [string]$Exit = '0'
  )
  $commandHash = Get-P4tSha256Hex ([Text.Encoding]::UTF8.GetBytes($Command))
  $targetManifestHash = Get-P4tEvidenceTargetManifestSha256 $Root
  return (@(
      'schema=borrowing-evidence/v1'
      ('time=' + $Time)
      ('command_sha256=' + $commandHash)
      ('exit=' + $Exit)
      ('target_manifest_sha256=' + $targetManifestHash)
    ) -join "`n") + "`n"
}

function New-P4tItemCard {
  param(
    [string]$Root,
    [string]$BorrowId,
    [object[]]$Bindings,
    [string]$Status = 'assessing',
    [string]$Decision = 'pending',
    [object[]]$History = @(),
    [bool]$Blocked = $false,
    [string]$BlockedFrom = '',
    [string]$BlockReason = '',
    [string]$ResumeCondition = '',
    [string]$Supersedes = '',
    [bool]$IncludeTarget = $true,
    [bool]$IncludeDifference = $true,
    [bool]$IncludeFreshEvidence = $true,
    [bool]$IncludeRejectEvidence = $true,
    [bool]$IncludeRejectReason = $true,
    [bool]$Seal = $false
  )
  if ($History.Count -eq 0) { $History = @(Get-P4tDefaultItemHistory $Status $Decision) }
  $updatedAt = [string]$History[-1].Time
  $bindingRows = @($Bindings | ForEach-Object {
      '| {0} | {1} | {2} | 证据/{0}/{1} |' -f $_.SourceId, $_.CaptureId, $_.Fingerprint
    })
  if ($bindingRows.Count -eq 0) { $bindingRows = @('| missing | missing | missing | missing |') }
  $targetRow = if ($IncludeTarget) {
    '| app/borrowed.txt | development-pm | L1 | ADR-039 |'
  } else { '| 待填写 | development-pm | L1 | 无 |' }
  $adoptLine = if ($IncludeDifference) { '- 适配差异：仅复制已审批的接口思想并本地化命名。' } else { '- 待填写。' }
  $rejectLine = if ($IncludeRejectReason) { '- 拒绝理由：与当前项目边界冲突，不予采纳。' } else { '- 待填写。' }
  $candidateReason = if ($IncludeRejectEvidence) { '已完成离线比较并保留评估证据' } else { '待填写' }
  $freshLine = if ($IncludeFreshEvidence) {
    '- time=2026-07-19T05:30:00+00:00; command=powershell -File check.ps1; exit=0; evidence=证据/验证摘要.md'
  } else { '- 当前尚无。' }
  $implementationLine = if ($Status -in @('implementing', 'verifying', 'closed')) {
    '- 已在 `app/borrowed.txt` 完成本地化实施。'
  } else { '- 当前尚未实施。' }
  $historyRows = @($History | ForEach-Object {
      '| {0} | {1} | {2} | {3} | {4} | {5} |' -f
        $_.Time, $_.Old, $_.New, $_.Decision, $_.Reason, $_.Confirmation
    })
  $blockedValue = if ($Blocked) { 'true' } else { 'false' }
  $lines = @(
    '---', 'schema: borrowing-item/v1', ('borrow_id: ' + $BorrowId),
    ('title: P4t fixture ' + $BorrowId), ('lifecycle_status: ' + $Status),
    ('decision: ' + $Decision), 'impact_level: L1', 'owner_pm: project-pm',
    ('blocked: ' + $blockedValue), 'created_at: 2026-07-19T01:00:00+00:00',
    ('updated_at: ' + $updatedAt), ('supersedes: "' + $Supersedes + '"'),
    'closure_seal_sha256: ""', '---', '# 借鉴卡', '',
    '- 适用项目：`P4t fixture`', ('- 正式路径：`借鉴区/事项/{0}/借鉴卡.md`' -f $BorrowId),
    '- 一张卡只维护一个事项的当前状态与追加历史；合法修订不得覆盖已关闭事项，应新建卡并填写 `supersedes`。',
    '', '## 问题与成功标准', '', '- 要解决的问题：减少重复治理实现。', '- 成功标准：P4t 离线验证可复验。',
    '', '## 来源绑定', '', '支持多来源；活动事项只能绑定 `ready` capture。证据定位符必须是净化后的相对路径或公开定位符。',
    '', '| source_id | capture_id | fingerprint | 证据定位符 |', '|---|---|---|---|'
  ) + $bindingRows + @(
    '', '## 候选矩阵', '', '| 已有能力 | 可借鉴点 | 冲突 | 结论 | 理由 |', '|---|---|---|---|---|',
    ('| 现有治理 | 固定卡片合同 | 无 | 已评估 | ' + $candidateReason + ' |'),
    '', '## 明确采纳', '', $adoptLine, '', '## 明确不采纳', '', $rejectLine,
    $(if ($Status -eq 'parked') { '- 恢复条件：2026-08-01 复查依赖条件。' } else { '- 无其他排除项。' }),
    '', '## 目标与责任', '', '| 目标文件 | 责任 PM | 影响级别 | PROP/ADR |', '|---|---|---|---|', $targetRow,
    '', '## 验收标准', '', '- 运行 P4t 并得到 exit 0。', '', '## 实施记录', '', $implementationLine,
    '', '## fresh 验证证据', '', $freshLine, '', '## 状态历史', '',
    '历史逐行追加，时间必须非递减；末行必须与 frontmatter 的 `lifecycle_status` 和 `decision` 一致。',
    '', '| 时间 | 旧状态 | 新状态 | decision | 原因 | 确认 |', '|---|---|---|---|---|---|'
  ) + $historyRows + @(
    '', '## 阻塞信息', '', '仅当 `blocked: true` 时填写；终态不得标记阻塞。', '',
    '| blocked_from | reason | resume_condition |', '|---|---|---|',
    ('| {0} | {1} | {2} |' -f $BlockedFrom, $BlockReason, $ResumeCondition)
  )
  $itemRoot = Join-Path $Root ('借鉴区\事项\' + $BorrowId)
  [void](New-Item -ItemType Directory -Path $itemRoot -Force)
  $cardPath = Join-Path $itemRoot '借鉴卡.md'
  Write-P4tUtf8 $cardPath (($lines -join "`n") + "`n")
  if ($IncludeTarget) {
    Write-P4tUtf8 (Join-Path $Root 'app\borrowed.txt') "fixture target`n"
  }
  if ($IncludeFreshEvidence) {
    $evidencePath = Join-Path $itemRoot '证据\验证摘要.md'
    [void](New-Item -ItemType Directory -Path (Split-Path -Parent $evidencePath) -Force)
    $evidenceText = if ($IncludeTarget) {
      Get-P4tEvidenceRecordText $Root
    } else { "fixture evidence without target`n" }
    Write-P4tUtf8 $evidencePath $evidenceText
  }
  $sealValue = ''
  if ($Seal) { $sealValue = Set-P4tFixtureSeal $cardPath }
  return [pscustomobject]@{
    BorrowId = $BorrowId; CardPath = $cardPath; Status = $Status
    Decision = $Decision; Seal = $sealValue
  }
}
