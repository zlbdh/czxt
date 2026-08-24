$ErrorActionPreference = 'Stop'

function global:Get-BorrowingP4tItemReferences {
  param([string]$Root, $Failures)
  $references = New-Object 'Collections.Generic.List[object]'
  $items = Join-Path $Root '借鉴区\事项'
  if (-not (Test-Path -LiteralPath $items -PathType Container)) { return $references.ToArray() }
  foreach ($directory in @(Get-ChildItem -LiteralPath $items -Directory -Force)) {
    try {
      $card = Join-Path $directory.FullName '借鉴卡.md'
      [byte[]]$bytes = Read-BorrowingStableSafeFileBytes $card p4t-source source-unsafe
      $text = (New-Object Text.UTF8Encoding($false, $true)).GetString($bytes)
      $statusMatches = [regex]::Matches($text, '(?m)^lifecycle_status: ([a-z_]+)$')
      if ($statusMatches.Count -ne 1) { throw 'item status invalid' }
      $status = $statusMatches[0].Groups[1].Value
      $section = [regex]::Match($text,
        '(?ms)^## 来源绑定\n.*?^\|---\|---\|---\|---\|\n(?<rows>(?:\| .*? \|\n)+)')
      if (-not $section.Success) { throw 'item bindings invalid' }
      foreach ($line in @($section.Groups['rows'].Value.TrimEnd("`n").Split("`n"))) {
        [string[]]$cells = ConvertFrom-BcvCardRow $line 4
        [void]$references.Add([pscustomobject]@{
            SourceId = $cells[0]; CaptureId = $cells[1]; Fingerprint = $cells[2]
            Status = $status; ItemId = $directory.Name
          })
      }
    }
    catch { Add-BorrowingP4tSourceIssue $Failures ('无法安全验证事项来源引用：' + $directory.Name) }
  }
  return $references.ToArray()
}
