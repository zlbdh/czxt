function Get-AppSrcP4bMeta {
  param([string]$Rel)

  $Rel = $Rel.Replace('\', '/')
  $appPattern = [regex]::Escape('{{APP_REPO_DIR}}'.Replace('\', '/'))
  $kind = if ($Rel -match '[\\/]__tests__[\\/]|\.test\.(js|jsx|ts|tsx)$') { "test" } else { "prod" }
  $domain = if ($Rel -match ('^' + $appPattern + '/src/features/([^/]+)')) { "features/$($matches[1])" }
    elseif ($Rel -match ('^' + $appPattern + '/src/shared/([^/]+)')) { "shared/$($matches[1])" }
    elseif ($Rel -match ('^' + $appPattern + '/src/([^/]+)')) { "src/$($matches[1])" }
    else { "src" }
  [PSCustomObject]@{ Kind = $kind; Domain = $domain }
}

function Get-P4bSizeLevel {
  param([long]$Size)

  if ($Size -ge 8000) {
    return [PSCustomObject]@{ Level = "danger"; Counter = "Danger"; Tag = "🔴"; Note = "Cowork danger; splitting is advisory for all tools" }
  }
  if ($Size -ge 6500) {
    return [PSCustomObject]@{ Level = "soft"; Counter = "Soft"; Tag = "🟡"; Note = "Cowork advisory: write with Python/Bash" }
  }
  if ($Size -ge 6000) {
    return [PSCustomObject]@{ Level = "warn"; Counter = "Warn"; Tag = "🟢"; Note = "Cowork caution zone" }
  }
  return [PSCustomObject]@{ Level = "safe"; Counter = "Safe"; Tag = ""; Note = "" }
}

function Add-P4bSizeFinding {
  param(
    [string]$Rel,
    [long]$Size,
    [string]$Scope,
    [hashtable]$SizeStats,
    [hashtable]$AreaStats,
    [object]$Warnings,
    [object]$SizeList,
    [object]$BusinessDebtList
  )

  $level = Get-P4bSizeLevel -Size $Size
  $SizeStats[$level.Counter]++
  $AreaStats[$Scope][$level.Counter]++
  if ($level.Level -eq "safe") { return }

  [void]$Warnings.Add("$($level.Tag) $Rel ${Size}B ($($level.Note))")
  [void]$SizeList.Add([PSCustomObject]@{ Size = $Size; Tag = $level.Tag; Rel = $Rel; Note = $level.Note })
  $appPattern = [regex]::Escape('{{APP_REPO_DIR}}'.Replace('\', '/'))
  if ($Rel.Replace('\', '/') -match ('^' + $appPattern + '/src/') -and @("danger", "soft") -contains $level.Level) {
    $meta = Get-AppSrcP4bMeta -Rel $Rel
    [void]$BusinessDebtList.Add([PSCustomObject]@{ Size = $Size; Level = $level.Level; Kind = $meta.Kind; Domain = $meta.Domain; Rel = $Rel })
  }
}
