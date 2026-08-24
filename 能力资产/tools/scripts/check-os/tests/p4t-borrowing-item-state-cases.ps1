[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-item-test-support.ps1')

function New-P4tItemStateCase {
  param([string]$Name)
  $root = New-ProjectSkeleton ('item-state-' + $Name)
  $source = New-P4tSourceCapture $root local 'source-item'
  Add-Member -InputObject $source -NotePropertyName Permissions `
    -NotePropertyValue ([pscustomobject]@{ ReuseScope = 'adapt-internal-approved' }) -Force
  return [pscustomobject]@{
    Name = $Name; Root = $root; Source = $source
    SourceState = New-P4tSourceState @($source); Item = $null
  }
}

Initialize-P4tTestFixture
try {
  $cases = @()
  $case = New-P4tItemStateCase 'unknown-status'
  $case.Item = New-P4tItemCard $case.Root 'borrow-20260719-unknown' @($case.Source)
  Set-P4tFrontmatterField $case.Item.CardPath lifecycle_status frozen
  $cases += $case
  $case = New-P4tItemStateCase 'draft-adopt'
  $case.Item = New-P4tItemCard $case.Root 'borrow-20260719-draft-adopt' @($case.Source) draft pending
  Set-P4tFrontmatterField $case.Item.CardPath decision adopt
  $cases += $case
  $case = New-P4tItemStateCase 'owner-outside-enum'
  $case.Item = New-P4tItemCard $case.Root 'borrow-20260719-owner-invalid' @($case.Source)
  Set-P4tFrontmatterField $case.Item.CardPath owner_pm Project-pm
  $cases += $case

  $case = New-P4tItemStateCase 'draft-to-closed'
  $history = @(
    (New-P4tHistoryRow '2026-07-19T01:00:00+00:00' none draft pending),
    (New-P4tHistoryRow '2026-07-19T02:00:00+00:00' draft closed reject)
  )
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-direct-close' `
    -Bindings @($case.Source) -Status closed -Decision reject -History $history -Seal $true
  $cases += $case

  $case = New-P4tItemStateCase 'illegal-assessing-to-verifying'
  $history = @(
    (New-P4tHistoryRow '2026-07-19T01:00:00+00:00' none draft pending),
    (New-P4tHistoryRow '2026-07-19T02:00:00+00:00' draft assessing pending),
    (New-P4tHistoryRow '2026-07-19T03:00:00+00:00' assessing verifying adapt)
  )
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-skip' `
    -Bindings @($case.Source) -Status verifying -Decision adapt -History $history
  $cases += $case

  $case = New-P4tItemStateCase 'time-regression'
  $history = @(
    (New-P4tHistoryRow '2026-07-19T02:00:00+00:00' none draft pending),
    (New-P4tHistoryRow '2026-07-19T01:00:00+00:00' draft assessing pending)
  )
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-time' `
    -Bindings @($case.Source) -History $history
  $cases += $case

  $case = New-P4tItemStateCase 'history-status-mismatch'
  $case.Item = New-P4tItemCard $case.Root 'borrow-20260719-last-status' @($case.Source) draft pending
  Set-P4tFrontmatterField $case.Item.CardPath lifecycle_status assessing
  $cases += $case
  $case = New-P4tItemStateCase 'history-decision-mismatch'
  $case.Item = New-P4tItemCard $case.Root 'borrow-20260719-last-decision' @($case.Source)
  Set-P4tFrontmatterField $case.Item.CardPath decision adapt
  $cases += $case

  $case = New-P4tItemStateCase 'blocked-fields-missing'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-blocked' `
    -Bindings @($case.Source) -Blocked $true
  $cases += $case
  $case = New-P4tItemStateCase 'terminal-blocked'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-terminal-blocked' `
    -Bindings @($case.Source) -Status closed -Decision reject -Blocked $true `
    -BlockedFrom assessing -BlockReason wait -ResumeCondition retry -Seal $true
  $cases += $case

  $case = New-P4tItemStateCase 'parked-without-resume'
  $case.Item = New-P4tItemCard $case.Root 'borrow-20260719-parked' @($case.Source) parked defer
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    '- 恢复条件：2026-08-01 复查依赖条件。', '- 当前没有恢复条件或复查时间。')
  $cases += $case

  $case = New-P4tItemStateCase 'closed-history-appended'
  $history = @(Get-P4tDefaultItemHistory closed adapt) +
    (New-P4tHistoryRow '2026-07-19T07:00:00+00:00' closed closed adapt '非法追加')
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-closed-append' `
    -Bindings @($case.Source) -Status closed -Decision adapt -History $history -Seal $true
  $cases += $case
  $case = New-P4tItemStateCase 'cancelled-history-appended'
  $history = @(Get-P4tDefaultItemHistory cancelled pending) +
    (New-P4tHistoryRow '2026-07-19T03:00:00+00:00' cancelled cancelled pending '非法追加')
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-cancel-append' `
    -Bindings @($case.Source) -Status cancelled -Decision pending -History $history
  $cases += $case

  $case = New-P4tItemStateCase 'cancelled-reason-empty'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-cancel-empty' `
    -Bindings @($case.Source) -Status cancelled -Decision pending
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    '| 明确取消原因 | fixture-owner |', '|  | fixture-owner |')
  $cases += $case

  $case = New-P4tItemStateCase 'cancelled-reason-placeholder'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-cancel-placeholder' `
    -Bindings @($case.Source) -Status cancelled -Decision pending
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    '| 明确取消原因 | fixture-owner |', '| 待填写 | fixture-owner |')
  $cases += $case

  $case = New-P4tItemStateCase 'cancelled-reason-decorated-placeholder'
  $case.Item = New-P4tItemCard -Root $case.Root -BorrowId 'borrow-20260719-cancel-decorated' `
    -Bindings @($case.Source) -Status cancelled -Decision pending
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    '| 明确取消原因 | fixture-owner |', '| 待填写取消原因 | fixture-owner |')
  $cases += $case

  $case = New-P4tItemStateCase 'root-mode-unknown'
  $case.Item = New-P4tItemCard $case.Root 'borrow-20260719-mode-unknown' @($case.Source)
  Remove-Item -LiteralPath (Join-Path $case.Root '.czxt-project-root') -Force
  $cases += $case

  $case = New-P4tItemStateCase 'root-mode-conflict'
  $case.Item = New-P4tItemCard $case.Root 'borrow-20260719-mode-conflict' @($case.Source)
  [void](New-Item -ItemType File -Path (Join-Path $case.Root '.czxt-template-root'))
  $cases += $case

  $case = New-P4tItemStateCase 'broad-staging-name'
  $case.Item = New-P4tItemCard $case.Root 'borrow-20260719-staging-name' @($case.Source)
  $staging = Join-Path (Split-Path -Parent $case.Item.CardPath) '.staging-evil'
  [void](New-Item -ItemType Directory -Path $staging)
  Write-P4tUtf8 (Join-Path $staging 'payload.ps1') "Write-Output unsafe`n"
  $cases += $case

  $case = New-P4tItemStateCase 'close-staging-unknown-member'
  $case.Item = New-P4tItemCard $case.Root 'borrow-20260719-staging-member' @($case.Source)
  $staging = Join-Path (Split-Path -Parent $case.Item.CardPath) `
    ('.staging-close-' + ('a' * 32))
  [void](New-Item -ItemType Directory -Path $staging)
  Write-P4tUtf8 (Join-Path $staging 'payload.ps1') "Write-Output unsafe`n"
  $cases += $case

  Invoke-CzxtContract 'item state fixtures cover combinations transitions chronology blocked and terminal history' {
    Assert-CzxtEqual 20 $cases.Count 'item state case count'
  }

  $script:ItemHelperReady = $false
  Invoke-CzxtContract 'P4t item helper exists for state cases' {
    Import-P4tHelper 'borrowing-item-cards.ps1' 'Invoke-BorrowingP4tItemCheck'
    $script:ItemHelperReady = $true
  }
  if ($script:ItemHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('item state rejects ' + $case.Name) {
        $before = Get-P4tTreeState $case.Root
        $result = Invoke-BorrowingP4tItemCheck $case.Root $case.SourceState
        Assert-P4tResult $result 10 $case.Name
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $case.Root) ($case.Name + ' read-only')
      }
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
