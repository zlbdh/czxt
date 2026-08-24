$ErrorActionPreference = 'Stop'
$script:CzxtContractPassed = 0
$script:CzxtContractFailed = 0
$script:CzxtUtf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:CzxtUtf8Bom = New-Object System.Text.UTF8Encoding($true)
. (Join-Path $PSScriptRoot 'gate0-process-support.ps1')

function Assert-CzxtTrue {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Assert-CzxtEqual {
  param($Expected, $Actual, [string]$Message)
  if ($Expected -ne $Actual) {
    throw ('{0}; expected=<{1}> actual=<{2}>' -f $Message, $Expected, $Actual)
  }
}

function Invoke-CzxtContract {
  param([string]$Name, [scriptblock]$Body)
  try {
    & $Body
    $script:CzxtContractPassed++
    Write-Output ('[PASS] {0}' -f $Name)
  }
  catch {
    $script:CzxtContractFailed++
    Write-Output ('[FAIL] {0}: {1}' -f $Name, $_.Exception.Message)
  }
}

function Write-CzxtText {
  param([string]$Path, [string]$Content, [Text.Encoding]$Encoding)
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent -Force)
  }
  [IO.File]::WriteAllText($Path, $Content, $Encoding)
}

function Write-CzxtNoBomText {
  param([string]$Path, [string]$Content)
  Write-CzxtText $Path $Content $script:CzxtUtf8NoBom
}

function Test-CzxtUtf8Bom {
  param([string]$Path)
  $bytes = [IO.File]::ReadAllBytes($Path)
  return ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
}

function Get-CzxtOutputLines {
  param([string]$Text)
  if ([string]::IsNullOrEmpty($Text)) { return @() }
  $normalized = $Text.Replace("`r`n", "`n").TrimEnd("`n")
  if ($normalized.Length -eq 0) { return @() }
  return @($normalized -split "`n")
}

function Assert-CzxtOfficialPowerShellScope {
  param([string]$GatePath, [string]$InstanceRoot)
  $previousOutputEncoding = [Console]::OutputEncoding
  try {
    [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(437)
    $listed = Invoke-CzxtPowerShell -ScriptPath $GatePath `
      -ScriptArguments @('-Root', $InstanceRoot, '-ListOnly')
  }
  finally { [Console]::OutputEncoding = $previousOutputEncoding }

  Assert-CzxtEqual 0 $listed.ExitCode ('ListOnly stderr: {0}' -f $listed.StdErr)
  $relativePaths = @(Get-CzxtOutputLines $listed.StdOut)
  Assert-CzxtTrue ($relativePaths.Count -gt 0) 'official PowerShell scope is empty'
  Assert-CzxtTrue ([Array]::IndexOf([string[]]$relativePaths, '实例化项目.ps1') -ge 0) `
    'official PowerShell scope lost exact root installer path'
  Assert-CzxtTrue ([Array]::IndexOf(
      [string[]]$relativePaths, '能力资产/tools/scripts/check-winps-encoding.ps1') -ge 0) `
    'official PowerShell scope lost exact encoding gate path'
  foreach ($relativePath in $relativePaths) {
    Assert-CzxtTrue ($relativePath.EndsWith('.ps1', [StringComparison]::OrdinalIgnoreCase)) `
      ('non-PS1 path in official scope: {0}' -f $relativePath)
    $fullPath = Join-Path $InstanceRoot ($relativePath.Replace('/', '\'))
    Assert-CzxtTrue (Test-CzxtUtf8Bom $fullPath) ('BOM stripped from {0}' -f $relativePath)
  }
}

function Invoke-CzxtP4aSinkContract {
  param(
    [string]$HarnessPath, [string]$P4aPath, [string]$RootPath,
    [int]$ExpectedP4aExit, [int]$ExpectedFailureCount, [string]$SeedFailure = ''
  )
  $harnessText = @'
param(
  [string]$P4aPath, [string]$RootPath, [int]$ExpectedExit,
  [int]$ExpectedCount, [string]$SeedFailure = ''
)
$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$passes = New-Object System.Collections.Generic.List[string]
if (-not [string]::IsNullOrEmpty($SeedFailure)) { $failures.Add($SeedFailure) }
& $P4aPath -Root $RootPath -Failures $failures -Warnings $warnings -Passes $passes
$actualExit = $LASTEXITCODE
if ($actualExit -ne $ExpectedExit) { Write-Error "P4a exit=$actualExit expected=$ExpectedExit"; exit 31 }
if ($failures.Count -ne $ExpectedCount) { Write-Error "failure count=$($failures.Count) expected=$ExpectedCount"; exit 32 }
if ($SeedFailure -and $failures[0] -cne $SeedFailure) { Write-Error 'seed failure changed'; exit 33 }
exit 0
'@
  Write-CzxtText $HarnessPath $harnessText $script:CzxtUtf8Bom
  $arguments = @(
    '-P4aPath', $P4aPath, '-RootPath', $RootPath,
    '-ExpectedExit', ([string]$ExpectedP4aExit), '-ExpectedCount', ([string]$ExpectedFailureCount)
  )
  if (-not [string]::IsNullOrEmpty($SeedFailure)) { $arguments += @('-SeedFailure', $SeedFailure) }
  return Invoke-CzxtPowerShell -ScriptPath $HarnessPath -ScriptArguments $arguments
}

function Remove-CzxtFixture {
  param([string]$FixtureParent, [string]$FixtureRoot)
  $parentFull = [IO.Path]::GetFullPath($FixtureParent).TrimEnd('\', '/')
  $rootFull = [IO.Path]::GetFullPath($FixtureRoot).TrimEnd('\', '/')
  $prefix = $parentFull + [IO.Path]::DirectorySeparatorChar
  Assert-CzxtTrue ($rootFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) `
    ('refuse cleanup outside fixture parent: {0}' -f $rootFull)
  Assert-CzxtTrue (-not $rootFull.Equals($parentFull, [StringComparison]::OrdinalIgnoreCase)) `
    'refuse cleanup of fixture parent itself'
  if (Test-Path -LiteralPath $rootFull) {
    Remove-Item -LiteralPath $rootFull -Recurse -Force
  }
}

function Complete-CzxtContracts {
  Write-Output ('contracts: {0} passed, {1} failed' -f $script:CzxtContractPassed, $script:CzxtContractFailed)
  if ($script:CzxtContractFailed -gt 0) { exit 10 }
  exit 0
}
