$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

function Import-BorrowingTransactionTestModules {
  Import-BorrowingCaptureModules @('transaction', 'p4t-runner', 'common')
  foreach ($name in @(
      'Get-BorrowingExpectedCacheMembers',
      'Invoke-BorrowingCaptureTransactionCore'
    )) { Assert-BorrowingCommandExists $name }
}

function New-BorrowingTransactionFixture {
  param(
    [string]$Name,
    [ValidateSet('Conflict', 'HealthyReuse', 'RepairMissingCache', 'New')]
    [string]$Disposition
  )
  $root = New-BorrowingFixtureRoot ($Name + '-root') project
  $sourceRoot = Join-Path $root '借鉴区\来源\web-source'
  $staging = Join-Path $sourceRoot ('.staging-' + $Name)
  $capture = Join-Path $sourceRoot 'web-20260719-cccccccccccc'
  [void](New-Item -ItemType Directory -Path (Join-Path $staging '快照') -Force)
  Write-BorrowingFixtureBytes (Join-Path $staging '快照\response.bin') ([byte[]](1, 2, 3))
  Write-CzxtNoBomText (Join-Path $staging '快照\response.metadata.json') "{}`n"
  Write-CzxtNoBomText (Join-Path $staging 'capture.local.json') "{}`n"
  Write-CzxtNoBomText (Join-Path $staging '来源版本卡.md') "candidate`n"
  if ($Disposition -in @('HealthyReuse', 'RepairMissingCache')) {
    [void](New-Item -ItemType Directory -Path $capture -Force)
    Write-CzxtNoBomText (Join-Path $capture '来源版本卡.md') "tracked-card`n"
    (Get-Item (Join-Path $capture '来源版本卡.md')).LastWriteTimeUtc = `
      [DateTime]::Parse('2020-01-01T00:00:00Z').ToUniversalTime()
  }
  if ($Disposition -eq 'HealthyReuse') {
    [void](New-Item -ItemType Directory -Path (Join-Path $capture '快照') -Force)
    Copy-Item -LiteralPath (Join-Path $staging '快照\response.bin') `
      -Destination (Join-Path $capture '快照\response.bin')
    Copy-Item -LiteralPath (Join-Path $staging '快照\response.metadata.json') `
      -Destination (Join-Path $capture '快照\response.metadata.json')
    Copy-Item -LiteralPath (Join-Path $staging 'capture.local.json') `
      -Destination (Join-Path $capture 'capture.local.json')
  }
  return [pscustomobject]@{
    Root = $root; SourceType = 'web'; StagingPath = $staging
    CapturePath = $capture; Disposition = $Disposition
  }
}

function New-BorrowingP4tResult {
  param([int]$ExitCode)
  return [pscustomobject]@{
    Outcome = 'exited'; ExitCode = $ExitCode; Projection = [string]$ExitCode
  }
}

function New-BorrowingTransactionOperations {
  param(
    $Context, [int]$BeforeExit = 0, [int]$AfterExit = 0,
    [bool]$FailRollback = $false, [bool]$FailCleanup = $false
  )
  $before = $BeforeExit
  $after = $AfterExit
  $failRollbackValue = $FailRollback
  $failCleanupValue = $FailCleanup
  $operations = [pscustomobject]@{
    RunP4t = {
      param($ctx, [string]$Gate)
      if ($Gate -eq 'p4t-before') { return New-BorrowingP4tResult $before }
      return New-BorrowingP4tResult $after
    }.GetNewClosure()
    AtomicMove = {
      param($ctx)
      [IO.Directory]::Move($ctx.StagingPath, $ctx.CapturePath)
    }
    InstallMissingCache = {
      param($ctx)
      [IO.Directory]::Move((Join-Path $ctx.StagingPath '快照'), (Join-Path $ctx.CapturePath '快照'))
      [IO.File]::Move((Join-Path $ctx.StagingPath 'capture.local.json'), `
        (Join-Path $ctx.CapturePath 'capture.local.json'))
    }
    PostLinkCheck = { param($ctx) }
    FinalCheck = {
      param($ctx)
      $ctx | Add-Member -NotePropertyName FinalChecked `
        -NotePropertyValue $true -Force
      $count = if ($null -ne $ctx.PSObject.Properties['FinalCheckCount']) {
        [int]$ctx.FinalCheckCount
      } else { 0 }
      $ctx | Add-Member -NotePropertyName FinalCheckCount `
        -NotePropertyValue ($count + 1) -Force
    }
    Rollback = {
      param($ctx)
      if ($failRollbackValue) { throw 'fixture rollback failure' }
      if ($ctx.Disposition -eq 'New') {
        [IO.Directory]::Move($ctx.CapturePath, $ctx.StagingPath)
      }
      elseif ($ctx.Disposition -eq 'RepairMissingCache') {
        [IO.Directory]::Move((Join-Path $ctx.CapturePath '快照'), `
          (Join-Path $ctx.StagingPath '快照'))
        [IO.File]::Move((Join-Path $ctx.CapturePath 'capture.local.json'), `
          (Join-Path $ctx.StagingPath 'capture.local.json'))
      }
    }.GetNewClosure()
    Cleanup = {
      param($ctx)
      if ($failCleanupValue) { throw 'fixture cleanup failure' }
      if (Test-Path -LiteralPath $ctx.StagingPath) {
        Remove-Item -LiteralPath $ctx.StagingPath -Recurse -Force
      }
    }.GetNewClosure()
    ProbePathState = {
      param($ctx)
      return [pscustomobject]@{
        CaptureExists = (Test-Path -LiteralPath $ctx.CapturePath -PathType Container)
        StagingExists = (Test-Path -LiteralPath $ctx.StagingPath -PathType Container)
      }
    }
  }
  return $operations
}

function Assert-BorrowingTransactionTrace {
  param($Result, [string[]]$Expected, [string]$Context)
  Assert-CzxtEqual ($Expected -join ',') ($Result.Trace -join ',') ($Context + ' trace')
}
