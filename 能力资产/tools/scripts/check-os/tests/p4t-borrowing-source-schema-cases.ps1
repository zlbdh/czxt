[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-source-test-support.ps1')

function New-P4tSchemaCase {
  param([string]$Name, [string]$Type = 'local')
  $root = New-ProjectSkeleton ('source-schema-' + $Name)
  $record = New-P4tSourceCapture -Root $root -SourceType $Type
  return [pscustomobject]@{ Name = $Name; Root = $root; Record = $record; Exit = 10 }
}

Initialize-P4tTestFixture
try {
  $cases = @()
  $case = New-P4tSchemaCase 'source-id-mismatch'
  Set-P4tFrontmatterField $case.Record.CardPath source_id 'different-source'
  $cases += $case
  $case = New-P4tSchemaCase 'unsafe-source-id'
  Set-P4tFrontmatterField $case.Record.CardPath source_id '../escape'
  $cases += $case
  $case = New-P4tSchemaCase 'capture-id-mismatch'
  Set-P4tFrontmatterField $case.Record.CardPath capture_id 'local-20260719-000000000000'
  $cases += $case
  $case = New-P4tSchemaCase 'unsafe-capture-id'
  Set-P4tFrontmatterField $case.Record.CardPath capture_id '../escape'
  $cases += $case
  $case = New-P4tSchemaCase 'missing-field'
  $text = [IO.File]::ReadAllText($case.Record.CardPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $case.Record.CardPath ([regex]::Replace($text, '(?m)^captured_at:.*\n', '', 1))
  $cases += $case
  $case = New-P4tSchemaCase 'unknown-status'
  Set-P4tFrontmatterField $case.Record.CardPath capture_status 'draft'
  $cases += $case
  $case = New-P4tSchemaCase 'wrong-algorithm'
  Set-P4tFrontmatterField $case.Record.CardPath fingerprint_algorithm 'git-object'
  $cases += $case
  $case = New-P4tSchemaCase 'malformed-fingerprint'
  Set-P4tFrontmatterField $case.Record.CardPath fingerprint 'ABC123'
  $cases += $case
  $case = New-P4tSchemaCase 'absolute-local-locator'
  Set-P4tFrontmatterField $case.Record.CardPath canonical_locator 'C:\private\source'
  $cases += $case
  $case = New-P4tSchemaCase 'credential-url' 'web'
  Set-P4tFrontmatterField $case.Record.CardPath canonical_locator `
    'https://user:secret@example.invalid/final'
  $cases += $case
  $case = New-P4tSchemaCase 'missing-card'
  Remove-Item -LiteralPath $case.Record.CardPath -Force
  $cases += $case
  $case = New-P4tSchemaCase 'multiple-cards'
  [void](New-Item -ItemType Directory -Path (Join-Path $case.Record.CapturePath 'extra'))
  Copy-Item -LiteralPath $case.Record.CardPath -Destination `
    (Join-Path $case.Record.CapturePath 'extra\来源版本卡.md')
  $cases += $case
  $case = New-P4tSchemaCase 'retired-without-history'
  Set-P4tFrontmatterField $case.Record.CardPath capture_status retired
  $cases += $case

  $duplicateRoot = New-ProjectSkeleton 'source-schema-duplicate-id'
  $first = New-P4tSourceCapture $duplicateRoot local 'source-first' -PayloadText first
  $second = New-P4tSourceCapture $duplicateRoot local 'source-second' -PayloadText second
  $duplicatePath = Join-Path (Split-Path -Parent $second.CapturePath) $first.CaptureId
  Move-Item -LiteralPath $second.CapturePath -Destination $duplicatePath
  $second.CapturePath = $duplicatePath
  $second.CardPath = Join-Path $duplicatePath '来源版本卡.md'
  Set-P4tFrontmatterField $second.CardPath capture_id $first.CaptureId
  $cases += [pscustomobject]@{
    Name = 'duplicate-capture-id'; Root = $duplicateRoot; Record = $second; Exit = 10
  }
  $duplicateSourceRoot = New-ProjectSkeleton 'source-schema-duplicate-source-id'
  $sourceA = New-P4tSourceCapture $duplicateSourceRoot local 'source-a' -PayloadText a
  $sourceB = New-P4tSourceCapture $duplicateSourceRoot local 'source-b' -PayloadText b
  Set-P4tFrontmatterField $sourceA.CardPath source_id 'source-duplicate'
  Set-P4tFrontmatterField $sourceB.CardPath source_id 'source-duplicate'
  $cases += [pscustomobject]@{
    Name = 'duplicate-source-id'; Root = $duplicateSourceRoot; Record = $sourceB; Exit = 10
  }

  $hiddenRoot = New-ProjectSkeleton 'source-schema-hidden-source'
  $hidden = New-P4tSourceCapture $hiddenRoot local 'source-hidden'
  Move-Item -LiteralPath (Split-Path -Parent $hidden.CapturePath) -Destination `
    (Join-Path $hiddenRoot '借鉴区\来源\.source-hidden')
  $cases += [pscustomobject]@{
    Name = 'hidden-source-directory'; Root = $hiddenRoot; Record = $hidden; Exit = 10
  }
  $rogueRoot = New-ProjectSkeleton 'source-schema-rogue-file'
  Write-P4tUtf8 (Join-Path $rogueRoot '借鉴区\来源\rogue.txt') "rogue`n"
  $cases += [pscustomobject]@{
    Name = 'source-root-rogue-file'; Root = $rogueRoot; Record = $null; Exit = 10
  }
  $memberRoot = New-ProjectSkeleton 'source-schema-capture-member'
  $member = New-P4tSourceCapture $memberRoot local 'source-member'
  Write-P4tUtf8 (Join-Path (Split-Path -Parent $member.CapturePath) 'rogue.txt') "rogue`n"
  $cases += [pscustomobject]@{
    Name = 'source-directory-rogue-file'; Root = $memberRoot; Record = $member; Exit = 10
  }

  Invoke-CzxtContract 'source schema fixtures cover identity and one-card failures' {
    Assert-CzxtEqual 18 $cases.Count 'source schema case count'
    foreach ($case in $cases) {
      Assert-P4tPathInside $case.Root $script:P4tFixtureRoot $case.Name | Out-Null
    }
  }

  $script:SourceHelperReady = $false
  Invoke-CzxtContract 'P4t source helper exists for schema cases' {
    Import-P4tHelper 'borrowing-source-cards.ps1' 'Invoke-BorrowingP4tSourceCheck'
    $script:SourceHelperReady = $true
  }
  if ($script:SourceHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('source schema rejects ' + $case.Name) {
        $before = Get-P4tTreeState $case.Root
        $result = Invoke-BorrowingP4tSourceCheck $case.Root project
        Assert-P4tResult $result 10 $case.Name
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $case.Root) ($case.Name + ' read-only')
      }
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
