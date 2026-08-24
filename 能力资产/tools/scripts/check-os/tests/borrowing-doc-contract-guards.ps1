$ErrorActionPreference = 'Stop'

function Test-BorrowingExactActionItem {
  param([string]$Text, [string]$Action)
  $scan = Get-BorrowingMarkdownScan $Text
  for ($index = 0; $index -lt $scan.Lines.Count; $index++) {
    if (-not $scan.OutsideFence[$index]) { continue }
    $line = $scan.Lines[$index]
    $normalized = $line.Trim().Replace('`', '')
    if ($normalized -notmatch '^[-*]\s+(.+?)\s*[。；;]?$') { continue }
    if ($Matches[1].Trim() -ceq $Action) { return $true }
  }
  return $false
}

function Assert-BorrowingActionOwnership {
  param(
    [hashtable]$Sections, [string]$Owner,
    [string[]]$Actions, [string]$Context
  )
  foreach ($action in $Actions) {
    Assert-CzxtTrue (Test-BorrowingExactActionItem $Sections[$Owner] $action) `
      ("{0} missing exact action item from {1}: {2}" -f $Context, $Owner, $action)
    foreach ($other in $Sections.Keys) {
      if ($other -eq $Owner) { continue }
      Assert-CzxtTrue (-not (Test-BorrowingExactActionItem $Sections[$other] $action)) `
        ("{0} misclassified action item in {1}: {2}" -f $Context, $other, $action)
    }
  }
}

function Test-BorrowingCellInSet {
  param([string]$Cell, [string[]]$Values)
  foreach ($value in $Values) {
    if ($Cell -ceq $value) { return $true }
  }
  return $false
}

function Test-BorrowingCellSequence {
  param([string[]]$Row, [string[]]$Sequence)
  if ($Sequence.Count -gt $Row.Count) { return $false }
  for ($start = 0; $start -le $Row.Count - $Sequence.Count; $start++) {
    $same = $true
    for ($offset = 0; $offset -lt $Sequence.Count; $offset++) {
      if ($Row[$start + $offset] -cne $Sequence[$offset]) { $same = $false; break }
    }
    if ($same) { return $true }
  }
  return $false
}

function ConvertTo-BorrowingPlainMarkdownCell {
  param([string]$Cell)
  $value = $Cell.Trim()
  for ($pass = 0; $pass -lt 8; $pass++) {
    $before = $value
    $match = [regex]::Match($value, '^\[(?<label>[^\]]+)\]\([^)]+\)$')
    if ($match.Success) { $value = $match.Groups['label'].Value.Trim() }
    elseif ($value -match '^`+(?<inner>.*?)`+$') { $value = $Matches['inner'].Trim() }
    elseif ($value -match '^\*\*(?<inner>.+)\*\*$') { $value = $Matches['inner'].Trim() }
    elseif ($value -match '^__(?<inner>.+)__$') { $value = $Matches['inner'].Trim() }
    elseif ($value -match '^\*(?<inner>.+)\*$') { $value = $Matches['inner'].Trim() }
    elseif ($value -match '^_(?<inner>.+)_$') { $value = $Matches['inner'].Trim() }
    if ($value -ceq $before) { break }
  }
  return $value
}

function Assert-BorrowingReadmeProjectionOnly {
  param([string]$Text, [string]$Context)
  $headingPattern = '^(?:(?:当前|活跃)\s*)?' +
    '(?:来源(?:\s*[/、与]\s*事项)?|事项(?:\s*[/、与]\s*来源)?)' +
    '(?:清单|列表|台账|索引)\s*$'
  $scan = Get-BorrowingMarkdownScan $Text
  for ($lineIndex = 0; $lineIndex -lt $scan.Lines.Count; $lineIndex++) {
    if (-not $scan.OutsideFence[$lineIndex]) { continue }
    $atx = [regex]::Match($scan.Lines[$lineIndex], '^[ ]{0,3}#{1,6}[ \t]+(?<body>.*?)(?:[ \t]+#+)?[ \t]*$')
    if (-not $atx.Success) { continue }
    $plainHeading = ConvertTo-BorrowingPlainMarkdownCell $atx.Groups['body'].Value
    Assert-CzxtTrue (-not [regex]::IsMatch($plainHeading, $headingPattern)) `
      ("active inventory heading in {0}: {1}" -f $Context, $plainHeading)
  }

  $identity = @(
    'source_id', 'borrow_id', '来源', '事项', '名称', '参考源', '参考来源',
    '来源 ID', '事项 ID', '来源标识', '事项标识', '来源名称', '事项名称'
  )
  $versionState = @(
    'capture_id', 'fingerprint', 'lifecycle_status', 'decision',
    '版本', '捕获', '状态', '决策', '来源版本', '事项状态'
  )
  $forbiddenHeaders = @(
    @('权限字段', '允许值', '默认值'),
    @('权限维度', '生效值', '授权时间', '授权来源', '适用范围'),
    @('lifecycle_status', '允许 decision', '必须满足'),
    @('旧状态', '新状态', 'decision/条件')
  )
  foreach ($row in @(Get-BorrowingTableRows $Text)) {
    $plainRow = @($row | ForEach-Object { ConvertTo-BorrowingPlainMarkdownCell $_ })
    $hasIdentity = $false
    $hasVersionState = $false
    foreach ($cell in $plainRow) {
      if (Test-BorrowingCellInSet $cell $identity) { $hasIdentity = $true }
      if (Test-BorrowingCellInSet $cell $versionState) { $hasVersionState = $true }
    }
    Assert-CzxtTrue (-not ($hasIdentity -and $hasVersionState)) `
      ("{0} contains active identity/version-state table: {1}" -f $Context, ($plainRow -join ' | '))
    foreach ($header in $forbiddenHeaders) {
      Assert-CzxtTrue (-not (Test-BorrowingCellSequence $plainRow $header)) `
        ("{0} contains normative table header: {1}" -f $Context, ($header -join ' | '))
    }
  }
}

function Assert-BorrowingWorkflowTriggerProjection {
  param([string]$Text)
  $target = '[借鉴闭环.md](借鉴闭环.md)'
  $table = Get-BorrowingMarkdownTableByHeader $Text @('触发', '进入哪个 workflow') 'workflow trigger table'
  $matches = @()
  foreach ($row in @($table.Rows)) {
    if ($row.Count -eq 2 -and $row[1] -ceq $target) { $matches += ,$row }
  }
  Assert-CzxtEqual 1 $matches.Count 'workflow borrowing trigger row count'
  $triggerCell = $matches[0][0]
  foreach ($word in @('借鉴', '参考', '对标', '吸收')) {
    Assert-CzxtTrue $triggerCell.Contains($word) ("workflow trigger cell missing: {0}" -f $word)
  }
}
