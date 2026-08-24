[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')

function Write-P4tIsolationInvalidUtf8 {
  param([string]$Path, [bool]$Oversized)
  if ($Oversized) {
    $bytes = [Text.Encoding]::ASCII.GetBytes(('a' * (8MB + 1)))
    $bytes[0] = 0xFF
  }
  else { [byte[]]$bytes = @(0xC3, 0x28, 0x61) }
  [IO.File]::WriteAllBytes($Path, $bytes)
}

Initialize-P4tTestFixture
try {
  Import-P4tHelper 'borrowing-isolation.ps1' 'Invoke-BorrowingP4tIsolationCheck'

  Invoke-CzxtContract 'isolation revalidates project config bytes at call closeout' {
    $root = New-ProjectSkeleton 'isolation-window-config'
    $configPath = Join-Path $root '项目配置\fixture.project.json'
    Write-P4tUtf8 (Join-Path $root 'app\safe.js') "export const safe = true;`n"
    $originalBytes = [IO.File]::ReadAllBytes($configPath)
    $originalInfo = Get-BorrowingSafePathInfo $configPath File `
      'p4t-test' 'unsafe-project-config'
    $script:P4tIsolationConfigDriftRan = $false
    $script:P4tIsolationTestInjections = @{
      'after-directory-inventory' = {
        param($context)
        if (-not $script:P4tIsolationConfigDriftRan -and
            ([string]$context.Path).Equals(
              (Join-Path $root 'app'), [StringComparison]::OrdinalIgnoreCase)) {
          $text = [Text.Encoding]::UTF8.GetString($originalBytes)
          Write-P4tUtf8 $configPath ($text.Replace('"app"', '"bad"'))
          $script:P4tIsolationConfigDriftRan = $true
        }
      }
    }
    try {
      $result = Invoke-BorrowingP4tIsolationCheck -Root $root -Mode project
      $changedInfo = Get-BorrowingSafePathInfo $configPath File `
        'p4t-test' 'unsafe-project-config'
    }
    finally {
      $script:P4tIsolationTestInjections = $null
      [IO.File]::WriteAllBytes($configPath, $originalBytes)
    }
    Assert-CzxtTrue ([bool]$script:P4tIsolationConfigDriftRan) `
      'project config drift injection did not run during the business scan'
    Assert-CzxtEqual ([string]$originalInfo.IdentityKey) ([string]$changedInfo.IdentityKey) `
      'config fixture did not preserve identity'
    Assert-CzxtEqual ([uint64]$originalInfo.Length) ([uint64]$changedInfo.Length) `
      'config fixture did not preserve length'
    Assert-P4tResult $result 10 'project config content drift before call closeout'
  }

  Invoke-CzxtContract 'isolation revalidates an earlier subtree after scanning a later sibling' {
    $root = New-ProjectSkeleton 'isolation-window-tree'
    $earlyDirectory = Join-Path $root 'app\a'
    $lateDirectory = Join-Path $root 'app\z'
    [void](New-Item -ItemType Directory -Path $earlyDirectory)
    [void](New-Item -ItemType Directory -Path $lateDirectory)
    $earlyPath = Join-Path $earlyDirectory 'a.js'
    Write-P4tUtf8 $earlyPath "export const value = 1;`n"
    Write-P4tUtf8 (Join-Path $lateDirectory 'z.js') "export const late = true;`n"
    $originalInfo = Get-BorrowingSafePathInfo $earlyPath File `
      'p4t-test' 'unsafe-business-path'
    $script:P4tIsolationEarlierTreeDriftRan = $false
    $script:P4tIsolationTestInjections = @{
      'after-directory-inventory' = {
        param($context)
        if (-not $script:P4tIsolationEarlierTreeDriftRan -and
            ([string]$context.Path).Equals(
              $lateDirectory, [StringComparison]::OrdinalIgnoreCase)) {
          Write-P4tUtf8 $earlyPath "export const value = 2;`n"
          $script:P4tIsolationEarlierTreeDriftRan = $true
        }
      }
    }
    try {
      $result = Invoke-BorrowingP4tIsolationCheck -Root $root -Mode project
      $changedInfo = Get-BorrowingSafePathInfo $earlyPath File `
        'p4t-test' 'unsafe-business-path'
    }
    finally { $script:P4tIsolationTestInjections = $null }
    Assert-CzxtTrue ([bool]$script:P4tIsolationEarlierTreeDriftRan) `
      'earlier subtree drift injection did not run while scanning the later sibling'
    Assert-CzxtEqual ([string]$originalInfo.IdentityKey) ([string]$changedInfo.IdentityKey) `
      'earlier subtree fixture did not preserve identity'
    Assert-CzxtEqual ([uint64]$originalInfo.Length) ([uint64]$changedInfo.Length) `
      'earlier subtree fixture did not preserve length'
    Assert-P4tResult $result 10 'earlier subtree content drift before whole-tree closeout'
  }

  foreach ($case in @(
      [pscustomobject]@{ Name = 'small'; Oversized = $false },
      [pscustomobject]@{ Name = 'oversized'; Oversized = $true })) {
    Invoke-CzxtContract ('isolation fails closed on non-NUL invalid UTF-8: ' + $case.Name) {
      $root = New-ProjectSkeleton ('isolation-invalid-utf8-' + $case.Name)
      $path = Join-Path $root 'app\invalid.bin'
      Write-P4tIsolationInvalidUtf8 -Path $path -Oversized $case.Oversized
      $bytes = [IO.File]::ReadAllBytes($path)
      Assert-CzxtTrue (-not ($bytes -contains [byte]0)) `
        ($case.Name + ' invalid UTF-8 fixture contains NUL evidence')
      $result = Invoke-BorrowingP4tIsolationCheck -Root $root -Mode project
      Assert-P4tResult $result 10 ($case.Name + ' non-NUL invalid UTF-8')
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
