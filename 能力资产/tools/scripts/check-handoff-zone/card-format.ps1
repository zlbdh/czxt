$ErrorActionPreference = "Stop"

function Get-HandoffFrontmatterStatus {
  param([string]$Path)

  $lines = Get-Content -LiteralPath $Path -TotalCount 40 -Encoding UTF8
  if ($lines.Count -eq 0 -or $lines[0].Trim().Trim([char]0xFEFF) -ne "---") {
    return [PSCustomObject]@{ HasFrontmatter = $false; Status = $null }
  }

  $status = $null
  for ($i = 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq "---") { break }
    $m = [regex]::Match($lines[$i], '^\s*status\s*:\s*(?<raw>[^#]+?)\s*(?:#.*)?$')
    if ($m.Success) {
      $status = $m.Groups["raw"].Value.Trim().Trim('"').Trim("'")
    }
  }

  [PSCustomObject]@{ HasFrontmatter = $true; Status = $status }
}

function Test-HandoffTimestampName {
  param([System.IO.FileInfo]$File)
  return $File.Name -match '^\d{4}-\d{2}-\d{2}-\d{4}-.+\.md$'
}

function Get-PendingHandoffCardIssues {
  param([object[]]$Pending)

  $pendingFormatIssues = @()
  $pendingWarnings = @()

  foreach ($card in $Pending) {
    $frontmatter = Get-HandoffFrontmatterStatus -Path $card.FullName
    if (-not $frontmatter.HasFrontmatter -or $frontmatter.Status -ne "pending") {
      $pendingFormatIssues += [PSCustomObject]@{
        File = $card.Name
        Issue = "待接手卡 frontmatter status 应为 pending"
      }
    }

    if (-not (Test-HandoffTimestampName -File $card)) {
      $pendingFormatIssues += [PSCustomObject]@{
        File = $card.Name
        Issue = "文件名缺少 YYYY-MM-DD-HHMM 前缀"
      }
    }

    $text = Get-Content -LiteralPath $card.FullName -Raw -Encoding UTF8
    $headingMatches = @([regex]::Matches($text, '(?m)^##\s*([①②③④⑤⑥])'))
    $headingMap = @{}
    foreach ($hm in $headingMatches) {
      $marker = $hm.Groups[1].Value
      if (-not $headingMap.ContainsKey($marker)) { $headingMap[$marker] = $hm.Index }
    }

    $missingMarkers = @()
    foreach ($marker in @("①", "②", "③", "④", "⑤", "⑥")) {
      if (-not $headingMap.ContainsKey($marker)) { $missingMarkers += $marker }
    }
    if ($missingMarkers.Count -gt 0) {
      $pendingFormatIssues += [PSCustomObject]@{
        File = $card.Name
        Issue = "缺少完整交接卡基础标题：$($missingMarkers -join ', ')"
      }
    } else {
      $lastIndex = -1
      foreach ($marker in @("①", "②", "③", "④", "⑤", "⑥")) {
        if ([int]$headingMap[$marker] -le $lastIndex) {
          $pendingFormatIssues += [PSCustomObject]@{
            File = $card.Name
            Issue = "交接卡基础标题顺序异常：$marker"
          }
          break
        }
        $lastIndex = [int]$headingMap[$marker]
      }
    }

    $warningSectionMatch = [regex]::Match($text, '(?ms)^##\s*⑤.*?(?=^##\s*⑥)')
    $warningSection = if ($warningSectionMatch.Success) { $warningSectionMatch.Value } else { "" }
    $statusMatch = [regex]::Match($warningSection, '(?m)^\s*(?:[-*>|]\s*)?(?:\*\*)?Status(?:\*\*)?\s*[:：]\s*(?:\*\*)?\s*(DONE|BLOCKED|HANDOFF|RISK|OBSERVE)(?:\*\*)?\s*$')
    if (-not $statusMatch.Success) {
      $pendingFormatIssues += [PSCustomObject]@{
        File = $card.Name
        Issue = "⑤ 警戒段缺少合法 Status 字段（DONE / BLOCKED / HANDOFF / RISK / OBSERVE）"
      }
    }

    $mentionsFramework = $text -match '操作系统/|能力资产/|状态\.md|交接区/'
    $mentionsSizeRule = $text -match '6500B|8KB|大文件|字节|PROP-013|ADR-017'
    if ($mentionsFramework -and -not $mentionsSizeRule) {
      $pendingWarnings += [PSCustomObject]@{
        File = $card.Name
        Issue = "涉及 framework 路径但未提及文件大小/PROP-013/ADR-017 复核；当前仅提示，不阻断"
      }
    }
  }

  [PSCustomObject]@{
    FormatIssues = @($pendingFormatIssues)
    Warnings = @($pendingWarnings)
  }
}

function Get-DoneHandoffMetadataIssues {
  param([object[]]$DoneCards)

  $donePendingMetadata = @()
  $doneReceiveLanguage = @()

  foreach ($card in $DoneCards) {
    $frontmatter = Get-HandoffFrontmatterStatus -Path $card.FullName
    if ($frontmatter.HasFrontmatter -and $frontmatter.Status -eq "pending") {
      $donePendingMetadata += [PSCustomObject]@{
        File = $card.Name
        Issue = "已接手卡 frontmatter 仍为 status: pending"
      }
    }

    $text = Get-Content -LiteralPath $card.FullName -Raw -Encoding UTF8
    $todoMatch = [regex]::Match($text, '(?ms)^##\s*④.*?(?=^##\s*[⑤⑥⑦]|\z)')
    $todoText = if ($todoMatch.Success) { $todoMatch.Value } else { "" }
    $activeReceiveTodos = @($todoText -split "`n" | Where-Object {
      $_ -match '^\s*-\s*\[\s\].*(接收本卡时|接收本卡后|如果接收|待接收改成已接收|当前唯一待接手卡是本卡)'
    })
    if ($activeReceiveTodos.Count -gt 0) {
      $doneReceiveLanguage += [PSCustomObject]@{
        File = $card.Name
        Issue = "已接手卡仍含未完成的待接收动作提示"
      }
    }
  }

  [PSCustomObject]@{
    PendingMetadata = @($donePendingMetadata)
    ReceiveLanguage = @($doneReceiveLanguage)
  }
}
