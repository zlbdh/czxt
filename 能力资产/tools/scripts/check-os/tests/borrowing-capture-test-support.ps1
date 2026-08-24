$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')

$script:BorrowingCaptureTemplateRoot = [IO.Path]::GetFullPath(
  (Join-Path $PSScriptRoot '..\..\..\..\..')
)
$script:BorrowingCaptureModuleRoot = [IO.Path]::GetFullPath(
  (Join-Path $PSScriptRoot '..\..\borrowing-capture')
)
$script:BorrowingCaptureFacadePath = [IO.Path]::GetFullPath(
  (Join-Path $PSScriptRoot '..\..\capture-borrowing-source.ps1')
)
$script:BorrowingCaptureFixtureParent = [IO.Path]::GetFullPath(
  (Join-Path $env:TEMP 'czxt-borrowing-capture-tests')
)
$script:BorrowingCaptureFixtureRoot = Join-Path `
  $script:BorrowingCaptureFixtureParent ([guid]::NewGuid().ToString('N'))

function Initialize-BorrowingCaptureFixture {
  [void](New-Item -ItemType Directory -Path $script:BorrowingCaptureFixtureRoot -Force)
}

function Remove-BorrowingCaptureFixture {
  Remove-CzxtFixture -FixtureParent $script:BorrowingCaptureFixtureParent `
    -FixtureRoot $script:BorrowingCaptureFixtureRoot
}

function Write-BorrowingFixtureBytes {
  param([string]$Path, [byte[]]$Bytes)
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent -Force)
  }
  [IO.File]::WriteAllBytes($Path, $Bytes)
}

function Copy-BorrowingFixtureFile {
  param([string]$Source, [string]$Destination)
  Write-BorrowingFixtureBytes -Path $Destination -Bytes ([IO.File]::ReadAllBytes($Source))
}

function New-BorrowingFixtureRoot {
  param(
    [string]$Name,
    [ValidateSet('project', 'template', 'unknown', 'conflict')]
    [string]$Mode = 'project',
    [int]$P4tExitCode = 0
  )
  $root = Join-Path $script:BorrowingCaptureFixtureRoot $Name
  [void](New-Item -ItemType Directory -Path $root -Force)
  if ($Mode -in @('project', 'conflict')) {
    Write-CzxtNoBomText (Join-Path $root '.czxt-project-root') "czxt-root-mode=project`nschema=1`n"
  }
  if ($Mode -in @('template', 'conflict')) {
    Write-CzxtNoBomText (Join-Path $root '.czxt-template-root') "czxt-root-mode=template`nschema=1`n"
  }

  foreach ($relative in @(
      '借鉴区\来源', '借鉴区\事项', '借鉴区\模板',
      '能力资产\tools\scripts\check-os'
    )) {
    [void](New-Item -ItemType Directory -Path (Join-Path $root $relative) -Force)
  }
  Copy-BorrowingFixtureFile `
    (Join-Path $script:BorrowingCaptureTemplateRoot '借鉴区\模板\来源版本卡.md') `
    (Join-Path $root '借鉴区\模板\来源版本卡.md')
  Copy-BorrowingFixtureFile `
    (Join-Path $script:BorrowingCaptureTemplateRoot '能力资产\tools\scripts\check-os\framework-scope.ps1') `
    (Join-Path $root '能力资产\tools\scripts\check-os\framework-scope.ps1')
  Write-CzxtNoBomText (Join-Path $root '借鉴区\.gitignore') @'
来源/*/*/快照/**
来源/*/*/*.local.json
**/.staging-*/
'@
  $p4t = @"
[CmdletBinding()]
param([string]`$Root)
exit $P4tExitCode
"@
  Write-CzxtText (Join-Path $root '能力资产\tools\scripts\check-os\p4t-borrowing-consistency.ps1') `
    $p4t $script:CzxtUtf8Bom
  return [IO.Path]::GetFullPath($root)
}

function Import-BorrowingCaptureModules {
  param([string[]]$Names)
  foreach ($name in $Names) {
    $path = Join-Path $script:BorrowingCaptureModuleRoot ($name + '.ps1')
    Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) `
      ('missing borrowing capture helper: {0}.ps1' -f $name)
    . $path
  }
}

function Assert-BorrowingCommandExists {
  param([string]$Name)
  Assert-CzxtTrue ($null -ne (Get-Command $Name -CommandType Function -ErrorAction SilentlyContinue)) `
    ('missing borrowing capture function: {0}' -f $Name)
}

function Get-BorrowingTreeState {
  param([string]$Root)
  if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return @() }
  $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\')
  return @(
    Get-ChildItem -LiteralPath $rootFull -Recurse -Force | Sort-Object FullName | ForEach-Object {
      $relative = $_.FullName.Substring($rootFull.Length).TrimStart('\') -replace '\\', '/'
      if ($_.PSIsContainer) {
        'D|{0}' -f $relative
      }
      else {
        $bytes = [IO.File]::ReadAllBytes($_.FullName)
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $hash = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant() }
        finally { $sha.Dispose() }
        'F|{0}|{1}|{2}|{3}' -f $relative, $bytes.Length, $_.LastWriteTimeUtc.Ticks, $hash
      }
    }
  )
}

