$ErrorActionPreference = 'Stop'

function global:Test-BpiSafeScalar {
  param([string]$Value, [bool]$AllowEmpty = $false)
  if ($null -eq $Value -or (-not $AllowEmpty -and $Value.Length -eq 0)) { return $false }
  try { $normalized = $Value.Normalize([Text.NormalizationForm]::FormC) }
  catch { return $false }
  return $normalized -ceq $Value -and
    $Value -notmatch '[\x00-\x1F\x7F-\x9F\u2028\u2029|`]' -and
    $Value -notmatch '[ \t]\z'
}

function global:Get-BpiSectionLines {
  param([string[]]$Lines, [string]$Heading)
  $indexes = @()
  for ($index = 0; $index -lt $Lines.Count; $index++) {
    if ($Lines[$index] -ceq $Heading) { $indexes += $index }
  }
  if ($indexes.Count -ne 1) { throw ('item section invalid: ' + $Heading) }
  $start = $indexes[0]
  $end = $Lines.Count
  for ($index = $start + 1; $index -lt $Lines.Count; $index++) {
    if ($Lines[$index].StartsWith('## ', [StringComparison]::Ordinal)) {
      $end = $index
      break
    }
  }
  if ($end -le $start) { throw ('item section is empty: ' + $Heading) }
  return [string[]]$Lines[$start..($end - 1)]
}

function global:ConvertFrom-BpiLooseRow {
  param([string]$Line, [int]$CellCount)
  if (-not $Line.StartsWith('| ', [StringComparison]::Ordinal) -or
      -not $Line.EndsWith(' |', [StringComparison]::Ordinal)) {
    throw 'item table row invalid'
  }
  [string[]]$cells = @($Line.Substring(2, $Line.Length - 4).Split(
      @(' | '), [StringSplitOptions]::None))
  if ($cells.Count -ne $CellCount -or
      ('| ' + ($cells -join ' | ') + ' |') -cne $Line) {
    throw 'item table cell count invalid'
  }
  foreach ($cell in $cells) {
    if (-not (Test-BpiSafeScalar $cell $true)) { throw 'item table cell unsafe' }
  }
  return ,$cells
}

function global:Get-BpiTableRows {
  param(
    [string[]]$Section,
    [string]$Header,
    [string]$Separator,
    [int]$CellCount,
    [switch]$AllowEmptyCells
  )
  $matches = @()
  for ($index = 0; $index -lt $Section.Count; $index++) {
    if ($Section[$index] -ceq $Header) { $matches += $index }
  }
  if ($matches.Count -ne 1 -or $matches[0] + 1 -ge $Section.Count -or
      $Section[$matches[0] + 1] -cne $Separator) {
    throw 'item table header invalid'
  }
  $rows = New-Object 'Collections.Generic.List[object]'
  for ($index = $matches[0] + 2; $index -lt $Section.Count; $index++) {
    $line = $Section[$index]
    if (-not $line.StartsWith('| ', [StringComparison]::Ordinal)) { break }
    [string[]]$cells = if ($AllowEmptyCells) {
      ConvertFrom-BpiLooseRow $line $CellCount
    }
    else { ConvertFrom-BcvCardRow $line $CellCount }
    [void]$rows.Add([pscustomobject]@{ Cells = $cells; Line = $line })
  }
  if ($rows.Count -eq 0) { throw 'item table has no data rows' }
  return $rows.ToArray()
}

