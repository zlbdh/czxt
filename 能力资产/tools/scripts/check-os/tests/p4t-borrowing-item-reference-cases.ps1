[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-item-test-support.ps1')

function New-P4tItemReferenceCase {
  param([string]$Name, [string]$Status = 'ready')
  $root = New-ProjectSkeleton ('item-reference-' + $Name)
  $source = New-P4tSourceCapture $root local 'source-item' $Status
  $item = New-P4tItemCard $root ('borrow-20260719-' + $Name) @($source) assessing pending
  return [pscustomobject]@{
    Name = $Name; Root = $root; Source = $source; Item = $item
    SourceState = New-P4tSourceState @($source)
  }
}

Initialize-P4tTestFixture
try {
  $cases = @()
  $case = New-P4tItemReferenceCase 'directory-mismatch'
  Set-P4tFrontmatterField $case.Item.CardPath borrow_id 'borrow-20260719-different'
  $cases += $case
  $case = New-P4tItemReferenceCase 'missing-card'
  Remove-Item -LiteralPath $case.Item.CardPath -Force
  $cases += $case
  $case = New-P4tItemReferenceCase 'multiple-cards'
  [void](New-Item -ItemType Directory -Path (Join-Path (Split-Path -Parent $case.Item.CardPath) 'extra'))
  Copy-Item -LiteralPath $case.Item.CardPath -Destination `
    (Join-Path (Split-Path -Parent $case.Item.CardPath) 'extra\借鉴卡.md')
  $cases += $case
  $case = New-P4tItemReferenceCase 'source-missing'
  $case.SourceState = New-P4tSourceState @()
  $cases += $case
  $case = New-P4tItemReferenceCase 'capture-missing'
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace($case.Source.CaptureId, 'local-20260719-000000000000')
  $cases += $case
  $case = New-P4tItemReferenceCase 'fingerprint-mismatch'
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Item.CardPath $text.Replace($case.Source.Fingerprint, ('0' * 64))
  $cases += $case
  $case = New-P4tItemReferenceCase 'active-retired' retired
  $cases += $case
  foreach ($floating in @('current', 'latest', 'HEAD')) {
    $case = New-P4tItemReferenceCase ('floating-' + $floating.ToLowerInvariant())
    $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
    Write-P4tUtf8 $case.Item.CardPath $text.Replace($case.Source.CaptureId, $floating)
    $cases += $case
  }
  $case = New-P4tItemReferenceCase 'evidence-userinfo'
  $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
  $relative = '证据/{0}/{1}' -f $case.Source.SourceId, $case.Source.CaptureId
  Write-P4tUtf8 $case.Item.CardPath $text.Replace(
    $relative, 'https://reader:redacted@example.invalid/evidence')
  $cases += $case
  foreach ($entry in @(
      [pscustomobject]@{ Name = 'token'; Url = 'https://example.invalid/evidence?access_token=redacted' },
      [pscustomobject]@{ Name = 'key'; Url = 'https://example.invalid/evidence?api_key=redacted' },
      [pscustomobject]@{ Name = 'secret'; Url = 'https://example.invalid/evidence?client_secret=redacted' },
      [pscustomobject]@{ Name = 'encoded-token'; Url = 'https://example.invalid/evidence?access%5Ftoken=redacted' }
    )) {
    $case = New-P4tItemReferenceCase ('evidence-query-' + $entry.Name)
    $text = [IO.File]::ReadAllText($case.Item.CardPath, $script:P4tUtf8NoBom)
    $relative = '证据/{0}/{1}' -f $case.Source.SourceId, $case.Source.CaptureId
    Write-P4tUtf8 $case.Item.CardPath $text.Replace($relative, $entry.Url)
    $cases += $case
  }
  $case = New-P4tItemReferenceCase 'supersedes-missing'
  Set-P4tFrontmatterField $case.Item.CardPath supersedes '"borrow-20260719-not-found"'
  $cases += $case

  $activeRoot = New-ProjectSkeleton 'item-reference-supersedes-active'
  $activeSource = New-P4tSourceCapture $activeRoot local 'source-item'
  $activeTarget = New-P4tItemCard $activeRoot 'borrow-20260719-active-target' @($activeSource)
  $activeRevision = New-P4tItemCard -Root $activeRoot `
    -BorrowId 'borrow-20260719-active-revision' -Bindings @($activeSource) `
    -Supersedes $activeTarget.BorrowId
  $cases += [pscustomobject]@{
    Name = 'supersedes-active'; Root = $activeRoot; Source = $activeSource; Item = $activeRevision
    SourceState = New-P4tSourceState @($activeSource)
  }

  $duplicate = New-P4tItemReferenceCase 'duplicate-id'
  $copyRoot = Join-Path $duplicate.Root '借鉴区\事项\borrow-20260719-duplicate-copy'
  Copy-Item -LiteralPath (Split-Path -Parent $duplicate.Item.CardPath) -Destination $copyRoot -Recurse
  $cases += $duplicate

  $cycleRoot = New-ProjectSkeleton 'item-reference-supersedes-cycle'
  $cycleSource = New-P4tSourceCapture $cycleRoot local 'source-item'
  $a = New-P4tItemCard -Root $cycleRoot -BorrowId 'borrow-20260719-cycle-a' `
    -Bindings @($cycleSource) -Supersedes 'borrow-20260719-cycle-b'
  $b = New-P4tItemCard -Root $cycleRoot -BorrowId 'borrow-20260719-cycle-b' `
    -Bindings @($cycleSource) -Supersedes 'borrow-20260719-cycle-a'
  $cases += [pscustomobject]@{
    Name = 'supersedes-cycle'; Root = $cycleRoot; Source = $cycleSource; Item = $a
    SourceState = New-P4tSourceState @($cycleSource)
  }

  Invoke-CzxtContract 'item reference fixtures cover identity binding floating and supersedes failures' {
    Assert-CzxtEqual 19 $cases.Count 'item reference case count'
    foreach ($case in $cases) {
      Assert-P4tPathInside $case.Root $script:P4tFixtureRoot $case.Name | Out-Null
    }
  }

  $script:ItemHelperReady = $false
  Invoke-CzxtContract 'P4t item helper exists for reference cases' {
    Import-P4tHelper 'borrowing-item-cards.ps1' 'Invoke-BorrowingP4tItemCheck'
    $script:ItemHelperReady = $true
  }
  if ($script:ItemHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('item references reject ' + $case.Name) {
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
