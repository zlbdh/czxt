$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-process-support.ps1')

function Assert-True {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Assert-Equal {
  param($Expected, $Actual, [string]$Message)
  if ($Expected -ne $Actual) {
    throw ('{0}; expected=<{1}> actual=<{2}>' -f $Message, $Expected, $Actual)
  }
}

function Assert-Contains {
  param([string]$Text, [string]$Expected, [string]$Message)
  if ($Text.IndexOf($Expected, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
    throw ('{0}; missing=<{1}> output=<{2}>' -f $Message, $Expected, $Text)
  }
}

function Invoke-Contract {
  param([string]$Name, [scriptblock]$Body)
  try {
    & $Body
    $script:Passed++
    Write-Output ('[PASS] {0}' -f $Name)
  }
  catch {
    $script:Failed++
    Write-Output ('[FAIL] {0}: {1}' -f $Name, $_.Exception.Message)
  }
}

function Initialize-WinpsContractFixture {
  if (-not (Test-Path -LiteralPath $script:FixtureParent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $script:FixtureParent -Force)
  }
  [void](New-Item -ItemType Directory -Path $script:FixtureRoot)
}

function New-CaseRoot {
  param([string]$Name)
  $path = Join-Path $script:FixtureRoot $Name
  [void](New-Item -ItemType Directory -Path $path -Force)
  return $path
}

function Write-ScriptFile {
  param(
    [string]$Root,
    [string]$RelativePath,
    [string]$Content,
    [bool]$WithBom
  )
  $path = Join-Path $Root $RelativePath
  $parent = Split-Path -Parent $path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent -Force)
  }
  $encoding = if ($WithBom) { $script:Utf8Bom } else { $script:Utf8NoBom }
  [IO.File]::WriteAllText($path, $Content, $encoding)
  return $path
}

function Invoke-Gate {
  param([string]$Root, [switch]$ListOnly)
  $arguments = @('-Root', $Root)
  if ($ListOnly) { $arguments += '-ListOnly' }
  $watch = [Diagnostics.Stopwatch]::StartNew()
  try {
    $result = Invoke-CzxtPowerShell -ScriptPath $script:GatePath `
      -ScriptArguments $arguments -TimeoutMilliseconds 30000
  }
  finally { $watch.Stop() }
  return [pscustomobject]@{
    ExitCode = $result.ExitCode
    StdOut = $result.StdOut
    StdErr = $result.StdErr
    ElapsedMilliseconds = $watch.ElapsedMilliseconds
  }
}

function Get-OutputLines {
  param([string]$Text)
  if ([string]::IsNullOrEmpty($Text)) { return @() }
  $normalized = $Text.Replace("`r`n", "`n").TrimEnd("`n")
  if ($normalized.Length -eq 0) { return @() }
  return @($normalized -split "`n")
}

function Assert-OutputLines {
  param([string[]]$Expected, [string[]]$Actual, [string]$Message)
  [Array]::Sort($Expected, [StringComparer]::OrdinalIgnoreCase)
  Assert-Equal $Expected.Count $Actual.Count ($Message + ' count')
  $set = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
  for ($i = 0; $i -lt $Expected.Count; $i++) {
    Assert-Equal $Expected[$i] $Actual[$i] ('{0} at index {1}' -f $Message, $i)
    Assert-True (-not [string]::IsNullOrWhiteSpace($Actual[$i])) ($Message + ' contains a blank line')
    Assert-True ($set.Add($Actual[$i])) ('{0} duplicate path: {1}' -f $Message, $Actual[$i])
  }
}

function New-NoBomScriptRange {
  param([string]$Root, [int]$Count)
  for ($i = 0; $i -lt $Count; $i++) {
    $relative = '能力资产\bulk\script-{0:D3}.ps1' -f $i
    [void](Write-ScriptFile $Root $relative '$value = 1' $false)
  }
}

function Get-FileSnapshot {
  param([string]$Path)
  $bytes = [IO.File]::ReadAllBytes($Path)
  $sha = [Security.Cryptography.SHA256]::Create()
  try { $hash = [Convert]::ToBase64String($sha.ComputeHash($bytes)) }
  finally { $sha.Dispose() }
  $item = Get-Item -LiteralPath $Path
  return [pscustomobject]@{ Hash = $hash; LastWriteTimeUtc = $item.LastWriteTimeUtc.Ticks }
}

function Remove-WinpsContractFixture {
  $parentFull = [IO.Path]::GetFullPath($script:FixtureParent).TrimEnd('\')
  $rootFull = [IO.Path]::GetFullPath($script:FixtureRoot).TrimEnd('\')
  $isDirectChild = ([IO.Path]::GetDirectoryName($rootFull) -eq $parentFull)
  if ($isDirectChild -and (Test-Path -LiteralPath $rootFull -PathType Container)) {
    Remove-Item -LiteralPath $rootFull -Recurse -Force
  }
}

function Complete-WinpsContracts {
  Write-Output ('contracts: {0} passed, {1} failed' -f $script:Passed, $script:Failed)
  if ($script:Failed -gt 0) { exit 10 }
  exit 0
}