function global:Read-BpiItemCard {
  param([string]$Path)
  $document = Read-BcvStrictUtf8Card -Path $Path
  [string[]]$keys = @(
    'schema', 'borrow_id', 'title', 'lifecycle_status', 'decision',
    'impact_level', 'owner_pm', 'blocked', 'created_at', 'updated_at',
    'supersedes', 'closure_seal_sha256'
  )
  if ($document.Lines.Count -lt 30 -or $document.Lines[0] -cne '---' -or
      $document.Lines[13] -cne '---') { throw 'item frontmatter boundary invalid' }
  $values = [ordered]@{}
  for ($index = 0; $index -lt $keys.Count; $index++) {
    $prefix = $keys[$index] + ': '
    $line = $document.Lines[$index + 1]
    if (-not $line.StartsWith($prefix, [StringComparison]::Ordinal)) {
      throw 'item frontmatter key order invalid'
    }
    $value = $line.Substring($prefix.Length)
    if (-not (Test-BpiSafeScalar $value)) { throw 'item frontmatter scalar unsafe' }
    $values[$keys[$index]] = $value
  }
  $supersedes = if ($values.supersedes -ceq '""') { '' }
    elseif ($values.supersedes -cmatch '\A"(?<id>[^"\\]+)"\z') { $Matches.id }
    else { throw 'item supersedes scalar invalid' }
  $seal = if ($values.closure_seal_sha256 -ceq '""') { '' }
    elseif ($values.closure_seal_sha256 -cmatch '\A[0-9a-f]{64}\z') {
      $values.closure_seal_sha256
    }
    else { throw 'item seal scalar invalid' }
  # 枚举直接锁定治理合同，避免任意字符串被误当成可写角色授权。
  $owners = @(
    'project-pm', 'sediment-pm', 'operating-system-pm', 'product-pm',
    'technical-pm', 'test-pm', 'operations-pm', 'development-pm', 'release-pm'
  )
  if ($values.schema -cne 'borrowing-item/v1' -or
      $values.borrow_id -cnotmatch '\Aborrow-[0-9]{8}-[a-z0-9](?:[a-z0-9._-]{0,126}[a-z0-9_-])?\z' -or
      $values.impact_level -notin @('L1', 'L2', 'L3', 'L4') -or
      $values.owner_pm -cnotin $owners -or
      $values.blocked -notin @('true', 'false')) {
    throw 'item public frontmatter invalid'
  }
  if ($supersedes.Length -gt 0 -and
      $supersedes -cnotmatch '\Aborrow-[0-9]{8}-[a-z0-9](?:[a-z0-9._-]{0,126}[a-z0-9_-])?\z') {
    throw 'item supersedes id invalid'
  }
  $formal = '- 正式路径：`借鉴区/事项/' + $values.borrow_id + '/借鉴卡.md`'
  if (@($document.Lines | Where-Object { $_ -ceq '# 借鉴卡' }).Count -ne 1 -or
      @($document.Lines | Where-Object { $_ -ceq $formal }).Count -ne 1) {
    throw 'item fixed identity body invalid'
  }
  $headings = @(
    '## 问题与成功标准', '## 来源绑定', '## 候选矩阵', '## 明确采纳',
    '## 明确不采纳', '## 目标与责任', '## 验收标准', '## 实施记录',
    '## fresh 验证证据', '## 状态历史', '## 阻塞信息'
  )
  $sections = [ordered]@{}
  foreach ($heading in $headings) {
    $sections[$heading] = @(Get-BpiSectionLines $document.Lines $heading)
  }
  $sourceRows = @(Get-BpiTableRows $sections['## 来源绑定'] `
      '| source_id | capture_id | fingerprint | 证据定位符 |' `
      '|---|---|---|---|' 4)
  $candidateRows = @(Get-BpiTableRows $sections['## 候选矩阵'] `
      '| 已有能力 | 可借鉴点 | 冲突 | 结论 | 理由 |' `
      '|---|---|---|---|---|' 5)
  $targetRows = @(Get-BpiTableRows $sections['## 目标与责任'] `
      '| 目标文件 | 责任 PM | 影响级别 | PROP/ADR |' `
      '|---|---|---|---|' 4)
  $historyRows = @(Get-BpiTableRows $sections['## 状态历史'] `
      '| 时间 | 旧状态 | 新状态 | decision | 原因 | 确认 |' `
      '|---|---|---|---|---|---|' 6)
  foreach ($row in $historyRows) {
    # 空原因已由表格标量拒绝；这里额外封住模板占位符及其装饰写法。
    if ($row.Cells[2] -ceq 'cancelled' -and
        $row.Cells[4].IndexOf('待填写', [StringComparison]::Ordinal) -ge 0) {
      throw 'cancelled item reason is placeholder'
    }
  }
  $blockedRows = @(Get-BpiTableRows $sections['## 阻塞信息'] `
      '| blocked_from | reason | resume_condition |' '|---|---|---|' 3 -AllowEmptyCells)
  if ($blockedRows.Count -ne 1) { throw 'item blocked table row count invalid' }
  return [pscustomobject][ordered]@{
    Path = $document.Path; Bytes = $document.Bytes; Text = $document.Text
    Lines = $document.Lines; BorrowId = $values.borrow_id; Title = $values.title
    Status = $values.lifecycle_status; Decision = $values.decision
    ImpactLevel = $values.impact_level; OwnerPm = $values.owner_pm
    Blocked = $values.blocked -ceq 'true'; CreatedAt = $values.created_at
    UpdatedAt = $values.updated_at; Supersedes = $supersedes
    ClosureSeal = $seal; ClosureSealRaw = $values.closure_seal_sha256
    Sections = $sections; SourceRows = $sourceRows; CandidateRows = $candidateRows
    TargetRows = $targetRows; HistoryRows = $historyRows
    BlockedRow = $blockedRows[0]
  }
}
