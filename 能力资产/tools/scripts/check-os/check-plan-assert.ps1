function Assert-OsCheckPlan {
  param(
    [object[]]$Plan,
    [string]$ScriptsRoot = (Split-Path -Parent $PSScriptRoot)
  )

  $sections = @($Plan)
  $checks = @($sections | ForEach-Object { $_.Checks })
  $ids = @($sections | ForEach-Object {
    $m = [regex]::Match($_.Title, '【(P4[a-t])】')
    if ($m.Success) { $m.Groups[1].Value }
  })
  $expected = @(
    "P4a", "P4b", "P4c", "P4d", "P4e", "P4f", "P4g", "P4h", "P4i",
    "P4j", "P4k", "P4l", "P4m", "P4n", "P4o", "P4p", "P4q", "P4r", "P4s", "P4t"
  )

  $issues = New-Object System.Collections.Generic.List[string]
  foreach ($id in $expected) {
    if ($ids -notcontains $id) { $issues.Add("Missing $id section") }
  }
  foreach ($group in @($ids | Group-Object | Where-Object { $_.Count -gt 1 })) {
    $issues.Add("Duplicate section: $($group.Name)")
  }
  foreach ($section in $sections) {
    $m = [regex]::Match($section.Title, '【(P4[a-t])】')
    if (-not $m.Success) { continue }
    $prefix = $m.Groups[1].Value.ToLowerInvariant()
    foreach ($check in @($section.Checks)) {
      $script = [string]$check.Script
      if ($script -notmatch "^check-os\\$prefix-") {
        $issues.Add("$($m.Groups[1].Value) script prefix mismatch: $script")
      }
      if (-not (Test-Path -LiteralPath (Join-Path $ScriptsRoot $script) -PathType Leaf)) {
        $issues.Add("Planned script does not exist: $script")
      }
    }
  }
  foreach ($group in @($checks.Script | Group-Object | Where-Object { $_.Count -gt 1 })) {
    $issues.Add("Duplicate script: $($group.Name)")
  }

  $p4d = @($checks | Where-Object { $_.Script -eq "check-os\p4d-state-freshness.ps1" })
  if ($p4d.Count -ne 1 -or $p4d[0].After -ne "StateStale") {
    $issues.Add("P4d must declare After=StateStale")
  }
  if (@($checks | Where-Object { $_.Script -eq "check-os\p4e-mount-cache-reminder.ps1" }).Count -ne 1) {
    $issues.Add("The P4e mount reminder must run exactly once")
  }
  if (@($checks | Where-Object { $_.Script -like "check-os\p4h-*" }).Count -ne 2) {
    $issues.Add("P4h must include both version/Sprint and ledger scripts")
  }
  if (@($checks | Where-Object { $_.Script -like "check-os\p4k-*-legacy.ps1" }).Count -ne 3) {
    $issues.Add("P4k must include entry, role-boundary, and tool-subject scripts")
  }
  $p4a = @($checks | Where-Object { $_.Script -eq "check-os\p4a-basic-integrity.ps1" })
  if ($p4a.Count -ne 1 -or $p4a[0].Args -ne "P4aPasses") {
    $issues.Add("P4a must record the Passes count")
  }
  $p4t = @($checks | Where-Object { $_.Script -eq "check-os\p4t-borrowing-consistency.ps1" })
  if ($p4t.Count -ne 1) {
    $issues.Add("The P4t borrowing completion facade must run exactly once")
  }

  if ($issues.Count -gt 0) {
    throw "P4 check plan self-check failed: $($issues -join '；')"
  }
}
