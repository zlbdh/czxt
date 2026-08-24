[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-item-test-support.ps1')

function New-P4tItemPermissionCase {
  param(
    [string]$Name, [string]$Status, [string]$Decision,
    [AllowEmptyString()][string]$ReuseScope
  )
  $root = New-ProjectSkeleton ('item-permission-' + $Name)
  $source = New-P4tSourceCapture $root local 'source-item'
  if ($ReuseScope.Length -gt 0) {
    Add-Member -InputObject $source -NotePropertyName Permissions `
      -NotePropertyValue ([pscustomobject]@{ ReuseScope = $ReuseScope }) -Force
  }
  $item = New-P4tItemCard -Root $root -BorrowId ('borrow-20260719-' + $Name) `
    -Bindings @($source) -Status $Status -Decision $Decision -Seal ($Status -eq 'closed')
  return [pscustomobject]@{
    Name = $Name; Root = $root; Item = $item
    SourceState = New-P4tSourceState @($source)
  }
}

Initialize-P4tTestFixture
try {
  $cases = @()
  $statuses = @(
    [pscustomobject]@{ Name = 'ready'; Value = 'implementation_ready' },
    [pscustomobject]@{ Name = 'doing'; Value = 'implementing' },
    [pscustomobject]@{ Name = 'verify'; Value = 'verifying' },
    [pscustomobject]@{ Name = 'closed'; Value = 'closed' }
  )
  foreach ($decision in @('adopt', 'adapt')) {
    $otherInternal = if ($decision -eq 'adopt') {
      'adapt-internal-approved'
    } else { 'copy-internal-approved' }
    $invalidScopes = @(
      [pscustomobject]@{ Name = 'inspect'; Value = 'inspect-and-analyze-only' },
      [pscustomobject]@{ Name = 'other-internal'; Value = $otherInternal },
      [pscustomobject]@{ Name = 'redistribute'; Value = 'redistribute-approved' }
    )
    foreach ($status in $statuses) {
      foreach ($scope in $invalidScopes) {
        $name = 'reuse-' + $status.Name + '-' + $decision + '-' + $scope.Name
        $cases += New-P4tItemPermissionCase `
          $name $status.Value $decision $scope.Value
      }
    }
  }
  $cases += New-P4tItemPermissionCase `
    'reuse-required-missing' implementation_ready adopt ''

  $root = New-ProjectSkeleton 'item-permission-mixed-bindings'
  $copy = New-P4tSourceCapture $root local 'source-copy'
  $inspect = New-P4tSourceCapture $root local 'source-inspect'
  Add-Member -InputObject $copy -NotePropertyName Permissions `
    -NotePropertyValue ([pscustomobject]@{ ReuseScope = 'copy-internal-approved' }) -Force
  Add-Member -InputObject $inspect -NotePropertyName Permissions `
    -NotePropertyValue ([pscustomobject]@{ ReuseScope = 'inspect-and-analyze-only' }) -Force
  $item = New-P4tItemCard -Root $root -BorrowId 'borrow-20260719-reuse-mixed' `
    -Bindings @($copy, $inspect) -Status implementation_ready -Decision adopt
  $cases += [pscustomobject]@{
    Name = 'reuse-mixed-bindings'; Root = $root; Item = $item
    SourceState = New-P4tSourceState @($copy, $inspect)
  }

  Invoke-CzxtContract 'item permission fixtures cover exact scopes without hierarchy inference' {
    Assert-CzxtEqual 26 $cases.Count 'item permission case count'
  }

  $script:ItemHelperReady = $false
  Invoke-CzxtContract 'P4t item helper exists for permission cases' {
    Import-P4tHelper 'borrowing-item-cards.ps1' 'Invoke-BorrowingP4tItemCheck'
    $script:ItemHelperReady = $true
  }
  if ($script:ItemHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('item permission rejects ' + $case.Name) {
        $before = Get-P4tTreeState $case.Root
        $result = Invoke-BorrowingP4tItemCheck $case.Root $case.SourceState
        Assert-P4tResult $result 10 $case.Name
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $case.Root) `
          ($case.Name + ' read-only')
      }
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
