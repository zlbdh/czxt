[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-item-test-support.ps1')

Initialize-P4tTestFixture
try {
  $cases = @()
  $root = New-ProjectSkeleton 'source-retired-unreferenced'
  $record = New-P4tSourceCapture $root local 'source-retired' retired
  $cases += [pscustomobject]@{
    Name = 'retired capture with management history and no references'
    Root = $root; Record = $record; Exit = 0
  }

  $root = New-ProjectSkeleton 'source-retired-active'
  $record = New-P4tSourceCapture $root local 'source-retired' retired
  [void](New-P4tItemCard $root 'borrow-20260719-active' @($record) assessing pending)
  $cases += [pscustomobject]@{
    Name = 'retired capture referenced by active item'; Root = $root; Record = $record; Exit = 10
  }

  $root = New-ProjectSkeleton 'source-retired-closed'
  $record = New-P4tSourceCapture $root local 'source-retired' retired
  [void](New-P4tItemCard -Root $root -BorrowId 'borrow-20260719-closed' `
    -Bindings @($record) -Status closed -Decision reject -Seal $true)
  $cases += [pscustomobject]@{
    Name = 'retired capture retained by closed history item'; Root = $root; Record = $record; Exit = 0
  }

  $root = New-ProjectSkeleton 'source-retired-cancelled'
  $record = New-P4tSourceCapture $root local 'source-retired' retired
  [void](New-P4tItemCard -Root $root -BorrowId 'borrow-20260719-cancelled' `
    -Bindings @($record) -Status cancelled -Decision pending)
  $cases += [pscustomobject]@{
    Name = 'retired capture retained by cancelled history item'; Root = $root; Record = $record; Exit = 0
  }

  $root = New-ProjectSkeleton 'source-retired-history-missing'
  $record = New-P4tSourceCapture $root local 'source-retired' ready
  Set-P4tFrontmatterField $record.CardPath capture_status retired
  $cases += [pscustomobject]@{
    Name = 'retired capture without ready-to-retired history'; Root = $root; Record = $record; Exit = 10
  }

  $root = New-ProjectSkeleton 'source-ready-retired-conflict'
  $ready = New-P4tSourceCapture $root local 'source-conflict' ready
  $retiredPath = Join-Path (Split-Path -Parent $ready.CapturePath) `
    ('local-20260720-' + $ready.Fingerprint.Substring(0, 12))
  Copy-Item -LiteralPath $ready.CapturePath -Destination $retiredPath -Recurse
  $retiredCard = Join-Path $retiredPath '来源版本卡.md'
  Set-P4tFrontmatterField $retiredCard capture_id (Split-Path -Leaf $retiredPath)
  Set-P4tFrontmatterField $retiredCard capture_status retired
  $cardText = [IO.File]::ReadAllText($retiredCard, $script:P4tUtf8NoBom)
  $cardText = $cardText.Replace(
    '| 2026-07-19T01:02:03.456Z | none | ready | initial-capture | capture-executor |',
    "| 2026-07-19T01:02:03.456Z | none | ready | initial-capture | capture-executor |`n" +
    '| 2026-07-20T01:02:03.456Z | ready | retired | no-active-reference | operating-system-pm |')
  Write-P4tUtf8 $retiredCard $cardText
  $cases += [pscustomobject]@{
    Name = 'same reuse key has ready and retired captures'; Root = $root; Record = $ready; Exit = 10
  }

  $root = New-ProjectSkeleton 'source-retired-history-credential'
  $record = New-P4tSourceCapture $root local 'source-retired' retired
  $text = [IO.File]::ReadAllText($record.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $record.CardPath $text.Replace('no-active-reference', 'Bearer abc')
  $cases += [pscustomobject]@{
    Name = 'retired capture with credential in management history'
    Root = $root; Record = $record; Exit = 10
  }

  Invoke-CzxtContract 'source retirement fixtures cover active and terminal reference semantics' {
    Assert-CzxtEqual 7 $cases.Count 'source retirement case count'
    Assert-CzxtTrue (Test-Path -LiteralPath $cases[2].Record.CardPath -PathType Leaf) `
      'closed retirement fixture source card'
  }

  $script:SourceHelperReady = $false
  Invoke-CzxtContract 'P4t source helper exists for retirement cases' {
    Import-P4tHelper 'borrowing-source-cards.ps1' 'Invoke-BorrowingP4tSourceCheck'
    $script:SourceHelperReady = $true
  }
  if ($script:SourceHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('source retirement: ' + $case.Name) {
        $before = Get-P4tTreeState $case.Root
        $result = Invoke-BorrowingP4tSourceCheck $case.Root project
        Assert-P4tResult $result $case.Exit $case.Name
        if ($case.Exit -eq 0) {
          Assert-CzxtTrue (@($result.RetiredCaptures | Where-Object {
                $_.SourceId -ceq $case.Record.SourceId -and $_.CaptureId -ceq $case.Record.CaptureId
              }).Count -eq 1) ($case.Name + ' retired map')
        }
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $case.Root) ($case.Name + ' read-only')
      }
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
