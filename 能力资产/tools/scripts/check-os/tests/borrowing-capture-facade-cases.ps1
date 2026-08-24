[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

function Get-BorrowingFacadeParameterNames {
  return @(
    'Root', 'SourceType', 'SourceId', 'GitLocator', 'GitRef', 'LocalPath',
    'LocalDisplayName', 'WebRawBytesPath', 'WebResponseMetadataPath',
    'RightsStatus', 'AccessPolicy', 'ReuseScope', 'ExecutionPolicy',
    'NetworkPolicy', 'StoragePolicy', 'DistributionPolicy',
    'UpstreamWritePolicy', 'AutoRefresh', 'AuthorizationTime',
    'AuthorizationSource', 'AuthorizationScope'
  )
}

function Assert-BorrowingFacadeAst {
  Assert-CzxtTrue (Test-Path -LiteralPath $script:BorrowingCaptureFacadePath -PathType Leaf) `
    'missing borrowing capture façade: capture-borrowing-source.ps1'
  $tokens = $null
  $errors = $null
  $ast = [Management.Automation.Language.Parser]::ParseFile(
    $script:BorrowingCaptureFacadePath, [ref]$tokens, [ref]$errors
  )
  Assert-CzxtEqual 0 $errors.Count 'façade parser errors'
  Assert-CzxtTrue ($null -ne $ast.ParamBlock) 'façade param block'
  $parameters = @($ast.ParamBlock.Parameters)
  $expected = Get-BorrowingFacadeParameterNames
  Assert-CzxtEqual $expected.Count $parameters.Count 'façade explicit parameter count'
  for ($index = 0; $index -lt $expected.Count; $index++) {
    $parameter = $parameters[$index]
    Assert-CzxtEqual $expected[$index] $parameter.Name.VariablePath.UserPath `
      ('façade parameter order {0}' -f $index)
    Assert-CzxtEqual 'System.String' $parameter.StaticType.FullName `
      ('façade parameter type {0}' -f $expected[$index])
    Assert-CzxtTrue ($null -eq $parameter.DefaultValue) `
      ('façade parameter default {0}' -f $expected[$index])
    $attributes = @($parameter.Attributes | Where-Object {
        $_ -is [Management.Automation.Language.AttributeAst]
      })
    Assert-CzxtEqual 0 $attributes.Count ('façade parameter attributes {0}' -f $expected[$index])
  }
  $binding = @($ast.ParamBlock.Attributes | Where-Object {
      $_.TypeName.FullName -eq 'CmdletBinding'
    })
  Assert-CzxtEqual 1 $binding.Count 'façade CmdletBinding count'
  Assert-CzxtTrue ($binding[0].Extent.Text -match '(?i)PositionalBinding\s*=\s*\$false') `
    'façade PositionalBinding false'
}

function Get-BorrowingLocalArguments {
  param([string]$Root, [string]$Source)
  return @(
    '-Root', $Root, '-SourceType', 'Local', '-SourceId', 'fixture-source',
    '-LocalPath', $Source, '-LocalDisplayName', 'fixture-source'
  )
}

Initialize-BorrowingCaptureFixture
try {
  Invoke-CzxtContract 'capture façade exposes exactly the 21 noninjectable string parameters' {
    Assert-BorrowingFacadeAst
  }

  Invoke-CzxtContract 'capture façade rejects every nonproject RootMode before writing' {
    $source = Join-Path $script:BorrowingCaptureFixtureRoot 'mode-source'
    [void](New-Item -ItemType Directory -Path $source)
    Write-CzxtNoBomText (Join-Path $source 'payload.txt') "safe`n"
    foreach ($entry in @(
        @('template', 'template'), @('unknown', 'unknown'), @('conflict', 'conflict')
      )) {
      $root = New-BorrowingFixtureRoot -Name ('mode-' + $entry[0]) -Mode $entry[1]
      $before = @(Get-BorrowingTreeState $root)
      $result = Invoke-BorrowingFacade -Arguments (Get-BorrowingLocalArguments $root $source)
      [void](Assert-BorrowingFacadeKnownFailure $result 'preflight' 'invalid-mode')
      $after = @(Get-BorrowingTreeState $root)
      Assert-BorrowingTreeStateEqual $before $after ('zero write for ' + $entry[0])
    }
  }

  Invoke-CzxtContract 'capture façade rejects the exact source matrix before writing' {
    $root = New-BorrowingFixtureRoot -Name 'invalid-matrix' -Mode project
    $source = Join-Path $script:BorrowingCaptureFixtureRoot 'matrix-source'
    [void](New-Item -ItemType Directory -Path $source)
    Write-CzxtNoBomText (Join-Path $source 'payload.txt') "safe`n"
    $cases = @(
      @('-Root', $root, '-SourceType', 'Local ', '-SourceId', 'safe-id', '-LocalPath', $source, '-LocalDisplayName', 'safe-id'),
      @('-Root', $root, '-SourceType', 'Local', '-SourceId', 'CON', '-LocalPath', $source, '-LocalDisplayName', 'safe-id'),
      @('-Root', $root, '-SourceType', 'Local', '-SourceId', 'safe-id.', '-LocalPath', $source, '-LocalDisplayName', 'safe-id'),
      @('-Root', $root, '-SourceType', 'Local', '-SourceId', 'safe-id', '-LocalPath', $source, '-LocalDisplayName', 'safe-id', '-GitLocator', '')
    )
    foreach ($arguments in $cases) {
      $before = @(Get-BorrowingTreeState $root)
      $result = Invoke-BorrowingFacade -Arguments ([string[]]$arguments)
      [void](Assert-BorrowingFacadeKnownFailure $result 'input' 'invalid-parameters')
      Assert-BorrowingTreeStateEqual $before @(Get-BorrowingTreeState $root) 'matrix zero write'
    }
  }

  Invoke-CzxtContract 'capture façade enforces permission evidence independently before writing' {
    $root = New-BorrowingFixtureRoot -Name 'invalid-permissions' -Mode project
    $source = Join-Path $script:BorrowingCaptureFixtureRoot 'permission-source'
    [void](New-Item -ItemType Directory -Path $source)
    Write-CzxtNoBomText (Join-Path $source 'payload.txt') "safe`n"
    $base = Get-BorrowingLocalArguments $root $source
    $cases = @(
      @($base + @('-StoragePolicy', 'tracked-content-approved')),
      @($base + @('-AuthorizationTime', '2026-07-19T00:00:00Z', '-AuthorizationSource', 'fixture', '-AuthorizationScope', 'current-capture')),
      @('-Root', $root, '-SourceType', 'Git', '-SourceId', 'safe-id', '-GitLocator', 'https://example.invalid/owner/repo.git', '-GitRef', 'refs/heads/main', '-AccessPolicy', 'source-read-only', '-NetworkPolicy', 'source-read-only')
    )
    foreach ($arguments in $cases) {
      $before = @(Get-BorrowingTreeState $root)
      $result = Invoke-BorrowingFacade -Arguments ([string[]]$arguments)
      [void](Assert-BorrowingFacadeKnownFailure $result 'input' 'invalid-permissions')
      Assert-BorrowingTreeStateEqual $before @(Get-BorrowingTreeState $root) 'permission zero write'
    }
  }

  Invoke-CzxtContract 'capture façade preflights the fixed P4t component before every write' {
    $root = New-BorrowingFixtureRoot -Name 'missing-p4t' -Mode project
    $source = Join-Path $script:BorrowingCaptureFixtureRoot 'missing-p4t-source'
    [void](New-Item -ItemType Directory -Path $source)
    Write-CzxtNoBomText (Join-Path $source 'payload.txt') "safe`n"
    Remove-Item -LiteralPath (Join-Path $root `
        '能力资产\tools\scripts\check-os\p4t-borrowing-consistency.ps1') -Force
    $before = @(Get-BorrowingTreeState $root)
    $result = Invoke-BorrowingFacade -Arguments (Get-BorrowingLocalArguments $root $source)
    [void](Assert-BorrowingFacadeKnownFailure $result 'preflight' `
        'missing-trusted-component')
    Assert-BorrowingTreeStateEqual $before @(Get-BorrowingTreeState $root) `
      'missing P4t zero write'
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
