$ErrorActionPreference = 'Stop'

function global:ConvertFrom-BpiOffsetTime {
  param([string]$Value)
  if ($Value -cnotmatch
      '\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,7})?(?:Z|[+-][0-9]{2}:[0-9]{2})\z') {
    throw 'item timestamp format invalid'
  }
  $parsed = [DateTimeOffset]::MinValue
  if (-not [DateTimeOffset]::TryParse(
      $Value, [Globalization.CultureInfo]::InvariantCulture,
      [Globalization.DateTimeStyles]::None, [ref]$parsed)) {
    throw 'item timestamp value invalid'
  }
  return $parsed
}

function global:Test-BpiStateDecision {
  param([string]$Status, [string]$Decision)
  $allowed = switch ($Status) {
    'draft' { @('pending') }
    'assessing' { @('pending', 'adopt', 'adapt', 'reject', 'defer') }
    'implementation_ready' { @('adopt', 'adapt') }
    'implementing' { @('adopt', 'adapt') }
    'verifying' { @('adopt', 'adapt') }
    'closed' { @('adopt', 'adapt', 'reject') }
    'parked' { @('defer') }
    'cancelled' { @('pending', 'adopt', 'adapt', 'reject', 'defer') }
    default { @() }
  }
  return $allowed -ccontains $Decision
}

function global:Test-BpiHistoryTransition {
  param([string]$Old, [string]$New, [string]$Decision)
  if ($Old -ceq 'none') { return $New -ceq 'draft' -and $Decision -ceq 'pending' }
  $active = @('draft', 'assessing', 'implementation_ready', 'implementing', 'verifying', 'parked')
  if ($New -ceq 'cancelled') { return $active -ccontains $Old }
  if ($Old -ceq $New) {
    return $active -ccontains $New -and (Test-BpiStateDecision $New $Decision)
  }
  if ($Old -ceq 'draft' -and $New -ceq 'assessing') {
    return Test-BpiStateDecision $New $Decision
  }
  if ($Old -ceq 'assessing') {
    if ($New -ceq 'implementation_ready') { return $Decision -in @('adopt', 'adapt') }
    if ($New -ceq 'parked') { return $Decision -ceq 'defer' }
    if ($New -ceq 'closed') { return $Decision -ceq 'reject' }
  }
  if ($Old -ceq 'parked' -and $New -ceq 'assessing') {
    return Test-BpiStateDecision $New $Decision
  }
  if ($Old -ceq 'implementation_ready' -and $New -ceq 'implementing') {
    return $Decision -in @('adopt', 'adapt')
  }
  if ($Old -ceq 'implementing' -and $New -ceq 'verifying') {
    return $Decision -in @('adopt', 'adapt')
  }
  if ($Old -ceq 'verifying' -and $New -ceq 'closed') {
    return $Decision -in @('adopt', 'adapt')
  }
  return $false
}

function global:Assert-BpiItemHistory {
  param($Card)
  if (-not (Test-BpiStateDecision $Card.Status $Card.Decision)) {
    throw 'item status and decision combination invalid'
  }
  $created = ConvertFrom-BpiOffsetTime $Card.CreatedAt
  $updated = ConvertFrom-BpiOffsetTime $Card.UpdatedAt
  if ($updated -lt $created) { throw 'item updated_at moved backwards' }
  if ($Card.HistoryRows.Count -eq 0) { throw 'item history is empty' }
  $previousTime = $null
  $previousState = $null
  for ($index = 0; $index -lt $Card.HistoryRows.Count; $index++) {
    [string[]]$cells = $Card.HistoryRows[$index].Cells
    $time = ConvertFrom-BpiOffsetTime $cells[0]
    if ($null -ne $previousTime -and $time -lt $previousTime) {
      throw 'item history time moved backwards'
    }
    if ($index -eq 0) {
      if ($cells[1] -cne 'none' -or $cells[2] -cne 'draft' -or
          $cells[3] -cne 'pending' -or $cells[0] -cne $Card.CreatedAt) {
        throw 'item initial history invalid'
      }
    }
    elseif ($cells[1] -cne $previousState) { throw 'item history chain is broken' }
    if (-not (Test-BpiHistoryTransition $cells[1] $cells[2] $cells[3])) {
      throw 'item history transition invalid'
    }
    $previousTime = $time
    $previousState = $cells[2]
  }
  [string[]]$last = $Card.HistoryRows[$Card.HistoryRows.Count - 1].Cells
  if ($last[2] -cne $Card.Status -or $last[3] -cne $Card.Decision -or
      $last[0] -cne $Card.UpdatedAt) { throw 'item history tail mismatches frontmatter' }
}

function global:Assert-BpiBlockedContract {
  param($Card)
  [string[]]$cells = $Card.BlockedRow.Cells
  $terminal = $Card.Status -in @('closed', 'cancelled')
  if ($Card.Blocked) {
    if ($terminal -or $cells[0].Length -eq 0 -or $cells[1].Length -eq 0 -or
        $cells[2].Length -eq 0 -or
        $cells[0] -notin @(
          'draft', 'assessing', 'implementation_ready', 'implementing', 'verifying', 'parked')) {
      throw 'item blocked fields invalid'
    }
  }
  elseif ($cells[0].Length -gt 0 -or $cells[1].Length -gt 0 -or $cells[2].Length -gt 0) {
    throw 'unblocked item retains blocked fields'
  }
}

function global:Assert-BpiItemStateContract {
  param($Card, [string]$Root, [switch]$AllowEmptyClosedSeal)
  Assert-BpiItemHistory $Card
  Assert-BpiBlockedContract $Card
  Assert-BpiClosureContract $Card $Root -AllowEmptyClosedSeal:$AllowEmptyClosedSeal
}
