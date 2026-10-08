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
        Issue = "Pending card frontmatter status must be pending"
      }
    }

    if (-not (Test-HandoffTimestampName -File $card)) {
      $pendingFormatIssues += [PSCustomObject]@{
        File = $card.Name
        Issue = "Filename is missing the YYYY-MM-DD-HHMM prefix"
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
        Issue = "Required base handoff card headings are missing: $($missingMarkers -join ', ')"
      }
    } else {
      $lastIndex = -1
      foreach ($marker in @("①", "②", "③", "④", "⑤", "⑥")) {
        if ([int]$headingMap[$marker] -le $lastIndex) {
          $pendingFormatIssues += [PSCustomObject]@{
            File = $card.Name
            Issue = "Base handoff card headings are out of order: $marker"
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
        Issue = "⑤ Warning section is missing a valid Status field (DONE / BLOCKED / HANDOFF / RISK / OBSERVE)"
      }
    }

    $mentionsFramework = $text -match '操作系统/|能力资产/|状态\.md|交接区/'
    $mentionsSizeRule = $text -match '6500B|8KB|大文件|字节|PROP-013|ADR-017|\blarge files?\b|\bbytes\b'
    if ($mentionsFramework -and -not $mentionsSizeRule) {
      $pendingWarnings += [PSCustomObject]@{
        File = $card.Name
        Issue = "Framework paths are involved but file-size/PROP-013/ADR-017 review is not mentioned; warning only, nonblocking"
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
        Issue = "Accepted card frontmatter still has status: pending"
      }
    }

    $text = Get-Content -LiteralPath $card.FullName -Raw -Encoding UTF8
    $todoMatch = [regex]::Match($text, '(?ms)^##\s*④.*?(?=^##\s*[⑤⑥⑦]|\z)')
    $todoText = if ($todoMatch.Success) { $todoMatch.Value } else { "" }
    $activeReceiveTodos = @($todoText -split "`n" | Where-Object {
      $_ -match '^\s*-\s*\[\s\].*(接收本卡时|接收本卡后|如果接收|待接收改成已接收|当前唯一待接手卡是本卡|\bwhen receiving this card\b|\bafter receiving this card\b|\bif receiving this card\b|\bchange pending to accepted\b|\bthis is the only pending card\b)'
    })
    if ($activeReceiveTodos.Count -gt 0) {
      $doneReceiveLanguage += [PSCustomObject]@{
        File = $card.Name
        Issue = "Accepted card still contains an unfinished pending-receipt action prompt"
      }
    }
  }

  [PSCustomObject]@{
    PendingMetadata = @($donePendingMetadata)
    ReceiveLanguage = @($doneReceiveLanguage)
  }
}
