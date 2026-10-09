$ErrorActionPreference = "Stop"

function Get-PropStateSpecs {
  @(
    [PSCustomObject]@{ Label = "Pending approval"; RelPattern = "确认改动\待审批\*"; StatusPattern = "待审批|\APending approval(?=\s*(?:/|$))"; DirRel = "确认改动\待审批"; LinkPrefix = "待审批/" },
    [PSCustomObject]@{ Label = "In progress"; RelPattern = "确认改动\已审批\进行中\*"; StatusPattern = "未收口|\AApproved\s*·\s*Open(?=\s*(?:/|$))"; DirRel = "确认改动\已审批\进行中"; LinkPrefix = "已审批/进行中/" },
    [PSCustomObject]@{ Label = "Completed"; RelPattern = "确认改动\已审批\已完成\*"; StatusPattern = "已完成|\AApproved\s*·\s*Completed(?=\s*(?:/|$))"; DirRel = "确认改动\已审批\已完成"; LinkPrefix = "已审批/已完成/" },
    [PSCustomObject]@{ Label = "Abandoned"; RelPattern = "确认改动\已审批\已弃用\*"; StatusPattern = "已弃用|\AApproved\s*·\s*Abandoned(?=\s*(?:/|$))"; DirRel = "确认改动\已审批\已弃用"; LinkPrefix = "已审批/已弃用/" },
    [PSCustomObject]@{ Label = "Rejected"; RelPattern = "确认改动\拒绝\*"; StatusPattern = "拒绝|\ARejected(?=\s*(?:/|$))"; DirRel = "确认改动\拒绝"; LinkPrefix = "拒绝/" }
  )
}

function ConvertTo-PropStatus {
  param([string]$Raw)
  $rawStatus = $Raw.Trim()
  $bold = [regex]::Match($rawStatus, '^\*\*(?<status>[^*]+)\*\*')
  if ($bold.Success) { return $bold.Groups["status"].Value.Trim() }
  return (($rawStatus -split '[（(]', 2)[0]).Trim().Trim("*").Trim()
}

function Get-PropHeaderStatus {
  param(
    [string]$Path,
    [string]$Rel
  )

  $candidates = @()
  $lines = Get-Content -LiteralPath $Path -TotalCount 80 -Encoding UTF8
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^\s*(?:[-*]|\>)?\s*(?:\*\*)?(当前状态|历史状态|处置状态|状态机|状态字段|状态层|职责状态)') { continue }

    $match = [regex]::Match($line, '^\s*[-*]\s*(?:\*\*)?(?:状态|Status)(?:\*\*)?\s*[：:]\s*(?<raw>.+)$')
    if (-not $match.Success) {
      $match = [regex]::Match($line, '^\s*>\s*(?:(?:.*?/)\s*)?(?:\*\*)?(?:状态|Status)(?:\*\*)?\s*[：:]\s*(?<raw>.+)$')
    }
    if ($match.Success) {
      $candidates += [PSCustomObject]@{
        Line = $i + 1
        Status = ConvertTo-PropStatus $match.Groups["raw"].Value
      }
    }
  }

  if ($candidates.Count -eq 0) {
    Add-Failure "$rel lacks a status field in its header"
    return ""
  }
  if ($candidates.Count -gt 1) {
    Add-Failure "$rel has multiple candidate header status fields: $($candidates.Line -join ', ')"
  }
  return $candidates[0].Status
}