function Assert-BorrowingTreeStateEqual {
  param([string[]]$Expected, [string[]]$Actual, [string]$Context)
  Assert-CzxtEqual $Expected.Count $Actual.Count ($Context + ' entry count')
  for ($index = 0; $index -lt $Expected.Count; $index++) {
    Assert-CzxtEqual $Expected[$index] $Actual[$index] ($Context + ' entry ' + $index)
  }
}

function Invoke-BorrowingFacade {
  param([string[]]$Arguments)
  Assert-CzxtTrue (Test-Path -LiteralPath $script:BorrowingCaptureFacadePath -PathType Leaf) `
    'missing borrowing capture façade: capture-borrowing-source.ps1'
  return Invoke-CzxtPowerShell -ScriptPath $script:BorrowingCaptureFacadePath `
    -ScriptArguments $Arguments -TimeoutMilliseconds 180000
}

function ConvertFrom-BorrowingFacadeOutput {
  param([string]$Text)
  $lines = @(Get-CzxtOutputLines $Text)
  Assert-CzxtEqual 12 $lines.Count 'façade stdout line count'
  Assert-CzxtEqual 'CZXT_BORROWING_CAPTURE_V1' $lines[0] 'façade output marker'
  $keys = @(
    'result', 'stage', 'source_id', 'capture_id', 'fingerprint', 'capture_path',
    'staging_path', 'p4t_before', 'p4t_after', 'reason_code', 'reason'
  )
  $result = @{}
  for ($index = 0; $index -lt $keys.Count; $index++) {
    $prefix = $keys[$index] + '='
    Assert-CzxtTrue $lines[$index + 1].StartsWith($prefix, [StringComparison]::Ordinal) `
      ('façade line {0} key' -f ($index + 2))
    $result[$keys[$index]] = $lines[$index + 1].Substring($prefix.Length)
  }
  return $result
}

function Assert-BorrowingFacadeKnownFailure {
  param($ProcessResult, [string]$Stage, [string]$ReasonCode)
  Assert-CzxtEqual 10 $ProcessResult.ExitCode 'façade failure exit code'
  Assert-CzxtEqual '' $ProcessResult.StdErr 'façade handled stderr'
  $output = ConvertFrom-BorrowingFacadeOutput $ProcessResult.StdOut
  Assert-CzxtEqual 'FAIL' $output.result 'façade failure result'
  Assert-CzxtEqual $Stage $output.stage 'façade failure stage'
  Assert-CzxtEqual $ReasonCode $output.reason_code 'façade failure reason code'
  Assert-CzxtEqual 'not-run' $output.p4t_before 'façade failure p4t-before'
  Assert-CzxtEqual 'not-run' $output.p4t_after 'façade failure p4t-after'
  Assert-CzxtEqual 'none' $output.capture_path 'façade failure capture path'
  Assert-CzxtTrue $output.staging_path.StartsWith('none', [StringComparison]::Ordinal) `
    'façade prewrite staging path'
  Assert-CzxtTrue (-not [string]::IsNullOrWhiteSpace($output.reason)) 'façade failure reason'
  return $output
}

function Assert-BorrowingFailureCode {
  param([scriptblock]$Body, [string]$Stage, [string]$ReasonCode)
  $caught = $null
  try { & $Body }
  catch { $caught = $_.Exception }
  Assert-CzxtTrue ($null -ne $caught) ('expected failure {0}/{1}' -f $Stage, $ReasonCode)
  Assert-CzxtEqual $Stage ([string]$caught.Data['BorrowingStage']) 'failure stage'
  Assert-CzxtEqual $ReasonCode ([string]$caught.Data['BorrowingReasonCode']) 'failure reason code'
}
