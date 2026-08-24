$ErrorActionPreference = 'Stop'

function global:New-BpiSourceIndex {
  param($SourceState, $Failures)
  $index = @{}
  if ($null -eq $SourceState -or
      $null -eq $SourceState.PSObject.Properties['ReadyCaptures'] -or
      $null -eq $SourceState.PSObject.Properties['RetiredCaptures']) {
    Add-BpiFailure $Failures '来源检查结果缺少 ready/retired capture 集合'
    return $index
  }
  if ($null -ne $SourceState.PSObject.Properties['Failures'] -and
      @($SourceState.Failures).Count -gt 0) {
    Add-BpiFailure $Failures '来源检查存在硬失败，事项引用不可判定'
  }
  foreach ($group in @(
      [pscustomobject]@{ Records = @($SourceState.ReadyCaptures); Ready = $true },
      [pscustomobject]@{ Records = @($SourceState.RetiredCaptures); Ready = $false })) {
    foreach ($record in $group.Records) {
      try {
        $sourceId = [string]$record.SourceId
        $captureId = [string]$record.CaptureId
        $fingerprint = [string]$record.Fingerprint
        [void](Assert-BcvIdentifier $sourceId)
        [void](Assert-BcvIdentifier $captureId)
        if ($fingerprint -cnotmatch '\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z') {
          throw 'source state fingerprint invalid'
        }
        $key = $sourceId + [char]0 + $captureId
        if ($index.ContainsKey($key)) { throw 'source state tuple duplicated' }
        $index[$key] = [pscustomobject]@{
          SourceId = $sourceId; CaptureId = $captureId; Fingerprint = $fingerprint
          IsReady = [bool]$group.Ready; Record = $record
        }
      }
      catch { Add-BpiFailure $Failures '来源检查结果包含无效 capture 记录' }
    }
  }
  return $index
}

function global:Test-BpiEvidenceLocator {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
  $uri = $null
  if ([Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri)) {
    if ($uri.Scheme -cne 'https' -or -not [string]::IsNullOrEmpty($uri.UserInfo)) {
      return $false
    }
    if (-not [string]::IsNullOrEmpty($uri.Query)) {
      try { $query = [Uri]::UnescapeDataString($uri.Query.Substring(1)) }
      catch { return $false }
      # 普通公开查询可保留，但凭据参数名即使经过 URL 编码也不得进入事项卡。
      $credentialName = '(?i)(?:(?:\A|[._-])(?:token|key|secret|password|credential|credentials|auth|authorization)(?:\z|[._-])|\A(?:access|refresh|id|bearer|api|client)(?:token|key|secret)\z)'
      foreach ($part in @($query -split '[&;]')) {
        if (($part -split '=', 2)[0] -match $credentialName) { return $false }
      }
    }
    return $true
  }
  if ($Value.StartsWith('/', [StringComparison]::Ordinal) -or $Value.Contains('\') -or
      $Value -match '^[A-Za-z]:' -or $Value.Contains('?') -or $Value.Contains('#')) {
    return $false
  }
  foreach ($segment in $Value.Split('/')) {
    if ($segment.Length -eq 0 -or $segment -in @('.', '..')) { return $false }
  }
  return $true
}

function global:Assert-BpiSourceBindings {
  param($Card, $SourceIndex)
  if ($Card.SourceRows.Count -eq 0) { throw 'item has no source binding' }
  $seen = @{}
  $terminal = $Card.Status -in @('closed', 'cancelled')
  $requiredReuseScope = ''
  if (@('implementation_ready', 'implementing', 'verifying', 'closed') `
      -ccontains $Card.Status) {
    if ($Card.Decision -ceq 'adopt') { $requiredReuseScope = 'copy-internal-approved' }
    elseif ($Card.Decision -ceq 'adapt') { $requiredReuseScope = 'adapt-internal-approved' }
  }
  foreach ($row in $Card.SourceRows) {
    [string[]]$cells = $row.Cells
    [void](Assert-BcvIdentifier $cells[0])
    if ($cells[1] -in @('current', 'latest', 'HEAD') -or
        $cells[1] -cnotmatch '\A(?:git|local|web)-[0-9]{8}-[0-9a-f]{12}\z') {
      throw 'item capture binding is floating or invalid'
    }
    $key = $cells[0] + [char]0 + $cells[1]
    if ($seen.ContainsKey($key)) { throw 'item source binding duplicated' }
    $seen[$key] = $true
    $source = $SourceIndex[$key]
    if ($null -eq $source -or $source.Fingerprint -cne $cells[2]) {
      throw 'item source binding does not match source state'
    }
    if (-not $terminal -and -not $source.IsReady) {
      throw 'active item references retired capture'
    }
    # reuse_scope 是互不推导的独立授权；每个绑定都必须精确满足当前内部决策。
    if ($requiredReuseScope.Length -gt 0) {
      $permissions = $source.Record.PSObject.Properties['Permissions']
      if ($null -eq $permissions -or
          [string]$source.Record.Permissions.ReuseScope -cne $requiredReuseScope) {
        throw 'item decision exceeds source reuse scope'
      }
    }
    if (-not (Test-BpiEvidenceLocator $cells[3])) {
      throw 'item evidence locator invalid'
    }
  }
}

function global:Assert-BpiSupersedesGraph {
  param([object[]]$Cards)
  $index = @{}
  foreach ($card in $Cards) {
    if ($index.ContainsKey($card.BorrowId)) { throw 'item id duplicated in graph' }
    $index[$card.BorrowId] = $card
  }
  foreach ($origin in $Cards) {
    $seen = @{}
    $current = $origin
    while ($current.Supersedes.Length -gt 0) {
      if ($seen.ContainsKey($current.BorrowId)) { throw 'item supersedes cycle detected' }
      $seen[$current.BorrowId] = $true
      if (-not $index.ContainsKey($current.Supersedes)) {
        throw 'item supersedes target missing'
      }
      $target = $index[$current.Supersedes]
      # supersedes 表示终态事项的合法修订，不能拿仍可继续编辑的活动事项做前身。
      if ($target.Status -cnotin @('closed', 'cancelled')) {
        throw 'item supersedes target is not terminal'
      }
      $current = $target
    }
  }
}
