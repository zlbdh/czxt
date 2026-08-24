[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-source-test-support.ps1')

function New-P4tPermissionCase {
  param([string]$Name, [string]$Type = 'local')
  $root = New-ProjectSkeleton ('source-permission-' + $Name)
  $record = New-P4tSourceCapture $root $Type
  return [pscustomobject]@{ Name = $Name; Root = $root; Record = $record }
}

function Edit-P4tPermissionCard {
  param($Case, [scriptblock]$Edit)
  $text = [IO.File]::ReadAllText($Case.Record.CardPath, $script:P4tUtf8NoBom)
  $updated = & $Edit $text
  Assert-CzxtTrue ($updated -cne $text) ($Case.Name + ' fixture mutation was a no-op')
  Write-P4tUtf8 $Case.Record.CardPath $updated
}

Initialize-P4tTestFixture
try {
  $cases = @()
  $case = New-P4tPermissionCase 'unknown-rights'
  Set-P4tFrontmatterField $case.Record.CardPath rights_status unknown
  $cases += $case
  $case = New-P4tPermissionCase 'local-remote-access'
  Set-P4tFrontmatterField $case.Record.CardPath access_policy source-read-only
  $cases += $case
  $case = New-P4tPermissionCase 'local-network-enabled'
  Set-P4tFrontmatterField $case.Record.CardPath network_policy source-read-only
  $cases += $case
  $case = New-P4tPermissionCase 'source-execution-enabled' 'git'
  Set-P4tFrontmatterField $case.Record.CardPath execution_policy sandbox-approved
  $cases += $case
  $case = New-P4tPermissionCase 'upstream-write-enabled' 'web'
  Set-P4tFrontmatterField $case.Record.CardPath upstream_write_policy allow
  $cases += $case
  $case = New-P4tPermissionCase 'auto-refresh-enabled'
  Set-P4tFrontmatterField $case.Record.CardPath auto_refresh true
  $cases += $case

  $case = New-P4tPermissionCase 'authorization-time-missing' 'git'
  Edit-P4tPermissionCard $case { param($t) $t.Replace(
      '| access_policy | source-read-only | 2026-07-19T01:00:00.000Z | approved-fixture | current-capture |',
      '| access_policy | source-read-only |  | approved-fixture | current-capture |') }
  $cases += $case
  $case = New-P4tPermissionCase 'authorization-source-missing' 'git'
  Edit-P4tPermissionCard $case { param($t) $t.Replace(
      '| network_policy | source-read-only | 2026-07-19T01:00:00.000Z | approved-fixture | current-capture |',
      '| network_policy | source-read-only | 2026-07-19T01:00:00.000Z |  | current-capture |') }
  $cases += $case
  $case = New-P4tPermissionCase 'authorization-scope-missing' 'web'
  Edit-P4tPermissionCard $case { param($t) $t.Replace(
      '| access_policy | source-read-only | 2026-07-19T01:00:00.000Z | approved-fixture | current-capture |',
      '| access_policy | source-read-only | 2026-07-19T01:00:00.000Z | approved-fixture |  |') }
  $cases += $case
  $case = New-P4tPermissionCase 'authorization-credential' 'web'
  Edit-P4tPermissionCard $case { param($t) $t.Replace(
      'approved-fixture', 'https://user:fixture-secret@example.invalid/approval') }
  $cases += $case
  $case = New-P4tPermissionCase 'authorization-credential-encoded' 'web'
  Edit-P4tPermissionCard $case { param($t) $t.Replace(
      'approved-fixture',
      'https%3A%2F%2Fuser%3Afixture-secret%40example.invalid%2Fapproval') }
  $cases += $case
  $case = New-P4tPermissionCase 'authorization-credential-bearer' 'web'
  Edit-P4tPermissionCard $case { param($t) $t.Replace(
      'approved-fixture', 'Bearer fixture-secret-token') }
  $cases += $case
  $case = New-P4tPermissionCase 'authorization-credential-api-key' 'web'
  Edit-P4tPermissionCard $case { param($t) $t.Replace(
      'current-capture', 'api_key=fixture-secret-value') }
  $cases += $case
  $case = New-P4tPermissionCase 'authorization-credential-punctuation-value' 'web'
  Edit-P4tPermissionCard $case { param($t) $t.Replace(
      'current-capture', 'api_key=?fixture-secret-value') }
  $cases += $case
  $case = New-P4tPermissionCase 'authorization-credential-raw-token' 'web'
  Edit-P4tPermissionCard $case { param($t) $t.Replace(
      'approved-fixture', (('s' + 'k-') + 'fixture1234567890')) }
  $cases += $case

  $root = New-ProjectSkeleton 'source-permission-credential-source-id'
  $record = New-P4tSourceCapture $root local 'glpat-1234567890abcdefghij'
  $cases += [pscustomobject]@{
    Name = 'credential-source-id'; Root = $root; Record = $record
  }
  $case = New-P4tPermissionCase 'credential-canonical-locator' 'git'
  Set-P4tFrontmatterField $case.Record.CardPath canonical_locator `
    'https://example.invalid/glpat-1234567890abcdefghij/source.git'
  $cases += $case
  $case = New-P4tPermissionCase 'credential-fact-value' 'git'
  Edit-P4tPermissionCard $case { param($t) [regex]::Replace(
      $t, '(?m)^\| refs/heads/main \| branch \|',
      '| refs/heads/glpat-1234567890abcdefghij | branch |', 1) }
  $cases += $case
  $case = New-P4tPermissionCase 'authorization-credential-network-path' 'web'
  Edit-P4tPermissionCard $case { param($t) $t.Replace(
      'approved-fixture', '//user:fixture-secret@example.invalid/approval') }
  $cases += $case
  $case = New-P4tPermissionCase 'credential-applicable-project'
  $skeletonPath = Join-Path $case.Root '借鉴区\模板\来源版本卡.md'
  foreach ($path in @($skeletonPath, $case.Record.CardPath)) {
    $text = [IO.File]::ReadAllText($path, $script:P4tUtf8NoBom)
    Write-P4tUtf8 $path $text.Replace('`P4t fixture`', '`Bearer abc`')
  }
  $cases += $case
  $case = New-P4tPermissionCase 'credential-applicable-project-whitespace-key'
  $skeletonPath = Join-Path $case.Root '借鉴区\模板\来源版本卡.md'
  foreach ($path in @($skeletonPath, $case.Record.CardPath)) {
    $text = [IO.File]::ReadAllText($path, $script:P4tUtf8NoBom)
    Write-P4tUtf8 $path `
      $text.Replace('`P4t fixture`', '`api key = fixture-secret-value`')
  }
  $cases += $case

  $case = New-P4tPermissionCase 'authorization-row-missing'
  Edit-P4tPermissionCard $case { param($t) [regex]::Replace($t,
      '(?m)^\| storage_policy \|.*\n', '', 1) }
  $cases += $case
  $case = New-P4tPermissionCase 'authorization-row-duplicate'
  Edit-P4tPermissionCard $case { param($t) $line =
      '| rights_status | unverified | 2026-07-19T01:02:03.456Z | default-policy | current-capture |';
      $t.Replace($line, $line + "`n" + $line) }
  $cases += $case

  Invoke-CzxtContract 'source permission fixtures cover enums combinations and nine-row binding' {
    Assert-CzxtEqual 23 $cases.Count 'source permission case count'
    foreach ($case in $cases) {
      Assert-CzxtTrue (Test-Path -LiteralPath $case.Record.CardPath -PathType Leaf) $case.Name
    }
  }

  $script:SourceHelperReady = $false
  Invoke-CzxtContract 'P4t source helper exists for permission cases' {
    Import-P4tHelper 'borrowing-source-cards.ps1' 'Invoke-BorrowingP4tSourceCheck'
    $script:SourceHelperReady = $true
  }
  if ($script:SourceHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('source permissions reject ' + $case.Name) {
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
