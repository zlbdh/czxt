$ErrorActionPreference = "Stop"

function Get-HandoffFileListIssues {
  param(
    [string]$Root,
    [object[]]$Pending
  )

  $issues = @()
  foreach ($card in $Pending) {
    $text = Get-Content -LiteralPath $card.FullName -Raw -Encoding UTF8
    $sectionMatch = [regex]::Match($text, '(?ms)^##\s*②.*?(?=^##\s*[③④⑤⑥⑦]|$)')
    if (-not $sectionMatch.Success) { continue }

    foreach ($line in ($sectionMatch.Value -split "`r?`n")) {
      if ($line -match '删除|移除|removed|delete') { continue }
      foreach ($match in [regex]::Matches($line, '`([^`]+)`')) {
        $rel = $match.Groups[1].Value.Trim()
        if ($rel -match '^(https?|file)://') { continue }
        if ($rel -match '[*?<>|]') { continue }
        if ($rel -notmatch '[\\/]' -and $rel -notmatch '\.[A-Za-z0-9]{1,8}$') { continue }

        $norm = $rel -replace '/', '\'
        $path = if ([System.IO.Path]::IsPathRooted($norm)) { $norm } else { Join-Path $Root $norm }
        if (-not (Test-Path -LiteralPath $path)) {
          $issues += [PSCustomObject]@{
            File = $card.Name
            Issue = "② 文件变更路径不存在：$rel"
          }
        }
      }
    }
  }

  return @($issues)
}
