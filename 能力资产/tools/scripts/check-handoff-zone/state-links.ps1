$ErrorActionPreference = "Stop"

function Get-HandoffSortValue {
  param([System.IO.FileInfo]$File)

  $m = [regex]::Match($File.BaseName, '^(?<d>\d{4}-\d{2}-\d{2})-(?<t>\d{4})-')
  if ($m.Success) {
    try {
      return [datetime]::ParseExact(
        "$($m.Groups['d'].Value)-$($m.Groups['t'].Value)",
        "yyyy-MM-dd-HHmm",
        [System.Globalization.CultureInfo]::InvariantCulture
      )
    } catch {}
  }

  return $File.LastWriteTime
}

function Get-HandoffStateIssues {
  param(
    [string]$Root,
    [object[]]$Pending
  )

  $stateBrokenLinks = @()
  $stateTopIssues = @()
  $stateFile = Join-Path $Root "状态.md"

  if (Test-Path -LiteralPath $stateFile) {
    $lines = Get-Content -LiteralPath $stateFile -Encoding UTF8
    $pattern = '交接区[\\/](?:待接手|已接手|历史归档)[\\/][^\s`)\]]+\.md'
    for ($i = 0; $i -lt $lines.Count; $i++) {
      foreach ($match in [regex]::Matches($lines[$i], $pattern)) {
        $rel = ($match.Value -replace '\\', '/').TrimEnd('.', '。', ',', '，', ';', '；', ':', '：')
        $path = Join-Path $Root ($rel -replace '/', '\')
        if (-not (Test-Path -LiteralPath $path)) {
          $fileName = Split-Path -Leaf $rel
          $actual = @(Get-ChildItem -LiteralPath (Join-Path $Root "交接区") -Recurse -File -Filter $fileName -ErrorAction SilentlyContinue | Select-Object -First 1)
          $to = if ($actual.Count -gt 0) { $actual[0].FullName.Substring($Root.Length).TrimStart('\') -replace '\\', '/' } else { "<未找到同名文件>" }
          $stateBrokenLinks += [PSCustomObject]@{
            Line = $i + 1
            From = $rel
            To = $to
          }
        }
      }
    }

    $topText = ($lines | Select-Object -First 80) -join "`n"
    if ($Pending.Count -gt 0) {
      $latestPending = $Pending | Sort-Object @{ Expression = { Get-HandoffSortValue $_ }; Descending = $true }, Name -Descending | Select-Object -First 1
      if ($topText -notmatch [regex]::Escape($latestPending.Name)) {
        $stateTopIssues += [PSCustomObject]@{
          File = $latestPending.Name
          Issue = "状态.md 顶部 80 行未指向最新待接手卡"
        }
      }
    } else {
      if ($topText -match '交接区[\\/]待接手[\\/][^\s`)\]]+\.md') {
        $stateTopIssues += [PSCustomObject]@{
          File = "无待接手"
          Issue = "待接手目录为空，但状态.md 顶部 80 行仍出现待接手卡路径"
        }
      }

      $doneDir = Join-Path $Root "交接区\已接手"
      if (Test-Path -LiteralPath $doneDir -PathType Container) {
        $latestDone = Get-ChildItem -LiteralPath $doneDir -File -Filter "*.md" -ErrorAction SilentlyContinue |
          Sort-Object @{ Expression = { Get-HandoffSortValue $_ }; Descending = $true }, Name -Descending |
          Select-Object -First 1
        if ($null -ne $latestDone -and $topText -notmatch [regex]::Escape($latestDone.Name) -and $topText -notmatch '无待接手|待接手\s*[:：]\s*0') {
          $stateTopIssues += [PSCustomObject]@{
            File = $latestDone.Name
            Issue = "状态.md 顶部 80 行未指向最新已接手卡，也未明确无待接手"
          }
        }
      }
    }
  }

  [PSCustomObject]@{
    BrokenLinks = @($stateBrokenLinks)
    TopIssues = @($stateTopIssues)
  }
}
