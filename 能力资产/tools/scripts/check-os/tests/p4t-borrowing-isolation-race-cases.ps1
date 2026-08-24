[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')

function Restore-P4tIsolationSwap {
  param([string]$Path, [string]$Original, [string]$Replacement)
  if (Test-Path -LiteralPath $Original -PathType Leaf) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
      if (-not (Test-Path -LiteralPath $Replacement)) {
        [IO.File]::Move($Path, $Replacement)
      }
      else { [IO.File]::Delete($Path) }
    }
    [IO.File]::Move($Original, $Path)
  }
}

function Write-P4tIsolationOversizedBinary {
  param([string]$Path, [byte]$Marker)
  $bytes = New-Object byte[] (8MB + 1)
  $bytes[0] = 0
  $bytes[$bytes.Length - 1] = $Marker
  [IO.File]::WriteAllBytes($Path, $bytes)
}

Initialize-P4tTestFixture
try {
  Import-P4tHelper 'borrowing-isolation.ps1' 'Invoke-BorrowingP4tIsolationCheck'

  Invoke-CzxtContract 'isolation binds project config bytes to the checked file handle' {
    $root = New-ProjectSkeleton 'isolation-race-config'
    $path = Join-Path $root '项目配置\fixture.project.json'
    $original = Join-Path $root '项目配置\fixture.original'
    $replacement = Join-Path $script:P4tFixtureRoot 'isolation-race-config-replacement.json'
    Write-P4tUtf8 $replacement @'
{
  "projectName": "replacement",
  "projectRoot": "fixture-only",
  "appRepoDir": "app",
  "currentVersion": "v0.0.0",
  "currentSprint": "test"
}
'@
    $script:P4tIsolationConfigSwapRan = $false
    $script:P4tIsolationTestInjections = @{
      'before-expected-full-handle-open' = {
        param($context)
        if (([string]$context.Path).Equals($path, [StringComparison]::OrdinalIgnoreCase)) {
          [IO.File]::Move($path, $original)
          [IO.File]::Move($replacement, $path)
          $script:P4tIsolationConfigSwapRan = $true
        }
      }
    }
    try { $result = Invoke-BorrowingP4tIsolationCheck -Root $root -Mode project }
    finally {
      $script:P4tIsolationTestInjections = $null
      Restore-P4tIsolationSwap $path $original $replacement
    }
    Assert-CzxtTrue ([bool]$script:P4tIsolationConfigSwapRan) `
      'project config did not use the expected-snapshot handle reader'
    Assert-P4tResult $result 10 'project config replacement before handle open'
  }

  Invoke-CzxtContract 'isolation rejects oversized file replacement before handle open' {
    $root = New-ProjectSkeleton 'isolation-race-oversized-open'
    $path = Join-Path $root 'app\payload.blob'
    $original = Join-Path $root 'app\payload.original'
    $replacement = Join-Path $script:P4tFixtureRoot 'isolation-race-oversized-replacement.blob'
    Write-P4tIsolationOversizedBinary $path 1
    Write-P4tIsolationOversizedBinary $replacement 2
    $script:P4tIsolationOversizedSwapRan = $false
    $script:P4tIsolationTestInjections = @{
      'before-oversized-handle-open' = {
        param($context)
        if (([string]$context.Path).Equals($path, [StringComparison]::OrdinalIgnoreCase)) {
          [IO.File]::Move($path, $original)
          [IO.File]::Move($replacement, $path)
          $script:P4tIsolationOversizedSwapRan = $true
        }
      }
    }
    try { $result = Invoke-BorrowingP4tIsolationCheck -Root $root -Mode project }
    finally {
      $script:P4tIsolationTestInjections = $null
      Restore-P4tIsolationSwap $path $original $replacement
    }
    Assert-CzxtTrue ([bool]$script:P4tIsolationOversizedSwapRan) `
      'oversized replacement injection did not run before handle open'
    Assert-P4tResult $result 10 'oversized replacement before handle open'
  }

  Invoke-CzxtContract 'isolation keeps oversized handle open through path revalidation' {
    $root = New-ProjectSkeleton 'isolation-race-oversized-recheck'
    $path = Join-Path $root 'app\payload.blob'
    $moved = Join-Path $root 'app\payload.moved'
    Write-P4tIsolationOversizedBinary $path 3
    $script:P4tIsolationOversizedMoveBlocked = $false
    $script:P4tIsolationTestInjections = @{
      'after-oversized-prefix-read' = {
        param($context)
        if (([string]$context.Path).Equals($path, [StringComparison]::OrdinalIgnoreCase)) {
          try { [IO.File]::Move($path, $moved) }
          catch [IO.IOException] { $script:P4tIsolationOversizedMoveBlocked = $true }
          throw 'injected mutation attempt'
        }
      }
    }
    try { $result = Invoke-BorrowingP4tIsolationCheck -Root $root -Mode project }
    finally {
      $script:P4tIsolationTestInjections = $null
      if ((Test-Path -LiteralPath $moved) -and -not (Test-Path -LiteralPath $path)) {
        [IO.File]::Move($moved, $path)
      }
    }
    Assert-CzxtTrue ([bool]$script:P4tIsolationOversizedMoveBlocked) `
      'oversized path was not revalidated while its read handle was still open'
    Assert-P4tResult $result 10 'oversized mutation during handle-bound revalidation'
  }

  Invoke-CzxtContract 'isolation detects a child added during a directory scan' {
    $root = New-ProjectSkeleton 'isolation-race-directory-add'
    $directory = Join-Path $root 'app'
    $added = Join-Path $directory 'late.js'
    $script:P4tIsolationDirectoryAddRan = $false
    $script:P4tIsolationTestInjections = @{
      'after-directory-inventory' = {
        param($context)
        if (([string]$context.Path).Equals($directory, [StringComparison]::OrdinalIgnoreCase)) {
          Write-P4tUtf8 $added "export const late = true;`n"
          $script:P4tIsolationDirectoryAddRan = $true
        }
      }
    }
    try { $result = Invoke-BorrowingP4tIsolationCheck -Root $root -Mode project }
    finally { $script:P4tIsolationTestInjections = $null }
    Assert-CzxtTrue ([bool]$script:P4tIsolationDirectoryAddRan) `
      'directory addition injection did not run after initial inventory'
    Assert-P4tResult $result 10 'child added during directory scan'
  }

  Invoke-CzxtContract 'isolation detects a same-name child replacement during a directory scan' {
    $root = New-ProjectSkeleton 'isolation-race-directory-replace'
    $directory = Join-Path $root 'app'
    $path = Join-Path $directory 'stable.js'
    $original = Join-Path $directory 'stable.original'
    Write-P4tUtf8 $path "export const value = 1;`n"
    $script:P4tIsolationDirectoryReplaceRan = $false
    $script:P4tIsolationTestInjections = @{
      'after-directory-inventory' = {
        param($context)
        if (([string]$context.Path).Equals($directory, [StringComparison]::OrdinalIgnoreCase)) {
          [IO.File]::Move($path, $original)
          Write-P4tUtf8 $path "export const value = 2;`n"
          $script:P4tIsolationDirectoryReplaceRan = $true
        }
      }
    }
    try { $result = Invoke-BorrowingP4tIsolationCheck -Root $root -Mode project }
    finally { $script:P4tIsolationTestInjections = $null }
    Assert-CzxtTrue ([bool]$script:P4tIsolationDirectoryReplaceRan) `
      'directory replacement injection did not run after initial inventory'
    Assert-P4tResult $result 10 'same-name child replacement during directory scan'
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
