[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-candidate-validator-test-support.ps1')

function Set-BtrsProbeMode {
  param([string]$Mode)
  $script:BtrsProbeMode = $Mode
  $script:BtrsProbeCalls = 0
}

function Copy-BtrsPathInfo {
  param($Info, [string]$IdentityKey, [Nullable[uint64]]$Length)
  $properties = [ordered]@{}
  foreach ($property in $Info.PSObject.Properties) {
    $properties[$property.Name] = $property.Value
  }
  if ($PSBoundParameters.ContainsKey('IdentityKey')) {
    $properties['IdentityKey'] = $IdentityKey
  }
  if ($PSBoundParameters.ContainsKey('Length')) { $properties['Length'] = $Length.Value }
  return [pscustomobject]$properties
}

function Assert-BtrsReaderFailure {
  param([scriptblock]$Reader, [string]$Stage, [string]$ReasonCode)
  Assert-BorrowingFailureCode -Body $Reader -Stage $Stage -ReasonCode $ReasonCode
}

function Get-BtrsReaderCases {
  param([string]$Root, [string]$CardPath)
  $readerRoot = $Root
  $readerCardPath = $CardPath
  return @(
    [pscustomobject]@{
      Name = 'ignore contract'; Stage = 'preflight'
      ReasonCode = 'missing-trusted-component'
      Body = { Assert-BorrowingCaptureIgnoreContract $readerRoot }.GetNewClosure()
    },
    [pscustomobject]@{
      Name = 'fixed source-card skeleton'; Stage = 'preflight'
      ReasonCode = 'missing-trusted-component'
      Body = { Get-BorrowingValidatedSourceCardSkeleton $readerRoot }.GetNewClosure()
    },
    [pscustomobject]@{
      Name = 'candidate source card'; Stage = 'candidate'; ReasonCode = 'source-unsafe'
      Body = { Read-BcvStrictUtf8Card $readerCardPath }.GetNewClosure()
    }
  )
}

function New-BtrsUnsafeFileRoot {
  param([ValidateSet('hardlink', 'ads', 'reparse')][string]$Kind)
  $root = New-BorrowingGoldenRoot ('trusted-' + $Kind + '-' + [guid]::NewGuid().ToString('N'))
  $capture = New-BcvCapture -Root $root -SourceType local -WithCache
  $paths = @(
    (Join-Path $root '借鉴区\.gitignore'),
    (Join-Path $root '借鉴区\模板\来源版本卡.md'),
    (Join-Path $capture.CaptureDirectory '来源版本卡.md')
  )
  if ($Kind -eq 'hardlink') {
    for ($index = 0; $index -lt $paths.Count; $index++) {
      $alias = Join-Path $root ('hardlink-' + $index + '.bin')
      [void](New-Item -ItemType HardLink -Path $alias -Target $paths[$index])
    }
  }
  elseif ($Kind -eq 'ads') {
    foreach ($path in $paths) {
      Set-Content -LiteralPath $path -Stream 'unsafe' -Value 'x' -Encoding ascii
    }
  }
  else {
    $borrowing = Join-Path $root '借鉴区'
    $target = Join-Path $root 'reparse-target'
    Move-Item -LiteralPath $borrowing -Destination $target
    [void](New-Item -ItemType Junction -Path $borrowing -Target $target)
    $paths = @(
      (Join-Path $borrowing '.gitignore'),
      (Join-Path $borrowing '模板\来源版本卡.md'),
      (Join-Path $borrowing ('来源\' + $capture.Artifact.SourceId + '\' +
          $capture.Artifact.CaptureId + '\来源版本卡.md'))
    )
  }
  return [pscustomobject]@{ Root = $root; Paths = $paths }
}

Initialize-BorrowingCaptureFixture
try {
  Import-BorrowingCandidateValidatorModules
  . (Join-Path $script:BorrowingCaptureModuleRoot 'orchestrator-preparation.ps1')
  . (Join-Path $script:BorrowingCaptureModuleRoot 'orchestrator-validation.ps1')

  Invoke-CzxtContract 'trusted reader binds checked identity to the opened byte stream' {
    $root = New-BorrowingGoldenRoot 'trusted-handle-binding'
    $path = Join-Path $root 'checked.txt'
    $attacker = Join-Path $root 'attacker.txt'
    $safeBytes = [Text.Encoding]::UTF8.GetBytes("safe`n")
    $attackerBytes = [Text.Encoding]::UTF8.GetBytes("attacker`n")
    Write-BorrowingFixtureBytes $path $safeBytes
    Write-BorrowingFixtureBytes $attacker $attackerBytes
    $script:BtrsSwapPath = $path
    $script:BtrsAttackerPath = $attacker
    $script:BtrsSwapRan = $false
    $script:BorrowingTrustedReadTestInjections = @{
      'before-handle-open' = {
        [IO.File]::Delete($script:BtrsSwapPath)
        [IO.File]::Move($script:BtrsAttackerPath, $script:BtrsSwapPath)
        $script:BtrsSwapRan = $true
      }
    }
    $caught = $null
    try {
      [void](Read-BorrowingStableSafeFileBytes $path candidate source-unsafe)
    }
    catch { $caught = $_.Exception }
    finally { $script:BorrowingTrustedReadTestInjections = $null }
    Assert-CzxtTrue ([bool]$script:BtrsSwapRan) `
      'trusted reader did not run the pre-open replacement injection'
    Assert-CzxtTrue ($null -ne $caught) `
      'trusted reader accepted bytes from a different file identity'
    Assert-CzxtTrue (Test-BcvBytesEqual $attackerBytes `
        ([IO.File]::ReadAllBytes($path))) `
      'trusted reader changed the attacker replacement bytes'
  }

  Invoke-CzxtContract 'trusted reader rejects a path replacement after handle open' {
    $root = New-BorrowingGoldenRoot 'trusted-open-window-binding'
    $path = Join-Path $root 'checked.txt'
    $moved = Join-Path $root 'checked.original.txt'
    $safeBytes = [Text.Encoding]::UTF8.GetBytes("safe`n")
    $attackerBytes = [Text.Encoding]::UTF8.GetBytes("attacker`n")
    Write-BorrowingFixtureBytes $path $safeBytes
    $script:BtrsSwapPath = $path
    $script:BtrsMovedPath = $moved
    $script:BtrsAttackerBytes = $attackerBytes
    $script:BtrsSwapRan = $false
    $script:BorrowingTrustedReadTestInjections = @{
      'after-handle-open-before-read' = {
        [IO.File]::Move($script:BtrsSwapPath, $script:BtrsMovedPath)
        [IO.File]::WriteAllBytes($script:BtrsSwapPath,
          $script:BtrsAttackerBytes)
        $script:BtrsSwapRan = $true
      }
    }
    $caught = $null
    try {
      [void](Read-BorrowingStableSafeFileBytes $path candidate source-unsafe)
    }
    catch { $caught = $_.Exception }
    finally { $script:BorrowingTrustedReadTestInjections = $null }
    Assert-CzxtTrue ([bool]$script:BtrsSwapRan) `
      'trusted reader did not run the open-window replacement injection'
    Assert-CzxtTrue ($null -ne $caught) `
      'trusted reader accepted a path replacement after handle open'
    Assert-CzxtTrue (Test-BcvBytesEqual $attackerBytes `
        ([IO.File]::ReadAllBytes($path))) `
      'trusted reader changed the open-window attacker replacement bytes'
    Assert-CzxtTrue (Test-BcvBytesEqual $safeBytes `
        ([IO.File]::ReadAllBytes($moved))) `
      'trusted reader changed the original open file bytes'
  }

  Invoke-CzxtContract 'orchestrator validation reader composes the trusted handle reader' {
    $root = New-BorrowingGoldenRoot 'trusted-validation-reader'
    $path = Join-Path $root 'checked.txt'
    $attacker = Join-Path $root 'attacker.txt'
    Write-BorrowingFixtureBytes $path ([Text.Encoding]::UTF8.GetBytes("safe`n"))
    Write-BorrowingFixtureBytes $attacker ([Text.Encoding]::UTF8.GetBytes("evil`n"))
    $script:BtrsSwapPath = $path
    $script:BtrsAttackerPath = $attacker
    $script:BtrsSwapRan = $false
    $script:BorrowingTrustedReadTestInjections = @{
      'before-handle-open' = {
        [IO.File]::Delete($script:BtrsSwapPath)
        [IO.File]::Move($script:BtrsAttackerPath, $script:BtrsSwapPath)
        $script:BtrsSwapRan = $true
      }
    }
    $caught = $null
    try { [void](Read-BorrowingStableSafeFile $path candidate source-unsafe) }
    catch { $caught = $_.Exception }
    finally { $script:BorrowingTrustedReadTestInjections = $null }
    Assert-CzxtTrue ([bool]$script:BtrsSwapRan) `
      'orchestrator reader did not run the trusted pre-open replacement injection'
    Assert-CzxtTrue ($null -ne $caught) `
      'orchestrator reader accepted bytes from a different file identity'
  }

  $script:BtrsRealSafePath =
    (Get-Command Get-BorrowingSafePathInfo -CommandType Function).ScriptBlock
  function global:Get-BorrowingSafePathInfo {
    param(
      $Path, $ExpectedKind, $Stage, $ReasonCode,
      [bool]$AllowHardLinks = $false,
      [bool]$AllowAncestorStreams = $false
    )
    $script:BtrsProbeCalls++
    if ($script:BtrsProbeMode -ceq 'fail-staging' -and $script:BtrsProbeCalls -eq 3) {
      Throw-BorrowingFailure capture capture-failed 'staging safety probe failed'
    }
    $info = & $script:BtrsRealSafePath $Path $ExpectedKind $Stage $ReasonCode `
      $AllowHardLinks $AllowAncestorStreams
    if ($script:BtrsProbeMode -ceq 'change-second' -and $script:BtrsProbeCalls -eq 2) {
      return Copy-BtrsPathInfo -Info $info -IdentityKey ($info.IdentityKey + ':changed')
    }
    if ($script:BtrsProbeMode -ceq 'change-second-length' -and
        $script:BtrsProbeCalls -eq 2) {
      return Copy-BtrsPathInfo -Info $info -Length ([uint64]$info.Length + 1)
    }
    return $info
  }

  $identityRoot = New-BorrowingGoldenRoot 'trusted-identity-change'
  $identityCapture = New-BcvCapture -Root $identityRoot -SourceType local -WithCache
  foreach ($case in Get-BtrsReaderCases $identityRoot `
      (Join-Path $identityCapture.CaptureDirectory '来源版本卡.md')) {
    Invoke-CzxtContract ($case.Name + ' rejects identity changes across byte reads') {
      Set-BtrsProbeMode change-second
      Assert-BtrsReaderFailure $case.Body $case.Stage $case.ReasonCode
      Assert-CzxtEqual 2 $script:BtrsProbeCalls 'trusted reader safety probe count'
    }
  }

  $lengthRoot = New-BorrowingGoldenRoot 'trusted-length-change'
  $lengthCapture = New-BcvCapture -Root $lengthRoot -SourceType local -WithCache
  foreach ($case in Get-BtrsReaderCases $lengthRoot `
      (Join-Path $lengthCapture.CaptureDirectory '来源版本卡.md')) {
    Invoke-CzxtContract ($case.Name + ' rejects length changes across byte reads') {
      Set-BtrsProbeMode change-second-length
      Assert-BtrsReaderFailure $case.Body $case.Stage $case.ReasonCode
      Assert-CzxtEqual 2 $script:BtrsProbeCalls 'trusted reader length probe count'
    }
  }

  foreach ($kind in @('hardlink', 'ads', 'reparse')) {
    $fixture = New-BtrsUnsafeFileRoot $kind
    foreach ($case in Get-BtrsReaderCases $fixture.Root $fixture.Paths[2]) {
      Invoke-CzxtContract ($case.Name + ' rejects ' + $kind + ' boundaries') {
        Set-BtrsProbeMode pass
        Assert-BtrsReaderFailure $case.Body $case.Stage $case.ReasonCode
      }
    }
  }

  Invoke-CzxtContract 'staging safety failure exposes only the created generated path' {
    $root = New-BorrowingGoldenRoot 'staging-path-projection'
    $prepared = [pscustomobject]@{
      Root = $root
      Request = [pscustomobject]@{ SourceId = 'source-local' }
    }
    Set-BtrsProbeMode pass
    $script:BorrowingOwnedStagingTestInjections = @{
      'after-staging-created' = {
        param($staging)
        Throw-BorrowingFailure capture capture-failed 'staging safety probe failed'
      }
    }
    $caught = $null
    try { [void](New-BorrowingStagingDirectory $prepared) }
    catch { $caught = $_.Exception }
    finally { $script:BorrowingOwnedStagingTestInjections = $null }
    Assert-CzxtTrue ($null -ne $caught) 'staging safety failure'
    $path = [string]$caught.Data['BorrowingStagingPath']
    Assert-CzxtTrue (-not [string]::IsNullOrEmpty($path)) 'staging failure path projection'
    Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Container) `
      'projected staging path exists'
    Assert-CzxtTrue ((Split-Path -Leaf $path) -cmatch '\A\.staging-[0-9a-f]{32}\z') `
      'projected staging path is generated'
    $source = Join-Path $root '借鉴区\来源\source-local'
    Assert-CzxtEqual ancestor (Get-BorrowingPathRelation $source $path) `
      'projected staging path stays inside source directory'
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
