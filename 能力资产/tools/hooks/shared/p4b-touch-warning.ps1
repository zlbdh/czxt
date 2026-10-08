$ErrorActionPreference = "Stop"

function Get-P4bTouchedWarning {
  param(
    [string]$Root,
    [string[]]$Paths
  )

  if (-not $Paths -or $Paths.Count -eq 0) { return $null }
  $rootN = ([System.IO.Path]::GetFullPath($Root) -replace '\\', '/').TrimEnd('/')
  $hits = New-Object System.Collections.Generic.List[string]
  $seen = @{}

  foreach ($path in $Paths) {
    if ([string]::IsNullOrWhiteSpace($path)) { continue }
    try {
      if ([System.IO.Path]::IsPathRooted($path)) {
        $abs = [System.IO.Path]::GetFullPath($path)
      } else {
        $abs = [System.IO.Path]::GetFullPath((Join-Path $Root $path))
      }
    } catch {
      continue
    }
    $absN = $abs -replace '\\', '/'
    $rel = $absN
    if ($absN.StartsWith($rootN, [System.StringComparison]::OrdinalIgnoreCase)) {
      $rel = $absN.Substring($rootN.Length).TrimStart('/')
    }
    if (-not $rel.StartsWith("{{APP_REPO_DIR}}/src/", [System.StringComparison]::OrdinalIgnoreCase)) { continue }
    if (-not (Test-Path -LiteralPath $abs -PathType Leaf)) { continue }
    $key = $rel.ToLowerInvariant()
    if ($seen.ContainsKey($key)) { continue }
    $seen[$key] = $true

    $size = (Get-Item -LiteralPath $abs).Length
    if ($size -lt 6500) { continue }
    $level = if ($size -ge 8000) { "danger" } else { "soft" }
    [void]$hits.Add(("{0} {1}B {2}" -f $rel, $size, $level))
  }

  if ($hits.Count -eq 0) { return $null }
  $shown = @($hits | Select-Object -First 5)
  $more = if ($hits.Count -gt 5) { "; $($hits.Count - 5) more" } else { "" }
  return "🟡 Large business files touched: $($shown -join '；')$more. Development PM should assess splitting as part of feature work; do not change business code solely to clear counts."
}
