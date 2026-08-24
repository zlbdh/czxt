[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-item-test-support.ps1')

function Add-P4tValidItemCase {
  param([string]$Name, [string]$Root, [object[]]$Sources, $Item)
  return [pscustomobject]@{
    Name = $Name; Root = $Root; SourceState = New-P4tSourceState $Sources; Item = $Item
  }
}

Initialize-P4tTestFixture
try {
  $cases = @()
  $root = New-ProjectSkeleton 'item-valid-multi-source'
  $local = New-P4tSourceCapture $root local 'source-local'
  $web = New-P4tSourceCapture $root web 'source-web'
  $item = New-P4tItemCard $root 'borrow-20260719-multi' @($local, $web) assessing pending
  $cases += Add-P4tValidItemCase 'multi-source assessing' $root @($local, $web) $item

  $root = New-ProjectSkeleton 'item-valid-reject'
  $source = New-P4tSourceCapture $root local
  $item = New-P4tItemCard -Root $root -BorrowId 'borrow-20260719-reject' `
    -Bindings @($source) -Status closed -Decision reject -Seal $true
  $cases += Add-P4tValidItemCase 'reject closes with evidence and seal' $root @($source) $item

  $root = New-ProjectSkeleton 'item-valid-defer-resume'
  $source = New-P4tSourceCapture $root local
  $history = @(
    (New-P4tHistoryRow '2026-07-19T01:00:00+00:00' none draft pending),
    (New-P4tHistoryRow '2026-07-19T02:00:00+00:00' draft assessing pending),
    (New-P4tHistoryRow '2026-07-19T03:00:00+00:00' assessing parked defer),
    (New-P4tHistoryRow '2026-07-19T04:00:00+00:00' parked assessing pending '恢复条件满足')
  )
  $item = New-P4tItemCard -Root $root -BorrowId 'borrow-20260719-resume' `
    -Bindings @($source) -Status assessing -Decision pending -History $history
  $cases += Add-P4tValidItemCase 'defer parked then resume assessing' $root @($source) $item

  foreach ($decision in @('adopt', 'adapt')) {
    $root = New-ProjectSkeleton ('item-valid-' + $decision)
    $source = New-P4tSourceCapture $root local
    $requiredScope = if ($decision -eq 'adopt') {
      'copy-internal-approved'
    } else { 'adapt-internal-approved' }
    Add-Member -InputObject $source -NotePropertyName Permissions `
      -NotePropertyValue ([pscustomobject]@{ ReuseScope = $requiredScope }) -Force
    $item = New-P4tItemCard -Root $root -BorrowId ('borrow-20260719-' + $decision) `
      -Bindings @($source) -Status closed -Decision $decision -Seal $true
    $cases += Add-P4tValidItemCase ($decision + ' full lifecycle closes') $root @($source) $item
  }

  $root = New-ProjectSkeleton 'item-valid-refresh-stable-reference'
  $old = New-P4tSourceCapture $root local 'source-refresh' ready 'old-payload'
  $new = New-P4tSourceCapture $root local 'source-refresh' ready 'new-payload'
  $item = New-P4tItemCard $root 'borrow-20260719-refresh' @($old) assessing pending
  $cases += Add-P4tValidItemCase 'refresh keeps old capture binding' $root @($old, $new) $item

  $root = New-ProjectSkeleton 'item-valid-owner-enum'
  $source = New-P4tSourceCapture $root local
  $owners = @(
    'project-pm', 'sediment-pm', 'operating-system-pm', 'product-pm',
    'technical-pm', 'test-pm', 'operations-pm', 'development-pm', 'release-pm'
  )
  for ($index = 0; $index -lt $owners.Count; $index++) {
    $item = New-P4tItemCard $root ('borrow-20260719-owner-' + ($index + 1)) @($source)
    Set-P4tFrontmatterField $item.CardPath owner_pm $owners[$index]
  }
  $cases += Add-P4tValidItemCase 'all governed owner_pm values' $root @($source) $item

  $root = New-ProjectSkeleton 'item-valid-supersedes-terminal'
  $source = New-P4tSourceCapture $root local
  $closed = New-P4tItemCard -Root $root -BorrowId 'borrow-20260719-old-closed' `
    -Bindings @($source) -Status closed -Decision reject -Seal $true
  $cancelled = New-P4tItemCard -Root $root -BorrowId 'borrow-20260719-old-cancelled' `
    -Bindings @($source) -Status cancelled -Decision pending
  $item = New-P4tItemCard -Root $root -BorrowId 'borrow-20260719-revisions' `
    -Bindings @($source) -Supersedes $closed.BorrowId
  $item = New-P4tItemCard -Root $root -BorrowId 'borrow-20260719-revisions-2' `
    -Bindings @($source) -Supersedes $cancelled.BorrowId
  $cases += Add-P4tValidItemCase 'supersedes closed or cancelled item' $root @($source) $item

  $root = New-ProjectSkeleton 'item-valid-benign-query'
  $source = New-P4tSourceCapture $root web
  $item = New-P4tItemCard $root 'borrow-20260719-benign-query' @($source)
  $text = [IO.File]::ReadAllText($item.CardPath, $script:P4tUtf8NoBom)
  $relative = '证据/{0}/{1}' -f $source.SourceId, $source.CaptureId
  Write-P4tUtf8 $item.CardPath $text.Replace(
    $relative, 'https://example.invalid/evidence?view=summary')
  $cases += Add-P4tValidItemCase 'benign HTTPS evidence query' $root @($source) $item

  foreach ($decision in @('adopt', 'adapt')) {
    $requiredScope = if ($decision -eq 'adopt') {
      'copy-internal-approved'
    } else { 'adapt-internal-approved' }
    foreach ($status in @('implementation_ready', 'implementing', 'verifying')) {
      $root = New-ProjectSkeleton `
        ('item-valid-scope-' + $decision + '-' + $status.Replace('_', '-'))
      $source = New-P4tSourceCapture $root local
      Add-Member -InputObject $source -NotePropertyName Permissions `
        -NotePropertyValue ([pscustomobject]@{ ReuseScope = $requiredScope }) -Force
      $item = New-P4tItemCard -Root $root `
        -BorrowId ('borrow-20260719-scope-' + $decision + '-' + $status.Replace('_', '-')) `
        -Bindings @($source) -Status $status -Decision $decision
      $cases += Add-P4tValidItemCase `
        ($status + ' ' + $decision + ' has exact reuse scope') $root @($source) $item
    }
  }
  foreach ($decision in @('adopt', 'adapt')) {
    $root = New-ProjectSkeleton ('item-valid-assessing-' + $decision)
    $source = New-P4tSourceCapture $root local
    $scope = if ($decision -eq 'adopt') {
      'inspect-and-analyze-only'
    } else { 'redistribute-approved' }
    Add-Member -InputObject $source -NotePropertyName Permissions `
      -NotePropertyValue ([pscustomobject]@{ ReuseScope = $scope }) -Force
    $item = New-P4tItemCard -Root $root `
      -BorrowId ('borrow-20260719-assessing-' + $decision) `
      -Bindings @($source) -Status assessing -Decision $decision
    $cases += Add-P4tValidItemCase `
      ('assessing ' + $decision + ' does not consume reuse scope') $root @($source) $item
  }

  Invoke-CzxtContract 'item positive fixtures cover all planned lifecycle branches' {
    Assert-CzxtEqual 17 $cases.Count 'item positive case count'
    $refreshText = [IO.File]::ReadAllText($cases[5].Item.CardPath, $script:P4tUtf8NoBom)
    Assert-CzxtTrue $refreshText.Contains($old.CaptureId) 'refresh item lost old capture'
    Assert-CzxtTrue (-not $refreshText.Contains($new.CaptureId)) 'refresh item followed new capture'
    Assert-CzxtEqual 9 $owners.Count 'owner_pm enum fixture count'
  }

  $script:ItemHelperReady = $false
  Invoke-CzxtContract 'P4t item helper exists with its dedicated leaf API' {
    Import-P4tHelper 'borrowing-item-cards.ps1' 'Invoke-BorrowingP4tItemCheck'
    $script:ItemHelperReady = $true
  }
  if ($script:ItemHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('item positive: ' + $case.Name) {
        $before = Get-P4tTreeState $case.Root
        $result = Invoke-BorrowingP4tItemCheck -Root $case.Root -SourceState $case.SourceState
        Assert-P4tResult $result 0 $case.Name
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $case.Root) ($case.Name + ' read-only')
      }
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
