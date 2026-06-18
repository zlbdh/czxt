function Assert-OsCheckPlan {
  param(
    [object[]]$Plan,
    [string]$ScriptsRoot = (Split-Path -Parent $PSScriptRoot)
  )

  $sections = @($Plan)
  $checks = @($sections | ForEach-Object { $_.Checks })
  $ids = @($sections | ForEach-Object {
    $m = [regex]::Match($_.Title, '【(P4[a-s])】')
    if ($m.Success) { $m.Groups[1].Value }
  })
  $expected = @(
    "P4a", "P4b", "P4c", "P4d", "P4e", "P4f", "P4g", "P4h", "P4i",
    "P4j", "P4k", "P4l", "P4m", "P4n", "P4o", "P4p", "P4q", "P4r", "P4s"
  )

  $issues = New-Object System.Collections.Generic.List[string]
  foreach ($id in $expected) {
    if ($ids -notcontains $id) { $issues.Add("缺少 $id section") }
  }
  foreach ($group in @($ids | Group-Object | Where-Object { $_.Count -gt 1 })) {
    $issues.Add("重复 section：$($group.Name)")
  }
  foreach ($section in $sections) {
    $m = [regex]::Match($section.Title, '【(P4[a-s])】')
    if (-not $m.Success) { continue }
    $prefix = $m.Groups[1].Value.ToLowerInvariant()
    foreach ($check in @($section.Checks)) {
      $script = [string]$check.Script
      if ($script -notmatch "^check-os\\$prefix-") {
        $issues.Add("$($m.Groups[1].Value) 脚本前缀不匹配：$script")
      }
      if (-not (Test-Path -LiteralPath (Join-Path $ScriptsRoot $script) -PathType Leaf)) {
        $issues.Add("计划脚本不存在：$script")
      }
    }
  }
  foreach ($group in @($checks.Script | Group-Object | Where-Object { $_.Count -gt 1 })) {
    $issues.Add("重复脚本：$($group.Name)")
  }

  $p4d = @($checks | Where-Object { $_.Script -eq "check-os\p4d-state-freshness.ps1" })
  if ($p4d.Count -ne 1 -or $p4d[0].After -ne "StateStale") {
    $issues.Add("P4d 必须声明 After=StateStale")
  }
  if (@($checks | Where-Object { $_.Script -eq "check-os\p4e-mount-cache-reminder.ps1" }).Count -ne 1) {
    $issues.Add("P4e mount 提醒必须执行一次")
  }
  if (@($checks | Where-Object { $_.Script -like "check-os\p4h-*" }).Count -ne 2) {
    $issues.Add("P4h 必须包含版本/Sprint与台账双脚本")
  }
  if (@($checks | Where-Object { $_.Script -like "check-os\p4k-*-legacy.ps1" }).Count -ne 3) {
    $issues.Add("P4k 必须包含入口、角色边界、工具主语三脚本")
  }
  $p4a = @($checks | Where-Object { $_.Script -eq "check-os\p4a-basic-integrity.ps1" })
  if ($p4a.Count -ne 1 -or $p4a[0].Args -ne "P4aPasses") {
    $issues.Add("P4a 必须写入 Passes 计数")
  }

  if ($issues.Count -gt 0) {
    throw "P4 check plan 自校验失败：$($issues -join '；')"
  }
}
