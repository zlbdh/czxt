$ErrorActionPreference = "Stop"

function Get-PropStateSpecs {
  @(
    [PSCustomObject]@{ Label = "待审批"; RelPattern = "确认改动\待审批\*"; StatusPattern = "待审批"; DirRel = "确认改动\待审批"; LinkPrefix = "待审批/" },
    [PSCustomObject]@{ Label = "进行中"; RelPattern = "确认改动\已审批\进行中\*"; StatusPattern = "未收口"; DirRel = "确认改动\已审批\进行中"; LinkPrefix = "已审批/进行中/" },
    [PSCustomObject]@{ Label = "已完成"; RelPattern = "确认改动\已审批\已完成\*"; StatusPattern = "已完成"; DirRel = "确认改动\已审批\已完成"; LinkPrefix = "已审批/已完成/" },
    [PSCustomObject]@{ Label = "已弃用"; RelPattern = "确认改动\已审批\已弃用\*"; StatusPattern = "已弃用"; DirRel = "确认改动\已审批\已弃用"; LinkPrefix = "已审批/已弃用/" },
    [PSCustomObject]@{ Label = "拒绝"; RelPattern = "确认改动\拒绝\*"; StatusPattern = "拒绝"; DirRel = "确认改动\拒绝"; LinkPrefix = "拒绝/" }
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

    $match = [regex]::Match($line, '^\s*[-*]\s*(?:\*\*)?状态(?:\*\*)?\s*[：:]\s*(?<raw>.+)$')
    if (-not $match.Success) {
      $match = [regex]::Match($line, '^\s*>\s*(?:(?:.*?/)\s*)?(?:\*\*)?状态(?:\*\*)?\s*[：:]\s*(?<raw>.+)$')
    }
    if ($match.Success) {
      $candidates += [PSCustomObject]@{
        Line = $i + 1
        Status = ConvertTo-PropStatus $match.Groups["raw"].Value
      }
    }
  }

  if ($candidates.Count -eq 0) {
    Add-Failure "$rel 缺少文件头状态字段"
    return ""
  }
  if ($candidates.Count -gt 1) {
    Add-Failure "$rel 文件头状态字段候选不唯一：$($candidates.Line -join ', ')"
  }
  return $candidates[0].Status
}
